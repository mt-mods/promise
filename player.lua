
-- creates a "wait for player event" function for the given registration function
local function player_event(register)
    -- playername -> promise
    local promises = {}

    register(function(player)
        local playername = player:get_player_name()
        local p = promises[playername]
        if p then
            promises[playername] = nil
            p:resolve(player)
        end
    end)

    return function(playername, timeout)
        local p = promises[playername]
        if not p then
            p = Promise.new()
            promises[playername] = p
        end
        return Promise.with_timeout(p, timeout)
    end
end

Promise.joinplayer  = player_event(core.register_on_joinplayer)
Promise.leaveplayer = player_event(core.register_on_leaveplayer)
