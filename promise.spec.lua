
mtt.register("simple promise", function(callback)
    Promise.new(function(resolve)
        resolve(5)
    end):next(function(result)
        assert(result == 5)
        callback()
    end)
end)

mtt.register("promise:finally", function(callback)
    Promise.new(function(resolve)
        resolve(5)
    end):finally(function()
        return Promise.reject("err")
    end):finally(function()
        callback()
    end)
end)

mtt.register("simple promise (resolved with false)", function(callback)
    Promise.new(function(resolve)
        resolve(false)
    end):next(function(result)
        assert(result == false)
        callback()
    end)
end)

mtt.register("simple promise (resolved with nil, chained with nil-result)", function(callback)
    Promise.new(function(resolve)
        resolve(nil)
    end):next(function(result)
        assert(result == nil)
    end):next(function(result)
        assert(result == nil)
        return Promise.resolve()
    end):next(function(result)
        assert(result == nil)
        callback()
    end)
end)

mtt.register("returned promise", function(callback)
    local p1 = Promise.new(function(resolve)
        resolve(5)
    end)

    local p2 = Promise.new(function(resolve)
        resolve(10)
    end)

    p1:next(function(result)
        assert(result == 5)
        return p2
    end):next(function(result)
        assert(result == 10)
        callback()
    end)
end)

mtt.register("error handling", function(callback)
    Promise.new(function(_, reject)
        reject("nope")
    end):catch(function(err)
        assert(err == "nope")
        callback()
    end)
end)

mtt.register("error handling 2", function(callback)
    Promise.reject("nope"):catch(function(err)
        -- "nope"
        assert(err)
    end)

    Promise.reject("nope"):next(function() end):catch(function(err)
        assert(err == "nope")
        callback()
    end)
end)

mtt.register("error handling 3", function(callback)
    Promise.new(function()
        error("nope", 0)
    end):catch(function(err)
        assert(err == "nope")
        callback()
    end)
end)

mtt.register("Promise.all (success)", function(callback)
    local p1 = Promise.new(function(resolve)
        resolve(5)
    end)

    local p2 = Promise.new(function(resolve)
        resolve(10)
    end)

    Promise.all(p1, p2):next(function(values)
        assert(#values == 2)
        assert(values[1] == 5)
        assert(values[2] == 10)
        callback()
    end):catch(function(err)
        callback(err)
    end)
end)

mtt.register("Promise.all (error)", function(callback)
    local p1 = Promise.new(function(resolve)
        resolve(5)
    end)

    local p2 = Promise.new(function(_, reject)
        reject("stuff")
    end)

    Promise.all(p1, p2):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err[1] == nil)
        assert(err[2] == "stuff")
        callback()
    end)
end)

mtt.register("Promise.race (success)", function(callback)
    local p1 = Promise.resolve(5)
    local p2 = Promise.new()

    Promise.race(p1, p2):next(function(v)
        assert(v == 5)
        callback()
    end)
end)

mtt.register("Promise.race (error)", function(callback)
    local p1 = Promise.reject("whatever")
    local p2 = Promise.new()

    Promise.race(p1, p2):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err == "whatever")
        callback()
    end)
end)

mtt.register("Promise.race (timeout error)", function(callback)
    local p = Promise.new()
    local to = Promise.after(0.1, nil, "whatever")

    Promise.race(p, to):next(function()
        callback("unexpected success")
    end):catch(function(err)
        assert(err == "whatever")
        callback()
    end)
end)

mtt.register("Promise.any (success)", function(callback)
    local p1 = Promise.resolve(5)
    local p2 = Promise.reject("stuff")

    Promise.any(p1, p2):next(function(v)
        assert(v == 5)
        callback()
    end)
end)

mtt.register("Promise.any (error)", function(callback)
    local p1 = Promise.reject("stuff1")
    local p2 = Promise.reject("stuff2")

    Promise.any(p1, p2):next(function()
        callback("unexpected success")
    end):catch(function(errors)
        assert(errors[1] == "stuff1")
        assert(errors[2] == "stuff2")
        callback()
    end)
end)

mtt.register("Promise control logic", function(callback)
    Promise.new(function(resolve)
        resolve(math.random())
    end):next(function(r)
        if r < 0.5 then
            -- branch 1
            return Promise.new(function(resolve)
                resolve(math.random())
            end)
        else
            -- branch 2
            return Promise.new(function(resolve)
                resolve(math.random())
            end)
        end
    end):next(function()
        callback()
    end)
end)