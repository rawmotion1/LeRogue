--LeRogue.lua
--by Rawmotion
local version = 'v2.0.1'
--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')


local rogSettings = {} -- initialize config tables
local boolSettings = {}
local rogClickies = {}
local rogPath = 'LeRogueConfig.lua' -- name of config file in config folder

--Combat abilities and aas
local myCombatAbilities = { 
	mq.TLO.Spell('shadowstrike').RankName(),
	mq.TLO.Spell('ambuscade').RankName(),
	mq.TLO.Spell('disorienting puncture').RankName(),
	mq.TLO.Spell('obfuscated blade').RankName(),
	mq.TLO.Spell('ecliptic weapons').RankName(),
	1506
}

local myDebuffs = {
	mq.TLO.Spell('foolish mark').RankName(),
	mq.TLO.Spell('pinpoint defects').RankName(),
	672
}

--Dots
local myDots = {
	mq.TLO.Spell('Jugular Rend').RankName(),
	mq.TLO.Spell('Lance').RankName(),
	670
}

--Rotating discs
local myDiscs = { 
	mq.TLO.Spell('Twisted Chance Discipline').RankName(),
	mq.TLO.Spell('Executioner Discipline').RankName(), 
	mq.TLO.Spell('Ragged Edge Discipline').RankName(),
	mq.TLO.Spell('Frenzied Stabbing Discipline').RankName(),
	mq.TLO.Spell('Knifeplay Discipline').RankName(),
	mq.TLO.Spell('Exotoxin Discipline').RankName(),
	mq.TLO.Spell('Weapon Covenant').RankName()
}

--For a burn command
local myBurn = {
	3514,
	1410,
	378,
	mq.TLO.Spell('Netherbian Blade').RankName()
}

--Other stuff
local calm = mq.TLO.Spell('Night\'s Calming').RankName()
local reflex = mq.TLO.Spell('Practiced Reflexes').RankName()
local thief = mq.TLO.Spell('thief\'s sight').RankName()
local beguile = mq.TLO.Spell('beguile').RankName()
local poison = mq.TLO.FindItem('Consigned')
local legs = mq.TLO.Me.Inventory(18)
local rage = 86155
local pause = false
local myTimer = 0
local nimble = 'Nimble Discipline'

local function color(val)
	if val == 'on' then val = '\agon' 
	elseif val == 'off' then val = '\aroff'
	end
	return val
end

local function listCommands()
	print('\at[LeRogue] \aw---- \atAll available commands \aw----')
	print('\at[LeRogue] \ay \awType \ay/lr help \aw(or just \ay/lr\aw) to repeat this list')
	print('\at[LeRogue] \ay \awType \ay/lr resetdefaults \aw to reset all settings')

	print('\at[LeRogue] \ao Pausing the script:')
	print('\at[LeRogue] \ay /lr pause \aw(toggles pause)')
	print('\at[LeRogue] \ay /lr pause \agon\aw/\aroff\aw (turn pause on or off)')

	print('\at[LeRogue] \ao Combat settings:')
	print('\at[LeRogue] \ay /lr combat \agon\aw/\aroff\aw (uses combat abilities)')
	print('\at[LeRogue] \ay /lr disc \agon\aw/\aroff\aw (rotates discs)')
	print('\at[LeRogue] \ay /lr dot \agon\aw/\aroff\aw (uses dots)')
	print('\at[LeRogue] \ay /lr clickies \agon\aw/\aroff\aw (uses combat clickies)')

	print('\at[LeRogue] \aoBurn settings:')
	print('\at[LeRogue] \ay /lr burn \aw(big burn on target)')
	print('\at[LeRogue] \ay /lr glyph \agon\aw/\aroff\aw (uses power glyph during burn)')
	print('\at[LeRogue] \ay /lr burnalways \aw(always use burns)')

	print('\at[LeRogue] \ao Combat routine clickies:')
	print('\at[LeRogue] \ay /lr addclicky \aw(add clicky on cursor to routine)')
	print('\at[LeRogue] \ay /lr removeclicky \aw(remove clicky on cursor from routine)')
	print('\at[LeRogue] \ay /lr listclickies \aw(shows clickies you\'ve added)')

	print('\at[LeRogue] \ao Auto hide settings:')
	print('\at[LeRogue] \ay /lr hide \agon\aw/\aroff\aw (keeps you hidden)')
	print('\at[LeRogue] \ay /lr pausehide x \aw(be visible for x seconds then resume)')

	print('\at[LeRogue] \ao Defense settings:')
	print('\at[LeRogue] \ay /lr stayalive \agon\aw/\aroff\aw (use defense abilities in emergency)')

	print('\at[LeRogue] \ao Poison settings:')
	print('\at[LeRogue] \ay /lr poison \agon\aw/\aroff\aw (reapplies poison when it\'s safe)')
	print('\at[LeRogue] \ay /lr summon \agon\aw/\aroff\aw (summons poison when it\'s safe)')

	print('\at[LeRogue] \ao Min NPC lvl to use combat abilities:')
	print('\at[LeRogue] \ay /lr minlevel \aox \aw(default is 110)')

	print('\at[LeRogue] \ao Pulling corpses:')
	print('\at[LeRogue] \ay /lr fetchcorpse \aoname \ayor \aotarget \aw(find and bring it back)')
	print('\at[LeRogue] \ay /lr bringcorpse \aoname \ayor \aotarget \aw(find and deliver to owner)')
