return function()
	local event = {} --[[@as event]]

	describe("Event Context Manager", function()
		before(function()
			event = require("event.event")
		end)

		it("Basic Get/Set", function()
			local current_instance = event_context_manager.get()
			assert(current_instance)

			event_context_manager.set(current_instance)
			assert(current_instance == event_context_manager.get())
		end)

		it("Set not valid context", function()
			local current_context = event_context_manager.get()

			local is_ok, error = pcall(event_context_manager.set)
			assert(not is_ok)
			assert(error)
			assert(current_context == event_context_manager.get())
		end)
	end)
end
