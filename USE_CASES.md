# Use Cases

This guide walks through practical examples of the Event library, ordered from basic to advanced. Start with the **Event** section — everything else in the library is built on top of it. Then move to **Global Events**, **Queues** and **Promise** when you need them.

| Module | When to use it |
| ------ | -------------- |
| [Event](#event) | You want a callback list on an object: subscribe, trigger, unsubscribe. |
| [Global Events](#global-events) | You want to trigger events from anywhere using a string id. |
| [Queues](#queues) | Events must not be lost: handle them whenever a subscriber appears, or store them and process on your own schedule. |
| [Promise](#promise) | You have asynchronous operations (animations, HTTP, timers) and want to chain, combine or cancel them. |

## Table of Contents

- [Event](#event)
  - [Add events to your components](#add-events-to-your-components)
  - [Shared events module](#shared-events-module)
  - [Subscribe for a single invocation](#subscribe-for-a-single-invocation)
  - [Check the subscribers count](#check-the-subscribers-count)
  - [Type-safe events with annotations](#type-safe-events-with-annotations)
  - [Call GUI functions from a GO script](#call-gui-functions-from-a-go-script)
- [Global Events](#global-events)
  - [Extend single-callback Defold listeners](#extend-single-callback-defold-listeners)
- [Queues](#queues)
  - [Communicate between script and gui_script](#communicate-between-script-and-gui_script)
  - [Process events on your own schedule](#process-events-on-your-own-schedule)
  - [Show popups one at a time](#show-popups-one-at-a-time)
  - [Use a queue as a pending storage](#use-a-queue-as-a-pending-storage)
- [Promise](#promise)
  - [Use a promise as a completion callback](#use-a-promise-as-a-completion-callback)
  - [Wrap an asynchronous operation](#wrap-an-asynchronous-operation)
  - [Chain steps with next, catch and finally](#chain-steps-with-next-catch-and-finally)
  - [Run operations in parallel with all and race](#run-operations-in-parallel-with-all-and-race)
  - [Make an operation cancellable](#make-an-operation-cancellable)
  - [Queue animations with append](#queue-animations-with-append)
  - [Cancellation reference](#cancellation-reference)


## Event

### Add events to your components

Give your components their own events so users of the component can react to what happens inside it. This is the most common pattern: for UI elements like buttons, for game entities, for anything with a lifecycle.

```lua
-- button.lua
local event = require("event.event")

local Button = {}


function Button.create()
	local instance = {
		on_click = event.create()
	}

	-- Set up button click behavior
	return setmetatable(instance, { __index = Button })
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

	-- Simulate a button click
	my_button.on_click:trigger()
end
```

When the component is destroyed together with its events, you don't need to unsubscribe — the subscriptions die with the event object.


### Shared events module

Create a Lua module with events that can be triggered from anywhere in your game. Since the module (and its events) outlives your scripts, remember to unsubscribe in `final` to avoid dangling subscriptions.

```lua
-- game_events.lua
local event = require("event.event")

local M = {}

M.on_game_start = event.create()
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

The second argument to `subscribe` is a context: it is passed as the first argument to the callback. Usually it is `self`, so the callback runs like a regular script function.


### Subscribe for a single invocation

Use `subscribe_once` when a handler should run only one time; it is automatically unsubscribed after the first trigger. The same API exists on `event`, `events`, `queue` and `queues`.

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


### Check the subscribers count

You can inspect an event to check if there are any subscribers, or for debugging purposes.

```lua
local event = require("event.event")

local my_event = event.create()

print(#my_event) -- 0
print(my_event:is_empty()) -- true
print(my_event:subscribe(function() end)) -- true
print(#my_event) -- 1
print(my_event:is_empty()) -- false
```


### Type-safe events with annotations

You can use Lua annotations to document your events, get autocompletion and let the linter check trigger and callback parameters.

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


### Call GUI functions from a GO script

An event created with a callback remembers the script context it was created in. This means you can wrap GUI functions in events and safely call them from a GO script — the library switches to the GUI context for the call.

> For example I use "global" table to store all wrapped functions, but you can use any other way to store and pass it.

> Instead of GUI functions it can be any of your custom functions, like `widget:set_color` for your UI components, and you will be able to navigate to it directly with the "Go to Reference" feature in your IDE.

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

This can be useful for workarounds or anything that fits your game architecture. This is not a usual "Defold" way, but it can be handy in some cases.


## Global Events

Global events are regular events stored behind string identifiers, so any part of the code can trigger or subscribe to them without sharing a module.

### Extend single-callback Defold listeners

Several Defold APIs accept only a single callback (`window.set_listener`, `sys.set_error_handler`, etc.). Forward that callback into a global event and any number of subscribers can react to it.

```lua
local events = require("event.events")

function init(self)
	-- The window.set_listener function allows to set only one callback,
	-- so we use a global event to extend it
	window.set_listener(function(_, event, data)
		events.trigger("window_event", event, data)
	end)

	-- Now we can subscribe to the window event at any place in the code
	events.subscribe("window_event", function(event, data)
		print("Window event: ", event, data)
	end)
end
```


## Queues

A regular event trigger is lost if nobody is subscribed yet. A **queue** keeps pushed events until they are handled. There are two ways to consume a queue:

- **Push style** — `subscribe` a handler; it is called for all pending events and for every future push.
- **Pull style** — no subscribers at all; call `process` or `process_next` whenever *you* decide it is time to consume events.

In both styles the handler must return a non-nil value to mark the event as handled and remove it from the queue. Returning nil keeps the event stored — this is what makes queues usable as a storage for "things to do later".

### Communicate between script and gui_script

When you put logic inside `init` of a `script` and a `gui_script`, you can't be sure which one runs first. With queues the request waits until the handler appears.

```lua
-- my_gui.gui_script
local queues = require("event.queues")

local function on_player_profile(self, profile)
	gui.set_text(gui.get_node("name"), profile.name)
end


function init(self)
	-- Safe to push even if the script below is not initialized yet:
	-- the request waits in the queue until a subscriber handles it
	queues.push("get_player_profile", { id = 1 }, on_player_profile, self)
end
```

```lua
-- my_go.script
local queues = require("event.queues")

local function get_player_profile(self, request)
	-- A non-nil return value marks the event as handled and removes it
	-- from the queue. The value is delivered to the on_handle callback of the push.
	return self.profiles[request.id]
end


function init(self)
	self.profiles = { { name = "Insality" } }
	queues.subscribe("get_player_profile", get_player_profile, self)
end


function final(self)
	queues.unsubscribe("get_player_profile", get_player_profile, self)
end
```

This is also useful when a `gui_script` needs data only a `script` can access, for example `go.get` resource properties like texture paths.


### Process events on your own schedule

A queue does not require subscribers. Push events from anywhere and consume them later with `process` — for example once per frame in `update`. This batches the work and decouples producers from the consumer completely.

```lua
-- Anywhere in the gameplay code: just push, nobody has to be subscribed
local queues = require("event.queues")

queues.push("damage_numbers", { amount = 10, position = go.get_position() })
```

```lua
-- damage_numbers.gui_script
local queues = require("event.queues")

local function spawn_damage_number(self, data)
	-- Spawn a floating text node at data.position
	return true -- Non-nil result: the event is handled and removed
end


function update(self, dt)
	-- Consume everything accumulated since the last frame
	queues.process("damage_numbers", spawn_damage_number, self)
end
```


### Show popups one at a time

`process_next` handles exactly one event from the head of the queue. This makes it easy to build "one at a time" flows: popups, dialog lines, tutorial steps. New requests pile up in the queue and are pulled only when the current one is finished.

```lua
-- popup_manager.lua
local queue = require("event.queue")

local M = {}

M.popups = queue.create()
M.is_showing = false


function M.show(popup_id, params)
	M.popups:push({ popup_id = popup_id, params = params })
	M._show_next()
end


---Call this when the current popup is closed
function M.on_popup_closed()
	M.is_showing = false
	M._show_next()
end


function M._show_next()
	if M.is_showing then
		return
	end

	M.popups:process_next(M._open_popup)
end


function M._open_popup(data)
	M.is_showing = true
	msg.post("main:/popups", "show_popup", data)
	return true -- Handled: remove the popup request from the queue
end


return M
```


### Use a queue as a pending storage

Since unhandled events stay in the queue, a queue works as a storage of "things to do later". Return nil from the handler to keep an event for the next attempt. A typical example is an analytics batcher that survives failed sends:

```lua
-- analytics.lua
local queue = require("event.queue")

local M = {}

M.pending = queue.create()


function M.track(event_name, params)
	M.pending:push({ name = event_name, params = params })
end


function M.flush()
	-- Try to send everything; failed events stay queued for the next flush
	M.pending:process(M._send)
end


function M._send(event_data)
	local is_sent = send_to_server(event_data)
	-- Non-nil removes the event, nil keeps it in the queue
	return is_sent or nil
end


return M
```

You can also inspect the stored events without consuming them, for example to persist them between sessions:

```lua
-- Save unsent events before the game closes
local unsent = {}
for _, event_data in ipairs(M.pending:get_events()) do
	table.insert(unsent, event_data.data)
end
sys.save(save_path, { analytics = unsent })
```

Related functions: `is_empty()` to check if anything is stored, `clear_events()` to drop the storage, `has_subscribers()` to check for push-style consumers.


## Promise

A promise represents a single asynchronous operation. It starts **pending**, then either **resolves** with a value or **rejects** with a reason — exactly once. You attach handlers with `next`, `catch` and `finally`, and you can cancel pending work with `cancel`.

The examples below build on each other, from the simplest form to full pipelines.

### Use a promise as a completion callback

Calling a promise resolves it. So a pending promise can be passed directly to any API that expects a one-shot completion callback:

```lua
local promise = require("event.promise")

function init(self)
	local task = promise.create()

	gui.animate(gui.get_node("icon"), "position.x", 300, gui.EASING_OUTSINE, 0.3, 0, task)

	task:next(function()
		print("Animation finished")
	end)
end
```

This is enough for operations that only report completion. Use the executor form below when the operation can fail or needs cancellation cleanup.


### Wrap an asynchronous operation

`promise.create(executor)` calls the executor immediately with `resolve`, `reject` and an `on_cancel` event. Call `resolve(value)` on success and `reject(reason)` on failure:

```lua
local promise = require("event.promise")

local function load_config(url)
	return promise.create(function(resolve, reject)
		http.request(url, "GET", function(_, _, response)
			if response.status == 200 then
				resolve(json.decode(response.response))
			else
				reject("Request failed with status " .. response.status)
			end
		end)
	end)
end
```

Subscribe to `on_cancel` when there is work to stop if the promise is cancelled:

```lua
local function delay(seconds)
	return promise.create(function(resolve, reject, on_cancel)
		local handle = timer.delay(seconds, false, resolve)
		on_cancel:subscribe(timer.cancel, handle)
	end)
end
```


### Chain steps with next, catch and finally

`next` returns a new promise. A handler may return a plain value for the next handler, or another promise — then the chain waits for that promise to finish.

```lua
load_config("https://example.com/config.json")
	:next(function(config)
		-- Returns another promise, the chain waits for it
		return load_level(config.start_level)
	end)
	:next(function(level)
		print("Level ready:", level.name)
	end)
	:catch(function(reason)
		-- Handles a rejection from any earlier step
		print("Loading failed:", reason)
	end)
	:finally(function()
		-- Runs after resolve, reject or cancellation
		hide_loading_spinner()
	end)
```

Errors thrown inside handlers reject the chain as well, so one `catch` at the end covers the whole sequence.


### Run operations in parallel with all and race

`promise.all` resolves when every promise resolves, with an array of results. If any promise rejects, it rejects with that reason:

```lua
local promise = require("event.promise")

promise.all({
	load_config("https://example.com/config.json"),
	delay(1), -- Show the splash screen at least 1 second
}):next(function(results)
	local config = results[1]
	print("Loaded, starting level:", config.start_level)
end)
```

`promise.race` finishes with the first promise that resolves or rejects. A common use is a timeout:

```lua
promise.race({
	load_config("https://example.com/config.json"),
	delay(5):next(function()
		return promise.rejected("timeout")
	end),
}):catch(function(reason)
	print("Failed:", reason)
end)
```


### Make an operation cancellable

`cancel()` rejects a pending promise with an internal cancellation reason and triggers its `on_cancel` handlers, where you stop timers, animations or other external work.

This small module turns a GUI animation into a cancellable promise:

```lua
-- move_animation.lua
local promise = require("event.promise")

local M = {}


function M.start(node, position, duration)
	-- You can pass a context as a first argument for the executor function
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

Cancellation is shared across a chain: promises created by `next`, `catch` and `finally` cancel together, no matter which one you call `cancel()` on.

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

chain:catch(function(reason)
	if not promise.is_cancelled_reason(reason) then
		print("Animation failed:", reason)
	end
end)

-- Cancelling any promise marks the shared chain as cancelled.
-- The currently running GUI animation is stopped by its on_cancel handler.
animation:cancel()
```

Cancellation is delivered as a rejection, so `catch` and `finally` handlers still run. If you have a promise reference, check `chain:is_cancelled()`; inside a rejection callback use `promise.is_cancelled_reason(reason)` to tell cancellation apart from a real failure.


### Queue animations with append

`append` is useful when an object receives animation requests over time. It adds each task to the current tail of the promise, so only one queued animation runs at a time.

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

A cancelled pipeline cannot be reused; create a new `promise.resolved()` pipeline.


### Cancellation reference

How `cancel()` propagates:

- **Single promise:** a pending promise is rejected and its `on_cancel` handlers run once. Normal resolve or reject does not invoke `on_cancel`.
- **Promise chain:** promises created by `next`, `catch` and `finally` share cancellation. Cancelling the head, middle or tail stops pending work and skips later success handlers; rejection handlers and `finally` still run.
- **Returned promise:** when a handler returns another promise, it joins the chain and its cleanup is triggered by chain cancellation too.
- **Append pipeline:** cancelling the pipeline or its tail stops the active task and prevents queued tasks from starting.
- **`promise.all` / `promise.race`:** cancelling the combined promise cancels every pending input promise. A normally resolved race does not automatically cancel the other inputs.
- **Already finished promise:** its state and value do not change, but cancelling it still cancels pending descendants that share its chain.

Cancellation is idempotent — calling `cancel()` again does nothing.

For a pending promise chain, callbacks run synchronously in this order:

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
