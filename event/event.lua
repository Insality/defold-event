local USE_PCALL = sys.get_config_int("event.use_pcall", 1) == 1
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
---@overload fun(vararg:any): any|nil Trigger the event. All subscribed callbacks will be called in the order they were subscribed.
---@class event
local M = {}

-- Forward declaration
local EVENT_METATABLE

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


---Check if the table is an event instance.
---@param value any
---@return boolean is_event
function M.is_event(value)
	return type(value) == "table" and getmetatable(value) == EVENT_METATABLE
end


---Generate a new event instance. This instance can then be used to subscribe to and trigger events.
---The callback function will be called when the event is triggered. The callback_context parameter is optional
---and will be passed as the first parameter to the callback function. Usually, it is used to pass the self instance.
---Allocate 64 bytes per instance.
---@param callback function|event|nil The function to be called when the event is triggered. Or the event instance to subscribe.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return event event_instance A new event instance.
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
	if M.is_event(callback) then
		return self:subscribe(callback.trigger, callback)
	end

	---@cast callback function
	if self:is_subscribed(callback, callback_context) then
		logger:warn("Callback is already subscribed to the event. Callback will not be subscribed again.")
		return false
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
	if M.is_event(callback) then
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
	if M.is_event(callback) then
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

		-- Call callback
		local ok, result_or_error
		if event_callback_context then
			if USE_PCALL then
				ok, result_or_error = pcall(event_callback, event_callback_context, ...)
			else
				-- Create a table with the context as the first element
				local args = { event_callback_context }

				-- Note: Most more oblivious ways to do this is not working
				-- because of the way Lua handles varargs and closures.
				-- This way seems okay
				local n = select("#", ...)
				for i = 1, n do
					args[i+1] = select(i, ...)
				end

				if USE_XPCALL then
					ok, result_or_error = xpcall(function()
						return event_callback(unpack(args))
					end, event_error_handler)
				else
					result_or_error = event_callback(unpack(args))
					ok = true
				end
			end
		else
			if USE_PCALL then
				ok, result_or_error = pcall(event_callback, ...)
			elseif USE_XPCALL then
				-- Create a new args table with the proper count
				local args = {}
				local n = select("#", ...)

				-- Add each argument individually
				for i = 1, n do
					args[i] = select(i, ...)
				end

				ok, result_or_error = xpcall(function()
					return event_callback(unpack(args))
				end, event_error_handler)
			else
				result_or_error = event_callback(...)
				ok = true
			end
		end

		-- Restore context
		if current_script_context ~= event_script_context then
			set_context(current_script_context)
		end

		-- Handle errors
		if (USE_PCALL or USE_XPCALL) and not ok then
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
