![](media/logo.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/defold-event?style=for-the-badge&label=Release)](https://github.com/Insality/defold-event/tags)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/insality/defold-event/ci_workflow.yml?style=for-the-badge)](https://github.com/Insality/defold-event/actions)
[![codecov](https://img.shields.io/codecov/c/github/Insality/defold-event?style=for-the-badge)](https://codecov.io/gh/Insality/defold-event)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


# Event

**Event** - is a single file Lua module for the [Defold](https://defold.com/) game engine. It provides a simple and efficient way to manage events and callbacks in your game.


## Features

- **Event Management**: Create, subscribe, unsubscribe, and trigger events.
- **Cross-Context**: You can subscribe to events from different scripts.
- **Callback Management**: Attach callbacks to events with optional data.
- **Global Events**: Create and subscribe global events that can be triggered from anywhere in your game.
- **Logging**: Set a logger to log event activities.
- **Memory Allocations Tracker**: Detects if an event callback causes a huge memory allocations.


## Setup

### [Dependency](https://www.defold.com/manuals/libraries/)

Open your `game.project` file and add the following line to the dependencies field under the project section:

**[Defold Event](https://github.com/Insality/defold-event/archive/refs/tags/11.zip)**

```
https://github.com/Insality/defold-event/archive/refs/tags/11.zip
```

### Library Size

> **Note:** The library size is calculated based on the build report per platform
> Events and Defer module will be included in the build only if you use them.

| Platform         | Event Size   | Events Size   | Defer Size   |
| ---------------- | ------------ | ------------- | ------------ |
| HTML5            | **1.85 KB**  | **0.42 KB**   | **1.07 KB**  |
| Desktop / Mobile | **3.14 KB**  | **0.71 KB**   | **1.93 KB**  |


### Memory Allocation Tracking

**Enabling in `game.project`**

To monitor memory allocations for event callbacks, add to your `game.project`:

```ini
[event]
memory_threshold_warning = 50
```

- `memory_threshold_warning`: Threshold in kilobytes for logging warnings about memory allocations. `0` disables tracking.

The event memory tracking is not 100% accurate and is used to check unexpected huge leaks in the event callbacks. The memory tracking applied additional memory allocations for tracking purposes.

Memory allocation tracking is turned off in release builds, regardless of the `game.project` settings.


### Using `xpcall` to get detailed tracebacks

You can use `xpcall` to get detailed tracebacks in case of an error in the event callback. Usually, in case of an error, you will get a line with `event.trigger` and traceback ended in event module. To get a detailed traceback to help with debug, you can use `use_xpcall`:

```ini
[event]
use_xpcall = 1
```

In this case, you will get a detailed traceback with the exact line of the error in the event callback. But the drawback of it is memory allocations per `event:trigger` call. Should be used only for debugging purposes.


## API Reference

### Quick API Reference

```lua
local event = require("event.event")
event.set_logger(logger)
event.set_memory_threshold(threshold)

local event_instance = event.create([callback], [callback_context])
event_instance:subscribe(callback, [callback_context])
event_instance:unsubscribe(callback, [callback_context])
event_instance:is_subscribed(callback, [callback_context])
event_instance:trigger(...)
event_instance:is_empty()
event_instance:clear()

local events = require("event.events")
events.subscribe(name, callback, [callback_context])
events.unsubscribe(name, callback, [callback_context])
events.is_subscribed(name, callback, [callback_context])
events.trigger(name, ...)
events.is_empty(name)
events.clear(name)
events.clear_all()

local defer = require("event.defer")
defer.push(event_id, data, [on_handle], [context])
defer.subscribe(event_id, handler, [context])
defer.unsubscribe(event_id, handler, [context])
defer.process(event_id, handler, [context])
defer.get_events(event_id)
defer.clear_events(event_id)
defer.clear_subscribers(event_id)
defer.clear_all()
```

For detailed API documentation, please refer to:
- [Event API Reference](api/event_api.md)
- [Global Events API Reference](api/events_api.md)
- [Defer API Reference](api/defer_api.md)

## Use Cases

Read the [Use Cases](USE_CASES.md) file to see several examples of how to use the Event module in your Defold game development projects.


## License

This project is licensed under the MIT License - see the LICENSE file for details.

Used libraries:
- [Lua Script Instance](https://github.com/DanEngelbrecht/LuaScriptInstance/)


## Issues and suggestions

If you have any issues, questions or suggestions please [create an issue](https://github.com/Insality/defold-event/issues).


## 👏 Contributors

<a href="https://github.com/Insality/defold-event/graphs/contributors">
  <img src="https://contributors-img.web.app/image?repo=insality/defold-event"/>
</a>


## Changelog

<details>

### **V1**
	- Initial release

### **V2**
	- Add global events module
	- The `event:subscribe` and `event:unsubscribe` now return boolean value of success

### **V3**
	- Event Trigger now returns value of last executed callback
	- Add `events.is_empty(name)` function
	- Add tests for Event and Global Events modules


### **V4**
	- Rename `lua_script_instance` to `event_context_manager` to escape conflicts with `lua_script_instance` library
	- Fix validate context in `event_context_manager.set`
	- Better error messages in case of invalid context
	- Refactor `event_context_manager`
	- Add tests for event_context_manager
	- Add `event.set_memory_threshold` function. Works only in debug builds.

### **V5**
	- The `event:trigger(...)` can be called as `event(...)` via `__call` metamethod
	- Add default pprint logger. Remove or replace it with `event.set_logger()`
	- Add tests for context changing

### **V6**
	- Optimize memory allocations per event instance
	- Localize functions in the event module for better performance

### **V7**
	- Optimize memory allocations per event instance
	- Default logger now empty except for errors

### **V8**
	- Optimize memory allocations per subscription (~35% less)

### **V9**
	- Better error tracebacks in case of error in subscription callback
	- Update annotations

### **V10**
	- The `event:unsubscribe` now removes all subscriptions with the same function if `callback_context` is not provided
	- You can use events instead callbacks in `event:subscribe` and `event:unsubscribe`. The subcribed event will be triggered by the parent event trigger.
	- Update docs and API reference

### **V11**
	- Introduced behavior in the `defer` module. The Defer module provides a queuing mechanism for events. Unlike regular events which are immediately processed, deferred events are stored in a queue until they are explicitly handled by a subscriber. This is useful for events that need to persist until they can be properly handled.
	- Add `use_xpcall` option to get detailed tracebacks in case of an error in the event callback.
	- Moved detailed API documentation to separate files
	- Remove annotations files. Now all annotations directly in the code.
</details>

## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
