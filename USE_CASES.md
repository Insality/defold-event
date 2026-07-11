## Use Cases

This section illustrates practical examples of how to use the Event module in your Defold game development projects.

### 1. Scope Events Management

You can create a event module that allows events to be triggered from anywhere within your game. This approach requires careful management of subscriptions and unsubscriptions to prevent errors.

```lua
-- game_events.lua
local event = require("event.event")
local M = {}

M.on_game_start = event.create(),
M.on_game_over = event.create()

return M
```

**Usage:**

```lua
local game_events = require("game_events")

local function on_game_start(self)
    -- Animate GUI elements somehow
end

local function on_game_over(self)
    -- Animate GUI elements somehow
end

function init(self)
    game_events.on_game_start:subscribe(on_game_start, self)
    game_events.on_game_over:subscribe(on_game_over, self)
end

function final(self)
    game_events.on_game_start:unsubscribe(on_game_start, self)
    game_events.on_game_over:unsubscribe(on_game_over, self)
end
```


### 2. Component-specific Events

Design components with built-in events, enabling customizable behavior for instances of the component. This is particularly useful for UI elements like buttons where you want to bind specific actions to events like clicks.

```lua
-- button.lua
local event = require("event.event")

local Button = {}

function Button.create()
    local instance = {
        on_click = event.create()
    }

    -- Set up button click behavior
    return setmetatable(instance, {__index = Button})
end

return Button
```

**Usage:**

```lua
local button = require("button")

function init(self)
    local my_button = button.create()

    -- Subscribe to the button's on_click event
    my_button.on_click:subscribe(function()
        print("Button clicked!")
    end)

    -- If we destroy the scene with the button
    -- We can do not unsubscribe from the event
    -- Cause the event will be destroyed with the button

    -- Simulate a button click
    my_button.on_click:trigger()
end

```


### 3. Lua annotations

You can use annotations to document your events and make them easier to understand.

```lua
---This event is triggered when the sound button is clicked.
---@class event.on_sound_click: event
---@field trigger fun(_, is_sound_on: boolean): boolean|nil
---@field subscribe fun(_, callback: fun(is_sound_on: boolean): boolean, _): boolean

local event = require("event.event")

---@type event.on_sound_click
local on_sound_click = event.create()

-- This callback params will be checked by Lua linter
on_sound_click:subscribe(function(is_sound_on)
    print("Sound is on: ", is_sound_on)
end)

-- Trigger params will be checked by Lua linter
on_sound_click:trigger(true)
```


### 4. Using Global Events to extend single callback Defold messages

You can use global events to extend single callback Defold messages. This is useful when you need to add multiple callbacks to a single message.

```lua
function init(self)
    -- The window set_listener function allows to set only one callback, so we can use global events to extend it
    window.set_listener(function(_, event, data)
        events.trigger("window_event", event, data)
    end)

    -- Now we can subscribe to the window event at any place in the code
    events.subscribe("window_event", function(event, data)
        print("Window event: ", event, data)
    end)
end
```

### 5. Wrap GUI/GO functions to call it anywhere

You can wrap a functions to remember it's context. As an example, in GUI we can wrap `gui.set_text` function to call it from attached GO script.

> For example I use "global" table to store all wrapped functions, but you can use any other way to store and pass it.

> Instead GUI functions it can be any other your custom function, like "widget:set_color" for your UI components and you will able to call it directly with "Go to Reference" feature in your IDE.

```lua
-- GUI script
local event = require("event.event")
local global = require("global.data")

function init(self)
    global.gui_set_text = event.create(gui.set_text)
    global.gui_get_node = event.create(gui.get_node)
end
```


```lua
-- GO script
local global = require("global.data")

function init(self)
    local node = global.gui_get_node("text")
    global.gui_set_text(node, "Hello, World!")
end
```

This one can be useful when you want to make some workarounds or any things what you want will fit in your game architecture. This is not a usual "Defold" way, but it can be useful in some cases.


### 6. Get the Event subscribers count

You can get the count of the events to check if there are any subscribers or for debugging purposes.

```lua
local event = require("event.event")

local my_event = event.create()

print(#my_event) -- 0
print(my_event:is_empty()) -- true
print(my_event:subscribe(function() end)) -- true
print(#my_event) -- 1
print(my_event:is_empty()) -- false
```

### 7. Using Queues module to communicate between script and gui_script

