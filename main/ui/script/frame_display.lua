local frame_display = {}

function frame_display:display_frame(atlas, anim, idx)
	self.img = io.open(atlas[anim].spr[idx], "rb")

	self.idx = idx
	
	local bytes = self.img:read("*a")
	local png = image.load(bytes)

	gui.set_texture_data("cur_frame", png.width, png.height, "rgba", png.buffer)

	gui.set_size(self.spr_view, vmath.vector3(png.width*self.zoom, png.height*self.zoom, 1))
	gui.set_size(self.spr_window, vmath.vector3(png.width*self.zoom, png.height*self.zoom, 1))

	self.size = vmath.vector3(png.width,png.height,1)
	gui.set_texture(self.spr_view, "cur_frame")
end

function frame_display:on_input(action_id, action)
	if action.pressed and (action_id ==hash("mouse_wheel_up") or action_id == hash("mouse_wheel_down")) then
		if action_id == hash("mouse_wheel_up") and action.pressed then
			if self.zoom < 4 then 
				self.zoom = self.zoom + 1 
				gui.set_size(self.spr_view, vmath.vector3(self.size.x*self.zoom, self.size.y*self.zoom, 1))
			end	
			
		elseif action_id == hash("mouse_wheel_down") and action.pressed then
			if self.zoom > 1 then 
				self.zoom = self.zoom - 1 
				gui.set_size(self.spr_view, vmath.vector3(self.size.x*self.zoom, self.size.y*self.zoom, 1))
			end
		end
		msg.post(".", "set_zoom", {zoom=self.zoom, origin=gui.get_position(self.spr_window)})
	end
end

function frame_display:init(druid)
	self.druid = druid

	self.drag = {}
	self.drag = druid:new_drag("sprite_window", function(_, dx, dy)
		if self.can_click then
			local position_x = gui.get(self.drag.node, "position.x")
			local position_y = gui.get(self.drag.node, "position.y")
			gui.set(self.drag.node, "position.x", position_x + dx)
			gui.set(self.drag.node, "position.y", position_y + dy)
		end
	end)

	self.img = io.open("data/empty.png", "rb")
	local bytes = self.img:read("*a")
	local png = image.load(bytes)
	gui.new_texture("cur_frame", png.width, png.height, "rgba", png.buffer)
	self.size = vmath.vector3(1,1,1)

	self.zoom = 1
	self.idx = 1
	
	self.spr_view = gui.get_node("sprite_view")
	self.spr_window = gui.get_node("sprite_window")

	self.grid = gui.get_node("grid")
	self.origin = gui.get_node("origin")

	self.can_click = true
end

return frame_display