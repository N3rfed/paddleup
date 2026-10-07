return function(Rules)
 local gravity=45
 local from=Vector3.new(0,10,0)
 local velocity=Vector3.new(20,45,-12)
 local at,v,g=Rules.advanceBall(from,velocity,gravity,0.5,true,false)
 assert(math.abs(at.Y-26.875)<1e-5 and v.Y==22.5 and g==45,"Lob ascent keeps base gravity")
 at,v,g=Rules.advanceBall(from,velocity,gravity,1.5,true,false)
 assert(math.abs(at.Y-23.5)<1e-5 and v.Y==-36 and g==72,"Apex-crossing frames split ascent and descent")
 assert(at.X==30 and at.Z==-18,"Flight keeps forward motion")
 local apex=Rules.advanceBall(from,velocity,gravity,1,true,false)
 local split=Rules.advanceBall(apex,Vector3.new(20,0,-12),gravity,0.5,true,false)
 assert((split-at).Magnitude<1e-5,"Single-frame and split-frame integration must agree")
 at,v,g=Rules.advanceBall(from,Vector3.new(20,18,-12),gravity,0.1,true,true)
 assert(math.abs(v.Y-10.8)<1e-5 and g==72,"Heavy gravity applies on post-bounce ascent too")
 local bounced=Rules.bounceVelocity(Vector3.new(20,-40,-12),true)
 assert(bounced==Vector3.new(15,18,-9),"Lob restitution is 0.45 and both horizontal axes retain 75%")
 assert(Rules.bounceVelocity(Vector3.new(20,-10,-12),true).Y==4.5,"Lobs must not inherit the 15-stud rebound floor")
 assert(Rules.bounceVelocity(Vector3.new(20,-10,-12),false)==Vector3.new(20,15,-12))
 for _,height in ipairs({2,10,40}) do
  for _,duration in ipairs({0.3,0.7,1.5,2.5}) do
   local vy=Rules.lobLaunchY(height,duration,gravity)
   local landing=Rules.advanceBall(Vector3.new(0,height,0),Vector3.new(0,vy,0),gravity,duration,true,false)
   assert(math.abs(landing.Y)<1e-5,"Launch solver must preserve the target with variable gravity")
   assert(math.abs(Rules.ballLandingTime(height,vy,gravity,true,false)-duration)<1e-7)
  end
 end
 local regular=Rules.advanceBall(from,velocity,gravity,1.5,false,false)
 assert(math.abs(regular.Y-(10+45*1.5-0.5*45*1.5^2))<1e-5)
 return "Lob ascent/descent split, post-bounce gravity, exact restitution, forward retention, targeting and normal-shot regression passed"
end
