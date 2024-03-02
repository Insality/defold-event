local event = require("event.event")

local M = {}
M.counter = 0
M.on_change_data = event.create()

function M.set_counter(self, counter)
	M.counter = counter
	M.on_change_data:trigger(counter)
end

return M
