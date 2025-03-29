# Event API Reference

## Core Functions

**event.create**
---
```lua
event.create([callback], [callback_context])
```
Generate a new event instance. This instance can then be used to subscribe to and trigger events. The `callback` function will be called when the event is triggered. The `callback_context` parameter is optional and will be passed as the first parameter to the callback function. Usually, it is used to pass the `self` instance. Allocate `64` bytes per instance.

- **Parameters:**
  - `callback` (optional): The function to be called when the event is triggered. Or the event instance to subscribe.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Return Value:** A new event instance.

- **Usage Example:**

```lua
local function callback(self)
	print("clicked!")
end

function init(self)
	self.on_click_event = event.create(callback, self)
end
```

## Event Instance Methods

Once an event instance is created, you can interact with it using the following methods:

**event:subscribe**
---
```lua
event:subscribe(callback, [callback_context])
```
Subscribe a callback to the event or other event. The callback will be invoked whenever the event is triggered. The `callback_context` parameter is optional and will be passed as the first parameter to the callback function. If the callback with context is already subscribed, the warning will be logged. Allocate `160` bytes per first subscription and `104` bytes per next subscriptions.

- **Parameters:**
  - `callback`: The function to be executed when the event occurs, or another event instance.
  - `callback_context` (optional): The first parameter to be passed to the callback function. Not used for event instance.

- **Return Value:** `true` if the subscription was successful, `false` otherwise.

- **Usage Example:**

```lua
on_click_event:subscribe(callback, self)
```

You can subscribe another event instance to be triggered by the event. Example:
```lua
event_1 = event.create(callback)
event_2 = event.create()
event_2:subscribe(event_1) -- Now event2 will trigger event1
event_2:trigger() -- callback from event1 will be called
```

**event:unsubscribe**
---
```lua
event:unsubscribe(callback, [callback_context])
```
Remove a previously subscribed callback from the event. The `callback_context` should be the same as the one used when subscribing the callback. If there is no `callback_context` provided, all callbacks with the same function will be unsubscribed.

- **Parameters:**
  - `callback`: The callback function to unsubscribe, or the event instance to unsubscribe.
  - `callback_context` (optional): The first parameter to be passed to the callback function. If not provided, will unsubscribe all callbacks with the same function. Not used for event instances.

- **Return Value:** `true` if the unsubscription was successful, `false` otherwise.

- **Usage Example:**

```lua
on_click_event:unsubscribe(callback, self)
```

**event:is_subscribed**
---
```lua
event:is_subscribed(callback, [callback_context])
```
Determine if a specific callback is currently subscribed to the event. The `callback_context` should be the same as the one used when subscribing the callback.

- **Parameters:**
  - `callback`: The callback function in question. Or the event instance to check.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Return Value:** `true` if the callback is subscribed to the event, `false` otherwise.

- **Usage Example:**

```lua
local is_subscribed = on_click_event:is_subscribed(callback, self)
```

**event:trigger**
---
```lua
event:trigger(...)
```
Trigger the event, causing all subscribed callbacks to be executed. Any parameters passed to `trigger` will be forwarded to the callbacks. The return value of the last executed callback is returned. The `event:trigger(...)` can be called as `event(...)`.

- **Parameters:** Any number of parameters to be passed to the subscribed callbacks.

- **Return Value:** The return value of the last callback executed.

- **Usage Example:**

```lua
on_click_event:trigger("arg1", "arg2")

-- The event can be triggered as a function
on_click_event("arg1", "arg2")
```

**event:is_empty**
---
```lua
event:is_empty()
```
Check if the event has no subscribed callbacks.

- **Return Value:** `true` if the event has no subscribed callbacks, `false` otherwise.

- **Usage Example:**

```lua
local is_empty = on_click_event:is_empty()
```

**event:clear**
---
```lua
event:clear()
```
Remove all callbacks subscribed to the event, effectively resetting it.

- **Usage Example:**

```lua
on_click_event:clear()
```

## Configuration Functions

**event.set_logger**
---
Customize the logging mechanism used by Event module. You can use **Defold Log** library or provide a custom logger. By default, the module uses the `pprint` logger.

```lua
event.set_logger([logger_instance])
```

- **Parameters:**
  - `logger_instance` (optional): A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.

- **Usage Example:**

Using the [Defold Log](https://github.com/Insality/defold-log) module:
```lua
-- Use defold-log module
local log = require("log.log")
local event = require("event.event")

event.set_logger(log.get_logger("event"))
```

Creating a custom user logger:
```lua
-- Create a custom logger
local logger = {
    trace = function(_, message, context) end,
    debug = function(_, message, context) end,
    info = function(_, message, context) end,
    warn = function(_, message, context) end,
    error = function(_, message, context) end
}
event.set_logger(logger)
```

Remove the default logger:
```lua
event.set_logger(nil)
```

**event.set_memory_threshold**
---
Set the threshold for logging warnings about memory allocations in event callbacks. Works only in debug builds. The threshold is in kilobytes. If the callback causes a memory allocation greater than the threshold, a warning will be logged.

```lua
event.set_memory_threshold(threshold)
```

- **Parameters:**
  - `threshold`: Threshold in kilobytes for logging warnings about memory allocations. `0` disables tracking.

- **Usage Example:**

```lua
event.set_memory_threshold(50)
event.set_memory_threshold(0) -- Disable tracking
```
