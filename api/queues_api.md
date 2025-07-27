# queues API

> at event/queues.lua

Global queues module that allows creation and management of global FIFO event queues that can be accessed from anywhere in your game.
This is particularly useful for events that need to be handled by multiple scripts or systems using a queue-based approach.

## Functions

- [push](#push)
- [subscribe](#subscribe)
- [unsubscribe](#unsubscribe)
- [is_subscribed](#is_subscribed)
- [process](#process)
- [get_events](#get_events)
- [clear_events](#clear_events)
- [clear_subscribers](#clear_subscribers)
- [clear](#clear)
- [clear_all](#clear_all)
- [is_empty](#is_empty)
- [has_subscribers](#has_subscribers)

## Fields

- [queues](#queues)



### push

---
```lua
queues.push(queue_id, [data], [on_handle], [context])
```

Push a new event to the specified global queue. The event will exist until it's handled by a subscriber.
If there are already subscribers for this queue_id, they will be called immediately.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to push to.
	- `[data]` *(any)*: The data associated with the event.
	- `[on_handle]` *(function|nil)*: Callback function to be called when the event is handled.
	- `[context]` *(any)*: The context to be passed as the first parameter to the on_handle function when the event is handled.

- **Example Usage:**

```lua
queues.push("save_game", save_data, on_save_complete, self)
```
### subscribe

---
```lua
queues.subscribe(queue_id, handler, [context])
```

Subscribe a handler to the specified global queue.
When an event is pushed to this queue, the handler will be called.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to subscribe to.
	- `handler` *(function)*: The handler function to be called when an event is pushed. Return true from the handler to mark the event as handled.
	- `[context]` *(any)*: The context to be passed as the first parameter to the handler function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler was subscribed successfully

- **Example Usage:**

```lua
function init(self)
	queues.subscribe("save_game", save_handler, self)
end
```
### unsubscribe

---
```lua
queues.unsubscribe(queue_id, handler, [context])
```

Unsubscribe a handler from the specified global queue.
The context should be the same as the one used when subscribing the handler.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to unsubscribe from.
	- `handler` *(function)*: The handler function to unsubscribe.
	- `[context]` *(any)*: The context that was passed when subscribing.

- **Returns:**
	- `is_unsubscribed` *(boolean)*: True if handler was unsubscribed successfully

- **Example Usage:**

```lua
function final(self)
	queues.unsubscribe("save_game", save_handler, self)
end
```
### is_subscribed

---
```lua
queues.is_subscribed(queue_id, handler, [context])
```

Check if a handler is subscribed to the specified global queue.
The context should be the same as the one used when subscribing the handler.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue in question.
	- `handler` *(function)*: The handler function to check.
	- `[context]` *(any)*: The context that was passed when subscribing.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if handler is subscribed
	- `index` *(number|nil)*: Index of handler if subscribed

- **Example Usage:**

```lua
local is_subscribed = queues.is_subscribed("save_game", save_handler, self)
```
### process

---
```lua
queues.process(queue_id, event_handler, [context])
```

Process all events in the specified global queue immediately. Subscribers will not be called in this function.
Events can be handled and removed in event handler callback. If event is handled, it will be removed from the queue.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to process.
	- `event_handler` *(function)*: Specific handler to process the events. If this function returns true, the event will be removed from the queue.
	- `[context]` *(any)*: The context to be passed to the handler.

- **Example Usage:**

```lua
queues.process("save_game", process_save_handler, self)
```
### get_events

---
```lua
queues.get_events(queue_id)
```

Get all pending events in the specified global queue.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to get events from.

- **Returns:**
	- `events` *(table)*: A table of pending events.

- **Example Usage:**

```lua
local events = queues.get_events("save_game")
```
### clear_events

---
```lua
queues.clear_events(queue_id)
```

Clear all pending events in the specified global queue.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to clear events from.

- **Example Usage:**

```lua
queues.clear_events("save_game")
```
### clear_subscribers

---
```lua
queues.clear_subscribers(queue_id)
```

Clear all subscribers from the specified global queue.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to clear subscribers from.

- **Example Usage:**

```lua
queues.clear_subscribers("save_game")
```
### clear

---
```lua
queues.clear(queue_id)
```

Remove all events and handlers from the specified global queue.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to clear.

- **Example Usage:**

```lua
queues.clear("save_game")
```
### clear_all

---
```lua
queues.clear_all()
```

Remove all events and handlers from all global queues.

- **Example Usage:**

```lua
queues.clear_all()
```
### is_empty

---
```lua
queues.is_empty(queue_id)
```

Check if the specified global queue has no pending events.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to check.

- **Returns:**
	- `is_empty` *(boolean)*: True if the queue has no pending events

- **Example Usage:**

```lua
local is_empty = queues.is_empty("save_game")
```
### has_subscribers

---
```lua
queues.has_subscribers(queue_id)
```

Check if the specified global queue has subscribed handlers.

- **Parameters:**
	- `queue_id` *(string)*: The id of the global queue to check.

- **Returns:**
	- `has_subscribers` *(boolean)*: True if the queue has subscribed handlers

- **Example Usage:**

```lua
local has_subscribers = queues.has_subscribers("save_game")
```

## Fields
<a name="queues"></a>
- **queues** (_table_): Storage for all queue instances

