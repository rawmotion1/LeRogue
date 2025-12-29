--LeRogue.lua
--by Rawmotion
local version = '3.3.2'
--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')

if mq.TLO.Me.Class() ~= 'Rogue' then
	print('\at[LeRogue]\ay Welcome to... Wait, you\'re not a rogue!')
	print('\aoLeRogue vanishes and you notice your purse feels lighter.')
	mq.exit()
end

local rogSettings = {} -- initialize config tables
local boolSettings = {}
local rogClickies = {}
local burnClickies = {}
local toon = mq.TLO.Me.Name() or ''
local rogPath = 'LeRogueConfig_'..toon..'.lua' -- name of config file in config folder
local oldPath = 'LeRogueConfig.lua'

local spells = require('spelldata')
local myCombatAbilities = spells.myCombatAbilities
local myDebuffs = spells.myDebuffs
local myDots = spells.myDots
local myDiscs = spells.myDiscs
local myBurn = spells.myBurn
local other = spells.other

local poison = mq.TLO.Me.Inventory(18).Clicky.Spell.Base(1)()
local legs = mq.TLO.Me.Inventory(18).ID()
local pause = false
local myTimer = 0

local function color(val)
	if val == 'on' then val = '\agon'
	elseif val == 'off' then val = '\aroff'
	end
	return val
end

local function listCommands()
	print('\at[LeRogue]\aw ---- \atAll available commands \aw----')
	print('\at[LeRogue]\aw Type \ay/lr help \aw(or just \ay/lr\aw) to repeat this list')
	print('\at[LeRogue]\aw Type \ay/lr resetdefaults \aw to reset all settings')

	print('\at[LeRogue]\ao Pausing the script:')
	print('\at[LeRogue]\ay /lr pause \aw(toggles pause)')
	print('\at[LeRogue]\ay /lr pause \agon\aw/\aroff\aw (turn pause on or off)')

	print('\at[LeRogue]\ao Combat settings:')
	print('\at[LeRogue]\ay /lr combat \agon\aw/\aroff\aw (uses combat abilities)')
	print('\at[LeRogue]\ay /lr disc \agon\aw/\aroff\aw (rotates discs)')
	print('\at[LeRogue]\ay /lr dot \agon\aw/\aroff\aw (uses dots)')
	print('\at[LeRogue]\ay /lr ligament \agon\aw/\aroff\aw (uses ligament slice)')

	print('\at[LeRogue]\ao Burn settings:')
	print('\at[LeRogue]\ay /lr burn \aw(big burn on target)')
	print('\at[LeRogue]\ay /lr glyph \agon\aw/\aroff\aw (uses power glyph during burn)')
	print('\at[LeRogue]\ay /lr burnalways \aw(always use burns)')

	print('\at[LeRogue]\ao Combat routine clickies:')
	print('\at[LeRogue]\ay /lr addclicky \agcombat \ayor \agburn \aw(add clicky on cursor to routine)')
	print('\at[LeRogue]\ay /lr removeclicky \aw(remove clicky on cursor from routine)')
	print('\at[LeRogue]\ay /lr listclickies \aw(shows clickies you\'ve added)')

	print('\at[LeRogue]\ao Auto hide settings:')
	print('\at[LeRogue]\ay /lr hide \agon\aw/\aroff\aw (keeps you hidden)')
	print('\at[LeRogue]\ay /lr pausehide x \aw(be visible for x seconds then resume)')

	print('\at[LeRogue]\ao Defense settings:')
	print('\at[LeRogue]\ay /lr stayalive \agon\aw/\aroff\aw (use defense abilities in emergency)')

	print('\at[LeRogue]\ao Poison settings:')
	print('\at[LeRogue]\ay /lr poison \agon\aw/\aroff\aw (reapplies poison when it\'s safe)')
	print('\at[LeRogue]\ay /lr summon \agon\aw/\aroff\aw (summons poison when it\'s safe)')

	print('\at[LeRogue]\ao Min NPC lvl to use combat abilities:')
	print('\at[LeRogue]\ay /lr minlevel \aox \aw(default is 110)')

	print('\at[LeRogue]\ao Pulling corpses:')
	print('\at[LeRogue]\ay /lr dragcorpses \agon\aw/\aroff\aw (automatically drags group corpses if you have a camp set)')
	print('\at[LeRogue]\ay /lr dragcorpse \aoname \ayor \aotarget \aw(find and corpse)')
end

-------------------------Handle settings----------------------------------------

local function saveSettings()
	mq.pickle(rogPath, { rogSettings=rogSettings, rogClickies=rogClickies, burnClickies=burnClickies })
end

local function updateSettings(cmd, val)
	rogSettings[cmd] = val
	print('\at[LeRogue] \aoTurning \ay', cmd, ' \ag ', color(val))
	saveSettings()
