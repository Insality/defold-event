local IS_DEBUG = sys.get_engine_info().is_debug
local MEMORY_THRESHOLD_WARNING = IS_DEBUG and sys.get_config_int("event.memory_threshold_warning", 0) or 0

---Xpcall is used to get the exact error place, but calls with xpcall are slower and use more memory.
---Used mostly for debug
local USE_XPCALL = sys.get_config_int("event.use_xpcall", 0) == 1

---Array of next items: { callback, callback_context, script_context }
---@class event.callback_data: table

---A logger object for event module should match the following interface
---@class event.logger
---@field trace fun(logger: event.logger, message: string, data: any|nil) Log a trace message.
---@field debug fun(logger: event.logger, message: string, data: any|nil) Log a debug message.
---@field info fun(logger: event.logger, message: string, data: any|nil) Log an info message.
---@field warn fun(logger: event.logger, message: string, data: any|nil) Log a warning message.
---@field error fun(logger: event.logger, message: string, data: any|nil) Log an error message.

---The Event module, used to create and manage events. Allows to subscribe to events and trigger them.
---@class event
---@overload fun(vararg:any): any|nil Trigger the event. All subscribed callbacks will be called in the order they were subscribed.
local M = {}

-- Forward declaration
local EVENT_METATABLE
local MEMORY_BEFORE_VALUE

-- Local versions
local set_context = event_context_manager.set
local get_context = event_context_manager.get
local pcall = pcall
local table_insert = table.insert
local table_remove = table.remove

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
local logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = function(_, message)
		pprint("WARN:", message)
	end,
	error = function(_, message)
		pprint("ERROR:", message)
	end,
}


---Customize the logging mechanism used by Event module. You can use **Defold Log** library or provide a custom logger.
---By default, the module uses the `pprint` logger for errors.
---@param logger_instance event.logger|table|nil A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.
function M.set_logger(logger_instance)
	logger = logger_instance or empty_logger
end


---Set the threshold for logging warnings about memory allocations in event callbacks.
---Works only in debug builds. The threshold is in kilobytes.
---If the callback causes a memory allocation greater than the threshold, a warning will be logged.
---@param value number Threshold in kilobytes for logging warnings about memory allocations. `0` disables tracking.
function M.set_memory_threshold(value)
	if not IS_DEBUG then
		return
	end
	MEMORY_THRESHOLD_WARNING = value
end


---Generate a new event instance. This instance can then be used to subscribe to and trigger events.
---The callback function will be called when the event is triggered. The callback_context parameter is optional
---and will be passed as the first parameter to the callback function. Usually, it is used to pass the self instance.
---Allocate 64 bytes per instance.
---@param callback function|event|nil The function to be called when the event is triggered. Or the event instance to subscribe.
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


