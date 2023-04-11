
function Promise.resolved(value)
    return Promise.new(function(resolve)
        resolve(value)
    end)
end

function Promise.rejected(value)
    return Promise.new(function(_, reject)
        reject(value)
    end)
end

function Promise.after(delay, value)
    return Promise.new(function(resolve)
        minetest.after(delay, function()
            resolve(value or true)
        end)
    end)
end