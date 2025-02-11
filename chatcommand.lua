local function get_message(t0, cmd, params, value, success)
    local micros = minetest.get_us_time() - t0
    local seconds = math.floor(micros / 1000 / 100) / 10

    local msg = "Command '" .. cmd
    if params and params ~= "" then
        msg = msg .. " " .. params
    end
    msg = msg .. "'"

    if success then
        msg = msg .. " succeeded"
    else
        msg = msg .. " failed"
    end

    if type(value) == "string" then
        msg = msg .. " with result: '" .. value .. "'"
    end

    msg = msg .. " (took " .. seconds .. " s)"
    return msg
end

function Promise.register_chatcommand(cmd, def)
    local old_func = def.func
    def.func = function(name, params)
        local t0 = minetest.get_us_time()
        local p = old_func(name, params)
        if p and p.is_promise then
            -- result is a promise, add success- and error-wrappers
            p:next(function(v)
                local msg = get_message(t0, cmd, params, v, true)
                minetest.log("action", msg)
                minetest.chat_send_player(name, msg)
            end):catch(function(e)
                local msg = get_message(t0, cmd, params, e, false)
                minetest.log("error", msg)
                minetest.chat_send_player(name, minetest.colorize("#ff0000", msg))
            end)

            return true
        else
            -- not a promise
            return p
        end
    end

    return minetest.register_chatcommand(cmd, def)
end