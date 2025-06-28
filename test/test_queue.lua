local function test_queue()
	describe("Queue module", function()
		local queue ---@type queue
		local queue_instance ---@type queue

		before(function()
			queue = require("event.queue")
			queue_instance = queue.create()
		end)

		after(function()
			queue_instance:clear()
		end)

		it("Should call subscriber when event is pushed after subscription", function()
			local was_called = false
			local test_data = "test_data"

			queue_instance:subscribe(function(data)
				was_called = true
				assert(data == test_data)
				return true -- Mark as handled
			end)

			queue_instance:push(test_data)

			assert(was_called == true)
			assert(#queue_instance:get_events() == 0) -- Event should be removed
		end)

		it("Should call subscriber when subscription happens after event is pushed", function()
			local was_called = false
			local test_data = "test_data"

			-- Push event first
			queue_instance:push(test_data)

			-- Then subscribe
			queue_instance:subscribe(function(data)
				was_called = true
				assert(data == test_data)
				return true -- Mark as handled
			end)

			assert(was_called == true)
			assert(#queue_instance:get_events() == 0) -- Event should be removed
		end)

		it("Should remove event when handler returns non-nil value", function()
			local test_data = "test_data"

			-- Push event
			queue_instance:push(test_data)

			-- Event should be in queue
			assert(#queue_instance:get_events() == 1)

			-- Subscribe with handler that returns a value
			queue_instance:subscribe(function(data)
				return "some_value" -- Any non-nil value should work
			end)

			-- Event should be removed
			assert(#queue_instance:get_events() == 0)
		end)

		it("Should call on_handle callback when event is handled", function()
			local test_data = "test_data"
			local on_handle_called = false
			local handle_result_value = "handled"

			-- Subscribe
			queue_instance:subscribe(function(data)
				return handle_result_value
			end)

			-- Push with on_handle callback
			queue_instance:push(test_data, function(result)
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
			queue_instance:push(test_data)

			-- Subscribe multiple handlers
			queue_instance:subscribe(function(data)
				handler1_called = true
				return nil -- Don't handle it yet
			end)

			queue_instance:subscribe(function(data)
				handler2_called = true
				return nil -- Don't handle it yet
			end)

			-- Event should still be in queue
			assert(#queue_instance:get_events() == 1)
			assert(handler1_called == true)
			assert(handler2_called == true)

			-- Subscribe a handler that will handle it
			queue_instance:subscribe(function(data)
				handler3_called = true
				return true -- Handle it
			end)

			-- Event should be removed now
			assert(#queue_instance:get_events() == 0)
			assert(handler3_called == true)
		end)

		it("Should process events manually without subscribers", function()
			local test_data = "test_data"
			local was_called = false

			-- Push event
			queue_instance:push(test_data)

			-- Event should be in queue
			assert(#queue_instance:get_events() == 1)

			-- Process manually
			queue_instance:process(function(data)
				was_called = true
				assert(data == test_data)
				return true -- Handle it
			end)

			assert(was_called == true)
			assert(#queue_instance:get_events() == 0) -- Event should be removed
		end)

		it("Should keep events if not handled", function()
			local test_data = "test_data"

			-- Push event
			queue_instance:push(test_data)

			-- Subscribe with handler that doesn't handle
			queue_instance:subscribe(function(data)
				return nil -- Not handled
			end)

			-- Event should still be in queue
			assert(#queue_instance:get_events() == 1)

			-- Process manually with handler that doesn't handle
			queue_instance:process(function(data)
				return nil -- Not handled
			end)

			-- Event should still be in queue
			assert(#queue_instance:get_events() == 1)
		end)

		it("Should pass context to handler", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local context_received = nil

			queue_instance:subscribe(function(self, data)
				context_received = self
				return true
			end, context)

			queue_instance:push(test_data)

			assert(context_received == context)
		end)

		it("Should pass context to on_handle callback", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local on_handle_context = nil

			queue_instance:subscribe(function(data)
				return true
			end)

			queue_instance:push(test_data, function(self)
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
			queue_instance:subscribe(handler)

			-- Unsubscribe
			queue_instance:unsubscribe(handler)

			-- Push event
			queue_instance:push(test_data)

			-- Handler should not be called
			assert(handler_called == false)

			-- Event should still be in queue
			assert(#queue_instance:get_events() == 1)
		end)

		it("Should check if handler is subscribed", function()
			local handler = function(data) return true end

			-- Not subscribed initially
			assert(queue_instance:is_subscribed(handler) == false)

			-- Subscribe
			queue_instance:subscribe(handler)

			-- Should be subscribed now
			assert(queue_instance:is_subscribed(handler) == true)

			-- Unsubscribe
			queue_instance:unsubscribe(handler)

			-- Should not be subscribed now
			assert(queue_instance:is_subscribed(handler) == false)
		end)

		it("Should check if handler is subscribed with context", function()
			local handler = function(self, data) return true end
			local context = { value = "context_value" }

			-- Not subscribed initially
			assert(queue_instance:is_subscribed(handler, context) == false)

			-- Subscribe with context
			queue_instance:subscribe(handler, context)

			-- Should be subscribed with context
			assert(queue_instance:is_subscribed(handler, context) == true)

			-- Should not be subscribed without context
			assert(queue_instance:is_subscribed(handler) == false)

			-- Unsubscribe with context
			queue_instance:unsubscribe(handler, context)

			-- Should not be subscribed now
			assert(queue_instance:is_subscribed(handler, context) == false)
		end)

		it("Should not subscribe the same handler twice", function()
			local test_data = "test_data"
			local handler_called_count = 0

			local handler = function(data)
				handler_called_count = handler_called_count + 1
				return true
			end

			-- Subscribe the same handler twice
			local first_subscribe_result = queue_instance:subscribe(handler)
			local second_subscribe_result = queue_instance:subscribe(handler)

			-- First subscription should succeed, second should fail
			assert(first_subscribe_result == true)
			assert(second_subscribe_result == false)

			-- Push event
			queue_instance:push(test_data)

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
			local first_subscribe_result = queue_instance:subscribe(handler, context)
			local second_subscribe_result = queue_instance:subscribe(handler, context)

			-- First subscription should succeed, second should fail
			assert(first_subscribe_result == true)
			assert(second_subscribe_result == false)

			-- Push event
			queue_instance:push(test_data)

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
			local first_subscribe_result = queue_instance:subscribe(handler, context1)
			local second_subscribe_result = queue_instance:subscribe(handler, context2)
			local third_subscribe_result = queue_instance:subscribe(handler) -- No context

			-- All subscriptions should succeed
			assert(first_subscribe_result == true)
			assert(second_subscribe_result == true)
			assert(third_subscribe_result == true)

			-- Push event
			queue_instance:push(test_data)

			-- Handler should be called three times (once for each context combination)
			assert(handler_called_count == 3)
		end)

		it("Should call on_handle callback when processing with custom handler", function()
			local test_data = "test_data"
			local on_handle_called = false
			local expected_result = "processed_result"
			local actual_result = nil

			-- Push event with on_handle callback
			queue_instance:push(test_data, function(result)
				on_handle_called = true
				actual_result = result
			end)

			-- Event should be in queue
			assert(#queue_instance:get_events() == 1)

			-- Process with custom handler
			queue_instance:process(function(data)
				assert(data == test_data)
				return expected_result
			end)

			-- Verify on_handle callback was called with the result
			assert(on_handle_called == true)
			assert(actual_result == expected_result)

			-- Event should be removed
			assert(#queue_instance:get_events() == 0)
		end)

		it("Should process events with custom handler and context", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local context_received = nil

			-- Push event
			queue_instance:push(test_data)

			-- Process with custom handler and context
			queue_instance:process(function(self, data)
				context_received = self
				assert(data == test_data)
				return true
			end, context)

			-- Verify context was passed to handler
			assert(context_received == context)

			-- Event should be removed
			assert(#queue_instance:get_events() == 0)
		end)

		it("Should call on_handle callback with context when processing with custom handler", function()
			local test_data = "test_data"
			local handler_context = { value = "handler_context" }
			local on_handle_context = { value = "on_handle_context" }
			local handler_context_received = nil
			local on_handle_called = false
			local expected_result = "processed_result"
			local actual_result = nil

			-- Push event with on_handle callback and context
			queue_instance:push(test_data, function(self, result)
				on_handle_called = true
				assert(self == on_handle_context)
				actual_result = result
			end, on_handle_context)

			-- Process with custom handler and context
			queue_instance:process(function(self, data)
				handler_context_received = self
				assert(data == test_data)
				return expected_result
			end, handler_context)

			-- Verify contexts were passed correctly
			assert(handler_context_received == handler_context)
			assert(on_handle_called == true)
			assert(actual_result == expected_result)

			-- Event should be removed
			assert(#queue_instance:get_events() == 0)
		end)

		it("Should check if queue is empty", function()
			-- Initially should be empty
			assert(queue_instance:is_empty() == true)

			-- Push event
			queue_instance:push("test_data")

			-- Should not be empty
			assert(queue_instance:is_empty() == false)

			-- Subscribe handler that handles the event
			queue_instance:subscribe(function(data)
				return true
			end)

			-- Should be empty again
			assert(queue_instance:is_empty() == true)
		end)

		it("Should check if queue instance has subscribers", function()
			-- Initially should have no subscribers
			assert(queue_instance:has_subscribers() == false)

			-- Subscribe handler
			queue_instance:subscribe(function(data)
				return true
			end)

			-- Should have subscribers
			assert(queue_instance:has_subscribers() == true)

			-- Clear subscribers
			queue_instance:clear_subscribers()

			-- Should have no subscribers again
			assert(queue_instance:has_subscribers() == false)
		end)

		it("Should create queue instance with initial handler", function()
			local handler_called = false
			local test_data = "test_data"
			local context = { value = "context_value" }
			local context_received = nil

			-- Create queue with initial handler and context
			local queue_with_handler = queue.create(function(self, data)
				handler_called = true
				context_received = self
				assert(data == test_data)
				return true
			end, context)

			-- Push event
			queue_with_handler:push(test_data)

			-- Handler should be called
			assert(handler_called == true)
			assert(context_received == context)

			-- Event should be removed
			assert(#queue_with_handler:get_events() == 0)
		end)

		it("Should process events in FIFO order (first in, first out)", function()
			local processed_order = {}

			-- Push multiple events
			queue_instance:push("event1")
			queue_instance:push("event2")
			queue_instance:push("event3")

			-- Subscribe handler that processes events in order
			queue_instance:subscribe(function(data)
				table.insert(processed_order, data)
				return true -- Handle all events
			end)

			-- Verify events were processed in FIFO order
			assert(#processed_order == 3)
			assert(processed_order[1] == "event1")
			assert(processed_order[2] == "event2")
			assert(processed_order[3] == "event3")

			-- All events should be removed
			assert(#queue_instance:get_events() == 0)
		end)

		it("Should process events in FIFO order with manual processing", function()
			local processed_order = {}

			-- Push multiple events
			queue_instance:push("event1")
			queue_instance:push("event2")
			queue_instance:push("event3")

			-- Process manually in order
			queue_instance:process(function(data)
				table.insert(processed_order, data)
				return true -- Handle all events
			end)

			-- Verify events were processed in FIFO order
			assert(#processed_order == 3)
			assert(processed_order[1] == "event1")
			assert(processed_order[2] == "event2")
			assert(processed_order[3] == "event3")

			-- All events should be removed
			assert(#queue_instance:get_events() == 0)
		end)

		-- Event-based handler tests
		describe("Queue with Event Handlers", function()
			local event

			before(function()
				event = require("event.event")
			end)

			it("Should call event subscriber when event is pushed after subscription", function()
				local was_called = false
				local test_data = "test_data"
				local received_data = nil

				-- Create an event handler
				local handler_event = event.create(function(data)
					was_called = true
					received_data = data
					return true -- Mark as handled
				end)

				queue_instance:subscribe(handler_event)
				queue_instance:push(test_data)

				assert(was_called == true)
				assert(received_data == test_data)
				assert(#queue_instance:get_events() == 0) -- Event should be removed
			end)

			it("Should call event subscriber when subscription happens after event is pushed", function()
				local was_called = false
				local test_data = "test_data"
				local received_data = nil

				-- Push event first
				queue_instance:push(test_data)

				-- Then subscribe with event handler
				local handler_event = event.create(function(data)
					was_called = true
					received_data = data
					return true -- Mark as handled
				end)

				queue_instance:subscribe(handler_event)

				assert(was_called == true)
				assert(received_data == test_data)
				assert(#queue_instance:get_events() == 0) -- Event should be removed
			end)

			it("Should pass context to event handler", function()
				local test_data = "test_data"
				local context = { value = "context_value" }
				local context_received = nil
				local data_received = nil

				local handler_event = event.create(function(self, data)
					context_received = self
					data_received = data
					return true
				end, context)

				queue_instance:subscribe(handler_event)
				queue_instance:push(test_data)

				assert(context_received == context)
				assert(data_received == test_data)
			end)

			it("Should allow multiple event subscribers to handle the same event", function()
				local test_data = "test_data"
				local handler1_called = false
				local handler2_called = false
				local handler3_called = false

				-- Push event
				queue_instance:push(test_data)

				-- Subscribe multiple event handlers
				local handler1_event = event.create(function(data)
					handler1_called = true
					return nil -- Don't handle it yet
				end)

				local handler2_event = event.create(function(data)
					handler2_called = true
					return nil -- Don't handle it yet
				end)

				queue_instance:subscribe(handler1_event)
				queue_instance:subscribe(handler2_event)

				-- Event should still be in queue
				assert(#queue_instance:get_events() == 1)
				assert(handler1_called == true)
				assert(handler2_called == true)

				-- Subscribe an event handler that will handle it
				local handler3_event = event.create(function(data)
					handler3_called = true
					return true -- Handle it
				end)

				queue_instance:subscribe(handler3_event)

				-- Event should be removed now
				assert(#queue_instance:get_events() == 0)
				assert(handler3_called == true)
			end)

			it("Should process events manually with event handler", function()
				local test_data = "test_data"
				local was_called = false
				local received_data = nil

				-- Push event
				queue_instance:push(test_data)

				-- Event should be in queue
				assert(#queue_instance:get_events() == 1)

				-- Process manually with event handler
				local process_event = event.create(function(data)
					was_called = true
					received_data = data
					return true -- Handle it
				end)

				queue_instance:process(process_event)

				assert(was_called == true)
				assert(received_data == test_data)
				assert(#queue_instance:get_events() == 0) -- Event should be removed
			end)

			it("Should process events with event handler and context", function()
				local test_data = "test_data"
				local context = { value = "context_value" }
				local context_received = nil
				local data_received = nil

				-- Push event
				queue_instance:push(test_data)

				-- Process with event handler and context
				local process_event = event.create(function(self, data)
					context_received = self
					data_received = data
					return true
				end, context)

				queue_instance:process(process_event)

				-- Verify context was passed to handler
				assert(context_received == context)
				assert(data_received == test_data)

				-- Event should be removed
				assert(#queue_instance:get_events() == 0)
			end)

			it("Should call on_handle callback when event handler processes event", function()
				local test_data = "test_data"
				local on_handle_called = false
				local expected_result = "processed_result"
				local actual_result = nil

				-- Push event with on_handle callback
				queue_instance:push(test_data, function(result)
					on_handle_called = true
					actual_result = result
				end)

				-- Event should be in queue
				assert(#queue_instance:get_events() == 1)

				-- Process with event handler
				local process_event = event.create(function(data)
					assert(data == test_data)
					return expected_result
				end)

				queue_instance:process(process_event)

				-- Verify on_handle callback was called with the result
				assert(on_handle_called == true)
				assert(actual_result == expected_result)

				-- Event should be removed
				assert(#queue_instance:get_events() == 0)
			end)

			it("Should call on_handle callback with context when processing with event handler", function()
				local test_data = "test_data"
				local handler_context = { value = "handler_context" }
				local on_handle_context = { value = "on_handle_context" }
				local handler_context_received = nil
				local on_handle_called = false
				local expected_result = "processed_result"
				local actual_result = nil

				-- Push event with on_handle callback and context
				queue_instance:push(test_data, function(self, result)
					on_handle_called = true
					assert(self == on_handle_context)
					actual_result = result
				end, on_handle_context)

				-- Process with event handler and context
				local process_event = event.create(function(self, data)
					handler_context_received = self
					assert(data == test_data)
					return expected_result
				end, handler_context)

				queue_instance:process(process_event)

				-- Verify contexts were passed correctly
				assert(handler_context_received == handler_context)
				assert(on_handle_called == true)
				assert(actual_result == expected_result)

				-- Event should be removed
				assert(#queue_instance:get_events() == 0)
			end)

			it("Should create queue instance with initial event handler", function()
				local handler_called = false
				local test_data = "test_data"
				local context = { value = "context_value" }
				local context_received = nil

				-- Create event handler with context
				local initial_handler = event.create(function(self, data)
					handler_called = true
					context_received = self
					assert(data == test_data)
					return true
				end, context)

				-- Create queue with initial event handler
				local queue_with_handler = queue.create(initial_handler)

				-- Push event
				queue_with_handler:push(test_data)

				-- Handler should be called
				assert(handler_called == true)
				assert(context_received == context)

				-- Event should be removed
				assert(#queue_with_handler:get_events() == 0)
			end)

			it("Should allow unsubscribing event handlers", function()
				local test_data = "test_data"
				local handler_called = false

				local handler_event = event.create(function(data)
					handler_called = true
					return true
				end)

				-- Subscribe
				queue_instance:subscribe(handler_event)

				-- Unsubscribe
				queue_instance:unsubscribe(handler_event)

				-- Push event
				queue_instance:push(test_data)

				-- Handler should not be called
				assert(handler_called == false)

				-- Event should still be in queue
				assert(#queue_instance:get_events() == 1)
			end)

			it("Should check if event handler is subscribed", function()
				local handler_event = event.create(function(data) return true end)

				-- Not subscribed initially
				assert(queue_instance:is_subscribed(handler_event) == false)

				-- Subscribe
				queue_instance:subscribe(handler_event)

				-- Should be subscribed now
				assert(queue_instance:is_subscribed(handler_event) == true)

				-- Unsubscribe
				queue_instance:unsubscribe(handler_event)

				-- Should not be subscribed now
				assert(queue_instance:is_subscribed(handler_event) == false)
			end)

			it("Should not subscribe the same event handler twice", function()
				local test_data = "test_data"
				local handler_called_count = 0

				local handler_event = event.create(function(data)
					handler_called_count = handler_called_count + 1
					return true
				end)

				-- Subscribe the same event handler twice
				local first_subscribe_result = queue_instance:subscribe(handler_event)
				local second_subscribe_result = queue_instance:subscribe(handler_event)

				-- First subscription should succeed, second should fail
				assert(first_subscribe_result == true)
				assert(second_subscribe_result == false)

				-- Push event
				queue_instance:push(test_data)

				-- Handler should be called exactly once
				assert(handler_called_count == 1)
			end)

			it("Should process events in FIFO order with event handler", function()
				local processed_order = {}

				-- Push multiple events
				queue_instance:push("event1")
				queue_instance:push("event2")
				queue_instance:push("event3")

				-- Subscribe event handler that processes events in order
				local handler_event = event.create(function(data)
					table.insert(processed_order, data)
					return true -- Handle all events
				end)

				queue_instance:subscribe(handler_event)

				-- Verify events were processed in FIFO order
				assert(#processed_order == 3)
				assert(processed_order[1] == "event1")
				assert(processed_order[2] == "event2")
				assert(processed_order[3] == "event3")

				-- All events should be removed
				assert(#queue_instance:get_events() == 0)
			end)

			it("Should handle event with multiple subscribers in event handler", function()
				local test_data = "broadcast_data"
				local subscriber1_called = false
				local subscriber2_called = false
				local received_values = {}

				-- Create an event with multiple subscribers
				local broadcast_event = event.create()
				broadcast_event:subscribe(function(data)
					subscriber1_called = true
					table.insert(received_values, "sub1_" .. data)
				end)
				broadcast_event:subscribe(function(data)
					subscriber2_called = true
					table.insert(received_values, "sub2_" .. data)
					return true  -- Only last return value is used for queue handling
				end)

				queue_instance:subscribe(broadcast_event)
				queue_instance:push(test_data)

				assert(subscriber1_called == true)
				assert(subscriber2_called == true)
				assert(#received_values == 2)
				assert(received_values[1] == "sub1_broadcast_data")
				assert(received_values[2] == "sub2_broadcast_data")
				assert(#queue_instance:get_events() == 0) -- Event should be handled
			end)

			it("Should mix function and event handlers", function()
				local test_data = "mixed_data"
				local function_called = false
				local event_called = false

				-- Subscribe function handler
				queue_instance:subscribe(function(data)
					function_called = true
					return nil -- Don't handle yet
				end)

				-- Subscribe event handler
				local event_handler = event.create(function(data)
					event_called = true
					return true -- Handle it
				end)

				queue_instance:subscribe(event_handler)

				-- Push event
				queue_instance:push(test_data)

				-- Both should be called
				assert(function_called == true)
				assert(event_called == true)

				-- Event should be handled
				assert(#queue_instance:get_events() == 0)
			end)
		end)
	end)
end

return test_queue
