local anim_sel =  {}
local tbl_utils = require('main.utils.table_utils')

local frame_view_state = {"ALL", "NEW FRAME + HITBOX", "ONLY NEW FRAME", "ONLY W/HITBOX"}

function anim_sel:set_anim(name, hitboxes)
	for idx = 1, #self.frame_idx.buttons do
		self.druid:remove(self.frame_idx.buttons[idx])
	end

	for idx = 1, #self.frame_idx.grid.nodes do
		gui.delete_node(self.frame_idx.grid.nodes[idx])
	end

	self.frame_idx.buttons = {}
	self.frame_idx.grid:clear()
	
	self.selected = name

	local frame_attr_tbl = {}
	
	local cur_img
	for idx, img in pairs(self.atlas[name].spr) do
		local continue = false
		local bg = {
			pencil = false,
			attr = false,
			hitbox = false
		}
		-- filter depending on frame state (always have at least 1 frame to avoid editor borking)
		if idx ~= 1 then
			if self.frame_view_state == 2 or self.frame_view_state == 4 then
				if hitboxes[name] and hitboxes[name][idx] ~= nil then
					if not tbl_utils:is_empty(hitboxes[name][idx]) then
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

		-- put down background for icons
		if cur_img ~= img then
			cur_img = img
			bg.pencil = true
		end

		if hitboxes[name] and hitboxes[name][idx] then
			for k, v in pairs(hitboxes[name][idx]) do
				if k == "attrs" then
					for attr_name, attr in pairs(v) do
						if frame_attr_tbl[attr_name] then
							if frame_attr_tbl[attr_name] ~= attr then
								frame_attr_tbl[attr_name] = attr
								bg.attr = true
							end
						else
							frame_attr_tbl[attr_name] = attr
							bg.attr = true
						end
					end
				else
					bg.hitbox = true
				end
			end
		end
		
		if continue then		
			local node = gui.clone_tree(gui.get_node("frame_idx_but"))
			local root = node.frame_idx_but
			local text = node.num

			gui.set_text(text, idx)

			gui.set_enabled(root, true)
			self.frame_idx.grid:add(root)

			for k, v in pairs(bg) do
				if bg[k] then
					gui.set_visible(node["frame_idx_" .. k .. "_bg"], true)
				end
			end
			
			table.insert(self.frame_idx.buttons, self.druid:new_button(root, function () msg.post(".", "display_frame", {idx=idx}) end))
		end
	end
	msg.post(".", "display_frame", {idx=next(self.frame_idx.buttons), ignore_set_attr=true})
end

function anim_sel:set_nodes()
	for idx = 1, #self.buttons do
		self.druid:remove(self.buttons[idx])
	end

	for idx = 1, #self.view.nodes do
		gui.delete_node(self.view.nodes[idx])
	end

	self.view:clear()

	local sorted_atlas_keys = tbl_utils.get_sorted_keys(self.atlas)
		
	for i=1, #sorted_atlas_keys do

		local node = gui.clone_tree(gui.get_node("anim_sel_but"))

		local root = node.anim_sel_but
		local text = node.name

		gui.set_text(text, sorted_atlas_keys[i])	

		gui.set_enabled(root, true)
		self.view:add(root)
		table.insert(self.buttons, self.druid:new_button(root, function () 
			msg.post(".", "set_anim", {name=sorted_atlas_keys[i]})
		end))
	end
	return
end

function anim_sel:change_frame_view(state)
	self.frame_view_state = state
	if self.selected then
		msg.post(".", "set_anim", {name=self.selected})
	end
end

function anim_sel:init(druid, atlas)
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
end


anim_sel.colors = {
	INACTIVE = vmath.vector4(125/255, 125/255, 125/255, 1),
	STARTUP = vmath.vector4(37/255, 195/255, 95/255, 1),
	ACTIVE = vmath.vector4(255/255, 43/255, 0, 1),
	RECOVERY = vmath.vector4(0, 105/255, 255/255, 1),
	NULL = vmath.vector4(128/255, 153/255, 255/255, 1)
}

function anim_sel:update_colors(frames, idx)
	for _, value in pairs(self.frame_idx.grid.nodes) do
		local node
		local f_idx
		local node_tree = gui.get_tree(value)

		for _, _value in pairs(node_tree) do
			if gui.get_type(_value) == gui.TYPE_TEXT then
				f_idx = tonumber(gui.get_text(_value))
				if idx and f_idx ~= idx then break end
			end
			
			if gui.get_type(_value) ~= gui.TYPE_TEXT and gui.get_size(_value) == gui.get_size(gui.get_node("frame_idx")) and gui.get_texture(_value) == hash("") then
				node = _value
			end
		end

		if not (idx and f_idx ~= idx) then
			if frames[f_idx] then
				if next(frames[f_idx].attrs) ~= nil and frames[f_idx].attrs.state then
					gui.set_color(node, self.colors[frames[f_idx].attrs.state])
				else
					gui.set_color(node, self.colors.NULL)
				end
			end
		end
	end
end

function anim_sel:update_bg(frame, bg_tbl)
	for _, value in pairs(self.frame_idx.grid.nodes) do
		local node_tree = gui.get_tree(value)
		local idx

		local bg_nodes = {
			pencil = 0,
			attr = 0,
			hitbox = 0
		}
		for _, _value in pairs(node_tree) do
			if gui.get_type(_value) == gui.TYPE_TEXT then
				idx = tonumber(gui.get_text(_value))
				if frame ~= idx then
					break
				end
			end

			for k in pairs(bg_nodes) do
				if gui.get_type(_value) ~= gui.TYPE_TEXT and gui.get_texture(_value) == hash(k .. "_bg") then
					bg_nodes[k] = _value
				end
			end
		end

		if frame == idx then
			for k,v in pairs(bg_tbl) do
				gui.set_visible(bg_nodes[k], v)
				break
			end
		end
	end
end

return anim_sel