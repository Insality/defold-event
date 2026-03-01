return function()
	describe("Defold Event (subscribe with event as callback)", function()
		local event ---@type event

		before(function()
			event = require("event.event")
		end)

		it("One event can be subscribed only once", function()
			local test_event = event.create()
			local event2 = event.create()

			assert(test_event:subscribe(event2) == true)
			assert(test_event:subscribe(event2) == false)
			assert(#test_event == 1)
			test_event:clear()

			assert(test_event:subscribe(event2, "context") == true)
			assert(test_event:subscribe(event2, "other_context") == true)
			assert(test_event:subscribe(event2, "other_context") == false)
			assert(#test_event == 2)
		end)

		it("Event can be subscribed on each other", function()
			local test_event1 = event.create()
			local test_event2 = event.create()
			local counter = 0
			local f1 = function() counter = counter + 1 end

			test_event1:subscribe(f1)

			test_event2:subscribe(test_event1)
			test_event2:trigger()
			assert(counter == 1)

			test_event2:trigger()
			assert(counter == 2)

			test_event2:unsubscribe(test_event1)
			test_event2:trigger()
			assert(counter == 2)
		end)

		it("Event can be checked if other event is subscribed", function()
			local test_event1 = event.create()
			local test_event2 = event.create()
			local counter = 0
			local f1 = function() counter = counter + 1 end

			test_event1:subscribe(f1)

			test_event2:subscribe(test_event1)
			assert(test_event2:is_subscribed(test_event1) == true)

			test_event2:unsubscribe(test_event1)
			assert(test_event2:is_subscribed(test_event1) == false)
		end)

		it("Chain of three events with context: contexts accumulate in trigger args", function()
			local event_A = event.create()
			local event_B = event.create()
			local event_C = event.create()

			event_A:subscribe(event_B, "A")
			event_B:subscribe(event_C, "B")
			event_C:subscribe(function(c, b, a, value)
				return { c, b, a, value }
			end, "C")

			local result = event_A:trigger("X")
			assert(result[1] == "C")
			assert(result[2] == "B")
			assert(result[3] == "A")
			assert(result[4] == "X")
		end)

		it("Event subscribed with event and context receives context and can be unsubscribed", function()
			local parent = event.create()
			local child = event.create()
			local counter = 0
			local last_context
			local f = function(ctx, _parent_ctx, amount)
				last_context = ctx
				counter = counter + amount
			end

			child:subscribe(f, "child_ctx")
			parent:subscribe(child, "parent_ctx")

			parent:trigger(1)
			assert(counter == 1)
			assert(last_context == "child_ctx")

			parent:trigger(2)
			assert(counter == 3)

			assert(parent:is_subscribed(child, "parent_ctx") == true)
			local ok = parent:unsubscribe(child, "parent_ctx")
			assert(ok == true)
			assert(parent:is_subscribed(child, "parent_ctx") == false)

			parent:trigger(10)
			assert(counter == 3)
		end)

		it("Unsubscribe event with context does not remove event without context", function()
			local parent = event.create()
			local child = event.create()
			local counter = 0
			local f = function() counter = counter + 1 end

			child:subscribe(f)
			parent:subscribe(child)
			parent:subscribe(child, "context")

			parent:unsubscribe(child, "context")
			parent:trigger()
			assert(counter == 1)

			parent:unsubscribe(child)
			assert(#parent == 0)
		end)

		it("Unsubscribe event with nil context removes no-context and all context-wrapped subscriptions", function()
			local parent = event.create()
			local child = event.create()
			local counter = 0
			local f = function() counter = counter + 1 end

			child:subscribe(f)
			parent:subscribe(child)
			parent:subscribe(child, "ctx_a")
			parent:subscribe(child, "ctx_b")
			assert(#parent == 3)

			parent:trigger()
			assert(counter == 3)

			local removed = parent:unsubscribe(child, nil)
			assert(removed == true)
			assert(#parent == 0)
			assert(parent:is_subscribed(child) == false)
			assert(parent:is_subscribed(child, "ctx_a") == false)
			assert(parent:is_subscribed(child, "ctx_b") == false)

			parent:trigger()
			assert(counter == 3)
		end)

		it("subscribe_once with event as callback: event triggered once then unsubscribed", function()
			local event1 = event.create()
			local event2 = event.create()
			local counter = 0
			local f = function() counter = counter + 1 end

			event1:subscribe(f)
			event2:subscribe_once(event1)
			event2:trigger()
			assert(counter == 1)
			assert(event2:is_subscribed(event1) == false)
			event2:trigger()
			assert(counter == 1)
		end)

		it("Should return false if unsubscribe not subscribed event", function()
			local test_event = event.create()
			local event2 = event.create()

			local is_unsubscribed = test_event:unsubscribe(event2)
			assert(is_unsubscribed == false)
		end)

		it("Event is_empty with event as subscriber", function()
			local test_event = event.create()
			local event2 = event.create()

			assert(test_event:is_empty() == true)

			test_event:subscribe(event2)
			assert(test_event:is_empty() == false)
		end)

		it("Event clear removes event subscribers", function()
			local test_event = event.create()
			local event2 = event.create()

			test_event:subscribe(event2)
			assert(test_event:is_empty() == false)

			test_event:clear()
			assert(test_event:is_empty() == true)
		end)

		it("Event trigger returns result when last subscriber is event", function()
			local parent = event.create()
			local child1 = event.create()
			child1:subscribe(function() return "result1" end)
			local child2 = event.create()
			child2:subscribe(function() return "result2" end)

			parent:subscribe(child1)
			local result = parent:trigger()
			assert(result == "result1")

			parent:subscribe(child2)
			local result = parent:trigger()
			assert(result == "result2")
		end)

		it("Event can be called with () syntax when event is subscribed", function()
			local parent = event.create()
			local child = event.create()
			local counter = 0
			local f = function(amount) counter = counter + amount end

			child:subscribe(f)
			parent:subscribe(child)
			parent(1)
			assert(counter == 1)

			parent(2)
			assert(counter == 3)
		end)

		it("Trigger with params when event is subscribed", function()
			local parent = event.create()
			local child = event.create()
			local counter = 0
			local f = function(a, b) counter = counter + a + b end

			child:subscribe(f)
			parent:subscribe(child)
			parent:trigger(1, 2)
			assert(counter == 3)
		end)
	end)
end
