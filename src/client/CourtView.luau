local View={}
local player=game:GetService("Players").LocalPlayer
function View.height() return player:GetAttribute("CourtHeight") or 0 end
function View.root()
 local id=player:GetAttribute("CourtId") or 0
 return workspace:FindFirstChild(id==0 and "PaddleUp" or "PaddleUpCourt"..id)
end
-- The present lunar benches are along +X. Keep the free camera above that
-- sideline and inside the platform, with room to move along the full court.
function View.clampMoonSpectator(position,height)
 return Vector3.new(
  math.clamp(position.X,34,62),
  math.clamp(position.Y,190+height,230+height),
  math.clamp(position.Z,-65,65))
end
return View
