-- Static scenery around the lobby: shared construction, no running decor scripts or lights.
local CitySurroundings={}
function CitySurroundings.build(lobby)
 local floor=lobby.Architecture["Cream marble floor"]
 local base=workspace:WaitForChild("Baseplate")
 local groundY=base.Position.Y+base.Size.Y/2
 -- The two rooftop venues predate the street grade. Extend only the
 -- supporting walls downward so the decks and their gameplay stay aligned.
 local function groundTower(model,name)
  local wall=model and model:FindFirstChild(name)
  if not wall then return end
  local gap=wall.Position.Y-wall.Size.Y/2-groundY
  if gap>0.001 then
   wall.Size+=Vector3.yAxis*gap
   wall.Position-=Vector3.yAxis*(gap/2)
  end
 end
 groundTower(workspace:FindFirstChild("PaddleUp"),"Apartment tower")
 groundTower(workspace:FindFirstChild("SkylineLobby"),"Lobby tower")
 local function openBlock(district)
  local origin=Vector3.new(floor.Position.X,groundY,floor.Position.Z)
  -- Fit the entire retail frontage, including its apron, between the
  -- west sidewalk and the adjacent apartment lot. Keep its base at street grade.
  local retail=district["Front commercial block"]
  local body=retail["Concrete structure"]
  if body.Size.X>61 then
   retail:ScaleTo(retail:GetScale()*60/body.Size.X)
   local target=origin+Vector3.new(-68,body.Size.Y/2,215)
   retail:PivotTo(retail:GetPivot()+(target-body.Position))
  end
  -- Legacy skyline windows are separate parts, so move each facade with
  -- its tower when setting it back from the entrance street and sidewalks.
  local skyline=workspace.PaddleUp:GetChildren()
  for _,tower in ipairs(skyline) do
   if tower.Name~="City tower" then continue end
   local offset=tower.Position-origin
   local dz=offset.Z-104
   local setback=17+tower.Size.Z/2-math.abs(dz)
   if setback<=0.001 or offset.X< -120 or offset.X>205 then continue end
   local shift=Vector3.zAxis*math.sign(dz)*setback
   for _,window in ipairs(skyline) do
    if window.Name=="City window ribbon" then
     local relative=window.Position-tower.Position
     if math.abs(relative.X)<=tower.Size.X/2+0.12 and math.abs(relative.Z)<=tower.Size.Z/2+0.12 then
      window.Position+=shift
     end
    end
   end
   tower.Position+=shift
  end
  local details=district:FindFirstChild("Concrete tower details")
  for _,band in ipairs(details:GetChildren()) do
   if band.Name=="Concrete base course" and band.Size.X>180 and band.Position.Z>origin.Z then
    local half=(band.Size.X-12)/2
    local center=band.Position
    band.Size=Vector3.new(half,band.Size.Y,band.Size.Z)
    band.Position=center+Vector3.new(6+half/2,0,0)
    local opposite=band:Clone()
    opposite.Position=center-Vector3.new(6+half/2,0,0); opposite.Parent=details
   end
  end
  require(script.Parent.LobbyStreet).build(district,origin)
 end
 local saved=workspace:FindFirstChild("LobbyCity")
 if saved then
  openBlock(saved)
  require(script.Parent.CityValley).build(saved,lobby,base)
  return lobby
 end
 local city=workspace:WaitForChild("PaddleUp")
 local concrete=city:FindFirstChild("Balcony slab")
 local tower=city:FindFirstChild("City tower")
 local glass=city:FindFirstChild("Apartment glazing")
 local district=Instance.new("Model")
 district.Name="LobbyCity"; district:SetAttribute("Version",1)
 local center=Vector3.new(floor.Position.X,0,floor.Position.Z)
 local function part(parent,name,size,pos,color,material,collide)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Position=pos; p.Color=color; p.Material=material
  p.Anchored=true; p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=true
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=parent
  return p
 end
 local function localPart(parent,name,size,x,y,z,color,material,collide)
  return part(parent,name,size,center+Vector3.new(x,y,z),color,material,collide)
 end
 local stone=concrete.Color
 local metal=Color3.fromRGB(65,75,84)
 local pavement=Color3.fromRGB(139,144,145)
 -- Tile beyond the original baseplate so the lobby never overlooks its nearby edge.
 local ground=Instance.new("Model"); ground.Name="Ground and streets"; ground.Parent=district
 for x=-1,1 do
  for z=-1,1 do
   if x~=0 or z~=0 then
    part(ground,"City ground extension",Vector3.new(base.Size.X,base.Size.Y,base.Size.Z),
     base.Position+Vector3.new(x*base.Size.X,0,z*base.Size.Z),base.Color,base.Material)
   end
  end
 end
 -- Concrete additions sit outside the retained windows and join the grounded foundation.
 local details=Instance.new("Model"); details.Name="Concrete tower details"; details.Parent=district
 local ceiling=lobby.Architecture["Ivory ceiling"]
 local podiumTop=ceiling.Position.Y+ceiling.Size.Y/2
 for _,x in ipairs({-91,91}) do
  for _,z in ipairs({-79,79}) do
   localPart(details,"Ground floor concrete pier",Vector3.new(2, podiumTop-groundY,2),
    x,(groundY+podiumTop)/2,z,stone,Enum.Material.Concrete)
  end
  localPart(details,"Concrete base course",Vector3.new(0.6,5,158),
   x+math.sign(x)*0.3,groundY+2.5,0,stone,Enum.Material.Concrete)
 end
 for _,z in ipairs({-79,79}) do
  localPart(details,"Concrete base course",Vector3.new(182,5,0.6),
   0,groundY+2.5,z+math.sign(z)*0.3,stone,Enum.Material.Concrete)
 end
 local foundation=lobby.Architecture["Penthouse foundation"]
 local top=foundation.Position.Y+foundation.Size.Y/2
 for _,x in ipairs({-91,91}) do
  for _,z in ipairs({-79,79}) do
   localPart(details,"Concrete corner fin",Vector3.new(1,top-podiumTop,1),
    x,(top+podiumTop)/2,z,stone,Enum.Material.Concrete)
  end
 end
 local occupied={}
 for _,p in ipairs(city:GetChildren()) do
  if p:IsA("BasePart") and (p.Name=="City tower" or p.Name=="Apartment tower") then
   table.insert(occupied,{x=p.Position.X,z=p.Position.Z,w=p.Size.X,d=p.Size.Z})
  end
 end
 table.insert(occupied,{x=center.X,z=center.Z,w=184,d=172})
 local function building(spec,index)
  local x,z,w,d,h=spec[1],spec[2],spec[3],spec[4],spec[5]
  local worldX,worldZ=center.X+x,center.Z+z
  for _,other in ipairs(occupied) do
   assert(math.abs(worldX-other.x)>(w+other.w)/2+4 or math.abs(worldZ-other.z)>(d+other.d)/2+4,
    "City scenery footprint overlaps an existing building")
  end
  table.insert(occupied,{x=worldX,z=worldZ,w=w,d=d})
  local model=Instance.new("Model"); model.Name=spec[6]; model.Parent=district
  local body=part(model,"Concrete structure",Vector3.new(w,h,d),
   Vector3.new(worldX,groundY+h/2,worldZ),tower.Color:Lerp(stone,(index%4)*0.12),Enum.Material.Concrete)
  local tint=glass.Color:Lerp(Color3.fromRGB(125,143,151),(index%3)*0.14)
  for _,side in ipairs({-1,1}) do
   local pane=part(model,"Glazed facade",Vector3.new(w-2,h-14,0.2),
    body.Position+Vector3.new(0,3,side*(d/2+0.11)),tint,Enum.Material.Glass,false)
   pane.Reflectance=0.15
   pane=part(model,"Glazed facade",Vector3.new(0.2,h-14,d-2),
    body.Position+Vector3.new(side*(w/2+0.11),3,0),tint,Enum.Material.Glass,false)
   pane.Reflectance=0.15
  end
  -- One shared slab per floor, rather than individual window parts.
  local stride=index>11 and 24 or 12
  for y=12,h-2,stride do
   part(model,"Concrete floor band",Vector3.new(w+0.6,0.5,d+0.6),
    Vector3.new(worldX,groundY+y,worldZ),stone,Enum.Material.Concrete,false)
  end
  part(model,"Roof parapet",Vector3.new(w+0.6,1.2,d+0.6),
   Vector3.new(worldX,groundY+h+0.6,worldZ),stone,Enum.Material.Concrete,false)
  part(model,"Rooftop service enclosure",Vector3.new(w*0.35,6,d*0.3),
   Vector3.new(worldX+w*0.1,groundY+h+4.2,worldZ-d*0.1),metal,Enum.Material.Metal,false)
  if index<=7 then
   -- Storefronts on the street-facing side; static glazing and frames only.
   local face=index<=4 and 1 or -1
   if index<=4 then
    local xFace=worldX+w/2+0.15
    part(model,"Storefront glazing",Vector3.new(0.2,9,d-8),
     Vector3.new(xFace,groundY+5.5,worldZ),glass.Color,Enum.Material.Glass,false)
    part(model,"Storefront canopy",Vector3.new(4,0.5,d-4),
     Vector3.new(xFace+1.5,groundY+11,worldZ),metal,Enum.Material.Metal,false)
    part(model,"Storefront entrance",Vector3.new(0.25,8,5),
     Vector3.new(xFace+0.1,groundY+4,worldZ),metal,Enum.Material.Metal,false)
   else
    local zFace=worldZ+face*(d/2+0.15)
    part(model,"Storefront glazing",Vector3.new(w-8,9,0.2),
     Vector3.new(worldX,groundY+5.5,zFace),glass.Color,Enum.Material.Glass,false)
    part(model,"Storefront canopy",Vector3.new(w-4,0.5,4),
     Vector3.new(worldX,groundY+11,zFace-1.5),metal,Enum.Material.Metal,false)
    part(model,"Storefront entrance",Vector3.new(5,8,0.25),
     Vector3.new(worldX,groundY+4,zFace-0.1),metal,Enum.Material.Metal,false)
   end
   part(model,"Concrete pavement",Vector3.new(w+12,0.5,d+12),
    Vector3.new(worldX,groundY+0.25,worldZ),pavement,Enum.Material.Concrete)
  end
 end
 -- Coordinates are relative to the integrated lobby; preserve every existing city tower.
 local blocks={
  {-205,-165,78,82,126,"West apartments"},
  {-205,-25,72,104,174,"West office tower"},
  {-205,135,88,84,94,"West commercial block"},
  {-205,285,68,108,198,"West residential tower"},
  {-75,215,78,74,84,"Front commercial block"},
  {5,224,60,80,132,"Front apartments"},
  {95,325,58,60,158,"City infill tower"},
  {-375,-215,110,100,212,"Outer west tower"},
  {-375,10,96,130,148,"Outer west apartments"},
  {-375,265,118,100,192,"Outer west offices"},
  {-135,495,110,96,156,"North district block"},
  {-615,-380,120,96,208,"Distant southwest tower"},
  {-615,-60,104,112,238,"Distant west tower"},
  {-615,280,126,100,182,"Distant northwest tower"},
  {-515,570,140,100,218,"Distant north offices"},
  {-15,640,160,100,190,"Distant north apartments"},
 }
 for index,spec in ipairs(blocks) do building(spec,index) end
 openBlock(district)
 district.Parent=workspace
 require(script.Parent.CityValley).build(district,lobby,base)
 return lobby
end
return CitySurroundings
