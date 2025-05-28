return function()
	describe("Defold Event Promise", function()
		local promise ---@type promise

		before(function()
			promise = require("event.promise")
		end)

		it("Create Promise", function()
			local test_promise = promise.create()
			assert(test_promise)
			assert(test_promise:is_pending())
			assert(not test_promise:is_resolved())
			assert(not test_promise:is_rejected())
			assert(not test_promise:is_finished())
		end)

		it("Create Promise with executor", function()
			local executed = false
			local resolve_func, reject_func

			local test_promise = promise.create(function(resolve, reject)
				executed = true
				resolve_func = resolve
				reject_func = reject
				assert(type(resolve) == "function")
				assert(type(reject) == "function")
			end)

			assert(executed)
			assert(test_promise:is_pending())
		end)

		it("Create Promise with event executor", function()
			local event = require("event.event")
			local executed = false
			local resolve_func, reject_func

			local executor_event = event.create(function(resolve, reject)
				executed = true
				resolve_func = resolve
				reject_func = reject
				assert(type(resolve) == "function")
				assert(type(reject) == "function")
			end)

			local test_promise = promise.create(executor_event)

			assert(executed)
			assert(test_promise:is_pending())
			assert(type(resolve_func) == "function")
			assert(type(reject_func) == "function")
		end)

		it("Create Promise with event executor that resolves immediately", function()
			local event = require("event.event")

			local executor_event = event.create(function(resolve, reject)
				resolve("immediate_value")
			end)

			local test_promise = promise.create(executor_event)

			assert(test_promise:is_resolved())
			assert(test_promise.value == "immediate_value")
		end)

		it("Create Promise with event executor that rejects immediately", function()
			local event = require("event.event")

			local executor_event = event.create(function(resolve, reject)
				reject("immediate_error")
			end)

			local test_promise = promise.create(executor_event)

			assert(test_promise:is_rejected())
			assert(test_promise.value == "immediate_error")
		end)

		it("Create Promise with event executor using context", function()
			local event = require("event.event")
			local context = { value = "context_value", delay = false }
			local received_context = nil

			local executor_event = event.create(function(self, resolve, reject)
				received_context = self
				if self.delay then
					-- Could be used for delayed execution
					return
				else
					resolve(self.value)
				end
			end, context)

			local test_promise = promise.create(executor_event)

			assert(received_context == context)
			assert(test_promise:is_resolved())
			assert(test_promise.value == "context_value")
		end)

		it("Create Promise with event executor that has multiple subscribers", function()
			local event = require("event.event")
			local subscriber1_called = false
			local subscriber2_called = false

			local executor_event = event.create()
			executor_event:subscribe(function(resolve, reject)
				subscriber1_called = true
				-- First subscriber doesn't resolve
			end)
			executor_event:subscribe(function(resolve, reject)
				subscriber2_called = true
				resolve("multi_subscriber_value")
			end)

			local test_promise = promise.create(executor_event)

			assert(subscriber1_called == true)
			assert(subscriber2_called == true)
			assert(test_promise:is_resolved())
			assert(test_promise.value == "multi_subscriber_value")
		end)

		it("Promise.fulfill creates resolved promise", function()
			local test_promise = promise.resolved("test_value")
			assert(test_promise:is_resolved())
			assert(not test_promise:is_pending())
			assert(not test_promise:is_rejected())
			assert(test_promise:is_finished())
			assert(test_promise.value == "test_value")
			assert(test_promise.state == "resolved")
		end)

		it("Promise.reject creates rejected promise", function()
			local test_promise = promise.rejected("test_reason")
			assert(test_promise:is_rejected())
			assert(not test_promise:is_pending())
			assert(not test_promise:is_resolved())
			assert(test_promise:is_finished())
			assert(test_promise.value == "test_reason")
			assert(test_promise.state == "rejected")
		end)

		it("Manual fulfill by calling promise", function()
			local test_promise = promise.create()
			assert(test_promise:is_pending())

			test_promise("manual_value")
			assert(test_promise:is_resolved())
			assert(test_promise.value == "manual_value")
		end)

		it("Manual reject by calling promise", function()
			local test_promise = promise.create()
			assert(test_promise:is_pending())

			test_promise(nil, "manual_reason")
			assert(test_promise:is_rejected())
			assert(test_promise.value == "manual_reason")
		end)

		it("Cannot fulfill already resolved promise", function()
			local test_promise = promise.resolved("first_value")
			test_promise("second_value")
			assert(test_promise.value == "first_value")
		end)

		it("Cannot reject already rejected promise", function()
			local test_promise = promise.rejected("first_reason")
			test_promise(nil, "second_reason")
			assert(test_promise.value == "first_reason")
		end)

		it("Executor resolve", function()
			local test_promise = promise.create(function(resolve, reject)
				resolve("executor_value")
			end)

			assert(test_promise:is_resolved())
			assert(test_promise.value == "executor_value")
		end)

		it("Executor reject", function()
			local test_promise = promise.create(function(resolve, reject)
				reject("executor_reason")
			end)

			assert(test_promise:is_rejected())
			assert(test_promise.value == "executor_reason")
		end)

		it("Promise next with fulfillment", function()
			local test_promise = promise.resolved("initial_value")
			local result_received = nil

			local next_promise = test_promise:next(function(value)
				result_received = value
				return "transformed_value"
			end)

			assert(result_received == "initial_value")
			assert(next_promise:is_resolved())
			assert(next_promise.value == "transformed_value")
		end)

		it("Promise next with rejection", function()
			local test_promise = promise.rejected("initial_reason")
			local reason_received = nil

			local next_promise = test_promise:next(nil, function(reason)
				reason_received = reason
				return "handled_value"
			end)

			assert(reason_received == "initial_reason")
			assert(next_promise:is_resolved())
			assert(next_promise.value == "handled_value")
		end)

		it("Promise next chaining", function()
			local test_promise = promise.resolved(1)

			local final_promise = test_promise
				:next(function(value) return value + 1 end)
				:next(function(value) return value * 2 end)
				:next(function(value) return "result: " .. value end)

			assert(final_promise:is_resolved())
			assert(final_promise.value == "result: 4")
		end)

		it("Promise next with pending promise", function()
			local test_promise = promise.create()
			local handler_called = false
			local received_value = nil

			local next_promise = test_promise:next(function(value)
				handler_called = true
				received_value = value
				return "handled_" .. value
			end)

			assert(not handler_called)
			assert(next_promise:is_pending())

			test_promise("delayed_value")

			assert(handler_called)
			assert(received_value == "delayed_value")
			assert(next_promise:is_resolved())
			assert(next_promise.value == "handled_delayed_value")
		end)

		it("Promise next returning promise", function()
			local test_promise = promise.resolved("initial")
			local inner_promise = promise.resolved("inner_value")

			local next_promise = test_promise:next(function(value)
				return inner_promise
			end)

			assert(next_promise:is_resolved())
			assert(next_promise.value == "inner_value")
		end)

		it("Promise next returning pending promise", function()
			local test_promise = promise.resolved("initial")
			local inner_promise = promise.create()

			local next_promise = test_promise:next(function(value)
				return inner_promise
			end)

			assert(next_promise:is_pending())

			inner_promise("delayed_inner_value")

			assert(next_promise:is_resolved())
			assert(next_promise.value == "delayed_inner_value")
		end)

		it("Promise catch", function()
			local test_promise = promise.rejected("error_reason")
			local caught_reason = nil

			local catch_promise = test_promise:catch(function(reason)
				caught_reason = reason
				return "caught_value"
			end)

			assert(caught_reason == "error_reason")
			assert(catch_promise:is_resolved())
			assert(catch_promise.value == "caught_value")
		end)

		it("Promise catch with resolved promise", function()
			local test_promise = promise.resolved("success_value")
			local catch_called = false

			local catch_promise = test_promise:catch(function(reason)
				catch_called = true
				return "caught_value"
			end)

			assert(not catch_called)
			assert(catch_promise:is_resolved())
			assert(catch_promise.value == "success_value")
		end)

		it("Promise finally", function()
			local finally_called = false
			local test_promise = promise.resolved("success_value")

			local final_promise = test_promise:finally(function()
				finally_called = true
			end)

			assert(finally_called)
			assert(final_promise:is_resolved())
			assert(final_promise.value == "success_value")
		end)

		it("Promise finally with rejection", function()
			local finally_called = false
			local test_promise = promise.rejected("error_reason")

			local final_promise = test_promise:finally(function()
				finally_called = true
			end)

			assert(finally_called)
			assert(final_promise:is_rejected())
			assert(final_promise.value == "error_reason")
		end)

		it("Promise.all with all resolved", function()
			local promise1 = promise.resolved("value1")
			local promise2 = promise.resolved("value2")
			local promise3 = promise.resolved("value3")

			local all_promise = promise.all({promise1, promise2, promise3})

			assert(all_promise:is_resolved())
			local result = all_promise.value
			assert(result[1] == "value1")
			assert(result[2] == "value2")
			assert(result[3] == "value3")
		end)

		it("Promise.all with empty array", function()
			local all_promise = promise.all({})
			assert(all_promise:is_resolved())
			assert(#all_promise.value == 0)
		end)

		it("Promise.all with one rejected", function()
			local promise1 = promise.resolved("value1")
			local promise2 = promise.rejected("error2")
			local promise3 = promise.resolved("value3")

			local all_promise = promise.all({promise1, promise2, promise3})

			assert(all_promise:is_rejected())
			assert(all_promise.value == "error2")
		end)

		it("Promise.all with pending promises", function()
			local promise1 = promise.create()
			local promise2 = promise.create()
			local promise3 = promise.resolved("value3")

			local all_promise = promise.all({promise1, promise2, promise3})
			assert(all_promise:is_pending())

			promise1("value1")
			assert(all_promise:is_pending())

			promise2("value2")
			assert(all_promise:is_resolved())

			local result = all_promise.value
			assert(result[1] == "value1")
			assert(result[2] == "value2")
			assert(result[3] == "value3")
		end)

		it("Promise.race with first resolved", function()
			local promise1 = promise.resolved("first_value")
			local promise2 = promise.create()
			local promise3 = promise.create()

			local race_promise = promise.race({promise1, promise2, promise3})

			assert(race_promise:is_resolved())
			assert(race_promise.value == "first_value")
		end)

		it("Promise.race with first rejected", function()
			local promise1 = promise.rejected("first_error")
			local promise2 = promise.create()
			local promise3 = promise.create()

			local race_promise = promise.race({promise1, promise2, promise3})

			assert(race_promise:is_rejected())
			assert(race_promise.value == "first_error")
		end)

		it("Promise.race with pending promises", function()
			local promise1 = promise.create()
			local promise2 = promise.create()
			local promise3 = promise.create()

			local race_promise = promise.race({promise1, promise2, promise3})
			assert(race_promise:is_pending())

			promise2("second_wins")
			assert(race_promise:is_resolved())
			assert(race_promise.value == "second_wins")

			-- Other promises shouldn't affect the result
			promise1("first_late")
			promise3(nil, "third_late")
			assert(race_promise.value == "second_wins")
		end)

		it("Promise.race with empty array", function()
			local race_promise = promise.race({})
			assert(race_promise:is_pending()) -- Never resolves
		end)

		it("Complex promise chain", function()
			local step1_called = false
			local step2_called = false
			local step3_called = false
			local finally_called = false

			local initial_promise = promise.create(function(resolve, reject)
				resolve("start")
			end)

			local final_result = initial_promise
				:next(function(value)
					step1_called = true
					assert(value == "start")
					return promise.resolved("step1_" .. value)
				end)
				:next(function(value)
					step2_called = true
					assert(value == "step1_start")
					return "step2_" .. value
				end)
				:next(function(value)
					step3_called = true
					assert(value == "step2_step1_start")
					return "final_" .. value
				end)
				:finally(function()
					finally_called = true
				end)

			assert(step1_called)
			assert(step2_called)
			assert(step3_called)
			assert(finally_called)
			assert(final_result:is_resolved())
			assert(final_result.value == "final_step2_step1_start")
		end)

		it("Promise resolution with another promise", function()
			local inner_promise = promise.resolved("inner_value")
			local outer_promise = promise.create()

			outer_promise(inner_promise)

			assert(outer_promise:is_resolved())
			assert(outer_promise.value == "inner_value")
		end)

		it("Promise resolution with pending promise", function()
			local inner_promise = promise.create()
			local outer_promise = promise.create()

			outer_promise(inner_promise)
			assert(outer_promise:is_pending())

			inner_promise("delayed_value")
			assert(outer_promise:is_resolved())
			assert(outer_promise.value == "delayed_value")
		end)

		it("Promise resolution with rejected promise", function()
			local inner_promise = promise.rejected("inner_error")
			local outer_promise = promise.create()

			outer_promise(inner_promise)

			assert(outer_promise:is_rejected())
			assert(outer_promise.value == "inner_error")
		end)

		-- Event-based callback tests
		describe("Promise with Event Callbacks", function()
			local event

			before(function()
				event = require("event.event")
			end)

			it("Promise next with event as fulfillment handler", function()
				local test_promise = promise.resolved("initial_value")
				local received_value = nil
				local transformed_value = "transformed_by_event"

				-- Create an event that transforms the value
				local fulfillment_event = event.create(function(value)
					received_value = value
					return transformed_value
				end)

				local next_promise = test_promise:next(fulfillment_event)

				assert(received_value == "initial_value")
				assert(next_promise:is_resolved())
				assert(next_promise.value == transformed_value)
			end)

			it("Promise next with event as rejection handler", function()
				local test_promise = promise.rejected("initial_reason")
				local received_reason = nil
				local handled_value = "handled_by_event"

				-- Create an event that handles the rejection
				local rejection_event = event.create(function(reason)
					received_reason = reason
					return handled_value
				end)

				local next_promise = test_promise:next(nil, rejection_event)

				assert(received_reason == "initial_reason")
				assert(next_promise:is_resolved())
				assert(next_promise.value == handled_value)
			end)

			it("Promise next with both fulfillment and rejection events", function()
				local resolved_promise = promise.resolved("success_value")
				local rejected_promise = promise.rejected("error_reason")

				local fulfillment_called = false
				local rejection_called = false

				local fulfillment_event = event.create(function(value)
					fulfillment_called = true
					return "resolved_" .. value
				end)

				local rejection_event = event.create(function(reason)
					rejection_called = true
					return "rejected_" .. reason
				end)

				-- Test resolved promise
				local resolved_next = resolved_promise:next(fulfillment_event, rejection_event)
				assert(fulfillment_called == true)
				assert(rejection_called == false)
				assert(resolved_next.value == "resolved_success_value")

				-- Reset flags
				fulfillment_called = false
				rejection_called = false

				-- Test rejected promise
				local rejected_next = rejected_promise:next(fulfillment_event, rejection_event)
				assert(fulfillment_called == false)
				assert(rejection_called == true)
				assert(rejected_next.value == "rejected_error_reason")
			end)

			it("Promise catch with event handler", function()
				local test_promise = promise.rejected("error_reason")
				local caught_reason = nil
				local handled_value = "caught_by_event"

				local catch_event = event.create(function(reason)
					caught_reason = reason
					return handled_value
				end)

				local catch_promise = test_promise:catch(catch_event)

				assert(caught_reason == "error_reason")
				assert(catch_promise:is_resolved())
				assert(catch_promise.value == handled_value)
			end)

			it("Promise catch with event handler on resolved promise", function()
				local test_promise = promise.resolved("success_value")
				local catch_called = false

				local catch_event = event.create(function(reason)
					catch_called = true
					return "should_not_be_called"
				end)

				local catch_promise = test_promise:catch(catch_event)

				assert(catch_called == false)
				assert(catch_promise:is_resolved())
				assert(catch_promise.value == "success_value")
			end)

			it("Promise finally with event handler", function()
				local finally_called = false
				local test_promise = promise.resolved("success_value")

				local finally_event = event.create(function()
					finally_called = true
				end)

				local final_promise = test_promise:finally(finally_event)

				assert(finally_called == true)
				assert(final_promise:is_resolved())
				assert(final_promise.value == "success_value")
			end)

			it("Promise finally with event handler on rejection", function()
				local finally_called = false
				local test_promise = promise.rejected("error_reason")

				local finally_event = event.create(function()
					finally_called = true
				end)

				local final_promise = test_promise:finally(finally_event)

				assert(finally_called == true)
				assert(final_promise:is_rejected())
				assert(final_promise.value == "error_reason")
			end)

			it("Promise next with event returning another promise", function()
				local test_promise = promise.resolved("initial")
				local inner_promise = promise.resolved("inner_value")

				local event_handler = event.create(function(value)
					return inner_promise
				end)

				local next_promise = test_promise:next(event_handler)

				assert(next_promise:is_resolved())
				assert(next_promise.value == "inner_value")
			end)

			it("Promise next with event returning pending promise", function()
				local test_promise = promise.resolved("initial")
				local inner_promise = promise.create()

				local event_handler = event.create(function(value)
					return inner_promise
				end)

				local next_promise = test_promise:next(event_handler)

				assert(next_promise:is_pending())

				inner_promise("delayed_inner_value")

				assert(next_promise:is_resolved())
				assert(next_promise.value == "delayed_inner_value")
			end)

			it("Promise chaining with mixed function and event handlers", function()
				local test_promise = promise.resolved(10)
				local step1_called = false
				local step2_called = false
				local step3_called = false

				-- Step 1: Function handler
				local step1_promise = test_promise:next(function(value)
					step1_called = true
					return value * 2
				end)

				-- Step 2: Event handler
				local step2_event = event.create(function(value)
					step2_called = true
					return value + 5
				end)
				local step2_promise = step1_promise:next(step2_event)

				-- Step 3: Function handler
				local step3_promise = step2_promise:next(function(value)
					step3_called = true
					return "result: " .. value
				end)

				assert(step1_called == true)
				assert(step2_called == true)
				assert(step3_called == true)
				assert(step3_promise:is_resolved())
				assert(step3_promise.value == "result: 25")
			end)

			it("Promise with event handler that has context", function()
				local test_promise = promise.resolved("test_value")
				local context = { multiplier = 3 }
				local received_context = nil
				local received_value = nil

				local context_event = event.create(function(self, value)
					received_context = self
					received_value = value
					return value .. "_" .. self.multiplier
				end, context)

				local next_promise = test_promise:next(context_event)

				assert(received_context == context)
				assert(received_value == "test_value")
				assert(next_promise:is_resolved())
				assert(next_promise.value == "test_value_3")
			end)

			it("Promise with event that triggers multiple subscribers", function()
				local test_promise = promise.resolved("broadcast_value")
				local subscriber1_called = false
				local subscriber2_called = false
				local received_values = {}

				-- Create an event with multiple subscribers
				local broadcast_event = event.create()
				broadcast_event:subscribe(function(value)
					subscriber1_called = true
					table.insert(received_values, "sub1_" .. value)
				end)
				broadcast_event:subscribe(function(value)
					subscriber2_called = true
					table.insert(received_values, "sub2_" .. value)
					return "final_result"  -- Only last return value is used
				end)

				local next_promise = test_promise:next(broadcast_event)

				assert(subscriber1_called == true)
				assert(subscriber2_called == true)
				assert(#received_values == 2)
				assert(received_values[1] == "sub1_broadcast_value")
				assert(received_values[2] == "sub2_broadcast_value")
				assert(next_promise:is_resolved())
				assert(next_promise.value == "final_result")
			end)
		end)
	end)
end