end

local function setDefaults(s)
	if s == 'all' then print('\at[LeRogue] \aw---- \at Setting toggles to default values \aw----') end
	if s == 'all' or rogSettings.dot == nil then rogSettings.dot = 'on' end
	if s == 'all' or rogSettings.hide == nil then rogSettings.hide = 'on' end
	if s == 'all' or rogSettings.disc == nil then rogSettings.disc = 'on' end
	if s == 'all' or rogSettings.combat == nil then rogSettings.combat = 'on' end
	if s == 'all' or rogSettings.clickies == nil then rogSettings.clickies = 'on' end
	if s == 'all' or rogSettings.poison == nil then rogSettings.poison = 'on' end
	if s == 'all' or rogSettings.summon == nil then rogSettings.summon = 'on' end
	if s == 'all' or rogSettings.stayalive == nil then rogSettings.stayalive = 'on' end
	if s == 'all' or rogSettings.glyph == nil then rogSettings.glyph = 'off' end
	if s == 'all' or rogSettings.burnalways == nil then rogSettings.burnalways = 'off' end
	if s == 'all' or rogSettings.dragcorpses == nil then rogSettings.dragcorpses = 'on' end
	if s == 'all' or rogSettings.minlevel == nil then rogSettings.minlevel = 75 end
	if s == 'all' or rogSettings.ligament == nil then rogSettings.ligament = 'on' end
	for k,v in pairs(rogSettings) do print('\at[LeRogue]\ao ',k,": \ay",color(v)) end
	saveSettings()
end

local function setup()
	local err
	local configData, error = loadfile(mq.configDir..'/'..rogPath) -- read config file
	if error then configData, err = loadfile(mq.configDir..'/'..oldPath) end
	if err then -- failed to read the config file, create it using pickle	    
	    print('\at[LeRogue] \ay Creating config file...')  
	    print('\at[LeRogue] \ay Welcome to LeRogue.lua ', version)
		setDefaults('all')
		listCommands()
	elseif configData then -- file loaded, put content into your config table
	    local conf = configData()
		if not conf.burnClickies then
			conf = { rogSettings=rogSettings, rogClickies=rogClickies, burnClickies=burnClickies }
		end
		rogSettings = conf.rogSettings
	    rogClickies = conf.rogClickies
		burnClickies = conf.burnClickies
	    print('\at[LeRogue]\ay Welcome to LeRogue.lua ', version)
		setDefaults() -- check for missing settings
		listCommands()
	end
end
setup()

local function boolizeSettings()
	for k,v in pairs(rogSettings) do
		if v == 'on' then
			boolSettings[k] = true
		elseif v == 'off' then
			boolSettings[k] = false
		end
	end
end
boolizeSettings()

-------------------------Misc functions----------------------------------------

local function notNil(arg)
	if arg ~= nil then
		return arg
	else
		return 0
	end
end

local function togglePause(val)
	if val == 'on' then pause = true
	elseif val == 'off' then
		pause = false
		print('\at[LeRogue] \agUNPAUSED')
	else
		if pause == true then
			pause = false
			print('\at[LeRogue] \agUNPAUSED')
		else pause = true
		end
	end
end

local function newMinLvl(val)
	val = tonumber(val)
	if val == nil then
		print('\at[LeRogue]\ay Specify a number between 1 and 120')
	elseif val < 1 or val > 120 then
		print('\at[LeRogue]\ay Specify a number between 1 and 120')
	else
		rogSettings.minlevel = val
		print('\at[LeRogue]\ay Min NPC lvl for combat is now \ag' , val)
		saveSettings()
	end
end

---------------------Add and remove clickes--------------------

local function addClicky()
	local id = mq.TLO.Cursor
	if id.ID() == nil then
		print('\at[LeRogue] \ayPut a clicky on your cursor')
		return
	elseif id.Clicky() == nil then
		print('\at[LeRogue] \ayThis is not a clicky')
		return
	else
		for _,v in pairs(rogClickies) do
			if v == id.ID() then
				print('\at[LeRogue] \ayAlready added to combat routine.')
				return
			end
		end
		for _,v in pairs(burnClickies) do
			if v == id.ID() then
				print('\at[LeRogue] \ayAlready in burn routine. Not adding to combat routine.')
				return
			end
		end
		table.insert(rogClickies, id.ID())
		saveSettings()
		print('\at[LeRogue] \ayAdded clicky to combat routine: \ag', id.Name())
	end
end

