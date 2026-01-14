local class = require('main.utils.class')
local attr_table = class.new_class({})

attr_table.frame_state = {"INACTIVE", "STARTUP", "ACTIVE", "RECOVERY"}
attr_table.frame_view_state = {"ALL", "NEW FRAME + HITBOX", "ONLY NEW FRAME", "ONLY W/HITBOX"}

function attr_table.new(druid, prefix)
	assert(druid)
	if not prefix then prefix = "" end
	
	local data = {
		druid = druid
	}
	data.root = gui.get_node(prefix .. "attr_table")

	data.prefix = prefix
	
	data.view = druid:new_grid(prefix .. "attr_content", "property", 1)
	data.scroll = druid:new_scroll(prefix .. "attr_table", prefix .. "attr_content")
	data.scroll:bind_grid(data.view)
	data.scroll:set_horizontal_scroll(false)

	data.attrs = {}
	data.attr_nodes = {}
	
	local self = setmetatable(data, attr_table)
	self._index = self
	return self
end

function attr_table:create_attr(attr)
	assert(attr)
	assert(attr.name)
	assert(attr.type)

	if not attr.callback then attr.callback = function (value) end end
	
	local new = gui.clone_tree(gui.get_node(self.prefix .. "property"))

	local root = new[self.prefix .. "property"]
	local text = new[self.prefix .. "attr_text"]
	local content = new[self.prefix .. "property_content"]
	
	gui.set_text(text, attr.name)
	gui.set_enabled(root, true)
	
	local input
	
	if attr.type == "range" then
		if not attr.min then attr.min = 0 end
		
		if not attr.max then
			if attr.values then
				attr.max = #attr.values-1
			else
				assert(attr.max)
			end
		end

		local slider_nodes = gui.clone_tree(gui.get_node("slider"))

		gui.set_enabled(slider_nodes.slider, true)
		local size = gui.get_size(content)
		gui.set_parent(slider_nodes.slider, content, false)
		gui.set_position(slider_nodes.slider, vmath.vector3(size.x/2,0,0))

		gui.set_size(slider_nodes.slider_back, vmath.vector3(size.x, 5, 0))
		gui.set_size(slider_nodes.slider, vmath.vector3(size.x, 20, 0))

		gui.set_position(slider_nodes.slider_pin, vmath.vector3(-(size.x/2)+15, 0, 0))
		
		local slider_textedit = self.druid:new_input(slider_nodes.slider_value, slider_nodes.slider_value_text)
		
		local slider = self.druid:new_slider(slider_nodes.slider_pin, vmath.vector3(size.x/2,0,0), 
			function (_, value) 
				if attr.values then
					gui.set_text(slider_nodes.slider_value_text, attr.values[(value*attr.max)+1])
				else
					slider_textedit:set_text(value*attr.max)
				end
				attr.callback(value)
			end
		)
		slider:set_input_node(slider_nodes.slider)
		
		if attr.max then
			local steps = {}
			for i=attr.min, attr.max do
				table.insert(steps,i/attr.max)
			end
			slider:set_steps(steps)
			slider:set(steps[attr.content or 1])
		end

		if not attr.values then 
			slider_textedit:set_allowed_characters("[%d]")
			slider_textedit.on_input_text:subscribe(function()
				local str = slider_textedit:get_text()
				if str.match(str, "^%d+$") then
					if tonumber(str) >= attr.min and tonumber(str) <= attr.max then
						slider:set(str/attr.max)
					end
				end
				slider_textedit:set_text(slider.value*attr.max)
			end)
		else
			slider_textedit:set_allowed_characters("[]")
		end

		attr.default = attr.content or 0
		
		input = {
			slider = slider,
			text = text,
			text_edit = slider_textedit,
			max = attr.max,
			get_value = function ()
				if attr.values then 
					return attr.values[(slider.value*attr.max)+1]
				else
					return slider.value*attr.max
				end
			end,
			set_value = function (value)
				if attr.values then
					if type(value) == "string" then
						local i = 0

						for idx, str in ipairs(attr.values) do
							if str == value then
								i = idx-1
								break
							end
						end
						
						slider:set(i/attr.max)
						return
					end
				end
				slider:set(value/attr.max)
			end,
			values = attr.values
		}
	end

	if attr.type == "bool" then
		local checkbox_nodes = gui.clone_tree(gui.get_node("checkbox"))
		gui.set_enabled(checkbox_nodes.checkbox, true)
		gui.set_parent(checkbox_nodes.checkbox, content, false)

		gui.set_visible(checkbox_nodes.checkmark, attr.content or false)
		gui.set_position(checkbox_nodes.checkbox, vmath.vector3(gui.get_size(content).x/2, 0, 1))
		local button = self.druid:new_button(checkbox_nodes.checkbox, 
			function ()
				attr.callback((not gui.get_visible(checkbox_nodes.checkmark)))
				gui.set_visible(checkbox_nodes.checkmark, not gui.get_visible(checkbox_nodes.checkmark))
			end 
		)

		attr.default = attr.content or false
		
		input = {
			button = button,
			checkbox = checkbox_nodes.checkbox,
			checkmark = checkbox_nodes.checkmark,
			get_value = function ()
				return gui.get_visible(checkbox_nodes.checkmark)
			end,
			set_value = function (value)
				return gui.set_visible(checkbox_nodes.checkmark, value)
			end
		}
	end

	if attr.type == "text" then
		local text_edit_nodes = gui.clone_tree(gui.get_node("text_edit"))

		gui.set_enabled(text_edit_nodes.text_edit, true)
		gui.set_parent(text_edit_nodes.text_edit, content, false)
		gui.set_position(text_edit_nodes.text_edit, vmath.vector3(gui.get_size(content).x/2, 0, 1))

		gui.set_text(text_edit_nodes.text, attr.content or "")

		local size = gui.get_size(content)
		
		gui.set_size(text_edit_nodes.text_edit, vmath.vector3(size.x, 30, 0))
		gui.set_size(text_edit_nodes.text, vmath.vector3(size.x*2, 20, 0))

		local text_edit = self.druid:new_input(text_edit_nodes.text_edit, text_edit_nodes.text)
		text_edit.on_input_text:subscribe( 
			function ()
				attr.callback(text_edit.value)
			end
		)
		
		if attr.allowed then text_edit:set_allowed_characters(attr.allowed) end

		attr.default = attr.content or ""
		
		input = {
			text_edit = text_edit,
			get_value = function ()
				return text_edit:get_text()
			end,
			set_value = function (value)
				text_edit:set_text(value)
			end,
		}
	end
	
	self.attrs[attr.name] = {
			nodes = {
				root = root,
			text = text,
			content = content,
		},
		input =  input,
		type = attr.type,
		value = attr.content,
		default = attr.default
	}

	self.view:add(root)
