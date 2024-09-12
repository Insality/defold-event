---@meta events
---@class events
local events = {}

---Subscribe a callback to the specified global event.
---@param event_name string The name of the global event to subscribe to.
---@param callback function The callback function to be executed when the global event occurs.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_subscribed True if event is subscribed
function events.subscribe(event_name, callback, callback_context) end

---Remove a previously subscribed callback from the specified global event.
---@param event_name string The name of the global event to unsubscribe from.
---@param callback function The callback function to unsubscribe.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_unsubscribed True if event is unsubscribed
function events.unsubscribe(event_name, callback, callback_context) end

---Determine if a specific callback is currently subscribed to the specified global event.
---@param event_name string The name of the global event in question.
---@param callback function The callback function in question.
---@param callback_context any|nil The first parameter to be passed to the callback function.
---@return boolean is_subscribed True if the callback is subscribed to the global event
---@return number|nil index Index of callback in event if subscribed
function events.is_subscribed(event_name, callback, callback_context) end

---Throw a global event with the specified name. All subscribed callbacks will be executed.
---@param event_name string The name of the global event to trigger.
---@vararg any Any number of parameters to be passed to the subscribed callbacks.
---@return any result Result of the last triggered callback
function events.trigger(event_name, ...) end

---Remove all callbacks subscribed to the specified global event.
---@param name string The name of the global event to clear.
function events.clear(name) end

---Remove all callbacks subscribed to all global events.
function events.clear_all() end

---Check if the specified global event has no subscribed callbacks.
---@param name string The name of the global event to check.
---@return boolean is_empty True if the global event has no subscribed callbacks
function events.is_empty(name) end