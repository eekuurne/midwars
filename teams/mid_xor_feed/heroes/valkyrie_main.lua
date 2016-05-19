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

local core, eventsLib, behaviorLib, metadata, skills, generics = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills, object.commonLib

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading valkyrie_main...')

object.heroName = 'Hero_Valkyrie'


behaviorLib.StartingItems = {"Item_MinorTotem", "Item_PretendersCrown", "Item_TrinketOfRestoration"}
behaviorLib.LaneItems = {"Item_MysticPotpourri", "Item_CrushingClaws", "Item_Strength5", "Item_Astrolabe", "Item_Marchers"}
behaviorLib.MidItems = {"Item_EnhancedMarchers", "Item_Sicarius", "Item_ManaBurn1", "Item_ManaBurn2"}
behaviorLib.LateItems = {"Item_Immunity", "Item_BehemothsHeart"}


--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 2, ShortSupport = 0, LongSupport = 0, ShortCarry = 4, LongCarry = 3}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
  local unitSelf = self.core.unitSelf

  if not bSkillsValid then
    skills.call = unitSelf:GetAbility(0)
    skills.javelin = unitSelf:GetAbility(1)
    skills.leap = unitSelf:GetAbility(2)
    skills.ulti = unitSelf:GetAbility(3)
    skills.attributeBoost = unitSelf:GetAbility(4)
    skills.courier = unitSelf:GetAbility(12)

    if skills.call and skills.javelin and skills.leap and skills.ulti and skills.attributeBoost then
      bSkillsValid = true
    else
      return
    end
  end

  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end

  if skills.javelin:CanLevelUp() and unitSelf:GetLevel() == 4 then
    skills.javelin:LevelUp()
  elseif skills.leap:CanLevelUp() and unitSelf:GetLevel() == 1 then
    skills.leap:LevelUp()
  elseif skills.call:CanLevelUp() then
    skills.call:LevelUp()
  elseif skills.javelin:CanLevelUp() then
    skills.javelin:LevelUp()
  elseif skills.leap:CanLevelUp() then
    skills.leap:LevelUp()
  elseif skills.attributeBoost:CanLevelUp() then
    skills.attributeBoost:LevelUp()
  else
    skills.ulti:LevelUp()
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

  local unitSelf = self.core.unitSelf

  if unitSelf:GetLevel() > 3 then
    behaviorLib.criticalHealthPercent = 0.23
    behaviorLib.wellUtilityAtCritical = 26
  elseif unitSelf:GetLevel() > 5 then
    behaviorLib.maxWellManaUtility = 8
    behaviorLib.criticalHealthPercent = 0.25
    behaviorLib.wellUtilityAtCritical = 28
  elseif unitSelf:GetLevel() > 7 then
    behaviorLib.maxWellManaUtility = 9
    behaviorLib.criticalHealthPercent = 0.27
    behaviorLib.wellUtilityAtCritical = 30
  end

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

  local addBonus = 0
  if EventData.Type == "Attack" then
    local unitTarget = EventData.TargetUnit
    if EventData.InflictorName == "Projectile_Valkyrie_Ability2" and unitTarget:IsHero() then
      addBonus = addBonus + 50
    end
  end

  if addBonus > 0 then
    core.nHarassBonus = core.nHarassBonus + addBonus
  end
end
-- override combat event trigger function.
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

function behaviorLib.CustomRetreatExecute(botBrain)
  local leap = skills.leap
  local unitSelf = core.unitSelf
  local unitsNearby = core.AssessLocalUnits(botBrain, unitSelf:GetPosition(), 500)

  if unitSelf:GetHealthPercent() < 0.3 and core.NumberElements(unitsNearby.EnemyHeroes) > 0 then
    local ulti = skills.ulti
    if ulti and ulti:CanActivate() then
      return core.OrderAbility(botBrain, ulti)
    end
    local angle = core.HeadingDifference(unitSelf, core.allyMainBaseStructure:GetPosition())
    if leap and leap:CanActivate() and angle < 0.5 then
      return core.OrderAbility(botBrain, leap)
    end
  end
  return false
end

