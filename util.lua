
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

function Promise.after(delay, value)
    return Promise.new(function(resolve)
        minetest.after(delay, function()
            resolve(value or true)
        end)
    end)
end