Then you add a logic inside `init` function in `script` and `gui_script`, you can't ensure which one will be called first.

With **Queues** module you can subscribe to the event in `script` and call it in `gui_script` or vice versa. The event will be proceed after the subscriber was initialized. So in case the trigger will be called before the subscriber, it will be queued and proceed after the subscriber will be initialized.

Can be useful when you need to use `go` resource functions in `gui_script` or in other cases when you don't know is the subscriber already initialized or not but want to ensure that trigger will be proceed.

```lua
-- gui_script file
local queues = require("event.queues")

function on_get_atlas_path(self, data)
    print("Atlas path: ", data)
end

function init(self)
    queues.push("get_atlas_path", {
        texture_name = gui.get_texture(self.node),
        sender = msg.url(),
    }, self.on_get_atlas_path, self)
end
```

```lua
-- script file
local queues = require("event.queues")

local function get_atlas_path(self, request)
    local my_url = msg.url()
    my_url.fragment = nil

    local copy_url = msg.url(request.sender)
    copy_url.fragment = nil

    -- This check should works well
    if my_url ~= copy_url then
        return nil
    end

    return go.get(request.sender, "textures", { key = request.texture_name })
end

function init(self)
    queues.subscribe("get_atlas_path", get_atlas_path, self)
end

function final(self)
    queues.unsubscribe("get_atlas_path", get_atlas_path, self)
end
```

### 8. Using subscribe_once: subscribe for a single invocation

Use `subscribe_once` when you want a handler to run only one time; it is automatically unsubscribed after the first trigger. Same API exists on `event`, `events`, `queue`, and `queues`.

**Event / global events:**

```lua
local event = require("event.event")
local events = require("event.events")

-- Local event: callback runs once, then is removed
local on_ready = event.create()
on_ready:subscribe_once(function()
    print("Ready! This will not run again.")
end)
on_ready:trigger() -- prints
on_ready:trigger() -- does nothing

-- Global event
events.subscribe_once("game_over", function(self)
    self:show_game_over_screen()
end, self)
```


### 9. Wrap an asynchronous callback with a promise

A promise can be passed directly as a completion callback. Calling the promise resolves it, so this is enough for an asynchronous operation that only reports completion:

```lua
local promise = require("event.promise")

local task = promise.create()

gui.animate(self.icon, "position.x", 300, gui.EASING_OUTSINE, 0.3, 0, task)

task:next(function()
	print("Animation finished")
end)
```

This pattern also works with other APIs that invoke a callback once. Use the executor form below when the operation can fail or needs cancellation cleanup.


### 10. Promises for animations and other asynchronous work

A promise wraps one asynchronous operation. Resolve it when the operation completes, reject it when the operation fails, and subscribe to `on_cancel` to stop any work that is still running.

This small module turns a GUI animation into a cancellable promise:

```lua
-- move_animation.lua
local promise = require("event.promise")

local M = {}


function M.start(node, position, duration)
	-- You can pass an context as a first argument for the executor function
	return promise.create(M._animate, {
		node = node,
		position = position,
		duration = duration,
	})
end


function M:_animate(resolve, reject, on_cancel)
	on_cancel:subscribe(M._cancel, self)

	gui.animate(self.node, "position", self.position, gui.EASING_OUTSINE, self.duration)
	-- Context fields are also available to the cancellation callback.
	self._timer_id = timer.delay(self.duration, false, resolve)
end


function M:_cancel()
	gui.cancel_animation(self.node, "position")
	timer.cancel(self._timer_id)
end


return M
```

#### Build a promise chain

Use `next` to run steps in order. A handler may return a plain value for the next handler, or another promise. When it returns a promise, the chain waits for that promise to finish.

```lua
local promise = require("event.promise")
local move_animation = require("move_animation")

local animation = move_animation.start(self.icon, vmath.vector3(300, 200, 0), 0.3)

local chain = animation
	:next(function()
		return move_animation.start(self.icon, vmath.vector3(300, 240, 0), 0.15)
	end)
	:next(function()
		return move_animation.start(self.icon, vmath.vector3(300, 200, 0), 0.15)
	end)

chain:next(function()
	print("Animation finished")
end)

chain:catch(function(reason)
	if not promise.is_cancelled_reason(reason) then
		print("Animation failed:", reason)
	end
end)

-- Cancelling any promise marks the shared chain as cancelled.
-- The currently running GUI animation is stopped by its on_cancel handler.
animation:cancel()
```

