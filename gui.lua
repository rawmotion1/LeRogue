-- The LeRogue window. Fixed size: it can't be resized.

--- @type Mq
local mq = require('mq')
--- @type ImGui
require('ImGui')
local state = require('state')
local config = require('config')
local commands = require('commands')
local routines = require('routines')

local gui = {}

local WIDTH, HEIGHT = 240, 550
local draggingLevel = false -- min level is saved when the slider is let go, not on every step

-- A checkbox for an on/off setting
local function settingCheckbox(label, key, tooltip)
	local checked, pressed = ImGui.Checkbox(label, config.isOn(key))
	if pressed then config.set(key, checked and 'on' or 'off') end
	if tooltip and ImGui.IsItemHovered() then ImGui.SetTooltip(tooltip) end
end

-- A button with an optional tooltip. Returns true when pressed.
local function button(label, width, tooltip)
	local pressed = ImGui.Button(label, width, 0)
	if tooltip and ImGui.IsItemHovered() then ImGui.SetTooltip(tooltip) end
	return pressed
end

local function drawContents()
	local width = ImGui.GetContentRegionAvail()
	local half = (width / 2) - 4
	local quarter = (width / 4) - 1

	-- Pause
	if ImGui.Button('Pause') then commands.togglePause() end
	ImGui.SameLine()
	if state.paused then
		ImGui.TextColored(.75, 0, 0, 1, 'Paused')
	else
		ImGui.TextColored(0, .75, 0, 1, 'Running '..config.version)
	end
	ImGui.Separator()

	-- Combat
	settingCheckbox('Combat abilities', 'combat')
	settingCheckbox('Rotating discs', 'disc')
	settingCheckbox('DoTs', 'dot')
	settingCheckbox('Ligament slice', 'ligament')
	settingCheckbox('Intimidation', 'intimidation')

	-- Clickies
	ImGui.Text('Add/remove clickies')
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 4)
	if button('Combat', quarter, 'Add clicky on cursor to combat routine.') then commands.addClicky('combat') end
	ImGui.SameLine()
	if button('Burn', quarter, 'Add clicky on cursor to burn routine.') then commands.addClicky('burn') end
	ImGui.SameLine()
	if button('Rem', quarter, 'Remove clicky on your cursor from LeRogue.') then commands.removeClicky() end
	ImGui.SameLine()
	if button('List', quarter) then commands.listClickies() end
	ImGui.PopStyleVar()
	ImGui.Separator()

	-- Burn
	settingCheckbox('Use glyphs', 'glyph')
	settingCheckbox('Always burn', 'burnalways')
	ImGui.Separator()

	-- Defense and endurance
	settingCheckbox('Use defense', 'stayalive')
	settingCheckbox('Use Hiatus line', 'hiatus', 'Use Hiatus line instead of Respite line (recommended at high levels).')
	ImGui.Separator()

	-- Poison
	settingCheckbox('Apply poison', 'poison')
	settingCheckbox('Summon poison', 'summon')
	ImGui.Separator()

	-- Min level
	local level, changed = ImGui.SliderInt('Min lvl', config.settings.minlevel, 1, 120)
	if changed then
		config.settings.minlevel = level
		draggingLevel = true
	end
	if draggingLevel and ImGui.IsMouseReleased(ImGuiMouseButton.Left) then
		commands.setMinLevel(config.settings.minlevel)
		draggingLevel = false
	end
	ImGui.Separator()

	-- Hiding
	settingCheckbox('Auto-hide', 'hide')
	ImGui.SameLine()
	if mq.TLO.Me.Invis('SOS')() then
		ImGui.TextColored(0, .75, .75, 1, '\xee\xa3\xb4'..' Hidden')
	else
		ImGui.TextColored(0, .75, .75, 1, '\xee\xa3\xb5'..' Visible')
	end
	if ImGui.Button('Pause hide 20', half, 0) then routines.pauseHide(20) end
	ImGui.SameLine()
	if ImGui.Button('Pause hide 60', half, 0) then routines.pauseHide(60) end
	ImGui.Separator()

	-- Corpses and burn
	settingCheckbox('Auto drag corpses', 'dragcorpses')
	ImGui.SameLine()
	ImGui.Text('\xee\xa3\xbd')
	if ImGui.IsItemHovered() then
		ImGui.SetTooltip('Automatically drag group corpses if you have a KA camp or campfire set.')
	end
	if button('Drag corpse', half, 'Drag your target\'s corpse to camp or current location.') then
		state.dragRequest = {}
	end
	ImGui.SameLine()
	ImGui.PushStyleColor(ImGuiCol.Button, .61, .0, .0, .75)
	if ImGui.Button('Burn now', half, 0) then state.burnRequested = true end
	ImGui.PopStyleColor()
end

local function window()
	ImGui.SetNextWindowSize(WIDTH, HEIGHT, ImGuiCond.Always)
	local open, show = ImGui.Begin('LeRogue', state.windowOpen, ImGuiWindowFlags.NoResize)
	state.windowOpen = open
	if show then drawContents() end
	ImGui.End()
end

function gui.register()
	mq.imgui.init('LeRogue', window)
end

return gui
