return function()
	local events = require("event.events")

	describe("Defold Events", function()
		before(function()
			events.clear_all()
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
			local counter = 0
			local f = function() counter = counter + 1 end

			events.subscribe("test", f)
			events.trigger("test")
			assert(counter == 1)

			events.clear_all()
			events.trigger("test")
			assert(counter == 1)
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
	end)
end
