local IS_DEBUG = sys.get_engine_info().is_debug
local MEMORY_THRESHOLD_WARNING = IS_DEBUG and sys.get_config_int("event.memory_threshold_warning", 0) or 0

---Contains each item[1] - callback, item[2] - callback_context, item[3] - script_context
---@class event.callback_data: table

---@class event.logger
---@field trace fun(logger: event.logger, message: string, data: any|nil) @Log a trace message.
---@field debug fun(logger: event.logger, message: string, data: any|nil) @Log a debug message.
---@field info fun(logger: event.logger, message: string, data: any|nil) @Log an info message.
---@field warn fun(logger: event.logger, message: string, data: any|nil) @Log a warning message.
---@field error fun(logger: event.logger, message: string, data: any|nil) @Log an error message.

---@class event @Event module
---@overload fun(vararg:any): any|nil Trigger the event. All subscribed callbacks will be called in the order they were subscribed.
local M = {}

-- Forward declaration
local EVENT_METATABLE
local MEMORY_BEFORE_VALUE

-- Local versions
local set_context = event_context_manager.set
local get_context = event_context_manager.get
local xpcall = xpcall
local tinsert = table.insert
local tremove = table.remove

--- Use empty function to save a bit of memory
local EMPTY_FUNCTION = function(_, message, context) end

---@type event.logger
local empty_logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = EMPTY_FUNCTION,
}

---@type event.logger
M.logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = EMPTY_FUNCTION,
	error = function(_, message)
		pprint("ERROR:", message)
	end,
}


---Customize the logging mechanism used by Event module. You can use **Defold Log** library or provide a custom logger. By default, the module uses the `pprint` logger for errors.
---@static
---@param logger_instance event.logger A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.
function M.set_logger(logger_instance)
	M.logger = logger_instance or empty_logger
end



---Set the threshold for logging warnings about memory allocations in event callbacks. Works only in debug builds. The threshold is in kilobytes. If the callback causes a memory allocation greater than the threshold, a warning will be logged.
---@static
---@param value number Threshold in kilobytes for logging warnings about memory allocations. `0` disables tracking.
function M.set_memory_threshold(value)
	if not IS_DEBUG then
		return
	end
	MEMORY_THRESHOLD_WARNING = value
end


---Create new event instance. If callback is passed, it will be subscribed to the event.
---@static
---@param callback function|nil The function to be called when the event is triggered.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return event A new event instance.
---@nodiscard
function M.create(callback, callback_context)
	local instance = setmetatable({}, EVENT_METATABLE)

	if callback then
		instance:subscribe(callback, callback_context)
	end

	return instance
end


---Subscribe to the event. If the callback is already subscribed, it will not be added again.
---@param callback function The function to be executed when the event occurs.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_subscribed True if event is subscribed
function M:subscribe(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")

	if self:is_subscribed(callback, callback_context) then
		M.logger:warn("Subscription attempt for an already subscribed event", debug.traceback())
		return false
	end

	if MEMORY_THRESHOLD_WARNING > 0 then
		self._mapping = self._mapping or {}
		local caller_info = debug.getinfo(2)
		self._mapping[callback] = caller_info.short_src .. ":" .. caller_info.currentline
	end

	tinsert(self, { callback, callback_context, get_context() })
	return true
end


---Unsubscribe from the event. If the callback is not subscribed, nothing will happen.
---@param callback function The callback function to unsubscribe.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_unsubscribed True if event is unsubscribed
function M:unsubscribe(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")

	local _, event_index = self:is_subscribed(callback, callback_context)
	if not event_index then
		M.logger:warn("Unsubscription attempt for an already unsubscribed event", debug.traceback())
		return false
	end

	tremove(self, event_index)
	return true
end


---Check if the callback is subscribed to the event.
---@param callback function The callback function in question.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_subscribed True if the callback is subscribed to the event
---@return number|nil index Index of callback in event if subscribed
function M:is_subscribed(callback, callback_context)
	if #self == 0 then
		return false, nil
	end

	for index = 1, #self do
		local cb = self[index]
		if cb[1] == callback and cb[2] == callback_context then
			return true, index
		end
	end

	return false, nil
end


---Error handler for event callbacks.
---@param error_message string Error message
---@return string Error message with stack trace
local function event_error_handler(error_message)
	return debug.traceback(error_message, 2)
end


---Trigger the event and call all subscribed callbacks. Returns the result of the last callback. If no callbacks are subscribed, nothing will happen.
---@vararg any Any number of parameters to be passed to the subscribed callbacks.
---@return any result Result of the last triggered callback
function M:trigger(...)
	if #self == 0 then
		return
	end

	local result = nil
	local current_script_context = get_context()

	for index = 1, #self do
		local callback = self[index]
		local event_callback = callback[1]
		local event_callback_context = callback[2]
		local event_script_context = callback[3]

		-- Set context for the callback
		if current_script_context ~= event_script_context then
			set_context(event_script_context)
		end

		-- Check memory allocation
		if MEMORY_THRESHOLD_WARNING > 0 then
			MEMORY_BEFORE_VALUE = collectgarbage("count")
		end

		-- Call callback
		local ok, result_or_error
		if event_callback_context then
			ok, result_or_error = xpcall(event_callback, event_error_handler, event_callback_context, ...)
		else
			ok, result_or_error = xpcall(event_callback, event_error_handler, ...)
		end

		-- Check memory allocation
		if MEMORY_THRESHOLD_WARNING > 0 then
			local memory_after = collectgarbage("count")
			if memory_after - MEMORY_BEFORE_VALUE > MEMORY_THRESHOLD_WARNING then
				local caller_info = debug.getinfo(2)
				M.logger:warn("Detected huge memory allocation in event", {
					event = self._mapping and self._mapping[event_callback],
					trigger = caller_info.short_src .. ":" .. caller_info.currentline,
					memory = memory_after - MEMORY_BEFORE_VALUE,
				})
			end
		end

		-- Restore context
		if current_script_context ~= event_script_context then
			set_context(current_script_context)
		end

		-- Handle errors
		if not ok then
			M.logger:error(result_or_error)
			break -- TODO: Is it necessary to stop the event if one of the callbacks failed?
		end

		result = result_or_error
	end

	return result
end


---Check if the event has any subscribed callbacks.
---@return boolean True if the event has any subscribed callbacks
function M:is_empty()
	return #self == 0
end


---Clear all subscribed callbacks.
function M:clear()
	for index = #self, 1, -1 do
		self[index] = nil
	end
end


-- Construct event metatable
EVENT_METATABLE = {
	__index = M,
	__call = M.trigger,
}

return M
