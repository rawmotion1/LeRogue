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

-- Colours: poison green and dark orange (red, green, blue, alpha)
local GREEN = { .50, .95, .20, 1 }
local ORANGE = { 1.0, .55, .0, 1 }
local THEME = {
	{ 'WindowBg',         .06, .09, .05, .95 },
	{ 'Border',           .55, .30, .00, .70 },
	{ 'TitleBg',          .10, .22, .05, 1 },
	{ 'TitleBgActive',    .20, .42, .08, 1 },
	{ 'TitleBgCollapsed', .10, .22, .05, 1 },
	{ 'FrameBg',          .12, .22, .08, 1 },
	{ 'FrameBgHovered',   .20, .35, .10, 1 },
	{ 'FrameBgActive',    .26, .46, .12, 1 },
	{ 'CheckMark',        .50, .95, .20, 1 },
	{ 'SliderGrab',       .85, .45, .00, 1 },
	{ 'SliderGrabActive', 1.0, .58, .10, 1 },
	{ 'Button',           .70, .35, .00, 1 },
	{ 'ButtonHovered',    .88, .48, .05, 1 },
	{ 'ButtonActive',     1.0, .60, .12, 1 },
	{ 'Separator',        .30, .50, .12, .70 },
}

local function pushTheme()
	for _, c in ipairs(THEME) do ImGui.PushStyleColor(ImGuiCol[c[1]], c[2], c[3], c[4], c[5]) end
end

-- Nightshade, Blade of Entropy, drawn from the game's own item icon sheets (A_DragItem).
-- Item icon numbers start at 500 there, so icon N is cell N - 500.
local NIGHTSHADE_ICON = 1518
local ICON_OFFSET = 500
local ICON_SIZE = 20
local itemIcons = nil -- looked up on first draw

-- Draw the icon in the title bar, just left of the title. ImGui has no slot for that, so we
-- widen the clip area to the title bar, draw there, and put the cursor back.
local function drawTitleIcon(title)
	itemIcons = itemIcons or mq.FindTextureAnimation('A_DragItem')
	if not itemIcons then return end

	local winX, winY = ImGui.GetWindowPos()
	local winW = ImGui.GetWindowWidth()
	local barH = ImGui.GetFrameHeight()
	local size = math.min(ICON_SIZE, barH - 2)
	local textW = ImGui.CalcTextSize(title)
	local align = ImGui.GetStyle().WindowTitleAlign.x -- 0.5 = centred title
	local x = winX + (winW - textW) * align - size - 4
	local y = winY + (barH - size) / 2

	local cursorX, cursorY = ImGui.GetCursorPos()
	ImGui.PushClipRect(winX, winY, winX + winW, winY + barH, false)
	-- A soft orange tile behind it: the blade is thin and dark, and vanishes on dark green
	ImGui.GetWindowDrawList():AddRectFilled(ImVec2(x, y), ImVec2(x + size, y + size), ImGui.GetColorU32(.95, .62, .25, 1), 3)
	ImGui.SetCursorScreenPos(x, y)
	itemIcons:SetTextureCell(NIGHTSHADE_ICON - ICON_OFFSET)
	ImGui.DrawTextureAnimation(itemIcons, size, size)
	ImGui.PopClipRect()
	ImGui.SetCursorPos(cursorX, cursorY)
end

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
		ImGui.TextColored(.85, .15, .05, 1, 'Paused')
	else
		ImGui.TextColored(GREEN[1], GREEN[2], GREEN[3], GREEN[4], 'Running '..config.version)
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
		ImGui.TextColored(GREEN[1], GREEN[2], GREEN[3], GREEN[4], '\xee\xa3\xb4'..' Hidden')
	else
		ImGui.TextColored(ORANGE[1], ORANGE[2], ORANGE[3], ORANGE[4], '\xee\xa3\xb5'..' Visible')
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
	pushTheme() -- before Begin, so the title bar and border get the colours too
	ImGui.SetNextWindowSize(WIDTH, HEIGHT, ImGuiCond.Always)
	local open, show = ImGui.Begin('LeRogue', state.windowOpen, ImGuiWindowFlags.NoResize)
	state.windowOpen = open
	if show then
		drawTitleIcon('LeRogue')
		drawContents()
	end
	ImGui.End()
	ImGui.PopStyleColor(#THEME)
end

function gui.register()
	mq.imgui.init('LeRogue', window)
end

return gui
