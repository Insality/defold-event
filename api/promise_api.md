# promise API

> at event/promise.lua

The Promise module, used to create and manage promises.
A promise represents a single asynchronous operation that will either resolve with a value or reject with a reason.

## Functions

- [create](#create)
- [resolved](#resolved)
- [rejected](#rejected)
- [all](#all)
- [race](#race)
- [is_promise](#is_promise)

- [next](#next)
- [catch](#catch)
- [finally](#finally)
- [is_pending](#is_pending)
- [is_resolved](#is_resolved)
- [is_rejected](#is_rejected)
- [is_finished](#is_finished)
- [resolve](#resolve)
- [reject](#reject)
- [append](#append)
- [tail](#tail)
- [reset](#reset)

## Fields

- [state](#state)
- [value](#value)



### create

---
```lua
promise.create([executor], [context])
```

Generate a new promise instance. This instance represents a single asynchronous operation.
The executor function is called immediately with resolve and reject functions.

- **Parameters:**
	- `[executor]` *(function|event|nil)*: The function or event that will be called with resolve and reject functions. Optional for manual promise creation.
	- `[context]` *(any)*: The context to call the executor function with.

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

### next

---
```lua
promise:next([on_resolved], [on_rejected], [context])
```

Attach resolve and reject handlers to the promise.
Returns a new promise that will be resolved or rejected based on the handlers' return values.

- **Parameters:**
	- `[on_resolved]` *(function|event|promise|nil)*: Handler called when promise is resolved. If nil, value passes through.
	- `[on_rejected]` *(function|event|promise|nil)*: Handler called when promise is rejected. If nil, rejection passes through.
	- `[context]` *(any)*: The context to call the handlers with.

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

### resolve

---
```lua
promise:resolve([value])
```

Resolve the promise.

- **Parameters:**
	- `[value]` *(any)*: The value to resolve with.

### reject

---
```lua
promise:reject([reason])
```

Reject the promise.

- **Parameters:**
	- `[reason]` *(any)*: The reason to reject with.

### append

---
```lua
promise:append([task])
```

Append a task to this promise's internal sequence without reassigning.
The task may return a value or a promise. Returns self for chaining.
Almost similar to `promise = promise:next(task)`, but without reassigning the promise.

- **Parameters:**
	- `[task]` *(fun(value: any):any)*:

- **Returns:**
	- `self` *(promise)*:

### tail

---
```lua
promise:tail()
```

Get the current tail promise representing all appended work.

- **Returns:**
	- `tail` *(promise)*:

### reset

---
```lua
promise:reset()
```

Reset the internal sequence to an already resolved promise.

- **Returns:**
	- `self` *(promise)*:


## Fields
<a name="state"></a>
- **state** (_"pending"|"rejected"|"resolved"_): Current state of the promise (pending, resolved, rejected)

<a name="value"></a>
- **value** (_any_): The resolved value or rejection reason

