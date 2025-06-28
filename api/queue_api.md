# event.queue API

> at /event/queue.lua

The Queue module, used to create and manage FIFO event queues. Allows to push events to a queue and subscribe handlers to process them.
Events are stored in the queue until they are handled by subscribers, following first-in-first-out (FIFO) order.
Unlike regular events which are processed immediately, queued events accumulate until they are explicitly handled by a subscriber.

## Functions

- [create](#create)
- [push](#push)
- [subscribe](#subscribe)
- [unsubscribe](#unsubscribe)
- [is_subscribed](#is_subscribed)
- [process](#process)
- [get_events](#get_events)
- [clear_events](#clear_events)
- [clear_subscribers](#clear_subscribers)
- [is_empty](#is_empty)
- [has_subscribers](#has_subscribers)
- [clear](#clear)



### create

---
```lua
queue.create([handler], [handler_context])
```

Generate a new queue instance. This instance can then be used to push events and subscribe handlers.
The handler function will be called when events are pushed to the queue. The handler_context parameter is optional
and will be passed as the first parameter to the handler function. Usually, it is used to pass the self instance.

- **Parameters:**
	- `[handler]` *(function|nil)*: The function to be called when events are pushed to the queue.
	- `[handler_context]` *(any|nil)*: The first parameter to be passed to the handler function.

- **Returns:**
	- `queue_instance` *(queue)*: A new queue instance.

**Example:**
```lua
local queue = require("event.queue")

-- Create empty queue instance
local queue_instance = queue.create()

-- Create queue instance with initial handler
local queue_with_handler = queue.create(function(self, data)
	print("Event received:", data)
	return true -- Mark as handled
end, self)
```

### push

---
```lua
queue_instance:push(data, [on_handle], [context])
```

Push a new event to the queue. The event will exist until it's handled by a subscriber.
If there are already subscribers for this queue instance, they will be called immediately.
If multiple subscribers handle the event, all subscribers will still be called. The on_handle callback
will be called for each subscriber that handles the event.

- **Parameters:**
	- `data` *(any)*: The data associated with the event.
	- `[on_handle]` *(function|nil)*: Callback function to be called when the event is handled.
	- `[context]` *(any|nil)*: The context to be passed as the first parameter to the on_handle function when the event is handled.

**Example:**
```lua
-- Push simple event
queue_instance:push("hello_world")

-- Push event with callback
queue_instance:push(save_data, function(result)
	print("Save completed with result:", result)
end)

-- Push event with callback and context
queue_instance:push(save_data, function(self, result)
	self:on_save_complete(result)
end, self)
```

### subscribe

---
```lua
queue_instance:subscribe(handler, [context])
```

Subscribe a handler to this queue instance. When an event is pushed to this queue,
the handler will be called. If there are already events in the queue, they will be processed immediately.

- **Parameters:**
	- `handler` *(function)*: The handler function to be called when an event is pushed. Return true from the handler to mark the event as handled.
	- `[context]` *(any|nil)*: The context to be passed as the first parameter to the handler function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler was subscribed successfully

**Example:**
```lua
-- Subscribe handler
queue_instance:subscribe(function(data)
	print("Processing:", data)
	return true -- Mark as handled
end)

-- Subscribe handler with context
queue_instance:subscribe(function(self, data)
	self:process_data(data)
	return true
end, self)
```

### unsubscribe

---
```lua
queue_instance:unsubscribe(handler, [context])
```

Unsubscribe a handler from this queue instance.

- **Parameters:**
	- `handler` *(function)*: The handler function to unsubscribe.
	- `[context]` *(any|nil)*: The context that was passed when subscribing.

- **Returns:**
	- `is_unsubscribed` *(boolean)*: True if handler was unsubscribed successfully

**Example:**
```lua
local handler = function(data) return true end
queue_instance:subscribe(handler)
queue_instance:unsubscribe(handler)
```

### is_subscribed

---
```lua
queue_instance:is_subscribed(handler, [context])
```

Check if a handler is subscribed to this queue instance.

- **Parameters:**
	- `handler` *(function)*: The handler function to check.
	- `[context]` *(any|nil)*: The context that was passed when subscribing.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler is subscribed
	- `index` *(number|nil)*: Index of handler if subscribed

### process

---
```lua
queue_instance:process(event_handler, [context])
```

Process all events in this queue immediately. Subscribers will not be called in this function.
Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.
Events are processed in FIFO order (first in, first out).

- **Parameters:**
	- `event_handler` *(function)*: Specific handler to process the events. If this function returns true, the event will be removed from the queue.
	- `[context]` *(any|nil)*: The context to be passed to the handler.

**Example:**
```lua
queue_instance:process(function(self, data)
	-- Custom processing logic
	return true -- Remove event from queue
end, self)
```

### get_events

---
```lua
queue_instance:get_events()
```

Get all pending events in this queue.

- **Returns:**
	- `events` *(table)*: A table of pending events.

### clear_events

---
```lua
queue_instance:clear_events()
```

Clear all pending events in this queue.

### clear_subscribers

---
```lua
queue_instance:clear_subscribers()
```

Clear all subscribers from this queue instance.

### is_empty

---
```lua
queue_instance:is_empty()
```

Check if this queue has no pending events.

- **Returns:**
	- `is_empty` *(boolean)*: True if the queue has no pending events

### has_subscribers

---
```lua
queue_instance:has_subscribers()
```

Check if this queue instance has subscribed handlers.

- **Returns:**
	- `has_subscribers` *(boolean)*: True if the queue instance has subscribed handlers

### clear

---
```lua
queue_instance:clear()
```

Remove all events and handlers from this queue instance, effectively resetting it.
