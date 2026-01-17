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

function tbl_utils:is_empty(tbl)
	if type(tbl) == "table" then
		for k,v in pairs(tbl) do
			if type(v) == "table" then
				if #v == 0 then
					return true
				else
					if not self.is_empty(v) then return false end
				end
			else
				return false
			end
		end
	end
	return true
end

function tbl_utils.sort_alphabetical(a, b)
	return a:lower() < b:lower()
end

return tbl_utils