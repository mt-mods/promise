
local function get_await(step)
    return function(p)
        local co, is_main = coroutine.running()
        assert(co and not is_main, "await() must be called inside a Promise.async() function")
        local result = nil
        local rejected = false
        local err = nil

        -- add success/error callbacks and continue afterwards
        p:next(function(value)
            result = value
        end, function(e)
            rejected = true
            err = e
        end):next(step)

        -- wait until the promise settles
        coroutine.yield()

        -- check if error or success
        if rejected then
            return nil, err
        else
            return result
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
            local await = get_await(step)
            cont, result = coroutine.resume(t, await)
            if not cont then
                -- error in first async() level
                p:reject(result)
                return
            end
        end

        if coroutine.status(t) == "dead" then
            -- async function exited
            p:resolve(result)
        end
    end
    step()

    return p
end
