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
  for _,pace in ipairs({0,10,56,200}) do
   for _,vertical in ipairs({-50,0,80}) do
    local incoming=Vector3.new(pace*0.6,vertical,side*pace*0.8)
    local outgoing=Bounce.deflect(incoming,side)
    local horizontal=Vector3.new(outgoing.X,0,outgoing.Z)
    assert(math.abs(horizontal.Magnitude-math.min(pace*0.15,8))<1e-8,"Body hits must lose 85% of horizontal speed and cap at 8 studs/second")
    assert(outgoing.Y==3,"Body hits must use a small fixed bump regardless of incoming vertical speed")
    assert(outgoing.Y^2/(2*45)<=0.11,"Deflection must rise no more than 0.11 studs under game gravity")
    if pace>0 then
     assert(horizontal:Dot(Vector3.new(incoming.X,0,incoming.Z))<0,"Visible deflection must reverse incoming horizontal travel")
    end
   end
  end
 end
 return "Swept body contacts and low, heavily damped deflections passed"
end
