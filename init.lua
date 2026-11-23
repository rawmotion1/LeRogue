--LeRogue.lua
--by Rawmotion
--
-- Files:
--   init.lua       startup and the main loop (this file)
--   config.lua     settings, saved per character
--   state.lua      runtime flags shared between files (pause, burn/drag requests, ...)
--   spelldata.lua  which abilities this character has, best rank first
--   abilities.lua  how any ability is checked and used, and the "can I act?" checks
--   routines.lua   combat rotation, burns, defense, endurance, rebuffs, poison, auto-hide
--   corpses.lua    dragging corpses to camp
--   commands.lua   the /lr command and clickies
--   gui.lua        the window

--- @type Mq
local mq = require('mq')

if mq.TLO.Me.Class() ~= 'Rogue' then
	print('\at[LeRogue]\ay Welcome to... Wait, you\'re not a rogue!')
	print('\aoLeRogue vanishes and you notice your purse feels lighter.')
	mq.exit()
end

local config = require('config')
local state = require('state')
local routines = require('routines')
local corpses = require('corpses')
local commands = require('commands')
local gui = require('gui')

config.load()
commands.help()
commands.register()
gui.register()

-- Pacing. Game data only refreshes once per frame, so running the loop again within the
-- same frame can't fire an ability any sooner. Waiting one frame in a fight costs no DPS
-- but stops the script from using CPU for nothing.
local FIGHT_WAIT_MS = 1   -- in a fight: wait for the next frame, then go again
local IDLE_WAIT_MS = 100  -- otherwise: about 10 passes a second, but wake at once when needed

local function inFight()
	return mq.TLO.Me.Combat() or (mq.TLO.Me.XTarget() or 0) > 0
end

-- Ends the idle wait early, so turning on attack or pressing a button reacts the next frame
local function somethingToDo()
	return state.paused or state.burnRequested or state.dragRequest ~= nil or inFight()
end

-- One pass of everything LeRogue does
local function runOnce()
	mq.doevents()
	if config.isOn('stayalive') then routines.stayAlive() end
	routines.stowPoison()

	local fighting = routines.fight()
	if state.burnRequested then
		state.burnRequested = false
		routines.burn()
	end

	routines.manageEndurance(fighting)
	routines.rebuff()
	routines.autoHide(fighting)
	if not fighting then commands.removeMissingClickies() end

	corpses.autoDrag()
	if state.dragRequest then
		local request = state.dragRequest
		state.dragRequest = nil
		corpses.dragManual(request.name)
	end
end

while state.windowOpen do
	if mq.TLO.MacroQuest.GameState() ~= 'INGAME' then break end

	if state.paused then
		print('\at[LeRogue] \arPAUSED (type /lr pause to unpause)')
		mq.delay(30000, function() return not state.paused end)
	elseif mq.TLO.Me.Zoning() then
		mq.delay(IDLE_WAIT_MS)
	else
		runOnce()
		if inFight() then
			mq.delay(FIGHT_WAIT_MS)
		else
			mq.delay(IDLE_WAIT_MS, somethingToDo)
		end
	end
end
