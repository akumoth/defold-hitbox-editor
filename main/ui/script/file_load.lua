local file_load = {}
local imagesize = require('main.utils.imagesize.imagesize')

local function is_in_table(key, tbl)
	for k,v in pairs(tbl) do
		if k == key then
			return true
		end
	end
	return false
end

local function deepcompare(t1, t2, compare_mt, ignore_keys)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not ignore_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
		if not (ignore_keys and is_in_table(k1, ignore_keys)) then 
			local v2 = t2[k1]
			if v2 == nil or not deepcompare(v1,v2) then return false end
		end
	end
	for k2,v2 in pairs(t2) do
		if not (ignore_keys and is_in_table(k2, ignore_keys)) then
			local v1 = t1[k2]
			if v1 == nil or not deepcompare(v1,v2) then return false end
		end
	end
	return true
end

local function is_empty(tbl)
	if type(tbl) == "table" then
		for k,v in pairs(tbl) do
			if type(v) == "table" then
				if #v == 0 then
					return true
				else
					if not is_empty(v) then return false end
				end
			else
				return false
			end
		end
	end
	return true
end

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

function file_load:save_hitbox_data(hitboxes)
	local exported_list = {}
	
	for anim_name, anim in pairs(hitboxes) do
		local ex_anim = anim_name
		exported_list[ex_anim] = {}

		self.save_attrs(exported_list[ex_anim], anim.attrs, {"extension"}, {function (attr) return 'hash("' .. attr .. '")' end})
		
		for frame_idx, frame in pairs(anim) do
			if frame_idx ~= "attrs" then
				if next(frame) ~= nil and ((not anim[frame_idx-1]) or (not deepcompare(anim[frame_idx], anim[frame_idx-1], true))) then
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
		luatbl:write("local framedata = {}" .. ln .. ln .. "local FRAME_STATUS = { INACTIVE = -1, STARTUP = 0, ACTIVE = 1, RECOVERY = 2 }" .. ln .. ln)
		for anim_name, anim in pairs(exported_list) do
			luatbl:write('framedata[hash("' .. anim_name .. '")] = {' .. ln)

			if anim.attrs then
				for attr_name, attr in pairs(anim.attrs) do
					luatbl:write(lt .. attr_name .. " = " .. attr .. "," .. ln)
				end
			end
			
			for	frame_idx, frame in pairs(anim) do
				if (type(frame) == "table" and not (
					type(frame_idx) == "number" and 
					anim[frame_idx-1] and 
					not (frame.hitbox_data and next(frame.hitbox_data)) and
					deepcompare(frame, anim[frame_idx-1], true, {"hitbox_data"})
				) and not is_empty(frame)) then 
					luatbl:write(lt .. "[" .. tostring(frame_idx) .. "] = {" .. ln)
					print( #next(frame))
					
					for name, attr in pairs(frame) do
						if name == "hitbox_data" and next(frame[name]) ~= nil then
							luatbl:write(lt .. lt .. "hitbox_data = {" .. ln)
							for idx, hitbox in ipairs(frame.hitbox_data) do
								luatbl:write(lt .. lt .. lt .. "{")
								for _name, data in pairs(hitbox) do
									if (data~=0 and not string.find(_name, "offset")) and data then
										luatbl:write(_name .. "=" .. tostring(data) .. ",")
									end
								end
								luatbl:write("}," .. ln)
							end
							luatbl:write(lt .. lt .. "}" .. ln)
						elseif type(frame_idx) == "number" and type(attr) ~= "table" then
							if not (anim[frame_idx-1] and anim[frame_idx-1][name] and attr == anim[frame_idx-1][name]) then
								luatbl:write(lt .. lt .. name .. " = " .. attr .. "," .. ln)
							end
						end
					end

					luatbl:write(lt .. '}' .. ln)
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