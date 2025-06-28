return function()
	describe("Defold Event", function()
		local event ---@type event

		before(function()
			event = require("event.event")
			event.set_mode("pcall")
		end)

		after(function()
			event.set_mode("none")
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

			local test_event = event.create()
			local f = function() error("error") end

			test_event:subscribe(f)
			pcall(test_event:trigger())

			assert(called == true)
		end)
	end)
end
