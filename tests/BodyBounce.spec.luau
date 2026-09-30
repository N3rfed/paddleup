return function(Bounce)
 local frame=CFrame.new(0,184,20)
 local size=Vector3.new(2,4,2)
 local from,to=Vector3.new(0,184,10),Vector3.new(0,184,30)
 local fraction=Bounce.contact(from,to,frame,size)
 assert(fraction and fraction>0 and fraction<0.5,"Fast shots must detect the first body contact")
 assert(Bounce.contact(from+Vector3.new(4,0,0),to+Vector3.new(4,0,0),frame,size)==nil,"Near misses must not deflect")
 assert(Bounce.contact(frame.Position,frame.Position,frame,size)==0,"Initial overlap must be detected")
 assert(Bounce.contact(from,from,frame,size)==nil)
 local rotated=frame*CFrame.Angles(0,math.pi/2,0)
 assert(Bounce.contact(from,to,rotated,Vector3.new(6,2,1)),"Rotated body parts must be supported")
 for _,side in ipairs({-1,1}) do
  for _,pace in ipairs({10,56,200}) do
   local position=Vector3.new(22,184,side*20)
   local target,speed,duration=Bounce.shot(position,Vector3.new(0,-20,side*pace),side,2,181.7)
   assert(target.Z*side<0 and math.abs(target.X)<=16,"Lob must target the opposite court")
   assert(math.abs(speed-1.4)<1e-8,"Body contact must reduce rally speed by 30 percent")
   local distance=Vector3.new(target.X-position.X,0,target.Z-position.Z).Magnitude
   assert(distance/duration<=pace*0.7+1e-8,"Lob must have slower horizontal pace")
   assert(duration>=1.5,"Body return must have lob airtime")
  end
 end
 return "Swept contact, misses, overlap, rotated parts, opposite-court targets, and slower lob pace passed"
end
