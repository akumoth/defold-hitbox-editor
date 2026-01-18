local file_load = {}
local imagesize = require('main.utils.imagesize.imagesize')
local tbl_utils = require('main.utils.table_utils')
local const = require("main.ui.script.constants")

function file_load:load_atlas(atlas_file)
	local root_folder

	local file = io.open(atlas_file)
	local file_iter = file:lines()

	local animname

	self.atlas = {}
	
	for line in file_iter do
		if string.match(line, "id: ") then
			animname = string.gmatch(line, '"(.-)"')()
			self.atlas[animname] = { spr = {} }
		elseif string.match(line, "image: ") then
			local img = string.gmatch(line, '"(.-)"')()

			if root_folder == nil then
				local root = string.gmatch(img, "/%a+/")()
				root_folder = string.sub(self.selected_file, 1, string.find(self.selected_file, root)-1)
			end

			self.atlas[animname].spr[#self.atlas[animname].spr+1] = root_folder .. img
		elseif string.find(line, "pivot") then
			local pivot = string.gmatch(line, '(%d?%..*)')()
			if not self.atlas[animname].pivot then
				self.atlas[animname].pivot = vmath.vector3()
			end
			self.atlas[animname].pivot[string.gmatch(line, '_(%w)')()] = pivot
		end
		
	end

	table.sort(self.atlas, tbl_utils.sort_alphabetical)
end

function file_load.get_new_file() 
	local _, file = diags.open("atlas")
	if file:match("^.+(%..+)$") ~= ".atlas" then return end
	file_load.selected_file = file

	file_load:load_atlas(file)
	msg.post(".", "file_loaded")
end

function file_load:init(druid)
	self.button = druid:new_button("load_atlas", self.get_new_file)	
end

function file_load:load_hitbox_data(hitboxes)
	local _, file = diags.open("lua")
	local f, err = loadfile(file)
	if not err then
		local tbl = f()
		return tbl
	else
		print(err)
	end
end

function file_load.save_attrs(list, attrs, matches, callbacks)
	for attr_name, a in pairs(attrs) do
		local attr = tostring(a)
		local match
		for idx, name in ipairs(matches) do
			if attr_name == name then
				match = idx
			end
		end
		
		if match then
			list[attr_name] = callbacks[match](attr)
		elseif string.match(tostring(attr), "^%d+$") then
			list[attr_name] = tostring(attr)
		elseif string.match(attr, "^%w+$") then
			list[attr_name] = attr
		end
	end
end

function file_load:save_hitbox_data(hitboxes, owner)
	local exported_list = {}
	
	for anim_name, anim in pairs(hitboxes) do
		local ex_anim = anim_name
		exported_list[ex_anim] = {}

		self.save_attrs(exported_list[ex_anim], anim.attrs, {"extension"}, {function (attr) return 'hash("' .. attr .. '")' end})
		
		for frame_idx, frame in pairs(anim) do
			if frame_idx ~= "attrs" then
				if next(frame) ~= nil and ((not anim[frame_idx-1]) or (not tbl_utils:deepcompare(anim[frame_idx], anim[frame_idx-1], true))) then
					exported_list[ex_anim][frame_idx] = {}

					self.save_attrs(exported_list[ex_anim][frame_idx], frame.attrs, {"state"}, {function (attr) return "FRAME_STATUS." .. attr end})

					exported_list[ex_anim][frame_idx].hitbox_data = {}
					
					for hitbox_idx, hitbox in pairs(frame) do
						if hitbox_idx ~= "attrs" then 
							table.insert(exported_list[ex_anim][frame_idx].hitbox_data, hitbox)
						end
					end
				end
			end
		end
	end

	local _, file = diags.save("lua")
	local lt, ln = "	", "\n"
	local luatbl,err = io.open( file, "wb" )

	if luatbl ~= nil then
		luatbl:write("local framedata = {}" .. ln .. ln .. "local FRAME_STATUS = { INACTIVE = -1, STARTUP = 0, ACTIVE = 1, RECOVERY = 2 }" .. ln .. ln .. "framedata.is_player = " .. (owner == "player" and "true" or "false") .. ln .. ln)

		local sorted_exported_keys = tbl_utils.get_sorted_keys(exported_list)

		for i=1, #sorted_exported_keys do
			local anim_name = sorted_exported_keys[i]
			local anim = exported_list[anim_name]
			
			luatbl:write('framedata[hash("' .. anim_name .. '")] = {' .. ln)

			local frame_attr_tbl = {}
			for	frame_idx, frame in pairs(anim) do
				if (type(frame) == "table" and not tbl_utils:is_empty(frame)) then 
					luatbl:write(lt .. "[" .. tostring(frame_idx) .. "] = {" .. ln)
					for name, attr in pairs(frame) do
						local continue = false
						
						if frame_attr_tbl[name] then
							if type(attr) == "table" then
								if not tbl_utils:deepcompare(frame_attr_tbl[name], attr) then
									frame_attr_tbl[name] = attr
									continue = true
								end
							else
								if frame_attr_tbl[name] ~= attr then
									frame_attr_tbl[name] = attr
									continue = true
								end
							end
						else
							frame_attr_tbl[name] = attr
							continue = true
						end

						if continue then
							if name == "hitbox_data" and next(frame[name]) ~= nil then
								luatbl:write(lt .. lt .. "hitbox_data = {" .. ln)
								for idx, hitbox in ipairs(frame.hitbox_data) do
									luatbl:write(lt .. lt .. lt .. "{")
									for _name, data in pairs(hitbox) do
										if data~=0 and data then
											if _name == "hitbox_type" then
												data = const.HITBOX_TYPE_IDX[data]
											end
											
											luatbl:write(_name .. "=" .. tostring(data) .. ",")
										end
									end
									luatbl:write("}," .. ln)
								end
								luatbl:write(lt .. lt .. "}," .. ln)
							elseif type(frame_idx) == "number" and type(attr) ~= "table" then
								luatbl:write(lt .. lt .. name .. " = " .. attr .. "," .. ln)
							end
						end
					end

					luatbl:write(lt .. '},' .. ln)
				elseif type(frame) ~= "table" then
					luatbl:write(lt .. frame_idx .. " = " .. frame .. "," .. ln)
				end
			end
			luatbl:write('}' .. ln .. ln)
		end

		luatbl:write('return framedata')
	end


end

function file_load:create_buttons(druid)
	gui.set_enabled(gui.get_node("load_hitbox_data"), true)
	self.hitbox_load = druid:new_button("load_hitbox_data", function ()
		msg.post(".", "load_hitbox_data")
	end)

	gui.set_enabled(gui.get_node("save_hitbox_data"), true)
	self.hitbox_load = druid:new_button("save_hitbox_data", function ()
		msg.post(".", "save_hitbox_data")
	end)
end

return file_load