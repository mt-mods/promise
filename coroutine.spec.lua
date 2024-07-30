
mtt.register("coroutine handling", function(callback)
    --[[
    local v1 = Promise.async(function()
        local v = Promise.await(Promise.after(1, 42))
        assert(v == 42)
        return v
    end)
    assert(v1 == 42)
    --]]

    local t = coroutine.create(function()
        coroutine.yield(1)
        coroutine.yield(2)
    end)

    print(coroutine.resume(t))
    print(coroutine.status(t))
    print(coroutine.resume(t))
    print(coroutine.status(t))
    print(coroutine.resume(t))
    print(coroutine.status(t))

    callback()
end)