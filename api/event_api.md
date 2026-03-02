# event API

> at /event/event.lua

The Event module, used to create and manage events. Allows to subscribe to events and trigger them.

## Functions

- [create](#create)
- [is_event](#is_event)
- [set_logger](#set_logger)
- [set_mode](#set_mode)
- [subscribe](#subscribe)
- [subscribe_once](#subscribe_once)
- [unsubscribe](#unsubscribe)
- [is_subscribed](#is_subscribed)
- [trigger](#trigger)
- [is_empty](#is_empty)
- [clear](#clear)


### create

---
```lua
event.create([callback], [callback_context])
```

Generate a new event instance. This instance can then be used to subscribe to and trigger events.
The callback function will be called when the event is triggered. The callback_context parameter is optional
and will be passed as the first parameter to the callback function. Usually, it is used to pass the self instance.

- **Parameters:**
	- `[callback]` *(function|event|nil)*: The function to be called when the event is triggered. Or the event instance to subscribe.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function.

- **Returns:**
	- `event_instance` *(event)*: A new event instance.

- **Example Usage:**

```lua
local e = event.create()
local e = event.create(function(self) print("ok") end, self)
```
### is_event

---
```lua
event.is_event([value])
```

Check if the table is an event instance.

- **Parameters:**
	- `[value]` *(any)*:

- **Returns:**
	- `is_event` *(boolean)*:

- **Example Usage:**

```lua
if event.is_event(my_value) then
	my_value:trigger()
end
```
### set_logger

---
```lua
event.set_logger([logger_instance])
```

Customize the logging mechanism used by Event module. You can use **Defold Log** library or provide a custom logger.
By default, the module uses the `pprint` logger for errors.

- **Parameters:**
	- `[logger_instance]` *(table|event.logger|nil)*: A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.

### set_mode

---
```lua
event.set_mode(mode)
```

Set the mode of the event module.
```lua
mode:
    | "pcall"
    | "xpcall"
    | "none"
```

- **Parameters:**
	- `mode` *("none"|"pcall"|"xpcall")*: The mode to set.

### subscribe

---
```lua
event:subscribe(callback, [callback_context])
```

Subscribe a callback to the event or other event. The callback will be invoked whenever the event is triggered.
The callback_context parameter is optional and will be passed as the first parameter to the callback function.
If the callback with context is already subscribed, the warning will be logged.

- **Parameters:**
	- `callback` *(function|event)*: The function to be executed when the event occurs.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if event is subscribed (Will return false if the callback is already subscribed)

- **Example Usage:**

```lua
local function callback(self)
	print("clicked!")
end
on_click_event:subscribe(callback, self)
-- Subscribe an event to another event
event_1 = event.create(callback)
event_2 = event.create()
event_2:subscribe(event_1) -- Now event2 will trigger event1
```
### subscribe_once

---
```lua
event:subscribe_once(callback, [callback_context])
```

Subscribe a callback for a single trigger. After the first trigger the callback is automatically unsubscribed.

- **Parameters:**
	- `callback` *(function|event)*: The function or event to run once.
	- `[callback_context]` *(any)*: Same as subscribe.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if subscribed

- **Example Usage:**

```lua
on_click_event:subscribe_once(function(self) print("one-time click!") end, self)
```
### unsubscribe

---
```lua
event:unsubscribe(callback, [callback_context])
```

Remove a previously subscribed callback from the event.
The callback_context should be the same as the one used when subscribing the callback.
If there is no callback_context provided, all callbacks with the same function will be unsubscribed.

- **Parameters:**
	- `callback` *(function|event)*: The callback function to unsubscribe.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function. If not provided, will unsubscribe all callbacks with the same function.

- **Returns:**
	- `is_unsubscribed` *(boolean)*: True if event is unsubscribed

- **Example Usage:**

```lua
on_click_event:unsubscribe(callback, self)
```
### is_subscribed

---
```lua
event:is_subscribed(callback, [callback_context])
```

Determine if a specific callback is currently subscribed to the event.
The callback_context should be the same as the one used when subscribing the callback.

- **Parameters:**
	- `callback` *(function|event)*: The callback function in question. Or the event instance to check.
	- `[callback_context]` *(any)*: The first parameter to be passed to the callback function.

- **Returns:**
	- `is_subscribed` *(boolean)*: True if the callback is subscribed to the event
	- `index` *(number|nil)*: Index of callback in event if subscribed (return first found index)

- **Example Usage:**

```lua
local is_subscribed = on_click_event:is_subscribed(callback, self)
```
### trigger

---
```lua
event:trigger(...)
```

Trigger the event, causing all subscribed callbacks to be executed.
Any parameters passed to trigger will be forwarded to the callbacks.
The return value of the last executed callback is returned.
The event:trigger(...) can be called as event(...).

- **Parameters:**
	- `...` *(...)*: vararg

- **Returns:**
	- `result` *(any)*: Result of the last triggered callback

- **Example Usage:**

```lua
on_click_event:trigger("arg1", "arg2")
-- The event can be triggered as a function
on_click_event("arg1", "arg2")
```
### is_empty

---
```lua
event:is_empty()
```

Check if the event has no subscribed callbacks.

- **Returns:**
	- `is_empty` *(boolean)*: True if the event has no subscribed callbacks

- **Example Usage:**

```lua
local is_empty = on_click_event:is_empty()
```
### clear

---
```lua
event:clear()
```

Remove all callbacks subscribed to the event, effectively resetting it.

- **Example Usage:**

```lua
on_click_event:clear()
```
