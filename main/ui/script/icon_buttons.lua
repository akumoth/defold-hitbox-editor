local icon_buttons = {}
local tbl_utils = require("main.utils.table_utils")

function icon_buttons:init(druid)
	self.druid = druid
	self.buttons = {}
	self.template = gui.get_node("icon_button")
	self.parent = gui.get_node("icons")

	msg.post(".", "icon_buttons_init")
end

function icon_buttons:new(name, icon, color, func)
	local new_nodes = gui.clone_tree(self.template)

	gui.set_parent(new_nodes.icon_button, self.parent, false)
	gui.set_position(new_nodes.icon_button, vmath.vector3(-16+(-40*(tbl_utils.len(self.buttons))), 0, 0))

	if icon then
		gui.set_texture(new_nodes.icon_button_icon, icon)
	end

	if color then
		gui.set_color(new_nodes.icon_button_box, color)
	end

	local new_button = self.druid:new_button(new_nodes.icon_button, func)

	gui.set_enabled(new_nodes.icon_button, true)
	gui.set_visible(new_nodes.icon_button, true)

	self.buttons[name] = {
		nodes = new_nodes,
		button = new_button
	}
end

function icon_buttons:delete()

end

return icon_buttons