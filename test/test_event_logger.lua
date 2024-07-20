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

		it("Should throw warn if subscribed callback consume more memory than threshold", function()
			event.set_memory_threshold(10)
			local called = false

			local EMPTY_FUNCTION = function() end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = function(_, message, context)
					pprint(message, context)
					called = true
				end,
				error = EMPTY_FUNCTION,
			}
			event.set_logger(logger)

			local test_event = event.create()
			local f = function(amount_of_tables)
				-- One table should be 40 bytes
				-- To reach 10 kb we need 160 tables
				for index = 1, amount_of_tables do
					local a = {}
				end
			end
			test_event:subscribe(f)

			-- Set low amount, due the test coverage big overhead
			test_event:trigger(1)
			assert(called == false)

			test_event:trigger(160)
			assert(called == true)
		end)
	end)
end
