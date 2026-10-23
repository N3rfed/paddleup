local View={}
local player=game:GetService("Players").LocalPlayer
function View.height() return player:GetAttribute("CourtHeight") or 0 end
function View.root()
 local id=player:GetAttribute("CourtId") or 0
 return workspace:FindFirstChild(id==0 and "PaddleUp" or "PaddleUpCourt"..id)
end
return View
