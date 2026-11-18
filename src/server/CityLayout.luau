local footprint=require(script.Parent.ValleyFootprint)
local Layout={}
local V=Vector3.new
local asphalt=Color3.fromRGB(52,57,62)
local paving=Color3.fromRGB(158,156,146)
local grass=Color3.fromRGB(115,150,91)
local roof=Color3.fromRGB(65,77,78)
local glass=Color3.fromRGB(84,119,130)
local brick={Color3.fromRGB(162,101,79),Color3.fromRGB(199,183,146),Color3.fromRGB(150,160,149)}
local function part(parent,name,size,frame,color,material)
 local p=Instance.new("Part")
 p.Name=name; p.Anchored=true; p.CanTouch=false
 p.Size=size; p.CFrame=frame; p.Color=color; p.Material=material; p.Parent=parent
 return p
end

-- Intersect each street with the actual polygon at the foot of the ridge.
local function limits(vertical,line,scale)
 local low,high=math.huge,-math.huge
 local function coordinates(i)
  local p=footprint.offset+footprint.radius(i)*(scale or footprint.toeScale)
  if vertical then return p.X,p.Z end
  return p.Z,p.X
 end
 local a,b=coordinates(footprint.sections)
 for i=1,footprint.sections do
  local c,d=coordinates(i)
  if (a<=line and line<c) or (c<=line and line<a) then
   local hit=b+(d-b)*(line-a)/(c-a)
   low=math.min(low,hit); high=math.max(high,hit)
  end
  a,b=c,d
 end
 return low,high
end

