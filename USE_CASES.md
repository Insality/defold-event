
## Use Cases

This section illustrates practical examples of how to use the Event module in your Defold game development projects.

### 1. Global Events Management

You can create a global event module that allows events to be triggered from anywhere within your game. This approach requires careful management of subscriptions and unsubscriptions to prevent errors.

```lua
-- global_events.lua
local event = require("event.event")
local M = {}

M.on_game_start = event.create(),
M.on_game_over = event.create()

return M
```

**Usage:**

```lua
local global_events = require("global_events")

local function on_game_start(self)
    -- Animate GUI elements somehow
end

local function on_game_over(self)
    -- Animate GUI elements somehow
end

function init(self)
    global_events.on_game_start:subscribe(on_game_start, self)
    global_events.on_game_over:subscribe(on_game_over, self)
end

function final(self)
    global_events.on_game_start:unsubscribe(on_game_start, self)
    global_events.on_game_over:unsubscribe(on_game_over, self)
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
