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
object.bDebugUtility = true
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

BotEcho('loading monkeyking_main...')

object.heroName = 'Hero_MonkeyKing'

behaviorLib.criticalHealthPercent = 0.30
behaviorLib.wellUtilityAtCritical = 22
behaviorLib.wellManaRegenMinLevel = 6
behaviorLib.maxWellManaUtility = 2

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 0, LongSolo = 0, ShortSupport = 0, LongSupport = 0, ShortCarry = 0, LongCarry = 0}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.dash = unitSelf:GetAbility(0)
    skills.pole = unitSelf:GetAbility(1)
    skills.rock = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)
    skills.courier = unitSelf:GetAbility(12)

    if skills.dash and skills.pole and skills.rock and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  if skills.ulti:CanLevelUp() then
    skills.ulti:LevelUp()
  elseif skills.dash:CanLevelUp() then
    skills.dash:LevelUp()
  elseif skills.pole:CanLevelUp() then
    skills.pole:LevelUp()
  elseif skills.rock:CanLevelUp() then
    skills.rock:LevelUp()
  else
    skills.attributeBoost:LevelUp()
  end
end

behaviorLib.StartingItems = {"Item_HealthPotion", "Item_LoggersHatchet", "Item_PretendersCrown"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_DuckBoots", "Item_Soulscream"}
behaviorLib.MidItems = {"Item_EnhancedMarchers", "Item_SolsBulwark"}
behaviorLib.LateItems = {"Item_Protect", "Item_Strength6", "Item_StrengthAgility"}

local function HarassHeroUtilityOverride(botBrain)
  local nUtility = 0

  local mana = core.unitSelf:GetMana()
  local poleUtility = 10
  local rockUtility = 10
  local dashUtility = 10

  if skills.dash:CanActivate()  then
    nUtility = nUtility + dashUtility
    mana = mana - skills.dash:GetManaCost()
    if skills.rock:CanActivate() and skills.rock:GetManaCost() < mana then
      mana = mana - skills.rock:GetManaCost()
      nUtility = nUtility + rockUtility
      if skills.pole:CanActivate() and skills.pole:GetManaCost() < mana then
        nUtility = nUtility + poleUtility
      end
    else
      if skills.pole:CanActivate() and skills.pole:GetManaCost() < mana then
        nUtility = nUtility + poleUtility
      end
    end
  else 
    if skills.rock:CanActivate() then
      mana = mana - skills.rock:GetManaCost()
      nUtility = nUtility + rockUtility
      if skills.pole:CanActivate() and skills.pole:GetManaCost() < mana then
        nUtility = nUtility + poleUtility
      end
    else 
      if skills.pole:CanActivate() then
        nUtility = nUtility + poleUtility
      end
    end
  end

  local unitTarget = behaviorLib.heroTarget
  if unitTarget then
    local s = commonLib.RelativeTowerPosition(unitTarget)
    if s == 1 then 
      nUtility = nUtility * 1.4
    end
    if s == -1 then 
      nUtility = nUtility / 1.4
    end

    if unitTarget:GetMana() > core.unitSelf:GetMana() then 
      nUtility = nUtility / 1.2
    else 
      nUtility = nUtility * 1.2
    end
  end

  BotEcho("============ "..nUtility.." ============")

  return nUtility
end

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget

  if unitTarget == nil or not unitTarget:IsValid() then
    BotEcho("Fail 1")
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf

  local bActionTaken = false

  --since we are using an old pointer, ensure we can still see the target for entity targeting
  if core.CanSeeUnit(botBrain, unitTarget) then
    BotEcho("Action action")
    local dist = Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition())
    local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)

    local dash = skills.dash
    local pole = skills.pole
    local stun = skills.rock
    
    local facing = core.HeadingDifference(unitSelf, unitTarget:GetPosition())

    if not bActionTaken and stun and stun:CanActivate() and Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < 300 and facing < 0.3 then
      bActionTaken = core.OrderAbility(botBrain, stun)
    end

    if not bActionTaken and dash and dash:CanActivate() and Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < dash:GetRange() and facing < 0.3 then
      bActionTaken = core.OrderAbility(botBrain, dash)
    end

    if not bActionTaken and pole and pole:CanActivate() and Vector3.Distance2D(unitSelf:GetPosition(), unitTarget:GetPosition()) < pole:GetRange() then
      bActionTaken = core.OrderAbilityEntity(botBrain, pole, unitTarget)
    end

  end

  if not bActionTaken then
    BotEcho("Movement action")

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
behaviorLib.CustomHarassUtility = HarassHeroUtilityOverride
--behaviorLib.HarassHeroBehavior["Utility"] = HarassHeroUtilityOverride