function Layout.build(district,valley,origin)
 local previous=district:FindFirstChild("Valley neighborhoods")
 if previous then
  if previous:GetAttribute("StreetPlanVersion")==3 then return end
  previous:Destroy()
 end
 local layout=Instance.new("Model")
 layout.Name="Valley neighborhoods"
 local streets=Instance.new("Folder"); streets.Name="Streets"; streets.Parent=layout
 local routes={}
 local function road(vertical,line,startAt,endAt)
  -- Carry the pavement slightly under the first grassy slope for a seamless end.
  local low,high=limits(vertical,line,footprint.toeScale+0.02)
  local first=math.max(low,startAt or low)
  local last=math.min(high,endAt or high)
  if last<=first then return end
  local length=last-first
  local midpoint=(first+last)/2
  local pos=vertical and V(line,0,midpoint) or V(midpoint,0,line)
  local frame=CFrame.new(origin+pos)*CFrame.Angles(0,vertical and 0 or math.pi/2,0)
  table.insert(routes,{frame=frame,length=length})
  part(streets,"Neighborhood road",V(20,0.23,length),frame*CFrame.new(0,0.115,0),asphalt,Enum.Material.Asphalt)

 end
 -- The entrance and outer districts share the road and sidewalk builder.
 road(true,-291); road(true,-120,nil,390)
 road(false,-300); road(false,345,nil,-475); road(false,380,-475)
 road(true,-700); road(true,-475,nil,420); road(true,-425,420)
 road(true,55,nil,-300); road(true,145,380)
 road(true,350,nil,-300); road(true,350,380); road(true,660)
 road(false,-470); road(false,420)
 road(false,60,-291,-120)
 road(false,104,nil,-291); road(false,104,-120,205)
 road(true,205,104,190); road(false,190,205)
 -- At an elbow the two centerlines end together. Complete the outside
 -- quadrant of the road and wrap the two sidewalk ends around its curb.
 local function elbow(x,z,outX,outZ)
  local function patch(name,dx,dz,w,d,h,color,material)
   local frame=CFrame.new(origin+V(x+outX*dx,h/2,z+outZ*dz))
   part(streets,name,V(w,h,d),frame,color,material)
  end
  patch("Junction asphalt",5,5,10,10,0.23,asphalt,Enum.Material.Asphalt)
  patch("Corner sidewalk",7.5,12.5,15,5,0.4,paving,Enum.Material.Concrete)
  patch("Corner sidewalk",12.5,5,5,10,0.4,paving,Enum.Material.Concrete)
 end
 elbow(205,104,1,-1)
 elbow(205,190,-1,1)
 -- Retire street geometry baked into earlier versions of the saved place.
 local ground=district["Ground and streets"]
 local legacy={["West street"]=true,["Connecting street"]=true,["West sidewalk"]=true,["Opposite sidewalk"]=true,
  ["Lobby forecourt"]=true,["North curb"]=true,["East sidewalk"]=true,["Lane marking"]=true}
 for _,p in ipairs(ground:GetChildren()) do
  if legacy[p.Name] then p:Destroy() end
 end
 for _,p in ipairs(valley:GetChildren()) do
  if p.Name=="District street" or p.Name=="District footpath" then p:Destroy() end
 end
 -- Cut each sidewalk at intersecting streets so the asphalt is continuous.
 local roadbeds={}
 for _,p in ipairs(streets:GetChildren()) do
  if p.Material==Enum.Material.Asphalt then table.insert(roadbeds,p) end
 end
 for _,route in ipairs(routes) do
  for _,side in ipairs({-1,1}) do
   local frame=route.frame*CFrame.new(side*12.5,0.2,0)
   local cuts={}
   for _,bed in ipairs(roadbeds) do
    local across=bed.CFrame:VectorToObjectSpace(frame.RightVector)
    local width=math.abs(across.X)*bed.Size.X+math.abs(across.Z)*bed.Size.Z
    local depth=math.abs(across.Z)*bed.Size.X+math.abs(across.X)*bed.Size.Z
    local pos=frame:PointToObjectSpace(bed.Position)
    if math.abs(pos.X)<width/2 and math.abs(pos.Z)<(depth+route.length)/2 then
     table.insert(cuts,{pos.Z-depth/2,pos.Z+depth/2})
    end
   end
   table.sort(cuts,function(a,b) return a[1]<b[1] end)
   local last=route.length/2
   table.insert(cuts,{last,last})
   local cursor=-last
   for _,cut in ipairs(cuts) do
    local stop=math.min(last,cut[1])
    if stop-cursor>0.1 then
     part(streets,"Sidewalk",V(5,0.4,stop-cursor),frame*CFrame.new(0,0,(cursor+stop)/2),paving,Enum.Material.Concrete)
    end
    cursor=math.max(cursor,cut[2])
   end
  end
 end
 local function onRoad(position,margin)
  local offset=position-origin
  if math.abs(offset.X)<104 and math.abs(offset.Z-35)<135 then return true end
  for _,route in ipairs(routes) do
   local p=route.frame:PointToObjectSpace(position)
   if math.abs(p.X)<15+margin and math.abs(p.Z)<route.length/2+margin then return true end
  end
  return false
 end
 for _,p in ipairs(valley:GetChildren()) do
  if (p.Name=="Woodland trunk" or p.Name=="Woodland canopy") and onRoad(p.Position,7) then p:Destroy() end
 end
 layout.Parent=district
 -- Survey the full lot before placing it. This includes existing towers,
 -- walks, mountain facets, trees and the other lots generated on this pass.
 local survey=OverlapParams.new()
 survey.MaxParts=1
 local rng=Random.new(1449)
 local function lot(frame,park)
  local localCenter=frame.Position-origin
  if math.abs(localCenter.X)<116 and localCenter.Z>-105 and localCenter.Z<181 then return end
  local lotWidth,lotDepth=40,35
  if #workspace:GetPartBoundsInBox(frame*CFrame.new(0,8,0),V(lotWidth-0.5,15.8,lotDepth-0.5),survey)>0 then return end
  -- A mountain facet can have a large bounding box. Confirm this is still
  -- inside the valley even when the last parcel sits near a street end.
  for _,dx in ipairs({-lotWidth/2,lotWidth/2}) do
   for _,dz in ipairs({-lotDepth/2,lotDepth/2}) do
    local corner=(frame*V(dx,0,dz))-origin
    local lo,hi=limits(true,corner.X)
    if corner.Z<lo or corner.Z>hi then return end
   end
  end
  local function place(name,size,x,y,z,color,material)
   return part(layout,name,size,frame*CFrame.new(x,y,z),color,material)
  end
  place("Street lawn",V(lotWidth,0.16,lotDepth),0,0.08,0,grass,Enum.Material.Grass)
  place("Entrance path",V(4,0.24,10),0,0.12,12.5,paving,Enum.Material.Concrete)
  if park then
   place("Courtyard terrace",V(28,0.24,15),0,0.12,2,paving,Enum.Material.Concrete)
   for _,x in ipairs({-9,9}) do
    place("Stone bench plinth",V(4,1.5,1.4),x,0.99,0,roof,Enum.Material.Concrete)
    place("Bench seat",V(7,0.35,2),x,1.92,0,brick[1],Enum.Material.Wood)
    local tree=place("Courtyard tree",V(8,10,8),x,10,-9,Color3.fromRGB(69,114,80),Enum.Material.Grass)
    tree.Shape=Enum.PartType.Ball
    place("Tree trunk",V(1.2,7,1.2),x,3.5,-9,roof,Enum.Material.Wood)
   end
   return
  end
  local h=rng:NextInteger(12,24)
  place("Neighborhood shop",V(30,h,20),0,h/2,-2,brick[rng:NextInteger(1,#brick)],Enum.Material.Brick)
  place("Roof cornice",V(31,0.8,21),0,h+0.4,-2,roof,Enum.Material.Metal)
  place("Shop entrance",V(4.4,7.8,0.3),0,3.9,8.1,glass,Enum.Material.Glass)
  for _,x in ipairs({-8.8,8.8}) do
   place("Display window",V(10,5,0.3),x,4.6,8.1,glass,Enum.Material.Glass)
  end
  place("Storefront awning",V(29,0.45,3),0,8.4,9,roof,Enum.Material.Metal)
  if h>=17 then place("Upper windows",V(25,3,0.3),0,h-4,8.1,glass,Enum.Material.Glass) end
 end
 for i,route in ipairs(routes) do
  local n=0
  for z=-route.length/2+40,route.length/2-35,86 do
   n+=1
   local side=(n+i)%2==0 and 1 or -1
   local frame=route.frame*CFrame.new(side*32.5,0,z)*CFrame.Angles(0,-side*math.pi/2,0)
   lot(frame,(i+n)%4==0)
  end
 end
 layout:SetAttribute("StreetPlanVersion",3)
end
return Layout
