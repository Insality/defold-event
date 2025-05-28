# promise API

> at /event/promise.lua

The Promise module, used to create and manage promises. Implements A+ Promise specification.
A promise represents a single asynchronous operation that will either resolve with a value or reject with a reason.

## Functions

- [is_promise](#is_promise)
- [create](#create)
- [resolved](#resolved)
- [rejected](#rejected)
- [all](#all)
- [race](#race)

- [next](#next)
- [catch](#catch)
- [finally](#finally)
- [is_pending](#is_pending)
- [is_resolved](#is_resolved)
- [is_rejected](#is_rejected)
- [is_finished](#is_finished)

## Fields

- [state](#state)
- [value](#value)



### is_promise

---
```lua
promise.is_promise([value])
```

Check if a value is a promise object

- **Parameters:**
	- `[value]` *(any)*: The value to check

- **Returns:**
	- `is_promise` *(boolean)*: True if the value is a promise

### create

---
```lua
promise.create([executor])
```

Generate a new promise instance. This instance represents a single asynchronous operation.
The executor function is called immediately with resolve and reject functions.

- **Parameters:**
	- `[executor]` *(function|event|nil)*: The function or event that will be called with resolve and reject functions. Optional for manual promise creation.

- **Returns:**
	- `promise_instance` *(promise)*: A new promise instance.

### resolved

---
```lua
promise.resolved([value])
```

Create a promise that is immediately resolved with the given value.

- **Parameters:**
	- `[value]` *(any)*: The value to resolve the promise with.

- **Returns:**
	- `promise_instance` *(promise)*: A resolved promise.

### rejected

---
```lua
promise.rejected([reason])
```

Create a promise that is immediately rejected with the given reason.

- **Parameters:**
	- `[reason]` *(any)*: The reason to reject the promise with.

- **Returns:**
	- `promise_instance` *(promise)*: A rejected promise.

### all

---
```lua
promise.all(promises)
```

Create a promise that resolves when all given promises resolve.
If any promise rejects, the returned promise will reject with that reason.

- **Parameters:**
	- `promises` *(promise[])*: Array of promises to wait for.

- **Returns:**
	- `promise_instance` *(promise)*: A promise that resolves with an array of all resolved values.

### race

---
```lua
promise.race(promises)
```

Create a promise that resolves or rejects as soon as one of the given promises resolves or rejects.

- **Parameters:**
	- `promises` *(promise[])*: Array of promises to race.

- **Returns:**
	- `promise_instance` *(promise)*: A promise that resolves or rejects with the first finished promise.

### next

---
```lua
promise:next([on_resolved], [on_rejected])
```

Attach resolve and reject handlers to the promise.
Returns a new promise that will be resolved or rejected based on the handlers' return values.

- **Parameters:**
	- `[on_resolved]` *(function|event|nil)*: Handler called when promise is resolved. If nil, value passes through.
	- `[on_rejected]` *(function|event|nil)*: Handler called when promise is rejected. If nil, rejection passes through.

- **Returns:**
	- `new_promise` *(promise)*: A new promise representing the result of the handlers.

### catch

---
```lua
promise:catch(on_rejected)
```

Attach a rejection handler to the promise. Equivalent to next(nil, on_rejected).

- **Parameters:**
	- `on_rejected` *(function|event)*: Handler called when promise is rejected.

- **Returns:**
	- `new_promise` *(promise)*: A new promise representing the result of the handler.

### finally

---
```lua
promise:finally(on_finally)
```

Attach a handler that is called regardless of whether the promise is resolved or rejected.
The handler receives no arguments and its return value is ignored.

- **Parameters:**
	- `on_finally` *(function|event)*: Handler called when promise is finished (resolved or rejected).

- **Returns:**
	- `new_promise` *(promise)*: A new promise that resolves/rejects with the same value/reason as the original.

### is_pending

---
```lua
promise:is_pending()
```

Check if the promise is in pending state.

- **Returns:**
	- `is_pending` *(boolean)*: True if the promise is pending.

### is_resolved

---
```lua
promise:is_resolved()
```

Check if the promise is in resolved state.

- **Returns:**
	- `is_resolved` *(boolean)*: True if the promise is resolved.

### is_rejected

---
```lua
promise:is_rejected()
```

Check if the promise is in rejected state.

- **Returns:**
	- `is_rejected` *(boolean)*: True if the promise is rejected.

### is_finished

---
```lua
promise:is_finished()
```

Check if the promise is finished (either resolved or rejected).

- **Returns:**
	- `is_finished` *(boolean)*: True if the promise is finished.


## Fields
<a name="state"></a>
- **state** (_string_): Current state of the promise (pending, resolved, rejected)

<a name="value"></a>
- **value** (_any_): The resolved val ue or rejection reason