end

-------------------------Handle settings----------------------------------------

local function saveSettings()
	mq.pickle(rogPath, { rogSettings=rogSettings, rogClickies=rogClickies })
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
	if s == 'all' or rogSettings.minlevel == nil then rogSettings.minlevel = 110 end
	for k,v in pairs(rogSettings) do print('\at[LeRogue] \ao ',k,": \ay",color(v)) end
	saveSettings()
end

local function setup()
	local configData, err = loadfile(mq.configDir..'/'..rogPath) -- read config file
	if err then -- failed to read the config file, create it using pickle	    
	    print('\at[LeRogue] \ay Creating config file...')  
	    print('\at[LeRogue] \ay Welcome to LeRogue.lua ', version)	    
		setDefaults('all')
		listCommands()
	elseif configData then -- file loaded, put content into your config table
	    rogSettings = configData().rogSettings
	    rogClickies = configData().rogClickies
	    print('\at[LeRogue] \ay Welcome to LeRogue.lua ', version)
	    print('\at[LeRogue] \aw---- \atToggles are currently set to \aw----')
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
		print('\at[LeRogue] \ay Specify a number between 1 and 120')
	elseif val < 1 or val > 120 then
		print('\at[LeRogue] \ay Specify a number between 1 and 120')
	else
		rogSettings.minlevel = val 
		print('\at[LeRogue] \ay Min NPC lvl for combat is now \ag' , val)
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
		for k,v in pairs(rogClickies) do
			if v == id.ID() then
				print('\at[LeRogue] \ayAlready added')
				return
			end
		end
		table.insert(rogClickies, id.ID())
		mq.delay(250)
		saveSettings()
		print('\at[LeRogue] \ayAdded clicky: \ag', id.Name())
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
				mq.delay(250)
				saveSettings()
				print('\at[LeRogue] \ayClicky removed')	
			end
		end
	end
end

local function listClickies()
	for k,v in pairs(rogClickies) do
		print('\at[LeRogue] \ay ', mq.TLO.FindItem(v).Name())
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

