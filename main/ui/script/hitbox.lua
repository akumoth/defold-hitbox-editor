local class = require('main.utils.class')
local hitbox = class.new_class({})
local const = require("main.ui.script.constants")

function hitbox:_create_drag_function()
	return function (_, dx, dy)
		if self.can_click then
			local position_x = gui.get(self.drag.node, "position.x")
			local position_y = gui.get(self.drag.node, "position.y")
			gui.set(self.drag.node, "position.x", math.floor(position_x + dx))
			gui.set(self.drag.node, "position.y", math.floor(position_y + dy))
			self.pos = gui.get_position(self.drag.node)/self.zoom
		end
	end
end

function hitbox.new(_data)
	assert(_data.druid)
	
	local data = {
		druid = _data.druid,
		zoom = 1
	}

	data.can_click = true
	
	local n
	if _data.nodes then 
		data.nodes = {
			fill = _data.nodes.fill,
			border = _data.nodes.border,
			root = _data.nodes.hitbox_prefab
		}
		n = data.nodes.root

		data.pos = gui.get_position(n)
		data.bounds = gui.get_size(n)

		data.creating = true

		data.attrs = {}
	else
		assert(_data.pos)
		assert(_data.bounds)

		data.pos = _data.pos
		data.bounds = _data.bounds

		data.nodes = {}
		
		if _data.attrs then
			data.attrs = {}
			for name, value in pairs(_data.attrs) do
				data.attrs[name] = value
			end
		end
	end
	
	local self = setmetatable(data, hitbox)
	self._index = self
	return self
end

function hitbox:update(dt, mouse_pos)
	if self.creating then 
		for _, node in pairs(self.nodes) do
			local size = mouse_pos - self.pos

			if size.x > 0 then
				if size.y > 0 then
					gui.set_pivot(node, gui.PIVOT_SW)
				elseif size.y < 0 then
					gui.set_pivot(node, gui.PIVOT_NW)
				end
			elseif size.x < 0 then
				if size.y > 0 then
					gui.set_pivot(node, gui.PIVOT_SE)
				elseif size.y < 0 then
					gui.set_pivot(node, gui.PIVOT_NE)
				end
			end

			size = vmath.vector3(math.abs(size.x),math.abs(size.y), 0)
			gui.set_size(node, size)
		end
	end
end

function hitbox:finish_create()
	self.creating = false
	
	local size = gui.get_size(self.nodes.root)
	local pivot = gui.get_pivot(self.nodes.root)

	local pos = gui.get_position(self.nodes.root)
	
	if pivot == gui.PIVOT_NW or pivot == gui.PIVOT_SW then
		pos.x = pos.x + size.x/2
	elseif pivot == gui.PIVOT_NE or pivot == gui.PIVOT_SE then
		pos.x = pos.x - size.x/2
	end

	if pivot == gui.PIVOT_NW or pivot == gui.PIVOT_NE then
		pos.y = pos.y - size.y/2
	elseif pivot == gui.PIVOT_SW or pivot == gui.PIVOT_SE then
		pos.y = pos.y + size.y/2
	end

	gui.set_position(self.nodes.root, pos)
	
	for _, node in pairs(self.nodes) do
		gui.set_pivot(node, gui.PIVOT_CENTER)
	end
	
	gui.set_size(self.nodes.border, vmath.vector3(size.x+4,size.y+4,0))

	self.pos = gui.get_position(self.nodes.root)/self.zoom
	self.bounds = gui.get_size(self.nodes.root)/self.zoom

	self.drag = self.druid:new_drag(self.nodes.root, self:_create_drag_function())

	self.drag.on_touch_start:subscribe(function () 
		msg.post(".","set_active", {idx=self.idx})
	end)
	msg.post(".","update_resize_buttons")
end

function hitbox:set_zoom(zoom)
	if self.zoom ~= zoom then
		self.zoom = zoom

		for _, node in pairs(self.nodes) do
			gui.set_size(node, self.bounds*zoom)
		end

		gui.set_size(self.nodes.border, vmath.vector3(self.bounds.x*zoom+4, self.bounds.y*zoom+4, 0))

		if self.nodes.arrow then
			self:update_knockback(self.attrs.angle or 1, self.attrs.knockback or 1)
		end

		local pos = self.pos*self.zoom
		gui.set_position(self.nodes.root, pos)

		msg.post(".","update_resize_buttons")
	end
end

function hitbox:create()
	local ok
	if self.nodes.root then
		local err
		ok, err = pcall(gui.get_position, self.nodes.root)
	end
	
	if not ok then
		local nodes = gui.clone_tree(gui.get_node("hitbox_prefab"))
		gui.set_enabled(nodes.hitbox_prefab, true)
		
		gui.set_position(nodes.hitbox_prefab, self.pos*self.zoom)
		gui.set_size(nodes.hitbox_prefab, self.bounds*self.zoom)
		gui.set_size(nodes.fill, self.bounds*self.zoom)
		
		gui.set_size(nodes.border, vmath.vector3((self.bounds.x*self.zoom)+4,(self.bounds.y*self.zoom)+4,1))

		self.nodes.root = nodes.hitbox_prefab
		self.nodes.border = nodes.border
		self.nodes.fill = nodes.fill

		self.drag = self.druid:new_drag(self.nodes.root, self:_create_drag_function())
		self.drag.on_touch_start:subscribe(function () 
			msg.post(".","set_active", {idx=self.idx})
		end)

		if not self.attrs.hitbox_type then
			self.attrs.hitbox_type = "hurtbox"
		end
		
		if self.attrs.hitbox_type == "hitbox" then
			self:add_knockback(self.attrs.angle or 1, self.attrs.knockback or 1)
		end
		self:set_color({
			fill = const.HITBOX_COLORS[self.attrs.hitbox_type],
			border = const.HITBOX_COLORS[self.attrs.hitbox_type] 
		})
	end
