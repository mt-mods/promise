
function Promise.resolved(value)
    local p = Promise.new()
    p:resolve(value)
    return p
end

function Promise.rejected(value)
    local p = Promise.new()
    p:reject(value)
    return p
end

function Promise.after(delay, value, err)
    return Promise.new(function(resolve, reject)
        minetest.after(delay, function()
            if err then
                reject(err)
            else
                resolve(value or true)
            end
        end)
    end)
end

function Promise.emerge_area(pos1, pos2)
    return Promise.new(function(resolve)
        minetest.emerge_area(pos1, pos2, function(_, _, calls_remaining)
            if calls_remaining == 0 then
                resolve(true)
            end
        end)
    end)
end

function Promise.handle_async(fn, ...)
    local args = {...}
    return Promise.new(function(resolve)
        if minetest.handle_async then
            -- use threaded async env
            minetest.handle_async(fn, resolve, unpack(args))
        else
            -- fall back to unthreaded async call
            resolve(fn(unpack(args)))
        end
    end)
end