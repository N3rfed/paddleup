-- Client-owned movement and procedural poses for Motor6D and upgraded avatar joints.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Controller={}
local active={}
local swings={}
local Movement
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
function Controller.swing(userId,backhand,slam)
 local p=Players:GetPlayerByUserId(userId)
 local c=p and p.Character
 local root=c and c:FindFirstChild("HumanoidRootPart")
 if not root then return end
 if swings[c] then restorePose(swings[c]) end
 local humanoid=c:FindFirstChildOfClass("Humanoid")
 local d={start=os.clock(),root=root,backhand=backhand,slam=slam,r15=humanoid and humanoid.RigType==Enum.HumanoidRigType.R15,joints={}}
 for _,joint in ipairs(c:GetDescendants()) do
  if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
   local name=joint.Name:lower():gsub(" ","")
   if name:find("shoulder") or name:find("elbow") or name=="rightwrist" or name=="waist" or name=="neck" or name=="root" or name=="rootjoint" then
    table.insert(d.joints,{instance=joint,name=name})
   end
  end
 end
 swings[c]=d
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
 if active[c] then finish(c,active[c]) end
 local d={root=root,humanoid=humanoid,direction=direction,start=os.clock(),joints={},localPlayer=p==Players.LocalPlayer,side=p:GetAttribute("CourtSide") or 1}
 for _,joint in ipairs(c:GetDescendants()) do
  if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
   local name=joint.Name:lower():gsub(" ","")
   if joint.Part0 and joint.Part1 then
    table.insert(d.joints,{instance=joint,name=name})
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
 for _,d in pairs(swings) do restorePose(d) end
 for _,d in pairs(active) do restorePose(d) end
 if Movement then Movement.restore() end
end)
RunService.PreSimulation:Connect(function(dt)
 if not Movement then
  local module=script.Parent:FindFirstChild("AthleticMovement")
  if module then Movement=require(module) end
 end
 if Movement then Movement.update(dt) end
 for c,d in pairs(active) do
  local elapsed=os.clock()-d.start
  if not c.Parent or not d.root.Parent or d.humanoid.Health<=0 or elapsed>=POSE_TIME then
   finish(c,d)
  else
   if d.airForce and (elapsed>=0.34 or d.humanoid.FloorMaterial~=Enum.Material.Air) then
    d.airForce:Destroy(); d.airAttachment:Destroy(); d.airForce=nil
   end
   if Movement then
    local localDirection=d.root.CFrame:VectorToObjectSpace(d.direction)
    for _,j in ipairs(d.joints) do
     if j.instance.Parent then
      local target,weight=Movement.Pose.dive(j.name,localDirection,elapsed)
      j.previous=j.instance.Transform
      j.instance.Transform=j.previous:Lerp(Movement.Pose.atJoint(j.instance,target),weight)
     end
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
    -- Camera controls facing independently of dive travel for shot aiming.
    local velocity=r.AssemblyLinearVelocity
    r.AssemblyLinearVelocity=Vector3.new(direction.X*speed,velocity.Y,direction.Z*speed)
   end
  end
 end
 -- Coordinate the chest, gaze, paddle arm, and balancing arm through contact.
 for c,d in pairs(swings) do
  local elapsed=os.clock()-d.start
  if not c.Parent or not d.root.Parent or elapsed>=(d.slam and 0.46 or 0.36) then
   restorePose(d)
   swings[c]=nil
  elseif Movement then
   for _,j in ipairs(d.joints) do
    local joint=j.instance
    if joint.Parent then
     local target,weight=Movement.Pose.stroke(j.name,elapsed,d.backhand,d.slam,d.r15)
     local dive=active[c]
     if dive then
      -- Preserve the dive's body orientation; the arm still reaches toward aim.
      if j.name=="waist" or j.name=="neck" or j.name=="root" or j.name=="rootjoint" then target=nil
      elseif target and j.name:find("shoulder") then
       local localDirection=d.root.CFrame:VectorToObjectSpace(dive.direction)
       local diveTarget,diveWeight=Movement.Pose.dive("root",localDirection,os.clock()-dive.start)
       local bodyTilt=CFrame.identity:Lerp(diveTarget.Rotation,diveWeight)
       target=bodyTilt:Inverse()*target
      end
     end
     if target then
      j.previous=joint.Transform
      joint.Transform=j.previous:Lerp(Movement.Pose.atJoint(joint,target),weight)
     end
    end
   end
  end
 end
end)
return Controller
