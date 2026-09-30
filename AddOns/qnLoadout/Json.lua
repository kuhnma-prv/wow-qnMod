-- qnLoadout: JSON writer for the export.
-- Objects keep their key order: ns.JsonObject({ { key, value }, ... }); other tables are arrays.
-- Keys with the value nil are left out.

local _, ns = ...

local OBJECT = {}

function ns.JsonObject(pairsList)
	return setmetatable(pairsList, OBJECT)
end

local ESCAPES = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function String(s)
	return '"' .. s:gsub('[%c"\\]', function(c)
		return ESCAPES[c] or ("\\u%04x"):format(c:byte())
	end) .. '"'
end

-- indent: text per level for readable output (nil = compact, one line)
local function Write(v, indent, level)
	local t = type(v)
	if t == "string" then
		return String(v)
	elseif t == "number" then
		return v == math.floor(v) and ("%d"):format(v) or tostring(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t ~= "table" then
		return "null"
	end
	local isObject = getmetatable(v) == OBJECT
	local items = {}
	if isObject then
		for _, pair in ipairs(v) do
			if pair[2] ~= nil then
				items[#items + 1] = String(pair[1]) .. (indent and ": " or ":") .. Write(pair[2], indent, level + 1)
			end
		end
	else
		for _, item in ipairs(v) do
			items[#items + 1] = Write(item, indent, level + 1)
		end
	end
	local open, close = isObject and "{" or "[", isObject and "}" or "]"
	if #items == 0 then
		return open .. close
	end
	if not indent then
		return open .. table.concat(items, ",") .. close
	end
	-- objects without nested tables (e.g. one numpad key) stay on one line
	local flat = isObject
	if flat then
		for _, pair in ipairs(v) do
			if type(pair[2]) == "table" then
				flat = false
			end
		end
	end
	if flat then
		return open .. " " .. table.concat(items, ", ") .. " " .. close
	end
	local pad, inner = indent:rep(level), indent:rep(level + 1)
	return open .. "\n" .. inner .. table.concat(items, ",\n" .. inner) .. "\n" .. pad .. close
end

function ns.ToJson(v, indent)
	return Write(v, indent, 0)
end
