local event = require("event.event")

---Deferred event system that allows events to be queued until they are handled.
---This differs from regular events which are processed immediately.
---@class defer
local M = {}

-- Local versions of functions to improve performance
local table_insert = table.insert
local table_remove = table.remove

---Storage for all deferred events organized by event_id
---@type table<string, table<number, {data:any, on_handle:event}>>
local deferred_events = {}

---Storage for all event handlers organized by event_id
---@type table<string, table<number, {handler:function, context:any, callback:function}>>
local handlers = {}

---Push a new event to the deferred queue. The event will exist until it's handled by a subscriber.
---If there are already subscribers for this event_id, they will be called immediately.
---@param event_id string The unique identifier for the event type.
---@param data any The data associated with the event.
---@param on_handle function|nil Callback function to be called when the event is handled.
---@param context any|nil The context to be passed as the first parameter to the on_handle function.
function M.push(event_id, data, on_handle, context)
	deferred_events[event_id] = deferred_events[event_id] or {}

	local event_data = {
		data = data,
		on_handle = on_handle and event.create(on_handle, context),
	}

	-- Add to queue
	table_insert(deferred_events[event_id], event_data)

	M._process_handlers(event_id)
end

---Subscribe a handler to a specific event type. When an event of this type is pushed,
---the handler will be called. If there are already events in the queue for this event_id,
---they will be processed immediately.
---@param event_id string The unique identifier for the event type.
---@param handler function The handler function to be called when an event is pushed. Return true from the handler to mark the event as handled.
---@param context any|nil The context to be passed as the first parameter to the handler function.
---@return boolean is_subscribed True if handler was subscribed successfully
function M.subscribe(event_id, handler, context)
	if M.is_subscribed(event_id, handler, context) then
		return false
	end

	-- Initialize handlers for this event_id if needed
	handlers[event_id] = handlers[event_id] or {}

	-- Add the handler
	table_insert(handlers[event_id], {
		handler = handler,
		context = context,
		callback = event.create(handler, context)
	})

	M._process_handlers(event_id)

	return true
end

---Unsubscribe a handler from a specific event type.
---@param event_id string The unique identifier for the event type.
---@param handler function The handler function to unsubscribe.
---@param context any|nil The context that was passed when subscribing.
---@return boolean is_unsubscribed True if handler was unsubscribed successfully
function M.unsubscribe(event_id, handler, context)
	assert(handler, "A function must be passed to unsubscribe from an event")

	-- Check if there are handlers for this event_id
	if not handlers[event_id] then
		return false
	end

	local is_removed = false
	for i = #handlers[event_id], 1, -1 do
		local handler_data = handlers[event_id][i]
		if handler_data.handler == handler and (context == nil or handler_data.context == context) then
			table_remove(handlers[event_id], i)
			is_removed = true
		end
	end

	-- Clean up if no more handlers
	if #handlers[event_id] == 0 then
		handlers[event_id] = nil
	end

	return is_removed
end


---Check if a handler is subscribed to a specific event type.
---@param event_id string The unique identifier for the event type.
---@param handler function The handler function to check.
---@param context any|nil The context that was passed when subscribing.
---@return boolean is_subscribed True if handler is subscribed
---@return number|nil index Index of handler if subscribed
function M.is_subscribed(event_id, handler, context)
	if not handlers[event_id] then
		return false, nil
	end

	for index = 1, #handlers[event_id] do
		local handler_data = handlers[event_id][index]
		if handler_data.handler == handler and handler_data.context == context then
			return true, index
		end
	end

	return false, nil
end


---Process all events of a specific type immediately.
---If a specific handler is provided, only that handler will be used.
---Otherwise, all subscribed handlers will be used.
---Return true from the handler to mark the event as handled.
---@param event_id string The unique identifier for the event type.
---@param event_handler function|nil Specific handler to process the events. If nil, all subscribed handlers will be used.
---@param context any|nil The context to be passed to the handler.
function M.process(event_id, event_handler, context)
	if not deferred_events[event_id] or #deferred_events[event_id] == 0 then
		return
	end

	local events = deferred_events[event_id]
	for event_index = #events, 1, -1 do
		local event_data = events[event_index]
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
				table_remove(events, event_index)
			end
		end
	end

	-- Clean up if all events are handled
	if #events == 0 then
		deferred_events[event_id] = nil
	end
end


---Get all pending events for a specific event type.
---@param event_id string The unique identifier for the event type.
---@return table events A table of pending events organized by event_id.
function M.get_events(event_id)
	return deferred_events[event_id] or {}
end


---Clear all pending events for a specific event type.
---@param event_id string The unique identifier for the event type.
function M.clear(event_id)
	deferred_events[event_id] = nil
end


---Clear all handlers for a specific event type.
---@param event_id string The unique identifier for the event type.
function M.clear_subscribers(event_id)
	handlers[event_id] = nil
end


---Process all handlers for a specific event type.
---@param event_id string The unique identifier for the event type.
function M._process_handlers(event_id)
	local events = deferred_events[event_id]
	if not events or #events == 0 then
		return
	end

	local event_handlers = handlers[event_id]
	if not event_handlers or #event_handlers == 0 then
		return -- No handlers to process events
	end

	for event_index = #events, 1, -1 do
		local event_data = events[event_index]
		local is_handled = false

		for index = 1, #event_handlers do
			local event_handler = event_handlers[index]

			local handle_result = event_handler.callback(event_data.data)
			if handle_result ~= nil then
				if event_data.on_handle then
					event_data.on_handle(handle_result)
				end
				is_handled = true
			end
		end

		if is_handled then
			table_remove(events, event_index)
		end
	end
end


return M
