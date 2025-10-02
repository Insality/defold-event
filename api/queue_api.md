# queue API

> at event/queue.lua

The Queue module, used to create and manage FIFO event queues. Allows to push events to a queue and subscribe handlers to process them.
Events are stored in the queue until they are handled by subscribers, following first-in-first-out (FIFO) order.

## Functions

- [create](#create)
- [is_queue](#is_queue)
- [push](#push)
- [subscribe](#subscribe)
- [unsubscribe](#unsubscribe)
- [is_subscribed](#is_subscribed)
- [process](#process)
- [process_next](#process_next)
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
	- `[handler]` *(function|event|nil)*: The function to be called when events are pushed to the queue.
	- `[handler_context]` *(any)*: The first parameter to be passed to the handler function.

- **Returns:**
	- `queue_instance` *(queue)*: A new queue instance.

### is_queue

---
```lua
queue.is_queue([value])
```

Check if a value is a queue object

- **Parameters:**
	- `[value]` *(any)*: The value to check

- **Returns:**
	- `is_queue` *(boolean)*: True if the value is a queue

### push

---
```lua
queue:push([data], [on_handle], [context])
```

Push a new event to the queue. The event will exist until it's handled by a subscriber.
If there are already subscribers for this queue instance, they will be called immediately.
If multiple subscribers handle the event, all subscribers will still be called. The on_handle callback
will be called for each subscriber that handles the event.

- **Parameters:**
	- `[data]` *(any)*: The data associated with the event.
	- `[on_handle]` *(function|event|nil)*: Callback function or event to be called when the event is handled.
	- `[context]` *(any)*: The context to be passed as the first parameter to the on_handle function when the event is handled.

### subscribe

---
```lua
queue:subscribe(handler, [context])
```

Subscribe a handler to this queue instance. When an event is pushed to this queue,
the handler will be called. If there are already events in the queue, they will be processed immediately.

- **Parameters:**
	- `handler` *(function|event)*: The handler function or event to be called when an event is pushed. Return true from the handler to mark the event as handled.
	- `[context]` *(any)*: The context to be passed as the first parameter to the handler function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler was subscribed successfully

### unsubscribe

---
```lua
queue:unsubscribe(handler, [context])
```

Unsubscribe a handler from this queue instance.

- **Parameters:**
	- `handler` *(function|event)*: The handler function or event to unsubscribe.
	- `[context]` *(any)*: The context that was passed when subscribing.

- **Returns:**
	- `is_unsubscribed` *(boolean)*: True if handler was unsubscribed successfully

### is_subscribed

---
```lua
queue:is_subscribed(handler, [context])
```

Check if a handler is subscribed to this queue instance.

- **Parameters:**
	- `handler` *(function|event)*: The handler function or event to check.
	- `[context]` *(any)*: The context that was passed when subscribing.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler is subscribed
	- `index` *(number|nil)*: Index of handler if subscribed

### process

---
```lua
queue:process(event_handler, [context])
```

Process all events in this queue immediately. Subscribers will not be called in this function.
Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.

- **Parameters:**
	- `event_handler` *(function|event)*: Specific handler or event to process the events. If this function returns true, the event will be removed from the queue.
	- `[context]` *(any)*: The context to be passed to the handler.

### process_next

---
```lua
queue:process_next(event_handler, [context])
```

Process exactly one queued event with a specific handler (subscribers will not be called).
If the handler returns non-nil the event will be removed from the queue.

- **Parameters:**
  - `event_handler` *(function|event)*: Specific handler or event to process the head event. If this function returns non-nil, the event will be removed from the queue.
  - `[context]` *(any)*: The context to be passed to the handler.

- **Returns:**
  - `handled` *(boolean)*: True if the head event was handled and removed

### get_events

---
```lua
queue:get_events()
```

Get all pending events in this queue.

- **Returns:**
	- `events` *(queue.event_data[])*: A table of pending events.

### clear_events

---
```lua
queue:clear_events()
```

Clear all pending events in this queue.

### clear_subscribers

---
```lua
queue:clear_subscribers()
```

Clear all subscribers from this queue instance.

### is_empty

---
```lua
queue:is_empty()
```

Check if this queue has no pending events.

- **Returns:**
	- `is_empty` *(boolean)*: True if the queue has no pending events

### has_subscribers

---
```lua
queue:has_subscribers()
```

Check if this queue instance has no subscribed handlers.

- **Returns:**
	- `has_subscribers` *(boolean)*: True if the queue instance has subscribed handlers

### clear

---
```lua
queue:clear()
```

Remove all events and handlers from this queue instance, effectively resetting it.

