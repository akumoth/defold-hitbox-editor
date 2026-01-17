
local resize_buttons = {}

function resize_buttons:update()
	local resize_root = gui.get_node("resize_buttons")
	local resize_buttons = gui.get_tree(resize_root)

	if not gui.is_enabled(resize_root) then
		gui.set_enabled(resize_root, true)
	end
		
	if self.active and self.active.nodes.root then
		local size = gui.get_size(self.active.nodes.root)
		
		gui.set_size(resize_root, size)
		gui.set_parent(resize_root, self.active.nodes.root)
		for name, corner in pairs(resize_buttons) do
			if name ~= hash("resize_buttons") then 
				local str = tostring(name)

				str = str:match('hash: %[(.-)%]')

				local pos = vmath.vector3()
				if string.match(str,"n") then
					pos.y = size.y/2
				end
				if string.match(str,"w") then
					pos.x = -size.x/2
				end
				if string.match(str,"s") then
					pos.y = -size.y/2
				end
				if string.match(str,"e") then
					pos.x = size.x/2
				end
				gui.set_position(corner, pos)
			end
		end
	end
end

function resize_buttons:init(active, druid)
	assert(active)
	assert(druid)
	
	local resize_root = gui.get_node("resize_buttons")
	local nodes = gui.get_tree(resize_root)
	
	self.nodes = {
		root =  nodes.resize_buttons
	}

	self.active = active
	self.buttons = {}
	self.druid = druid
	gui.set_enabled(resize_root, true)
	gui.set_parent(resize_root, self.active.root, false)
	self:update()

	for name, corner in pairs(nodes) do
		if name ~= hash("resize_buttons") then 

			table.insert(self.buttons, self.druid:new_drag(corner, function(_, dx, dy) 
				local pos = gui.get_position(self.active.nodes.root)
				local size = gui.get_size(self.active.nodes.root)
				local c_pos = gui.get_position(corner)

				local new_pos = vmath.vector3()
				local new_size = vmath.vector3()

				if c_pos.x > 0 then
					new_pos.x = -dx/2
					new_size.x = dx
				elseif c_pos.x < 0 then
					new_pos.x = -dx/2
					new_size.x = -dx
				end

				if c_pos.y < 0 then
					new_pos.y = -dy/2
					new_size.y = -dy
				elseif c_pos.y > 0 then
					new_pos.y = -dy/2
					new_size.y = dy
				end

				new_size = vmath.vector3(math.floor(new_size.x), math.floor(new_size.y), 0)
				
				gui.set_position(self.active.nodes.root, pos-new_pos)
				gui.set_size(self.active.nodes.root, size+new_size)
				gui.set_size(self.active.nodes.fill, size+new_size)
				gui.set_size(self.active.nodes.border, vmath.vector3(size.x+new_size.x+4,size.y+new_size.y+4,0))

				self.active.pos = (pos-new_pos)/self.active.zoom
				self.active.bounds = (size+new_size)/self.active.zoom

				self:update()
				return
			end))

			self.buttons[#self.buttons].on_touch_start:subscribe(function ()
				msg.post(".", "start_resize")
			end)
		end
	end
end

return resize_buttons