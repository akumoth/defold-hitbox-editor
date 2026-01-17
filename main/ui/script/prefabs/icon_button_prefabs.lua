local icon_button_prefabs = {}

function icon_button_prefabs:make_prefabs(icon_buttons)
	icon_buttons:new("origin_toggle", "originbutton", nil, 
		function () 
			local origin = gui.get_node("origin")
			gui.set_visible(origin, not gui.get_visible(origin))
		end
	)
	icon_buttons:new("grid_toggle", "gridbutton", nil, 
		function () 
			local grid = gui.get_node("grid")
			gui.set_visible(grid, not gui.get_visible(grid))
		end
	)
	icon_buttons:new("player_toggle", "playerbutton", vmath.vector4(204/255, 255/255, 204/255, 1),
	function () 
		if not icon_buttons.buttons.player_toggle.current then
			icon_buttons.buttons.player_toggle.current = "player"
		end
		
		if icon_buttons.buttons.player_toggle.current == "enemy" then
			icon_buttons.buttons.player_toggle.current = "player"
			gui.set_texture(icon_buttons.buttons.player_toggle.nodes.icon_button_icon, "playerbutton")
			gui.set_color(icon_buttons.buttons.player_toggle.nodes.icon_button_box, vmath.vector4(204/255, 255/255, 204/255, 1))
		else
			icon_buttons.buttons.player_toggle.current = "enemy"
			gui.set_texture(icon_buttons.buttons.player_toggle.nodes.icon_button_icon, "enemybutton")
			gui.set_color(icon_buttons.buttons.player_toggle.nodes.icon_button_box, vmath.vector4(255/255, 204/255, 204/255, 1))
		end
		
		msg.post(".", "set_player",{owner = icon_buttons.buttons.player_toggle.current})
	end
	)
end

return icon_button_prefabs