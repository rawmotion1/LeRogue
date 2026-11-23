-- Settings, saved per character in config\LeRogueConfig_<name>.lua.
-- On/off settings are stored as the strings 'on' and 'off', the format every
-- earlier version used, so existing config files keep working.

--- @type Mq
local mq = require('mq')

local config = {
	version = '3.4.0',
	settings = {},        -- e.g. settings.dot = 'on', settings.minlevel = 75
	combatClickies = {},  -- item IDs used in the combat routine
	burnClickies = {},    -- item IDs used in the burn routine
}

local fileName = 'LeRogueConfig_'..(mq.TLO.Me.Name() or '')..'.lua'
local oldFileName = 'LeRogueConfig.lua' -- one shared file, used before 3.0

local DEFAULTS = {
	combat = 'on',
	disc = 'on',
	dot = 'on',
	ligament = 'on',
	intimidation = 'on',
	glyph = 'off',
	burnalways = 'off',
	stayalive = 'on',
	hiatus = 'on',
	poison = 'on',
	summon = 'on',
	hide = 'on',
	dragcorpses = 'on',
	minlevel = 75,
	clickies = 'on', -- not used any more; kept so older config files stay the same shape
}

-- 'on' in green, 'off' in red, anything else as is
local function colored(value)
	if value == 'on' then return '\agon' end
	if value == 'off' then return '\aroff' end
	return value
end

-- Turn a list that may have gaps (older versions removed clickies by leaving holes) into a plain list
local function compact(list)
	local keys = {}
	for k in pairs(list or {}) do
		if type(k) == 'number' then table.insert(keys, k) end
	end
	table.sort(keys)
	local result = {}
	for _, k in ipairs(keys) do table.insert(result, list[k]) end
	return result
end

function config.save()
	mq.pickle(fileName, {
		rogSettings = config.settings,
		rogClickies = config.combatClickies,
		burnClickies = config.burnClickies,
	})
end

function config.isOn(key)
	return config.settings[key] == 'on'
end

-- Change one setting, announce it and save
function config.set(key, value)
	config.settings[key] = value
	print('\at[LeRogue] \aoTurning \ay', key, ' \ag ', colored(value))
	config.save()
end

-- Fill in missing settings (or reset all of them), print them all and save
function config.applyDefaults(resetAll)
	if resetAll then print('\at[LeRogue] \aw---- \at Setting toggles to default values \aw----') end
	for key, value in pairs(DEFAULTS) do
		if resetAll or config.settings[key] == nil then config.settings[key] = value end
	end
	for key, value in pairs(config.settings) do print('\at[LeRogue]\ao ', key, ": \ay", colored(value)) end
	config.save()
end

-- Read this character's settings file, or create it on the first run
function config.load()
	local chunk, err = loadfile(mq.configDir..'/'..fileName)
	if err then chunk, err = loadfile(mq.configDir..'/'..oldFileName) end

	if err or not chunk then
		print('\at[LeRogue] \ay Creating config file...')
		print('\at[LeRogue] \ay Welcome to LeRogue.lua ', config.version)
		config.applyDefaults(true)
		return
	end

	local saved = chunk()
	if saved.burnClickies then -- files from before burn clickies existed start from defaults
		config.settings = saved.rogSettings or {}
		config.combatClickies = compact(saved.rogClickies)
		config.burnClickies = compact(saved.burnClickies)
	end
	-- Older versions could save hide as 'paused'; pausing hide is no longer stored
	if config.settings.hide == 'paused' then config.settings.hide = 'on' end

	print('\at[LeRogue]\ay Welcome to LeRogue.lua ', config.version)
	config.applyDefaults(false)
end

return config