local function removeClicky()
	local id = mq.TLO.Cursor
	if id.ID() == nil then
		print('\at[LeRogue] \ayPut a clicky on your cursor')
		return
	elseif id.Clicky() == nil then
		print('\at[LeRogue] \ayThis is not a clicky')
		return
	else
		for k,v in pairs(rogClickies) do
			if v == id.ID() then
				rogClickies[k] = nil
				saveSettings()
				print('\at[LeRogue] \ayClicky removed from combat routine.')
			end
		end
		for k,v in pairs(burnClickies) do
			if v == id.ID() then
				burnClickies[k] = nil
				saveSettings()
				print('\at[LeRogue] \ayClicky removed from burn routine.')
			end
		end
	end
end

local function addBurnClicky()
	local id = mq.TLO.Cursor
	if id.ID() == nil then
		print('\at[LeRogue] \ayPut a clicky on your cursor.')
		return
	elseif id.Clicky() == nil then
		print('\at[LeRogue] \ayThis is not a clicky.')
		return
	else
		for k,v in pairs(rogClickies) do
			if v == id.ID() then
				print('\at[LeRogue] \ayAlready in combat routine. Not adding to burn routine.')
				return
			end
		end
		for k,v in pairs(burnClickies) do
			if v == id.ID() then
				print('\at[LeRogue] \ayAlready added to burn routine.')
				return
			end
		end
		table.insert(burnClickies, id.ID())
		saveSettings()
		print('\at[LeRogue] \ayAdded clicky to burn routine: \ag', id.Name())
	end
end

local function listClickies()
	for k,v in pairs(rogClickies) do
		print('\at[LeRogue]\ay Combat clickies: \ag', mq.TLO.FindItem(v).Name())
	end
	for k,v in pairs(burnClickies) do
		print('\at[LeRogue]\ay Burn clickies: \ag', mq.TLO.FindItem(v).Name())
	end
end

---------------------State checks---------------------

local function goodToGo()
	return not mq.TLO.Me.Stunned()
	and not	mq.TLO.Me.Dead()
	and not mq.TLO.Me.Feigning()
	and not	mq.TLO.Me.Ducking()
	and not mq.TLO.Me.Silenced()
	and not mq.TLO.Me.Charmed()
	and not mq.TLO.Me.Mezzed()
	and not mq.TLO.Me.Invulnerable()
	and not mq.TLO.Me.Casting()
end

local function engaged()
	return goodToGo()
	and mq.TLO.Target.ID() ~= 0
	and notNil(mq.TLO.Target.Distance()) < 18
	and	notNil(mq.TLO.Target.Distance()) > 0
	and notNil(mq.TLO.Target.Level()) >= rogSettings.minlevel
	and mq.TLO.Target.Type() == 'NPC'
	and mq.TLO.Me.Combat()
end	

local function safeToCast()
	return goodToGo()
	and not	mq.TLO.Me.Moving()
	and mq.TLO.SpawnCount('npc radius 60')() < 1
	and mq.TLO.Me.XTarget() < 1
	and mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() == nil
	and mq.TLO.Me.Song('Evader\'s Invisibility').ID() == nil
	and mq.TLO.Me.Buff('Revival Sickness').ID() == nil
	and not (mq.TLO.Me.PctHPs() < 26)
end

--------------------------Combat routine--------------------------

local function checks(n, c, k)
	local passed = true
	if pause == true then passed = false end
	if not goodToGo() then passed = false end
	if c == 1 and mq.TLO.Me.Ability(n)() == nil then passed = false end
	if c == 2 and mq.TLO.Me.CombatAbility(n)() == nil then passed = false end
	if c == 3 and mq.TLO.FindItemCount(n)() < 1 then passed = false end
	if c == 4 and mq.TLO.Me.AltAbility(n)() == nil then passed = false end

	if c == 1 and not mq.TLO.Me.AbilityReady(n)() then
		passed = false
	elseif c == 2 and not mq.TLO.Me.CombatAbilityReady(n)() then
		passed = false
	elseif c == 3 and not mq.TLO.Me.ItemReady(n)() then
		passed = false
	elseif c == 4 and not mq.TLO.Me.AltAbilityReady(n)() then
		passed = false
	end
	if (c == 2 or c == 3) and mq.TLO.Spell(n).SpellType() == 'Beneficial' and (mq.TLO.Spell(n).Stacks() == false and mq.TLO.Spell(n..' Effect').Stacks() == false) then passed = false end
	if (k == 'dot' or k == 'debuff') and notNil(mq.TLO.Target.PctHPs()) < 20 then passed = false end
	if n == 672 and rogSettings.ligament == 'off' then passed = false end
	if n == mq.TLO.Spell('beguile').RankName() and mq.TLO.Me.TargetOfTarget() == mq.TLO.Me.Name() then passed = false end
	if n == mq.TLO.Spell('Knifeplay Discipline').RankName() and mq.TLO.Me.Song("Rogue's Fury")() ~= nil then passed = false end
	if string.find(n, 'Thief') and mq.TLO.Me.Song('thief')() ~= nil then passed = false end
	if c == 3 and mq.TLO.FindItem(n).Prestige() == true and mq.TLO.Me.Subscription() ~= 'GOLD' then passed = false end
	return passed
