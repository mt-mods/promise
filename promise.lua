---------
-- promise library/module
-- Port of https://github.com/rhysbrettbowen/promise_impl/blob/master/promise.js
-- and https://github.com/rhysbrettbowen/Aplus
-- Source: https://github.com/Billiam/promise.lua
local State = {
  PENDING   = 'pending',
  FULFILLED = 'fulfilled',
  REJECTED  = 'rejected',
}

local function callable_table(callback)
  local mt = getmetatable(callback)
  return type(mt) == 'table' and type(mt.__call) == 'function'
end

local function is_callable(value)
  local t = type(value)
  return t == 'function' or (t == 'table' and callable_table(value))
end

local transition, resolve, run

local prototype = {
  is_promise = true,
  state = State.PENDING
}

local mt = { __index = prototype }

local reject = function(promise, reason)
  transition(promise, State.REJECTED, reason)
end

local fulfill = function(promise, value)
  transition(promise, State.FULFILLED, value)
end

transition = function(promise, state, value)
  if promise.state == state
    or promise.state ~= State.PENDING
    or ( state ~= State.FULFILLED and state ~= State.REJECTED )
  then
    return
  end

  promise.state = state
  promise.value = value
  run(promise)
end

function prototype:next(on_fulfilled, on_rejected)
  local promise = Promise.new()

  table.insert(self.queue, {
    fulfill = is_callable(on_fulfilled) and on_fulfilled or nil,
    reject = is_callable(on_rejected) and on_rejected or nil,
    promise = promise
  })

  run(self)

  return promise
end

resolve = function(promise, x)
  if promise == x then
    reject(promise, 'TypeError: cannot resolve a promise with itself')
    return
  end

  local x_type = type(x)

  if x_type ~= 'table' then
    fulfill(promise, x)
    return
  end

  -- x is a promise in the current implementation
  if x.is_promise then
    -- 2.3.2.1 if x is pending, resolve or reject this promise after completion
    if x.state == State.PENDING then
      x:next(
        function(value)
          resolve(promise, value)
        end,
        function(reason)
          reject(promise, reason)
        end
      )
      return
    end
    -- if x is not pending, transition promise to x's state and value
    transition(promise, x.state, x.value)
    return
  end

  local called = false
  -- 2.3.3.1. Catches errors thrown by __index metatable
  local success, reason = pcall(function()
    local next = x.next
    if is_callable(next) then
      next(
        x,
        function(y)
          if not called then
            resolve(promise, y)
            called = true
          end
        end,
        function(r)
          if not called then
            reject(promise, r)
            called = true
          end
        end
      )
    else
      fulfill(promise, x)
    end
  end)

  if not success then
    if not called then
      reject(promise, reason)
    end
  end
end

run = function(promise)
  if promise.state == State.PENDING then return end

  minetest.after(0, function()
    -- drain promise.queue while allowing pushes from within callbacks
    local q = promise.queue
    local i = 0
    while i < #q do
      i = i + 1
      local obj = q[i]
      local success, result = pcall(function()
        local success_fn = obj.fulfill or function(x) return x end
        local failure_fn = obj.reject or function(x) error(x) end
        local callback = promise.state == State.FULFILLED and success_fn or failure_fn
        return callback(promise.value)
      end)

      if not success and obj.reject == nil then
        -- replace reason
        result = promise.value
      end

      if not success then
        reject(obj.promise, result)
      else
        resolve(obj.promise, result)
      end
    end
    for j = 1, i do
      q[j] = nil
    end
  end)
end

function Promise.new(callback)
  local instance = {
    queue = {}
  }
  setmetatable(instance, mt)

  if callback then
    -- catch error in first callback function
    local success, err = pcall(callback,
      function(value)
        resolve(instance, value)
      end,
      function(reason)
        reject(instance, reason)
      end
    )

    if not success then
      return Promise.reject(err)
    end
  end

  return instance
end

function prototype:catch(callback)
  return self:next(nil, callback)
end

function prototype:finally(callback)
  return self:next(callback, callback)
end

function prototype:resolve(value)
  fulfill(self, value)
end

function prototype:reject(reason)
  reject(self, reason)
end

-- resolve when all promises complete
function Promise.all(...)
  local promises = {...}
  local results = {}
  local errors = {}
  local state = State.FULFILLED
  local remaining = #promises

  local promise = Promise.new()

  local check_finished = function()
    if remaining > 0 then
      return
    end
    if state == State.FULFILLED then
      transition(promise, state, results)
    else
      transition(promise, state, errors)
    end
  end

  for i,p in ipairs(promises) do
    p:next(
      function(value)
        results[i] = value
        remaining = remaining - 1
        check_finished()
      end,
      function(err)
        errors[i] = err
        remaining = remaining - 1
        state = State.REJECTED
        check_finished()
      end
    )
  end

  check_finished()

  return promise
end

-- resolve with first promise to settle (rejected or fulfilled)
function Promise.race(...)
  local promises = {...}
  local promise = Promise.new()

  local success = function(value)
    fulfill(promise, value)
  end

  local failure = function(err)
    reject(promise, err)
  end

  for _,p in ipairs(promises) do
    p:next(success):catch(failure)
  end

  return promise
end

-- resolve with the first fulfilled or all rejected
function Promise.any(...)
  local promises = {...}
  local promise = Promise.new()
  local errors = {}
  local error_count = 0

  for i,p in ipairs(promises) do
    p:next(function(v)
      fulfill(promise, v)
    end):catch(function(err)
      errors[i] = err
      error_count = error_count + 1
      if error_count == #promises then
        -- all failed
        reject(promise, errors)
      end
    end)
  end

  return promise
end