local event = require("event.event")
local events = require("event.events")

local M = {}

local function print_error(message)
	error(message)
end

M.counter = 0
M.on_change_data = event.create()
M.call_error = event.create(function()
	print_error("from event")
end)

function M.set_counter(self, counter)
	M.counter = counter
	M.on_change_data:trigger(counter)

	timer.delay(1, false, function()
		events.trigger("hehe", "arg1", "arg2", {"list", "of", "values"})
	end)
end

return M