end

local function execute(name, kind)
	if name == nil then return end
	local category
	local start
	local stop
	local printName
	if type(name) == 'string' then
		if name == 'hide' or name == 'sneak' or name == 'disarm' or name == 'intimidation' then
			category = 1
			start = function() mq.cmdf('/doability %s', name) end
			stop = function() return not mq.TLO.Me.AbilityReady(name)() end
			printName = 'none'
		else
			category = 2
			if kind == 'rotate' then
				if mq.TLO.Me.ActiveDisc() then return end
				start = function() repeat mq.cmdf('/disc %s', name) mq.delay(250) until mq.TLO.Me.ActiveDisc() == name end
			else
				start = function() mq.cmdf('/disc %s', name) end
			end
			stop = function() return not mq.TLO.Me.CombatAbilityReady(name)() end
			printName = name
		end
	elseif type(name) == 'number' then
		if mq.TLO.FindItemCount(name)() > 0 then
			category = 3
			start = function() mq.cmdf('/useitem "%s"', mq.TLO.FindItem(name).Name()) end
			stop = function() return not mq.TLO.Me.ItemReady(name)() end
			printName = mq.TLO.FindItem(name).Name()
		else
			category = 4
			start = function() mq.cmdf('/alt activate %s', name) end
			stop = function() return not mq.TLO.Me.AltAbilityReady(name)() end
			printName = mq.TLO.Spell(mq.TLO.AltAbility(name).Name()).RankName()
		end
	end
	local message
	if kind == 'combat' or kind == 'debuff' then
		message = function() print('\at[LeRogue] \aoUsing: \ar', printName) end
	elseif kind == 'dot' then
		message = function() print('\at[LeRogue] \aoUsing DoT: \ay', printName) end
	elseif kind == 'live' then
		message = function() print('\at[LeRogue] \arOuch!! \ayUsing ', printName) end
	elseif kind == 'burn' then
		message = function() print('\at[LeRogue] \aoBurning: \ay', printName) end
	elseif kind == 'click' then
		message = function() print('\at[LeRogue] \aoClicking: \ay', printName) end
	elseif kind == 'rotate' then
		message = function() print('\at[LeRogue] \aoStarting: \ay', printName) end
	elseif kind == 'buff' then
		message = function() print('\at[LeRogue] \aoUsing: \ay', printName) end
	end
	if checks(name, category, kind) == true then
		start()
		if message ~= nil then message() end
		mq.delay(3000, stop)
	end
end

local function doCombatAbilies()
	for _,v in pairs(myCombatAbilities) do
		if not engaged() or pause == true then break end
		execute(v, 'combat')
	end
end

local function doDebuffs()
	for _,v in pairs(myDebuffs) do
		if not engaged() or pause == true then break end
		execute(v, 'debuff')
	end
end

local function doDots()
	for _,v in pairs(myDots) do
		if not engaged() or pause == true then break end
		execute(v, 'dot')
	end
end

local function doClickies()
	for _,v in pairs(rogClickies) do
		if not engaged() or pause == true then break end
		execute(v, 'click')
	end
end

local function doDiscs()
	for _,v in pairs(myDiscs) do
		if not engaged() or pause == true then break end
		execute(v, 'rotate')
	end
end

local function doOther()
  	execute('disarm')
    execute('hide')
	execute('intimidation')
end

local function breathe()
	execute(other.calm, 'buff')
end

local function doBurn()
	if engaged() then
		print('\at[LeRogue] \arBUURRRRNNNNN!!!')
		for _,v in pairs(myBurn) do
			if not engaged() or pause == true then break end
			execute(v, 'burn')
		end
		for _,v in pairs(burnClickies) do
			if not engaged() or pause == true then break end
			execute(v, 'click')
		end
        if rogSettings.glyph == 'on' then
			execute(5304, 'burn')
		end
	else
		print('\at[LeRogue] \ayYou\'re not engaged. Cancelling burn.')
	end
end

local function keepBurning()
    for _,v in pairs(myBurn) do
        if not engaged() or pause == true then break end
        execute(v, 'burn')
    end
	for _,v in pairs(burnClickies) do
		if not engaged() or pause == true then break end
		execute(v, 'click')
	end
end

------------------------------Safe to cast -----------------------------

local function reflexes()
	if mq.TLO.Me.Buff('reflexes').ID() == nil then
		execute(other.reflex, 'buff')
	end
