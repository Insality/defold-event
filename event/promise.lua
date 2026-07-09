local event = require("event.event")

---@alias promise.state "pending" | "resolved" | "rejected"

---@class promise.cancelled_context
---@field is_cancelled boolean
---@field on_cancel event

---The Promise module, used to create and manage promises.
---A promise represents a single asynchronous operation that will either resolve with a value or reject with a reason.
---@overload fun(value:any): nil Call the promise to resolve it with value
---@class promise: function
---@field state promise.state Current state of the promise (pending, resolved, rejected)
---@field value any The resolved value or rejection reason
---@field cancellation promise.cancelled_context Shared cancelled context for a promise chain
---@field private on_resolve event Event for resolve handlers
---@field private on_reject event Event for rejection handlers
---@field private _tail promise|nil Internal tail promise for append chaining
---@field private _cancel_children table<promise, boolean>|nil Promises linked via next or adopt
local M = {}

-- Forward declaration
local PROMISE_METATABLE

---Unique sentinel rejection reason for cancelled promises.
local CANCELLED = { "promise.cancelled" }


---Generate a new promise instance. This instance represents a single asynchronous operation.
---The executor function is called immediately with resolve, reject functions and on_cancel event.
---		local p = promise.create(function(resolve, reject, on_cancel)
---			local handle = timer.delay(1, false, resolve)
---			on_cancel:subscribe(function() timer.cancel(handle) end)
---		end)
---@param executor function|event|nil The function or event that will be called with resolve, reject functions and cancel event. Optional for manual promise creation.
---@param context any|nil The context to call the executor function with.
---@return promise promise_instance A new promise instance.
function M.create(executor, context)
	local self = setmetatable({
		state = "pending",
		value = nil,
		cancellation = { is_cancelled = false, on_cancel = event.create() },
		on_resolve = event.create(),
		on_reject = event.create()
	}, PROMISE_METATABLE)

	if executor then
		---@cast executor function

		local resolve_func = function(value) self:resolve(value) end
		local reject_func = function(reason) self:reject(reason) end

		local ok, err
		if context ~= nil then
			ok, err = pcall(executor, context, resolve_func, reject_func, self.cancellation.on_cancel)
		else
			ok, err = pcall(executor, resolve_func, reject_func, self.cancellation.on_cancel)
		end

		if not ok then
			self:reject(err)
		end
	end

	return self
end


---Create a promise that is immediately resolved with the given value.
---		local p = promise.resolved(42)
---		p:next(function(v) print(v) end)
---@param value any The value to resolve the promise with.
---@return promise promise_instance A resolved promise.
---@nodiscard
function M.resolved(value)
	local promise_instance = M.create()
	promise_instance:resolve(value)
	return promise_instance
end


