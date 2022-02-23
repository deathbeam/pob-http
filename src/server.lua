local server = require "http.server"
local headers = require "http.headers"
local json = require "rapidjson"
local util = require "util"
local parser = require "parser"

function handle_request(sv, st)
	local rqh = st:get_headers()
	local rqm = rqh:get(':method')
	local path = rqh:get(':path') or '/'
	local rsh = headers.new()

	if rqm == 'HEAD' then
		rsh:append(':status','200')
		rsh:append('content-type','text/plain')
		st:write_headers(rsh, true)
		return
	end

	local parts = util.str_split(path, '/')

	if not parts or #parts < 2 then
		rsh:append(':status','404')
		rsh:append('content-type','text/plain')
		st:write_headers(rsh, false)
		st:write_chunk("Invalid URL "..path, true)
		return
	end

	local is_code = parts[1] == "code"
	local accountName = ""
	local characterName = ""

	if is_code then
		accountName = parts[2]
		characterName = parts[3]
	else
		accountName = parts[1]
		characterName = parts[2]
	end

	local ran, data, code = pcall(parser, accountName, characterName)

	if not ran then
		rsh:append(':status','500')
		rsh:append('content-type','text/plain')
		st:write_headers(rsh, false)
		st:write_chunk(data, true)
		return
	end

	rsh:append(':status','200')

	if is_code then
		rsh:append('content-type','text/plain')
		st:write_headers(rsh, false)
		st:write_chunk(code, true)
	else
		rsh:append('content-type','application/json')
		st:write_headers(rsh, false)
		st:write_chunk(json.encode(data, {sort_keys=true, empty_table_as_array=true}), true)
	end
end

local port = os.getenv("PORT") or 8000

local s = server.listen {
	host = '0.0.0.0',
	port = port,
	onstream = function (sv, st)
		ran, err = pcall(handle_request, sv, st)
		if not ran then
			print(err)
		end
	end
}

s:listen()
print("Listening on port "..port)
s:loop()
