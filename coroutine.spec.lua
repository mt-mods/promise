
mtt.register("Promise.async", function(callback)
    local p = Promise.async(function(await)
        local v = await(Promise.after(0, 42))
        assert(v == 42)
        local v1 = await(Promise.resolved(666))
        assert(v1 == 666)
        return 99
    end)

    p:next(function(v)
        assert(v == 99)
        callback()
    end)
end)

mtt.register("Promise.async simple", function()
    return Promise.async(function(await)
        local v = await(Promise.resolved(42))
        assert(v == 42)
    end)
end)

mtt.register("Promise.async with handle_async", function()
    return Promise.async(function(await)
        local v = await(Promise.resolved(42))
        assert(v == 42)
        v = await(Promise.handle_async(function() return 100 end))
        assert(v == 100)
    end)
end)

--[[
mtt.register("Promise.async rejected", function(callback)
    local p = Promise.async(function(await)
        await(Promise.rejected("my-err"))
    end)

    p:catch(function(e)
        -- assert(e == "my-err")
        callback()
    end)
end)
--]]