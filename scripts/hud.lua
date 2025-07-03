function on_hud_open()
    input.add_callback("movement.jump", function()
        print("АЛЁЁ")
        if _G["$PLAYER_ON"] then
            local vel = {player.get_vel(hud.get_player())}
            player.set_vel(hud.get_player(), vel[1], 9, vel[3])
        end
    end)
end