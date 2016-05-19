local _G = getfenv(0)
local object = _G.object

runfile 'bots/teams/mid_xor_feed/teambotbrain.lua'

object.myName = 'MidXORFeed'

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
