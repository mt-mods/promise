
function Promise.async(fn)
    local co = coroutine.create(fn)
    local nxt = nil
    nxt = function(cont, ...)
        if not cont then
            return ...
        else
            return nxt(coroutine.resume(co, ...))
        end
    end
    return nxt(coroutine.resume(co))
end

function Promise.await(p)
    p:next(function(...)
        coroutine.yield(...)
    end)
end