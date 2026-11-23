-- Dragging corpses back to camp (needs MQ2Nav).
-- Camp is your KissAssist camp, else your campfire in this zone, else where you stand.

--- @type Mq
local mq = require('mq')
local state = require('state')
local config = require('config')
local abilities = require('abilities')

local corpses = {}

local NAV_POLL_MS = 50     -- how often to check progress while navigating
local SCAN_EVERY_MS = 3000 -- how often auto-drag looks for group members' corpses
local nextScan = 0
local hasConsent = true
local pausedMacro = false  -- true while a macro is paused because of us

mq.event('consent', '#*#You do not have consent to summon that corpse.#*#', function()
	print('\at[LeRogue] \ayI don\'t have consent to drag this corpse.')
	hasConsent = false
end)

local function kissAssistCamp()
	return mq.TLO.Macro.Variable('ReturnToCamp')() == 1
end

local function campfireHere()
	return mq.TLO.Me.Fellowship.Campfire() and mq.TLO.Me.Fellowship.CampfireZone() == mq.TLO.Zone()
end

-- Where corpses go, and what to call that place
local function campLocation()
	if kissAssistCamp() then
		local v = mq.TLO.Macro.Variable
		return { x = v('CampXLoc')(), y = v('CampYLoc')(), z = v('CampZLoc')() }, 'Kissassist camp'
	elseif campfireHere() then
		local f = mq.TLO.Me.Fellowship
		return { x = f.CampfireX(), y = f.CampfireY(), z = f.CampfireZ() }, 'campfire'
	end
	return { x = mq.TLO.Me.X(), y = mq.TLO.Me.Y(), z = mq.TLO.Me.Z() }, 'starting location'
end

-- Is the corpse more than 50 units from camp (on any axis)?
local function awayFromCamp(id, camp)
	local corpse = mq.TLO.Spawn(id)
	local x, y, z = corpse.X(), corpse.Y(), corpse.Z()
	if x == nil then return false end
	return math.abs(camp.x - x) > 50 or math.abs(camp.y - y) > 50 or math.abs(camp.z - z) > 50
end

local function pauseMacro()
	if mq.TLO.Macro() and mq.TLO.Macro.Paused() == false then
		print('\at[LeRogue] \ayPausing macro')
		mq.cmd('/squelch /mqp on')
		pausedMacro = true
	end
end

local function resumeMacro()
	if pausedMacro and mq.TLO.Macro() and mq.TLO.Macro.Paused() == true then
		print('\at[LeRogue] \ayUnpausing macro')
		mq.cmd('/squelch /mqp off')
	end
	pausedMacro = false
end

-- Walk to a corpse, drag it to camp and drop it
local function drag(id, name, camp, campName)
	if not mq.TLO.Navigation.PathExists('id '..id)() then
		print('\at[LeRogue] \ayCan\'t find path to ', name)
		return
	end
	print('\at[LeRogue] \agGoing to pull ', name)
	config.set('hide', 'on')
	pauseMacro()
	mq.delay(2000)

	-- Walk to the corpse
	mq.cmdf('/squelch /nav id %s', id)
	while mq.TLO.Navigation.Active() do
		if state.paused then mq.cmd('/squelch /nav stop') resumeMacro() return end
		local distance = mq.TLO.Spawn(id).Distance()
		if distance == nil then -- rezzed, summoned or decayed
			mq.cmd('/squelch /nav stop')
			print('\at[LeRogue] \ayLost track of ', name)
			resumeMacro()
			return
		end
		if distance < 75 and mq.TLO.Spawn(id).LineOfSight() then
			mq.cmd('/squelch /nav stop')
			mq.cmdf('/target %s', name)
			mq.cmd('/corpsedrag')
			break
		end
		mq.delay(NAV_POLL_MS)
	end

	hasConsent = true
	mq.delay(2000)
	mq.doevents()
	if not hasConsent then resumeMacro() return end

	-- Walk back and drop it
	mq.cmdf('/squelch /nav locxyz %s, %s, %s', camp.x, camp.y, camp.z)
	print('\at[LeRogue] \agBringing corpse back to your ', campName)
	while mq.TLO.Navigation.Active() do
		if state.paused then mq.cmd('/squelch /nav stop') break end
		local x, y, z = mq.TLO.Me.X(), mq.TLO.Me.Y(), mq.TLO.Me.Z()
		if x == nil then break end -- zoned or died on the way
		if math.abs(x - camp.x) < 10 and math.abs(y - camp.y) < 10 and math.abs(z - camp.z) < 10 then
			mq.cmd('/squelch /nav stop')
			mq.delay(1000)
			mq.cmd('/corpsedrop')
			break
		end
		mq.delay(NAV_POLL_MS)
	end
	resumeMacro()
end

-- Find group members' corpses away from camp and drag them back
local function dragGroupCorpses(notifyIfNone)
	local members = mq.TLO.Group.Members() or 0
	local corpseCount = mq.TLO.SpawnCount('pccorpse')() or 0
	local found = false
	for i = 1, members do
		if state.paused then break end
		local corpseName = (mq.TLO.Group.Member(i).Name() or '')..'\'s corpse'
		for j = 1, corpseCount do
			if state.paused then break end
			local corpse = mq.TLO.NearestSpawn(j..',pccorpse')
			if corpse.CleanName() == corpseName then
				found = true
				local id = corpse.ID()
				local camp, campName = campLocation()
				if awayFromCamp(id, camp) then
					if mq.TLO.Navigation.PathExists('id '..id)() then
						drag(id, corpseName, camp, campName)
					else
						print('\at[LeRogue] \ayCan\'t find path to ', corpseName)
						print('\at[LeRogue] \ayTurning auto-drag off to avoid loop')
						config.set('dragcorpses', 'off')
					end
				end
			end
		end
	end
	if notifyIfNone and not found then
		print('\at[LeRogue] \ayCan\'t find any corpses in this zone')
	end
end

-- Auto-drag, when a camp is set and nothing is on XTarget. Scanning every group
-- member against every corpse is costly, so it only runs every few seconds.
function corpses.autoDrag()
	if not config.isOn('dragcorpses') or mq.gettime() < nextScan then return end
	nextScan = mq.gettime() + SCAN_EVERY_MS
	if (kissAssistCamp() or campfireHere()) and (mq.TLO.Me.XTarget() or 0) < 1 then
		dragGroupCorpses(false)
	end
end

-- Drag a named player's corpse, your target's corpse, or else any group member's corpse
function corpses.dragManual(playerName)
	if not abilities.canAct() or abilities.engaged() or (mq.TLO.Me.XTarget() or 0) > 0 then
		print('\at[LeRogue] \ayToo busy right now...')
		return
	end

	local corpseName
	if playerName then
		corpseName = playerName:gsub('^%l', string.upper)..'\'s corpse'
	elseif mq.TLO.Target.Name() and mq.TLO.Target.Type() == 'PC' then
		corpseName = mq.TLO.Target.Name()..'\'s corpse'
	elseif mq.TLO.Target.Name() and mq.TLO.Target.Type() == 'Corpse' then
		corpseName = mq.TLO.Target.CleanName()
	else
		dragGroupCorpses(true)
		return
	end

	if mq.TLO.SpawnCount(corpseName)() == 0 then
		print('\at[LeRogue] \ayCan\'t find any corpses in this zone')
		return
	end
	local id = mq.TLO.NearestSpawn(corpseName).ID()
	local camp, campName = campLocation()
	if awayFromCamp(id, camp) then
		drag(id, corpseName, camp, campName)
	else
		print('\at[LeRogue] \ayLooks like that corpse is already at camp')
	end
end

return corpses
