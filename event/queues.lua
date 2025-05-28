local queue = require("event.queue")

---Global queues module that allows creation and management of global FIFO event queues that can be accessed from anywhere in your game.
---This is particularly useful for events that need to be handled by multiple scripts or systems using a queue-based approach.
---@class queues
local M = {}

---Storage for all queue instances
---@type table<string, queue>
M.queues = {}


---Push a new event to the specified global queue. The event will exist until it's handled by a subscriber.
---If there are already subscribers for this queue_id, they will be called immediately.
---		queues.push("save_game", save_data, on_save_complete, self)
---@param queue_id string The id of the global queue to push to.
---@param data any The data associated with the event.
---@param on_handle function|nil Callback function to be called when the event is handled.
---@param context any|nil The context to be passed as the first parameter to the on_handle function when the event is handled.
function M.push(queue_id, data, on_handle, context)
	M.queues[queue_id] = M.queues[queue_id] or queue.create()
	M.queues[queue_id]:push(data, on_handle, context)
end


---Subscribe a handler to the specified global queue.
---When an event is pushed to this queue, the handler will be called.
---		function init(self)
---			queues.subscribe("save_game", save_handler, self)
---		end
---@param queue_id string The id of the global queue to subscribe to.
---@param handler function The handler function to be called when an event is pushed. Return true from the handler to mark the event as handled.
---@param context any|nil The context to be passed as the first parameter to the handler function.
---@return boolean is_subscribed True if handler was subscribed successfully
function M.subscribe(queue_id, handler, context)
	M.queues[queue_id] = M.queues[queue_id] or queue.create()
	return M.queues[queue_id]:subscribe(handler, context)
end


---Unsubscribe a handler from the specified global queue.
---The context should be the same as the one used when subscribing the handler.
---		function final(self)
---			queues.unsubscribe("save_game", save_handler, self)
---		end
---@param queue_id string The id of the global queue to unsubscribe from.
---@param handler function The handler function to unsubscribe.
---@param context any|nil The context that was passed when subscribing.
---@return boolean is_unsubscribed True if handler was unsubscribed successfully
function M.unsubscribe(queue_id, handler, context)
	if not M.queues[queue_id] then
		return false
	end

	return M.queues[queue_id]:unsubscribe(handler, context)
end


---Check if a handler is subscribed to the specified global queue.
---The context should be the same as the one used when subscribing the handler.
---		local is_subscribed = queues.is_subscribed("save_game", save_handler, self)
---@param queue_id string The id of the global queue in question.
---@param handler function The handler function to check.
---@param context any|nil The context that was passed when subscribing.
---@return boolean is_subscribed True if handler is subscribed
---@return number|nil index Index of handler if subscribed
function M.is_subscribed(queue_id, handler, context)
	if not M.queues[queue_id] then
		return false
	end

	return M.queues[queue_id]:is_subscribed(handler, context)
end


---Process all events in the specified global queue immediately. Subscribers will not be called in this function.
---Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.
---		queues.process("save_game", process_save_handler, self)
---@param queue_id string The id of the global queue to process.
---@param event_handler function Specific handler to process the events. If this function returns true, the event will be removed from the queue.
---@param context any|nil The context to be passed to the handler.
function M.process(queue_id, event_handler, context)
	if not M.queues[queue_id] then
		return
	end

	M.queues[queue_id]:process(event_handler, context)
end


---Get all pending events in the specified global queue.
---		local events = queues.get_events("save_game")
---@param queue_id string The id of the global queue to get events from.
---@return table events A table of pending events.
function M.get_events(queue_id)
	if not M.queues[queue_id] then
		return {}
	end

	return M.queues[queue_id]:get_events()
end


---Clear all pending events in the specified global queue.
---		queues.clear_events("save_game")
---@param queue_id string The id of the global queue to clear events from.
function M.clear_events(queue_id)
	if not M.queues[queue_id] then
		return
	end

	M.queues[queue_id]:clear_events()
end


---Clear all subscribers from the specified global queue.
---		queues.clear_subscribers("save_game")
---@param queue_id string The id of the global queue to clear subscribers from.
function M.clear_subscribers(queue_id)
	if not M.queues[queue_id] then
		return
	end

	M.queues[queue_id]:clear_subscribers()
end


---Remove all events and handlers from the specified global queue.
---		queues.clear("save_game")
---@param queue_id string The id of the global queue to clear.
function M.clear(queue_id)
	M.queues[queue_id] = nil
end


---Remove all events and handlers from all global queues.
---		queues.clear_all()
function M.clear_all()
	M.queues = {}
end


---Check if the specified global queue has no pending events.
---		local is_empty = queues.is_empty("save_game")
---@param queue_id string The id of the global queue to check.
---@return boolean is_empty True if the queue has no pending events
function M.is_empty(queue_id)
	if not M.queues[queue_id] then
		return true
	end

	return M.queues[queue_id]:is_empty()
end


---Check if the specified global queue has subscribed handlers.
---		local has_subscribers = queues.has_subscribers("save_game")
---@param queue_id string The id of the global queue to check.
---@return boolean has_subscribers True if the queue has subscribed handlers
function M.has_subscribers(queue_id)
	if not M.queues[queue_id] then
		return false
	end

	return M.queues[queue_id]:has_subscribers()
end


return M
