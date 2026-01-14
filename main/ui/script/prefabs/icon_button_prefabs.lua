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
end

return icon_button_prefabs