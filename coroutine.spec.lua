
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
        minetest.after(0, function()
            coroutine.yield(3) -- attempt to yield across C-call boundary
        end)
    end)

    minetest.after(1, function()
        while true do
            local cont, i = coroutine.resume(t)
            print(dump({
                cont = cont,
                i = i,
                status = coroutine.status(t)
            }))
            if not cont then
                break
            end
        end

        callback()
    end)
end)