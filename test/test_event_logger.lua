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

		it("Should handle error in callback", function()
			local called = false

			local EMPTY_FUNCTION = function(_, message, context) end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = EMPTY_FUNCTION,
				error = function() called = true end,
			}
			event.set_logger(logger)
			assert(event.logger == logger)
			
			local test_event = event.create()
			local f = function() error("error") end

			test_event:subscribe(f)
			test_event:trigger()

			assert(called == true)
		end)
	end)
end
