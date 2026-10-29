-- extended tests: nested / chained / combined promise constellations

mtt.register("nested: promise resolved with pending promise", function()
    local inner = Promise.new()
    local outer = Promise.new(function(resolve)
        resolve(inner)
    end)

    core.after(0.1, function() inner:resolve("late") end)

    return outer:next(function(v)
        assert(v == "late")
    end)
end)

mtt.register("nested: deeply nested resolve chain", function()
    local p = Promise.resolve(1)
    for _ = 1, 20 do
        local prev = p
        p = Promise.new(function(resolve) resolve(prev) end)
    end
    return p:next(function(v)
        assert(v == 1)
    end)
end)

mtt.register("nested: promise returned from next returning promise", function()
    return Promise.resolve(1):next(function(a)
        return Promise.after(0, a + 1):next(function(b)
            return Promise.after(0, b + 1):next(function(c)
                return Promise.resolve(c + 1)
            end)
        end)
    end):next(function(v)
        assert(v == 4)
    end)
end)

mtt.register("nested: inner rejection propagates through outer chain", function(callback)
    Promise.resolve(1):next(function()
        return Promise.resolve(2):next(function()
            return Promise.reject("inner-fail")
        end)
    end):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err == "inner-fail")
        callback()
    end)
end)

mtt.register("nested: inner catch recovers, outer continues", function()
    return Promise.resolve(1):next(function()
        return Promise.reject("oops"):catch(function(err)
            assert(err == "oops")
            return "recovered"
        end)
    end):next(function(v)
        assert(v == "recovered")
    end)
end)

mtt.register("nested: error thrown in nested callback", function(callback)
    Promise.resolve(1):next(function()
        return Promise.resolve(2):next(function()
            error("boom", 0)
        end)
    end):catch(function(err)
        assert(err == "boom")
        callback()
    end)
end)

mtt.register("chain: error skips next without handler until catch", function()
    local called = false
    return Promise.reject("e1"):next(function()
        called = true
    end):next(function()
        called = true
    end):catch(function(err)
        assert(err == "e1")
        assert(not called)
        return "after-catch"
    end):next(function(v)
        assert(v == "after-catch")
    end)
end)

mtt.register("chain: error thrown in catch handler replaces reason", function(callback)
    Promise.reject("first"):catch(function()
        error("second", 0)
    end):catch(function(err)
        assert(err == "second")
        callback()
    end)
end)

mtt.register("chain: rethrow from catch handler", function(callback)
    Promise.reject("first"):catch(function(err)
        return Promise.reject(err .. "+second")
    end):catch(function(err)
        assert(err == "first+second")
        callback()
    end)
end)

mtt.register("chain: finally runs on success and on error", function()
    local count = 0
    return Promise.resolve(1):finally(function()
        count = count + 1
    end):next(function()
        return Promise.reject("x")
    end):finally(function()
        count = count + 1
    end):catch(function(err)
        assert(err == "x")
        assert(count == 2)
    end)
end)

