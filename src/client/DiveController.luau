-- Client-owned movement and procedural poses for Motor6D and upgraded avatar joints.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Controller={}
local active={}
local Shots=require(script.Parent:WaitForChild("ShotAnimation"))
Controller.charge=Shots.charge
Controller.release=Shots.release
Controller.swing=Shots.swing
local MOVE_TIME,POSE_TIME=0.48,0.66
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
 if d.airForce then d.airForce:Destroy(); d.airAttachment:Destroy(); d.airForce=nil end
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
 direction=Vector3.new(direction.X,0,direction.Z)
 if direction.Magnitude<0.001 then return end
 direction=direction.Unit
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
    table.insert(d.joints,{instance=joint,pose=pose,rootJoint=joint.Part0==root,
     offset=offset or Vector3.zero,rotation=CFrame.Angles(math.rad(rotation.X),math.rad(rotation.Y),math.rad(rotation.Z))})
   end
  end
 end
 if d.localPlayer then
  if humanoid.FloorMaterial==Enum.Material.Air then
   local velocity=root.AssemblyLinearVelocity
   root.AssemblyLinearVelocity=Vector3.new(velocity.X,math.clamp(velocity.Y,-4,8),velocity.Z)
   d.airAttachment=Instance.new("Attachment",root)
   d.airForce=Instance.new("VectorForce")
   d.airForce.Attachment0=d.airAttachment; d.airForce.RelativeTo=Enum.ActuatorRelativeTo.World
   d.airForce.ApplyAtCenterOfMass=true
   d.airForce.Force=Vector3.new(0,root.AssemblyMass*workspace.Gravity*0.8,0)
   d.airForce.Parent=root
  end
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
 Shots.restore()
 for _,d in pairs(active) do restorePose(d) end
end)
RunService.PreSimulation:Connect(function(dt)
 for c,d in pairs(active) do
  local elapsed=os.clock()-d.start
  if not c.Parent or not d.root.Parent or d.humanoid.Health<=0 or elapsed>=POSE_TIME then
   finish(c,d)
  else
   if d.airForce and (elapsed>=0.34 or d.humanoid.FloorMaterial~=Enum.Material.Air) then
    d.airForce:Destroy(); d.airAttachment:Destroy(); d.airForce=nil
   end
   local weight=smooth(elapsed/0.08)*(1-smooth((elapsed-0.44)/0.22))
   for _,j in ipairs(d.joints) do
    if j.instance.Parent then
     j.previous=j.instance.Transform
     local target=j.pose
     if j.rootJoint then
      -- Turn the whole dive pose into the travel direction. Recompute relative
      -- yaw each frame so camera aiming cannot turn the body away mid-dive.
      local facing=CFrame.lookAt(Vector3.zero,d.direction).Rotation
      local relative=d.root.CFrame.Rotation:Inverse()*facing
      local basis=j.instance.C0.Rotation
      target=basis:Inverse()*relative*CFrame.new(j.offset)*j.rotation*basis
     end
     j.instance.Transform=j.previous:Lerp(target,weight)
    end
   end
   if d.localPlayer then
    local r,h=d.root,d.humanoid
    h:Move(Vector3.zero,false)
    h.Jump=false
    local direction=d.direction
    local speed=elapsed<MOVE_TIME and 64*(1-smooth(elapsed/MOVE_TIME)) or 0
    local position=r.Position
    local safeStep=math.max(dt,1/240)
    local hit=workspace:Raycast(position,direction*(speed*safeStep+1.6),d.raycast)
    if hit then speed=math.min(speed,math.max(0,hit.Distance-1.6)/safeStep) end
    -- Root facing remains available for shot aim; the body pose follows travel.
    local velocity=r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity=Vector3.new(direction.X*speed,velocity.Y,direction.Z*speed)
   end
  end
 end
 Shots.update()
end)
return Controller
