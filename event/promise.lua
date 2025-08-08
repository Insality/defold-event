local event = require("event.event")

---@alias promise.state "pending" | "resolved" | "rejected"

---The Promise module, used to create and manage promises.
---A promise represents a single asynchronous operation that will either resolve with a value or reject with a reason.
---@overload fun(value:any, reason:any|nil): nil Call the promise to resolve it with value or reject it with reason if value is nil
---@class promise
---@field state promise.state Current state of the promise (pending, resolved, rejected)
---@field value any The resolved value or rejection reason
---@field private resolve_handlers event Event for resolve handlers
---@field private reject_handlers event Event for rejection handlers
local M = {}

-- Forward declaration
local PROMISE_METATABLE


---Generate a new promise instance. This instance represents a single asynchronous operation.
---The executor function is called immediately with resolve and reject functions.
---@param executor function|event|nil The function or event that will be called with resolve and reject functions. Optional for manual promise creation.
---@return promise promise_instance A new promise instance.
function M.create(executor)
	local self = setmetatable({
		state = "pending",
		value = nil,
		resolve_handlers = event.create(),
		reject_handlers = event.create()
	}, PROMISE_METATABLE)

	if executor then
		local resolve_func = function(value) self:resolve(value) end
		local reject_func = function(reason) self:_reject(reason) end
		executor(resolve_func, reject_func)
	end

	return self
end


---Create a promise that is immediately resolved with the given value.
---@param value any The value to resolve the promise with.
---@return promise promise_instance A resolved promise.
---@nodiscard
function M.resolved(value)
	local promise_instance = M.create()
	promise_instance:resolve(value)
	return promise_instance
end


---Create a promise that is immediately rejected with the given reason.
---@param reason any The reason to reject the promise with.
---@return promise promise_instance A rejected promise.
---@nodiscard
function M.rejected(reason)
	local promise_instance = M.create()
	promise_instance:reject(reason)
	return promise_instance
end


---Create a promise that resolves when all given promises resolve.
---If any promise rejects, the returned promise will reject with that reason.
---@param promises promise[] Array of promises to wait for.
---@return promise promise_instance A promise that resolves with an array of all resolved values.
---@nodiscard
function M.all(promises)
	if #promises == 0 then
		return M.resolved({})
	end

	local result_promise = M.create()
	local results = {}
	local completed_count = 0
	local total_count = #promises

	local function check_completion()
		if completed_count == total_count then
			result_promise:resolve(results)
		end
	end

	for i, promise_instance in ipairs(promises) do
		if promise_instance:is_resolved() then
			results[i] = promise_instance.value
			completed_count = completed_count + 1
		elseif promise_instance:is_rejected() then
			result_promise:reject(promise_instance.value)
			return result_promise
		else
			promise_instance:next(function(value)
				results[i] = value
				completed_count = completed_count + 1
				check_completion()
			end, function(reason)
				result_promise:reject(reason)
			end)
		end
	end

	check_completion()
	return result_promise
end


---Create a promise that resolves or rejects as soon as one of the given promises resolves or rejects.
---@param promises promise[] Array of promises to race.
---@return promise promise_instance A promise that resolves or rejects with the first finished promise.
---@nodiscard
function M.race(promises)
	if #promises == 0 then
		return M.create() -- Never resolves
	end

	local result_promise = M.create()

	for _, promise_instance in ipairs(promises) do
		if promise_instance:is_finished() then
			if promise_instance:is_resolved() then
				result_promise:resolve(promise_instance.value)
			else
				result_promise:reject(promise_instance.value)
			end
			break
		else
			promise_instance:next(function(value)
				if result_promise:is_pending() then
					result_promise:resolve(value)
				end
			end, function(reason)
				if result_promise:is_pending() then
					result_promise:reject(reason)
				end
			end)
		end
	end

	return result_promise
end


---Check if a value is a promise object
---@param value any The value to check
---@return boolean is_promise True if the value is a promise
function M.is_promise(value)
	return type(value) == "table" and getmetatable(value) == PROMISE_METATABLE
end


---Resolve a promise with a value or another promise
---@param target_promise promise The promise to resolve
---@param value any The value or promise to resolve with
local function resolve_promise(target_promise, value)
	if not M.is_promise(value) then
		target_promise:resolve(value)
		return
	end

	if value:is_resolved() then
		target_promise:resolve(value.value)
	elseif value:is_rejected() then
		target_promise:reject(value.value)
	else
		value:next(function(val)
			target_promise:resolve(val)
		end, function(reason)
			target_promise:reject(reason)
		end)
	end