local function execute(name, kind)
	if type(name) == 'string' then 
		if name == 'hide' or name == 'sneak' or name == 'disarm' then --it's an ability
            if mq.TLO.Me.AbilityReady(name)() then
                mq.cmdf('/doability %s', name)
                local function stop() return not mq.TLO.Me.AbilityReady(name)() end
                mq.delay(3000, stop)
            end
		else --it's a disc
            if mq.TLO.Me.CombatAbilityReady(name)() then
                mq.cmdf('/disc %s', name)
                if kind == 'dot' then
                    print('\at[LeRogue] \aoUsing DoT: \ay', name)
                elseif kind == 'burn' then
                    print('\at[LeRogue] \aoBurning: \ay', name)
				elseif kind == 'live' then
					print('\at[LeRogue] \arOuch!! \ayUsing ', name)
                else
                    print('\at[LeRogue] \aoUsing: \ar', name)
                end
                local function stop() return not mq.TLO.Me.CombatAbilityReady(name)() end
                mq.delay(3000, stop)
            end
		end
	elseif type(name) == 'number' then
		if mq.TLO.FindItemCount(name)() > 0 then --it's a clicky
            if mq.TLO.Me.ItemReady(name)() then
                mq.cmdf('/useitem "%s"', mq.TLO.FindItem(name).Name())
                print('\at[LeRogue] \aoClicking: \ay', mq.TLO.FindItem(name).Name())
                local function stop() return not mq.TLO.Me.ItemReady(name)() end
                mq.delay(3000, stop)
            end
		else --it's an aa
            if mq.TLO.Me.AltAbilityReady(name)() then
                mq.cmdf('/alt activate %s', name)
                local cleanName = mq.TLO.Spell(mq.TLO.AltAbility(name).Name()).RankName()
                if kind == 'dot' then
                    print('\at[LeRogue] \aoUsing DoT: \ay', cleanName)
                elseif kind == 'burn' then
                    print('\at[LeRogue] \aoBurning: \ay', cleanName)
				elseif kind == 'live' then
					print('\at[LeRogue] \arOuch!! \ayUsing ', cleanName)    
                else
                    print('\at[LeRogue] \aoUsing: \ar', cleanName)
                end
                local function stop() return not mq.TLO.Me.AltAbilityReady(name)() end
                mq.delay(3000, stop) 
            end
		end
	end
end

local function doCombatAbilies()
	for k,v in pairs(myCombatAbilities) do
		if not engaged() or pause == true then break end
		execute(v)
	end
	if notNil(mq.TLO.Target.PctHPs()) > 20 then
		for k,v in pairs(myDebuffs) do
			if not engaged() or pause == true then break end
			execute(v)
		end
	end
end

local function doDots()
	if notNil(mq.TLO.Target.PctHPs()) > 20 then
		for k,v in pairs(myDots) do
			if not engaged() or pause == true then break end
			execute(v, 'dot')
		end
	end
end

local function doClickies()
	for k,v in pairs(rogClickies) do
		if not engaged() or pause == true then break end
		execute(v)
	end
end

local function doDiscs()
	for k,v in pairs(myDiscs) do
		if not engaged() or pause == true then break end	
		if mq.TLO.Me.ActiveDisc() then return
		elseif v == 'Knifeplay Discipline' and mq.TLO.Me.Song('Rogue\'s Fury')() ~= nil then
			-- do nothing			
	  	elseif mq.TLO.Me.CombatAbilityReady(v)() then     
	        repeat
				mq.cmdf('/disc %s', v)
				mq.delay(250)
			until mq.TLO.Me.ActiveDisc() == v
			print('\at[LeRogue] \ao Starting: \ay', v)
	  	end		
	end
end

local function doOther()
    if not engaged() or pause == true then return end
  	execute('disarm')
    execute('hide')
    if rogSettings.combat == 'on' and mq.TLO.Me.TargetOfTarget() ~= mq.TLO.Me.Name() then
	    execute(beguile)
  	end
    if mq.TLO.Me.PctEndurance() < 10 then
		execute(calm)
	end
  	if mq.TLO.Me.CombatAbilityReady(thief)() and not mq.TLO.Me.Song(thief)() then
  		local function stop() return mq.TLO.Me.Song(thief)() end
	    mq.cmdf('/disc %s', thief)
	    mq.delay(3000, stop)
  	end
end 

local function doBurn()
	if engaged() then
		print('\at[LeRogue] \arBUURRRRNNNNN!!!')
		for k,v in pairs(myBurn) do
			if not engaged() or pause == true then break end
			execute(v, 'burn')
		end
        if rogSettings.glyph == 'on' then
			if not engaged() or pause == true then return end
			execute(5304, burn)
		end
		if mq.TLO.FindItem(rage)() then
            if not engaged() or pause == true then return end
			execute(rage)
		end
	else
		print('\at[LeRogue] \ayYou\'re not engaged. Cancelling burn.')
	end
end

local function keepBurning()
    for k,v in pairs(myBurn) do
        if not engaged() or pause == true then break end
        execute(v, 'burn')
    end
    if mq.TLO.FindItem(rage)() then
        if not engaged() or pause == true then return end
        execute(rage)
    end
