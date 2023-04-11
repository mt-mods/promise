local formspec_promises = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local p = formspec_promises[formname]
    if not p then
        return false
    end

    p:resolve({
        fields = fields,
        player = player
    })

    -- cleanup
    formspec_promises[formname] = nil
    return true
end)

function Promise.formspec(player, formspec)
    local p = Promise.new()
    local id = "" .. math.floor(math.random() * 100000)
    formspec_promises[id] = p
    minetest.show_formspec(player:get_player_name(), id, formspec)
    return p
end