end
local function applyPoison()
	if mq.TLO.FindItemCount(poison)() > 0 and mq.TLO.Me.Buff(mq.TLO.FindItem(poison).Clicky()).ID() == nil then
		execute(poison, 'click')
	end
end

local function summonPoison()
	if mq.TLO.FindItem(legs).Clicky() and mq.TLO.Me.ItemReady(legs)() and mq.TLO.FindItemCount(poison)() < 20 then
		execute(legs, 'click')
	end
end

----------------------------Emergency stay alive--------------------------

local function stayAlive()
	if mq.TLO.Me.XTarget() > 0 and not mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() then
	    -- Tumble
	    if mq.TLO.Me.PctHPs() < 75 and mq.TLO.Me.PctHPs() > 59 then execute(other.tumble, 'live') end
	    -- Premonition
	    if mq.TLO.Me.PctHPs() < 60 and mq.TLO.Me.PctHPs() > 39 then execute(other.premonition, 'live') end
	    -- Nimble
	    if mq.TLO.Me.PctHPs() < 40 and mq.TLO.Me.PctHPs() > 19 and mq.TLO.Me.CombatAbilityReady(other.nimble)() then
	        if mq.TLO.Me.ActiveDisc() ~= nil and mq.TLO.Me.ActiveDisc() ~= other.nimble then
				mq.cmd('/stopdisc')
			end
	        repeat
				execute(other.nimble, 'live')
			until mq.TLO.Me.ActiveDisc() == other.nimble
	    end
	    -- Escape
	    if mq.TLO.Me.PctHPs() < 20 and mq.TLO.Me.AltAbilityReady(other.escape)() then
	        mq.cmd('/squelch /backoff')
	        mq.cmd('/squelch /end')
	        mq.cmd('/squelch /attack off')
	        mq.cmd('/squelch /afollow off')
	        mq.cmd('/squelch /stick off')
	        mq.cmd('/squelch /moveto off')
	        mq.cmd('/squelch /nav stop')
	        mq.cmd('/squelch /play off')
	        mq.delay(250)
	        execute(other.escape, 'live')
	    end
	end
end

--------------------------Auto hide and pause hide-------------------

local function autoHide()
    if mq.TLO.Me.State() ~= 'MOUNT' and not mq.TLO.Me.Dead() then
    	execute('sneak')
    end
    if mq.TLO.Me.Sneaking() then
    	execute('hide')
    end
end

local function setTimer(d)
    local startTime = os.time()
    myTimer = startTime + d
end
local function pauseHide(val)
	val = tonumber(val)
	if val == nil then
		print('\at[LeRogue]\ay Please specify seconds (e.g. 30 for 30 seconds)')
		return
	end
	if rogSettings.hide == 'off' then
		print('\at[LeRogue]\ay Pausehide only works when autohide is on')
	elseif rogSettings.hide == 'paused' then
		print('\at[LeRogue]\ay Hide is already paused!')
	elseif val > 300 then
		print('\at[LeRogue]\ay Max value is 300')	
	else	
		setTimer(val)
		mq.cmd('/makemevisible')
		rogSettings.hide = 'paused'
		print('\at[LeRogue]\ay Hide paused for ', val, ' seconds')
	end
end

----------------------------Define events--------------------------------------
local consent
local function noConsent(line)
	print('\at[LeRogue] \ayI don\'t have consent do drag this corpse.')
	consent = false
end
local function backstab()
	mq.cmd('/autoskill backstab')
end
mq.event('consent', '#*#You do not have consent to summon that corpse.#*#', noConsent)
mq.event('autoskill', '#*#You will no longer use backstab while attacking.#*#', backstab)
backstab()
--------------------------Fetch corpse routine--------------------------------

local campUp
local where
local returnLoc = {}
local corpseLocation = {}

local function dragCorpse(id, name)
	if mq.TLO.Navigation.PathExists('id '..id)() then
		print('\at[LeRogue] \agGoing to pull ', name)
		updateSettings('hide', 'on')
		if mq.TLO.Macro() and mq.TLO.Macro.Paused() == false then
			print('\at[LeRogue] \ayPausing macro')
			mq.cmd('/squelch /mqp on')
		end

		mq.delay(2000)
		mq.cmdf('/squelch /nav id %s', id)
	else
		print('\at[LeRogue] \ayCan\'t find path to ', name)
		return
	end

	while mq.TLO.Navigation.Active() do
		if pause == true then mq.cmd('/squelch /nav stop') break end
		if mq.TLO.Spawn(id).Distance() < 75 and mq.TLO.Spawn(id).LineOfSight() then
			mq.cmd('/squelch /nav stop')
			mq.cmdf('/target %s', name)
			mq.cmd('/corpsedrag')
			break
		end
	end
	
	consent = true
	mq.delay(2000)
	mq.doevents()
	if consent == false then return end

	mq.cmdf('/squelch /nav locxyz %s, %s, %s', returnLoc.x, returnLoc.y, returnLoc.z)
	print('\at[LeRogue] \agBringing corpse back to your ', where)
	while mq.TLO.Navigation.Active() do
		if pause == true then mq.cmd('/squelch /nav stop') break end
		local x = math.abs(mq.TLO.Me.X() - returnLoc.x)
		local y = math.abs(mq.TLO.Me.Y() - returnLoc.y)
		local z = math.abs(mq.TLO.Me.Z() - returnLoc.z)
		if x < 10 and y < 10 and z < 10 then
			mq.cmd('/squelch /nav stop')
			mq.delay(1000)
			mq.cmd('/corpsedrop')
			break
		end
	end
	if mq.TLO.Macro() and mq.TLO.Macro.Paused() == true then
		print('\at[LeRogue] \ayUnpausing macro')
		mq.cmd('/squelch /mqp off')
	end
