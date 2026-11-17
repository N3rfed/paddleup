-- Visual camera offset is applied AFTER aim/camera calculation; never rotate the root.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Feedback={}
local started=-math.huge
function Feedback.hit(message)
 if type(message)=="table" and message.slam and message.userId==Players.LocalPlayer.UserId then started=os.clock() end
end
RunService:BindToRenderStep("SlamCameraShake",Enum.RenderPriority.Camera.Value+2,function()
 local age=os.clock()-started
 local p=Players.LocalPlayer
 if age>=0.28 or (p:GetAttribute("CourtSide") or 0)==0 or p:GetAttribute("PracticePaused") then return end
 local camera=workspace.CurrentCamera
 if not camera then return end
 local fade=(1-age/0.28)^2
 camera.CFrame*=CFrame.new(math.sin(age*160)*0.16*fade,math.sin(age*120)*0.12*fade,0)
  *CFrame.Angles(math.rad(1.15)*math.sin(age*100)*fade,0,math.rad(0.65)*math.sin(age*140)*fade)
end)
return Feedback
