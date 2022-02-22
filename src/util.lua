local request = require "http.request"

local M = {}

function M.str_split (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function M.fetch_contents(url)
  local headers, stream = assert(request.new_from_uri(url):go())
  local body = assert(stream:get_body_as_string())
  if headers:get ":status" ~= "200" then
    error(body)
  end
  return body
end

function M.is_array(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

function M.table_len(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function M.table_last(t)
  local len = M.table_len(t)
  local count = 0
  for key, value in pairs(t) do
    count = count + 1
    if count == len then
      return value
    end
  end

  return nil
end

return M
