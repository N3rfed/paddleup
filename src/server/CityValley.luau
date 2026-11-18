-- The city sits in a closed valley. Every ridge section shares its endpoints
-- with its neighbors, including the vertical rock face below the peaks.
local Valley={}
local footprint=require(script.Parent.ValleyFootprint)
local layout=require(script.Parent.CityLayout)
local V=Vector3.new
local meadow=Color3.fromRGB(105,139,84)
local function triangle(parent,a,b,c,color,material)
 local ab,ac,bc=b-a,c-a,c-b
 if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then
  a,c=c,a
 elseif ac.Magnitude>bc.Magnitude then
  a,b=b,a
 end
 ab,ac,bc=b-a,c-a,c-b
 local normal=ac:Cross(ab).Unit
 local along=bc.Unit
 local up=along:Cross(normal)
 local height=math.abs(ab:Dot(up))
 local function wedge(mid,width,direction)
  if width<0.05 then return end
  local p=Instance.new("WedgePart")
  p.Name="Ridge facet"; p.Size=V(1,height,width)
  p.CFrame=CFrame.fromMatrix(mid,normal*direction,up,along*direction)
  p.Anchored=true; p.CanTouch=false; p.Color=color; p.Material=material
  p.Parent=parent
 end
 wedge((a+b)/2,math.abs(ab:Dot(along)),1)
 wedge((a+c)/2,math.abs(ac:Dot(along)),-1)
end

function Valley.build(district,lobby,base)
 local streets=district["Ground and streets"]
 base.Material=Enum.Material.Grass; base.Color=meadow
 for _,overlay in ipairs(base:GetChildren()) do
  if overlay:IsA("Texture") and overlay.Face==Enum.NormalId.Top then overlay.Transparency=1 end
 end
 for _,p in ipairs(streets:GetChildren()) do
  if p.Name=="City ground extension" then p.Material=Enum.Material.Grass; p.Color=meadow end
 end
 local floor=lobby.Architecture["Cream marble floor"]
 local origin=V(floor.Position.X,base.Position.Y+base.Size.Y/2,floor.Position.Z)
 local saved=district:FindFirstChild("Mountain valley")
 if saved then layout.build(district,saved,origin); return end
 local landscape=Instance.new("Model")
 landscape.Name="Mountain valley"
 local function part(name,size,pos,color,material)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Position=pos; p.Color=color; p.Material=material
  p.Anchored=true; p.CanTouch=false; p.Parent=landscape
  return p
 end
 local center=origin+footprint.offset
 local count=footprint.sections
 local rng=Random.new(718)
 local rings={}
 for i=1,count do
  local radius=footprint.radius(i)
  local shelf=center+radius*rng:NextNumber(0.96,1.04)
  local height=rng:NextNumber(240,410)
  local ledge=rng:NextNumber(22,42)
  rings[i]={
   center+radius*footprint.toeScale-V(0,2,0),
   shelf+V(0,ledge,0),
   shelf+V(0,ledge+64,0),
   center+radius*rng:NextNumber(1.09,1.16)+V(0,height*0.74,0),
   center+radius*rng:NextNumber(1.18,1.29)+V(0,height,0),
   center+radius*1.45-V(0,3,0),
  }
 end
 local colors={Color3.fromRGB(91,122,80),Color3.fromRGB(98,105,94),Color3.fromRGB(102,115,104),
  Color3.fromRGB(139,148,145),Color3.fromRGB(108,122,119)}
 for i,points in ipairs(rings) do
  local nextPoints=rings[i%count+1]
  for j,color in ipairs(colors) do
   local material=j==1 and Enum.Material.Grass or Enum.Material.Rock
   local shade=color:Lerp(Color3.fromRGB(70,78,79),rng:NextNumber(0,0.18))
   triangle(landscape,points[j],nextPoints[j],points[j+1],shade,material)
   triangle(landscape,nextPoints[j],nextPoints[j+1],points[j+1],shade,material)
  end
 end
 landscape.Parent=district
 -- Grow clusters only on uncovered turf, leaving roads, parks and courts clear.
 local params=RaycastParams.new()
 local function turf(x,z)
  local hit=workspace:Raycast(V(x,origin.Y+450,z),V(0,-455,0),params)
  return hit and (hit.Instance==base or hit.Instance.Name=="City ground extension")
 end
 for _=1,105 do
  local angle=rng:NextNumber(0,2*math.pi)
  local distance=math.sqrt(rng:NextNumber())*0.85
  local patch=center+V(950*math.cos(angle)*distance,0,860*math.sin(angle)*distance)
  for _=1,3 do
   local x,z=patch.X+rng:NextNumber(-17,17),patch.Z+rng:NextNumber(-17,17)
   if turf(x,z) and turf(x-5,z) and turf(x+5,z) and turf(x,z-5) and turf(x,z+5) then
    local h=rng:NextNumber(11,22)
    part("Woodland trunk",V(1.4,h*0.6,1.4),V(x,origin.Y+h*0.3,z),Color3.fromRGB(96,77,57),Enum.Material.Wood)
    local crown=part("Woodland canopy",V(h*0.64,h*0.73,h*0.67),V(x,origin.Y+h*0.72,z),
     Color3.fromRGB(56,rng:NextInteger(95,127),73),Enum.Material.Grass)
    crown.Shape=Enum.PartType.Ball
   end
  end
 end
 layout.build(district,landscape,origin)
end
return Valley
