local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rules
local Overlay={}
local folder=Instance.new("Folder")
folder.Name="DeveloperHitboxes"
local shapes={}
local function part(name,color,shape)
 local p=Instance.new("Part")
 p.Name=name; p.Shape=shape; p.Color=color; p.Material=Enum.Material.ForceField
 p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false
 p.Transparency=0.8; p.Parent=folder
 return p
end
function Overlay.update(enabled)
 folder.Parent=enabled and workspace or nil
 if not enabled then return end
 if not Rules then
  local shared=ReplicatedStorage:FindFirstChild("Shared")
  local module=shared and shared:FindFirstChild("MatchRules")
  if not module then return end
  Rules=require(module)
 end
 local active={}
 for _,player in ipairs(Players:GetPlayers()) do
  local c=player.Character
  local r=c and c:FindFirstChild("HumanoidRootPart")
  local h=c and c:FindFirstChildOfClass("Humanoid")
  if r and h and h.Health>0 and player:GetAttribute("CourtSide")~=0 then
   active[player]=true
   local parts=shapes[player]
   if not parts then
    parts={part("Hit radius 12",Color3.fromRGB(255,190,60),Enum.PartType.Ball),
     part("Perfect radius 9",Color3.fromRGB(90,240,160),Enum.PartType.Ball),
     part("Slam vertical zone",Color3.fromRGB(60,150,255),Enum.PartType.Cylinder),
     part("Slam paddle limit 16",Color3.fromRGB(170,120,255),Enum.PartType.Ball),
     part("Rear contact cutoff",Color3.fromRGB(255,70,70),Enum.PartType.Block)}
    shapes[player]=parts
   end
   parts[5].Size=Vector3.new(32,32,0.08)
   parts[5].CFrame=r.CFrame*CFrame.new(0,0,Rules.REAR_REACH)
   local face=c:FindFirstChild("PaddleFace")
   local center=face and face.Position or r.Position
   for i,radius in pairs({[1]=Rules.HIT_RANGE,[2]=Rules.PERFECT_RANGE,[4]=Rules.SLAM_RANGE}) do
    parts[i].Size=Vector3.one*radius*2; parts[i].Position=center
   end
   local minY,maxY=Rules.slamBounds(c,r)
   parts[3].Size=Vector3.new(maxY-minY,Rules.SLAM_HORIZONTAL*2,Rules.SLAM_HORIZONTAL*2)
   parts[3].CFrame=CFrame.new(r.Position.X,(minY+maxY)/2,r.Position.Z)*CFrame.Angles(0,0,math.pi/2)
  end
 end
 for player,parts in pairs(shapes) do
  if not active[player] then
   for _,p in ipairs(parts) do p:Destroy() end
   shapes[player]=nil
  end
 end
end
return Overlay
