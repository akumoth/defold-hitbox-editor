local M = { }

function M.new_class(typetbl)
	typetbl.__index = typetbl
	setmetatable(typetbl, {
		__call = function(cls, ...)
			return cls.new(...)
		end,
	})
	return typetbl
end

function M.empty_fn(...) end

return M