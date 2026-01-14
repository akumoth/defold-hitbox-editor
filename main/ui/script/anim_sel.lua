local anim_sel =  {}

local frame_view_state = {"ALL", "NEW FRAME + HITBOX", "ONLY NEW FRAME", "ONLY W/HITBOX"}

function anim_sel:set_anim(name)
	for idx = 1, #self.frame_idx.buttons do
		self.druid:remove(self.frame_idx.buttons[idx])
	end

	for idx = 1, #self.frame_idx.grid.nodes do
		gui.delete_node(self.frame_idx.grid.nodes[idx])
	end

	self.frame_idx.buttons = {}
	self.frame_idx.grid:clear()
	
	self.selected = name

	local cur_img
	for idx, img in pairs(self.atlas[name].spr) do
		local continue = false
		if idx ~= 1 then
			if self.frame_view_state == 2 or self.frame_view_state == 4 then
				if self.hitboxes[name] and self.hitboxes[name][idx] then
					if next(self.hitboxes[name][idx]) ~= nil and next(self.hitboxes[name][idx]) ~= "attrs" then
						continue = true
					end
				end
			end
			if self.frame_view_state == 2 or self.frame_view_state == 3 then
				if cur_img ~= img then
					continue = true
				end
			end
			if self.frame_view_state == 1 then
				continue = true
			end
		else
			continue = true
		end

		if cur_img ~= img then
			cur_img = img
		end

		if continue then		
			local node = gui.clone_tree(gui.get_node("frame_idx_but"))
			local root = node.frame_idx_but
			local text = node.num

			gui.set_text(text, idx)

			gui.set_enabled(root, true)
			self.frame_idx.grid:add(root)
			table.insert(self.frame_idx.buttons, self.druid:new_button(root, function () msg.post(".", "display_frame", {idx=idx}) end))
		end
	end
	msg.post(".", "display_frame", {idx=next(self.frame_idx.buttons)})
end

function anim_sel:set_nodes()
	for idx = 1, #self.buttons do
		self.druid:remove(self.buttons[idx])
	end

	for idx = 1, #self.view.nodes do
		gui.delete_node(self.view.nodes[idx])
	end

	self.view:clear()

	for name, anim in pairs(self.atlas) do

		local node = gui.clone_tree(gui.get_node("anim_sel_but"))

		local root = node.anim_sel_but
		local text = node.name

		gui.set_text(text, name)	

		gui.set_enabled(root, true)
		self.view:add(root)
		table.insert(self.buttons, self.druid:new_button(root, function () 
			msg.post(".", "set_anim", {name=name})
		end))
	end
	return
end

function anim_sel:change_frame_view(state, hitboxes)
	self.frame_view_state = state
	if self.selected then
		self:set_anim(self.selected)
	end
end

function anim_sel:init(druid, atlas, hitboxes)
	self.druid = druid
	
	self.view = druid:new_grid("anim_sel_content", "anim_sel_but", 1)
	self.scroll = druid:new_scroll("anim_sel_view", "anim_sel_content")
	self.scroll:bind_grid(self.view)

	self.buttons = {}
	
	self.frame_idx = {}
	self.frame_idx.grid = druid:new_grid("frame_idx_content", "frame_idx_but", 8)
	self.frame_idx.scroll = druid:new_scroll("frame_idx_view", "frame_idx_content")
	self.frame_idx.scroll:bind_grid(self.frame_idx.grid)
	
	self.frame_idx.buttons = {}

	self.frame_view_state = 1
	
	self.atlas = atlas
	self.hitboxes = hitboxes
end


anim_sel.colors = {
	INACTIVE = vmath.vector4(125/255, 125/255, 125/255, 1),
	STARTUP = vmath.vector4(37/255, 195/255, 95/255, 1),
	ACTIVE = vmath.vector4(255/255, 43/255, 0, 1),
	RECOVERY = vmath.vector4(0, 105/255, 255/255, 1)
}

function anim_sel:update_colors(frames)
	for idx, value in pairs(self.frame_idx.grid.nodes) do
		if frames[idx] and next(frames[idx].attrs) ~= nil then
			local node
			local node_tree = gui.get_tree(value)
			
			for _, _value in pairs(node_tree) do
				if gui.get_type(_value) ~= gui.TYPE_TEXT and gui.get_size(_value) == gui.get_size(gui.get_node("frame_idx")) then
					node = _value
					break
				end
			end
			
			if frames[idx].attrs.state then
				gui.set_color(node, self.colors[frames[idx].attrs.state])
			end
		end
	end
end

return anim_sel