end

local function setLoc()
	if mq.TLO.Macro.Variable('ReturnToCamp')() == 1 then
		returnLoc.x = mq.TLO.Macro.Variable('CampXLoc')()
		returnLoc.y = mq.TLO.Macro.Variable('CampYLoc')()
		returnLoc.z = mq.TLO.Macro.Variable('CampZLoc')()
		where = 'Kissassist camp'
	elseif mq.TLO.Me.Fellowship.Campfire() and mq.TLO.Me.Fellowship.CampfireZone() == mq.TLO.Zone() then
		returnLoc.x = mq.TLO.Me.Fellowship.CampfireX()
		returnLoc.y = mq.TLO.Me.Fellowship.CampfireY()
		returnLoc.z = mq.TLO.Me.Fellowship.CampfireZ()
		where = 'campfire'
	else
		returnLoc.x = mq.TLO.Me.X()
		returnLoc.y = mq.TLO.Me.Y()
		returnLoc.z = mq.TLO.Me.Z()
		where = 'starting location'
	end
end

local function campCorpseDist(id)
	corpseLocation.x = mq.TLO.Spawn(id).X()
	corpseLocation.y = mq.TLO.Spawn(id).Y()
	corpseLocation.z = mq.TLO.Spawn(id).Z()
	setLoc()
	local x = math.abs(returnLoc.x - corpseLocation.x)
	local y = math.abs(returnLoc.y - corpseLocation.y)
	local z = math.abs(returnLoc.z - corpseLocation.z)
	if x > 50 or y > 50 or z > 50 then
		return true
	end
end

local function checkForDead(n)
	local groupMembers = mq.TLO.Group.Members()
	local pcCorpses = mq.TLO.SpawnCount('pccorpse')()
	local found = false
	if groupMembers > 0 and pcCorpses > 0 then
		for i = 1, groupMembers do
			if pause == true then break end
			local groupMember = mq.TLO.Group.Member(i).Name()
			local corpseName = groupMember..'\'s corpse'
			for j = 1, pcCorpses do
				if pause == true then break end
				local pcCorpse = mq.TLO.NearestSpawn(j..',pccorpse').CleanName()
				local corpseID = mq.TLO.NearestSpawn(j..',pccorpse').ID()
				if pcCorpse == corpseName then
					found = true
					if campCorpseDist(corpseID) then
						if mq.TLO.Navigation.PathExists('id '..corpseID)() then
							dragCorpse(corpseID, corpseName)
						else 
							print('\at[LeRogue] \ayCan\'t find path to ', corpseName)
							print('\at[LeRogue] \ayTurning auto-drag off to avoid loop')
							updateSettings('dragcorpses', 'off') boolizeSettings()
						end
					end
				end
			end
		end
	end
	if n == 'notify' and not found then
		print('\at[LeRogue] \ayCan\'t find any corpses in this zone')
	end
end

local function manualDragCorpse(val)
	if not goodToGo() or engaged() or mq.TLO.Me.XTarget() > 0 then
		print('\at[LeRogue] \ayToo busy right now...')
		return
	end
	
	local corpseName
	local corpseID
	if val then
		corpseName = val:gsub("^%l", string.upper)..'\'s corpse'
	elseif mq.TLO.Target.Name() and mq.TLO.Target.Type() == 'PC' then
		corpseName = mq.TLO.Target.Name()..'\'s corpse'
	elseif mq.TLO.Target.Name() and mq.TLO.Target.Type() == 'Corpse' then
		corpseID = mq.TLO.Target.ID()
		corpseName = mq.TLO.Target.CleanName()
	else
		checkForDead('notify')
		return
	end
	if mq.TLO.SpawnCount(corpseName)() == 0 then
		print('\at[LeRogue] \ayCan\t find any corpses in this zone')
		return
	end
	corpseID = mq.TLO.NearestSpawn(corpseName).ID()
	if campCorpseDist(corpseID) then
		
		dragCorpse(corpseID, corpseName)
	else
		print('\at[LeRogue] \ayLooks like that corpse is already at camp')
	end
