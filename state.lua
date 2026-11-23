-- Runtime state shared between LeRogue's files. Nothing in here is saved to disk.

---@class LeRogueState
---@field dragRequest {name: string?}|nil
local state = {
	paused = false,          -- /lr pause or the Pause button
	burnRequested = false,   -- /lr burn or "Burn now": the main loop does the burn
	dragRequest = nil,       -- /lr dragcorpse or "Drag corpse": { name = <player or nil> }
	hidePausedUntil = nil,   -- mq.gettime() at which auto-hide resumes; nil when not paused
	windowOpen = true,       -- closing the window ends the script
}

return state
