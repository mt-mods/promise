
mtt.register("Promise.sync", function(callback)
    local p = Promise.sync(function()
        local v = Promise.await(Promise.after(0, 42))
        assert(v == 42)
        local v1 = Promise.await(Promise.resolved(666))
        assert(v1 == 666)
        return v
    end)

    p:next(function(v)
        assert(v == 42)
        callback()
    end)
end)

mtt.register("Promise.sync 2", function()
    return Promise.sync(function()
        local v = Promise.await(Promise.resolved(42))
        assert(v == 42)
    end)
end)