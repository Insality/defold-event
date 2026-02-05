return function()
	describe("Defold Event", function()
		local event ---@type event

		before(function()
			event = require("event.event")
		end)

		it("Instantiate Event", function()
			local test_event = event.create()
			assert(test_event)
		end)

		it("Instantiate Event with callback", function()
			local ctx = "some context"
			local f = function(self, arg)
				assert(self == "some context")
				assert(arg == "arg")
			end

			local test_event = event.create(f, ctx)
			assert(#test_event == 1)

			test_event:trigger("arg")
		end)

		it("Subscribe and Unsubscribe", function()
			local test_event = event.create()
			local f = function() end

			test_event:subscribe(f)
			assert(#test_event == 1)

			test_event:unsubscribe(f)
			assert(#test_event == 0)
		end)

		it("Trigger", function()
			local test_event = event.create()
			local counter = 0
			local f = function() counter = counter + 1 end

			test_event:subscribe(f)
			test_event:trigger()
			assert(counter == 1)
			test_event:trigger()
			assert(counter == 2)

			test_event:unsubscribe(f)
			test_event:trigger()
			assert(counter == 2)
		end)

		it("Trigger with params", function()
			local test_event = event.create()
			local counter = 0
			local f = function(a, b) counter = counter + a + b end

			test_event:subscribe(f)
			test_event:trigger(1, 2)
			assert(counter == 3)
		end)

		it("One function can be subscribed only once", function()
			local test_event = event.create()
			local counter = 0
			local f = function() counter = counter + 1 end

			local is_subscribed = test_event:subscribe(f)
			assert(is_subscribed == true)

			is_subscribed = test_event:subscribe(f)
			assert(is_subscribed == false)
			assert(#test_event == 1)
		end)

		it("Event is_subscribed", function()
			local test_event = event.create()
			local f = function() end

			assert(test_event:is_subscribed(f) == false)

			test_event:subscribe(f)
			assert(test_event:is_subscribed(f) == true)
		end)

		it("Subscribe with context", function()
			local test_event = event.create()
			local last_context
			local f = function(context) last_context = context end

			test_event:subscribe(f, "context")
			test_event:trigger("foo", "bar")
			assert(last_context == "context")
		end)

		it("Event is_empty", function()
			local test_event = event.create()
			local f = function() end

			assert(test_event:is_empty() == true)

			test_event:subscribe(f)
			assert(test_event:is_empty() == false)
		end)

		it("Event clear", function()
			local test_event = event.create()
			local f = function() end

			test_event:subscribe(f)
			assert(test_event:is_empty() == false)

			test_event:clear()
			assert(test_event:is_empty() == true)
		end)

		it("Event trigger returns result", function()
			local test_event = event.create()
			local f = function() return "result" end

			test_event:subscribe(f)
			local result = test_event:trigger()
			assert(result == "result")
		end)

		it("Event trigger returns last subscriber result", function()
			local test_event = event.create()
			local f1 = function() return "result1" end
			local f2 = function() return "result2" end

			test_event:subscribe(f1)
			test_event:subscribe(f2)

			local result = test_event:trigger()
			assert(result == "result2")
		end)

		it("Event trigger returns nil if no subscribers", function()
			local test_event = event.create()
			local result = test_event:trigger()
			assert(result == nil)
		end)

		it("Should return false if unsubscribe not subscribed function", function()
			local test_event = event.create()
			local f = function() end

			local is_unsubscribed = test_event:unsubscribe(f)
			assert(is_unsubscribed == false)
		end)

		it("Event can be called with regular function syntax", function()
			local test_event = event.create()
			local counter = 0
			local f = function(amount) counter = counter + amount end

			test_event:subscribe(f)
			test_event(1)
			assert(counter == 1)

			test_event(2)
			assert(counter == 3)
		end)

		it("Event can be subscribed on each other", function()
			local test_event1 = event.create()
			local test_event2 = event.create()
			local counter = 0
			local f1 = function() counter = counter + 1 end

			test_event1:subscribe(f1)

			-- So test_event2 will trigger test_event1
			test_event2:subscribe(test_event1)
			test_event2:trigger()
			assert(counter == 1)

			test_event2:trigger()
			assert(counter == 2)

			-- Unsubscribe test_event1 from test_event2
			test_event2:unsubscribe(test_event1)
			test_event2:trigger()
			assert(counter == 2)
		end)

		it("Event can be checked if øther event is subscribed", function()
			local test_event1 = event.create()
			local test_event2 = event.create()
			local counter = 0
			local f1 = function() counter = counter + 1 end

			test_event1:subscribe(f1)

			-- So test_event2 will trigger test_event1
			test_event2:subscribe(test_event1)
			assert(test_event2:is_subscribed(test_event1) == true)

			-- Unsubscribe test_event1 from test_event2
			test_event2:unsubscribe(test_event1)
			assert(test_event2:is_subscribed(test_event1) == false)
		end)

		it("Print memory allocations per function", function()
			local EMPTY_FUNCTION = function() end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = function(_, message, context)
					pprint(message, context)
				end,
				error = EMPTY_FUNCTION,
			}
			event.set_logger(logger)

			collectgarbage("stop")

			local current_memory = collectgarbage("count")
			local events = {}
			for _ = 1, 1000 do
				table.insert(events, event.create())
			end

			local new_memory = collectgarbage("count")
			local memory_per_event = ((new_memory - current_memory) * 1024) / 1000
			print("Event instance should be around 64 bytes, but on CI with code debug coverage it will be much more")
			print("Memory allocations per instance (Bytes): ", memory_per_event)

			local e = event.create()
			current_memory = collectgarbage("count")
			e:subscribe(function() end)
			new_memory = collectgarbage("count")
			local memory_per_subscribe = ((new_memory - current_memory) * 1024)
			print("Memory allocations per first subscribe (Bytes): ", memory_per_subscribe)

			local functions_memory = 40 * 1000 / 1024 -- kbytes
			current_memory = collectgarbage("count")
			for i_ndex = 1, 1000 do
				e:subscribe(function() end)
			end
			new_memory = collectgarbage("count") - functions_memory
			local memory_per_subscribe = ((new_memory - current_memory) * 1024) / 1000
			print("Memory allocations per subscribe (Bytes): ", memory_per_subscribe)

			collectgarbage("restart")
		end)

		it("Print memory allocations per trigger with 1 subscriber", function()
			collectgarbage("stop")

			local e = event.create()
			e:subscribe(function(a, b, c) end)

			local current_memory = collectgarbage("count")
			for _ = 1, 1000 do
				e:trigger(1, 2, 3)
			end

			local new_memory = collectgarbage("count")
			local memory_per_trigger = ((new_memory - current_memory) * 1024) / 1000
			print("Memory allocations per trigger with 1 subscriber (Bytes): ", memory_per_trigger)

			collectgarbage("restart")
		end)

		it("Event should unsubscribe all callbacks by passin unsubscribe without context", function()
			local test_event = event.create()
			local counter = 0
			local f1 = function(amount) counter = counter + amount end

			test_event:subscribe(f1, 2)
			test_event:subscribe(f1, 3)
			test_event:subscribe(f1, 7)

			test_event:trigger()
			assert(counter == 12)

			local is_unsubscribed = test_event:unsubscribe(f1, 2)
			test_event:trigger()
			assert(counter == 22)
			assert(is_unsubscribed == true)

			is_unsubscribed = test_event:unsubscribe(f1)
			test_event:trigger()
			assert(counter == 22)
			assert(is_unsubscribed == true)

			is_unsubscribed = test_event:unsubscribe(f1, 7)
			test_event:trigger()
			assert(counter == 22)
			assert(is_unsubscribed == false)
		end)

		it("Event without context and with context should be able to subscribe", function()
			local test_event = event.create()
			local counter = 0
			local f1 = function(amount) counter = counter + amount end

			test_event:subscribe(f1)
			test_event:subscribe(f1, 2)

			test_event:trigger(1)
			assert(counter == 3)

			-- Should unsubscribe both
			test_event:unsubscribe(f1)

			-- Other order should works too. Check it due the nil context unsubscribe feature
			assert(test_event:subscribe(f1, 2))
			assert(test_event:subscribe(f1))

			test_event:trigger(1)
			assert(counter == 6)
		end)

		it("Event should allow unsubscribe events with different context and without it", function()
			local test_event = event.create()
			local counter = 0
			local f1 = function(amount) counter = counter + amount end

			test_event:subscribe(f1)
			test_event:subscribe(f1, 2)

			-- Should unsubscribe only with context
			assert(test_event:unsubscribe(f1, 2))
			assert(#test_event == 1)

			assert(test_event:unsubscribe(f1))
			assert(#test_event == 0)

			test_event:subscribe(f1)
			test_event:subscribe(f1, 2)

			assert(test_event:unsubscribe(f1))
			assert(#test_event == 0)
		end)

		it("Event should return count of subscribers by length property", function()
			local test_event = event.create()
			local counter = 0
			local f1 = function(amount) counter = counter + amount end

			assert(#test_event == 0)

			test_event:subscribe(f1)
			assert(#test_event == 1)

			test_event:subscribe(f1, 2)
			assert(#test_event == 2)

			test_event:unsubscribe(f1)
			assert(#test_event == 0)
		end)

		it("Trigger with context passes all args under xpcall (nil in middle)", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			local ctx = {}
			local ra, rb, rc
			local f = function(self, ...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f, ctx)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)

			-- restore default mode
			event.set_mode("pcall")
		end)

		it("Trigger without context passes all args under xpcall (nil in middle)", function()
			event.set_mode("xpcall")

			local test_event = event.create()
			local ra, rb, rc
			local f = function(...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)

			-- restore default mode
			event.set_mode("pcall")
		end)


		it("Trigger with context passes all args under none mode (nil in middle)", function()
			event.set_mode("none")

			local test_event = event.create()
			local ctx = {}
			local ra, rb, rc
			local f = function(self, ...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f, ctx)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)

			-- restore default mode
			event.set_mode("pcall")
		end)


		it("Trigger without context passes all args under none mode (nil in middle)", function()
			event.set_mode("none")

			local test_event = event.create()
			local ra, rb, rc
			local f = function(...)
				ra, rb, rc = ...
			end

			test_event:subscribe(f)
			test_event:trigger(1, nil, 3)

			assert(ra == 1)
			assert(rb == nil)
			assert(rc == 3)

			-- restore default mode
			event.set_mode("pcall")
		end)


		it("Error in callback in none mode rethrows", function()
			event.set_mode("none")

			local test_event = event.create()
			local err_msg = "none mode error"
			test_event:subscribe(function()
				error(err_msg)
			end)

			local ok, err = pcall(function()
				test_event:trigger()
			end)

			assert(ok == false)
			assert(err and tostring(err):find(err_msg))

			event.set_mode("pcall")
		end)

		--[[
		it("Print execution time per function", function()
			local test_time = function(c)
				local start_time = socket.gettime() * 1000
				c()
				local end_time = socket.gettime() * 1000
				return end_time - start_time
			end

			local EMPTY_FUNCTION = function() end
			local logger =  {
				trace = EMPTY_FUNCTION,
				debug = EMPTY_FUNCTION,
				info = EMPTY_FUNCTION,
				warn = function(_, message, context)
					pprint(message, context)
				end,
				error = EMPTY_FUNCTION,
			}
			event.set_logger(logger)

			local times = 100000

			local start = socket.gettime() * 1000
			for _ = 1, times do
				event.create()
			end
			local finish = socket.gettime() * 1000
			local create_time_per_instance = (finish - start) / times
			print("Create time per instance (ms): ", create_time_per_instance)

			start = socket.gettime() * 1000
			for index = 1, 1000 do
				event.create():subscribe(function() end)
			end
			finish = socket.gettime() * 1000
			print("Subscribe time per 1000 callbacks on new event (ms): ", (finish - start) / 1000 - create_time_per_instance)

			local e = event.create()
			start = socket.gettime() * 1000
			for index = 1, 1000 do
				e:subscribe(function() end)
			end
			finish = socket.gettime() * 1000
			print("Subscribe time per 1000 callbacks on one event (ms): ", (finish - start) / 1000)

			start = socket.gettime() * 1000
			for index = 1, times do
				e:trigger(1, 2, 3)
			end
			finish = socket.gettime() * 1000
			print("Trigger time per instance with 1000 callbacks (ms): ", (finish - start) / times)

			e:clear()
			e:subscribe(function() end)
			start = socket.gettime() * 1000
			for index = 1, times do
				e:trigger(1, 2, 3)
			end
			finish = socket.gettime() * 1000
			print("Trigger time per instance with 1 callback (ms): ", (finish - start) / times)
		end)
		--]]
	end)
end
