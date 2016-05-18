local _G = getfenv(0)
local object = _G.object

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
  = _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
  = _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog, Clamp = core.BotEcho, core.VerboseLog, core.BotLog, core.Clamp

object.commonLib = {}
local commonLib = object.commonLib

function commonLib.IsFreeLine(pos1, pos2)
  BotEcho("freeline check")
  core.DrawDebugLine(pos1, pos2, "yellow")
  local tAllies = core.CopyTable(core.localUnits["AllyUnits"])
  local tEnemies = core.CopyTable(core.localUnits["EnemyCreeps"])
  local distanceLine = Vector3.Distance2DSq(pos1, pos2)
  local x1, x2, y1, y2 = pos1.x, pos2.x, pos1.y, pos2.y
  local reserveWidth = 100*100

  local obstructed = false

  for _, ally in pairs(tAllies) do
    local posAlly = ally:GetPosition()
    local x0, y0, z0 = posAlly.x, posAlly.y, posAlly.z
    local U = (x0 - x1)*(x2 - x1) + (y0 - y1)*(y2 - y1)
    U = U / ((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
    local xc = x1 + (U * (x2 - x1))
    local yc = y1 + (U * (y2 - y1))
    local d2 = (x0 - xc)*(x0 - xc) + (y0 - yc)*(y0 - yc)

    local color = "red"
    if d2 >= reserveWidth then color = "green" end
    local t = (xc - x1) / (x2 - x1)
    local between = t < 1 and t > 0
    if not between then color = "yellow" end

    if d2 < reserveWidth and between then
      core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
      core.DrawXPosition(posAlly, color, 25)
      obstructed = true
    else
      core.DrawXPosition(posCreep, color, 25)
      core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
    end
  end

  for _, creep in pairs(tEnemies) do
    local posCreep = creep:GetPosition()
    local x0, y0, z0 = posCreep.x, posCreep.y, posCreep.z
    local U = (x0 - x1)*(x2 - x1) + (y0 - y1)*(y2 - y1)
    U = U / ((x2 - x1)*(x2 - x1) + (y2 - y1)*(y2 - y1))
    local xc = x1 + (U * (x2 - x1))
    local yc = y1 + (U * (y2 - y1))
    local d2 = (x0 - xc)*(x0 - xc) + (y0 - yc)*(y0 - yc)

    local color = "red"
    if d2 >= reserveWidth then color = "green" end
    local t = (xc - x1) / (x2 - x1)
    local between = t < 1 and t > 0
    if not between then color = "yellow" end

    if d2 < reserveWidth and between then
      core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
      core.DrawXPosition(posCreep, color, 25)
      obstructed = true
    else 
      core.DrawDebugLine(Vector3.Create(x0, y0, z0), Vector3.Create(xc, yc, z0), color)
      core.DrawXPosition(posCreep, color, 25)
    end
  end

  if obstructed then return false end

  core.DrawDebugLine(pos1, pos2, "green")
  return true
end

function commonLib.CustomHarassUtility(target)
  local nUtil = 0
  local creepLane = core.GetFurthestCreepWavePos(core.tMyLane, core.bTraverseForward)
  local unitSelf = core.unitSelf
  local myPos = unitSelf:GetPosition()

  if unitSelf:GetHealthPercent() < 0.3 then
     nUtil = nUtil - 10
  end

  if unitSelf:GetHealth() > target:GetHealth() then
     nUtil = nUtil + 20
  end
  
  if target:IsChanneling() or target:IsDisarmed() or target:IsImmobilized() or target:IsPerplexed() or target:IsSilenced() or target:IsStunned() or unitSelf:IsStealth() then
    nUtil = nUtil + 50
  end

  local unitsNearby = core.AssessLocalUnits(object, myPos,100)
  
  if #unitsNearby.AllyHeroes == 0 then
  
    if core.GetClosestEnemyTower(myPos, 720) then
      nUtil = nUtil - 100
    end
    
    for id, creep in pairs(unitsNearby.EnemyCreeps) do
      local creepPos = creep:GetPosition()
      if(creep:GetAttackType() == "ranged" or Vector3.Distance2D(myPos, creepPos) < 20) then
        core.DrawXPosition(creepPos)
        nUtil = nUtil - 20
      end 
    end
  end

  return nUtil
end

--
-- courier behaviour
--

local CourierUseBehavior = {}
local function CourierUseUtility(botBrain)

  if #behaviorLib.curItemList == 0 then
    behaviorLib.DetermineBuyState(botBrain)
    --BotEcho("Populating itemlist")
  end

  if #behaviorLib.curItemList == 0 then
    --BotEcho("Itemlist empty")
    return 0
  end

  -- count empty slots
  local emptyInventorySlots = 0
  for slot = 1, 6, 1 do
    local curItem = inventory[slot]
    if not curItem then
      emptyInventorySlots = emptyInventorySlots + 1
    end
  end

  local emptyStashSlots = 0
  for slot = 7, 12, 1 do
    local curItem = inventory[slot]
    if not curItem then
      emptyStashSlots = emptyStashSlots + 1
    end
  end

  -- determine next buy item

  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
  local componentDefs = core.unitSelf:GetItemComponentsRemaining(nextItemDef)
  --[[
  if courierDebug then
    BotEcho("Component defs for "..nextItemDef:GetName()..":")
    core.printGetNameTable(componentDefs)
    BotEcho("Checking if room in stash and inventory...")
    BotEcho("  #components: "..#componentDefs.."  stash: "..emptyStashSlots.. "  inv: "..emptyInventorySlots)
  end
  --]]

  if emptyStashSlots == 0 then 
    --BotEcho("Stash full")
    return 0
  end

  i = 1
  while i <= #componentDefs do
    if componentDefs[i]:GetCost() <= botBrain:GetGold() then
      object.courierBuyItem = componentDefs[i]
      --BotEcho("Queueing component "..componentDefs[i]:GetName().." of "..nextItemDef:GetName())
      break
    else
      --BotEcho("Not enough gold: "..componentDefs[i]:GetName().." costs "..componentDefs[i]:GetCost())
    end
    i = i + 1
  end

  if not object.courierBuyItem then
    
    return 0
  end

  --BotEcho("Item find successful")
  return 100
end

local function CourierUseExecute(botBrain)

  if not object.courierBuyItem then return false end

  BotEcho("Buying "..object.courierBuyItem:GetName())

  core.unitSelf:PurchaseRemaining(object.courierBuyItem)
  object.courierBuyItem = nil  

  if not skills.courier:CanActivate() then
    if courierDebug then
      BotEcho("Cannot use courier")
    end
    return 0
  end

  return core.OrderAbility(botBrain, skills.courier)
end

CourierUseBehavior["Utility"] = CourierUseUtility
CourierUseBehavior["Execute"] = CourierUseExecute
CourierUseBehavior["Name"] = "Use courier"
tinsert(behaviorLib.tBehaviors, CourierUseBehavior)

--
-- don't buy tp
--

function commonLib.ShopExecute(botBrain)
  --[[Current algorithm:
    A) Buy items from the list
  B) Swap items to complete recipes
    C) Swap items to fill inventory, prioritizing...
       1. Boots / +ms
     2. Magic Armor
       3. Homecoming Stone
       4. Most Expensive Item(s) (price decending)
    --]]

  if object.bUseShop == false then
    return
  end

  --Space out your buys
  if behaviorLib.nextBuyTime > HoN.GetGameTime() then
    return
  end

  behaviorLib.nextBuyTime = HoN.GetGameTime() + behaviorLib.buyInterval

  if behaviorLib.buyState == behaviorLib.BuyStateUnknown then
    --Determine where in the pattern we are (mostly for reloads)
    behaviorLib.DetermineBuyState(botBrain)
  end
  
  local unitSelf = core.unitSelf

  local bChanged = false
  local bShuffled = false
  local bGoldReduced = false
  local inventory = core.unitSelf:GetInventory(true)
  local nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)

  --[[ nope nope nope
  --For our first frame of this execute
  if core.GetLastBehaviorName(botBrain) ~= core.GetCurrentBehaviorName(botBrain) then
    if nextItemDef:GetName() ~= core.idefHomecomingStone:GetName() then   
      --Seed a TP stone into the buy items after 1 min
      local sName = "Item_HomecomingStone"
      local nTime = HoN.GetMatchTime()
      if nTime > core.MinToMS(1) then
        tinsert(behaviorLib.curItemList, 1, sName)
        nextItemDef = behaviorLib.DetermineNextItemDef(botBrain)
      end
    end
  end
  --]]
  
  if behaviorLib.printShopDebug then
    BotEcho("============ BuyItems ============")
    --printInventory(inventory)
    if nextItemDef then
      BotEcho("BuyItems - nextItemDef: "..nextItemDef:GetName())
    else
      BotEcho("ERROR: BuyItems - Invalid ItemDefinition returned from DetermineNextItemDef")
    end
  end

  if nextItemDef then
    core.teamBotBrain.bPurchasedThisFrame = true
    
    --open up slots if we don't have enough room in the stash + inventory
    local componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
    local slotsOpen = behaviorLib.NumberSlotsOpen(inventory)

    if behaviorLib.printShopDebug then
      BotEcho("Component defs for "..nextItemDef:GetName()..":")
      core.printGetNameTable(componentDefs)
      BotEcho("Checking if we need to sell items...")
      BotEcho("  #components: "..#componentDefs.."  slotsOpen: "..slotsOpen)
    end

    if #componentDefs > slotsOpen + 1 then --1 for provisional slot
      behaviorLib.SellLowestItems(botBrain, #componentDefs - slotsOpen - 1)
    elseif #componentDefs == 0 then
      behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
    end

    local goldAmtBefore = botBrain:GetGold()
    unitSelf:PurchaseRemaining(nextItemDef)

    local goldAmtAfter = botBrain:GetGold()
    bGoldReduced = (goldAmtAfter < goldAmtBefore)
    bChanged = bChanged or bGoldReduced

    --if bGoldReduced and nextItemDef ~= nil then
    --  botBrain:Chat("Hey all! I just bought a " .. nextItemDef:GetName())
    --end

    --Check to see if this purchased item has uncombined parts
    componentDefs = unitSelf:GetItemComponentsRemaining(nextItemDef)
    if #componentDefs == 0 then
      behaviorLib.ShuffleCombine(botBrain, nextItemDef, unitSelf)
    end
  end

  bShuffled = behaviorLib.SortInventoryAndStash(botBrain)
  bChanged = bChanged or bShuffled

  --BotEcho("bChanged: "..tostring(bChanged).."  bShuffled: "..tostring(bShuffled).."  bGoldReduced:"..tostring(bGoldReduced))

  if bChanged == false then
    BotEcho("Finished Buying!")
    behaviorLib.finishedBuying = true
  end
end

behaviorLib.ShopExecute = commonLib.ShopExecute
behaviorLib.ShopBehavior["Execute"] = commonLib.ShopExecute

--
-- behaviorLib overrides etc
--

local function AttackCreepsUtilityOverride(botBrain)

  local nDenyVal = 21
  local nLastHitVal = 24

  local nUtility = 0

  --we don't want to deny if we are pushing
  local unitDenyTarget = core.unitAllyCreepTarget
  if core.GetCurrentBehaviorName(botBrain) == "Push" then
    unitDenyTarget = nil
  end
  
  local unitTarget = behaviorLib.GetCreepAttackTarget(botBrain, core.unitEnemyCreepTarget, unitDenyTarget)
  
  if unitTarget and core.unitSelf:IsAttackReady() then
    BotEcho("has target")
    if unitTarget:GetTeam() == core.myTeam then
      nUtility = nDenyVal
    else
      nUtility = nLastHitVal
    end
    core.unitCreepTarget = unitTarget
  end

  if botBrain.bDebugUtility == true and nUtility ~= 0 then
    BotEcho(format("  AttackCreepsUtility: %g", nUtility))
  end

  return nUtility
end

behaviorLib.AttackCreepsBehavior["Utility"] = AttackCreepsUtilityOverride

function behaviorLib.PositionSelfCreepWave(botBrain, unitCurrentTarget)
  local bDebugLines = false
  local bDebugEchos = false
  local nLineLen = 150

  --if botBrain.myName == "ShamanBot" then bDebugLines = true bDebugEchos = true end

  if bDebugEchos then BotEcho("PositionCreepWave") end

  --Vector-based relative position logic
  local unitSelf = core.unitSelf
  
  --Don't run our calculations if we're basically in the same spot
  if unitSelf.bIsMemoryUnit and unitSelf.storedTime == behaviorLib.nLastPositionTime then
    --BotEcho("early exit")
    return behaviorLib.vecLastDesiredPosition
  end
  
  local vecMyPos = unitSelf:GetPosition()
  local tLocalUnits = core.localUnits
  
  --Local references for improved performance
  local nHeroInfluencePercent = behaviorLib.nHeroInfluencePercent
  local nPositionHeroInfluenceMul = behaviorLib.nPositionHeroInfluenceMul
  local nCreepPushbackMul = behaviorLib.nCreepPushbackMul
  local vecLaneForward = object.vecLaneForward
  local vecLaneForwardOrtho = object.vecLaneForwardOrtho
  local funcGetThreat  = behaviorLib.GetThreat
  local funcGetDefense = behaviorLib.GetDefense
  local funcLethalityUtility = behaviorLib.LethalityDifferenceUtility
  local funcDistanceThreatUtility = behaviorLib.DistanceThreatUtility
  local funcGetAbsoluteAttackRangeToUnit = core.GetAbsoluteAttackRangeToUnit
  local funcV3Normalize = Vector3.Normalize
  local funcV3Dot = Vector3.Dot
  local funcAngleBetween = core.AngleBetween
  local funcRotateVec2DRad = core.RotateVec2DRad  
  
  local nMyThreat =  funcGetThreat(unitSelf)
  local nMyDefense = funcGetDefense(unitSelf)
  local vecBackUp = behaviorLib.PositionSelfBackUp()
  
  
  local nExtraThreat = 0.0
  if unitSelf:HasState("State_HealthPotion") then
    if unitSelf:GetHealthPercent() < 0.95 then
      nExtraThreat = 10.0
    end
  end
  
  --Stand appart from enemies
  local vecTotalEnemyInfluence = Vector3.Create()
  local tEnemyUnits = core.CopyTable(tLocalUnits.EnemyUnits)
  core.teamBotBrain:AddMemoryUnitsToTable(tEnemyUnits, core.enemyTeam, vecMyPos)
  
  StartProfile('Loop')
  for nUID, unitEnemy in pairs(tEnemyUnits) do
    StartProfile('Setup')
    local bIsHero = unitEnemy:IsHero()
    local vecEnemyPos = unitEnemy:GetPosition()
    local vecTheirRange = funcGetAbsoluteAttackRangeToUnit(unitEnemy, unitSelf)
    local vecTowardsMe, nEnemyDist = funcV3Normalize(vecMyPos - vecEnemyPos)
    
    local nDistanceMul = funcDistanceThreatUtility(nEnemyDist, vecTheirRange, unitEnemy:GetMoveSpeed(), false) / 100
    
    local vecEnemyInfluence = Vector3.Create()
    StopProfile()

    if not bIsHero then
      StartProfile('Creep')
      
      --stand away from creeps
      if bDebugEchos then BotEcho('  creep unit: ' .. unitEnemy:GetTypeName()) end
      vecEnemyInfluence = vecTowardsMe * (nDistanceMul + nExtraThreat)

      StopProfile()
    else
      StartProfile('Hero')
      
      --stand away from enemy heroes
      if bDebugEchos then BotEcho('  hero unit: ' .. unitEnemy:GetTypeName()) end
      local vecHeroDir = vecTowardsMe

      local vecBackwards = funcV3Normalize(vecBackUp - vecMyPos)
      vecHeroDir = vecHeroDir * nHeroInfluencePercent + vecBackwards * (1 - nHeroInfluencePercent)

      --Calculate their lethality utility
      local nThreat = funcGetThreat(unitEnemy)
      local nDefense = funcGetDefense(unitEnemy)
      local nLethalityDifference = (nThreat - nMyDefense) - (nMyThreat - nDefense) 
      local nBaseMul = 1 + (Clamp(funcLethalityUtility(nLethalityDifference), 0, 100) / 50)
      local nLength = nBaseMul * nDistanceMul
      
      vecEnemyInfluence = vecHeroDir * nLength * nPositionHeroInfluenceMul      
      StopProfile()
    end
    
    StartProfile('Common')
    
    --enemies should not push you forward, flip it across the orthogonal line
    if vecLaneForward and funcV3Dot(vecEnemyInfluence, vecLaneForward) > 0 then
      local vecX = Vector3.Create(1,0)
      local nLaneOrthoAngle = funcAngleBetween(vecLaneForwardOrtho, vecX)

      local nInfluenceOrthoAngle = funcAngleBetween(vecEnemyInfluence, vecLaneForwardOrtho)

      local vecRelativeInfluence = funcRotateVec2DRad(vecEnemyInfluence, -nLaneOrthoAngle)
      if vecRelativeInfluence.y < 0 then
        nInfluenceOrthoAngle = -nInfluenceOrthoAngle
      end

      vecEnemyInfluence = funcRotateVec2DRad(vecEnemyInfluence, -nInfluenceOrthoAngle*2)
      --core.DrawDebugArrow(creepPos, creepPos + vecFlip * nLineLen, 'blue')
    end
    
    if not bIsHero then
      vecEnemyInfluence = vecEnemyInfluence * nCreepPushbackMul
    end

    --vecTotalEnemyInfluence.AddAssign(vecEnemyInfluence)
    vecTotalEnemyInfluence = vecTotalEnemyInfluence + vecEnemyInfluence

    if bDebugLines then core.DrawDebugArrow(vecEnemyPos, vecEnemyPos + vecEnemyInfluence * nLineLen, 'teal') end
    if bDebugEchos and unitEnemy then BotEcho(unitEnemy:GetTypeName()..': '..tostring(vecEnemyInfluence)) end
    
    StopProfile()
  end

  --stand appart from allies a bit
  StartProfile('Allies')
  local tAllyHeroes = tLocalUnits.AllyHeroes
  local vecTotalAllyInfluence = Vector3.Create()
  local nAllyInfluenceMul = behaviorLib.nAllyInfluenceMul
  local nPositionSelfAllySeparation = behaviorLib.nPositionSelfAllySeparation
  for nUID, unitAlly in pairs(tAllyHeroes) do
    local vecAllyPos = unitAlly:GetPosition()
    local vecCurrentAllyInfluence, nDistance = funcV3Normalize(vecMyPos - vecAllyPos)
    if nDistance < nPositionSelfAllySeparation then
      vecCurrentAllyInfluence = vecCurrentAllyInfluence * (1 - nDistance/nPositionSelfAllySeparation) * nAllyInfluenceMul
      
      --vecTotalAllyInfluence.AddAssign(vecCurrentAllyInfluence)
      vecTotalAllyInfluence = vecTotalAllyInfluence + vecCurrentAllyInfluence
      
      if bDebugLines then core.DrawDebugArrow(vecMyPos, vecMyPos + vecCurrentAllyInfluence * nLineLen, 'white') end
    end
  end
  StopProfile()

  --stand near your target
  StartProfile('Target')
  local vecTargetInfluence = Vector3.Create()
  local nTargetMul = behaviorLib.nTargetPositioningMul
  if unitCurrentTarget ~= nil and botBrain:CanSeeUnit(unitCurrentTarget) then
    local nMyRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitCurrentTarget)
    local vecTargetPosition = unitCurrentTarget:GetPosition()
    local vecToTarget, nTargetDist = funcV3Normalize(vecTargetPosition - vecMyPos)
    local nLength = 1
    if not unitCurrentTarget:IsHero() then
      nLength = nTargetDist / nMyRange
      if bDebugEchos then BotEcho('  nLength calc - nTargetDist: '..nTargetDist..'  nMyRange: '..nMyRange) end
    end

    nLength = Clamp(nLength, 0, 25)

    --Hack: get closer if they are critical health and we are out of nRange
    if unitCurrentTarget:GetHealth() < (core.GetFinalAttackDamageAverage(unitSelf) * 3) then --and nTargetDist > nMyRange then
      nTargetMul = behaviorLib.nTargetCriticalPositioningMul
    end
    
    vecTargetInfluence = vecToTarget * nLength * nTargetMul
    if bDebugEchos then BotEcho('  target '..unitCurrentTarget:GetTypeName()..': '..tostring(vecTargetInfluence)..'  nLength: '..nLength) end
  else 
    if bDebugEchos then BotEcho("PositionSelfCreepWave - target is nil") end
  end
  StopProfile()

  --sum my influences
  local vecDesiredPos = vecMyPos
  local vecDesired = vecTotalEnemyInfluence + vecTargetInfluence + vecTotalAllyInfluence
  local vecMove = vecDesired * core.moveVecMultiplier

  if bDebugEchos then BotEcho('vecDesiredPos: '..tostring(vecDesiredPos)..'  vCreepInfluence: '..tostring(vecTotalEnemyInfluence)..'  vecTargetInfluence: '..tostring(vecTargetInfluence)) end

  --minimum move distance threshold
  if Vector3.LengthSq(vecMove) >= core.distSqTolerance then
    vecDesiredPos = vecDesiredPos + vecMove
  end
  
  behaviorLib.nLastPositionTime = unitSelf.storedTime
  behaviorLib.vecLastDesiredPosition = vecDesiredPos

  --debug
  if bDebugLines then
    if vecLaneForward then
      local offset = vecLaneForwardOrtho * (nLineLen * 3)
      core.DrawDebugArrow(vecMyPos + offset, vecMyPos + offset + vecLaneForward * nLineLen, 'white')
      core.DrawDebugArrow(vecMyPos - offset, vecMyPos - offset + vecLaneForward * nLineLen, 'white')
    end

    core.DrawDebugArrow(vecMyPos, vecMyPos + vecTotalEnemyInfluence * nLineLen, 'cyan')

    if unitCurrentTarget ~= nil and botBrain:CanSeeUnit(unitCurrentTarget) then
      local color = 'cyan'
      if nTargetMul ~= behaviorLib.nTargetPositioningMul then
        color = 'orange'
      end
      core.DrawDebugArrow(vecMyPos, vecMyPos + vecTargetInfluence * nLineLen, color)
    end

    core.DrawXPosition(vecDesiredPos, 'blue')

    core.DrawDebugArrow(vecMyPos, vecMyPos + vecDesired * nLineLen, 'blue')
    --core.DrawDebugArrow(vecMyPos, vecMyPos + vProjection * nLineLen)
  end

  return vecDesiredPos
end