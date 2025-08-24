local event = require("event.event")

---@class queue.event_data
---@field data any
---@field on_handle event

---The Queue module, used to create and manage FIFO event queues. Allows to push events to a queue and subscribe handlers to process them.
---Events are stored in the queue until they are handled by subscribers, following first-in-first-out (FIFO) order.
---@class queue
---@field private events queue.event_data[]
---@field private handlers event[]
local M = {}

-- Forward declaration
local QUEUE_METATABLE

-- Local versions
local table_insert = table.insert
local table_remove = table.remove


---Generate a new queue instance. This instance can then be used to push events and subscribe handlers.
---The handler function will be called when events are pushed to the queue. The handler_context parameter is optional
---and will be passed as the first parameter to the handler function. Usually, it is used to pass the self instance.
---@param handler function|event|nil The function to be called when events are pushed to the queue.
---@param handler_context any|nil The first parameter to be passed to the handler function.
---@return queue queue_instance A new queue instance.
---@nodiscard
function M.create(handler, handler_context)
	---@type queue
	local self = setmetatable({
		events = {},
		handlers = {}
	}, QUEUE_METATABLE)

	if handler then
		self:subscribe(handler, handler_context)
	end

	return self
end


---Check if a value is a queue object
---@param value any The value to check
---@return boolean is_queue True if the value is a queue
function M.is_queue(value)
	return type(value) == "table" and getmetatable(value) == QUEUE_METATABLE
end


---Push a new event to the queue. The event will exist until it's handled by a subscriber.
---If there are already subscribers for this queue instance, they will be called immediately.
---If multiple subscribers handle the event, all subscribers will still be called. The on_handle callback
---will be called for each subscriber that handles the event.
---@param data any The data associated with the event.
---@param on_handle function|event|nil Callback function or event to be called when the event is handled.
---@param context any|nil The context to be passed as the first parameter to the on_handle function when the event is handled.
function M:push(data, on_handle, context)
	local event_data = {
		data = data,
		on_handle = on_handle and event.create(on_handle, context)
	}

	table_insert(self.events, event_data)
	self:_check_subscribers()
end


---Subscribe a handler to this queue instance. When an event is pushed to this queue,
---the handler will be called. If there are already events in the queue, they will be processed immediately.
---@param handler function|event The handler function or event to be called when an event is pushed. Return true from the handler to mark the event as handled.
---@param context any|nil The context to be passed as the first parameter to the handler function.
---@return boolean is_subscribed True if handler was subscribed successfully
function M:subscribe(handler, context)
	if self:is_subscribed(handler, context) then
		return false
	end

	-- Add the handler
	table_insert(self.handlers, event.create(handler, context))

	self:_check_subscribers()

	return true
end


---Unsubscribe a handler from this queue instance.
---@param handler function|event The handler function or event to unsubscribe.
---@param context any|nil The context that was passed when subscribing.
---@return boolean is_unsubscribed True if handler was unsubscribed successfully
function M:unsubscribe(handler, context)
	assert(handler, "A function must be passed to unsubscribe from a queue")

	local is_removed = false
	for index = #self.handlers, 1, -1 do
		local handler_event = self.handlers[index]
		if handler_event:is_subscribed(handler, context) then
			table_remove(self.handlers, index)
			is_removed = true
		end
	end

	return is_removed
end


---Check if a handler is subscribed to this queue instance.
---@param handler function|event The handler function or event to check.
---@param context any|nil The context that was passed when subscribing.
---@return boolean is_subscribed True if handler is subscribed
---@return number|nil index Index of handler if subscribed
function M:is_subscribed(handler, context)
	for index = 1, #self.handlers do
		local handler_event = self.handlers[index]
		if handler_event:is_subscribed(handler, context) then
			return true, index
		end
	end

	return false, nil
end


---Process all events in this queue immediately. Subscribers will not be called in this function.
---Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.
---@param event_handler function|event Specific handler or event to process the events. If this function returns true, the event will be removed from the queue.
---@param context any|nil The context to be passed to the handler.
function M:process(event_handler, context)
	if #self.events == 0 then
		return
	end

	-- Process events in FIFO order (first in, first out)
	local event_index = 1
	while event_index <= #self.events do
		local event_data = self.events[event_index]
		local handle_result = nil

		if event_handler then
			if context then
				handle_result = event_handler(context, event_data.data)
			else
				handle_result = event_handler(event_data.data)
			end

			if handle_result ~= nil then
				if event_data.on_handle then
					event_data.on_handle(handle_result)
				end
				-- Remove the event, don't increment index since elements shift down
				table_remove(self.events, event_index)
			else
				-- Event not handled, move to next event
				event_index = event_index + 1
			end
		else
			-- No handler provided, move to next event
			event_index = event_index + 1
		end
	end
end


---Process exactly one queued event with a specific handler (subscribers will NOT be called).
---If the handler returns non-nil the event will be removed from the queue.
---@param event_handler function|event Specific handler or event to process the event. If this function returns non-nil, the event will be removed from the queue.
---@param context any|nil The context to be passed to the handler.
---@return boolean handled True if the head event was handled and removed
function M:process_next(event_handler, context)
	if #self.events == 0 or not event_handler then
		return false
	end

	local event_data = self.events[1]
	local handle_result

	if context then
		handle_result = event_handler(context, event_data.data)
	else
		handle_result = event_handler(event_data.data)
	end

	if handle_result ~= nil then
		if event_data.on_handle then
			event_data.on_handle(handle_result)
		end
		table_remove(self.events, 1)
		return true
	end

	return false
end


---Get all pending events in this queue.
---@return queue.event_data[] events A table of pending events.
function M:get_events()
	return self.events
end


---Clear all pending events in this queue.
function M:clear_events()
	for index = #self.events, 1, -1 do
		self.events[index] = nil
	end
end


---Clear all subscribers from this queue instance.
function M:clear_subscribers()
	for index = #self.handlers, 1, -1 do
		self.handlers[index] = nil
	end
end


---Check if this queue has no pending events.
---@return boolean is_empty True if the queue has no pending events
function M:is_empty()
	return #self.events == 0
end


---Check if this queue instance has no subscribed handlers.
---@return boolean has_subscribers True if the queue instance has subscribed handlers
function M:has_subscribers()
	return #self.handlers > 0
end


---Remove all events and handlers from this queue instance, effectively resetting it.
function M:clear()
	self:clear_events()
	self:clear_subscribers()
end


---Process the events if there are subscribers for this queue instance.
---If event is handled, it will be removed from the queue.
---All subscribers will be called for each event, even if it's already been handled.
---@private
function M:_check_subscribers()
	if #self.events == 0 or #self.handlers == 0 then
		return -- No events or handlers to process
	end

	-- Process events in FIFO order (first in, first out)
	local event_index = 1
	while event_index <= #self.events do
		local event_data = self.events[event_index]
		local is_handled = false

		for index = 1, #self.handlers do
			local event_handler = self.handlers[index]

			local handle_result = event_handler:trigger(event_data.data)
			if handle_result ~= nil then
				if event_data.on_handle then
					event_data.on_handle(handle_result)
				end
				is_handled = true
				-- No break here, continue processing all subscribers
			end
		end

		if is_handled then
			-- Remove the event, don't increment index since elements shift down
			table_remove(self.events, event_index)
		else
			-- Event not handled, move to next event
			event_index = event_index + 1
		end
	end
end


-- Construct queue metatable
QUEUE_METATABLE = {
	__index = M,
}

return M