end

------------------------------Safe to cast -----------------------------

local function reflexes()
	if mq.TLO.Me.Buff(reflex).ID() == nil then
		local function stop() return mq.TLO.Me.Buff(reflex)() end
        mq.cmdf('/disc %s', reflex)
        mq.delay(3000, stop)
		print('\at[LeRogue] \aoUsing: \ay', reflex)
	end
end

local function applyPoison()
	poisonN = poison.Name()
	if mq.TLO.FindItemCount(poisonN)() > 0 and mq.TLO.Me.Buff(mq.TLO.FindItem(poisonN).Clicky()).ID() == nil then
		local function stop() return mq.TLO.Me.Buff(mq.TLO.FindItem(poisonN).Clicky()).ID() end
        mq.cmdf('/useitem "%s"', poisonN)
        print('\at[LeRogue] \aoClicking: \ay', poisonN)
        mq.delay(3000, stop)
	end
end

local function summonPoison()
	if legs.Clicky() and mq.TLO.Me.ItemReady(legs)() and mq.TLO.FindItemCount(poison)() < 20 then
		local function stop() return not mq.TLO.Me.ItemReady(legs)() end
		mq.cmdf('/useitem "%s"', legs)
        print('\at[LeRogue] \aoClicking: \ay', legs)
        mq.delay(3000, stop)
	end
end

----------------------------Emergency stay alive--------------------------

local function stayAlive()
	if mq.TLO.Me.XTarget() > 0 and not mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() and goodToGo() then
	    -- Tumble
	    if mq.TLO.Me.PctHPs() < 75 and mq.TLO.Me.PctHPs() > 59 and goodToGo() then execute(673, 'live') end
	    -- Premonition
	    if mq.TLO.Me.PctHPs() < 60 and mq.TLO.Me.PctHPs() > 39 and goodToGo() then execute(1134, 'live') end
	    -- Nimble
	    if mq.TLO.Me.PctHPs() < 40 and mq.TLO.Me.PctHPs() > 19 and goodToGo() and mq.TLO.Me.CombatAbilityReady(nimble)() then
	        if mq.TLO.Me.ActiveDisc() ~= nil and mq.TLO.Me.ActiveDisc() ~= nimble then 
				mq.cmd('/stopdisc')
				mq.delay(500)
			end
	        repeat
				mq.cmdf('/disc %s', nimble)
				mq.delay(250)
				if not mq.TLO.Me.CombatAbilityReady(nimble)() then break end
			until mq.TLO.Me.ActiveDisc() == nimble
			print('\at[LeRogue] \arOuch!! \ayUsing ', nimble)
	    end
	    -- Escape
	    if mq.TLO.Me.PctHPs() < 20 and mq.TLO.Me.AltAbilityReady('102')() and goodToGo() then
	        mq.cmd('/backoff')
	        mq.cmd('/end')
	        mq.cmd('/attack off')
	        mq.cmd('/afollow off')
	        mq.cmd('/stick off')
	        mq.cmd('/moveto off')
	        mq.cmd('/nav stop')
	        mq.cmd('/play off')
	        mq.delay(250)
	        execute(102, 'live')
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
		print('\at[LeRogue] \ay Please specify seconds (e.g. 30 for 30 seconds)')
		return
	end
	if rogSettings.hide == 'off' then
		print('\at[LeRogue] \ay Pausehide only works when autohide is on')
	elseif rogSettings.hide == 'paused' then
		print('\at[LeRogue] \ay Hide is already paused!')
	elseif val > 300 then
		print('\at[LeRogue] \ay Max value is 300')	
	else	
		setTimer(val)
		mq.cmd('/makemevisible')
		rogSettings.hide = 'paused'
		print('\at[LeRogue] \ay Hide paused for ', val, ' seconds')
	end
end

--------------------------Fetch corpse routine--------------------------------

local bringOrFetch
local pickItUp
local bringItBack
local putItDown
local playerToFetch
local bringID
local corpseName
local fetchLocation = {}

