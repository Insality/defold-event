return function()
	local event = {}

	describe("Defold Event", function()
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

		it("Print memory allocations per function", function()
			collectgarbage("stop")

			local current_memory = collectgarbage("count")

			for _ = 1, 10000 do
				event.create()
			end

			local new_memory = collectgarbage("count")
			local memory_per_event = ((new_memory - current_memory) * 1024) / 10000
			print("Event instance should be around 64 bytes, but on CI with code debug coverage it will be much more")
			print("Memory allocations per function (Bytes): ", memory_per_event)

			collectgarbage("restart")
		end)
	end)
end
