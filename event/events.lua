local Event = require("event.event")

local M = {}

---@type table<string, event>
M.events = {}


---Throws the event
---@param event_name string Event name
---@vararg any @Event params
---@return any @Result of the last triggered callback
function M.trigger(event_name, ...)
	local event = M.events[event_name]
	if event then
		return event:trigger(...)
	end
end


---Clear the event by name
---@param name string Event name
function M.clear(name)
	M.events[name] = nil
end


---Clear all events
function M.clear_all()
	M.events = {}
end


---Subscribe the callback on event
---@param event_name string Event name
---@param callback function Event callback
---@param callback_context any|nil Callback context
---@return boolean|nil @True if event is subscribed
function M.subscribe(event_name, callback, callback_context)
	M.events[event_name] = M.events[event_name] or Event.create()
	local is_subscribed = M.events[event_name]:subscribe(callback, callback_context)

	if not is_subscribed then
		Event.logger:warn("Event is not subscribed", event_name)
	end

	return is_subscribed
end


---Unsubscribe the event from events flow
---@param event_name string Event name
---@param callback function Event callback
---@param callback_context any|nil Callback context
---@return boolean @True if event is unsubscribed. If event is not exist, return false
function M.unsubscribe(event_name, callback, callback_context)
	if not M.events[event_name] then
		return false
	end

	return M.events[event_name]:unsubscribe(callback, callback_context)
end


---Check if the event is subscribed
---@param event_name string Event name
---@param callback function Event callback
---@param callback_context any|nil Callback context
---@return boolean @True if event is subscribed. If event is not exist, return false
function M.is_subscribed(event_name, callback, callback_context)
	if not M.events[event_name] then
		return false
	end

	return M.events[event_name]:is_subscribed(callback, callback_context)
end


---Check if the event is empty
---@param event_name string Event name
---@return boolean @True if event is empty. If event is not exist, return true
function M.is_empty(event_name)
	if not M.events[event_name] then
		return true
	end

	return M.events[event_name]:is_empty()
end


return M
