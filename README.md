![](media/logo.png)

[![GitHub release (latest by date)](https://img.shields.io/github/v/tag/insality/defold-event?style=for-the-badge&label=Release)](https://github.com/Insality/defold-event/tags)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/insality/defold-event/ci_workflow.yml?style=for-the-badge)](https://github.com/Insality/defold-event/actions)
[![codecov](https://img.shields.io/codecov/c/github/Insality/defold-event?style=for-the-badge)](https://codecov.io/gh/Insality/defold-event)

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)


# Event

**Event** is a comprehensive event-driven toolkit for the [Defold](https://defold.com/) game engine that enables decoupled communication between different parts of your code through a publish-subscribe pattern. It provides events, queues, promises, and global messaging systems to create clean, maintainable game architectures with efficient asynchronous operations.


## Features

- **Event Management**: Create, subscribe, unsubscribe, and trigger events.
- **Cross-Context**: You can subscribe to events from different scripts.
- **Callback Management**: Attach callbacks to events with optional data.
- **Global Events**: Create and subscribe global events that can be triggered from anywhere in your game.
- **Queue**: Create queue instances to queue events until they are handled by subscribers. Unlike regular events which are immediately processed, queued events are stored in a queue until they are explicitly handled.
- **Global Queues**: Create and subscribe global queue instances that can be accessed from anywhere in your game.
- **Promise**: A promise implementation built on top of the event system for asynchronous operations and chaining.
- **Logging**: Set a logger to log event activities.


## Setup

### [Dependency](https://www.defold.com/manuals/libraries/)

Open your `game.project` file and add the following line to the dependencies field under the project section:

**[Defold Event](https://github.com/Insality/defold-event/archive/refs/tags/12.zip)**

```
https://github.com/Insality/defold-event/archive/refs/tags/12.zip
```

### Library Size

> **Note:** The library size is calculated based on the build report per platform
> Events, Queues, and Promise modules will be included in the build only if you use them.

| Platform         | Event Size   | Events Size   | Queue Size   | Queues Size  | Promise Size |
| ---------------- | ------------ | ------------- | ------------ | ------------ | ------------ |
| HTML5            | **1.68 KB**  | **0.41 KB**   | **1.11 KB**  | **0.49 KB**  | **1.74 KB**  |
| Desktop / Mobile | **2.88 KB**  | **0.71 KB**   | **2.03 KB**  | **0.97 KB**  | **3.22 KB**  |


## Event Mode

Event module can work in 3 modes:

| Mode | Default | Cross-Context | Detailed Tracebacks | Notes |
| --- | --- | --- | --- | --- |
| `pcall` | ✅ | ✅ | ❌ | The `pcall` function is used to handle errors within event callback. |
| `xpcall` | ❌ | ✅ | ✅ | The `xpcall` function is used to handle errors within event callback. |
| `none` | ❌ | ❌ | ✅ | The error will be thrown as usual Lua error. No cross GO, GUI function calls

You can set the Event Mode with code:

```lua
event.set_mode("pcall")
event.set_mode("xpcall")
event.set_mode("none")
```

The context changing is disabled in case of `none` mode. That means the event callback will be executed in the same context as the event trigger, which can lead to unexpected behavior. With `pcall` (default) the subscribed callback will be executed in the same context where created. By context I mean the GO scripts and GUI scripts in Defold.

### Using `pcall` for cross-context function calls

The `pcall` function is **enabled** by default. If you want to disable it to use `none` mode, you can set the `use_pcall` option to `0` in the `game.project` file:

```ini
[event]
use_pcall = 0
```


### Using `xpcall` to get detailed tracebacks

You can use `xpcall` to get detailed tracebacks in case of an error in the event callback. In case of just pcall, you will get a line with `event.trigger` and traceback ended in event module. To get a detailed traceback to help with debug, you can use `use_xpcall`:

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
event.set_mode("pcall" | "xpcall" | "none")

local event_instance = event.create([callback], [callback_context])
event_instance:subscribe(callback, [callback_context])
event_instance:unsubscribe(callback, [callback_context])
event_instance:is_subscribed(callback, [callback_context])
event_instance:trigger(...)
event_instance:is_empty()
event_instance:clear()

local events = require("event.events")
events.subscribe(event_id, callback, [callback_context])
events.unsubscribe(event_id, callback, [callback_context])
events.is_subscribed(event_id, callback, [callback_context])
events.trigger(event_id, ...)
events.is_empty(event_id)
events.clear(event_id)
events.clear_all()

local queue = require("event.queue")
local queue_instance = queue.create([handler], [handler_context])
queue_instance:push(data, [on_handle], [context])
queue_instance:subscribe(handler, [context])
queue_instance:unsubscribe(handler, [context])
queue_instance:process(event_handler, [context])
queue_instance:get_events()
queue_instance:clear_events()
queue_instance:clear_subscribers()
queue_instance:is_empty()
queue_instance:has_subscribers()
queue_instance:clear()

local queues = require("event.queues")
queues.push(queue_id, data, [on_handle], [context])
queues.subscribe(queue_id, handler, [context])
queues.unsubscribe(queue_id, handler, [context])
queues.process(queue_id, event_handler, [context])
queues.get_events(queue_id)
queues.clear_events(queue_id)
queues.clear_subscribers(queue_id)
queues.is_empty(queue_id)
queues.has_subscribers(queue_id)
queues.clear(queue_id)
queues.clear_all()

local promise = require("event.promise")
local promise_instance = promise.create([executor])
promise_instance:next([on_resolved], [on_rejected])
promise_instance:catch(on_rejected)
promise_instance:finally(on_finally)
promise_instance:is_pending()
promise_instance:is_resolved()
promise_instance:is_rejected()
promise_instance:is_finished()

-- Create specific promise instances
promise.resolved(value)
promise.rejected(reason)
promise.all(promises)
promise.race(promises)
```

For detailed API documentation, please refer to:
- [Event API Reference](api/event_api.md)
- [Global Events API Reference](api/events_api.md)
- [Queue API Reference](api/queue_api.md)
- [Global Queues API Reference](api/queues_api.md)
- [Promise API Reference](api/promise_api.md)

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

### **V12**
	- **MIGRATION**: Replace `require("event.defer")` with `require("event.queues")` in case of using `defer` module

	- **BREAKING CHANGE**: Refactored defer system to be instance-based like event system. `defer.lua` now creates defer instances with `defer.create()` instead of global event_id system
	- **BREAKING CHANGE**: Renamed `defer` module to `queues` for better clarity
	- Removed memory allocation tracking feature
	- Added `queues.lua` for global queues operations (renamed from defer.lua functionality)
	- Added **Promise** module on top of event module
	- Fixed queue event processing order from LIFO to FIFO (events now processed in correct queue order)
	- Added no_context_change mode to disable context changing in event callback and using `pcall` by default
	- Added `event.set_mode` function to set the event mode

</details>

## ❤️ Support project ❤️

Your donation helps me stay engaged in creating valuable projects for **Defold**. If you appreciate what I'm doing, please consider supporting me!

[![Github-sponsors](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#EA4AAA)](https://github.com/sponsors/insality) [![Ko-Fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/insality) [![BuyMeACoffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/insality)
