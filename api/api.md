# API Reference

## [Event](event_api.md)
```lua
local event = require("event.event")

event.create([callback], [callback_context])
event.is_event([value])
event.set_logger([logger_instance])
event.set_mode(mode)

event:subscribe(callback, [callback_context])
event:subscribe_once(callback, [callback_context])
event:unsubscribe(callback, [callback_context])
event:is_subscribed(callback, [callback_context])
event:trigger(...)
event:is_empty()
event:clear()
```

## [Events](events_api.md)
```lua
local events = require("event.events")

events.trigger(event_id, ...)
events.clear(event_id)
events.clear_all()
events.subscribe(event_id, callback, [callback_context])
events.subscribe_once(event_id, callback, [callback_context])
events.unsubscribe(event_id, callback, [callback_context])
events.is_subscribed(event_id, callback, [callback_context])
events.is_empty(event_id)
events.get(event_id)
```

## [Queue](queue_api.md)
```lua
local queue = require("event.queue")

queue.create([handler], [handler_context])
queue.is_queue([value])

queue:push([data], [on_handle], [context])
queue:subscribe(handler, [context])
queue:subscribe_once(handler, [context])
queue:unsubscribe(handler, [context])
queue:is_subscribed(handler, [context])
queue:process(event_handler, [context])
queue:process_next([event_handler], [context])
queue:get_events()
queue:clear_events()
queue:clear_subscribers()
queue:is_empty()
queue:has_subscribers()
queue:clear()
```

## [Queues](queues_api.md)
```lua
local queues = require("event.queues")

queues.push(queue_id, [data], [on_handle], [context])
queues.subscribe(queue_id, handler, [context])
queues.subscribe_once(queue_id, handler, [context])
queues.unsubscribe(queue_id, handler, [context])
queues.is_subscribed(queue_id, handler, [context])
queues.process(queue_id, event_handler, [context])
queues.process_next(queue_id, event_handler, [context])
queues.get_events(queue_id)
queues.clear_events(queue_id)
queues.clear_subscribers(queue_id)
queues.clear(queue_id)
queues.clear_all()
queues.is_empty(queue_id)
queues.has_subscribers(queue_id)
```

## [Promise](promise_api.md)
```lua
local promise = require("event.promise")

promise.create([executor], [context])
promise.resolved([value])
promise.rejected([reason])
promise.all(promises)
promise.race(promises)
promise.is_promise([value])

promise:next([on_resolved], [on_rejected], [context])
promise:catch(on_rejected, [context])
promise:finally(on_finally, [context])
promise:is_pending()
promise:is_resolved()
promise:is_rejected()
promise:is_finished()
promise:is_cancelled()
promise:resolve([value])
promise:reject([reason])
promise:cancel()
promise:append([task])
promise:tail()
promise:reset()

promise.state
promise.value
promise.cancellation
```
