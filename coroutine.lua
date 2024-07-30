
function Promise.sync(fn)
    local t = coroutine.create(fn)
    local p = Promise.new()

    local step = nil
    local result = nil
    local _ = nil
    step = function()
        if coroutine.status(t) == "suspended" then
            _, result = coroutine.resume(t)
            minetest.after(0, step)
        else
            p:resolve(result)
        end
    end
    step()

    return p
end

function Promise.await(p)
    assert(coroutine.running(), "running inside a Promise.sync() call")
    local result = nil
    local err = nil
    local finished = false

    p:next(function(...)
        result = {...}
        finished = true
    end):catch(function(e)
        print(dump({
            fn = "catch",
            err = e
        }))
        err = e
        finished = true
    end)

    while true do
        if finished then
            coroutine.yield({ done = true })
            if err then
                return error(err)
            else
                return unpack(result)
            end
        else
            coroutine.yield()
        end
    end
end