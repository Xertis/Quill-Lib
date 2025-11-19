input.add_callback("movement.jump", function()
    if _G["$PLAYER_ON"] then
        local vel = {player.get_vel(hud.get_player())}
        player.set_vel(hud.get_player(), vel[1], 9, vel[3])
    end
end)