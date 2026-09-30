-- Arm poses layer after locomotion/diving and are restored before Animator runs.
local Players=game:GetService("Players")
local Shots={}
local states={}
local observedCharge=setmetatable({},{__mode="k"})
local function smooth(t) t=math.clamp(t,0,1); return t*t*(3-2*t) end
local function angles(x,y,z) return CFrame.Angles(math.rad(x or 0),math.rad(y or 0),math.rad(z or 0)) end
local function restore(d)
 for _,j in pairs(d.joints) do
  if j.previous and j.instance.Parent then j.instance.Transform=j.previous end
  j.previous=nil
 end
end
local function collect(c)
 local d={character=c,root=c:FindFirstChild("HumanoidRootPart"),joints={}}
 for _,j in ipairs(c:GetDescendants()) do
  if (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) and j.Part0 and j.Part1 then
   local name=j.Name:lower():gsub(" ","")
   if name=="waist" or name=="neck" or name:find("shoulder") or name:find("elbow") or name=="rightwrist" then
    d.joints[name]={instance=j}
   end
  end
 end
 return d
end
function Shots.charge(userId,enabled,startedAt)
 local p=Players:GetPlayerByUserId(userId)
 local c=p and p.Character
 if not c then return end
 local old=states[c]
 if old then restore(old) end
 if not enabled then states[c]=nil; return end
 local d=collect(c); d.start=startedAt or os.clock(); d.charging=true; states[c]=d
end
function Shots.swing(userId,backhand,slam,contact,direction,charge,soft,predicted)
 local p=Players:GetPlayerByUserId(userId)
 local c=p and p.Character
 if not c then return end
 local old=states[c]
 -- Reconcile the accepted contact without replaying the locally predicted swing.
 if old and old.predicted and not predicted and not old.charging and os.clock()-old.start<0.6 then
  old.backhand=backhand; old.slam=slam; old.contact=contact; old.direction=direction
  old.charge=charge or old.charge; old.soft=soft or old.soft; old.predicted=false
  return
 end
 local held=old and old.charging and math.clamp(os.clock()-old.start,0,1) or 0
 if old then restore(old) end
 local d=collect(c)
 d.start=os.clock(); d.backhand=backhand; d.slam=slam; d.contact=contact
 d.direction=direction; d.charge=charge or held; d.soft=soft; d.predicted=predicted
 states[c]=d
end
function Shots.release(userId)
 local p=Players:GetPlayerByUserId(userId)
 local d=p and p.Character and states[p.Character]
 -- Retain the windup briefly while the authoritative hit event travels back.
 if d and d.charging then d.releaseAt=d.releaseAt or os.clock() end
end
function Shots.restore()
 for _,d in pairs(states) do restore(d) end
end
local function pose(d,name,rotation,weight)
 local entry=d.joints[name]
 if not entry or not entry.instance.Parent then return end
 local j=entry.instance
 entry.previous=entry.previous or j.Transform
 local basis=j.C0.Rotation
 j.Transform=j.Transform:Lerp(basis:Inverse()*rotation*basis,weight)
end
local function worldPart(part,d,cache)
 if cache[part] then return cache[part] end
 for _,entry in pairs(d.joints) do
  local j=entry.instance
  if j.Part1==part then
   local cf=worldPart(j.Part0,d,cache)*j.C0*j.Transform*j.C1:Inverse()
   cache[part]=cf; return cf
  end
 end
 return part.CFrame
end
local function rotateBetween(a,b)
 a=a.Unit; b=b.Unit
 local axis=a:Cross(b); local dot=math.clamp(a:Dot(b),-1,1)
 if axis.Magnitude<0.00001 then
  if dot>0 then return CFrame.identity end
  axis=a:Cross(math.abs(a.Y)<0.9 and Vector3.yAxis or Vector3.xAxis)
 end
 return CFrame.fromAxisAngle(axis.Unit,math.acos(dot))
end
local function orientBone(localAxis,worldAxis,reference)
 return rotateBetween(reference:VectorToWorldSpace(localAxis),worldAxis)*reference
