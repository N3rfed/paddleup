-- Standard Roblox R15 bodies, generated once on the server and shared with every viewport.
local Mannequins={}
function Mannequins.prepare()
 local ReplicatedStorage=game:GetService("ReplicatedStorage")
 local existing=ReplicatedStorage:FindFirstChild("ShopMannequins")
 if existing then return existing end
 local folder=Instance.new("Folder"); folder.Name="ShopMannequins"
 for _,fit in ipairs({"Male","Female"}) do
  local description=Instance.new("HumanoidDescription")
  description.Torso=fit=="Male" and 86500008 or 86499666
  description.LeftArm=fit=="Male" and 86500054 or 86499716
  description.RightArm=fit=="Male" and 86500036 or 86499698
  description.LeftLeg=fit=="Male" and 86500064 or 86499753
  description.RightLeg=fit=="Male" and 86500078 or 86499793
  description.HairAccessory=fit=="Male" and "16630147" or "62724852"
  description.WidthScale=fit=="Male" and 1 or 0.95
  description.DepthScale=0.95; description.HeightScale=1; description.HeadScale=1
  description.BodyTypeScale=0; description.ProportionScale=0
  local skin=Color3.fromRGB(214,177,145)
  for _,name in ipairs({"HeadColor","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor","TorsoColor"}) do description[name]=skin end
  local ok,rig=pcall(function()
   return game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
  end)
  if not ok then
   warn("Shop mannequin body request failed; retrying with the standard R15 body: "..tostring(rig))
   description.Torso=0; description.LeftArm=0; description.RightArm=0; description.LeftLeg=0; description.RightLeg=0
   description.HairAccessory=""
   rig=game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
  end
  description:Destroy(); rig.Name=fit
  -- Returned rigs can still have unassembled accessory transforms. Solve the
  -- attachment weld before anchoring, otherwise hair floats in front of the outfit.
  for _,accessory in ipairs(rig:GetChildren()) do
   if accessory:IsA("Accessory") then
    local handle=accessory:FindFirstChild("Handle")
    local weld=handle and handle:FindFirstChild("AccessoryWeld")
    if weld and weld:IsA("Weld") and weld.Part0 and weld.Part1 then
     if weld.Part0==handle then handle.CFrame=weld.Part1.CFrame*weld.C1*weld.C0:Inverse()
     elseif weld.Part1==handle then handle.CFrame=weld.Part0.CFrame*weld.C0*weld.C1:Inverse() end
    end
   end
  end
  for _,item in ipairs(rig:GetDescendants()) do
   if item:IsA("LuaSourceContainer") then item:Destroy()
   elseif item:IsA("BasePart") then
    item.Anchored=true; item.CanCollide=false; item.CanTouch=false; item.CanQuery=false; item.Massless=true; item.CastShadow=false
   end
  end
  local humanoid=rig:FindFirstChildOfClass("Humanoid")
  if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; humanoid.EvaluateStateMachine=false end
  local root=rig:FindFirstChild("HumanoidRootPart"); if root then root.Transparency=1 end
  local cf,size=rig:GetBoundingBox()
  rig:PivotTo(rig:GetPivot()-Vector3.new(cf.Position.X,cf.Position.Y-size.Y/2,cf.Position.Z))
  rig:SetAttribute("ShopFit",fit); rig.Parent=folder
 end
 folder.Parent=ReplicatedStorage
 return folder
end
return Mannequins
