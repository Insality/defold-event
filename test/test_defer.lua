local defer = require("event.defer")

local function test_defer()
	describe("Defer module", function()
		local TEST_EVENT = "test_event"

		local function reset()
			defer.clear(TEST_EVENT)
			defer.clear_subscribers(TEST_EVENT)
		end

		before(reset)
		after(reset)

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
	end)
end

return test_defer
