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

function prepare_build(build)
  local longestLink = 0
  local socketGroupIndex = 0
  local gemIndex = 1

  -- find main skill
  for k,v in pairs(build.skillsTab.socketGroupList) do
    if v.enabled and #v.gemList >= longestLink then
      longestLink = #v.gemList
      socketGroupIndex = k
    end
  end

  build.mainSocketGroup = socketGroupIndex
  build.mainActiveSkill = gemIndex

  -- activate all flasks
  build.itemsTab.slots["Flask 1"].active = true
  build.itemsTab.slots["Flask 2"].active = true
  build.itemsTab.slots["Flask 3"].active = true
  build.itemsTab.slots["Flask 4"].active = true
  build.itemsTab.slots["Flask 5"].active = true

  -- configure stuff
  build.calcsTab.input["enemyIsBoss"] = "Sirus"
  build.calcsTab.input["multiplierNearbyEnemies"] = 1
  build.calcsTab.input["multiplierWitheredStackCount"] = 15
  build.calcsTab.input["buffAlchemistsGenius"] = true
  build.calcsTab.input["infusedChannelingInfusion"] = true
  build.calcsTab.input["buffLifetap"] = true
  build.calcsTab.input["BrandsAttachedToEnemy"] = true
  build.calcsTab.input["useChallengerCharges"] = true
  build.calcsTab.input["useBlitzCharges"] = true
  build.calcsTab.input["multiplierGaleForce"] = 10
  build.calcsTab.input["multiplierRage"] = 100
  build.calcsTab.input["conditionLeeching"] = true
  build.calcsTab.input["conditionCritRecently"] = true
  build.calcsTab.input["conditionEnemyTaunted"] = true
  build.calcsTab.input["conditionEnemyMaimed"] = true
  build.calcsTab.input["conditionEnemyChilled"] = true
  build.calcsTab.input["conditionEnemyIgnited"] = true
  build.calcsTab.input["intensifyIntensity"] = 10
  build.calcsTab.input["plagueBearerState"] = "INF"

  for k, v in pairs(build.calcsTab.input) do
    build.configTab.input[k] = v
  end

  -- finishing touches
  build.configTab:ImportCalcSettings()
  build.buildFlag = true
  build:OnFrame({})

  out = build.calcsTab.mainOutput
  out["MainSkill"] = build.skillsTab.socketGroupList[build.mainSocketGroup].displaySkillList[build.mainActiveSkill].activeEffect.grantedEffect.name
  return out
end

function get_character_data(accountName, characterName)
  print("Loading character "..characterName.." for account "..accountName)
  local itemsJson = fetch_contents("https://www.pathofexile.com/character-window/get-items?accountName="..accountName.."&character="..characterName)
  local passiveTreeJson = fetch_contents("https://www.pathofexile.com/character-window/get-passive-skills?accountName="..accountName.."&character="..characterName)
  local build = LoadModule("Modules/Build")
  build:Init(false, "")
  build:OnFrame({})
	local charData = build.importTab:ImportItemsAndSkills(itemsJson)
	build.importTab:ImportPassiveTreeAndJewels(passiveTreeJson, charData)
  return prepare_build(build)
end

return function(accountName, characterName)
  return to_json(get_character_data(accountName, characterName))
end
