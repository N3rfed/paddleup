-- Client-owned movement and procedural poses for Motor6D and upgraded avatar joints.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Controller={}
local active={}
local MOVE_TIME,POSE_TIME=0.46,0.72
local function smooth(x)
 x=math.clamp(x,0,1)
 return x*x*(3-2*x)
end
local function restorePose(d)
 for _,j in ipairs(d.joints) do
  if j.instance.Parent and j.previous then
   j.instance.Transform=j.previous
   j.previous=nil
  end
 end
end
local function finish(character,d)
 restorePose(d)
 character:SetAttribute("Diving",nil)
 if d.localPlayer and d.humanoid.Parent then
  d.humanoid.AutoRotate=d.autoRotate
  d.humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,d.jumpEnabled)
  if d.root.Parent then
   local v=d.root.AssemblyLinearVelocity
   d.root.AssemblyLinearVelocity=Vector3.new(0,v.Y,0)
  end
 end
 active[character]=nil
end
function Controller.play(userId,direction)
 local p=Players:GetPlayerByUserId(userId)
 local c=p and p.Character
 local root=c and c:FindFirstChild("HumanoidRootPart")
 local humanoid=c and c:FindFirstChildOfClass("Humanoid")
 if not root or not humanoid or humanoid.Health<=0 then return end
 if active[c] then finish(c,active[c]) end
 local d={root=root,humanoid=humanoid,direction=direction,start=os.clock(),joints={},localPlayer=p==Players.LocalPlayer,side=p:GetAttribute("CourtSide") or 1}
 for _,joint in ipairs(c:GetDescendants()) do
  if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
   local name=joint.Name:lower()
   local rotation,offset
   if joint.Part0==root then
    rotation=Vector3.new(-74,0,0); offset=Vector3.new(0,-0.55,-0.2)
   elseif name:find("shoulder") then
    rotation=Vector3.new(155,0,name:find("right") and 12 or -12)
   elseif name:find("hip") then
    rotation=Vector3.new(name:find("right") and 8 or -8,0,0)
   elseif name:find("knee") then rotation=Vector3.new(18,0,0)
   elseif name:find("neck") then rotation=Vector3.new(30,0,0)
   elseif name:find("elbow") then rotation=Vector3.new(-12,0,0)
   elseif name:find("waist") then rotation=Vector3.zero end
   if rotation then
    -- Convert a pose in the parent-part axes to the joint's local axes (also works on R6).
    local basis=joint.C0.Rotation
    local pose=basis:Inverse()*CFrame.new(offset or Vector3.zero)*CFrame.Angles(math.rad(rotation.X),math.rad(rotation.Y),math.rad(rotation.Z))*basis
    table.insert(d.joints,{instance=joint,pose=pose})
   end
  end
 end
 if d.localPlayer then
  d.autoRotate=humanoid.AutoRotate
  d.jumpEnabled=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
  humanoid.AutoRotate=false
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  d.raycast=RaycastParams.new()
  d.raycast.FilterType=Enum.RaycastFilterType.Exclude
  d.raycast.FilterDescendantsInstances={c}
  d.raycast.RespectCanCollide=true
 end
 c:SetAttribute("Diving",true)
 active[c]=d
end
-- Remove our previous overlay before the Animator evaluates the next frame.
RunService.PreAnimation:Connect(function()
 for _,d in pairs(active) do restorePose(d) end
end)
RunService.PreSimulation:Connect(function(dt)
 for c,d in pairs(active) do
  local elapsed=os.clock()-d.start
  if not c.Parent or not d.root.Parent or d.humanoid.Health<=0 or elapsed>=POSE_TIME then
   finish(c,d)
  else
   local weight=smooth(elapsed/0.12)*(1-smooth((elapsed-0.43)/0.29))
   for _,j in ipairs(d.joints) do
    if j.instance.Parent then
     j.previous=j.instance.Transform
     j.instance.Transform=j.previous:Lerp(j.pose,weight)
    end
   end
   if d.localPlayer then
    local r,h=d.root,d.humanoid
    h:Move(Vector3.zero,false)
    h.Jump=false
    local direction=d.direction
    local speed=elapsed<MOVE_TIME and 44*(1-smooth(elapsed/MOVE_TIME)) or 0
    local position=r.Position
    local safeStep=math.max(dt,1/240)
    -- Brake before court edges so the server's containment correction never fires.
    local allowance=math.huge
    if math.abs(direction.X)>0.001 then
     allowance=math.min(allowance,((direction.X>0 and 23 or -23)-position.X)/direction.X)
    end
    if math.abs(direction.Z)>0.001 then
     local minZ,maxZ=d.side==1 and 3.5 or -45,d.side==1 and 45 or -3.5
     allowance=math.min(allowance,((direction.Z>0 and maxZ or minZ)-position.Z)/direction.Z)
    end
    speed=math.min(speed,math.max(0,allowance-0.15)/safeStep)
    local hit=workspace:Raycast(position,direction*(speed*safeStep+1.6),d.raycast)
    if hit then speed=math.min(speed,math.max(0,hit.Distance-1.6)/safeStep) end
    local desired=CFrame.lookAt(position,position+direction)
    r.CFrame=r.CFrame:Lerp(desired,1-math.exp(-dt*24))
    local velocity=r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity=Vector3.new(direction.X*speed,velocity.Y,direction.Z*speed)
   end
  end
 end
end)
return Controller
