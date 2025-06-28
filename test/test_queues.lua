local function test_queues()
	describe("Queues module", function()
		local queues ---@type queues
		local TEST_EVENT = "test_event"

		before(function()
			queues = require("event.queues")
		end)

		after(function()
			queues.clear_all()
		end)

		it("Should call subscriber when event is pushed after subscription", function()
			local was_called = false
			local test_data = "test_data"

			queues.subscribe(TEST_EVENT, function(data)
				was_called = true
				assert(data == test_data)
				return true -- Mark as handled
			end)

			queues.push(TEST_EVENT, test_data)

			assert(was_called == true)
			assert(#queues.get_events(TEST_EVENT) == 0) -- Event should be removed
		end)

		it("Should call subscriber when subscription happens after event is pushed", function()
			local was_called = false
			local test_data = "test_data"

			-- Push event first
			queues.push(TEST_EVENT, test_data)

			-- Then subscribe
			queues.subscribe(TEST_EVENT, function(data)
				was_called = true
				assert(data == test_data)
				return true -- Mark as handled
			end)

			assert(was_called == true)
			assert(#queues.get_events(TEST_EVENT) == 0) -- Event should be removed
		end)

		it("Should remove event when handler returns non-nil value", function()
			local test_data = "test_data"

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Event should be in queue
			assert(#queues.get_events(TEST_EVENT) == 1)

			-- Subscribe with handler that returns a value
			queues.subscribe(TEST_EVENT, function(data)
				return "some_value" -- Any non-nil value should work
			end)

			-- Event should be removed
			assert(#queues.get_events(TEST_EVENT) == 0)
		end)

		it("Should call on_handle callback when event is handled", function()
			local test_data = "test_data"
			local on_handle_called = false
			local handle_result_value = "handled"

			-- Subscribe
			queues.subscribe(TEST_EVENT, function(data)
				return handle_result_value
			end)

			-- Push with on_handle callback
			queues.push(TEST_EVENT, test_data, function(result)
				on_handle_called = true
				assert(result == handle_result_value)
			end)

			assert(on_handle_called == true)
		end)

		it("Should allow multiple subscribers to handle the same event", function()
			local test_data = "test_data"
			local handler1_called = false
			local handler2_called = false
			local handler3_called = false

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Subscribe multiple handlers
			queues.subscribe(TEST_EVENT, function(data)
				handler1_called = true
				return nil -- Don't handle it yet
			end)

			queues.subscribe(TEST_EVENT, function(data)
				handler2_called = true
				return nil -- Don't handle it yet
			end)

			-- Event should still be in queue
			assert(#queues.get_events(TEST_EVENT) == 1)
			assert(handler1_called == true)
			assert(handler2_called == true)

			-- Subscribe a handler that will handle it
			queues.subscribe(TEST_EVENT, function(data)
				handler3_called = true
				return true -- Handle it
			end)

			-- Event should be removed now
			assert(#queues.get_events(TEST_EVENT) == 0)
			assert(handler3_called == true)
		end)

		it("Should process events manually without subscribers", function()
			local test_data = "test_data"
			local was_called = false

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Event should be in queue
			assert(#queues.get_events(TEST_EVENT) == 1)

			-- Process manually
			queues.process(TEST_EVENT, function(data)
				was_called = true
				assert(data == test_data)
				return true -- Handle it
			end)

			assert(was_called == true)
			assert(#queues.get_events(TEST_EVENT) == 0) -- Event should be removed
		end)

		it("Should keep events if not handled", function()
			local test_data = "test_data"

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Subscribe with handler that doesn't handle
			queues.subscribe(TEST_EVENT, function(data)
				return nil -- Not handled
			end)

			-- Event should still be in queue
			assert(#queues.get_events(TEST_EVENT) == 1)

			-- Process manually with handler that doesn't handle
			queues.process(TEST_EVENT, function(data)
				return nil -- Not handled
			end)

			-- Event should still be in queue
			assert(#queues.get_events(TEST_EVENT) == 1)
		end)

		it("Should pass context to handler", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local context_received = nil

			queues.subscribe(TEST_EVENT, function(self, data)
				context_received = self
				return true
			end, context)

			queues.push(TEST_EVENT, test_data)

			assert(context_received == context)
		end)

		it("Should pass context to on_handle callback", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local on_handle_context = nil

			queues.subscribe(TEST_EVENT, function(data)
				return true
			end)

			queues.push(TEST_EVENT, test_data, function(self)
				on_handle_context = self
			end, context)

			assert(on_handle_context == context)
		end)

		it("Should allow unsubscribing handlers", function()
			local test_data = "test_data"
			local handler_called = false

			local handler = function(data)
				handler_called = true
				return true
			end

			-- Subscribe
			queues.subscribe(TEST_EVENT, handler)

			-- Unsubscribe
			queues.unsubscribe(TEST_EVENT, handler)

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Handler should not be called
			assert(handler_called == false)

			-- Event should still be in queue
			assert(#queues.get_events(TEST_EVENT) == 1)
		end)

		it("Should check if handler is subscribed", function()
			local handler = function(data) return true end

			-- Not subscribed initially
			assert(queues.is_subscribed(TEST_EVENT, handler) == false)

			-- Subscribe
			queues.subscribe(TEST_EVENT, handler)

			-- Should be subscribed now
			assert(queues.is_subscribed(TEST_EVENT, handler) == true)

			-- Unsubscribe
			queues.unsubscribe(TEST_EVENT, handler)

			-- Should not be subscribed now
			assert(queues.is_subscribed(TEST_EVENT, handler) == false)
		end)

		it("Should check if handler is subscribed with context", function()
			local handler = function(self, data) return true end
			local context = { value = "context_value" }

			-- Not subscribed initially
			assert(queues.is_subscribed(TEST_EVENT, handler, context) == false)

			-- Subscribe with context
			queues.subscribe(TEST_EVENT, handler, context)

			-- Should be subscribed with context
			assert(queues.is_subscribed(TEST_EVENT, handler, context) == true)

			-- Should not be subscribed without context
			assert(queues.is_subscribed(TEST_EVENT, handler) == false)

			-- Unsubscribe with context
			queues.unsubscribe(TEST_EVENT, handler, context)

			-- Should not be subscribed now
			assert(queues.is_subscribed(TEST_EVENT, handler, context) == false)
		end)

		it("Should not subscribe the same handler twice", function()
			local test_data = "test_data"
			local handler_called_count = 0

			local handler = function(data)
				handler_called_count = handler_called_count + 1
				return true
			end

			-- Subscribe the same handler twice
			local first_subscribe_result = queues.subscribe(TEST_EVENT, handler)
			local second_subscribe_result = queues.subscribe(TEST_EVENT, handler)

			-- First subscription should succeed, second should fail
			assert(first_subscribe_result == true)
			assert(second_subscribe_result == false)

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Handler should be called exactly once
			assert(handler_called_count == 1)
		end)

		it("Should not subscribe the same handler+context combination twice", function()
			local test_data = "test_data"
			local handler_called_count = 0
			local context = { value = "context_value" }

			local handler = function(self, data)
				handler_called_count = handler_called_count + 1
				return true
			end

			-- Subscribe the same handler+context twice
			local first_subscribe_result = queues.subscribe(TEST_EVENT, handler, context)
			local second_subscribe_result = queues.subscribe(TEST_EVENT, handler, context)

			-- First subscription should succeed, second should fail
			assert(first_subscribe_result == true)
			assert(second_subscribe_result == false)

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Handler should be called exactly once
			assert(handler_called_count == 1)
		end)

		it("Should allow different context combinations for the same handler", function()
			local test_data = "test_data"
			local handler_called_count = 0
			local context1 = { value = "context1" }
			local context2 = { value = "context2" }

			local handler = function(self, data)
				handler_called_count = handler_called_count + 1
				return true
			end

			-- Subscribe the same handler with different contexts
			local first_subscribe_result = queues.subscribe(TEST_EVENT, handler, context1)
			local second_subscribe_result = queues.subscribe(TEST_EVENT, handler, context2)
			local third_subscribe_result = queues.subscribe(TEST_EVENT, handler) -- No context

			-- All subscriptions should succeed
			assert(first_subscribe_result == true)
			assert(second_subscribe_result == true)
			assert(third_subscribe_result == true)

			-- Push event
			queues.push(TEST_EVENT, test_data)

			-- Handler should be called three times (once for each context combination)
			assert(handler_called_count == 3)
		end)

		it("Should check if queue is empty", function()
			-- Initially should be empty
			assert(queues.is_empty(TEST_EVENT) == true)

			-- Push event
			queues.push(TEST_EVENT, "test_data")

			-- Should not be empty
			assert(queues.is_empty(TEST_EVENT) == false)

			-- Subscribe handler that handles the event
			queues.subscribe(TEST_EVENT, function(data)
				return true
			end)

			-- Should be empty again
			assert(queues.is_empty(TEST_EVENT) == true)
		end)

		it("Should check if queue has subscribers", function()
			-- Initially should have no subscribers
			assert(queues.has_subscribers(TEST_EVENT) == false)

			-- Subscribe handler
			queues.subscribe(TEST_EVENT, function(data)
				return true
			end)

			-- Should have subscribers
			assert(queues.has_subscribers(TEST_EVENT) == true)

			-- Clear subscribers
			queues.clear_subscribers(TEST_EVENT)

			-- Should have no subscribers again
			assert(queues.has_subscribers(TEST_EVENT) == false)
		end)

		it("Should process events in FIFO order (first in, first out)", function()
			local processed_order = {}

			-- Push multiple events
			queues.push(TEST_EVENT, "event1")
			queues.push(TEST_EVENT, "event2")
			queues.push(TEST_EVENT, "event3")

			-- Subscribe handler that processes events in order
			queues.subscribe(TEST_EVENT, function(data)
				table.insert(processed_order, data)
				return true -- Handle all events
			end)

			-- Verify events were processed in FIFO order
			assert(#processed_order == 3)
			assert(processed_order[1] == "event1")
			assert(processed_order[2] == "event2")
			assert(processed_order[3] == "event3")

			-- All events should be removed
			assert(#queues.get_events(TEST_EVENT) == 0)
		end)

		it("Should process events in FIFO order with manual processing", function()
			local processed_order = {}

			-- Push multiple events
			queues.push(TEST_EVENT, "event1")
			queues.push(TEST_EVENT, "event2")
			queues.push(TEST_EVENT, "event3")

			-- Process manually in order
			queues.process(TEST_EVENT, function(data)
				table.insert(processed_order, data)
				return true -- Handle all events
			end)

			-- Verify events were processed in FIFO order
			assert(#processed_order == 3)
			assert(processed_order[1] == "event1")
			assert(processed_order[2] == "event2")
			assert(processed_order[3] == "event3")

			-- All events should be removed
			assert(#queues.get_events(TEST_EVENT) == 0)
		end)
	end)
end

return test_queues
