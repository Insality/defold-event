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
			event.set_memory_threshold(5)
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
				local t = {}
				for index = 1, amount_of_tables do
					local e = event.create()
					table.insert(t, e)
				end
			end
			test_event:subscribe(f)

			-- Stop collecting garbage
			collectgarbage("stop")

			local cur_memory = collectgarbage("count")
			print("Memory before: " .. cur_memory)

			-- Set low amount, due the test coverage big overhead
			test_event:trigger(1)
			assert(called == false)

			print("Memory after 1: " .. collectgarbage("count") - cur_memory)

			test_event:trigger(4000)
			assert(called == true)

			print("Memory after 2: " .. collectgarbage("count") - cur_memory)

			-- Start collecting garbage
			collectgarbage("restart")
		end)
	end)
end