end

function hitbox:delete(clear)
	if not clear then clear = false end
	
	if self.drag then
		self.druid:remove(self.drag)
	end

	for _, value in pairs(self.nodes) do
		gui.delete_node(value)
		self.nodes[_] = nil
	end

	if clear then
		self = nil
		return nil
	end
end

function hitbox:move(action_id, mod, hold)
	local pos = gui.get_position(self.nodes.root)
	local d = (mod and 1) or (hold and 2) or 4
	
	if action_id == hash("key_left") then
		gui.set_position(self.nodes.root, vmath.vector3(pos.x-(d), pos.y, 0))
	elseif action_id == hash("key_right") then
		gui.set_position(self.nodes.root, vmath.vector3(pos.x+(d), pos.y, 0))
	elseif action_id == hash("key_up") then
		gui.set_position(self.nodes.root, vmath.vector3(pos.x, pos.y+(d), 0))
	elseif action_id == hash("key_down") then
		gui.set_position(self.nodes.root, vmath.vector3(pos.x, pos.y-(d), 0))
	end

	self.pos = gui.get_position(self.nodes.root)/self.zoom
end

function hitbox:set_size(new_size)
	gui.set_size(self.nodes.root, new_size)
	gui.set_size(self.nodes.fill, new_size)
	gui.set_size(self.nodes.border, vmath.vector3(new_size.x+4,new_size.y+4,1))

	self.bounds = new_size/self.zoom
end

function hitbox:set_color(color)
	gui.set_color(self.nodes.fill, color.fill)
	gui.set_color(self.nodes.border, color.border)
end

function hitbox:resize(action_id, mod, hold)
	local pos = gui.get_position(self.nodes.root)
	local size = gui.get_size(self.nodes.root)
	local d = (mod and 1) or (hold and 2) or 4

	if action_id == hash("key_left") then
		self:set_size(vmath.vector3(size.x+(d), size.y, 0))
		gui.set_position(self.nodes.root, vmath.vector3(pos.x-(d)/2, pos.y, 0))
	elseif action_id == hash("key_right") then
		self:set_size(vmath.vector3(size.x-(d), size.y, 0))
		gui.set_position(self.nodes.root, vmath.vector3(pos.x+(d)/2, pos.y, 0))
	elseif action_id == hash("key_up") then
		self:set_size(vmath.vector3(size.x, size.y-(d), 0))
		gui.set_position(self.nodes.root, vmath.vector3(pos.x, pos.y+(d)/2, 0))
	elseif action_id == hash("key_down") then
		self:set_size(vmath.vector3(size.x, size.y+(d), 0))
		gui.set_position(self.nodes.root, vmath.vector3(pos.x, pos.y-(d)/2, 0))
	end

	self.pos = gui.get_position(self.nodes.root)/self.zoom
	
	msg.post(".","update_resize_button")
end

function hitbox:update_knockback(angle, size)
	local arrow = self.nodes.arrow

	if arrow then
		gui.set_size(arrow, vmath.vector3(100, 50+(200*size/360),0)*(self.zoom/4))
		gui.set_rotation(arrow, vmath.vector3(0,0, angle-90))
	end

	if self.attrs.knockback ~= size then self.attrs.knockback = size end
	if self.attrs.angle ~= angle then self.attrs.angle = angle end
end

function hitbox:add_knockback(angle, size)
	if not self.nodes.arrow then
		local arrow = gui.clone(gui.get_node("arrow"))

		gui.set_enabled(arrow, true)
		gui.set_parent(arrow, self.nodes.root)
		self.nodes.arrow = arrow
	end

	self:update_knockback(angle, size)
end

function hitbox:remove_knockback()
	if self.nodes.arrow then 
		gui.delete_node(self.nodes.arrow)
	end
	self.nodes.arrow = nil
end

function hitbox:on_message(message_id, message, sender)
	if message_id == hash("update_color") then
		local color = {
			fill = const.HITBOX_COLORS[message.type],
			border = const.HITBOX_BORDER_COLORS[message.type]
		}
		self:set_color(color)
	end

	if message_id == hash("add_knockback") then
		self:add_knockback(message.angle, message.knockback)
	end

	if message_id == hash("update_knockback") then
		self:update_knockback(message.angle, message.knockback)
	end

	if message_id == hash("remove_knockback") then
		self:remove_knockback()
	end
end

function hitbox:to_table()
	local data = {
		x_offset=math.floor(self.pos.x), 
		y_offset=math.floor(self.pos.y),
		width=math.floor(self.bounds.x),
		height=math.floor(self.bounds.y),
		hitbox_type=self.attrs.hitbox_type or "hurtbox",
	}

	if self.attrs.hitbox_type == "hitbox" then
		if self.attrs.is_clashable then data.is_clashable = self.attrs.is_clashable end
		if self.attrs.is_collision then data.is_collision = self.attrs.is_collision end
		if self.attrs.knockback then data.knockback = self.attrs.knockback end
		if self.attrs.angle then data.knockback_angle = self.attrs.angle end
		if self.attrs.damage then data.damage = self.attrs.damage end
	end
	if self.attrs.duration then data.duration = self.attrs.duration end

	return data
end

return hitbox