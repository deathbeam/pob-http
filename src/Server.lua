local server = require "http.server"
local headers = require "http.headers"

function str_split (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function eval_isolated_file(filename, env)
    setmetatable ( env, { __index = _G } )
    local status, result = assert(pcall(setfenv(assert(loadfile(filename)), env)))
    setmetatable(env, nil)
    return result
end

function get_character_data(accountName, characterName)
    return eval_isolated_file("Parser.lua", {
            accountName=accountName,
            characterName=characterName
        })
end

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

    local parts = str_split(path, '/')
    local accountName = parts[1]
    local characterName = parts[2]
    local ran, data = pcall(get_character_data, accountName, characterName)
    if not ran then
        rsh:append(':status','500')
        rsh:append('content-type','text/plain')
        st:write_headers(rsh, false)
        st:write_chunk(data, true)
        return
    end

    rsh:append(':status','200')
    rsh:append('content-type','application/json')
    st:write_headers(rsh, false)
    st:write_chunk(data, true)
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
