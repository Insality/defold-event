local IS_DEBUG = sys.get_engine_info().is_debug
local MEMORY_THRESHOLD_WARNING = IS_DEBUG and sys.get_config_int("event.memory_threshold_warning", 0) or 0

---@class event @Event Module
local M = {}

-- Forward declaration
local EVENT_METATABLE

-- Local versions
local set_context = event_context_manager.set
local get_context = event_context_manager.get
local pcall = pcall
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
	error = function(_, message, context)
		error(context.error or "")
	end,
}


---@param logger_instance event.logger
function M.set_logger(logger_instance)
	M.logger = logger_instance or empty_logger
end


---@param value number
function M.set_memory_threshold(value)
	if not IS_DEBUG then
		return
	end
	MEMORY_THRESHOLD_WARNING = value
end


---@static
---Create new event instance. If callback is passed, it will be subscribed to the event.
---@param callback function|nil
---@param callback_context any|nil
---@return event
function M.create(callback, callback_context)
	local instance = setmetatable({}, EVENT_METATABLE)

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
		M.logger:warn("Subscription attempt for an already subscribed event", debug.traceback())
		return false
	end

	if MEMORY_THRESHOLD_WARNING > 0 then
		self._mapping = self._mapping or {}
		local caller_info = debug.getinfo(2)
		self._mapping[callback] = caller_info.short_src .. ":" .. caller_info.currentline
	end

	local callback_data = {
		script_context = get_context(),
		callback = callback,
		callback_context = callback_context,
	}
	tinsert(self, callback_data)

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
		M.logger:warn("Unsubscription attempt for an already unsubscribed event", debug.traceback())
		return false
	end

	for index = 1, #self do
		local cb = self[index]
		if cb.callback == callback and cb.callback_context == callback_context then
			tremove(self, index)
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
	if #self == 0 then
		return false
	end

	for index = 1, #self do
		local cb = self[index]
		if cb.callback == callback and cb.callback_context == callback_context then
			return true
		end
	end

	return false
end


local memory_before = 0

---Trigger the event. All subscribed callbacks will be called in the order they were subscribed.
---@vararg any
---@return any @Result of the last triggered callback
function M:trigger(...)
	if #self == 0 then
		return
	end

	local result = nil
	local current_script_context = get_context()

	for index = 1, #self do
		result = self:call_callback(self[index], current_script_context, ...)
	end

	return result
end


---@private
---@param callback event.callback_data
---@param current_script_context userdata
---@param ... any
---@return any|nil
function M:call_callback(callback, current_script_context, ...)
	-- Set context for the callback
	if current_script_context ~= callback.script_context then
		set_context(callback.script_context)
	end

	-- Check memory allocation
	if MEMORY_THRESHOLD_WARNING > 0 then
		memory_before = collectgarbage("count")
	end

	-- Call callback
	local ok, result_or_error
	if callback.callback_context then
		ok, result_or_error = pcall(callback.callback, callback.callback_context, ...)
	else
		ok, result_or_error = pcall(callback.callback, ...)
	end

	-- Check memory allocation
	if MEMORY_THRESHOLD_WARNING > 0 then
		local memory_after = collectgarbage("count")
		if memory_after - memory_before > MEMORY_THRESHOLD_WARNING then
			local caller_info = debug.getinfo(2)
			M.logger:warn("Detected huge memory allocation in event", {
				event = self._mapping and self._mapping[callback.callback],
				trigger = caller_info.short_src .. ":" .. caller_info.currentline,
				memory = memory_after - memory_before,
			})
		end
	end

	-- Restore context
	if current_script_context ~= callback.script_context then
		set_context(current_script_context)
	end

	-- Handle errors
	if not ok then
		local caller_info = debug.getinfo(2)
		M.logger:error("An error occurred during event processing", {
			trigger = caller_info.short_src .. ":" .. caller_info.currentline,
			error = result_or_error,
		})
		M.logger:error("Traceback", debug.traceback())
		return nil
	end

	return result_or_error
end


---Check is event instance has no callbacks.
---@return boolean
function M:is_empty()
	return #self == 0
end


---Clear all event instance callbacks.
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