local function CustomHarassUtilityFnOverride(target)
  local nUtility = 0

  local call = skills.call
  if call and call:CanActivate() then
    nUtility = nUtility + 10
  end

  return generics.CustomHarassUtility(target) + nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)
  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil or not unitTarget:IsValid() then
    return false --can not execute, move on to the next behavior
  end

  local unitSelf = core.unitSelf


  local bActionTaken = false

  local call = skills.call
  if call and call:CanActivate() and Vector3.Distance2D(unitTarget:GetPosition(), unitSelf:GetPosition()) < 650 then
    bActionTaken = core.OrderAbility(botBrain, call)
  end

  if not bActionTaken then
    return object.harassExecuteOld(botBrain)
  end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

local PositionSelfLogicOld = behaviorLib.PositionSelfLogic
local function PositionSelfLogicOverride(botBrain)
  local vecDesiredPos, unitTarget = PositionSelfLogicOld(botBrain)  
  vecDesiredPos = core.AdjustMovementForTowerLogic(vecDesiredPos)
  return vecDesiredPos, unitTarget
end
behaviorLib.PositionSelfLogic = PositionSelfLogicOverride

local function DetermineArrowTarget(arrow)
  local tLocalEnemies = core.CopyTable(core.localUnits["EnemyHeroes"])
  local maxDistance = arrow:GetRange()
  local maxDistanceSq = maxDistance * maxDistance
  local myPos = core.unitSelf:GetPosition()
  local unitTarget = nil
  local distanceTarget = 999999999
  for _, unitEnemy in pairs(tLocalEnemies) do
    local enemyPos = unitEnemy:GetPosition()
    local distanceEnemy = Vector3.Distance2DSq(myPos, enemyPos)
    if distanceEnemy < maxDistanceSq then
      if distanceEnemy < distanceTarget and generics.IsFreeLineNoAllies(myPos, enemyPos) then
        unitTarget = unitEnemy
        distanceTarget = distanceEnemy
      end
    end
  end
  return unitTarget
end

local arrowTarget = nil
local function ArrowUtility(botBrain)
  local javelin = skills.javelin
  if javelin and javelin:CanActivate() then
    local unitTarget = DetermineArrowTarget(javelin)
    if unitTarget then
      arrowTarget = unitTarget:GetPosition()

      return 60
    end
  end
  arrowTarget = nil
  return 0
end
local function ArrowExecute(botBrain)
  local javelin = skills.javelin
  if javelin and javelin:CanActivate() and arrowTarget then
    return core.OrderAbilityPosition(botBrain, javelin, arrowTarget)
  end
  return false
end
local ArrowBehavior = {}
ArrowBehavior["Utility"] = ArrowUtility
ArrowBehavior["Execute"] = ArrowExecute
ArrowBehavior["Name"] = "Arrowing"
tinsert(behaviorLib.tBehaviors, ArrowBehavior)

local CallPushBehavior = {}
local function CallPushUtility(botBrain)
  local nUtility = 0;
  local unitSelf = core.unitSelf
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local enemyCreepsInRange = 0
  local siegeOnLane = false
  
  local call = skills.call
  if call and call:CanActivate() then
      for _, ally in pairs(tAllies) do
      local typeAlly = ally:GetTypeName()

      if typeAlly == "Creep_LegionSiege" or typeAlly == "Creep_HellbourneSiege" then
        siegeOnLane = true
      end
    end

    for _, creep in pairs(tEnemies) do
      local typeCreep = creep:GetTypeName()

      if typeCreep == "Creep_LegionSiege" or typeCreep == "Creep_HellbourneSiege" then
        siegeOnLane = true
      end

      if siegeOnLane == true and typeCreep ~= "Creep_LegionSiege" and typeCreep ~= "Creep_HellbourneSiege" then
        if Vector3.Distance2D(creep:GetPosition(), unitSelf:GetPosition()) < 600 then
          enemyCreepsInRange = enemyCreepsInRange + 1
        end 
      end
    end
  end

  if enemyCreepsInRange > 2 then
    nUtility = nUtility + 50
  end

  return nUtility
end
local function CallPushExecute(botBrain)
  local call = skills.call
  if call and call:CanActivate() then
    BotEcho('Push call!')
    return core.OrderAbility(botBrain, call)
  end
  return false
end
CallPushBehavior["Utility"] = CallPushUtility
CallPushBehavior["Execute"] = CallPushExecute
CallPushBehavior["Name"] = "Call push"
tinsert(behaviorLib.tBehaviors, CallPushBehavior)

BotEcho('finished loading valkyrie_main')
