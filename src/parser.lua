dofile('HeadlessWrapper.lua')

local zlib = require "zlib"
local util = require "util"

function mod_to_string(mod)
  local line = mod.line
  if mod.crafted then
    line = "{crafted}" .. line
  end
  if mod.scourge then
    line = "{scourge}" .. line
  end
  if mod.fractured then
    line = "{fractured}" .. line
  end
  return line
end

function build_items(build)
  local slots = {}

  for slotName, slot in pairs(build.itemsTab.slots) do
    if slot.selItemId ~= 0 and not slot.nodeId then
      slots[slotName] = slot.selItemId
    end
  end

  local items = {}

  for _, id in ipairs(build.itemsTab.itemOrderList) do
    local item = build.itemsTab.items[id]
    local out_item = {}
    out_item["id"] = item.uniqueID
    out_item["name"] = item.title or ((item.namePrefix or "")..item.baseName..(item.nameSuffix or ""))
    out_item["base"] = item.baseName
    out_item["rarity"] = item.rarity
    out_item["league"] = item.league
    influences = {}
    if item.shaper then table.insert(influences, "Shaper") end
    if item.elder then table.insert(influences, "Elder") end
    if item.adjudicator then table.insert(influences, "Warlord") end
    if item.basilisk then table.insert(influences, "Hunter") end
    if item.crusader then table.insert(influences, "Crusader") end
    if item.eyrie then table.insert(influences, "Redeemer") end
    if #influences > 0 then out_item["influences"] = influences end
    out_item["ilvl"] = item.itemLevel
    out_item["corrupted"] = item.corrupted or item.scourge
    if item.armourData then
      if item.armourData["Armour"] and item.armourData["Armour"] > 0 then out_item["armour"] = item.armourData["Armour"] end
      if item.armourData["Evasion"] and item.armourData["Evasion"] > 0 then out_item["evasion"] = item.armourData["Evasion"] end
      if item.armourData["EnergyShield"] and item.armourData["EnergyShield"] > 0 then out_item["energyShield"] = item.armourData["EnergyShield"] end
      if item.armourData["Ward"] and item.armourData["Ward"] > 0 then out_item["ward"] = item.armourData["Ward"] end
    end
    implicits = {}
    for _, mod in ipairs(item.enchantModLines) do table.insert(implicits, mod_to_string(mod)) end
    for _, mod in ipairs(item.scourgeModLines) do table.insert(implicits, mod_to_string(mod)) end
    for _, mod in ipairs(item.implicitModLines) do table.insert(implicits, mod_to_string(mod)) end
    if #implicits > 0 then out_item["implicits"] = implicits end

    if #item.explicitModLines > 0 then
      out_item["explicits"] = {}
      for _, mod in ipairs(item.explicitModLines) do table.insert(out_item["explicits"], mod_to_string(mod)) end
    end

    if item.quality then out_item["quality"] = item.quality end
    if item.requirements then
      requirements = {}
      if item.requirements.level and item.requirements.level > 0 then requirements["level"] = item.requirements.level end
      if item.requirements.strMod and item.requirements.strMod > 0 then requirements["str"] = item.requirements.strMod end
      if item.requirements.intMod and item.requirements.intMod > 0 then requirements["int"] = item.requirements.intMod end
      if item.requirements.dexMod and item.requirements.dexMod > 0 then requirements["dex"] = item.requirements.dexMod end
      if util.table_len(requirements) > 0 then
        out_item["requirements"] = requirements
      end
    end
    if item.sockets and #item.sockets > 0 then
      local line = ""
      for i, socket in pairs(item.sockets) do
        line = line .. socket.color
        if item.sockets[i+1] then
          line = line .. (socket.group == item.sockets[i+1].group and "-" or " ")
        end
      end
      out_item["sockets"] = line
    end
    if item.jewelRadiusLabel then out_item["radius"] = item.jewelRadiusLabel end

    items[id] = out_item
  end

  return {
    slots=slots,
    items=items
  }
end

function build_tree(build)
  local out = {}
  local tree = util.table_last(build.treeTab.specList)
  out["url"] = tree:EncodeURL("https://www.pathofexile.com/fullscreen-passive-skill-tree/")
  out["nodes"] = {}
  for nodeId in pairs(tree.allocNodes) do table.insert(out["nodes"], nodeId) end
  out["masteries"] = {}
  for mastery, effect in pairs(tree.masterySelections) do out["masteries"][tostring(mastery)] = effect end
  out["sockets"] = {}
  for nodeId, itemId in pairs(tree.jewels) do
    if itemId > 0 then
      out["sockets"][tostring(nodeId)] = itemId
    end
  end

  return out
end

function build_skills(build)
  local out = {}
  for _, socket_group in ipairs(build.skillsTab.socketGroupList) do
    local out_socket_group = {}

    for _, gem in ipairs(socket_group.gemList) do
      table.insert(out_socket_group, {
          skillId=gem.skillId,
          name=gem.nameSpec,
          level=gem.level,
          quality=gem.quality,
          qualityId=gem.qualityId,
        })
    end

    out[socket_group.slot] = out_socket_group
  end
  return out
end

function build_stats(build)
  local player_stats = {}

  for index, stat_data in ipairs(build.displayStats) do
    if not stat_data.flag or build.calcsTab.mainEnv.player.mainSkill.skillFlags[stat_data.flag] then
      if stat_data.stat and not player_stats[stat_data.stat] then
        local stat_val = build.calcsTab.mainOutput[stat_data.stat]
        if stat_val and (stat_data.condFunc and stat_data.condFunc(stat_val, build.calcsTab.mainOutput) or true) then
          player_stats[stat_data.stat] = stat_val
        end
      end
    end
  end

  for index, stat in ipairs(build.extraSaveStats) do
    local stat_val = build.calcsTab.mainOutput[stat]
    if stat_val then
      player_stats[stat] = stat_val
    end
  end

  local minion_stats = {}

  if build.calcsTab.mainEnv.minion then
    for index, stat_data in ipairs(build.minionDisplayStats) do
      if stat_data.stat then
        local stat_val = build.calcsTab.mainOutput.Minion[stat_data.stat]
        if stat_val then
          minion_stats[stat_data.stat] = stat_val
        end
      end
    end
  end

  local out = {}
  if player_stats then out["player"] = player_stats end
  if minion_stats then out["minion"] = minion_stats end
  return out
end

function build_build(build)
  local mainSlot = ""
  local mainSkill = ""

  if build.mainSocketGroup > 0 then
    mainSlot = build.skillsTab.socketGroupList[build.mainSocketGroup].slot
    mainSkill = build.skillsTab.socketGroupList[build.mainSocketGroup].gemList[build.mainActiveSkill].nameSpec
  end

  local out = {
    level=build.characterLevel,
    class=build.spec.curClassName,
    ascendancy=build.spec.curAscendClassName,
    mainSlot=mainSlot,
    mainSkill=mainSkill
  }

  for k,v in pairs(build_stats(build)) do out[k] = v end
  for k,v in pairs(build_items(build)) do out[k] = v end
  out["skills"] = build_skills(build)
  out["tree"] = build_tree(build)
  return out
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

      local foundAlready = false

      for i, gem in ipairs(v.gemList) do
        if gem.gemData then
          if gem.gemData.tags.active_skill == true then
            if not foundAlready or (gem.gemData.tags.spell and not gem.gemData.tags.curse) then
              gemIndex = i
            end

            foundAlready = true
          end
        end
      end
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
  build.calcsTab.input["BrandsAttachedToEnemy"] = 1
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
  local data = build_build(build)
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
