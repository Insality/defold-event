# Global Events API Reference

The Event library comes with a global events module that allows you to create and manage global events that can be triggered from anywhere in your game. This is particularly useful for events that need to be handled by multiple scripts or systems.

To start using the **Events** module in your project, you first need to import it. This can be done with the following line of code:

Global events module requires careful management of subscriptions and unsubscriptions to prevent errors.

```lua
local events = require("event.events")
```

## API Reference

**events.subscribe**
---
```lua
events.subscribe(name, callback, [callback_context])
```
Subscribe a callback to the specified global event.

- **Parameters:**
  - `name`: The name of the global event to subscribe to.
  - `callback`: The function to be executed when the global event occurs.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Usage Example:**

```lua
function init(self)
	events.subscribe("on_game_over", callback, self)
end
```

**events.unsubscribe**
---
```lua
events.unsubscribe(name, callback, [callback_context])
```
Remove a previously subscribed callback from the specified global event. The `callback_context` should be the same as the one used when subscribing the callback. If there is no `callback_context` provided, all callbacks with the same function will be unsubscribed.

- **Parameters:**
  - `name`: The name of the global event to unsubscribe from.
  - `callback`: The callback function to unsubscribe.
  - `callback_context` (optional): The first parameter to be passed to the callback function. If not provided, will unsubscribe all callbacks with the same function.

- **Usage Example:**

```lua
function final(self)
	events.unsubscribe("on_game_over", callback, self)
end
```

**events.is_subscribed**
---
```lua
events.is_subscribed(name, callback, [callback_context])
```
Determine if a specific callback is currently subscribed to the specified global event.

- **Parameters:**
  - `name`: The name of the global event in question.
  - `callback`: The callback function in question.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Return Value:** `true` if the callback is subscribed to the global event, `false` otherwise.

- **Usage Example:**

```lua
local is_subscribed = events.is_subscribed("on_game_over", callback, self)
```

**events.trigger**
---
```lua
events.trigger(name, ...)
```
Throw a global event with the specified name. All subscribed callbacks will be executed. Any parameters passed to `trigger` will be forwarded to the callbacks. The return value of the last executed callback is returned.

- **Parameters:**
  - `name`: The name of the global event to trigger.
  - `...`: Any number of parameters to be passed to the subscribed callbacks.

- **Usage Example:**

```lua
events.trigger("on_game_over", "arg1", "arg2")
```

**events.is_empty**
---
```lua
events.is_empty(name)
```
Check if the specified global event has no subscribed callbacks.

- **Parameters:**
  - `name`: The name of the global event to check.

- **Return Value:** `true` if the global event has no subscribed callbacks, `false` otherwise.

- **Usage Example:**

```lua
local is_empty = events.is_empty("on_game_over")
```

**events.clear**
---
```lua
events.clear(name)
```
Remove all callbacks subscribed to the specified global event.

- **Parameters:**
  - `name`: The name of the global event to clear.

- **Usage Example:**

```lua
events.clear("on_game_over")
```

**events.clear_all**
---
```lua
events.clear_all()
```
Remove all callbacks subscribed to all global events.

- **Usage Example:**

```lua
events.clear_all()
```
