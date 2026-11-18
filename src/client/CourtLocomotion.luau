-- Preserve the lobby Animator gait; layer court adjustments before dives/swings.
-- Works for every observed player, without uploaded animation dependencies.
local Players=game:GetService("Players")
local Motion={}
local actors={}
local function angles(x,y,z) return CFrame.Angles(math.rad(x or 0),math.rad(y or 0),math.rad(z or 0)) end
local function collect(c)
 local d={joints={},phase=0,weight=0,airborne=false,airTime=0,takeoffStride=0,land=0}
 for _,j in ipairs(c:GetDescendants()) do
  if (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) and j.Part0 and j.Part1 then
   local name=j.Name:lower():gsub(" ","")
   if j.Part0.Name=="HumanoidRootPart" or name:find("waist") or name:find("neck") or name:find("hip") or name:find("knee") or name:find("ankle") or name:find("shoulder") or name:find("elbow") then
    d.joints[name]={instance=j,pose=CFrame.identity,root=j.Part0.Name=="HumanoidRootPart"}
   end
  end
 end
 return d
end
function Motion.restore()
 for c,d in pairs(actors) do
  for _,j in pairs(d.joints) do
   if j.previous and j.instance.Parent then j.instance.Transform=j.previous end
   j.previous=nil
  end
  if not c.Parent then actors[c]=nil end
 end
