-- Poses are expressed in the parent body's axes, then converted at the joint.
-- Roblox characters face -Z: hips/elbows flex with +X, knees flex with -X.
local Pose={}
local function angles(x,y,z)
 return CFrame.Angles(math.rad(x or 0),math.rad(y or 0),math.rad(z or 0))
end
function Pose.smooth(t)
 t=math.clamp(t,0,1)
 return t*t*(3-2*t)
end
function Pose.atJoint(joint,parentPose)
 local basis=joint.C0.Rotation
 return basis:Inverse()*parentPose*basis
end

-- 60% planted stance followed by a lifted recovery step. The two legs are
-- half a cycle apart; their swing phases never overlap at walking speeds.
function Pose.step(phase)
 phase=phase%1
 if phase<0.6 then return 0.5-phase/0.6,0,true end
 local swing=(phase-0.6)/0.4
 return -0.5+Pose.smooth(swing),math.sin(math.pi*swing)^2,false
end

function Pose.leg(phase,forward,lateral,amount,upper,lower,crouch)
 local travel,lift,planted=Pose.step(phase)
 local length=upper+lower
 local stride=length*0.72*amount
 local x=travel*stride*lateral
 local z=-travel*stride*forward
 local down=length-crouch-lift*length*0.17*amount
 local distance=math.sqrt(x*x+z*z+down*down)
 distance=math.clamp(distance,math.abs(upper-lower)+0.01,length-0.015)
 -- Knees hinge backwards; ankle counter-rotation keeps the planted sole flat.
 local knee=-math.acos(math.clamp((distance*distance-upper*upper-lower*lower)/(2*upper*lower),-1,1))
 local roll=math.atan2(x,down)
 local hip=math.atan2(-z,math.sqrt(down*down+x*x))-math.atan2(lower*math.sin(knee),upper+lower*math.cos(knee))
 local hipRotation=CFrame.Angles(0,0,roll)*CFrame.Angles(hip,0,0)
 local kneeRotation=CFrame.Angles(knee,0,0)
 local ankle=(hipRotation*kneeRotation):Inverse()*angles(planted and 0 or -lift*8)
 return hipRotation,kneeRotation,ankle,knee,planted
end

function Pose.walk(name,s)
 local stride=math.cos(s.phase*math.pi*2)
 local charge=s.charge or 0
 local amount=s.amount or 0
 local forward,lateral=s.forward or 0,s.lateral or 0
 if name=="root" or name=="rootjoint" then
  local lean=s.r15 and CFrame.identity or angles(-4-forward*5,0,-lateral*4)
  return CFrame.new(0,-s.crouch,0)*lean
 elseif name=="waist" then
  return angles(-5-forward*6,-stride*amount*3-charge*20,-lateral*5)
 elseif name=="neck" then return angles(4+forward*4,charge*12,lateral*3)
 elseif name=="lefthip" or name=="righthip" or name=="leftknee" or name=="rightknee" or name=="leftankle" or name=="rightankle" then
  local left=name:sub(1,4)=="left"
  local phase=s.phase+(left and 0 or 0.5)
  local lengths=left and s.leftLeg or s.rightLeg
  if s.r15 and lengths then
   local hip,knee,ankle=Pose.leg(phase,forward,lateral,amount,lengths[1],lengths[2],s.crouch)
   if name:find("hip") then return hip end
   if name:find("knee") then return knee end
   return ankle
  end
  -- R6 has rigid legs. Keep their arc restrained instead of faking knees.
  local travel=Pose.step(phase)
  return angles(travel*forward*amount*48,0,travel*lateral*amount*24)
 elseif name=="leftshoulder" then
  return angles(18-stride*forward*amount*14,0,-12)
 elseif name=="rightshoulder" then
  return angles(25+stride*forward*amount*8+charge*15,-charge*50,12+charge*26)
 elseif name=="leftelbow" then return angles(32)
 elseif name=="rightelbow" then return angles(42+charge*20)
 elseif name=="rightwrist" then return angles(0,-charge*12,0) end
 return CFrame.identity
end