end


---Handle the result of a callback and resolve the target promise accordingly
---@param target_promise promise The promise to resolve
---@param callback function|event|nil The callback to execute (function or event)
---@param value any The value to pass to the callback
---@param is_rejection boolean Whether this is handling a rejection
local function handle_callback_result(target_promise, callback, value, is_rejection)
	if not callback then
		if is_rejection then
			target_promise:reject(value)
		else
			target_promise:resolve(value)
		end
		return
	end

	resolve_promise(target_promise, callback(value))
end


---Attach resolve and reject handlers to the promise.
---Returns a new promise that will be resolved or rejected based on the handlers' return values.
---@param on_resolved function|event|nil Handler called when promise is resolved. If nil, value passes through.
---@param on_rejected function|event|nil Handler called when promise is rejected. If nil, rejection passes through.
---@return promise new_promise A new promise representing the result of the handlers.
function M:next(on_resolved, on_rejected)
	local new_promise = M.create()

	local handle_resolve = function(value)
		handle_callback_result(new_promise, on_resolved, value, false)
	end

	local handle_reject = function(reason)
		handle_callback_result(new_promise, on_rejected, reason, true)
	end

	if self:is_resolved() then
		handle_resolve(self.value)
	elseif self:is_rejected() then
		handle_reject(self.value)
	else
		self.resolve_handlers:subscribe(handle_resolve)
		self.reject_handlers:subscribe(handle_reject)
	end

	return new_promise
end


---Attach a rejection handler to the promise. Equivalent to next(nil, on_rejected).
---@param on_rejected function|event Handler called when promise is rejected.
---@return promise new_promise A new promise representing the result of the handler.
function M:catch(on_rejected)
	return self:next(nil, on_rejected)
end


---Attach a handler that is called regardless of whether the promise is resolved or rejected.
---The handler receives no arguments and its return value is ignored.
---@param on_finally function|event Handler called when promise is finished (resolved or rejected).
---@return promise new_promise A new promise that resolves/rejects with the same value/reason as the original.
function M:finally(on_finally)
	return self:next(
		function(value)
			on_finally()
			return value
		end,
		function(reason)
			on_finally()
			return M.rejected(reason)
		end
	)
end


---Check if the promise is in pending state.
---@return boolean is_pending True if the promise is pending.
function M:is_pending()
	return self.state == "pending"
end


---Check if the promise is in resolved state.
---@return boolean is_resolved True if the promise is resolved.
function M:is_resolved()
	return self.state == "resolved"
end


---Check if the promise is in rejected state.
---@return boolean is_rejected True if the promise is rejected.
function M:is_rejected()
	return self.state == "rejected"
end


---Check if the promise is finished (either resolved or rejected).
---@return boolean is_finished True if the promise is finished.
function M:is_finished()
	return self.state ~= "pending"
end


---Call the promise to resolve or reject it.
---If value is not nil, the promise will be resolved with that value.
---If value is nil and reason is provided, the promise will be rejected with that reason.
---@param value any The value to resolve with, or nil to indicate rejection.
---@param reason any|nil The reason to reject with (only used if value is nil).
---@private
function M:__call(value, reason)
	if not self:is_pending() then
		return
	end

	if value ~= nil then
		self:resolve(value)
	else
		self:reject(reason)
	end
end


---Settle the promise with the given state and value
---@param state promise.state The new state (resolved or rejected)
---@param value any The value or reason
local function settle_promise(self, state, value)
	if self.state ~= "pending" then
		return
	end

	self.state = state
	self.value = value

	-- Trigger appropriate handlers
	if state == "resolved" then
		self.resolve_handlers:trigger(value)
	else
		self.reject_handlers:trigger(value)
	end

	-- Clear handlers to prevent memory leaks
	self.resolve_handlers:clear()
	self.reject_handlers:clear()
end


---Internal method to resolve the promise.
---@param value any The value to resolve with.
function M:resolve(value)
	if self.state ~= "pending" then
		return
	end

	-- Handle promise resolution with another promise
	if M.is_promise(value) then
		resolve_promise(self, value)
		return
	end

	settle_promise(self, "resolved", value)
end


---Internal method to reject the promise.
---@param reason any The reason to reject with.
function M:reject(reason)
	settle_promise(self, "rejected", reason)
end


-- Construct promise metatable
PROMISE_METATABLE = {
	__index = M,
	__call = M.__call,
}

return M
