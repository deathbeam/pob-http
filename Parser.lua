dofile('HeadlessWrapper.lua')

local request = require "http.request"

function fetch_contents(url)
  local headers, stream = assert(request.new_from_uri(url):go())
  local body = assert(stream:get_body_as_string())
  if headers:get ":status" ~= "200" then
    error(body)
  end
  return body
end

function to_json(data)
  local result = {}

  for key, value in pairs(data) do
    if type(value) == "string" then
      value = '"'..value..'"'
    end
    if type(value) == "table" then
      value = to_json(value)
    end

    table.insert(result, string.format("\"%s\":%s", key, value))
  end

  -- get simple json string
  result = "{" .. table.concat(result, ",") .. "}"
  return result
end

function get_character_data(accountName, characterName)
  print("Loading character "..characterName.." for account "..accountName)
  local itemsJson = fetch_contents("https://www.pathofexile.com/character-window/get-items?accountName="..accountName.."&character="..characterName)
  local passiveTreeJson = fetch_contents("https://www.pathofexile.com/character-window/get-passive-skills?accountName="..accountName.."&character="..characterName)
  loadBuildFromJSON(itemsJson, passiveTreeJson)
  build.mainSocketGroup = 3
  build.mainActiveSkill = 1
  build.itemsTab.slots["Flask 1"].active = true
  build.itemsTab.slots["Flask 2"].active = true
  build.itemsTab.slots["Flask 3"].active = true
  build.itemsTab.slots["Flask 4"].active = true
  build.itemsTab.slots["Flask 5"].active = true
  runCallback("OnFrame")

  out = build.calcsTab.mainOutput
  out["MainSkill"] = build.skillsTab.socketGroupList[build.mainSocketGroup].displaySkillList[build.mainActiveSkill].activeEffect.grantedEffect.name
  return out
end

characterName = characterName or arg[1]
accountName = accountName or arg[2]

local data = get_character_data(accountName, characterName)
return to_json(data)