end

----------------------------Handle binds--------------------------------------

local function binds(cmd, val)
	if cmd == 'pause' then togglePause(val)
	elseif cmd == 'dragcorpse' then manualDragCorpse(val)
	elseif cmd == 'resetdefaults' then setDefaults('all')
	elseif cmd == 'minlevel' then newMinLvl(val)
	elseif cmd == 'pausehide' then pauseHide(val)	
	elseif cmd == 'addclicky' then
		if val == 'burn' then addBurnClicky() 
		elseif val == 'combat' then addClicky()
		else print('\at[LeRogue] \ayPlease use /lr addclicky \agcombat\ay or \agburn') end
	elseif cmd == 'removeclicky' then removeClicky()
	elseif cmd == 'listclickies' then listClickies()
	elseif cmd == 'burn' then doBurn()
	elseif cmd == nil or cmd == 'help' then listCommands()
	elseif cmd ~= 'dot' 
		and cmd ~= 'hide' 
		and cmd ~= 'disc' 
		and cmd ~= 'combat' 
		and cmd ~= 'poison' 
		and cmd ~= 'summon' 
		and cmd ~= 'stayalive'
		and cmd ~= 'glyph' 
		and cmd ~= 'dragcorpses'
		and cmd ~= 'ligament'
		and cmd ~= 'burnalways' then
		print('\at[LeRogue]\ay Invalid command. Type /lr help for a list.')
	elseif (val ~= 'on' and val ~= 'off') or val == nil then
		print('\at[LeRogue]\ay Please use on/off')
	else updateSettings(cmd, val) boolizeSettings() end
end
mq.bind('/lr', binds)

-----------------------------GUI----------------------------------------------

local function boolSwitch()
	for k,v in pairs(boolSettings) do
		if boolSettings[k] == true and rogSettings[k] =='off' then
			updateSettings(k,'on')
		elseif boolSettings[k] == false and rogSettings[k] == 'on' then
			updateSettings(k, 'off')
		end
	end
end

local burnNow
local dragNow
local lvlUpdated
local Open, ShowUI = true, true
local function buildLrWindow()
	local update
	ImGui.SetWindowSize(240, 500, ImGuiCond.Once)
	local x, y = ImGui.GetContentRegionAvail()
	local buttonHalfWidth = (x / 2) - 4
	local buttonThirdWidth = (x / 4) - 1
	
    if ImGui.Button('Pause') then togglePause() end
    ImGui.SameLine()
    if pause == false then ImGui.TextColored(0, .75, 0, 1, 'Running '..version) else ImGui.TextColored(.75, 0, 0, 1, 'Paused') end

    ImGui.Separator()

    boolSettings.combat, update = ImGui.Checkbox('Combat abilities', boolSettings.combat)
	if update then boolSwitch() end

    boolSettings.disc, update = ImGui.Checkbox('Rotating discs', boolSettings.disc)
	if update then boolSwitch() end

    boolSettings.dot, update = ImGui.Checkbox('DoTs', boolSettings.dot)
	if update then boolSwitch() end

	boolSettings.ligament, update = ImGui.Checkbox('Ligament slice', boolSettings.ligament)
	if update then boolSwitch() end

    ImGui.Text('Add/remove clickies')
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 4)
    if ImGui.Button('Combat', buttonThirdWidth, 0) then addClicky() end
	if (ImGui.IsItemHovered()) then
        ImGui.SetTooltip("Add clicky on cursor to combat routine.")
	end
    ImGui.SameLine()
	if ImGui.Button('Burn', buttonThirdWidth, 0) then addBurnClicky() end
	if (ImGui.IsItemHovered()) then
        ImGui.SetTooltip("Add clicky on cursor to burn routine.")
	end
    ImGui.SameLine()
    if ImGui.Button('Rem', buttonThirdWidth, 0) then removeClicky() end
	if (ImGui.IsItemHovered()) then
        ImGui.SetTooltip("Remove clicky on your cursor from LeRogue.")
	end
    ImGui.SameLine()
    if ImGui.Button('List', buttonThirdWidth, 0) then listClickies() end
	ImGui.PopStyleVar()
	ImGui.Separator()

    boolSettings.glyph, update = ImGui.Checkbox('Use glyphs', boolSettings.glyph)
	if update then boolSwitch() end

    boolSettings.burnalways, update = ImGui.Checkbox('Always burn', boolSettings.burnalways)
	if update then boolSwitch() end

	ImGui.Separator()

    boolSettings.stayalive, update = ImGui.Checkbox('Use defense', boolSettings.stayalive)
	if update then boolSwitch() end

    ImGui.Separator()

    boolSettings.poison, update = ImGui.Checkbox('Apply poison', boolSettings.poison)
	if update then boolSwitch() end

    boolSettings.summon, update = ImGui.Checkbox('Summon poison', boolSettings.summon)
	if update then boolSwitch() end
    
    ImGui.Separator()
	
    rogSettings.minlevel, update = ImGui.SliderInt('Min lvl', rogSettings.minlevel, 1, 120)
	if update then lvlUpdated = true end
	if lvlUpdated == true and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then 
		newMinLvl(rogSettings.minlevel) 
		lvlUpdated = false
	end

    ImGui.Separator()

    boolSettings.hide, update = ImGui.Checkbox('Auto-hide', boolSettings.hide)
	if update then boolSwitch() end
	ImGui.SameLine()
	if mq.TLO.Me.Invis('SOS')() then 
		ImGui.TextColored(0, .75, .75, 1, '\xee\xa3\xb4'..' Hidden') 
	else
		ImGui.TextColored(0, .75, .75, 1, '\xee\xa3\xb5'..' Visible') 
	end

    if ImGui.Button('Pause hide 20', buttonHalfWidth, 0) then pauseHide(20) end
    ImGui.SameLine()
    if ImGui.Button('Pause hide 60', buttonHalfWidth, 0) then pauseHide(60) end

    ImGui.Separator()
	
	boolSettings.dragcorpses, update = ImGui.Checkbox('Auto drag corpses', boolSettings.dragcorpses)
	if update then boolSwitch() end
	ImGui.SameLine()
	ImGui.Text('\xee\xa3\xbd')
	if (ImGui.IsItemHovered()) then
        ImGui.SetTooltip("Automatically drag group corpses if you have a KA camp or campfire set.")
	end
    if ImGui.Button('Drag corpse', buttonHalfWidth, 0) then dragNow = true end
	if (ImGui.IsItemHovered()) then
        ImGui.SetTooltip("Drag your target's corpse to camp or current location.")
	end
	ImGui.SameLine()
	ImGui.PushStyleColor(ImGuiCol.Button, .61, .0, .0, .75)
	if ImGui.Button('Burn now', buttonHalfWidth, 0) then burnNow = true end
	ImGui.PopStyleColor()
	
