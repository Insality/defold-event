local function test_defer()
	describe("Defer module", function()
		local defer ---@type event.defer
		local TEST_EVENT = "test_event"

		before(function()
			defer = require("event.defer")
			defer.clear_all()
		end)

		after(function()
			defer.clear_all()
		end)

		it("Should call subscriber when event is pushed after subscription", function()
			local was_called = false
			local test_data = "test_data"

			defer.subscribe(TEST_EVENT, function(data)
				was_called = true
				assert(data == test_data)
				return true -- Mark as handled
			end)

			defer.push(TEST_EVENT, test_data)

			assert(was_called == true)
			assert(#defer.get_events(TEST_EVENT) == 0) -- Event should be removed
		end)

		it("Should call subscriber when subscription happens after event is pushed", function()
			local was_called = false
			local test_data = "test_data"

			-- Push event first
			defer.push(TEST_EVENT, test_data)

			-- Then subscribe
			defer.subscribe(TEST_EVENT, function(data)
				was_called = true
				assert(data == test_data)
				return true -- Mark as handled
			end)

			assert(was_called == true)
			assert(#defer.get_events(TEST_EVENT) == 0) -- Event should be removed
		end)

		it("Should remove event when handler returns non-nil value", function()
			local test_data = "test_data"

			-- Push event
			defer.push(TEST_EVENT, test_data)

			-- Event should be in queue
			assert(#defer.get_events(TEST_EVENT) == 1)

			-- Subscribe with handler that returns a value
			defer.subscribe(TEST_EVENT, function(data)
				return "some_value" -- Any non-nil value should work
			end)

			-- Event should be removed
			assert(#defer.get_events(TEST_EVENT) == 0)
		end)

		it("Should call on_handle callback when event is handled", function()
			local test_data = "test_data"
			local on_handle_called = false
			local handle_result_value = "handled"

			-- Subscribe
			defer.subscribe(TEST_EVENT, function(data)
				return handle_result_value
			end)

			-- Push with on_handle callback
			defer.push(TEST_EVENT, test_data, function(result)
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
			defer.push(TEST_EVENT, test_data)

			-- Subscribe multiple handlers
			defer.subscribe(TEST_EVENT, function(data)
				handler1_called = true
				return nil -- Don't handle it yet
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler2_called = true
				return nil -- Don't handle it yet
			end)

			-- Event should still be in queue
			assert(#defer.get_events(TEST_EVENT) == 1)
			assert(handler1_called == true)
			assert(handler2_called == true)

			-- Subscribe a handler that will handle it
			defer.subscribe(TEST_EVENT, function(data)
				handler3_called = true
				return true -- Handle it
			end)

			-- Event should be removed now
			assert(#defer.get_events(TEST_EVENT) == 0)
			assert(handler3_called == true)
		end)

		it("Should process events manually without subscribers", function()
			local test_data = "test_data"
			local was_called = false

			-- Push event
			defer.push(TEST_EVENT, test_data)

			-- Event should be in queue
			assert(#defer.get_events(TEST_EVENT) == 1)

			-- Process manually
			defer.process(TEST_EVENT, function(data)
				was_called = true
				assert(data == test_data)
				return true -- Handle it
			end)

			assert(was_called == true)
			assert(#defer.get_events(TEST_EVENT) == 0) -- Event should be removed
		end)

		it("Should keep events if not handled", function()
			local test_data = "test_data"

			-- Push event
			defer.push(TEST_EVENT, test_data)

			-- Subscribe with handler that doesn't handle
			defer.subscribe(TEST_EVENT, function(data)
				return nil -- Not handled
			end)

			-- Event should still be in queue
			assert(#defer.get_events(TEST_EVENT) == 1)

			-- Process manually with handler that doesn't handle
			defer.process(TEST_EVENT, function(data)
				return nil -- Not handled
			end)

			-- Event should still be in queue
			assert(#defer.get_events(TEST_EVENT) == 1)
		end)

		it("Should pass context to handler", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local context_received = nil

			defer.subscribe(TEST_EVENT, function(self, data)
				context_received = self
				return true
			end, context)

			defer.push(TEST_EVENT, test_data)

			assert(context_received == context)
		end)

		it("Should pass context to on_handle callback", function()
			local test_data = "test_data"
			local context = { value = "context_value" }
			local on_handle_context = nil

			defer.subscribe(TEST_EVENT, function(data)
				return true
			end)

			defer.push(TEST_EVENT, test_data, function(self)
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
			defer.subscribe(TEST_EVENT, handler)

			-- Unsubscribe
			defer.unsubscribe(TEST_EVENT, handler)

			-- Push event
			defer.push(TEST_EVENT, test_data)

			-- Handler should not be called
			assert(handler_called == false)

			-- Event should still be in queue
			assert(#defer.get_events(TEST_EVENT) == 1)
		end)

		it("Should call subscribers in the order they were subscribed", function()
			local test_data = "test_data"
			local call_order = {}
			local handler1_called = false
			local handler2_called = false
			local handler3_called = false

			-- Subscribe handlers in specific order
			defer.subscribe(TEST_EVENT, function(data)
				handler1_called = true
				table.insert(call_order, 1)
				return nil -- Don't handle it yet
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler2_called = true
				table.insert(call_order, 2)
				return nil -- Don't handle it yet
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler3_called = true
				table.insert(call_order, 3)
				return true -- Handle it
			end)

			-- Push event after all subscriptions
			defer.push(TEST_EVENT, test_data)

			-- Verify handlers were called in the correct order
			assert(handler1_called == true)
			assert(handler2_called == true)
			assert(handler3_called == true)
			assert(call_order[1] == 1)
			assert(call_order[2] == 2)
			assert(call_order[3] == 3)
			assert(#call_order == 3)

			-- Event should be removed now
			assert(#defer.get_events(TEST_EVENT) == 0)
		end)

		it("Should call all subscribers and handle the event if any returns non-nil", function()
			local test_data = "test_data"
			local handler1_called = false
			local handler2_called = false

			-- Subscribe handlers
			defer.subscribe(TEST_EVENT, function(data)
				handler1_called = true
				return true -- Handle it
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler2_called = true
				return true -- Also handle it
			end)

			-- Push event
			defer.push(TEST_EVENT, test_data)

			-- Both handlers should be called
			assert(handler1_called == true)
			assert(handler2_called == true)

			-- Event should be removed
			assert(#defer.get_events(TEST_EVENT) == 0)

			-- Reset and test with multiple events
			defer.clear_all()
			handler1_called = false
			handler2_called = false

			-- Push two events
			defer.push(TEST_EVENT, "event1")
			defer.push(TEST_EVENT, "event2")

			-- Subscribe handlers
			defer.subscribe(TEST_EVENT, function(data)
				handler1_called = true
				if data == "event1" then
					return true -- Handle first event
				end
				return nil -- Don't handle second event
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler2_called = true
				return true -- Handle all events
			end)

			-- Both handlers should be called for both events
			assert(handler1_called == true)
			assert(handler2_called == true)

			-- Both events should be removed
			assert(#defer.get_events(TEST_EVENT) == 0)
		end)

		it("Should call all subscribers and call on_handle for each subscriber that handles the event", function()
			local test_data = "test_data"
			local handler1_called = false
			local handler2_called = false
			local handler3_called = false
			local on_handle_results = {}

			-- Subscribe handlers
			defer.subscribe(TEST_EVENT, function(data)
				handler1_called = true
				return "result1"
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler2_called = true
			end)

			defer.subscribe(TEST_EVENT, function(data)
				handler3_called = true
				return "result3"
			end)

			-- Push event with on_handle callback
			defer.push(TEST_EVENT, test_data, function(result)
				table.insert(on_handle_results, result)
			end)

			-- Both handlers should be called
			assert(handler1_called == true)
			assert(handler2_called == true)
			assert(handler3_called == true)
			-- on_handle should be called with the first result
			assert(on_handle_results[1] == "result1")
			assert(on_handle_results[2] == "result3")

			-- Event should be removed
			assert(#defer.get_events(TEST_EVENT) == 0)
		end)
	end)
end

return test_defer
