local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true

object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/teams/mid_xor_feed/core.lua"
runfile "bots/teams/mid_xor_feed/behaviorLib.lua"
runfile "bots/teams/mid_xor_feed/botbraincore.lua"
runfile "bots/teams/mid_xor_feed/eventsLib.lua"
runfile "bots/teams/mid_xor_feed/metadata.lua"

runfile "bots/teams/mid_xor_feed/commonLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
local commonLib = object.commonLib

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading nymphora_main...')

behaviorLib.StartingItems = {"Item_PretendersCrown", "Item_MarkOfTheNovice"}
behaviorLib.LaneItems = {"Item_MysticVestments", "Item_Intelligence5", "Item_Marchers"}
behaviorLib.MidItems = {"Item_ManaRegen3", "Item_NomesWisdom", "Item_SpellShards", "Item_Striders"}
behaviorLib.LateItems = {"Item_Astrolabe", "Item_BehemothsHeart"}

object.heroName = 'Hero_Fairy'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 0, ShortSolo = 0, LongSolo = 0, ShortSupport = 5, LongSupport = 5, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.heal = unitSelf:GetAbility(0)
    skills.mana = unitSelf:GetAbility(1)
    skills.stun = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)
    skills.courier = unitSelf:GetAbility(12)

    if skills.heal and skills.mana and skills.stun and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  local level = unitSelf:GetLevel()
  local heal = skills.heal
  local mana = skills.mana
  local stun = skills.stun
  local ulti = skills.ulti

  if level == 1 then
    heal:LevelUp()
  elseif level == 2 then
    mana:LevelUp()
  elseif level == 3 then
    mana:LevelUp()
  elseif level == 4 then
    stun:LevelUp()
  elseif level == 5 then
    mana:LevelUp()
  elseif level == 6 then
    heal:LevelUp()
  elseif level == 7 then
    heal:LevelUp()
  elseif level == 8 then
    heal:LevelUp()
  elseif level == 9 then
    mana:LevelUp()
  elseif level == 10 then
    stun:LevelUp()
  elseif level == 11 then
    stun:LevelUp()
  elseif level == 12 then
    stun:LevelUp()
  end

  if skills.attributeBoost:CanLevelUp() then
    skills.attributeBoost:LevelUp()
  else
    ulti:LevelUp()
  end
end

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function object:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function object:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

function behaviorLib.HealUtility(botBrain)
  local nUtility = 0
  if not skills.heal then return 0 end
  if skills.heal:CanActivate() then
    local unitSelf = core.unitSelf
    local healthPc = unitSelf:GetHealth() / unitSelf:GetMaxHealth()
    nUtility = 100 * (1 - healthPc)
  end

  if object.bDebugUtility == true and nUtility ~= 0 then
    BotEcho(format("  HealSelfUtility: %g", nUtility))
  end

  return nUtility
end
 
function behaviorLib.HealExecute(botBrain)
  local heal = skills.heal
  if heal and heal:CanActivate() then
    return core.OrderAbilityPosition(botBrain, heal, core.unitSelf:GetPosition())
  end
  return false
end
 
behaviorLib.HealBehavior = {}
behaviorLib.HealBehavior["Utility"] = behaviorLib.HealUtility
behaviorLib.HealBehavior["Execute"] = behaviorLib.HealExecute
behaviorLib.HealBehavior["Name"] = "Heal"
tinsert(behaviorLib.tBehaviors, behaviorLib.HealBehavior) 

local ManaRegenSpellBehavior = {}
local function ManaRegenSpellUtility(botBrain)
  local nUtility = 0
  local mana = skills.mana
  if not mana or mana:GetLevel() < 2 then return 0 end
  if mana:CanActivate() and core.unitSelf:GetMana() < core.unitSelf:GetMaxMana() * 0.9
  then
    nUtility = 100
  end
  if object.bDebugUtility == true and nUtility ~= 0 then
    BotEcho(format("  ManaRegenSpellUtility: %g", nUtility))
  end
  return nUtility
end

local function ManaRegenSpellExecute(botBrain)
  local mana = skills.mana
  if mana and mana:CanActivate() then
    return core.OrderAbilityEntity(botBrain, mana, core.unitSelf)
  end
  return false
end
ManaRegenSpellBehavior["Utility"] = ManaRegenSpellUtility
ManaRegenSpellBehavior["Execute"] = ManaRegenSpellExecute
ManaRegenSpellBehavior["Name"] = "Mana regen spell"
tinsert(behaviorLib.tBehaviors, ManaRegenSpellBehavior)

local function CustomHarassUtilityOverride(hero)
  BotEcho("2")
  local nUtility = 0
  local stunUtility = 20
  local healUtility = 20

  if skills.stun:CanActivate() then
    nUtility = nUtility + stunUtility
  end

  if skills.heal:CanActivate() then
    nUtility = nUtility + healUtility
  end
  
  if object.bDebugUtility == true and nUtility ~= 0 then
    BotEcho(format("  CustomHarassUtility: %g", nUtility))
  end

  return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride


local function HarassHeroExecuteOverride(botBrain)
  BotEcho("1")
  local unitTarget = behaviorLib.heroTarget

  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  local bActionTaken = false

  --
  -- Use abilities
  --
  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, unitTarget) then
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)

    local heal = skills.heal
    local stun = skills.stun
    
    local facing = core.HeadingDifference(unitSelf, unitTarget:GetPosition())
    local targetDisabled = commonLib.IsDisabled(unitTarget)

    if not bActionTaken and stun and stun:CanActivate() and 
      Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < stun:GetRange()*0.9 then

      BotEcho("!!!!!!!!!!!!!!1 Using stun")
      local ownPos = core.unitSelf:GetPosition()
      local enemyPos = unitTarget:GetPosition()
      local direction = Vector3.Normalize(enemyPos - ownPos)
      local targetSpot = ownPos + direction * stun:GetRange()

      core.DrawXPosition(targetSpot, "yellow", 100)
      bActionTaken = core.OrderAbilityPosition(botBrain, stun, targetSpot)
    end

    if not bActionTaken and heal and heal:CanActivate() and 
      Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < (heal:GetRange() + 100) then

      BotEcho("!!!!!!!!!!!!!!1 Using heal")
      local ownPos = core.unitSelf:GetPosition()
      local enemyPos = unitTarget:GetPosition()
      local direction = Vector3.Normalize(enemyPos - ownPos)
      local distance = Vector3.Distance2D(ownPos, enemyPos)
      local targetSpot = enemyPos
      if distance > heal:GetRange() then
        targetSpot = ownPos + direction * (heal:GetRange())
      end

      core.DrawXPosition(targetSpot, "green", 100)
      bActionTaken = core.OrderAbilityPosition(botBrain, heal, targetSpot)
    end
  end

  if not bActionTaken then

    local desiredPos = unitTarget:GetPosition()

    if not bActionTaken and itemGhostMarchers and itemGhostMarchers:CanActivate() then
      bActionTaken = core.OrderItemClamp(botBrain, unitSelf, itemGhostMarchers)
    end

    if not bActionTaken and behaviorLib.lastHarassUtil < behaviorLib.diveThreshold then
      desiredPos = core.AdjustMovementForTowerLogic(desiredPos)
    end

    --bActionTaken = core.OrderMoveToPosClamp(botBrain, unitSelf, desiredPos, false)
    
    if not bActionTaken then 
      return object.harassExecuteOld(botBrain)
    end
  end
  return true
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho('finished loading nymphora_main')