end
-- A two-bone solve positions the hand; the wrist squares the broad (-Z) face.
function Shots.contactPose(d,position,direction,weight)
 local shoulder=d.joints.rightshoulder
 local elbow=d.joints.rightelbow
 local wrist=d.joints.rightwrist
 if not shoulder or not elbow or not wrist or direction.Magnitude<0.001 then return false end
 local s,e,w=shoulder.instance,elbow.instance,wrist.instance
 local parent=worldPart(s.Part0,d,{})
 local origin=(parent*s.C0).Position
 local normal=direction.Unit
 local up=origin-position
 up=up-normal*up:Dot(normal)
 if up.Magnitude<0.01 then up=d.root.CFrame.UpVector-normal*d.root.CFrame.UpVector:Dot(normal) end
 if up.Magnitude<0.01 then up=d.root.CFrame.RightVector end
 -- Ball radius .425 + paddle half-thickness .15 puts the surface at contact.
 local face=CFrame.lookAt(position-normal*0.575,position,up.Unit)
 local hand=face*CFrame.new(0,2,0)
 local target=(hand*w.C1).Position
 local upper=e.C0.Position-s.C1.Position
 local lower=w.C0.Position-e.C1.Position
 local a,b=upper.Magnitude,lower.Magnitude
 if a<0.01 or b<0.01 then return false end
 local delta=target-origin
 if delta.Magnitude<0.01 then return false end
 local distance=math.clamp(delta.Magnitude,math.abs(a-b)+0.001,a+b-0.001)
 local axis=delta.Unit
 local pole=d.root.CFrame.RightVector*0.7-d.root.CFrame.UpVector*0.7
 pole=pole-axis*pole:Dot(axis)
 if pole.Magnitude<0.01 then pole=axis:Cross(d.root.CFrame.LookVector) end
 if pole.Magnitude<0.01 then pole=axis:Cross(Vector3.xAxis) end
 local along=(a*a-b*b+distance*distance)/(2*distance)
 local bend=origin+axis*along+pole.Unit*math.sqrt(math.max(0,a*a-along*along))
 local endpoint=origin+axis*distance
 local upperRotation=orientBone(upper,bend-origin,d.root.CFrame.Rotation)
 local upperFrame=CFrame.new(origin)*upperRotation*CFrame.new(-s.C1.Position)
 local lowerRotation=orientBone(lower,endpoint-bend,upperRotation)
 local lowerFrame=CFrame.new(bend)*lowerRotation*CFrame.new(-e.C1.Position)
 local targets={
  {shoulder,(s.C0:Inverse()*parent:Inverse()*upperFrame*s.C1).Rotation},
  {elbow,(e.C0:Inverse()*upperFrame:Inverse()*lowerFrame*e.C1).Rotation},
  {wrist,(w.C0:Inverse()*lowerFrame:Inverse()*hand*w.C1).Rotation},
 }
 for _,item in ipairs(targets) do
  local entry,cf=item[1],item[2]
  entry.previous=entry.previous or entry.instance.Transform
  entry.instance.Transform=entry.instance.Transform:Lerp(cf,weight)
 end
 return delta.Magnitude<=a+b
end
function Shots.update()
 -- Server attributes expose the windup to opponents without per-frame remotes.
 for _,p in ipairs(Players:GetPlayers()) do
  local c=p.Character
  if c and p~=Players.LocalPlayer then
   local started=c:GetAttribute("ShotChargeAt")
   local d=states[c]
   if started and started~=observedCharge[c] then
    Shots.charge(p.UserId,true)
    states[c].start=os.clock()-math.max(0,workspace:GetServerTimeNow()-started)
   elseif not started and d and d.charging then Shots.release(p.UserId) end
   observedCharge[c]=started
  end
 end
 for c,d in pairs(states) do
  local h=c:FindFirstChildOfClass("Humanoid")
  local t=os.clock()-d.start
  local duration=d.slam and 0.62 or 0.52+0.1*(d.charge or 0)
  if not c.Parent or not d.root or not d.root.Parent or not h or h.Health<=0
   or (not d.charging and t>=duration) or (d.releaseAt and os.clock()-d.releaseAt>0.3) then
   restore(d); states[c]=nil
  else
   local charge=d.charging and math.clamp((t-0.4)/0.6,0,1) or d.charge or 0
   local side=d.backhand and -1 or 1
   -- A tap is a normal swing; only begin showing the windup after the charge threshold.
   local weight=d.charging and smooth((t-0.4)/0.15) or (1-smooth((t-duration*0.55)/(duration*0.45)))
   local follow=d.charging and 0 or smooth(t/0.25)
   local twist=d.charging and (-16-12*charge) or side*(d.soft and (3+9*follow) or (8+24*follow))
   if not c:GetAttribute("Diving") then
    pose(d,"waist",angles(d.charging and -4 or -10,twist,0),weight)
    pose(d,"neck",angles(4,-twist*0.55,0),weight)
   end
   pose(d,"leftshoulder",angles(30,0,-25),weight)
   pose(d,"leftelbow",angles(45),weight)
   local shoulder=d.charging and angles(35+20*charge,-40-20*charge,25)
    or (d.soft and angles((d.soft=="dink" and 12 or 20)+35*follow,side*(8+18*follow),8))
    or (d.slam and angles(110-70*follow,15+20*follow,12) or angles(70-15*follow,side*(10+65*follow),12-25*follow))
   pose(d,"rightshoulder",shoulder,weight)
   pose(d,"rightelbow",angles(d.charging and 50+25*charge or d.soft and 15+15*follow or 20+40*follow),weight)
   pose(d,"rightwrist",angles(0,d.charging and -15 or 10*follow,0),weight)
   if not d.charging and d.contact and d.direction then
    -- Contact is immediate: gameplay has already launched the ball at this event.
    Shots.contactPose(d,d.contact,d.direction,(1-smooth(t/0.16))*weight)
   end
  end
 end
end
return Shots
