-- What LeRogue does and when: the combat rotation, burns, emergency defense,
-- endurance, rebuffing, poison and auto-hide. Each routine is one step of the main loop.

--- @type Mq
local mq = require('mq')
local state = require('state')
local config = require('config')
local abilities = require('abilities')
local spells = require('spelldata')

local use, useList = abilities.use, abilities.useList
local other = spells.other

local routines = {}

local GLYPH_AA = 5304   -- power glyph, used at the end of a burn when "Use glyphs" is on
local LEGS_SLOT = 18
local legs = mq.TLO.Me.Inventory(LEGS_SLOT).ID()                      -- legs that summon poison
local poison = mq.TLO.Me.Inventory(LEGS_SLOT).Clicky.Spell.Base(1)()  -- item ID of that poison

-- Keep backstab on: the game turns it off now and then
local function autoBackstab() mq.cmd('/autoskill backstab') end
mq.event('autoskill', '#*#You will no longer use backstab while attacking.#*#', autoBackstab)
autoBackstab()

------------------------------ Combat ------------------------------

-- One pass of the combat rotation. Returns true if still engaged afterwards.
function routines.fight()
	if not abilities.engaged() then return false end
	local fighting = true
	if config.isOn('combat') then
		fighting = useList(spells.myCombatAbilities, 'combat')
			and useList(spells.myDebuffs, 'debuff')
			and useList(config.combatClickies, 'click')
	end
	if fighting and config.isOn('disc') then fighting = useList(spells.myDiscs, 'rotate') end
	if fighting and config.isOn('dot') then fighting = useList(spells.myDots, 'dot') end
	if fighting and config.isOn('burnalways') then
		fighting = useList(spells.myBurn, 'burn') and useList(config.burnClickies, 'click')
	end
	if fighting then
		local extras = { 'disarm', 'hide' }
		if config.isOn('intimidation') then table.insert(extras, 'intimidation') end
		fighting = useList(extras)
	end
	return fighting
end

-- Big burn on the current target (/lr burn or the "Burn now" button)
function routines.burn()
	if not abilities.engaged() then
		print('\at[LeRogue] \ayYou\'re not engaged. Cancelling burn.')
		return
	end
	print('\at[LeRogue] \arBUURRRRNNNNN!!!')
	if useList(spells.myBurn, 'burn') and useList(config.burnClickies, 'click') and config.isOn('glyph') then
		use(GLYPH_AA, 'burn')
	end
end

------------------------------ Defense ------------------------------

-- Escalating defensive abilities as health drops, while anything is on XTarget
function routines.stayAlive()
	if (mq.TLO.Me.XTarget() or 0) < 1 then return end
	if mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() then return end
	if not abilities.canAct() then return end
	local hp = mq.TLO.Me.PctHPs()
	if hp == nil then return end

	if hp < 75 and hp > 59 then use(other.tumble, 'live') end
	if hp < 60 and hp > 39 then use(other.premonition, 'live') end

	if other.nimble and hp < 40 and hp > 19 and mq.TLO.Me.CombatAbilityReady(other.nimble)() then
		-- Nimble is a disc, so any running disc has to stop first
		local active = mq.TLO.Me.ActiveDisc()
		if active ~= nil and active ~= other.nimble then
			mq.cmd('/stopdisc')
			mq.delay(500, function() return mq.TLO.Me.ActiveDisc() == nil end)
		end
		use(other.nimble, 'live') -- if it doesn't take, the next pass tries again
	end

	if other.escape and hp < 20 and mq.TLO.Me.AltAbilityReady(other.escape)() then
		-- Drop everything that would keep us in the fight, then escape
		for _, cmd in ipairs({ '/backoff', '/end', '/attack off', '/afollow off', '/stick off', '/moveto off', '/nav stop', '/play off' }) do
			mq.cmd('/squelch '..cmd)
		end
		mq.delay(250)
		use(other.escape, 'live')
	end
end

------------------------------ Endurance ------------------------------

-- Use the breather line when low on endurance, and click it off once recovered.
-- The Hiatus line works in combat; the Respite line only out of combat.
function routines.manageEndurance(fighting)
	local endurance = mq.TLO.Me.PctEndurance() or 100
	if endurance < 10 and abilities.canAct() then
		if config.isOn('hiatus') then
			use(other.hiatus, 'buff')
		elseif not fighting then
			use(other.calm, 'buff')
		end
	end
	if other.calm and endurance >= 25 and mq.TLO.Me.Song(other.calm)() ~= nil then
		mq.cmd('/removebuff '..other.calm)
	end
	if other.hiatus and endurance >= 33 and mq.TLO.Me.Song(other.hiatus)() ~= nil then
		mq.cmd('/removebuff '..other.hiatus)
	end
end

------------------------------ Downtime ------------------------------

-- Put summoned poison straight into your bags.
-- The "poison and" matters: without poison legs both sides are nil, which used to
-- trigger /autoinv plus a 500ms wait on every pass.
function routines.stowPoison()
	if poison and mq.TLO.Cursor.ID() == poison then
		mq.cmd('/autoinv')
		mq.delay(500)
	end
end

local function applyPoison()
	if not poison then return end
	if mq.TLO.FindItemCount(poison)() > 0 and mq.TLO.Me.Buff(mq.TLO.FindItem(poison).Clicky()).ID() == nil then
		use(poison, 'click')
	end
end

local function summonPoison()
	if not legs or not poison then return end
	if mq.TLO.FindItem(legs).Clicky() and mq.TLO.Me.ItemReady(legs)() and mq.TLO.FindItemCount(poison)() < 20 then
		use(legs, 'click')
	end
end

-- Reflexes buff and poison, when it's quiet
function routines.rebuff()
	if not abilities.safeToBuff() then return end
	if mq.TLO.Me.Buff('reflexes').ID() == nil then use(other.reflex, 'buff') end
	if config.isOn('poison') then applyPoison() end
	if config.isOn('summon') then summonPoison() end
end

------------------------------ Auto-hide ------------------------------

function routines.autoHide(fighting)
	if state.hidePausedUntil then
		if mq.gettime() < state.hidePausedUntil then return end
		state.hidePausedUntil = nil
		if config.isOn('hide') then print('\at[LeRogue] \agHide is back on') end
	end
	if fighting or not config.isOn('hide') then return end

	if mq.TLO.Me.State() ~= 'MOUNT' and not mq.TLO.Me.Dead() then use('sneak') end
	if mq.TLO.Me.Sneaking() then use('hide') end
end

-- Become visible and stop auto-hiding for a number of seconds (max 300)
function routines.pauseHide(seconds)
	seconds = tonumber(seconds)
	if seconds == nil then
		print('\at[LeRogue]\ay Please specify seconds (e.g. 30 for 30 seconds)')
	elseif not config.isOn('hide') then
		print('\at[LeRogue]\ay Pausehide only works when autohide is on')
	elseif state.hidePausedUntil then
		print('\at[LeRogue]\ay Hide is already paused!')
	elseif seconds > 300 then
		print('\at[LeRogue]\ay Max value is 300')
	else
		state.hidePausedUntil = mq.gettime() + seconds * 1000
		mq.cmd('/makemevisible')
		print('\at[LeRogue]\ay Hide paused for ', seconds, ' seconds')
	end
end

return routines
