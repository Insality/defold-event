![](media/logo.png)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/defold-event?style=for-the-badge&label=Release)](https://github.com/Insality/defold-event/tags)


# Event

**Event** - is a single file Lua module for the [Defold](https://defold.com/) game engine. It provides a simple and efficient way to manage events and callbacks in your game.


## Features

- **Event Management**: Create, subscribe, unsubscribe, and trigger events.
- **Cross-Context**: You can subscribe to events from different scripts.
- **Callback Management**: Attach callbacks to events with optional data.
- **Logging**: Set a logger to log event activities.
- **Memory Allocations Tracker**: Detects if an event callback causes a huge memory allocations.


## Setup

### [Dependency](https://www.defold.com/manuals/libraries/)

Open your `game.project` file and add the following line to the dependencies field under the project section:

**[Event v1](https://github.com/Insality/defold-event/archive/refs/tags/1.zip)**

```
https://github.com/Insality/defold-event/archive/refs/tags/1.zip
```

Size: **2.26 KB**

### Lua Script Instance Compatibility

The project already includes the [Lua Script Instance](https://github.com/DanEngelbrecht/LuaScriptInstance/) library. If Lua Script Instance is listed in your project's dependencies, remove it to prevent duplication.

### Logger Configuration

**Setting a Predefined Logger**

To log event activities, assign a logger instance to the Event library:

```lua
local log = require("log.log")
local event = require("event.event")

event.set_logger(log.get_logger("event"))
```

**Implementing a Custom Logger**

Create a custom logger by following this interface:

```lua
local event = require("event.event")

local logger = {
    trace = function(_, message, context) end,
    debug = function(_, message, context) end,
    info = function(_, message, context) end,
    warn = function(_, message, context) end,
    error = function(_, message, context) end
}

event.set_logger(logger)
```

### Memory Allocation Tracking

**Enabling in `game.project`**

To monitor memory allocations for event callbacks, add to your `game.project`:

```ini
[event]
memory_threshold_warning = 50
```

- `memory_threshold_warning`: Threshold in kilobytes for logging warnings about memory allocations. `0` disables tracking.

**Release Build Behavior**

Memory allocation tracking is turned off in release builds, regardless of the `game.project` settings.


## API Documentation

### Setup and Initialization

To start using the Event module in your project, you first need to import it. This can be done with the following line of code:

```lua
local event = require("event.event")
```

### Core Functions

**event.create**
---
```lua
event.create(callback, callback_context)
```
Generate a new event instance. This instance can then be used to subscribe to and trigger events.

- **Parameters:**
  - `callback`: The function to be called when the event is triggered.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Return Value:** A new event instance.

- **Usage Example:**

```lua
local callback = function(self) print("clicked!") end
local on_click_event = event.create(callback, self)
```

### Event Instance Methods

Once an event instance is created, you can interact with it using the following methods:

**event:subscribe**
---
```lua
event:subscribe(callback, callback_context)
```
Subscribe a callback to the event. The callback will be invoked whenever the event is triggered.

- **Parameters:**
  - `callback`: The function to be executed when the event occurs.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Usage Example:**

```lua
on_click_event:subscribe(callback, self)
```

**event:unsubscribe**
---
```lua
event:unsubscribe(callback, callback_context)
```
Remove a previously subscribed callback from the event.

- **Parameters:**
  - `callback`: The callback function to unsubscribe.
  - `callback_context` (optional): The first parameter to be passed to the callback function.

- **Usage Example:**

```lua
on_click_event:unsubscribe(callback, self)
```

**event:is_subscribed**
---
```lua
event:is_subscribed(callback, callback_context)
```
Determine if a specific callback is currently subscribed to the event.

- **Parameters:**
  - `callback`: The callback function in question.
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
Trigger the event, causing all subscribed callbacks to be executed.

- **Parameters:** Any number of parameters to be passed to the subscribed callbacks.

- **Usage Example:**

```lua
on_click_event:trigger("arg1", "arg2")
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

This comprehensive API facilitates the creation and management of events within your projects, enhancing modularity and interaction between different components. Enjoy the power and flexibility of the Event library in your Lua projects!


## Use Cases

Read the [Use Cases](USE_CASES.md) file to see several examples of how to use the Event module in your Defold game development projects.


## License

This project is licensed under the MIT License - see the LICENSE file for details.

Used libraries:
- [Lua Script Instance](https://github.com/DanEngelbrecht/LuaScriptInstance/)


## Issues and suggestions

If you have any issues, questions or suggestions please [create an issue](https://github.com/Insality/defold-event/issues).


## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