end

local function lrWindow()
    Open, ShowUI = ImGui.Begin('LeRogue', Open)
    if ShowUI then
        buildLrWindow()
    end
    ImGui.End()
end

mq.imgui.init('LeRogue', lrWindow)

----------------------------Start loop----------------------------------------

local terminate = false
while not terminate do
	if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then break end
	if pause == true then 
		local function stop() return pause == false end
		print('\at[LeRogue] \arPAUSED (type /lr pause to unpause)')
		mq.delay(30000, stop)
	end
	if pause == false then
		mq.doevents()
		local currentTime = os.time()

		if rogSettings.stayalive == 'on' and goodToGo() then stayAlive() end
		if mq.TLO.Cursor.ID() == poison then mq.cmd('/autoinv') mq.delay(500) end
		
		--combat
		if engaged() and rogSettings.combat == 'on' then 
			doCombatAbilies()
			doDebuffs()
			doClickies()
		end
		if engaged() and rogSettings.disc == 'on' then doDiscs() end
		if engaged() and rogSettings.dot == 'on' then doDots() end
		if engaged() and rogSettings.burnalways == 'on' then keepBurning() end
		if engaged() then doOther() end
		if burnNow == true then doBurn() burnNow = false end

		if not engaged() and goodToGo() and mq.TLO.Me.PctEndurance() < 18 then
			breathe()
		end

		--rebuff
		if safeToCast() then
			reflexes()
			if rogSettings.poison == 'on' then applyPoison() end
			if rogSettings.summon == 'on' then summonPoison() end
		end

		--autohide
		if rogSettings.hide == 'on' and not engaged() then
			autoHide()
		elseif rogSettings.hide == 'paused' and currentTime >= myTimer then
			rogSettings.hide = 'on'
			print('\at[LeRogue] \agHide is back on')
		end

		--corpse pulling
		if mq.TLO.Macro.Variable('ReturnToCamp')() == 1 or (mq.TLO.Me.Fellowship.Campfire() and mq.TLO.Me.Fellowship.CampfireZone() == mq.TLO.Zone()) then
			campUp = true
		else
			campUp = false
		end
		if rogSettings.dragcorpses == 'on' and campUp == true and mq.TLO.Me.XTarget() < 1 then checkForDead() end
		if dragNow == true then manualDragCorpse() dragNow = false end
	end
	if not Open then return end
end