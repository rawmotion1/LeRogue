-- How LeRogue uses any ability: checks whether it can be used right now, uses it,
-- and waits just long enough to see that it worked. Also the "what state am I in" checks.
--
-- An ability is named one of four ways:
--   skill  'hide', 'sneak', 'disarm', 'intimidation'   -> /doability
--   disc   a combat ability's rank name (a string)      -> /disc
--   item   an item ID (a number) that's in your bags    -> /useitem
--   aa     an AA ID (a number) that isn't an item       -> /alt activate

--- @type Mq
local mq = require('mq')
local state = require('state')
local config = require('config')

local abilities = {}

-- After using an ability we wait until it shows its cooldown, so it can't be fired twice.
-- A successful use ends the wait at once; the timeout only matters when it failed.
local ACTION_TIMEOUT_MS = 1000
local CAST_TIMEOUT_MS = 6000 -- longest we wait for a clicky's cast to finish
local FAIL_BACKOFF_MS = 2000 -- skip an ability this long after it didn't fire (e.g. "must be behind")
local DISC_TRIES = 3         -- attempts to start a rotating disc before moving on
local failedUntil = {}       -- ability -> mq.gettime() until which it's skipped

-- Looked up once at startup instead of on every check
local beguileRank = mq.TLO.Spell('beguile').RankName()
local knifeplayRank = mq.TLO.Spell('Knifeplay Discipline').RankName()
local LIGAMENT_SLICE = 672 -- AA

local SKILLS = { hide = true, sneak = true, disarm = true, intimidation = true }

-- Messages per purpose. Purposes without a message (hiding, disarm) are silent.
local MESSAGES = {
	combat = '\aoUsing: \ar',
	debuff = '\aoUsing: \ar',
	dot = '\aoUsing DoT: \ay',
	live = '\arOuch!! \ayUsing ',
	burn = '\aoBurning: \ay',
	click = '\aoClicking: \ay',
	rotate = '\aoStarting: \ay',
	buff = '\aoUsing: \ay',
}

---------------------------- State checks ----------------------------

-- Able to act at all: not stunned, mezzed, casting, feigning and so on
function abilities.canAct()
	local me = mq.TLO.Me
	return not me.Stunned()
		and not me.Dead()
		and not me.Feigning()
		and not me.Ducking()
		and not me.Silenced()
		and not me.Charmed()
		and not me.Mezzed()
		and not me.Invulnerable()
		and not me.Casting()
end

-- Meleeing an NPC that's in range and at least the minimum level
function abilities.engaged()
	local distance = mq.TLO.Target.Distance() or 0
	return abilities.canAct()
		and mq.TLO.Target.ID() ~= 0
		and distance < 18
		and distance > 0
		and (mq.TLO.Target.Level() or 0) >= config.settings.minlevel
		and mq.TLO.Target.Type() == 'NPC'
		and mq.TLO.Me.Combat()
end

-- Safe to rebuff and apply poison: nothing around, not moving, not invisible, not hurt.
-- Cheap checks first; the NPC radius search is the most expensive, so it goes last.
function abilities.safeToBuff()
	return (mq.TLO.Me.XTarget() or 0) < 1
		and not mq.TLO.Me.Moving()
		and abilities.canAct()
		and mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() == nil
		and mq.TLO.Me.Song('Evader\'s Invisibility').ID() == nil
		and mq.TLO.Me.Buff('Revival Sickness').ID() == nil
		and (mq.TLO.Me.PctHPs() or 0) >= 26
		and mq.TLO.SpawnCount('npc radius 60')() < 1
end

---------------------------- Using abilities ----------------------------

local function typeOf(name)
	if type(name) == 'string' then
		return SKILLS[name] and 'skill' or 'disc'
	end
	return mq.TLO.FindItemCount(name)() > 0 and 'item' or 'aa'
end

local function isReady(name, kind)
	if kind == 'skill' then return mq.TLO.Me.AbilityReady(name)() end
	if kind == 'disc' then return mq.TLO.Me.CombatAbilityReady(name)() end
	if kind == 'item' then return mq.TLO.Me.ItemReady(name)() end
	return mq.TLO.Me.AltAbilityReady(name)()
end

