return function()
	local event = {} --[[@as event]]

	describe("Defold Event", function()
		before(function()
			event = require("event.event")
		end)
		
		it("Event Set logger", function()
			local EMPTY_FUNCTION = function(_, message, context) end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = EMPTY_FUNCTION,
				error = EMPTY_FUNCTION,
			}
			event.set_logger(logger)
			assert(event.logger == logger)
		end)

		it("Subscribe and Unsubscribe", function()
			local test_event = event.create()
			local f = function() end

			test_event:subscribe(f)
			assert(#test_event.callbacks == 1)

			test_event:unsubscribe(f)
			assert(#test_event.callbacks == 0)
		end)
	end)
end
