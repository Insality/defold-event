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

### 7. Using Defers module to communicate between script and gui_script

Then you add a logic inside `init` function in `script` and `gui_script`, you can't ensure which one will be called first.

With **Defers** module you can subscribe to the event in `script` and call it in `gui_script` or vice versa. The event will be proceed after the subscriber was initialized. So in case the trigger will be called before the subscriber, it will be queued and proceed after the subscriber will be initialized.

Can be useful when you need to use `go` resource functions in `gui_script` or in other cases when you don't know is the subscriber already initialized or not but want to ensure that trigger will be proceed.

```lua
-- gui_script file
local defers = require("event.defers")

function on_get_atlas_path(self, data)
    print("Atlas path: ", data)
end

function init(self)
    defers.push("get_atlas_path", {
        texture_name = gui.get_texture(self.node),
        sender = msg.url(),
    }, self.on_get_atlas_path, self)
end
```

```lua
-- script file
local defers = require("event.defers")

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
    defers.subscribe("get_atlas_path", get_atlas_path, self)
end

function final(self)
    defers.unsubscribe("get_atlas_path", get_atlas_path, self)
end
```
end
```


