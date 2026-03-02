# queue API

> at /event/queue.lua

The Queue module, used to create and manage FIFO event queues. Allows to push events to a queue and subscribe handlers to process them.
Events are stored in the queue until they are handled by subscribers, following first-in-first-out (FIFO) order.

## Functions

- [create](#create)
- [is_queue](#is_queue)
- [push](#push)
- [subscribe](#subscribe)
- [subscribe_once](#subscribe_once)
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

- **Example Usage:**

```lua
local save_queue = queue.create()
local save_queue = queue.create(function(self, data) return save_data(self, data) end, self)
```
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

- **Example Usage:**

```lua
if queue.is_queue(my_value) then
	my_value:push(data)
end
```
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

- **Example Usage:**

```lua
my_queue:push(save_data)
my_queue:push(save_data, function() print("saved!") end)
```
### subscribe

---
```lua
queue:subscribe(handler, [context])
```

Subscribe a handler to this queue instance. When an event is pushed to this queue,
the handler will be called. If there are already events in the queue, they will be processed immediately.
Return a non-nil value from the handler to mark the event as handled and remove it from the queue.

- **Parameters:**
	- `handler` *(function|event)*: The handler function or event to be called when an event is pushed.
	- `[context]` *(any)*: The context to be passed as the first parameter to the handler function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler was subscribed successfully

- **Example Usage:**

```lua
local function on_save(self, data)
	do_save(data)
	return true
end
my_queue:subscribe(on_save, self)
```
### subscribe_once

---
```lua
queue:subscribe_once(handler, [context])
```

Subscribe a handler until it handles one event. The handler is invoked for each event in the queue until it returns non-nil (handles an event)
then it is automatically unsubscribed and will not be invoked again, even if more events remain in the queue.

- **Parameters:**
	- `handler` *(function|event)*: The handler function or event to be called when an event is pushed.
	- `[context]` *(any)*: The context to be passed as the first parameter to the handler function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler was subscribed successfully

- **Example Usage:**

```lua
my_queue:subscribe_once(function(self, data) return process(data) end, self)
```
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

- **Example Usage:**

```lua
my_queue:unsubscribe(on_save, self)
```
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

- **Example Usage:**

```lua
local ok = my_queue:is_subscribed(on_save, self)
```
### process

---
```lua
queue:process(event_handler, [context])
```

Process all events in this queue immediately. Subscribers will not be called in this function.
Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.

- **Parameters:**
	- `event_handler` *(function|event)*: Specific handler or event to process the events. If this function returns non-nil, the event will be removed from the queue.
	- `[context]` *(any)*: The context to be passed to the handler.

- **Example Usage:**

```lua
my_queue:process(function(self, data) return handle(data) end, self)
```
### process_next

---
```lua
queue:process_next([event_handler], [context])
```

Process exactly one queued event with a specific handler (subscribers will NOT be called).
If the handler returns non-nil the event will be removed from the queue.

- **Parameters:**
	- `[event_handler]` *(function|event|nil)*: Specific handler or event to process the event. If this function returns non-nil, the event will be removed from the queue.
	- `[context]` *(any)*: The context to be passed to the handler.

- **Returns:**
	- `handled` *(boolean)*: True if the head event was handled and removed

- **Example Usage:**

```lua
local handled = my_queue:process_next(function(data) return handle(data) end)
```
### get_events

---
```lua
queue:get_events()
```

Get all pending events in this queue.

- **Returns:**
	- `events` *(queue.event_data[])*: A table of pending events.

- **Example Usage:**

```lua
for _, event_data in ipairs(my_queue:get_events()) do
	print(event_data.data)
end
```
### clear_events

---
```lua
queue:clear_events()
```

Clear all pending events in this queue.

- **Example Usage:**

```lua
my_queue:clear_events()
```
### clear_subscribers

---
```lua
queue:clear_subscribers()
```

Clear all subscribers from this queue instance.

- **Example Usage:**

```lua
my_queue:clear_subscribers()
```
### is_empty

---
```lua
queue:is_empty()
```

Check if this queue has no pending events.

- **Returns:**
	- `is_empty` *(boolean)*: True if the queue has no pending events

- **Example Usage:**

```lua
if my_queue:is_empty() then
	return
end
```
### has_subscribers

---
```lua
queue:has_subscribers()
```

Check if this queue instance has no subscribed handlers.

- **Returns:**
	- `has_subscribers` *(boolean)*: True if the queue instance has subscribed handlers

- **Example Usage:**

```lua
if my_queue:has_subscribers() then
	my_queue:push(data)
end
```
### clear

---
```lua
queue:clear()
```

Remove all events and handlers from this queue instance, effectively resetting it.

- **Example Usage:**

```lua
my_queue:clear()
```