end
function Motion.update(dt)
 local present={}
 for _,p in ipairs(Players:GetPlayers()) do
  local c=p.Character
  local h=c and c:FindFirstChildOfClass("Humanoid")
  local r=c and c:FindFirstChild("HumanoidRootPart")
  if not c or not h or not r then continue end
  local active=(p:GetAttribute("CourtSide") or 0)~=0 and h.Health>0 and not h.Sit
   and not p:GetAttribute("PracticePaused")
  local d=actors[c]
  if not d and active then d=collect(c); actors[c]=d end
  if not d then continue end
  present[c]=true
  local blend=1-math.exp(-18*math.min(dt,0.1))
  d.weight+=( (active and 1 or 0)-d.weight)*blend
  if d.weight<0.001 then continue end
  local v=r.CFrame:VectorToObjectSpace(r.AssemblyLinearVelocity)
  local speed=Vector3.new(v.X,0,v.Z).Magnitude
  local stride=math.clamp(speed/18,0,1.25)
  local forward=speed>0.5 and -v.Z/speed or 0
  local lateral=speed>0.5 and v.X/speed or 0
  d.phase+=math.min(dt,0.1)*math.pi*2*2.3*math.clamp(speed/18,0,1.6)
  local airborne=h.FloorMaterial==Enum.Material.Air
  if airborne and not d.airborne then
   d.airTime=0
   d.takeoffStride=math.sin(d.phase)*math.min(stride,1)
  end
  if d.airborne and not airborne then d.land=1 end
  d.airTime=airborne and d.airTime+math.min(dt,0.1) or 0
  d.airborne=airborne
  d.land=math.max(0,d.land-dt*4.5)
  -- Continuous takeoff/apex/descent blend, including low-gravity jumps.
  local ascent=math.clamp((r.AssemblyLinearVelocity.Y+10)/35,0,1)
  ascent=ascent*ascent*(3-2*ascent)
  local takeoff=airborne and math.sin(math.clamp(d.airTime/0.32,0,1)*math.pi) or 0
  local tuck=airborne and math.clamp(ascent*0.8+takeoff*0.65,0,1) or 0
  local legOffset=airborne and d.takeoffStride*math.exp(-d.airTime*3) or 0
  -- Hip and chest counter-rotation follows the stride, never the aiming root.
  local slipAge=workspace:GetServerTimeNow()-(c:GetAttribute("CourtSlipStarted") or -math.huge)
  local stumble=0
  if slipAge>=0 and slipAge<1 then
   stumble=math.min(1,slipAge/0.1)*math.min(1,(1-slipAge)/0.4)
  end
  local groundStride=airborne and 0 or stride
  local beat=math.sin(d.phase)
  local bounce=(1-math.cos(d.phase*2))*0.5
  local hipYaw=beat*2*groundStride
  local hipRoll=beat*1.5*groundStride
  local chestYaw=-beat*3*groundStride
  local chestRoll=-beat*1.5*groundStride
  for name,j in pairs(d.joints) do
   if not j.instance.Parent then continue end
   local side=name:find("left") and -1 or 1
   local cycle=math.sin(d.phase+(side==1 and math.pi or 0))
   local lift=math.max(0,cycle)
   local pose=CFrame.identity
   if j.root then
    pose=CFrame.new(beat*0.015*groundStride,
     -bounce*0.025*groundStride-d.land*0.12,0)
     *angles(-2*groundStride-3*tuck,hipYaw,hipRoll)
   elseif name:find("waist") then
    pose=angles(-2*groundStride+math.cos(d.phase*2)*0.5*groundStride-4*tuck,
     chestYaw,chestRoll)
   elseif name:find("neck") then
    -- Counter the small visual chest twist so the gaze stays steady.
    pose=angles(groundStride,-(hipYaw+chestYaw)*0.7,-(hipRoll+chestRoll)*0.6)
   elseif name:find("hip") then
    if airborne then
     pose=angles(-3-12*tuck+side*7*legOffset,0,side*2)
    else
     pose=angles(-cycle*8*stride*math.max(0,-forward)-d.land*16,0,side*2*math.abs(lateral)-cycle*12*stride*lateral)
    end
   elseif name:find("knee") then
    pose=angles(airborne and (5+20*tuck-side*5*legOffset) or lift*8*stride*math.abs(lateral)+d.land*28)
   elseif name:find("ankle") then
    pose=angles(airborne and (3-9*tuck) or -lift*4*stride*math.abs(lateral)-d.land*8)
   elseif name:find("shoulder") then
    -- Relaxed athletic arm drive; ShotAnimation overlays the paddle arm on contact.
    -- Free arm sights the ball; paddle arm coils above/behind the head.
    pose=airborne and (side==1 and angles(145+12*tuck,-20,18) or angles(65+8*tuck,0,-18))
     or angles(4,side*2,side*4)
   elseif name:find("elbow") then
    pose=angles(airborne and (side==1 and 95-10*tuck or 20+6*tuck) or 8)
   end
   if stumble>0 then
    local catch=math.sin(slipAge*11)
    local trip
    if j.root then trip=angles(24,0,12*catch)
    elseif name:find("hip") then trip=angles(side*34*catch,0,side*9)
    elseif name:find("knee") then trip=angles(26-side*18*catch)
    elseif name:find("shoulder") then trip=angles(38+side*19*catch,0,side*48) end
    if trip then pose=pose:Lerp(trip,stumble) end
   end
   local basis=j.instance.C0.Rotation
   local target=basis:Inverse()*pose*basis
   local poseBlend=airborne and (name:find("shoulder") or name:find("elbow")) and (1-math.exp(-40*math.min(dt,0.1))) or (1-math.exp(-18*math.min(dt,0.1)))
   j.pose=j.pose:Lerp(target,poseBlend)
   j.previous=j.instance.Transform
   -- Preserve Animator motion in the air too. The small jump overlay follows
   -- velocity rather than replacing the entire body with a held pose.
   local overheadArm=airborne and (name:find("shoulder") or name:find("elbow"))
   local animatedTarget=overheadArm and j.pose or j.previous*j.pose
   local output=j.previous:Lerp(animatedTarget,d.weight)
   local arm=name:find("shoulder") or name:find("elbow")
   if arm and j.output then
    -- Blend the resolved pose, not just the overlay. This avoids a composition
    -- discontinuity when landing changes absolute overhead poses to additive ones.
    local _,angle=(j.output:Inverse()*output):ToAxisAngle()
    local limit=math.rad(airborne and (rising and 1400 or 1000) or 700)*math.min(dt,0.1)
    local amount=math.min(poseBlend,limit/math.max(angle,0.0001))
    output=j.output:Lerp(output,amount)
   end
   j.output=output
   j.instance.Transform=output
  end
 end
 for c in pairs(actors) do if not present[c] then actors[c]=nil end end
end
return Motion
