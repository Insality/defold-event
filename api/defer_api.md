# event.defer API

> at /event/defer.lua

Deferred event system that allows events to be queued until they are handled.
This differs from regular events which are processed immediately.

## Functions

- [push](#push)
- [subscribe](#subscribe)
- [unsubscribe](#unsubscribe)
- [is_subscribed](#is_subscribed)
- [process](#process)
- [get_events](#get_events)
- [clear_events](#clear_events)
- [clear_subscribers](#clear_subscribers)
- [clear_all](#clear_all)



### push

---
```lua
defer.push(event_id, [data], [on_handle], [context])
```

Push a new event to the deferred queue. The event will exist until it's handled by a subscriber.
If there are already subscribers for this event_id, they will be called immediately.
If multiple subscribers handle the event, all subscribers will still be called. The on_handle callback
will be called for each subscriber that handles the event.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.
	- `[data]` *(any)*: The data associated with the event.
	- `[on_handle]` *(function|nil)*: Callback function to be called when the event is handled.
	- `[context]` *(any)*: The context to be passed as the first parameter to the on_handle function when the event is handled.

### subscribe

---
```lua
defer.subscribe(event_id, handler, [context])
```

Subscribe a handler to a specific event type. When an event of this type is pushed,
the handler will be called. If there are already events in the queue for this event_id,
they will be processed immediately.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.
	- `handler` *(function)*: The handler function to be called when an event is pushed. Return true from the handler to mark the event as handled.
	- `[context]` *(any)*: The context to be passed as the first parameter to the handler function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler was subscribed successfully

### unsubscribe

---
```lua
defer.unsubscribe(event_id, handler, [context])
```

Unsubscribe a handler from a specific event type.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.
	- `handler` *(function)*: The handler function to unsubscribe.
	- `[context]` *(any)*: The context that was passed when subscribing.

- **Returns:**
	- `is_unsubscribed` *(boolean)*: True if handler was unsubscribed successfully

### is_subscribed

---
```lua
defer.is_subscribed(event_id, handler, [context])
```

Check if a handler is subscribed to a specific event type.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.
	- `handler` *(function)*: The handler function to check.
	- `[context]` *(any)*: The context that was passed when subscribing.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler is subscribed
	- `index` *(number|nil)*: Index of handler if subscribed

### process

---
```lua
defer.process(event_id, event_handler, [context])
```

Process all events of a specific type immediately. Subscribers will be not called in this function.
Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.
	- `event_handler` *(function)*: Specific handler to process the events
	- `[context]` *(any)*: The context to be passed to the handler.

### get_events

---
```lua
defer.get_events(event_id)
```

Get all pending events for a specific event type.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.

- **Returns:**
	- `events` *(table)*: A table of pending events organized by event_id.

### clear_events

---
```lua
defer.clear_events(event_id)
```

Clear all pending events for a specific event type.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.

### clear_subscribers

---
```lua
defer.clear_subscribers(event_id)
```

Clear all subscribers for a specific event type.

- **Parameters:**
	- `event_id` *(string)*: The unique identifier for the event type.

### clear_all

---
```lua
defer.clear_all()
```

Clear all pending events and handlers.

