-- The /lr command, clicky management and the help text

--- @type Mq
local mq = require('mq')
local state = require('state')
local config = require('config')
local routines = require('routines')

local commands = {}

-- Settings that /lr <name> on|off switches
local TOGGLES = {
	combat = true, disc = true, dot = true, ligament = true, intimidation = true,
	glyph = true, burnalways = true, stayalive = true, hiatus = true,
	poison = true, summon = true, hide = true, dragcorpses = true,
}

function commands.help()
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
	print('\at[LeRogue]\ay /lr intimidation \agon\aw/\aroff\aw (uses intimidation)')

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

	print('\at[LeRogue]\ao Defense and endurance settings:')
	print('\at[LeRogue]\ay /lr stayalive \agon\aw/\aroff\aw (use defense abilities in emergency)')
	print('\at[LeRogue]\ay /lr hiatus \agon\aw/\aroff\aw (use Hiatus line instead of Respite line)')

	print('\at[LeRogue]\ao Poison settings:')
	print('\at[LeRogue]\ay /lr poison \agon\aw/\aroff\aw (reapplies poison when it\'s safe)')
	print('\at[LeRogue]\ay /lr summon \agon\aw/\aroff\aw (summons poison when it\'s safe)')

	print('\at[LeRogue]\ao Min NPC lvl to use combat abilities:')
	print('\at[LeRogue]\ay /lr minlevel \aox \aw(default is 75)')

	print('\at[LeRogue]\ao Pulling corpses:')
	print('\at[LeRogue]\ay /lr dragcorpses \agon\aw/\aroff\aw (automatically drags group corpses if you have a camp set)')
	print('\at[LeRogue]\ay /lr dragcorpse \aoname \ayor \aotarget \aw(find and drag a corpse)')
end

function commands.togglePause(value)
	if value == 'on' then
		state.paused = true
	elseif value == 'off' or state.paused then
		state.paused = false
		print('\at[LeRogue] \agUNPAUSED')
	else
		state.paused = true
	end
end

function commands.setMinLevel(value)
	value = tonumber(value)
	if value == nil or value < 1 or value > 120 then
		print('\at[LeRogue]\ay Specify a number between 1 and 120')
		return
	end
	config.settings.minlevel = value
	print('\at[LeRogue]\ay Min NPC lvl for combat is now \ag', value)
	config.save()
end

------------------------------ Clickies ------------------------------

-- The clicky on your cursor: its item ID and name, or nil (with a message) if there isn't one
local function clickyOnCursor()
	local cursor = mq.TLO.Cursor
	if cursor.ID() == nil then
		print('\at[LeRogue] \ayPut a clicky on your cursor')
		return nil
	end
	if cursor.Clicky() == nil then
		print('\at[LeRogue] \ayThis is not a clicky')
		return nil
	end
	return cursor.ID(), cursor.Name()
end

local function contains(list, id)
	for _, v in ipairs(list) do
		if v == id then return true end
	end
	return false
end

-- Add the clicky on your cursor to the 'combat' or 'burn' routine. An item can only be in one.
function commands.addClicky(routine)
	local id, name = clickyOnCursor()
	if not id then return end
	local otherRoutine = routine == 'burn' and 'combat' or 'burn'
	local list = routine == 'burn' and config.burnClickies or config.combatClickies
	local otherList = routine == 'burn' and config.combatClickies or config.burnClickies

	if contains(list, id) then
		print('\at[LeRogue] \ayAlready added to '..routine..' routine.')
	elseif contains(otherList, id) then
		print('\at[LeRogue] \ayAlready in '..otherRoutine..' routine. Not adding to '..routine..' routine.')
	else
		table.insert(list, id)
		config.save()
		print('\at[LeRogue] \ayAdded clicky to '..routine..' routine: \ag', name)
	end
end

-- Remove the clicky on your cursor from both routines
function commands.removeClicky()
	local id = clickyOnCursor()
	if not id then return end
	for routine, list in pairs({ combat = config.combatClickies, burn = config.burnClickies }) do
		for i = #list, 1, -1 do
			if list[i] == id then
				table.remove(list, i)
				config.save()
				print('\at[LeRogue] \ayClicky removed from '..routine..' routine.')
			end
		end
	end
end

function commands.listClickies()
	for _, id in ipairs(config.combatClickies) do
		print('\at[LeRogue]\ay Combat clickies: \ag', mq.TLO.FindItem(id).Name())
	end
	for _, id in ipairs(config.burnClickies) do
		print('\at[LeRogue]\ay Burn clickies: \ag', mq.TLO.FindItem(id).Name())
	end
end

------------------------------ /lr ------------------------------

-- Commands other than on/off toggles. Burns and drags are only requested here:
-- the main loop carries them out, so they never run in the middle of something else.
local ACTIONS = {
	help = commands.help,
	pause = commands.togglePause,
	resetdefaults = function() config.applyDefaults(true) end,
	minlevel = commands.setMinLevel,
	pausehide = routines.pauseHide,
	burn = function() state.burnRequested = true end,
	dragcorpse = function(name) state.dragRequest = { name = name } end,
	removeclicky = commands.removeClicky,
	listclickies = commands.listClickies,
	addclicky = function(routine)
		if routine == 'combat' or routine == 'burn' then
			commands.addClicky(routine)
		else
			print('\at[LeRogue] \ayPlease use /lr addclicky \agcombat\ay or \agburn')
		end
	end,
}

local function onCommand(cmd, value)
	if cmd == nil then
		commands.help()
	elseif ACTIONS[cmd] then
		ACTIONS[cmd](value)
	elseif not TOGGLES[cmd] then
		print('\at[LeRogue]\ay Invalid command. Type /lr help for a list.')
	elseif value ~= 'on' and value ~= 'off' then
		print('\at[LeRogue]\ay Please use on/off')
	else
		config.set(cmd, value)
	end
end

function commands.register()
	mq.bind('/lr', onCommand)
end

return commands