Use `catch` for failures and `finally` for cleanup that must run after resolve, reject, or cancellation. If you still have a chain reference, use `chain:is_cancelled()`. If a callback only has the rejection reason, use `promise.is_cancelled_reason(reason)`.

#### Queue animations with append

`append` is useful when an object receives animation requests over time. It adds each task to the current tail, so only one queued animation runs at a time.

```lua
local promise = require("event.promise")
local move_animation = require("move_animation")

function init(self)
	self.animation_pipeline = promise.resolved()
end


function on_message(self, message_id)
	if message_id == hash("bounce") then
		self.animation_pipeline:append(function()
			return move_animation.start(self.icon, vmath.vector3(300, 240, 0), 0.1)
		end)
		self.animation_pipeline:append(function()
			return move_animation.start(self.icon, vmath.vector3(300, 200, 0), 0.1)
		end)
	end
end


function final(self)
	self.animation_pipeline:cancel()
end
```

Pass a function that creates and returns the animation promise. Promise executors run immediately, so an already-created promise may start its animation before its turn:

```lua
-- Starts only when all earlier tasks have finished.
pipeline:append(function()
	return move_animation.start(node, target, 0.2)
end)

-- The move starts now; append only makes the pipeline wait for it.
pipeline:append(move_animation.start(node, target, 0.2))
```

Use `pipeline:tail()` to observe all work currently queued:

```lua
pipeline:tail():next(function()
	print("Everything currently queued has finished")
end)
```

#### How cancellation propagates

- **Single promise:** `cancel()` rejects a pending promise and triggers its `on_cancel` handlers once. Use those handlers to cancel timers, HTTP requests, animations, or other external work.
- **Promise chain:** Promises created by `next`, `catch`, and `finally` share cancellation. Cancelling the head, middle, or tail stops pending work and skips later success handlers. Rejection handlers and `finally` still run, so use `promise.is_cancelled_reason(reason)` when no chain reference is available.
- **Returned promise:** When a handler returns another promise, it joins the chain. Cancelling the chain also triggers that promise's cleanup.
- **Append pipeline:** Cancelling the pipeline or its tail stops the active task and prevents queued tasks from starting. A cancelled pipeline cannot be reused; create a new `promise.resolved()` pipeline.
- **`promise.all`:** Cancelling the combined promise cancels every pending input promise.
- **`promise.race`:** Cancelling the race while it is pending cancels every pending input promise. A normally resolved race does not automatically cancel the other inputs.
- **Already finished promise:** Its resolved or rejected state does not change, but cancelling it still cancels pending descendants that share its chain.

Cancellation is safe to call more than once. Normal resolve or reject does not invoke `on_cancel`.

#### Callback order during cancellation

Cancellation is handled as a rejection with an internal reason. For a pending promise chain, callbacks run synchronously in this order:

1. Every `on_cancel` subscriber runs once. This is where the active asynchronous operation should be stopped.
2. The promise is rejected with the cancellation reason.
3. Rejection handlers registered with `next(nil, on_rejected)` or `catch` run in chain order.
4. `finally` handlers run as the rejection continues through the chain.

Success handlers registered with `next(on_resolved)` do not run.

```lua
local task = promise.create(function(resolve, reject, on_cancel)
	on_cancel:subscribe(function()
		print("1. Stop the asynchronous operation")
	end)
end)

local chain = task
	:next(function()
		print("This is not called")
	end)
	:catch(function(reason)
		if promise.is_cancelled_reason(reason) then
			print("2. Handle cancellation")
			return
		end
		print("Handle failure:", reason)
	end)
	:finally(function()
		print("3. Final cleanup")
	end)

task:cancel()
```

Additional cases:

- **Cancel a pending chain:** Cleanup runs first, then `catch` and `finally`. Later success steps are skipped.
- **Cancel an active append pipeline:** The active task's cleanup runs, queued task functions are not called, then rejection handlers attached to the pipeline tail run.
- **Cancel `promise.all` or `promise.race`:** Pending input promises are cancelled synchronously. Their cleanup and rejection handlers run before cancellation finishes.
- **Cancel an already finished promise:** Its state and value do not change, and handlers that already ran are not called again. Its `on_cancel` cleanup still runs, followed by rejection handlers of any pending descendants.
- **Call `cancel()` again:** Nothing runs again; cancellation is idempotent.
