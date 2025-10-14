return function()
	local events = {}

	describe("Defold Events", function()
		before(function()
			events = require("event.events") --[[@as events]]
		end)

		after(function()
			events.clear("test")
		end)

		it("Events Subscribe and Unsubscribe", function()
			local f = function() end

			events.subscribe("test", f)
			assert(events.is_subscribed("test", f) == true)

			events.unsubscribe("test", f)
			assert(events.is_subscribed("test", f) == false)
		end)

		it("Events Trigger", function()
			local counter = 0
			local f = function() counter = counter + 1 end

			events.subscribe("test", f)
			events.trigger("test")
			assert(counter == 1)
			events.trigger("test")
			assert(counter == 2)

			events.unsubscribe("test", f)
			events.trigger("test")
			assert(counter == 2)
		end)

		it("Events Trigger with params", function()
			local counter = 0
			local f = function(a, b) counter = counter + a + b end

			events.subscribe("test", f)
			events.trigger("test", 1, 2)
			assert(counter == 3)
		end)

		it("One function can be subscribed only once", function()
			local counter = 0
			local f = function() counter = counter + 1 end

			local is_subscribed = events.subscribe("test", f)
			assert(is_subscribed == true)

			is_subscribed = events.subscribe("test", f)
			assert(is_subscribed == false)
			assert(events.is_subscribed("test", f) == true)
		end)

		it("Events Clear", function()
			local counter = 0
			local f = function() counter = counter + 1 end

			events.subscribe("test", f)
			events.trigger("test")
			assert(counter == 1)

			events.clear("test")
			events.trigger("test")
			assert(counter == 1)
		end)

		it("Events Clear All", function()
			local counter1 = 0
			local counter2 = 0
			local f1 = function() counter1 = counter1 + 1 end
			local f2 = function() counter2 = counter2 + 1 end

			events.subscribe("test1", f1)
			events.subscribe("test2", f2)

			events.trigger("test1")
			events.trigger("test2")
			assert(counter1 == 1)
			assert(counter2 == 1)

			events.clear_all()

			events.trigger("test1")
			events.trigger("test2")
			assert(counter1 == 1)
			assert(counter2 == 1)

			assert(events.is_empty("test1") == true)
			assert(events.is_empty("test2") == true)
		end)

		it("Events is_subscribed", function()
			local f = function() end

			assert(events.is_subscribed("test", f) == false)

			events.subscribe("test", f)
			assert(events.is_subscribed("test", f) == true)
		end)

		it("Events is_empty", function()
			assert(events.is_empty("test") == true)

			local f = function() end
			events.subscribe("test", f)
			assert(events.is_empty("test") == false)
		end)

		it("Events Subscribe with context", function()
			local last_context
			local f = function(context) last_context = context end

			events.subscribe("test", f, "context")
			events.trigger("test", "foo", "bar")
			assert(last_context == "context")
		end)

		it("Events Trigger returns result", function()
			local f = function() return "result" end

			events.subscribe("test", f)
			local result = events.trigger("test")
			assert(result == "result")
		end)

		it("Events Trigger return last callback result", function()
			local f1 = function() return "result1" end
			local f2 = function() return "result2" end

			events.subscribe("test", f1)
			events.subscribe("test", f2)
			local result = events.trigger("test")
			assert(result == "result2")
		end)

		it("Unsubscribe unknown event", function()
			local f = function() end

			local is_unsubscribed = events.unsubscribe("unknown", f)
			assert(is_unsubscribed == false)
		end)


		it("Events callable as shorthand for trigger", function()
			local counter = 0
			local f = function() counter = counter + 1 end

			events.subscribe("test", f)
			events("test") -- Should be equivalent to events.trigger("test")
			assert(counter == 1)
			events("test")
			assert(counter == 2)

			events.unsubscribe("test", f)
			events("test")
			assert(counter == 2)
		end)


		it("Events callable with params", function()
			local counter = 0
			local f = function(a, b) counter = counter + a + b end

			events.subscribe("test", f)
			events("test", 1, 2) -- Should be equivalent to events.trigger("test", 1, 2)
			assert(counter == 3)
		end)


		it("Events callable returns result", function()
			local f = function() return "result" end

			events.subscribe("test", f)
			local result = events("test") -- Should be equivalent to events.trigger("test")
			assert(result == "result")
		end)


		it("Events callable return last callback result", function()
			local f1 = function() return "result1" end
			local f2 = function() return "result2" end

			events.subscribe("test", f1)
			events.subscribe("test", f2)
			local result = events("test") -- Should be equivalent to events.trigger("test")
			assert(result == "result2")
		end)
	end)
end
