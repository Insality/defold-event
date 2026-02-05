# API Reference

## [Event](event_api.md)
```lua
local event = require("event.event")

event.set_logger(logger)
event.set_mode("pcall" | "xpcall" | "none")

local object = event.create([callback], [callback_context])
object(...) -- Alias for object:trigger(...)
object:trigger(...)
object:subscribe(callback, [callback_context])
object:unsubscribe(callback, [callback_context])
object:is_subscribed(callback, [callback_context])
object:is_empty()
object:clear()
```

## [Events](events_api.md)
```lua
local events = require("event.events")

events(event_id, ...) -- Alias for events.trigger(event_id, ...)
events.trigger(event_id, ...)
events.get(event_id)
events.subscribe(event_id, callback, [callback_context])
events.unsubscribe(event_id, callback, [callback_context])
events.is_subscribed(event_id, callback, [callback_context])
events.is_empty(event_id)
events.clear(event_id)
events.clear_all()
```

## [Queue](queue_api.md)
```lua
local queue = require("event.queue")

local object = queue.create([handler], [handler_context])
object:push(data, [on_handle], [context])
object:process_next(event_handler, [context])
object:process(event_handler, [context])
object:subscribe(handler, [context])
object:unsubscribe(handler, [context])
object:get_events()
object:clear_events()
object:clear_subscribers()
object:is_empty()
object:has_subscribers()
object:clear()
```

## [Queues](queues_api.md)
```lua
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
```

## [Promise](promise_api.md)
```lua
local promise = require("event.promise")

local object = promise.create([executor])
object:next([on_resolved], [on_rejected])
object:catch(on_rejected)
object:finally(on_finally)
object:is_pending()
object:is_resolved()
object:is_rejected()
object:is_finished()

-- Create specific promise instances
promise.resolved(value)
promise.rejected(reason)
promise.all(promises)
promise.race(promises)
```
