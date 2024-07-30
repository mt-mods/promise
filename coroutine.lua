
local err_symbol = {}

local function await(p)
    assert(coroutine.running(), "running inside a Promise.async() call")
    local result = nil
    local err = nil
    local finished = false

    p:next(function(...)
        result = {...}
        finished = true
    end):catch(function(e)
        err = e
        finished = true
    end)

    while true do
        if finished then
            if err then
                return coroutine.yield({ err = err, err_symbol = err_symbol })
            else
                return unpack(result)
            end
        else
            coroutine.yield()
        end
    end
end

function Promise.async(fn)
    local t = coroutine.create(fn)
    local p = Promise.new()

    local step = nil
    local result = nil
    local cont = nil
    local _ = nil
    step = function()
        if coroutine.status(t) == "suspended" then
            cont, result = coroutine.resume(t, await)
            if not cont then
                -- error in first async() level
                p:reject(result)
            end
            if type(result) == "table" and result.err_symbol == err_symbol then
                -- error in await() call
                p:reject(result.err)
                return
            end
            minetest.after(0, step)
        else
            -- last result from resume was the return value
            p:resolve(result)
        end
    end
    step()

    return p
end
