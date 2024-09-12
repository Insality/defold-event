---@meta
---@class event
local event = {}

---Customize the logging mechanism used by Event module. You can use **Defold Log** library or provide a custom logger. By default, the module uses the `pprint` logger for errors.
---@param logger_instance event.logger|nil @A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.
function event.set_logger(logger_instance) end

---Set the threshold for logging warnings about memory allocations in event callbacks. Works only in debug builds. The threshold is in kilobytes. If the callback causes a memory allocation greater than the threshold, a warning will be logged.
---@param value number @Threshold in kilobytes for logging warnings about memory allocations. `0` disables tracking.
function event.set_memory_threshold(value) end

---Create new event instance. If callback is passed, it will be subscribed to the event.
---@nodiscard
---@param callback function|nil @The function to be called when the event is triggered.
---@param callback_context any|nil @The first parameter to be passed to the callback function.
---@return event @A new event instance.
function event.create(callback, callback_context) end

---Subscribe to the event. If the callback is already subscribed, it will not be added again.
---@param callback function @The function to be executed when the event occurs.
---@param callback_context any|nil @The first parameter to be passed to the callback function.
---@return boolean @True if event is subscribed
function event:subscribe(callback, callback_context) end

---Unsubscribe from the event. If the callback is not subscribed, nothing will happen.
---@param callback function @The callback function to unsubscribe.
---@param callback_context any|nil @The first parameter to be passed to the callback function.
---@return boolean @True if event is unsubscribed
function event:unsubscribe(callback, callback_context) end

---Check if the callback is subscribed to the event.
---@param callback function @The callback function in question.
---@param callback_context any|nil @The first parameter to be passed to the callback function.
---@return boolean @True if the callback is subscribed to the event
---@return number|nil @Index of callback in event if subscribed
function event:is_subscribed(callback, callback_context) end

---Trigger the event and call all subscribed callbacks. Returns the result of the last callback. If no callbacks are subscribed, nothing will happen.
---@vararg any @Any number of parameters to be passed to the subscribed callbacks.
---@return any @Result of the last triggered callback
function event.trigger(...) end

---Clear all subscribed callbacks.
function event:clear() end

---Check if the event has any subscribed callbacks.
---@return boolean @True if the event has any subscribed callbacks
---@return number @Number of subscribed callbacks
function event:is_empty() end

---@class event.logger
---@field trace fun(logger: event.logger, message: string, data: any|nil) @Log a trace message.
---@field debug fun(logger: event.logger, message: string, data: any|nil) @Log a debug message.
---@field info fun(logger: event.logger, message: string, data: any|nil) @Log an info message.
---@field warn fun(logger: event.logger, message: string, data: any|nil) @Log a warning message.
---@field error fun(logger: event.logger, message: string, data: any|nil) @Log an error message.