---Subscribe a callback to the event or other event. The callback will be invoked whenever the event is triggered.
---The callback_context parameter is optional and will be passed as the first parameter to the callback function.
---If the callback with context is already subscribed, the warning will be logged.
---Allocate 160 bytes per first subscription and 104 bytes per next subscriptions.
---		local function callback(self)
---			print("clicked!")
---		end
---		on_click_event:subscribe(callback, self)
---
---		-- Subscribe an event to another event
---		event_1 = event.create(callback)
---		event_2 = event.create()
---		event_2:subscribe(event_1) -- Now event2 will trigger event1
---@param callback function|event The function to be executed when the event occurs.
---@param callback_context any|nil The first parameter to be passed to the callback function. Not used if the callback is an event.
---@return boolean is_subscribed True if event is subscribed (Will return false if the callback is already subscribed)
function M:subscribe(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")

	-- If callback is an event, subscribe to it and return
	if type(callback) == "table" and callback.trigger then
		return self:subscribe(callback.trigger, callback)
	end

	---@cast callback function
	if self:is_subscribed(callback, callback_context) then
		logger:warn("Callback is already subscribed to the event. Callback will not be subscribed again.")
		return false
	end

	if MEMORY_THRESHOLD_WARNING > 0 then
		self._mapping = self._mapping or {}
		local caller_info = debug.getinfo(2)
		self._mapping[callback] = caller_info.short_src .. ":" .. caller_info.currentline
	end

	table_insert(self, { callback, callback_context, get_context() })
	return true
end


---Remove a previously subscribed callback from the event.
---The callback_context should be the same as the one used when subscribing the callback.
---If there is no callback_context provided, all callbacks with the same function will be unsubscribed.
---		on_click_event:unsubscribe(callback, self)
---@param callback function|event The callback function to unsubscribe.
---@param callback_context any|nil The first parameter to be passed to the callback function. If not provided, will unsubscribe all callbacks with the same function. Not used for event instances.
---@return boolean is_unsubscribed True if event is unsubscribed
function M:unsubscribe(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")

	-- If callback is an event, unsubscribe from it and return
	if type(callback) == "table" and callback.trigger then
		return self:unsubscribe(callback.trigger, callback)
	end

	---@cast callback function

	local is_removed = false
	for index = #self, 1, -1 do
		local cb = self[index]
		if cb[1] == callback and (not callback_context or cb[2] == callback_context) then
			table_remove(self, index)
			is_removed = true
		end
	end

	return is_removed
end


---Determine if a specific callback is currently subscribed to the event.
---The callback_context should be the same as the one used when subscribing the callback.
---		local is_subscribed = on_click_event:is_subscribed(callback, self)
---@param callback function|event The callback function in question. Or the event instance to check.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_subscribed True if the callback is subscribed to the event
---@return number|nil index Index of callback in event if subscribed (return first found index)
function M:is_subscribed(callback, callback_context)
	if #self == 0 then
		return false, nil
	end

	-- If callback is an event, check if it is subscribed
	if type(callback) == "table" and callback.trigger then
		return self:is_subscribed(callback.trigger, callback)
	end

	---@cast callback function

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


---Trigger the event, causing all subscribed callbacks to be executed.
---Any parameters passed to trigger will be forwarded to the callbacks.
---The return value of the last executed callback is returned.
---The event:trigger(...) can be called as event(...).
---		on_click_event:trigger("arg1", "arg2")
---
---		-- The event can be triggered as a function
---		on_click_event("arg1", "arg2")
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
			if not USE_XPCALL then
				ok, result_or_error = pcall(event_callback, event_callback_context, ...)
			else
				-- This one should be used for find exact error place, since with pcall
				-- I can't figure out how to get a full traceback
				-- Not should be cause of memory allocations (it's more 100 bytes!

				-- Using closue due the lua5.1 in HTML don't allow pass args in xpcall as 3rd+ arguments
				local args = { event_callback_context, ... }
				ok, result_or_error = xpcall(function()
					return event_callback(unpack(args))
				end, event_error_handler)
			end
		else
			if not USE_XPCALL then
				ok, result_or_error = pcall(event_callback, ...)
			else
				local args = { ... }
				ok, result_or_error = xpcall(function()
					return event_callback(unpack(args))
				end, event_error_handler)
			end
		end

		-- Check memory allocation
		if MEMORY_THRESHOLD_WARNING > 0 then
			local memory_after = collectgarbage("count")
			if memory_after - MEMORY_BEFORE_VALUE > MEMORY_THRESHOLD_WARNING then
				local caller_info = debug.getinfo(2)
				logger:warn("Detected huge memory allocation in event", {
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
			local caller_info = debug.getinfo(2)
			local place = caller_info.short_src .. ":" .. caller_info.currentline
			logger:error("Error in trigger event: " .. place, result_or_error)
			logger:error(debug.traceback(result_or_error, 2))
		end

		result = result_or_error
	end

	return result
end


---Check if the event has no subscribed callbacks.
---		local is_empty = on_click_event:is_empty()
---@return boolean is_empty True if the event has no subscribed callbacks
function M:is_empty()
	return #self == 0
end


---Remove all callbacks subscribed to the event, effectively resetting it.
---		on_click_event:clear()
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