---Create a promise that is immediately rejected with the given reason.
---		local p = promise.rejected("error")
---		p:catch(function(reason) print(reason) end)
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
---		local p = promise.all({ load_asset(1), load_asset(2), load_asset(3) })
---		p:next(function(results) print(#results) end)
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

	result_promise.cancellation.on_cancel:subscribe(function()
		for _, promise_instance in ipairs(promises) do
			if promise_instance:is_pending() then
				promise_instance:cancel()
			end
		end
	end)

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
---		local p = promise.race({ fetch_with_timeout(url, 1000), slow_fetch(url) })
---@param promises promise[] Array of promises to race.
---@return promise promise_instance A promise that resolves or rejects with the first finished promise.
---@nodiscard
function M.race(promises)
	if #promises == 0 then
		return M.create() -- Never resolves
	end

	local result_promise = M.create()

	result_promise.cancellation.on_cancel:subscribe(function()
		for _, promise_instance in ipairs(promises) do
			if promise_instance:is_pending() then
				promise_instance:cancel()
			end
		end
	end)

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
---		if promise.is_promise(my_value) then
---			my_value:next(handler)
---		end
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

	M._share_cancellation(target_promise, value)

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
---@param callback function|event|promise|nil The callback to execute (function or event)
---@param value any The value to pass to the callback
---@param is_rejection boolean Whether this is handling a rejection
---@param context any|nil The context to call the callback with.
local function handle_callback_result(target_promise, callback, value, is_rejection, context)
	if not callback then
		if is_rejection then
			target_promise:reject(value)
		else
			target_promise:resolve(value)
		end

		return
	end

	if not is_rejection and target_promise.cancellation.is_cancelled then
		target_promise:reject(CANCELLED)
		return
	end

	-- If callback is a promise, resolve target_promise with it directly
	if M.is_promise(callback) then
		resolve_promise(target_promise, callback)
		return
	end

	local ok, result = pcall(M._invoke_callback, callback, context, value)
	if not ok then
		target_promise:reject(result)
		return
	end

	resolve_promise(target_promise, result)
end


---Attach resolve and reject handlers to the promise.
---Returns a new promise that will be resolved or rejected based on the handlers' return values.
---		load_data():next(function(data) return process(data) end):next(display):catch(show_error)
---@param on_resolved function|promise|event|nil Handler called when promise is resolved. If nil, value passes through.
---@param on_rejected function|promise|event|nil Handler called when promise is rejected. If nil, rejection passes through.
---@param context any|nil The context to call the handlers with.
---@return promise new_promise A new promise representing the result of the handlers.
function M:next(on_resolved, on_rejected, context)
	local new_promise = M.create()
	M._share_cancellation(self, new_promise)

	if self:is_resolved() then
		handle_callback_result(new_promise, on_resolved, self.value, false, context)
	elseif self:is_rejected() then
		handle_callback_result(new_promise, on_rejected, self.value, true, context)
	else
		self.on_resolve:subscribe(function(value)
			handle_callback_result(new_promise, on_resolved, value, false, context)
		end)
		self.on_reject:subscribe(function(reason)
			handle_callback_result(new_promise, on_rejected, reason, true, context)
		end)
	end

	return new_promise
end


---Attach a rejection handler to the promise. Equivalent to next(nil, on_rejected).
---		load_data():catch(function(err) print("Failed:", err) end)
---@param on_rejected function|event Handler called when promise is rejected.
---@param context any|nil The context to call the handler with.
---@return promise new_promise A new promise representing the result of the handler.
function M:catch(on_rejected, context)
	return self:next(nil, on_rejected, context)
end


---Attach a handler that is called regardless of whether the promise is resolved or rejected.
---The handler is called with the resolved value or rejection reason.
---When context is provided, it is passed as the first argument.
---The handler return value is ignored.
---		load_data():finally(function() hide_loading_spinner() end)
---@param on_finally function|event Handler called when promise is finished (resolved or rejected).
---@param context any|nil The context to call the handler with.
---@return promise new_promise A new promise that resolves/rejects with the same value/reason as the original.
function M:finally(on_finally, context)
	return self:next(
		function(value)
			if context ~= nil then
				on_finally(context, value)
			else
				on_finally(value)
			end
			return value
		end,
		function(reason)
			if context ~= nil then
				on_finally(context, reason)
			else
				on_finally(reason)
			end
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


---Check if the shared cancel_context was cancelled.
---@return boolean is_cancelled True if the promise chain was cancelled.
function M:is_cancelled()
	return self.cancellation.is_cancelled
end


---Call the promise to resolve it with a single value (e.g. as a one-argument callback).
---@param value any
---@private
function M:__call(value)
	if not self:is_pending() then
		return
	end

	self:resolve(value)
end


---Resolve the promise.
---		my_promise:resolve(result)
---@param value any The value to resolve with.
function M:resolve(value)
	if self.state ~= "pending" then
		return
	end

	if self.cancellation.is_cancelled then
		self:reject(CANCELLED)
		return
	end

	-- Handle promise resolution with another promise
	if M.is_promise(value) then
		resolve_promise(self, value)
		return
	end

	-- Inline settle_promise logic for resolved state
	self.state = "resolved"
	self.value = value
	self.on_resolve:trigger(value)

	-- Clear handlers to prevent memory leaks
	self.on_resolve:clear()
	self.on_reject:clear()
end


---Reject the promise.
---		my_promise:reject("failed")
---@param reason any The reason to reject with.
function M:reject(reason)
	if self.state ~= "pending" then
		return
	end

	if self.cancellation.is_cancelled and reason ~= CANCELLED then
		reason = CANCELLED
	end

	if reason == CANCELLED then
		self:_cancel_promise()
	end

	-- Inline settle_promise logic for rejected state
	self.state = "rejected"
	self.value = reason
	self.on_reject:trigger(reason)

	-- Clear handlers to prevent memory leaks
	self.on_resolve:clear()
	self.on_reject:clear()

	if reason == CANCELLED then
		self.cancellation.on_cancel:clear()
	end
end


---Cancel the promise chain. Triggers cleanup and rejects if still pending.
---		my_promise:cancel()
function M:cancel()
	if self.cancellation.is_cancelled then
		return
	end

	if self:is_pending() then
		self:reject(CANCELLED)
	else
		self:_cancel_promise()
	end

	self:_reject_cancel_children()
end


---Append a task to this promise's internal sequence without reassigning.
---The task may return a value or a promise. If `task` is a promise, the pipeline waits for it
---to finish before continuing (same as returning it from a function).
---Returns self for chaining.
---Almost similar to `promise = promise:next(task)`, but without reassigning the promise.
---		pipeline:append(step1)
---		pipeline:append(step2)
---		pipeline:append(step3)
---		local last = pipeline:tail()
---		print("Is going to check status of", last:is_pending())
---@param task (fun(value:any):any)|promise
---@return promise self
function M:append(task)
	if M.is_promise(task) then
		---@cast task promise
		M._share_cancellation(self._tail or self, task)
		self._tail = (self._tail or self):next(function()
			return task
		end)
		return self
	end

	self._tail = (self._tail or self):next(function(value)
		return task(value)
	end)
	return self
end


---Get the current tail promise representing all appended work.
---		local last = pipeline:tail()
---		last:next(on_complete)
---@return promise tail
function M:tail()
	return self._tail or self
end


---Reset the internal sequence to an already resolved promise.
---		pipeline:reset()
---		pipeline:append(new_step)
---@return promise self
function M:reset()
	self._tail = M.create()
	M._share_cancellation(self, self._tail)
	self._tail:resolve(nil)
	return self
end


---Reject pending child promises when a settled promise is cancelled.
function M:_reject_cancel_children()
	local children = self._cancel_children
	if not children then
		return
	end

	for child in pairs(children) do
		if child:is_pending() then
			child:reject(CANCELLED)
		end
		child:_reject_cancel_children()
	end
end


---Cancel the promise chain.
---@private
function M:_cancel_promise()
	if self.cancellation.is_cancelled then
		return
	end
	self.cancellation.is_cancelled = true
	self.cancellation.on_cancel:trigger()
	self.cancellation.on_cancel:clear()
end


---Share the cancellation context from the parent promise with the child promise.
---@private
---@param parent promise The parent promise
---@param child promise The child promise
function M._share_cancellation(parent, child)
	local old_cancellation = child.cancellation
	child.cancellation = parent.cancellation
	if old_cancellation.on_cancel ~= child.cancellation.on_cancel then
		-- event.subscribe accepts another event and forwards triggers to it
		child.cancellation.on_cancel:subscribe(old_cancellation.on_cancel)
	end
	parent._cancel_children = parent._cancel_children or {}
	parent._cancel_children[child] = true
end


---Invoke a callback with the given context and value.
---@private
---@param callback function|event The callback to invoke.
---@param context any|nil The context to call the callback with.
---@param value any The value to pass to the callback.
---@return any result The result of the callback.
function M._invoke_callback(callback, context, value)
	if event.is_event(callback) then
		if context ~= nil then
			return callback:trigger(context, value)
		else
			return callback:trigger(value)
		end
	else
		if context ~= nil then
			return callback(context, value)
		else
			return callback(value)
		end
	end
end


-- Construct promise metatable
PROMISE_METATABLE = {
	__index = M,
	__call = M.__call,
}


return M
