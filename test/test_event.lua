local event = require("event.event")

return function()
	describe("Defold Event", function()
		it("Instantiate Event", function()
			local test_event = event.create()
			assert(test_event)
		end)

		it("Subscribe and Unsubscribe", function()
			local test_event = event.create()
			local f = function() end

			test_event:subscribe(f)
			assert(#test_event.callbacks == 1)

			test_event:unsubscribe(f)
			assert(#test_event.callbacks == 0)
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
			assert(#test_event.callbacks == 1)
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
	end)
end