end

function attr_table:init_attrs(attr_type)
	gui.set_enabled(self.root, true)

	if next(self.attrs) == nil then
		if attr_type == "hitbox" then
			self:create_attr({
				name="angle",
				type="range",
				content=1,
				max=360,
				callback= function (value)
					if self.attrs.angle and self.attrs.knockback then
						msg.post(".", "update_knockback", {angle = self.attrs.angle.input.get_value(), knockback = self.attrs.knockback.input.get_value()})
					end
				end
			})
			self:create_attr({
				name="knockback",
				type="range",
				content=1,
				max=200,
				callback= function (value)
					if self.attrs.angle and self.attrs.knockback then
						msg.post(".", "update_knockback", {angle = self.attrs.angle.input.get_value(), knockback = self.attrs.knockback.input.get_value()})
					end
				end
			})
			self:create_attr({
				name="duration",
				type="range",
				content=1,
				max=10
			})
			self:create_attr({
				name="is_hurtbox",
				type="bool",
				content=true,
				callback= function (value)
					msg.post(".", "update_color", {hurtbox = value})
					if self.attrs.angle and self.attrs.knockback then
						if value == false then
							msg.post(".", "add_knockback", {angle = self.attrs.angle.input.get_value(), knockback = self.attrs.knockback.input.get_value()})
						else
							msg.post(".", "remove_knockback")
						end
					end
				end
			})
			self:create_attr({
				name="is_player",
				type="bool",
				content=true
			})
			self:create_attr({
				name="is_clashable",
				type="bool",
				content=false
			})
			self:create_attr({
				name="is_collision",
				type="bool",
				content=false
			})
		end

		if attr_type == "anim" then
			self:create_attr({
				name="land_lag",
				type="text",
				content="",
				allowed="[%d]",
				callback = function (value)
					msg.post(".", "update_attr", {type="anim", name="land_lag", value=value})
				end
			})
			self:create_attr({
				name="extension",
				type="text",
				content="",
				callback = function (value)
					msg.post(".", "update_attr", {type="anim", name="extension", value=value})
				end
			})
		end

		if attr_type == "frame" then
			self:create_attr({
				name="state",
				type="range",
				values=self.frame_state,
				callback = function (value)
					if type(value) == "number" then
						local val_table = self.frame_state
						value = val_table[(value*(#self.frame_state-1))+1]
					end
					
					msg.post(".", "update_attr", {type="frame", name="state", value=value})
				end
			})
			self:create_attr({
				name="cancel_land",
				type="bool",
				content=false,
				callback = function (value)
					msg.post(".", "update_attr", {type="frame", name="cancel_land", value=value})
				end
			})
			self:create_attr({
				name="can_extend",
				type="bool",
				content=false,
				callback = function (value)
					msg.post(".", "update_attr", {type="frame", name="can_extend", value=value})
				end
			})
		end

		if attr_type == "editor" then
			self:create_attr({
				name="x_offset",
				type="text",
				content="0",
				allowed="[%-?%d+]",
				callback = function (value)
					msg.post(".", "update_attr", {type="editor", name="x_offset", value=value})
				end
			})
			self:create_attr({
				name="y_offset",
				type="text",
				content="0",
				allowed="[%-?%d+]",
				callback = function (value)
					msg.post(".", "update_attr", {type="editor", name="y_offset", value=value})
				end
			})
			self:create_attr({
				name="Frames to\ndisplay",
				type="range",
				values=self.frame_view_state,
				callback = function (value)
					if type(value) == "number" then
						local val_table = self.frame_view_state
						value = val_table[(value*(#self.frame_view_state-1))+1]
					end

					local idx

					for i=1, #self.frame_view_state do
						if self.frame_view_state[i] == value then
							idx = i
							break
						end
					end
					
					msg.post(".", "update_attr", {type="editor", name="frame_view_state", value=idx})
				end
			})
		end
	end

end

function attr_table:set_attrs(attrs)
	for name, value in pairs(self.attrs) do
		attrs[name] = self.attrs[name].input.get_value()
	end
end

function attr_table:update_attrs(attrs, default)
	if next(attrs) == nil and default == nil then
		for name, value in pairs(self.attrs) do
			self.attrs[name].input.set_value(self.attrs[name].default)
		end
	else
		for name, value in pairs(attrs or default) do
			if self.attrs[name] then
				self.attrs[name].input.set_value(value)
			end
		end
	end
end

return attr_table