local function fetchCorpse(val, dest)

	if not goodToGo() or engaged() or mq.TLO.Me.XTarget() > 0 then
		print('\at[LeRogue] \ayToo busy right now...')
		return
	end

	if val then
		playerToFetch = val:gsub("^%l", string.upper)
		
		if dest == 'bring' then --If using bring, check if player is in the zone
			local function findPlayer(spawn)
				return spawn.Type() == 'PC' and spawn.Name() == playerToFetch
			end
			local ids = mq.getFilteredSpawns(findPlayer)
			if ids[1] == nil then
				print('\at[LeRogue] \ayYou can only bringcorpse to players in the zone. Try /lr fetchcorpse instead.')
				return
			else 
				bringID = ids[1].ID()
			end 
		end

	elseif mq.TLO.Target.Name() and mq.TLO.Target.Type() == 'PC' then
		playerToFetch = mq.TLO.Target.Name()
		bringID = mq.TLO.Target.ID()
	else
		print('\at[LeRogue] \ayPlease target a player or specify a name')
		return
	end
	corpseName = playerToFetch..'\'s corpse'
	if mq.TLO.SpawnCount(corpseName)() == 0 then
		print('\at[LeRogue] \ayCan\t find any corpses in this zone')
		return
	else
		bringOrFetch = dest
		if bringOrFetch == 'fetch' then
			fetchLocation.X = mq.TLO.Me.X()
			fetchLocation.Y = mq.TLO.Me.Y()
			fetchLocation.Z = mq.TLO.Me.Z()
		end
		print('\at[LeRogue] \ayTracking down ', corpseName)
		updateSettings('hide', 'on')
		if mq.TLO.Macro() and mq.TLO.Macro.Paused() == false then
			mq.cmd('/mqp on')
		end
		mq.delay(1000)
		mq.cmdf('/nav spawn %s', corpseName)
		pickItUp = true
	end
end

local function pickUpCorpse()
	pickItUp = false
	print('\at[LeRogue] \ayI found ', corpseName)
	mq.delay(1000)
	mq.cmdf('/target %s', corpseName)
	mq.delay(1000)
	mq.cmd('/corpsedrag')
	bringItBack = true
	mq.delay(2000)
end

local function returnCorpse()
	bringItBack = false
	if bringOrFetch == 'fetch' then
		mq.cmdf('/nav locxyz %s, %s, %s', fetchLocation.X, fetchLocation.Y, fetchLocation.Z)
	elseif mq.TLO.Spawn(bringID)() ~= nil then
		mq.cmdf('/nav id %s', bringID)
	else
		print('\at[LeRogue] \ayPlayer is no longer in the zone!')
		return
	end
	mq.delay(500)
	print('\at[LeRogue] \ayBringing corpse back')
	putItDown = true
end

local function dropCorpse()	
	if bringOrFetch == 'fetch' then
		local x = math.abs(mq.TLO.Me.X() - fetchLocation.X)
		local y = math.abs(mq.TLO.Me.Y() - fetchLocation.Y)
		local z = math.abs(mq.TLO.Me.Z() - fetchLocation.Z)
		if x < 10 and y < 10 and z < 10 then
			putItDown = false
			mq.delay(1000)
			mq.cmd('/corpsedrop')
			print('\at[LeRogue] \ayDropping corpse')
			if mq.TLO.Macro() and mq.TLO.Macro.Paused() == true then
				mq.cmd('/mqp off')
			end
		end
	elseif mq.TLO.Spawn(bringID).Distance() < 10 then
		putItDown = false
		mq.delay(1000)
		mq.cmd('/corpsedrop')
		print('\at[LeRogue] \ayDropping corpse')
		if mq.TLO.Macro() and mq.TLO.Macro.Paused() == true then
			mq.cmd('/mqp off')
		end
	end
end

----------------------------Handle events--------------------------------------

local function noConsent(line)
	print('\at[LeRogue] \ayI don\'t have consent do drag this corpse.')
	bringItBack = false
end
mq.event('consent', '#*#You do not have consent to summon that corpse.#*#', noConsent)

----------------------------Handle binds--------------------------------------

