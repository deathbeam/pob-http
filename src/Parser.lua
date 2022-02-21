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

function is_array(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

function table_len(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function table_last(t)
  local len = table_len(t)
  local count = 0
  for key, value in pairs(t) do
    count = count + 1
    if count == len then
      return value
    end
  end

  return nil
end

function simplify_pair(out_key, key, body, out)
  if table_len(body) == 2 and body[key] ~= nil then
    if type(out[out_key]) ~= "table" then
      out[out_key] = {}
    end

    out[out_key][body[key]] = table_last(body)
    return true
  end

  return false
end

function normalize_build_data(input, out)
  if type(input) ~= "table" then
    out["value"] = input
    return
  end

  local key = nil
  local body = {}

  for k, v in pairs(input) do
    if k == "elem" then
      key = v
    elseif k == "attrib" then
      for k2, v2 in pairs(v) do
        if not k2:find("^active") and v2 ~= nil and v2 ~= "" and v2 ~= "nil" then
          body[k2] = v2
        end
      end
    elseif k then
      normalize_build_data(v, body, k)
    end
  end

  if key == "PathOfBuilding" then
    for k, v in pairs(body) do
      out[k] = v
    end
    return
  end

  if key == "Calcs" or key == "TreeView" or key == "Import" or key == "Section" or key == "Config" or key == "Notes" or key == "ItemSet" then
    return
  end

  if table_len(body) == 1 and (body["value"] ~= nil or body["Spec"] ~= nil) then
    out[key] = table_last(body)
    return
  end

  if body["Skill"] ~= nil then
    out[key] = body["Skill"]
    return
  end

  should_return = simplify_pair(key, "name", body, out)
  should_return = simplify_pair(key, "id", body, out) or should_return
  should_return = simplify_pair(key, "stat", body, out) or should_return
  should_return = simplify_pair(key, "nodeId", body, out) or should_return

  if should_return then
    return
  end

  if out[key] ~= nil then
    if not is_array(out[key]) then
      out[key] = {out[key]}
    end
    table.insert(out[key], body)
  else
    out[key] = body
  end
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
  -- out["MainSkill"] = build.skillsTab.socketGroupList[build.mainSocketGroup].displaySkillList[build.mainActiveSkill].activeEffect.grantedEffect.name

  out_t = { elem = "PathOfBuilding" }

  do
    local node = { elem = "Build" }
    build:Save(node)
    table.insert(out_t, node)
  end
  for elem, saver in pairs(build.savers) do
    local node = { elem = elem }
    saver:Save(node)
    table.insert(out_t, node)
  end

  out_n = {}
  normalize_build_data(out_t, out_n)
  return out_n
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
  return get_character_data(accountName, characterName)
end
