# Defer API Reference

The Defer module provides a queuing mechanism for events. Unlike regular events which are immediately processed, deferred events are stored in a queue until they are explicitly handled by a subscriber. This is useful for events that need to persist until they can be properly handled.

To start using the **Defer** module in your project, you first need to import it:

```lua
local defer = require("event.defer")
```

## API Reference

**defer.push**
---
```lua
defer.push(event_id, data, [on_handle], [context])
```
Push a new event to the deferred queue. The event will exist until it's handled by a subscriber. If there are already subscribers for this event_id, they will be called immediately.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.
  - `data`: The data associated with the event.
  - `on_handle` (optional): Callback function to be called when the event is handled.
  - `context` (optional): The context to be passed to the on_handle callback.

- **Usage Example:**

```lua
defer.push("new_achievement", { id = "first_win", name = "First Victory" }, function(self)
    print("Achievement handled by the UI!")
end, self)
```

**defer.subscribe**
---
```lua
defer.subscribe(event_id, handler, [context])
```
Subscribe a handler to a specific event type. When an event of this type is pushed, the handler will be called. If there are already events in the queue for this event_id, they will be processed immediately.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.
  - `handler`: The handler function to be called when an event is pushed. Return a non-nil value from the handler to mark the event as handled.
  - `context` (optional): The context to be passed as the first parameter to the handler function.

- **Return Value:** `true` if handler was subscribed successfully, `false` otherwise.

- **Usage Example:**

```lua
local function achievement_handler(self, achievement_data)
    -- Display achievement UI
    print("Displaying achievement:", achievement_data.name)
    return true -- Mark as handled
end

function init(self)
    defer.subscribe("new_achievement", achievement_handler, self)
end
```

**defer.unsubscribe**
---
```lua
defer.unsubscribe(event_id, handler, [context])
```
Unsubscribe a handler from a specific event type.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.
  - `handler`: The handler function to unsubscribe.
  - `context` (optional): The context that was passed when subscribing.

- **Return Value:** `true` if handler was unsubscribed successfully, `false` otherwise.

- **Usage Example:**

```lua
function final(self)
    defer.unsubscribe("new_achievement", achievement_handler, self)
end
```

**defer.process**
---
```lua
defer.process(event_id, handler, [context])
```
Process all events of a specific type immediately with the provided handler. Subscribers will not be called in this function. This is useful for manually handling events without affecting subscribed handlers.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.
  - `handler`: The handler function to process the events. Return a non-nil value from the handler to mark the event as handled.
  - `context` (optional): The context to be passed to the handler.

- **Usage Example:**

```lua
-- Process all new_achievement events with a specific handler
local function special_handler(achievement_data)
    -- Special handling logic
    return true -- Mark as handled
end

defer.process("new_achievement", special_handler)
```

**defer.get_events**
---
```lua
defer.get_events(event_id)
```
Get all pending events for a specific event type.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.

- **Return Value:** A table of pending events for the specified event_id.

- **Usage Example:**

```lua
local pending_achievements = defer.get_events("new_achievement")
print("Pending achievements:", #pending_achievements)
```

**defer.clear**
---
```lua
defer.clear(event_id)
```
Clear all pending events for a specific event type.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.

- **Usage Example:**

```lua
-- Clear all new_achievement events
defer.clear("new_achievement")
```

**defer.clear_subscribers**
---
```lua
defer.clear_subscribers(event_id)
```
Clear all subscribers for a specific event type.

- **Parameters:**
  - `event_id`: The unique identifier for the event type.

- **Usage Example:**

```lua
-- Clear all subscribers for new_achievement events
defer.clear_subscribers("new_achievement")
```

**defer.clear_all**
---
```lua
defer.clear_all()
```
Clear all pending events and handlers for all event types.

- **Usage Example:**

```lua
-- Clear everything - all events and all subscribers
defer.clear_all()
```
