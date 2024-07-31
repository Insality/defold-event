
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
    local myButton = Button.create()

    -- Subscribe to the button's on_click event
    myButton.on_click:subscribe(function()
        print("Button clicked!")
    end)

    -- If we destroy the scene with the button
    -- We can do not unsubscribe from the event
    -- Cause the event will be destroyed with the button

    -- Simulate a button click
    myButton.on_click:trigger()
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