mtt.register("chain: multiple handlers on same promise run in order", function()
    local p = Promise.new()
    local order = {}

    local p1 = p:next(function(v) order[#order + 1] = "a" .. v end)
    local p2 = p:next(function(v) order[#order + 1] = "b" .. v end)
    local p3 = p:next(function(v) order[#order + 1] = "c" .. v end)

    p:resolve(1)

    return Promise.all(p1, p2, p3):next(function()
        assert(table.concat(order, ",") == "a1,b1,c1")
    end)
end)

mtt.register("chain: handler added after settlement still fires", function()
    local p = Promise.resolve("v")
    return Promise.after(0.1):next(function()
        return p:next(function(v)
            assert(v == "v")
        end)
    end)
end)

mtt.register("chain: settling twice keeps first value", function()
    local p = Promise.new(function(resolve, reject)
        resolve("first")
        resolve("second")
        reject("third")
    end)
    return p:next(function(v)
        assert(v == "first")
    end)
end)

mtt.register("chain: thenable adoption", function()
    local thenable = {
        next = function(_, on_ok)
            on_ok("from-thenable")
        end
    }
    return Promise.resolve(1):next(function()
        return thenable
    end):next(function(v)
        assert(v == "from-thenable")
    end)
end)

mtt.register("chain: self-resolution is rejected", function(callback)
    local p
    p = Promise.resolve(1):next(function()
        return p
    end)
    p:catch(function(err)
        assert(type(err) == "string")
        assert(err:find("TypeError"))
        callback()
    end)
end)

mtt.register("all: nested Promise.all", function()
    return Promise.all(
        Promise.all(Promise.resolve(1), Promise.after(0, 2)),
        Promise.all(Promise.after(0, 3), Promise.resolve(4)),
        Promise.resolve(5)
    ):next(function(r)
        assert(#r == 3)
        assert(r[1][1] == 1 and r[1][2] == 2)
        assert(r[2][1] == 3 and r[2][2] == 4)
        assert(r[3] == 5)
    end)
end)

mtt.register("all: results keep order regardless of completion time", function()
    return Promise.all(
        Promise.after(0.3, "slow"),
        Promise.after(0, "fast"),
        Promise.after(0.1, "medium")
    ):next(function(r)
        assert(r[1] == "slow")
        assert(r[2] == "fast")
        assert(r[3] == "medium")
    end)
end)

mtt.register("all: failure in nested all rejects outer all", function(callback)
    Promise.all(
        Promise.resolve(1),
        Promise.all(Promise.resolve(2), Promise.reject("deep"))
    ):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err[1] == nil)
        assert(type(err[2]) == "table")
        assert(err[2][2] == "deep")
        callback()
    end)
end)

mtt.register("all: handlers inside all return promises", function()
    local function step(v)
        return Promise.resolve(v):next(function(x)
            return Promise.after(0, x * 2)
        end)
    end
    return Promise.all(step(1), step(2), step(3)):next(function(r)
        assert(r[1] == 2 and r[2] == 4 and r[3] == 6)
    end)
end)

mtt.register("all: chained all inside next", function()
    return Promise.resolve({1, 2, 3}):next(function(list)
        local promises = {}
        for i, v in ipairs(list) do
            promises[i] = Promise.after(0, v * 10)
        end
        return Promise.all(unpack(promises))
    end):next(function(r)
        assert(#r == 3)
        assert(r[1] == 10 and r[2] == 20 and r[3] == 30)
    end)
end)

mtt.register("race: nested race and all", function()
    return Promise.race(
        Promise.all(Promise.after(0.3, "x"), Promise.after(0.3, "y")),
        Promise.race(Promise.after(0.2, "slow"), Promise.after(0, "winner"))
    ):next(function(v)
        assert(v == "winner")
    end)
end)

mtt.register("race: rejection wins if first", function(callback)
    Promise.race(
        Promise.after(0.2, "late"),
        Promise.after(0, nil, "early-error")
    ):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err == "early-error")
        callback()
    end)
end)

mtt.register("any: skips failures inside nested constellation", function()
    return Promise.any(
        Promise.reject("a"),
        Promise.all(Promise.resolve(1), Promise.reject("b")),
        Promise.resolve(1):next(function()
            return Promise.after(0.1, "ok")
        end)
    ):next(function(v)
        assert(v == "ok")
    end)
end)

mtt.register("any: all nested failures reject", function(callback)
    Promise.any(
        Promise.reject("a"),
        Promise.all(Promise.reject("b")),
        Promise.resolve(1):next(function() error("c", 0) end)
    ):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err[1] == "a")
        assert(type(err[2]) == "table")
        assert(err[3] == "c")
        callback()
    end)
end)

mtt.register("timeout: race between work and timeout", function(callback)
    Promise.race(Promise.after(0.5, "work"), Promise.timeout(0)):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err == "timeout")
        callback()
    end)
end)

mtt.register("async: nested async with error caught in outer", function()
    return Promise.async(function(await)
        local v = await(Promise.async(function(await2)
            return await2(Promise.after(0, 21)) * 2
        end))
        assert(v == 42)

        local res, err = await(Promise.async(function()
            error("inner-error", 0)
        end))
        assert(not res)
        assert(err == "inner-error")
        return "done"
    end):next(function(v)
        assert(v == "done")
    end)
end)

mtt.register("async: await in loop combined with Promise.all", function()
    return Promise.async(function(await)
        local sum = 0
        for i = 1, 5 do
            sum = sum + await(Promise.after(0, i))
        end
        assert(sum == 15)

        local r = await(Promise.all(Promise.after(0, 1), Promise.after(0, 2)))
        assert(r[1] == 1 and r[2] == 2)
        return sum
    end):next(function(v)
        assert(v == 15)
    end)
end)

mtt.register("mixed: fan-out / fan-in pipeline", function()
    local function fetch(id)
        return Promise.after(0, { id = id })
    end
    local function enrich(item)
        return Promise.after(0, item.id * 100):next(function(extra)
            item.extra = extra
            return item
        end)
    end

    return Promise.resolve({1, 2, 3}):next(function(ids)
        local ps = {}
        for i, id in ipairs(ids) do
            ps[i] = fetch(id):next(enrich)
        end
        return Promise.all(unpack(ps))
    end):next(function(items)
        local total = 0
        for _, item in ipairs(items) do
            total = total + item.extra
        end
        return total
    end):next(function(total)
        assert(total == 600)
    end)
end)
