local IS_DEBUG = sys.get_engine_info().is_debug
local MEMORY_THRESHOLD_WARNING = sys.get_config_int("event.memory_threshold_warning", 0)

if not IS_DEBUG then
	MEMORY_THRESHOLD_WARNING = 0
end


---@class event @Event Module
local M = {}

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

---@type event.logger
M.logger =  {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}


---@param logger_instance event.logger
function M.set_logger(logger_instance)
	M.logger = logger_instance
end


---@static
---Create new event instance. If callback is passed, it will be subscribed to the event.
---@param callback function|nil
---@param callback_context any|nil
---@return event
function M.create(callback, callback_context)
	local instance = setmetatable({
		_mapping = nil, -- Used for memory threshold warning, only in debug mode
		callbacks = nil,
	}, {
		__index = M,
	})

	if callback then
		instance:subscribe(callback, callback_context)
	end

	return instance
end


---Subscribe to the event. If the callback is already subscribed, it will not be added again.
---@param callback function
---@param callback_context any|nil
---@return boolean @True if event is subscribed
function M:subscribe(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")

	if self:is_subscribed(callback, callback_context) then
		M.logger:error("Subscription attempt for an already subscribed event", debug.traceback())
		return false
	end

	local caller_info = debug.getinfo(2)

	if MEMORY_THRESHOLD_WARNING > 0 then
		self._mapping = self._mapping or {}
		self._mapping[callback] = caller_info.short_src .. ":" .. caller_info.currentline
	end

	self.callbacks = self.callbacks or {}
	table.insert(self.callbacks, {
		script_context = event_context_manager.get(),
		callback = callback,
		callback_context = callback_context,
	})

	return true
end


---Unsubscribe from the event. If the callback is not subscribed, nothing will happen.
---@param callback function
---@param callback_context any|nil
---@return boolean @True if event is unsubscribed
function M:unsubscribe(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")

	local is_subscribed = self:is_subscribed(callback, callback_context)

	if not is_subscribed then
		M.logger:error("Unsubscription attempt for an already unsubscribed event", debug.traceback())
		return false
	end

	for index = 1, #self.callbacks do
		local cb = self.callbacks[index]
		if cb.callback == callback and cb.callback_context == callback_context then
			table.remove(self.callbacks, index)
			return true
		end
	end

	return false
end


---Check is event subscribed.
---@param callback function
---@param callback_context any|nil
---@return boolean @Is event subscribed
function M:is_subscribed(callback, callback_context)
	if not self.callbacks then
		return false
	end

	for index = 1, #self.callbacks do
		local cb = self.callbacks[index]
		if cb.callback == callback and cb.callback_context == callback_context then
			return true
		end
	end

	return false
end


local last_used_memory = 0

---Trigger the event. All subscribed callbacks will be called in the order they were subscribed.
---@vararg any
---@return any @Result of the last triggered callback
function M:trigger(...)
	if not self.callbacks then
		return
	end

	local current_script_context = event_context_manager.get()

	local result = nil

	for index = 1, #self.callbacks do
		local callback = self.callbacks[index]

		if current_script_context ~= callback.script_context then
			event_context_manager.set(callback.script_context)
		end

		if MEMORY_THRESHOLD_WARNING > 0 then
			last_used_memory = collectgarbage("count")
		end

		local ok, result_or_error
		if callback.callback_context then
			ok, result_or_error = pcall(callback.callback, callback.callback_context, ...)
		else
			ok, result_or_error = pcall(callback.callback, ...)
		end

		if current_script_context ~= callback.script_context then
			event_context_manager.set(current_script_context)
		end

		if not ok then
			local traceback = debug.traceback()
			M.logger:error("An error occurred during event processing", { errors = result_or_error, traceback = traceback })
			-- Print again cause it's just better to see it in the console
			pprint(result_or_error)
			pprint(traceback)
		else
			result = result_or_error
		end

		if MEMORY_THRESHOLD_WARNING > 0 then
			local after_memory = collectgarbage("count")
			if after_memory - last_used_memory > MEMORY_THRESHOLD_WARNING then
				M.logger:warn("Detected huge memory allocation in event", {
					source = self._mapping[callback.callback],
					memory = after_memory - last_used_memory,
					index = index
				})
			end
		end
	end

	return result
end


---Check is event instance has no callbacks.
---@return boolean
function M:is_empty()
	return not self.callbacks or #self.callbacks == 0
end


---Clear all event instance callbacks.
function M:clear()
	self.callbacks = nil
end


return M
