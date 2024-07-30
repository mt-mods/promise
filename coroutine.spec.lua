
mtt.register("Promise.sync", function(callback)
    local p = Promise.sync(function()
        local v = Promise.await(Promise.after(0, 42))
        assert(v == 42)
        local v1 = Promise.await(Promise.resolved(666))
        assert(v1 == 666)
        return 99
    end)

    p:next(function(v)
        assert(v == 99)
        callback()
    end)
end)

mtt.register("Promise.sync simple", function()
    return Promise.sync(function()
        local v = Promise.await(Promise.resolved(42))
        assert(v == 42)
    end)
end)

mtt.register("Promise.sync with handle_async", function()
    return Promise.sync(function()
        local v = Promise.await(Promise.resolved(42))
        assert(v == 42)
        v = Promise.await(Promise.handle_async(function() return 100 end))
        assert(v == 100)
    end)
end)

--[[
mtt.register("Promise.sync rejected", function(callback)
    local p = Promise.sync(function()
        Promise.await(Promise.rejected("my-err"))
    end)

    p:catch(function(e)
        -- assert(e == "my-err")
        callback()
    end)
end)
--]]