local function binds(cmd, val)
	if cmd == 'pause' then togglePause(val)
	elseif cmd == 'fetchcorpse' then fetchCorpse(val, 'fetch')
	elseif cmd == 'bringcorpse' then fetchCorpse(val, 'bring')
	elseif cmd == 'resetdefaults' then setDefaults('all')
	elseif cmd == 'minlevel' then newMinLvl(val)
	elseif cmd == 'pausehide' then pauseHide(val)	
	elseif cmd == 'addclicky' then addClicky() 
	elseif cmd == 'removeclicky' then removeClicky()
	elseif cmd == 'listclickies' then listClickies()
	elseif cmd == 'burn' then doBurn()
	elseif cmd == nil or cmd == 'help' then listCommands()
	elseif cmd ~= 'dot' 
		and cmd ~= 'hide' 
		and cmd ~= 'disc' 
		and cmd ~= 'combat' 
		and cmd ~= 'clickies' 
		and cmd ~= 'poison' 
		and cmd ~= 'summon' 
		and cmd ~= 'stayalive'
		and cmd ~= 'glyph' 
		and cmd ~= 'burnalways' then
		print('\at[LeRogue] \ay Invalid command')
	elseif (val ~= 'on' and val ~= 'off') or val == nil then
		print('\at[LeRogue] \ay Please use on/off')
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

local lvlUpdated
local Open, ShowUI = true, true
local function buildLrWindow()
	local update
	ImGui.SetWindowSize(220, 455, ImGuiCond.Once) 
	local x, y = ImGui.GetContentRegionAvail()
	local buttonHalfWidth = (x / 2) - 4
	local buttonThirdWidth = (x / 3) - 5

    if ImGui.Button('Pause') then togglePause() end
    ImGui.SameLine()
    if pause == false then ImGui.TextColored(0, .75, 0, 1, 'Running') else ImGui.TextColored(.75, 0, 0, 1, 'Paused') end

    ImGui.Separator()

    boolSettings.combat, update = ImGui.Checkbox('Combat abilities', boolSettings.combat)
	if update then boolSwitch() end

    boolSettings.disc, update = ImGui.Checkbox('Rotating discs', boolSettings.disc)
	if update then boolSwitch() end

    boolSettings.dot, update = ImGui.Checkbox('DoTs', boolSettings.dot)
	if update then boolSwitch() end

    boolSettings.clickies, update = ImGui.Checkbox('Combat clickies', boolSettings.clickies)
	if update then boolSwitch() end

    if ImGui.Button('Add clicky', buttonThirdWidth, 0) then addClicky() end
    ImGui.SameLine()
    if ImGui.Button('Remove', buttonThirdWidth, 0) then removeClicky() end
    ImGui.SameLine()
    if ImGui.Button('List all', buttonThirdWidth, 0) then listClickies() end

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
	
	
    if ImGui.Button('Fetch corpse', buttonHalfWidth, 0) then fetchCorpse(val, 'fetch') end
	
	ImGui.SameLine()
	ImGui.PushStyleColor(ImGuiCol.Button, .61, .0, .0, .75)
	if ImGui.Button('Burn now', buttonHalfWidth, 0) then doBurn() end
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
	if pause == true then 
		local function stop() return pause == false end
		print('\at[LeRogue] \arPAUSED (type /lr pause to unpause)')
		mq.delay(30000, stop)
	end
	if pause == false then
		mq.doevents()
		local currentTime = os.time()

		if rogSettings.stayalive == 'on' and goodToGo() then stayAlive() end
		if mq.TLO.Cursor.ID() == poison.ID() then mq.cmd('/autoinv') mq.delay(500) end
		
		--combat
		if engaged() and rogSettings.combat == 'on' then doCombatAbilies() end
		if engaged() and rogSettings.disc == 'on' then doDiscs() end
		if engaged() and rogSettings.dot == 'on' then doDots() end
		if engaged() and rogSettings.clickies == 'on' then doClickies() end
		if engaged() and rogSettings.burnalways == 'on' then keepBurning() end
		if engaged() then doOther() end

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

		--fetch corpse
		if pickItUp == true and goodToGo() and mq.TLO.SpawnCount(corpseName)() > 0 and notNil(mq.TLO.Spawn(corpseName).Distance()) < 10 then pickUpCorpse() end
		mq.doevents()
		if bringItBack == true and goodToGo() then returnCorpse() end
		if putItDown == true and goodToGo() then dropCorpse() end
		
	end
	if not Open then return end
end