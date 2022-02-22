dofile('HeadlessWrapper.lua')

local zlib = require "zlib"
local util = require "util"

function simplify_pair(out_key, key, body, out)
  if util.table_len(body) == 2 and body[key] ~= nil then
    if type(out[out_key]) ~= "table" then
      out[out_key] = {}
    end

    out[out_key][tostring(body[key])] = util.table_last(body)
    return true
  end

  return false
end

function parse_value(val)
  if type(val) ~= "string" then
    return val
  end

  if val == "true" then
    return true
  end

  if val == "false" then
    return false
  end

  if val ~= "INF" and tonumber(val) then
    return tonumber(val)
  end

  return val
end

function normalize_build_data(input, out)
  if type(input) ~= "table" then
    out["value"] = parse_value(input)
    return
  end

  local key = nil
  local body = {}

  for k, v in pairs(input) do
    if k == "elem" then
      key = v
    elseif k == "attrib" then
      for k2, v2 in pairs(v) do
        if not k2:find("^active") and not k2:find("^enable") and k2 ~= "gemId" and k2 ~= "viewMode" and k2 ~= "targetVersion" and v2 ~= nil and v2 ~= "" and v2 ~= "nil" then
          body[k2] = parse_value(v2)
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

  if key == "Calcs" or key == "TreeView" or key == "Import" or key == "Section" or key == "Notes" or key == "ItemSet" or key == "EditedNodes" then
    return
  end

  if util.table_len(body) == 1 and (body["value"] ~= nil or body["Spec"] ~= nil) then
    out[key] = util.table_last(body)
    return
  end

  if body["Skill"] ~= nil then
    out[key] = body["Skill"]
    return
  end

  if body["Socket"] ~= nil then
    out[key] = body["Socket"]
    return
  end

  if body["Input"] ~= nil then
    out[key] = body["Input"]
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
    if not util.is_array(out[key]) then
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
  build.itemsTab.activeItemSet["Flask 1"].active = true
  build.itemsTab.activeItemSet["Flask 2"].active = true
  build.itemsTab.activeItemSet["Flask 3"].active = true
  build.itemsTab.activeItemSet["Flask 4"].active = true
  build.itemsTab.activeItemSet["Flask 5"].active = true

  -- configure stuff
  build.calcsTab.input["enemyIsBoss"] = "Sirus"

  build.calcsTab.input["infusedChannelingInfusion"] = true
  build.calcsTab.input["plagueBearerState"] = "INF"
  build.calcsTab.input["BrandsAttachedToEnemy"] = true
  build.calcsTab.input["useChallengerCharges"] = true
  build.calcsTab.input["useBlitzCharges"] = true

  build.calcsTab.input["multiplierNearbyEnemies"] = 1
  build.calcsTab.input["multiplierGaleForce"] = 10
  build.calcsTab.input["multiplierRage"] = 100
  build.calcsTab.input["multiplierEnsnaredStackCount"] = 3
  build.calcsTab.input["multiplierWitheredStackCount"] = 15
  build.calcsTab.input["multiplierRuptureStacks"] = 3

  build.calcsTab.input["intensifyIntensity"] = 5
  build.calcsTab.input["meleeDistance"] = 1

  build.calcsTab.input["buffElusive"] = true
  build.calcsTab.input["buffLifetap"] = true
  build.calcsTab.input["buffPhasing"] = true
  build.calcsTab.input["buffAlchemistsGenius"] = true

  build.calcsTab.input["conditionOnConsecratedGround"] = true
  build.calcsTab.input["conditionUsedMinionSkillRecently"] = true
  build.calcsTab.input["conditionUsedTravelSkillRecently"] = true
  build.calcsTab.input["conditionUsedMovementSkillRecently"] = true
  build.calcsTab.input["conditionImpaledRecently"] = true
  build.calcsTab.input["conditionHaveManaStorm"] = true
  build.calcsTab.input["conditionLeeching"] = true
  build.calcsTab.input["conditionAtCloseRange"] = true
  build.calcsTab.input["conditionCritRecently"] = true
  build.calcsTab.input["conditionNearLinkedTarget"] = true

  build.calcsTab.input["conditionEnemyMoving"] = true
  build.calcsTab.input["conditionEnemyCursed"] = true
  build.calcsTab.input["conditionEnemyPoisoned"] = true
  build.calcsTab.input["conditionEnemyBleeding"] = true
  build.calcsTab.input["conditionEnemyTaunted"] = true
  build.calcsTab.input["conditionEnemyMaimed"] = true
  build.calcsTab.input["conditionEnemyHindered"] = true
  build.calcsTab.input["conditionEnemyChilled"] = true
  build.calcsTab.input["conditionEnemyIgnited"] = true
  build.calcsTab.input["conditionEnemyShocked"] = true
  build.calcsTab.input["conditionEnemyOnShockedGround"] = true
  build.calcsTab.input["conditionEnemyOnConsecratedGround"] = true
  build.calcsTab.input["conditionEnemyInChillingArea"] = true
  build.calcsTab.input["conditionEnemyInFrostGlobe"] = true

  for k, v in pairs(build.calcsTab.input) do
    build.configTab.input[k] = v
  end

  -- finishing touches
  build.configTab:BuildModList()
  build.buildFlag = true
  build:OnFrame({})

  local out = build.calcsTab.mainOutput
  local out_t = { elem = "PathOfBuilding" }

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

  local code = common.base64.encode(zlib.deflate()(common.xml.ComposeXML(out_t), "finish")):gsub("+","-"):gsub("/","_")
  local data = {}
  normalize_build_data(out_t, data)
  return data, code
end

function parse_character(accountName, characterName)
  print("Loading character "..characterName.." for account "..accountName)
  local itemsJson = util.fetch_contents("https://www.pathofexile.com/character-window/get-items?accountName="..accountName.."&character="..characterName)
  local passiveTreeJson = util.fetch_contents("https://www.pathofexile.com/character-window/get-passive-skills?accountName="..accountName.."&character="..characterName)
  local build = LoadModule("Modules/Build")
  build:Init(false, "")
  build:OnFrame({})
  local charData = build.importTab:ImportItemsAndSkills(itemsJson)
  build.importTab:ImportPassiveTreeAndJewels(passiveTreeJson, charData)
  return prepare_build(build)
end

return parse_character
