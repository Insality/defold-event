# events API

> at /event/events.lua

Global events module that allows creation and management of global events that can be triggered from anywhere in your game.
This is particularly useful for events that need to be handled by multiple scripts or systems.

## Functions

- [trigger](#trigger)
- [clear](#clear)
- [clear_all](#clear_all)
- [subscribe](#subscribe)
- [unsubscribe](#unsubscribe)
- [is_subscribed](#is_subscribed)
- [is_empty](#is_empty)

## Fields

- [events](#events)



### trigger

---
```lua
events.trigger(event_id, ...)
```

Throw a global event with the specified name. All subscribed callbacks will be executed.
Any parameters passed to trigger will be forwarded to the callbacks.
The return value of the last executed callback is returned.

- **Parameters:**
	- `event_id` *(string)*: The id of the global event to trigger.
	- `...` *(...)*: vararg

- **Returns:**
	- `result` *(any)*: Result of the last triggered callback

- **Example Usage:**

```lua
events.trigger("on_game_over", "arg1", "arg2")
```
### clear

---
```lua
events.clear(event_id)
```

Remove all callbacks subscribed to the specified global event.

- **Parameters:**
	- `event_id` *(string)*: The id of the global event to clear.

- **Example Usage:**

```lua
events.clear("on_game_over")
```
### clear_all

---
```lua
events.clear_all()
```

Remove all callbacks subscribed to all global events.

- **Example Usage:**

```lua
events.clear_all()
```
### subscribe

---
```lua
events.subscribe(event_id, callback, [callback_context])
```

Subscribe a callback to the specified global event.
The callback will be invoked whenever the global event is triggered.

- **Parameters:**
	- `event_id` *(string)*: The id of the global event to subscribe to.
	- `callback` *(function)*: The callback function to be executed when the global event occurs.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if event is subscribed (Will return false if callback is already subscribed)

- **Example Usage:**

```lua
function init(self)
	events.subscribe("on_game_over", callback, self)
end
```
### unsubscribe

---
```lua
events.unsubscribe(event_id, callback, [callback_context])
```

Remove a previously subscribed callback from the specified global event.
The callback_context should be the same as the one used when subscribing the callback.
If there is no callback_context provided, all callbacks with the same function will be unsubscribed.

- **Parameters:**
	- `event_id` *(string)*: The id of the global event to unsubscribe from.
	- `callback` *(function)*: The callback function to unsubscribe.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function. If not provided, all callbacks with the same function will be unsubscribed.

- **Returns:**
	- `is_unsubscribed` *(boolean)*: True if event is unsubscribed

- **Example Usage:**

```lua
function final(self)
	events.unsubscribe("on_game_over", callback, self)
end
```
### is_subscribed

---
```lua
events.is_subscribed(event_id, callback, [callback_context])
```

Determine if a specific callback is currently subscribed to the specified global event.
The callback_context should be the same as the one used when subscribing the callback.

- **Parameters:**
	- `event_id` *(string)*: The id of the global event in question.
	- `callback` *(function)*: The callback function in question.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if the callback is subscribed to the global event
	- `index` *(number|nil)*: Index of callback in event if subscribed

- **Example Usage:**

```lua
local is_subscribed = events.is_subscribed("on_game_over", callback, self)
```
### is_empty

---
```lua
events.is_empty(event_id)
```

Check if the specified global event has no subscribed callbacks.

- **Parameters:**
	- `event_id` *(string)*: The id of the global event to check.

- **Returns:**
	- `is_empty` *(boolean)*: True if the global event has no subscribed callbacks

- **Example Usage:**

```lua
local is_empty = events.is_empty("on_game_over")
```

## Fields
<a name="events"></a>
- **events** (_table_): Storage for all event instances

