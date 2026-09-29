-- Procedural court footwork. DiveController owns update ordering so paddle
-- strokes and dives can layer over this pose without competing for joints.
local Players=game:GetService("Players")
local Movement={}
local Pose=require(script.Parent:WaitForChild("SportsPose"))
Movement.Pose=Pose
local rigs={}
local supported={root=true,rootjoint=true,waist=true,neck=true,
 lefthip=true,righthip=true,leftknee=true,rightknee=true,
 leftankle=true,rightankle=true,leftshoulder=true,rightshoulder=true,
 leftelbow=true,rightelbow=true,rightwrist=true}

local function restore(d)
 for _,j in ipairs(d.joints) do
  if j.previous and j.instance.Parent then j.instance.Transform=j.previous end
  j.previous=nil
 end
end

function Movement.restore()
 for _,d in pairs(rigs) do restore(d) end
end

function Movement.destroy()
 for _,d in pairs(rigs) do restore(d); d.added:Disconnect() end
 table.clear(rigs)
end

local function collect(character,d)
 restore(d)
 table.clear(d.joints)
 for _,joint in ipairs(character:GetDescendants()) do
  if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
   local name=joint.Name:lower():gsub(" ","")
   if supported[name] and joint.Part0 and joint.Part1 then
    table.insert(d.joints,{instance=joint,name=name})
   end
  end
 end
 local named={}
 for _,j in ipairs(d.joints) do named[j.name]=j.instance end
 d.r15=named.leftknee~=nil and named.rightknee~=nil
 local function leg(side)
  local hip,knee,ankle=named[side.."hip"],named[side.."knee"],named[side.."ankle"]
  if not hip or not knee or not ankle then return nil end
  return {math.max(0.2,(hip.C1.Position-knee.C0.Position).Magnitude),
   math.max(0.2,(knee.C1.Position-ankle.C0.Position).Magnitude)}
 end
 d.leftLeg=leg("left"); d.rightLeg=leg("right")
 d.dirty=false
end

function Movement.update(dt)
 local active={}
 for _,player in ipairs(Players:GetPlayers()) do
  local c=player.Character
  local r=c and c:FindFirstChild("HumanoidRootPart")
  local h=c and c:FindFirstChildOfClass("Humanoid")
  if r and h then
   active[c]=true
   local d=rigs[c]
   if not d then
    d={joints={},phase=0,weight=0,velocity=Vector3.zero,charge=0,dirty=true}
    d.added=c.DescendantAdded:Connect(function(item)
     if item:IsA("Motor6D") or item:IsA("AnimationConstraint") then d.dirty=true end
    end)
    rigs[c]=d
   end
   if d.dirty then collect(c,d) end
   local response=1-math.exp(-math.min(dt,0.1)*14)
   local velocity=r.CFrame:VectorToObjectSpace(r.AssemblyLinearVelocity)
   local horizontal=Vector3.new(velocity.X,0,velocity.Z)
   -- Ignore replication corrections and teleports when driving the gait.
   if horizontal.Magnitude>26 then horizontal=horizontal.Unit*26 end
   d.velocity=d.velocity:Lerp(horizontal,response)
   local speed=d.velocity.Magnitude
   local amount=math.clamp(speed/18,0,1)
   local forward=speed>0.1 and -d.velocity.Z/speed or 0
   local lateral=speed>0.1 and d.velocity.X/speed or 0
   local state=h:GetState()
   local grounded=h.FloorMaterial~=Enum.Material.Air and h.Health>0 and not h.Sit
    and state~=Enum.HumanoidStateType.Climbing and state~=Enum.HumanoidStateType.Swimming
    and state~=Enum.HumanoidStateType.Jumping and state~=Enum.HumanoidStateType.Freefall
   local available=grounded and not c:GetAttribute("Diving")
   d.weight+=( (available and 1 or 0)-d.weight)*response
   local chargeStart=c:GetAttribute("ShotChargeStarted")
   local charge=typeof(chargeStart)=="number" and math.clamp(workspace:GetServerTimeNow()-chargeStart,0,1) or 0
   d.charge+=(charge-d.charge)*response
   -- One cycle is two alternating steps; speed drives cadence, never frame rate.
   d.phase=(d.phase+dt*1.85*amount)%1
   local legLength=d.leftLeg and (d.leftLeg[1]+d.leftLeg[2]) or 2
   local crouch=(d.r15 and (0.055+0.025*amount) or 0.015)*legLength
   local sample={phase=d.phase,forward=forward,lateral=lateral,amount=amount,
    charge=d.charge,crouch=crouch,r15=d.r15,leftLeg=d.leftLeg,rightLeg=d.rightLeg}
   for _,j in ipairs(d.joints) do
    local joint=j.instance
    if joint.Parent and d.weight>0.001 then
     local pose=Pose.atJoint(joint,Pose.walk(j.name,sample))
     j.previous=joint.Transform
     joint.Transform=j.previous:Lerp(pose,d.weight)
    end
   end
  end
 end
 for c,d in pairs(rigs) do
  if not active[c] then restore(d); d.added:Disconnect(); rigs[c]=nil end
 end
end

return Movement
