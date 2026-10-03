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

-- Preserve the PR's playable body save: a slower lob into the opposite court.
function BodyBounce.shot(position,velocity,side,speed,floor)
 local target=Vector3.new(math.clamp(position.X,-16,16),floor,-side*27)
 local distance=Vector3.new(target.X-position.X,0,target.Z-position.Z).Magnitude
 local pace=Vector3.new(velocity.X,0,velocity.Z).Magnitude
 return target,speed*0.7,math.max(1.5,distance/math.max(0.1,pace*0.7))
end

return BodyBounce