local forehand={
 waist={angles(0,-18),angles(-8,10),angles(-5,24)},
 neck={angles(0,10),angles(4,-5),angles(3,-12)},
 rightshoulder={angles(45,-48,35),angles(66,6,12),angles(58,52,-12)},
 rightelbow={angles(55),angles(20),angles(48)},
 rightwrist={angles(0,-12),angles(0,0),angles(0,14)},
 leftshoulder={angles(28,10,-22),angles(22,-12,-18),angles(18,-18,-12)},
 leftelbow={angles(45),angles(35),angles(30)},
}
local backhand={
 waist={angles(0,18),angles(-6,-8),angles(-4,-20)},
 neck={angles(0,-10),angles(3,4),angles(3,10)},
 rightshoulder={angles(55,45,-12),angles(66,0,12),angles(45,-42,35)},
 rightelbow={angles(70),angles(28),angles(38)},
 rightwrist={angles(0,12),angles(0,0),angles(0,-12)},
 leftshoulder={angles(40,0,-8),angles(35,0,-12),angles(20,0,-18)},
 leftelbow={angles(65),angles(48),angles(35)},
}
local slam={
 waist={angles(8,-12),angles(-16,8),angles(-10,18)},
 neck={angles(-6,6),angles(10,-4),angles(6,-8)},
 rightshoulder={angles(145,-12,18),angles(95,12,12),angles(38,30,5)},
 rightelbow={angles(55),angles(12),angles(48)},
 rightwrist={angles(-8),angles(8),angles(12)},
 leftshoulder={angles(70,0,-25),angles(40,0,-22),angles(22,0,-16)},
 leftelbow={angles(35),angles(45),angles(50)},
}
function Pose.stroke(name,t,isBackhand,isSlam,r15)
 local key=name
 if (name=="rootjoint" or name=="root") and not r15 then key="waist" end
 local frames=(isSlam and slam or isBackhand and backhand or forehand)[key]
 if not frames then return nil end
 -- The ball has already been struck when the event arrives: contact is early,
 -- followed by a readable follow-through and a soft return to ready stance.
 local contact=isSlam and 0.08 or 0.065
 local follow=isSlam and 0.22 or 0.17
 local duration=isSlam and 0.46 or 0.36
 local pose=t<contact and frames[1]:Lerp(frames[2],Pose.smooth(t/contact))
  or frames[2]:Lerp(frames[3],Pose.smooth((t-contact)/(follow-contact)))
 local weight=Pose.smooth(t/0.025)*(1-Pose.smooth((t-follow)/(duration-follow)))
 return pose,weight
end

local function pointArm(direction)
 local down=Vector3.new(0,-1,0)
 direction=direction.Unit
 local axis=down:Cross(direction)
 if axis.Magnitude<0.001 then return CFrame.identity end
 return CFrame.fromAxisAngle(axis.Unit,math.min(math.rad(155),math.acos(math.clamp(down:Dot(direction),-1,1))))
end
function Pose.diveTilt(localDirection)
 local axis=Vector3.new(localDirection.Z,0,-localDirection.X)
 if axis.Magnitude<0.01 then return CFrame.identity end
 return CFrame.fromAxisAngle(axis.Unit,math.rad(localDirection.Z>0 and 42 or 60))
end
function Pose.dive(name,localDirection,t)
 local tilt=Pose.diveTilt(localDirection)
 local weight=Pose.smooth(t/0.08)*(1-Pose.smooth((t-0.36)/0.3))
 if name=="root" or name=="rootjoint" then return CFrame.new(0,-0.28,0)*tilt,weight end
 if name=="waist" then return angles(-5),weight end
 if name=="neck" then return angles(18,0,0),weight end
 if name=="rightshoulder" or name=="leftshoulder" then
  local right=name=="rightshoulder"
  local reach=Vector3.new(localDirection.X+(right and 0.12 or -0.12),right and 0.05 or -0.35,localDirection.Z)
  return pointArm(tilt:VectorToObjectSpace(reach)),weight
 end
 if name=="rightelbow" then return angles(18),weight end
 if name=="leftelbow" then return angles(48),weight end
 if name=="righthip" then return angles(8,0,5),weight end
 if name=="lefthip" then return angles(-6,0,-5),weight end
 if name=="rightknee" then return angles(-22),weight end
 if name=="leftknee" then return angles(-35),weight end
 if name=="rightankle" or name=="leftankle" then return angles(12),weight end
 return CFrame.identity,weight
end
return Pose
