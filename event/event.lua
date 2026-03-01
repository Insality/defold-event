local event_mode = sys.get_config_string("event.event_mode", "pcall")
local USE_XPCALL = event_mode == "xpcall"
local USE_PCALL = event_mode == "pcall"
local USE_NONE = event_mode == "none"

---Array of next items:
---[1] callback,
---[2] callback_context,
---[3] script_context
---[4] remaining: nil=infinite, number=fires left, 0=pending delete.
---[5] subscribed_event: event when callback is event with context.
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
---@field package _defer_unsubscribe boolean When true, unsubscribe marks for deferred removal instead of removing immediately.
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
	error = function(_, message)
		event_context_manager.log_error(message)
	end,
}

---@type event.logger
local logger = {
	trace = EMPTY_FUNCTION,
	debug = EMPTY_FUNCTION,
	info = EMPTY_FUNCTION,
	warn = function(_, message)
		print("WARN:", message)
	end,
	error = function(_, message)
		event_context_manager.log_error(message)
	end,
}


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


---Check if the table is an event instance.
---@param value any
---@return boolean is_event
function M.is_event(value)
	return type(value) == "table" and getmetatable(value) == EVENT_METATABLE
end


---Subscribe a callback to the event or other event. The callback will be invoked whenever the event is triggered.
---@param self event The event instance
---@param callback function|event The function to be executed when the event occurs.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@param remaining number|nil nil = infinite, number = fires left then remove
local function subscribe(self, callback, callback_context, remaining)
	if self:is_subscribed(callback, callback_context) then
		logger:warn("Callback is already subscribed to the event. Callback will not be subscribed again.")
		return false
	end

	-- With event subscription we need to store the event instance to be able to unsubscribe it later.
	if M.is_event(callback) then
		---@cast callback event
		if not callback_context or callback_context == callback then
			table_insert(self, { callback.trigger, callback, get_context(), remaining, nil })
		else
			local wrapper = function(context, ...)
				return callback:trigger(...)
			end
			table_insert(self, { wrapper, callback_context, get_context(), remaining, callback })
		end
		return true
	end

	table_insert(self, { callback, callback_context, get_context(), remaining, nil })

	return true
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
	return subscribe(self, callback, callback_context, nil)
end


---Subscribe a callback for a single trigger. After the first trigger the callback is automatically unsubscribed.
---@param callback function|event The function or event to run once.
---@param callback_context any|nil Same as subscribe.
---@return boolean is_subscribed True if subscribed
function M:subscribe_once(callback, callback_context)
	assert(callback, "A function must be passed to subscribe to an event")
	return subscribe(self, callback, callback_context, 1)
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

	if M.is_event(callback) then
		---@cast callback event
		if not callback_context or callback_context == callback then
			return self:unsubscribe(callback.trigger, callback)
		end
		for index = #self, 1, -1 do
			local cb = self[index]
			if cb[5] == callback and cb[2] == callback_context then
				if self._defer_unsubscribe then
					cb[4] = 0
				else
					table_remove(self, index)
				end
				return true
			end
		end
		return false
	end

	local is_removed = false

	for index = #self, 1, -1 do
		local cb = self[index]
		if cb[1] == callback and (not callback_context or cb[2] == callback_context) then
			if self._defer_unsubscribe then
				cb[4] = 0
			else
				table_remove(self, index)
			end
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

	if M.is_event(callback) then
		---@cast callback event
		if not callback_context or callback_context == callback then
			return self:is_subscribed(callback.trigger, callback)
		end
		for index = 1, #self do
			local cb = self[index]
			local is_pending_delete = self._defer_unsubscribe and cb[4] == 0
			local is_same_subscription = cb[5] == callback and cb[2] == callback_context
			if not is_pending_delete and is_same_subscription then
				return true, index
			end
		end
		return false, nil
	end

	---@cast callback function
	for index = 1, #self do
		local cb = self[index]
		local is_pending_delete = self._defer_unsubscribe and cb[4] == 0
		local is_same_subscription = cb[1] == callback and cb[2] == callback_context
		if not is_pending_delete and is_same_subscription then
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

	self._defer_unsubscribe = true
	local result = nil
	local current_script_context = get_context()

	for index = 1, #self do
		local callback = self[index]
		local event_callback = callback[1]
		local event_callback_context = callback[2]
		local event_script_context = callback[3]

		-- Decrement remaining count if it is a number and greater than 0
		if callback[4] and callback[4] > 0 then
			callback[4] = callback[4] - 1
		end

		-- Set context for the callback
		if current_script_context ~= event_script_context then
			set_context(event_script_context)
		end

		-- Call callback
		local ok, result_or_error
		if event_callback_context then
			if USE_PCALL then
				ok, result_or_error = pcall(event_callback, event_callback_context, ...)
			elseif USE_XPCALL or USE_NONE then
				local args = { event_callback_context }
				local n = select("#", ...)
				for i = 1, n do
					args[i+1] = select(i, ...)
				end

				ok, result_or_error = xpcall(function()
					return event_callback(unpack(args, 1, n + 1))
				end, event_error_handler)
			else
				result_or_error = event_callback(event_callback_context, ...)
				ok = true
			end
		else
			if USE_PCALL then
				ok, result_or_error = pcall(event_callback, ...)
			elseif USE_XPCALL or USE_NONE then
				local args = {}
				local n = select("#", ...)
				for i = 1, n do
					args[i] = select(i, ...)
				end

				ok, result_or_error = xpcall(function()
					return event_callback(unpack(args, 1, n))
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
		if not ok then
			if USE_NONE then
				-- Clear before error
				local current_index = index
				for i = current_index - 1, 1, -1 do
					if self[i][4] == 0 then
						table_remove(self, i)
					end
				end
				self._defer_unsubscribe = false

				error(result_or_error, 2)
			end

			local caller_info = debug.getinfo(2)
			local place = caller_info.short_src .. ":" .. caller_info.currentline
			logger:error("Error from trigger event here: " .. place, 2)
			logger:error(USE_XPCALL and result_or_error or debug.traceback(result_or_error, 2))
		end

		result = result_or_error
	end

	-- Remove deferred unsubscribed callbacks
	for index = #self, 1, -1 do
		if self[index][4] == 0 then
			table_remove(self, index)
		end
	end

	self._defer_unsubscribe = false

	return result
end


---Check if the event has no subscribed callbacks.
---		local is_empty = on_click_event:is_empty()
---@return boolean is_empty True if the event has no subscribed callbacks
function M:is_empty()
	return #self == 0
end


---Customize the logging mechanism used by Event module. You can use **Defold Log** library or provide a custom logger.
---By default, the module uses the `pprint` logger for errors.
---@param logger_instance event.logger|table|nil A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.
function M.set_logger(logger_instance)
	logger = logger_instance or empty_logger
end


---Set the mode of the event module.
---@param mode "pcall" | "xpcall" | "none" The mode to set.
function M.set_mode(mode)
	USE_PCALL = mode == "pcall"
	USE_XPCALL = mode == "xpcall"
	USE_NONE = mode == "none"
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
