local BodyBounce={}

-- Sweep the ball through an expanded body-part box so fast shots cannot tunnel.
function BodyBounce.contact(from,to,frame,size)
 local origin=frame:PointToObjectSpace(from)
 local delta=frame:VectorToObjectSpace(to-from)
 local extent=size*0.5+Vector3.new(0.35,0.35,0.35)
 local first,last=0,1
 for _,axis in ipairs({"X","Y","Z"}) do
  if math.abs(delta[axis])<1e-8 then
   if math.abs(origin[axis])>extent[axis] then return nil end
  else
   local a=(-extent[axis]-origin[axis])/delta[axis]
   local b=(extent[axis]-origin[axis])/delta[axis]
   first=math.max(first,math.min(a,b)); last=math.min(last,math.max(a,b))
   if first>last then return nil end
  end
 end
 return first
end

-- A body hit loses most of its energy and drops locally, without lob assistance.
function BodyBounce.deflect(velocity,side)
 local horizontal=Vector3.new(velocity.X,0,velocity.Z)
 local pace=horizontal.Magnitude
 local direction=pace>1e-8 and -horizontal/pace or Vector3.new(0,0,-side)
 return direction*math.min(pace*0.15,8)+Vector3.new(0,3,0)
end

return BodyBounce
