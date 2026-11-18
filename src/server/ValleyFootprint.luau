-- The first row of mountain vertices also defines the edge of the city plan.
local Footprint={sections=36,radiusX=950,radiusZ=860,toeScale=0.86,offset=Vector3.new(40,0,65)}
function Footprint.radius(i)
 local angle=2*math.pi*i/Footprint.sections
 return Vector3.new(math.cos(angle)*Footprint.radiusX,0,math.sin(angle)*Footprint.radiusZ)
end
return Footprint
