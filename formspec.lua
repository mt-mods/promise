-- playername -> { id => fn() }
local formspec_promises = {}

minetest.register_on_leaveplayer(function(player)
    local playername = player:get_player_name()
    formspec_promises[playername] = nil
end)

minetest.register_on_player_receive_fields(function(player, id, fields)
    local playername = player:get_player_name()
    local p = formspec_promises[id]
    if not p then
        return false
    end

    p:resolve({
        fields = fields,
        player = player
    })

    -- cleanup
    local cb_map = formspec_promises[playername]
    if cb_map then
        cb_map[id] = nil
    end
    return true
end)

function Promise.formspec(player, formspec)
    local p = Promise.new()
    local id = "" .. math.floor(math.random() * 100000)

    local playername = player:get_player_name()
    local cb_map = formspec_promises[playername]
    if not cb_map then
        -- create callback map
        cb_map = {}
        formspec_promises[playername] = cb_map
    end
    cb_map[id] = p
    minetest.show_formspec(player:get_player_name(), id, formspec)
    return p
end