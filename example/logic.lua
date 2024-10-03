local event = require("event.event")
local events = require("event.events")

local M = {}

M.counter = 0
M.on_change_data = event.create()

function M.set_counter(self, counter)
	M.counter = counter
	M.on_change_data:trigger(counter)

	timer.delay(1, false, function()
		events.trigger("hehe", "arg1", "arg2", {"list", "of", "values"})
	end)
end

return M
