--LeRogue.lua
--by Rawmotion
local version = 'v1.1.0'
local mq = require('mq')
local rogSettings = {} -- initialize config tables
local rogClickies = {}
local rogPath = 'LeRogueConfig.lua' -- name of config file in config folder

--Combat abilities and aas
local myCombatAbilities = { 
	mq.TLO.Spell('shadowstrike').RankName(),
	mq.TLO.Spell('ambuscade').RankName(),
	mq.TLO.Spell('disorienting puncture').RankName(),
	mq.TLO.Spell('obfuscated blade').RankName(),
	mq.TLO.Spell('ecliptic weapons').RankName(),
	1506,
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

local function saveSettings()
	mq.pickle(rogPath, { rogSettings=rogSettings, rogClickies=rogClickies })
end

local function updateSettings(cmd, val)
	rogSettings[cmd] = val
	print('\at[LeRogue] \aoTurning \ay', cmd, ' \ag ', val)
	mq.delay(250)
	saveSettings()
end

local function listCommands()
	print('\at[LeRogue] \aw---\aoAvailable commands\aw:')
	print('\at[LeRogue] \ay Type /lr help (or just /lr) to repeat this list')
	print('\at[LeRogue] \ay /lr pause (toggles pause)')
	print('\at[LeRogue] \ay /lr pause on/off (turn pause on or off)')
	print('\at[LeRogue] \ay /lr combat on/off (uses combat abilities)')
	print('\at[LeRogue] \ay /lr disc on/off (rotates discs)')
	print('\at[LeRogue] \ay /lr dot on/off (uses dots)')
	print('\at[LeRogue] \ay /lr hide on/off (keeps you hidden)')
	print('\at[LeRogue] \ay /lr pausehide x (pauses autohide for x seconds then resumes)')
	print('\at[LeRogue] \ay /lr stayalive on/off (uses defensive abilities to no die)')
	print('\at[LeRogue] \ay /lr poison on/off (reapplies poison when it\'s safe)')
	print('\at[LeRogue] \ay /lr summon on/off (summons poison when it\'s safe)')
	print('\at[LeRogue] \ay /lr clickies on/off (uses combat clickies)')
	print('\at[LeRogue] \ay /lr glyph on/off (uses power glyph during burn)')
	print('\at[LeRogue] \ay /lr addclicky (adds a clicky on your cursor to combat routine)')
	print('\at[LeRogue] \ay /lr removeclicky (removes a clicky on your cursor from combat routine)')
	print('\at[LeRogue] \ay /lr listclickies (shows clickies you\'ve added)')
	print('\at[LeRogue] \ay /lr burn (burn target)')
end

local function setup()
	local configData, err = loadfile(mq.configDir..'/'..rogPath) -- read config file
	if err then -- failed to read the config file, create it using pickle	    
	    rogSettings.dot = 'on'
		rogSettings.hide = 'on'
		rogSettings.disc = 'on'
		rogSettings.combat = 'on'
		rogSettings.clickies = 'on'
		rogSettings.poison = 'on'
		rogSettings.summon = 'on'
		rogSettings.stayalive = 'on'
		rogSettings.glyph = 'on'
	    saveSettings()
	    print('\at[LeRogue] \ay Creating config file...')  
	    print('\at[LeRogue] \ay Welcome to LeRogue.lua ', version)	    
	    print('\at[LeRogue] \aw---\ayToggles are currently set to\aw:')
		for k,v in pairs(rogSettings) do print('\at[LeRogue] \ao ',k,": \ay",v) end  
		listCommands()
	elseif configData then -- file loaded, put content into your config table
	    rogSettings = configData().rogSettings
	    rogClickies = configData().rogClickies
	    -- print the contents
	    print('\at[LeRogue] \ay Welcome to LeRogue.lua ', version)
	    print('\at[LeRogue] \aw---\ayToggles are currently set to\aw:')
		for k,v in pairs(rogSettings) do print('\at[LeRogue] \ao ',k,": \ay",v) end
		listCommands()
	end
end
setup()

local function addClicky(cmd,val)
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

local function removeClicky(cmd,val)
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

local function notNil(arg)
	if arg ~= nil then
		return arg
	else
		return 0			
	end
end

local function goodToGo() --Checks whether you can perform actions
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

local function engaged() --Checks whether in combat with NPC lvl 110+
	return goodToGo()
	and mq.TLO.Target.ID() ~= 0 
	and notNil(mq.TLO.Target.Distance()) < 18 
	and	notNil(mq.TLO.Target.Distance()) > 0 
	and notNil(mq.TLO.Target.Level()) > 110 
	and mq.TLO.Target.Type() == 'NPC' 
	and mq.TLO.Me.Combat() 
end	

local function safeToCast() --Checks whether it's safe to cast and rebuff
	return goodToGo()
	and not	mq.TLO.Me.Moving()
	and mq.TLO.SpawnCount('npc radius 60')() < 1 
	and mq.TLO.Me.XTarget() < 1 
	and mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() == nil 
	and mq.TLO.Me.Song('Evader\'s Invisibility').ID() == nil 
	and mq.TLO.Me.Buff('Revival Sickness').ID() == nil 
	and not (mq.TLO.Me.PctHPs() < 26) 
end

--Helper function to manage delays
local function delayCombat(name)
	local function stop() return not mq.TLO.Me.CombatAbilityReady(name)() end
	mq.delay(3000, stop)
end

local function delayAlt(name)
	local function stop() return not mq.TLO.Me.AltAbilityReady(name)() end
	mq.delay(3000, stop)
end

local function delayItem(name)
	local function stop() return not mq.TLO.Me.ItemReady(name)() end
	mq.delay(3000, stop)
end

local function delayAbility(name)
	local function stop() return not mq.TLO.Me.AbilityReady(name)() end
	mq.delay(3000, stop)
end

local function doCombatAbilies()
	for k,v in pairs(myCombatAbilities) do
		local abyName = v
		if type(v) == 'number' and mq.TLO.Me.AltAbilityReady(v)() then --for aas
			mq.cmdf('/alt activate %s', v)
			abyName = mq.TLO.Spell(mq.TLO.AltAbility(v).Name()).RankName()
			delayAlt(v)
			print('\at[LeRogue] \aoUsing: \ar', abyName)
		elseif type(v) == 'string' and mq.TLO.Me.CombatAbilityReady(v)() then --for discs     
	        mq.cmdf('/disc %s', v)
	        delayCombat(v)
			print('\at[LeRogue] \aoUsing: \ar', abyName)
		end
	end
	if notNil(mq.TLO.Target.PctHPs()) > 20 then
		for k,v in pairs(myDebuffs) do
			local abyName = v
			if type(v) == 'number' and mq.TLO.Me.AltAbilityReady(v)() then --for aas
				mq.cmdf('/alt activate %s', v)
				abyName = mq.TLO.Spell(mq.TLO.AltAbility(v).Name()).RankName()
				delayAlt(v)
				print('\at[LeRogue] \aoUsing: \ar', abyName)
			elseif type(v) == 'string' and mq.TLO.Me.CombatAbilityReady(v)() then --for discs     
		        mq.cmdf('/disc %s', v)
		        delayCombat(v)
				print('\at[LeRogue] \aoUsing: \ar', abyName)
			end
		end
	end
end

local function doDots()
	if notNil(mq.TLO.Target.PctHPs()) > 20 then
		for k,v in pairs(myDots) do
			local dotName = v
			if type(v) == 'number' and mq.TLO.Me.AltAbilityReady(v)() then --for aas
				mq.cmdf('/alt activate %s', v)
				dotName = mq.TLO.Spell(mq.TLO.AltAbility(v).Name()).RankName()
				delayAlt(v)
				print('\at[LeRogue] \aoUsing Dot: \ay', dotName)
		  	elseif type(v) == 'string' and mq.TLO.Me.CombatAbilityReady(v)() then --for discs       
		        mq.cmdf('/disc %s', v)
		        delayCombat(v)
				print('\at[LeRogue] \aoUsing Dot: \ay', dotName)
		  	end		
		end
	end
end

local function doDiscs()
	for k,v in pairs(myDiscs) do		
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

local function doClickies()
	for k,v in pairs(rogClickies) do
		if mq.TLO.FindItemCount(v)() > 0 and mq.TLO.Me.ItemReady(v)() then
			mq.cmdf('/useitem "%s"', mq.TLO.FindItem(v).Name())
			delayItem(v)
			print('\at[LeRogue] \aoClicking: \ay', mq.TLO.FindItem(v).Name())
		end
	end
end

local function doBurn()
	if engaged() then
		print('\at[LeRogue] \arBUURRRRNNNNN!!!')
		if rogSettings.glyph == 'on' and mq.TLO.Me.AltAbilityReady(5304)() then
			mq.cmd('/alt activate 5304')
			delayAlt(5304)
			print('\at[LeRogue] \aoBurning: \ayPower Glyph')
		end
		for k,v in pairs(myBurn) do
			local burnName = v
			if type(v) == 'number' and mq.TLO.Me.AltAbilityReady(v)() then --for aas
				mq.cmdf('/alt activate %s', v)
				burnName = mq.TLO.Spell(mq.TLO.AltAbility(v).Name()).RankName()
				delayAlt(v)
				print('\at[LeRogue] \aoBurning: \ay', burnName)
			elseif type(v) == 'string' and mq.TLO.Me.CombatAbilityReady(v)() then --for discs        
		        mq.cmdf('/disc %s', v)
		        delayCombat(v)
				print('\at[LeRogue] \aoBurning: \ay', burnName)
			end
		end
		local r = 'Rage of Rolfron'
		if mq.TLO.FindItem(r)() and mq.TLO.Me.ItemReady(r)() then
			mq.cmdf('/useitem %s', r)
			delayItem(r)
			print('\at[LeRogue] \aoBurning: \ay', r)
		end
	else
		print('\at[LeRogue] \ayYou\'re not engaged. Cancelling burn.')
	end
end

local function doOther()
  	if mq.TLO.Me.AbilityReady('Disarm')() then
	    mq.cmd('/doability disarm')
	    delayAbility('disarm')
  	end
  	if mq.TLO.Me.AbilityReady('Hide')() then
	    mq.cmd('/doability hide')
	    delayAbility('hide')
  	end
  	if mq.TLO.Me.CombatAbilityReady(thief)() and not mq.TLO.Me.Song(thief)() then
  		local function stop() return mq.TLO.Me.Song(thief)() end
	    mq.cmdf('/disc %s', thief)
	    mq.delay(3000, stop)
  	end
  	if rogSettings.combat == 'on' and mq.TLO.Me.CombatAbilityReady(beguile)() and mq.TLO.Me.TargetOfTarget() ~= mq.TLO.Me.Name() then
	    mq.cmdf('/disc %s', beguile)
	    delayCombat(beguile)
	    print('\at[LeRogue] \aoUsing: \ar', beguile)
  	end
  	if mq.TLO.Me.CombatAbilityReady(calm)() and mq.TLO.Me.PctEndurance() < 10 then
        mq.cmdf('/disc %s', calm)
		delayCombat(calm)
		print('\at[LeRogue] \aoUsing: \ay', calm)
	end
end 

local function autoHide()
    if mq.TLO.Me.AbilityReady('Sneak')() and mq.TLO.Me.State() ~= 'MOUNT' and not mq.TLO.Me.Dead() then
    	mq.cmd('/doability sneak')
    	delayAbility('Sneak')
    end
    if mq.TLO.Me.AbilityReady('Hide')() and mq.TLO.Me.Sneaking() then
    	mq.cmd('/doability hide')
    	delayAbility('Hide')
    end
end

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
        mq.cmdf('/useitem "%s"', legs)
		print('\at[LeRogue] \aoClicking: \ay', legs)
		delayItem(legs)
	end
end

local function stayAlive()
	if mq.TLO.Me.XTarget() > 0 and not mq.TLO.Me.Song('Evader\'s Shroud of Stealth').ID() and goodToGo() then
	    -- Tumble
	    if mq.TLO.Me.PctHPs() < 75 and mq.TLO.Me.AltAbilityReady('673')() and goodToGo() then
	        mq.cmd('/alt activate 673')
	        delayAlt(673)
	        print('\at[LeRogue] \arOuch!! \ayUsing Tumble')
	    end
	    -- Tumble
	    if mq.TLO.Me.PctHPs() < 60 and mq.TLO.Me.AltAbilityReady('1134')() and goodToGo() then
	        mq.cmd('/alt activate 1134')
	        delayAlt(1134)
	        print('\at[LeRogue] \arOuch!! \ayUsing Assassin\'s Premonition')
	    end
	    -- Nimble
	    if mq.TLO.Me.PctHPs() < 40 and mq.TLO.Me.CombatAbilityReady('Nimble Discipline')() and goodToGo() then
	        mq.cmd('/stopdisc')
	        mq.delay(250)
	        mq.cmd('/disc Nimble Discipline')
	        delayCombat('Nimble Discipline')
	        print('\at[LeRogue] \arOuch!! \ayUsing Nible Discipline')
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
	        mq.cmd('/alt activate 102')
	        print('\at[LeRogue] \arOuch!! \ayUsing ESCAPE!')
	        delayAlt(102)
	    end
	end
end

local pause = false
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

local myTimer = 0
local function setTimer(d)
    local startTime = os.time()
    myTimer = startTime + d
end

--binds
local function binds(cmd, val)
	if cmd == 'pause' then togglePause(val)
	elseif cmd == 'pausehide' then
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
	elseif cmd == 'addclicky' then addClicky(cmd, val) 
	elseif cmd == 'removeclicky' then removeClicky(cmd, val)
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
		and cmd ~= 'glyph' then
		print('\at[LeRogue] \ay Invalid command')
	elseif (val ~= 'on' and val ~= 'off') or val == nil then
		print('\at[LeRogue] \ay Please use on/off')
	else updateSettings(cmd, val) end
end
mq.bind('/lr', binds)

local terminate = false
while not terminate do
	if pause == true then 
		local function stop() return pause == false end
		print('\at[LeRogue] \arPAUSED (type /lr pause to unpause)')
		mq.delay(30000, stop)
	end
	while not pause do
		local currentTime = os.time()
		while engaged() do
			if pause == true then break end
			if rogSettings.stayalive == 'on' and goodToGo() then stayAlive() end
			if rogSettings.combat == 'on' then doCombatAbilies() end
			if rogSettings.disc == 'on' then doDiscs() end
			if rogSettings.dot == 'on' then doDots() end
			if rogSettings.clickies == 'on' then doClickies() end
			doOther()
		end
		if safeToCast() then 
			reflexes() 
			if rogSettings.poison == 'on' then applyPoison() end
			if rogSettings.summon == 'on' then summonPoison() end
		end
		if rogSettings.hide == 'on' and not engaged() then 
			autoHide()
		elseif rogSettings.hide == 'paused' and currentTime >= myTimer then
			rogSettings.hide = 'on'
			print('\at[LeRogue] \agHide is back on')
		end
		if rogSettings.stayalive == 'on' and goodToGo() then stayAlive() end
		if mq.TLO.Cursor.ID() == poison.ID() then mq.cmd('/autoinv') mq.delay(500) end
	end
end