-- Can this ability be used right now? Mid-fight most abilities are simply on cooldown,
-- so the cooldown check comes first and usually is the only lookup made.
local function canUse(name, kind, purpose)
	if state.paused then return false end
	if not isReady(name, kind) then return false end
	if not abilities.canAct() then return false end

	-- Do we actually have it?
	if kind == 'skill' and mq.TLO.Me.Ability(name)() == nil then return false end
	if kind == 'disc' and mq.TLO.Me.CombatAbility(name)() == nil then return false end
	if kind == 'aa' and mq.TLO.Me.AltAbility(name)() == nil then return false end

	-- A beneficial disc or clicky whose buff won't stack
	if (kind == 'disc' or kind == 'item')
		and mq.TLO.Spell(name).SpellType() == 'Beneficial'
		and mq.TLO.Spell(name).Stacks() == false
		and mq.TLO.Spell(name..' Effect').Stacks() == false then
		return false
	end

	-- DoTs and debuffs aren't worth it on a mob that's nearly dead
	if (purpose == 'dot' or purpose == 'debuff') and (mq.TLO.Target.PctHPs() or 0) < 20 then return false end

	-- Rules for specific abilities
	if name == LIGAMENT_SLICE and not config.isOn('ligament') then return false end
	if name == beguileRank and mq.TLO.Me.TargetOfTarget() == mq.TLO.Me.Name() then return false end
	if name == knifeplayRank and mq.TLO.Me.Song("Rogue's Fury")() ~= nil then return false end -- they don't stack
	if string.find(name, 'Thief') and mq.TLO.Me.Song('thief')() ~= nil then return false end -- already running
	if kind == 'item' and mq.TLO.FindItem(name).Prestige() == true and mq.TLO.Me.Subscription() ~= 'GOLD' then return false end

	return true
end

local function activate(name, kind, purpose)
	if kind == 'skill' then
		mq.cmdf('/doability %s', name)
	elseif kind == 'item' then
		mq.cmdf('/useitem "%s"', mq.TLO.FindItem(name).Name())
	elseif kind == 'aa' then
		mq.cmdf('/alt activate %s', name)
	elseif purpose == 'rotate' then
		-- A rotating disc sometimes needs a second /disc before it starts
		local function running() return mq.TLO.Me.ActiveDisc() == name end
		for _ = 1, DISC_TRIES do
			mq.cmdf('/disc %s', name)
			mq.delay(250, running)
			if running() then break end
		end
	else
		mq.cmdf('/disc %s', name)
	end
end

local function displayName(name, kind)
	if kind == 'item' then return mq.TLO.FindItem(name).Name() end
	if kind == 'aa' then return mq.TLO.Spell(mq.TLO.AltAbility(name).Name()).RankName() end
	return name
end

-- Use an ability if it can be used right now. Returns true if it was used.
-- purpose: 'combat', 'debuff', 'dot', 'rotate', 'burn', 'click', 'buff', 'live' or nil.
-- 'live' (defensive) abilities are never skipped after a failure: they're retried every pass.
function abilities.use(name, purpose)
	if name == nil then return false end
	if failedUntil[name] and mq.gettime() < failedUntil[name] then return false end
	if purpose == 'rotate' and mq.TLO.Me.ActiveDisc() then return false end -- one rotating disc at a time

	-- Clickies are always items: one that's missing is just not ready, never tried as an AA
	local kind = purpose == 'click' and 'item' or typeOf(name)
	if not canUse(name, kind, purpose) then return false end

	activate(name, kind, purpose)
	if MESSAGES[purpose] then print('\at[LeRogue] '..MESSAGES[purpose], displayName(name, kind)) end

	-- Worked once it's on cooldown, or once a cast has started (clickies with a cast time)
	local function casting() return mq.TLO.Me.Casting() ~= nil end
	local function worked() return not isReady(name, kind) or casting() end
	mq.delay(ACTION_TIMEOUT_MS, worked)
	local itWorked = worked()
	-- Let a cast finish: nothing else can be used meanwhile, and stopping here would make
	-- the next check see "casting, can't act" and end the burn list early
	if casting() then mq.delay(CAST_TIMEOUT_MS, function() return not casting() end) end
	if itWorked or purpose == 'live' then
		failedUntil[name] = nil
	else
		failedUntil[name] = mq.gettime() + FAIL_BACKOFF_MS
	end
	return true
end

-- Use each ability in a list, while engaged (only call it when engaged).
-- Game state only changes when the script yields, so engagement is re-checked
-- only after an ability actually fired. Returns true if still engaged at the end.
function abilities.useList(list, purpose)
	for _, name in pairs(list) do
		if state.paused then return false end
		if abilities.use(name, purpose) and not abilities.engaged() then return false end
	end
	return true
end

return abilities
