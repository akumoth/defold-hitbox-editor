local tbl_utils = {}

function tbl_utils.is_in_table(key, tbl)
	for k,v in pairs(tbl) do
		if k == key then
			return true
		end
	end
	return false
end

function tbl_utils:deepcompare(t1, t2, compare_mt, ignore_keys)
	local ty1 = type(t1)
	local ty2 = type(t2)
	if ty1 ~= ty2 then return false end
	-- non-table types can be directly compared
	if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(t1)
	if not compare_mt and mt and mt.__eq then return t1 == t2 end
	for k1,v1 in pairs(t1) do
		if not (ignore_keys and self.is_in_table(k1, ignore_keys)) then 
			local v2 = t2[k1]
			if v2 == nil or not self.deepcompare(v1,v2) then return false end
		end
	end
	for k2,v2 in pairs(t2) do
		if not (ignore_keys and self.is_in_table(k2, ignore_keys)) then
			local v1 = t1[k2]
			if v1 == nil or not self.deepcompare(v1,v2) then return false end
		end
	end
	return true
end

function tbl_utils:is_empty(tbl, seen)
	seen = seen or {}
	
	if type(tbl) ~= "table" then
		return false
	elseif type(tbl) == "table" then
		if seen[tbl] then
			return true
		end
		seen[tbl] = true
			
		for k,v in pairs(tbl) do
			if not self:is_empty(v) then return false end
		end
	end
	
	return true
end

function tbl_utils.sort_alphabetical(a, b)
	return a:lower() < b:lower()
end

function tbl_utils.get_sorted_keys(tbl)
	local sorted_tbl = {}

	for k in pairs(tbl) do
		table.insert(sorted_tbl, k)
	end

	table.sort(sorted_tbl)

	return sorted_tbl
end

function tbl_utils.len(tbl)
	local incr=0
	for k in pairs (tbl) do
		incr=incr+1
	end
	return incr
end

-- goes backwards through a indexed array of hash tables to get the values set closest to the supplied idx for each key-value pair in the hash tables
function tbl_utils:return_defaults(tbl, start_idx, key, max_size)
	local defaults = {}

	if start_idx == 1 then return defaults end
	
	for i=start_idx-1, 1, -1 do
		if tbl[i] and next(tbl[i][key] or tbl[i]) ~= nil then
			for k,v in pairs(tbl[i][key]) do
				if defaults[k] == nil then defaults[k] = v end
			end
		end

		if max_size and self.len(defaults) == max_size then
			break
		end
	end

	return defaults
end


return tbl_utils