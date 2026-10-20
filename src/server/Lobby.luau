-- Separate versioned environment; menu admission, court, and elevator metadata are unchanged.
local Lobby={}
local Furniture=require(script.Parent:WaitForChild("LobbyFurniture"))
local P=Furniture.Palette
local VERSION=6
local O=Vector3.new(0,181,600)
-- Keep the established arrival point and its view of reception.
Lobby.Spawn=CFrame.lookAt(Vector3.new(0,185,650),Vector3.new(0,185,608))
-- Refresh lighting on saved lobbies without rebuilding their furniture.
function Lobby.lightInterior(root)
 for _,item in ipairs(root:GetDescendants()) do
  if item:IsA("Light") then item.Enabled=true end
  if item:IsA("BasePart") and item.Name=="Recessed warm diffuser" then
   local light=item:FindFirstChildOfClass("SurfaceLight")
   if light then
    light.Enabled=true; light.Brightness=1.8; light.Range=55
    light.Color=Color3.fromRGB(255,244,230); light.Shadows=false
   end
  elseif item:IsA("BasePart") and (item.Name=="Cafe canopy" or item.Name=="Boutique canopy") then
   local light=item:FindFirstChild("Interior task light")
   if not light then
    light=Instance.new("SurfaceLight"); light.Name="Interior task light"; light.Parent=item
   end
   light.Enabled=true; light.Face=Enum.NormalId.Bottom; light.Angle=120
   light.Range=28; light.Brightness=0.9; light.Color=Color3.fromRGB(255,244,230); light.Shadows=false
  end
 end
 return root
end
-- Relocate saved lobbies in place; keep the upper building mass above the ceiling.
function Lobby.moveToFirstFloor(root)
 local shell=root:WaitForChild("Architecture")
 local floor=shell:WaitForChild("Cream marble floor")
 local foundation=shell:WaitForChild("Penthouse foundation")
 if not root:GetAttribute("FirstFloorLobby") then
  local bottom=foundation.Position.Y-foundation.Size.Y/2
  local targetY=bottom+floor.Size.Y
  local delta=Vector3.new(0,targetY-(floor.Position.Y+floor.Size.Y/2),0)
  local foundationTop=foundation.Position.Y+foundation.Size.Y/2
  -- Every lobby component receives exactly the same translation.
  root:PivotTo(root:GetPivot()+delta)
  local ceiling=shell:WaitForChild("Ivory ceiling")
  local ceilingTop=ceiling.Position.Y+ceiling.Size.Y/2
  foundation.Size=Vector3.new(foundation.Size.X,foundationTop-ceilingTop,foundation.Size.Z)
  foundation.Position=Vector3.new(floor.Position.X,(foundationTop+ceilingTop)/2,floor.Position.Z)
  local function piece(template,name,size,position)
   local p=template:Clone()
   p:ClearAllChildren(); p.Name=name; p.Size=size; p.Position=position; p.Parent=shell
   return p
  end
  local center=floor.Position
  local height=ceilingTop-bottom
  for _,side in ipairs({-1,1}) do
   piece(foundation,"Ground floor side wall",Vector3.new(1,height,foundation.Size.Z),
    Vector3.new(center.X+side*(foundation.Size.X/2-0.5),bottom+height/2,center.Z))
  end
  piece(foundation,"Ground floor rear wall",Vector3.new(foundation.Size.X-2,height,1),
   Vector3.new(center.X,bottom+height/2,center.Z-foundation.Size.Z/2+0.5))
  local glass=shell:WaitForChild("Arrival glazing")
  local originalSize,originalPosition=glass.Size,glass.Position
  local width,doorHeight=12,12
  local wing=(originalSize.X-width)/2
  glass.Size=Vector3.new(wing,originalSize.Y,originalSize.Z)
  glass.Position=originalPosition-Vector3.new((width+wing)/2,0,0)
  piece(glass,"Arrival glazing right",glass.Size,originalPosition+Vector3.new((width+wing)/2,0,0))
  piece(glass,"Arrival glazing transom",Vector3.new(width,originalSize.Y-doorHeight,originalSize.Z),
   originalPosition+Vector3.new(0,doorHeight/2,0))
  -- The structural front wall shares the glazing's opening.
  local frontZ=center.Z+foundation.Size.Z/2-0.5
  local frontWing=(foundation.Size.X-2-width)/2
  for _,side in ipairs({-1,1}) do
   piece(foundation,"Ground floor front wall",Vector3.new(frontWing,height,1),
    Vector3.new(center.X+side*(width+frontWing)/2,bottom+height/2,frontZ))
  end
  piece(foundation,"Ground floor entrance lintel",Vector3.new(width,ceilingTop-targetY-doorHeight,1),
   Vector3.new(center.X,(ceilingTop+targetY+doorHeight)/2,frontZ))
  for _,p in ipairs(shell:GetChildren()) do
   if p:IsA("BasePart") and p.Name=="Arrival mullion" and math.abs(p.Position.X-center.X)<width/2 then
    p.Size=Vector3.new(p.Size.X,originalSize.Y-doorHeight,p.Size.Z)
    p.Position+=Vector3.new(0,doorHeight/2,0)
   end
  end
  -- A supported landing reaches outside the building; each step is one stud.
  local edge=center.Z+floor.Size.Z/2
  piece(floor,"Entrance landing",Vector3.new(width, floor.Size.Y,12),
   Vector3.new(center.X,floor.Position.Y,edge+6))
  piece(floor,"Entrance step",Vector3.new(width,1,2),
   Vector3.new(center.X,bottom+0.5,edge+13))
  root:SetAttribute("FirstFloorLobby",true)
 end
 local offset=Vector3.new(0,floor.Position.Y+floor.Size.Y/2-O.Y,0)
 Lobby.Spawn=CFrame.lookAt(O+Vector3.new(0,4,50)+offset,O+Vector3.new(0,4,8)+offset)
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
 if spawn then spawn.CFrame=Lobby.Spawn-Vector3.new(0,3.5,0) end
 return root
end
-- Complete only this building; reuse the existing lobby glass and upper mass.
function Lobby.encloseBuilding(root)
 local shell=root:WaitForChild("Architecture")
 if root:GetAttribute("ExteriorVersion")==1 then return root end
 local floor=shell:WaitForChild("Cream marble floor")
 local ceiling=shell:WaitForChild("Ivory ceiling")
 local mass=shell:WaitForChild("Penthouse foundation")
 local floorY=floor.Position.Y+floor.Size.Y/2
 local bottom=floor.Position.Y-floor.Size.Y/2
 local top=mass.Position.Y+mass.Size.Y/2
 local center=floor.Position
 local neighbors=workspace:FindFirstChild("PaddleUp")
 local function sample(name,fallback)
  return neighbors and neighbors:FindFirstChild(name) or fallback
 end
 local concrete=sample("Apartment tower",mass)
 local slab=sample("Balcony slab",floor)
 local glazing=sample("Apartment glazing",shell:WaitForChild("Arrival glazing"))
 local facade=Instance.new("Model")
 facade.Name="Building Exterior"; facade.Parent=root
 local function part(name,size,position,color,material,collide)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Position=position; p.Color=color; p.Material=material
  p.Anchored=true; p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=true
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=facade
  return p
 end
 mass.Color=concrete.Color; mass.Material=concrete.Material
 -- Replace opaque backing with a sill and header around the retained glazing.
 for _,p in ipairs(shell:GetChildren()) do
  if p:IsA("BasePart") and (p.Name=="Ground floor side wall" or p.Name=="Ground floor front wall") then
   local size,pos=p.Size,p.Position
   p.Size=Vector3.new(size.X,floorY-bottom,size.Z)
   p.Position=Vector3.new(pos.X,(bottom+floorY)/2,pos.Z)
   p.Color=slab.Color
   local header=part("Lobby window header",Vector3.new(size.X,1.5,size.Z),
    Vector3.new(pos.X,ceiling.Position.Y-0.25,pos.Z),slab.Color,Enum.Material.Concrete)
   -- Cover the small return between the original glazing and exterior wall line.
   if size.X<size.Z then header.Size=Vector3.new(3,1.5,size.Z)
   else header.Size=Vector3.new(size.X,1.5,3) end
  elseif p:IsA("BasePart") and p.Name=="Ground floor entrance lintel" then
   p.Size=Vector3.new(p.Size.X,1.5,3)
   p.Position=Vector3.new(p.Position.X,ceiling.Position.Y-0.25,p.Position.Z)
   p.Color=slab.Color
  end
 end
 local glass=shell:WaitForChild("Arrival glazing")
 local frontZ=glass.Position.Z
 local windowHeight=26
 local halfX=89
 local rearZ=center.Z-77
 -- The retained panes form a continuous collision boundary at their original locations.
 for _,p in ipairs(shell:GetChildren()) do
  if p:IsA("BasePart") and (p.Name=="Panoramic window" or p.Name:find("Arrival glazing",1,true)) then
   p.CanCollide=true; p.CollisionGroup="Default"; p.Anchored=true
  end
 end
 for _,x in ipairs({center.X-halfX,center.X+halfX}) do
  for _,z in ipairs({rearZ,frontZ}) do
   part("Lobby corner pier",Vector3.new(2,windowHeight,2),
    Vector3.new(x,floorY+windowHeight/2,z),slab.Color,Enum.Material.Concrete)
  end
 end
 local door=part("Fixed entrance doors",Vector3.new(12,12,0.6),
  Vector3.new(center.X,floorY+6,frontZ),P.forest,Enum.Material.Metal)
 door.CollisionGroup="Default"
 for _,dx in ipairs({-6,0,6}) do
  part("Entrance brass stile",Vector3.new(0.14,12,0.12),
   door.Position+Vector3.new(dx,0,0.36),P.brass,Enum.Material.Metal,false)
 end
 for _,dx in ipairs({-0.7,0.7}) do
  part("Fixed door handle",Vector3.new(0.16,2,0.3),
   door.Position+Vector3.new(dx,0,-0.45),P.brass,Enum.Material.Metal,false)
 end
 -- Match the adjacent tower's floor rhythm, glazing tint and pale concrete bands.
 local spacing=12
 if neighbors then
  local levels={}
  for _,p in ipairs(neighbors:GetChildren()) do
   if p:IsA("BasePart") and p.Name=="Balcony slab" then table.insert(levels,p.Position.Y) end
  end
  table.sort(levels)
  if #levels>1 then spacing=levels[2]-levels[1] end
 end
 local halfWidth,halfDepth=mass.Size.X/2,mass.Size.Z/2
 for y=math.ceil((ceiling.Position.Y+1)/spacing)*spacing,top-spacing,spacing do
  part("Exterior floor band",Vector3.new(mass.Size.X+0.8,0.8,mass.Size.Z+0.8),
   Vector3.new(center.X,y,center.Z),slab.Color,slab.Material)
  for _,side in ipairs({-1,1}) do
   local front=part("Upper floor glazing",Vector3.new(mass.Size.X-2,7,0.2),
    Vector3.new(center.X,y+5,center.Z+side*(halfDepth+0.11)),glazing.Color,Enum.Material.Glass,false)
   front.Reflectance=0.25
   local flank=part("Upper floor glazing",Vector3.new(0.2,7,mass.Size.Z-2),
    Vector3.new(center.X+side*(halfWidth+0.11),y+5,center.Z),glazing.Color,Enum.Material.Glass,false)
   flank.Reflectance=0.25
  end
 end
 local base=ceiling.Position.Y+ceiling.Size.Y/2
 for x=-halfWidth+10,halfWidth-5,20 do
  for _,side in ipairs({-1,1}) do
   part("Facade mullion",Vector3.new(0.35,top-base,0.35),
    Vector3.new(center.X+x,(base+top)/2,center.Z+side*(halfDepth+0.24)),slab.Color,Enum.Material.Metal,false)
  end
 end
 for z=-halfDepth+10,halfDepth-5,20 do
  for _,side in ipairs({-1,1}) do
   part("Facade mullion",Vector3.new(0.35,top-base,0.35),
    Vector3.new(center.X+side*(halfWidth+0.24),(base+top)/2,center.Z+z),slab.Color,Enum.Material.Metal,false)
  end
 end
 part("Building roof cap",Vector3.new(mass.Size.X+0.8,0.8,mass.Size.Z+0.8),
  Vector3.new(center.X,top+0.4,center.Z),slab.Color,slab.Material)
 root:SetAttribute("ExteriorVersion",1)
 return root
end
-- Surveyed clear site west of the court, inside the existing city baseplate.
function Lobby.integrateCity(root)
 local floor=root:WaitForChild("Architecture"):WaitForChild("Cream marble floor")
 local exterior=root:WaitForChild("Building Exterior")
 if root:GetAttribute("CityIntegrationVersion")~=1 then
  local target=Vector3.new(-345,floor.Position.Y,-70)
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={root,workspace:FindFirstChildWhichIsA("SpawnLocation")}
  params.RespectCanCollide=true
  local ground=workspace:Raycast(target+Vector3.new(0,50,0),Vector3.new(0,-1000,0),params)
  assert(ground,"City lobby site needs supporting ground")
  root:PivotTo(root:GetPivot()+(target-floor.Position))
  local shell=root.Architecture
  local mass=shell:WaitForChild("Penthouse foundation")
  local bottom=floor.Position.Y-floor.Size.Y/2
  local function support(name,size,position)
   local p=Instance.new("Part")
   p.Name=name; p.Size=size; p.Position=position
   p.Color=mass.Color; p.Material=Enum.Material.Concrete
   p.Anchored=true; p.CanCollide=true; p.CanTouch=false
   p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
   p.Parent=exterior
  end
  local height=bottom-ground.Position.Y
  if height>0 then
   support("Grounded building foundation",Vector3.new(mass.Size.X,height,mass.Size.Z),
    Vector3.new(floor.Position.X,ground.Position.Y+height/2,floor.Position.Z))
   for _,name in ipairs({"Entrance landing","Entrance step"}) do
    local p=shell:WaitForChild(name)
    local underside=p.Position.Y-p.Size.Y/2
    support(name.." foundation",Vector3.new(p.Size.X,underside-ground.Position.Y,p.Size.Z),
     Vector3.new(p.Position.X,(underside+ground.Position.Y)/2,p.Position.Z))
   end
  end
  local door=exterior:WaitForChild("Fixed entrance doors")
  local glass=shell:WaitForChild("Arrival glazing")
  door.Material=Enum.Material.Glass; door.Color=glass.Color
  door.Transparency=0.65; door.Reflectance=0.08
  door.Anchored=true; door.CanCollide=true; door.CollisionGroup="Default"
  root:SetAttribute("CityIntegrationVersion",1)
 end
 -- Both saved and newly generated lobbies derive arrival from the moved floor.
 Lobby.Spawn=CFrame.lookAt(
  floor.Position+Vector3.new(0,floor.Size.Y/2+4,38),
  floor.Position+Vector3.new(0,floor.Size.Y/2+4,-4))
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
 if spawn then spawn.CFrame=Lobby.Spawn-Vector3.new(0,3.5,0) end
 return root
end
function Lobby.build()
 local old=workspace:FindFirstChild("PaddleUpLobby")
 if old then return require(script.Parent:WaitForChild("CitySurroundings")).build(Lobby.integrateCity(Lobby.encloseBuilding(Lobby.moveToFirstFloor(old)))) end
 local root=Instance.new("Model"); root.Name="PaddleUpLobby"
 root:SetAttribute("Version",VERSION)
 root:SetAttribute("FloorAreaIncrease",180*156/(156*136)-1)
 local furniture=Furniture.new()
 local function group(name)
  local model=Instance.new("Model"); model.Name=name; model.Parent=root; return model
 end
 local shell=group("Architecture")
 local reception=group("Check In")
 local elevators=group("Elevator Banks")
 local shop=group("Shop")
 local cafe=group("Cafe")
 local achievements=group("Achievements")
 local lounges=group("Seating Zones")
 local function part(parent,name,size,pos,color,material,collide)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Position=O+pos; p.Anchored=true
  p.Color=color or P.ivory; p.Material=material or Enum.Material.SmoothPlastic
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=p.CanCollide
  p.CastShadow=p.CanCollide; p.Parent=parent
  return p
 end
 local function decor(parent,name,size,pos,color,material)
  return part(parent,name,size,pos,color,material,false)
 end
 local function place(kind,parent,x,y,z,yaw)
  return furniture.place(kind,parent,CFrame.new(O+Vector3.new(x,y,z))*CFrame.Angles(0,math.rad(yaw or 0),0))
 end
 local function sign(parent,name,value,pos,width,height,color,background)
  local p=decor(parent,name,Vector3.new(width,height,0.15),pos,background or P.forest)
  if background==false then p.Transparency=1 end
  local gui=Instance.new("SurfaceGui",p)
  gui.Face=Enum.NormalId.Back; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
  gui.PixelsPerStud=32; gui.LightInfluence=0.5
  local t=Instance.new("TextLabel",gui)
  t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
  t.Font=Enum.Font.GothamMedium; t.TextScaled=true; t.TextColor3=color or P.ivory; t.Text=value
  local pad=Instance.new("UIPadding",t)
  pad.PaddingLeft=UDim.new(0,12); pad.PaddingRight=UDim.new(0,12)
  pad.PaddingTop=UDim.new(0,5); pad.PaddingBottom=UDim.new(0,5)
  return p
 end
 local function wash(p,range,brightness,face)
  local light=Instance.new("SurfaceLight",p)
  light.Face=face or Enum.NormalId.Bottom; light.Color=P.warm
  light.Enabled=true; light.Range=range; light.Brightness=brightness; light.Angle=120; light.Shadows=false
 end
 local function rug(parent,x,z,width,depth)
  decor(parent,"Woven rug border",Vector3.new(width,0.05,depth),Vector3.new(x,0.04,z),P.linen,Enum.Material.Fabric)
  decor(parent,"Warm neutral woven rug",Vector3.new(width-0.7,0.05,depth-0.7),Vector3.new(x,0.09,z),P.beige,Enum.Material.Fabric)
  for _,dx in ipairs({-width/2+1.4,width/2-1.4}) do
   decor(parent,"Woven rug detail",Vector3.new(0.12,0.02,depth-2.8),Vector3.new(x+dx,0.13,z),P.upholstery,Enum.Material.Fabric)
  end
 end
 local function art(parent,x,y,z,width,height,style)
  decor(parent,"Walnut picture frame",Vector3.new(width,height,0.3),Vector3.new(x,y,z),P.walnut,Enum.Material.Wood)
  decor(parent,"Ivory art mat",Vector3.new(width-0.4,height-0.4,0.12),Vector3.new(x,y,z+0.21),P.ivory)
  decor(parent,"Sage abstract field",Vector3.new(width*0.58,height*0.52,0.05),Vector3.new(x-width*0.1,y+0.4,z+0.3),P.blue)
  local p=decor(parent,"Abstract forest shape",Vector3.new(width*0.25,height*0.7,0.07),Vector3.new(x+width*0.2,y-0.15,z+0.35),P.pink)
  if style then p.Shape=Enum.PartType.Ball end
  decor(parent,"Brass art line",Vector3.new(width*0.72,0.08,0.09),Vector3.new(x,y-height*0.25,z+0.42),P.brass,Enum.Material.Metal)
 end
 -- +32.4% usable floor area, preserving all original area relationships.
 part(shell,"Penthouse foundation",Vector3.new(182,180,158),Vector3.new(0,-91,12),P.walnut,Enum.Material.Concrete)
 part(shell,"Cream marble floor",Vector3.new(180,2,156),Vector3.new(0,-1,12),P.ivory,Enum.Material.Marble)
 part(shell,"Ivory ceiling",Vector3.new(180,1,156),Vector3.new(0,27,12),P.ivory)
 part(shell,"Reception feature wall",Vector3.new(180,26,2),Vector3.new(0,13,-65),P.ivory)
 for _,x in ipairs({-89,89}) do
  local glass=part(shell,"Panoramic window",Vector3.new(0.4,26,154),Vector3.new(x,13,12),Color3.fromRGB(189,199,216),Enum.Material.Glass)
  glass.Transparency=0.78; glass.Reflectance=0.05
  part(shell,"Window walnut sill",Vector3.new(1.4,0.5,154),Vector3.new(x,1.4,12),P.walnut,Enum.Material.Wood)
  for z=-62,86,18 do decor(shell,"Brushed window mullion",Vector3.new(0.6,26,0.35),Vector3.new(x,13,z),P.brass,Enum.Material.Metal) end
 end
 local glass=part(shell,"Arrival glazing",Vector3.new(178,26,0.4),Vector3.new(0,13,89),Color3.fromRGB(185,198,186),Enum.Material.Glass)
 glass.Transparency=0.78; glass.Reflectance=0.05
 for x=-88,88,22 do decor(shell,"Arrival mullion",Vector3.new(0.35,26,0.6),Vector3.new(x,13,89),P.brass,Enum.Material.Metal) end
 for _,x in ipairs({-87,87}) do
  part(shell,"Ivory architectural column",Vector3.new(2,26,2),Vector3.new(x,13,-63),P.ivory,Enum.Material.Concrete)
  decor(shell,"Walnut column inset",Vector3.new(1.2,21,0.15),Vector3.new(x,11,-61.9),P.walnut,Enum.Material.Wood)
 end
 for _,z in ipairs({-63,87}) do
  decor(shell,"Perimeter walnut trim",Vector3.new(177,0.7,0.3),Vector3.new(0,0.5,z),P.walnut,Enum.Material.Wood)
  decor(shell,"Ceiling cornice",Vector3.new(177,0.4,1.8),Vector3.new(0,25.8,z),P.ivory)
 end
 for _,x in ipairs({-87.5,87.5}) do decor(shell,"Window cornice",Vector3.new(1.8,0.4,152),Vector3.new(x,25.8,12),P.ivory) end
 -- Subtle large-format floor joints, rather than the former busy marble texture.
 for x=-75,75,15 do decor(shell,"Stone floor joint",Vector3.new(0.025,0.012,152),Vector3.new(x,0.013,12),P.linen) end
 for z=-60,80,20 do decor(shell,"Stone floor joint",Vector3.new(177,0.012,0.025),Vector3.new(0,0.013,z),P.linen) end
 -- Soft ceiling fill is supplemented by local pendants, lamps, sconces, and accents.
 for _,x in ipairs({-57,0,57}) do
  for _,z in ipairs({-29,29,74}) do
   local lamp=decor(shell,"Recessed warm diffuser",Vector3.new(5,0.1,1.4),Vector3.new(x,26.42,z),P.warm,Enum.Material.Neon)
   wash(lamp,55,1.8)
  end
 end
 -- Check-in desk retains its original central position and arrival view.
 part(reception,"Reception desk",Vector3.new(32,4.5,6),Vector3.new(0,2.25,8),P.ivory,Enum.Material.Marble)
 for x=-14,14,2 do decor(reception,"Desk walnut fluting",Vector3.new(1.2,3.2,0.18),Vector3.new(x,2.3,11.1),P.walnut,Enum.Material.Wood) end
 decor(reception,"Desk brass plinth",Vector3.new(32.3,0.35,6.3),Vector3.new(0,0.2,8),P.brass,Enum.Material.Metal)
 part(reception,"Reception stone top",Vector3.new(33,0.35,7),Vector3.new(0,4.7,8),P.linen,Enum.Material.Marble)
 part(reception,"Reception privacy screen",Vector3.new(18,8,0.6),Vector3.new(0,4,2.5),P.walnut,Enum.Material.Wood)
 sign(reception,"Check in sign","CHECK IN",Vector3.new(0,3,11.35),6,1,P.brass,false)
 sign(reception,"Club signature","P A D D L E U P",Vector3.new(0,6,2.95),10,1.2,P.brass,false)
 local glow=decor(reception,"Reception undercounter glow",Vector3.new(30,0.08,0.15),Vector3.new(0,4.35,11.3),P.warm,Enum.Material.Neon)
 wash(glow,12,0.35)
 decor(reception,"Reception monitor",Vector3.new(2.8,1.8,0.25),Vector3.new(7,5.8,8),P.ink)
 decor(reception,"Monitor stand",Vector3.new(0.2,0.8,0.2),Vector3.new(7,5.2,8),P.brass,Enum.Material.Metal)
 decor(reception,"Guest register",Vector3.new(2.5,0.15,1.8),Vector3.new(-5,4.95,9),P.forest)
 decor(reception,"Brass pen",Vector3.new(0.1,0.1,1.2),Vector3.new(-3.2,5,9),P.brass,Enum.Material.Metal)
 local bell=decor(reception,"Reception bell",Vector3.new(0.8,0.5,0.8),Vector3.new(0,5.1,9),P.brass,Enum.Material.Metal); bell.Shape=Enum.PartType.Ball
 place("Vase",reception,-12,4.9,8); place("TableLamp",reception,12,4.9,8)
 for _,x in ipairs({-12,0,12}) do place("Pendant",reception,x,22,7) end
 rug(reception,0,42,21,52)
 for _,x in ipairs({-23,23}) do place("Plant",reception,x,0,6) end
 -- Elevator banks sit flush against the rear wall; no queue/elevator behavior is added.
 for _,bank in ipairs({{x=-52,name="1V1"},{x=52,name="2V2"}}) do
  local bankRoot=Instance.new("Model"); bankRoot.Name=bank.name; bankRoot.Parent=elevators
  local wallZ=-63.7
  part(bankRoot,"Walnut bank backdrop",Vector3.new(46,22,0.8),Vector3.new(bank.x,11,wallZ),P.walnut,Enum.Material.Wood)
  sign(bankRoot,bank.name.." header",bank.name,Vector3.new(bank.x,18,wallZ+0.6),12,2.6,P.brass,false)
  for index,mode in ipairs({"CLASSIC","ARCADE","CHAOTIC"}) do
   local x=bank.x+(index-2)*14
   local frame=part(bankRoot,bank.name.." "..mode.." elevator",Vector3.new(12,13.5,2),Vector3.new(x,6.75,wallZ+1.5),P.ivory,Enum.Material.Concrete)
   frame:SetAttribute("TeamFormat",bank.name); frame:SetAttribute("Mode",mode); frame:SetAttribute("Placeholder",true)
   for _,dx in ipairs({-2.5,2.5}) do
    part(bankRoot,"Brushed elevator door",Vector3.new(4.85,10.5,0.25),Vector3.new(x+dx,5.65,wallZ+2.65),Color3.fromRGB(164,164,183),Enum.Material.Metal)
   end
   decor(bankRoot,"Door brass seam",Vector3.new(0.1,10.5,0.3),Vector3.new(x,5.65,wallZ+2.83),P.brass,Enum.Material.Metal)
   sign(bankRoot,mode.." label",mode,Vector3.new(x,12.5,wallZ+2.75),7,1.05,P.walnut,false)
   decor(bankRoot,"Elevator indicator",Vector3.new(0.45,0.65,0.1),Vector3.new(x+5.3,5,wallZ+2.8),P.brass,Enum.Material.Metal)
  end
  for _,x in ipairs({bank.x-22,bank.x+22}) do place("Sconce",bankRoot,x,11,wallZ+0.9) end
  place("Plant",bankRoot,bank.x+math.sign(bank.x)*26,0,wallZ+5)
 end
 for _,x in ipairs({-22,22}) do art(shell,x,12,-63.7,5,7,true) end
 -- An open boutique storefront in the established Shop area.
 part(shop,"Boutique back wall",Vector3.new(42,16,0.6),Vector3.new(-60,8,5),P.ivory,Enum.Material.Concrete)
 part(shop,"Boutique canopy",Vector3.new(43,0.6,20),Vector3.new(-60,16,14.5),P.walnut,Enum.Material.Wood)
 for _,x in ipairs({-80,-40}) do
  part(shop,"Boutique side pier",Vector3.new(0.7,16,2),Vector3.new(x,8,5.5),P.walnut,Enum.Material.Wood)
  part(shop,"Storefront brass post",Vector3.new(0.4,16,0.4),Vector3.new(x,8,24),P.brass,Enum.Material.Metal)
  local glass=part(shop,"Boutique storefront glazing",Vector3.new(2.8,12,0.15),Vector3.new(x+(x==-80 and 2 or -2),6.5,24),P.ivory,Enum.Material.Glass)
  glass.Transparency=0.82
 end
 sign(shop,"Boutique fascia lettering","PADDLEUP GOODS",Vector3.new(-60,15.8,24.9),13,1.1,P.brass,false)
 -- Wall-mounted paddles and individual brass hooks.
 for index,x in ipairs({-74,-68,-62}) do
  decor(shop,"Paddle wall inset",Vector3.new(4,6.5,0.2),Vector3.new(x,7.5,5.5),P.linen)
  decor(shop,"Paddle display hook",Vector3.new(0.25,0.25,0.6),Vector3.new(x,6.5,5.8),P.brass,Enum.Material.Metal)
  local display=place("DisplayPaddle",shop,x,5.2,6.05)
  if index==2 then display["Forest paddle face"].Color=P.sage end
  if index==3 then display["Forest paddle face"].Color=P.teal end
 end
 -- A hanging apparel rail plus a static outfit mannequin show future skins.
 decor(shop,"Apparel rail",Vector3.new(12,0.16,0.16),Vector3.new(-48,8.3,6.2),P.brass,Enum.Material.Metal)
 for _,x in ipairs({-54,-42}) do decor(shop,"Apparel bracket",Vector3.new(0.14,0.14,1.1),Vector3.new(x,8.3,5.75),P.brass,Enum.Material.Metal) end
 for index,x in ipairs({-52,-46}) do
  local jersey=place("HangingJersey",shop,x,7.6,6.2)
  if index==2 then for _,piece in ipairs(jersey:GetChildren()) do if piece.Name=="Jersey body" or piece.Name=="Jersey sleeve" then piece.Color=P.sage end end end
 end
 part(shop,"Outfit display dais",Vector3.new(5,0.5,5),Vector3.new(-46,0.25,11),P.linen,Enum.Material.Marble)
 place("DisplayOutfit",shop,-46,0.5,11,180)
 for index,x in ipairs({-72,-61}) do
  part(shop,"Display plinth",Vector3.new(4.5,3,4.5),Vector3.new(x,1.5,17),P.ivory,Enum.Material.Marble)
  decor(shop,"Plinth brass foot",Vector3.new(4.5,0.18,4.5),Vector3.new(x,0.15,17),P.brass,Enum.Material.Metal)
  if index==1 then place("DisplayPaddle",shop,x,3.05,17)
  else
   for n=-1,1 do decor(shop,"Folded skin display",Vector3.new(2.6,0.25,1.7),Vector3.new(x,3.2+(n+1)*0.27,17),({P.linen,P.teal,P.sage})[n+2],Enum.Material.Fabric) end
  end
 end
 part(shop,"Boutique counter",Vector3.new(8,3.6,4),Vector3.new(-45,1.8,20),P.walnut,Enum.Material.Wood)
 part(shop,"Boutique stone top",Vector3.new(8.5,0.3,4.4),Vector3.new(-45,3.75,20),P.linen,Enum.Material.Marble)
 decor(shop,"Boutique terminal",Vector3.new(1.8,1.2,0.2),Vector3.new(-43,4.5,20),P.ink)
 decor(shop,"Gift bag",Vector3.new(1.3,1.6,0.8),Vector3.new(-46,4.7,20),P.ivory)
 decor(shop,"Bag handle",Vector3.new(0.6,0.6,0.1),Vector3.new(-46,5.75,20),P.brass,Enum.Material.Metal)
 place("Vase",shop,-48,3.95,20)
 place("Sconce",shop,-78,10,5.5); place("Sconce",shop,-38,10,5.5)
 -- Cafe grows from a 29-stud counter into a complete 44-stud counter/bar.
 part(cafe,"Cafe walnut backsplash",Vector3.new(48,12,0.6),Vector3.new(60,6,8),P.walnut,Enum.Material.Wood)
 sign(cafe,"Cafe plaque","CAFE",Vector3.new(41,10.5,8.45),5,1.1,P.brass,false)
 sign(cafe,"Cafe menu","ESPRESSO / LATTE\nTEA / COCOA\nFRESH BAKES",Vector3.new(60,10.1,8.45),8,3.2,P.ivory,P.ink)
 part(cafe,"Cafe counter",Vector3.new(43,4.5,7),Vector3.new(60,2.25,21),P.walnut,Enum.Material.Wood)
 part(cafe,"Cafe worktop",Vector3.new(44,0.35,8),Vector3.new(60,4.7,21),P.ivory,Enum.Material.Marble)
 for x=40,80,2.5 do decor(cafe,"Counter forest fluting",Vector3.new(1.6,3.4,0.2),Vector3.new(x,2.4,24.6),P.forest) end
 decor(cafe,"Counter brass rail",Vector3.new(43,0.16,0.2),Vector3.new(60,0.6,24.8),P.brass,Enum.Material.Metal)
 local cafeGlow=decor(cafe,"Cafe counter glow",Vector3.new(42,0.08,0.15),Vector3.new(60,4.4,24.75),P.warm,Enum.Material.Neon)
 wash(cafeGlow,13,0.4)
 -- Short return bar leaves the cross-lobby route open.
 part(cafe,"Cafe return bar",Vector3.new(5,4.5,13),Vector3.new(80,2.25,15),P.walnut,Enum.Material.Wood)
 part(cafe,"Return stone top",Vector3.new(5.5,0.35,13),Vector3.new(80,4.7,15),P.ivory,Enum.Material.Marble)
 decor(cafe,"Espresso machine",Vector3.new(5,3,2.8),Vector3.new(72,6.35,21),P.ink,Enum.Material.Metal)
 decor(cafe,"Espresso brass front",Vector3.new(4.6,1.1,0.15),Vector3.new(72,6.2,22.5),P.brass,Enum.Material.Metal)
 for _,x in ipairs({70.7,73.2}) do decor(cafe,"Coffee spout",Vector3.new(0.3,0.7,0.7),Vector3.new(x,5.7,22.9),P.ink,Enum.Material.Metal) end
 decor(cafe,"Coffee grinder",Vector3.new(1.7,2,1.7),Vector3.new(66,5.9,21),P.brass,Enum.Material.Metal)
 local hopper=decor(cafe,"Coffee bean hopper",Vector3.new(1.6,1.8,1.6),Vector3.new(66,7.8,21),P.walnut,Enum.Material.Glass)
 hopper.Transparency=0.28
 for _,y in ipairs({3.8,6.8}) do
  part(cafe,"Cafe decorative shelf",Vector3.new(36,0.3,2),Vector3.new(60,y,8.9),P.walnut,Enum.Material.Wood)
  for i=1,6 do
   local jar=decor(cafe,"Tea / coffee jar",Vector3.new(0.9,1.3,0.9),Vector3.new(45+i*4,y+0.8,9),i%2==0 and P.linen or P.sage)
   jar.Shape=Enum.PartType.Cylinder; jar.CFrame*=CFrame.Angles(0,0,math.pi/2)
  end
 end
 place("Vase",cafe,77,7,9); place("TeaService",cafe,61,4.95,21)
 -- Pastry display with three glazing panes rather than an expensive mesh.
 decor(cafe,"Display case base",Vector3.new(13,0.2,5),Vector3.new(48,5,21),P.brass,Enum.Material.Metal)
 for _,x in ipairs({41.5,54.5}) do
  local pane=decor(cafe,"Pastry case side glass",Vector3.new(0.15,2.6,5),Vector3.new(x,6.4,21),P.ivory,Enum.Material.Glass); pane.Transparency=0.72
 end
 for _,z in ipairs({18.5,23.5}) do
  local pane=decor(cafe,"Pastry display glass",Vector3.new(13,2.6,0.15),Vector3.new(48,6.4,z),P.ivory,Enum.Material.Glass); pane.Transparency=0.72
 end
 decor(cafe,"Case top",Vector3.new(13.2,0.2,5.2),Vector3.new(48,7.8,21),P.walnut,Enum.Material.Wood)
 for x=44,52,4 do
  decor(cafe,"Pastry tray",Vector3.new(3,0.15,2.5),Vector3.new(x,5.25,21),P.ivory)
  for _,z in ipairs({20.3,21.7}) do
   local pastry=decor(cafe,"Baked pastry",Vector3.new(1.3,0.6,0.85),Vector3.new(x,5.6,z),Color3.fromRGB(171,130,82)); pastry.Shape=Enum.PartType.Ball
  end
 end
 for _,x in ipairs({43,51,59,67,75}) do place("BarStool",cafe,x,0,29) end
 for _,x in ipairs({44,60,76}) do place("Pendant",cafe,x,22,21) end
 local cafeSeats=Instance.new("Model"); cafeSeats.Name="Cafe Seating"; cafeSeats.Parent=lounges
 rug(cafeSeats,60,46,48,24)
 for _,x in ipairs({43,60,77}) do
  place("CafeTable",cafeSeats,x,0,45)
  place("CafeChair",cafeSeats,x,0,50)
  place("CafeChair",cafeSeats,x,0,40,180)
  place("TeaService",cafeSeats,x,3.3,45)
 end
 place("Sofa",cafeSeats,28,0,70,-90)
 place("CoffeeTable",cafeSeats,35,0,70,90)
 place("Books",cafeSeats,35,2.03,70)
 place("FloorLamp",cafeSeats,27,0,79)
 -- Main conversation area, off the central arrival spine.
 local main=Instance.new("Model"); main.Name="Main Lounge"; main.Parent=lounges
 rug(main,-31,42,35,28)
 place("Sofa",main,-29,0,51)
 place("Sofa",main,-44,0,40,-90)
 place("LoungeChair",main,-23,0,35,180)
 place("CoffeeTable",main,-29,0,41)
 place("Books",main,-30,2.04,41); place("Candle",main,-26,2.04,41)
 place("SideTable",main,-21,0,50); place("TableLamp",main,-21,2.5,50)
 place("FloorLamp",main,-49,0,51); place("Plant",main,-51,0,35)
 -- Hall of Fame is a shallow, wall-mounted gallery between the elevator banks.
 -- Record frames and leaderboard screens are visual placeholders, not fabricated statistics.
 part(achievements,"Gallery walnut inset",Vector3.new(34,15,0.35),Vector3.new(0,8.5,-63.7),P.walnut,Enum.Material.Wood)
 sign(achievements,"Hall of Fame lettering","HALL OF FAME",Vector3.new(0,15.1,-63.3),12,1.1,P.brass,false)
 part(achievements,"Trophy display cabinet",Vector3.new(34,3,3),Vector3.new(0,1.5,-61.8),P.forest)
 part(achievements,"Gallery stone ledge",Vector3.new(34.5,0.3,3.3),Vector3.new(0,3.2,-61.8),P.linen,Enum.Material.Marble)
 decor(achievements,"Cabinet brass inlay",Vector3.new(33,0.12,0.08),Vector3.new(0,0.6,-60.25),P.brass,Enum.Material.Metal)
 for _,x in ipairs({-12,-6,0}) do
  local trophy=place("Trophy",achievements,x,3.4,-61.8)
  if x==0 then trophy:ScaleTo(1.35) end
 end
 part(achievements,"Medal display shelf",Vector3.new(17,0.25,1.7),Vector3.new(-7,9,-62.7),P.linen,Enum.Material.Marble)
 for index,x in ipairs({-12,-7,-2}) do
  for _,dx in ipairs({-0.28,0.28}) do
   local ribbon=decor(achievements,"Medal ribbon",Vector3.new(0.4,1.6,0.1),Vector3.new(x+dx,11.6,-63.13),index==2 and P.sage or P.forest,Enum.Material.Fabric)
   ribbon.CFrame*=CFrame.Angles(0,0,dx>0 and 0.24 or -0.24)
  end
  local medal=decor(achievements,"Brass medal",Vector3.new(0.14,1.05,1.05),Vector3.new(x,10.55,-62.97),P.brass,Enum.Material.Metal)
  medal.Shape=Enum.PartType.Cylinder; medal.CFrame*=CFrame.Angles(0,math.pi/2,0)
 end
 for index,x in ipairs({6,12}) do
  decor(achievements,"Framed club record",Vector3.new(4.7,4,0.25),Vector3.new(x,12,-63.2),P.brass,Enum.Material.Metal)
  sign(achievements,"Record engraving",index==1 and "RALLY RECORD\nAwaiting records" or "CLUB MILESTONES\nAwaiting records",Vector3.new(x,12,-62.98),4.3,3.6,P.walnut,P.ivory)
 end
 decor(achievements,"Leaderboard screen bezel",Vector3.new(11.8,5,0.25),Vector3.new(9,7.1,-63.2),P.ink,Enum.Material.Metal)
 sign(achievements,"Leaderboard screen","CLUB LEADERS\n01   --\n02   --\n03   --",Vector3.new(9,7.1,-62.98),11.3,4.5,P.linen,P.ink)
 sign(achievements,"Leaderboard status","NO RECORDS YET",Vector3.new(9,4.1,-62.95),6,0.65,P.brass,false)
 for _,x in ipairs({-18,18}) do place("Sconce",achievements,x,10,-63.45) end
 -- Intimate window nook, with inward-facing chairs and cozy lamp light.
 local nook=Instance.new("Model"); nook.Name="Window Conversation"; nook.Parent=lounges
 rug(nook,67,77,30,21)
 place("Sofa",nook,67,0,83)
 place("LoungeChair",nook,58,0,74,-90)
 place("LoungeChair",nook,76,0,69,180)
 place("CoffeeTable",nook,67,0,75)
 place("TeaService",nook,67,2.04,75); place("Vase",nook,69.5,2.04,75)
 place("SideTable",nook,76,0,83); place("TableLamp",nook,76,2.5,83)
 place("Plant",nook,84,0,80)
 -- Quiet reading corner keeps its open window-side setting.
 local reading=Instance.new("Model"); reading.Name="Reading Corner"; reading.Parent=lounges
 rug(reading,-73,80,24,17)
 place("Bookshelf",reading,-74,0,87)
 place("LoungeChair",reading,-80,0,81,-20)
 place("LoungeChair",reading,-68,0,81,20)
 place("CoffeeTable",reading,-74,0,74)
 place("Books",reading,-76,2.04,74); place("Candle",reading,-71,2.04,74)
 place("SideTable",reading,-74,0,82); place("TableLamp",reading,-74,2.5,82)
 place("FloorLamp",reading,-84,0,74)
 -- Decorative art, planting, and recessed niches soften the architecture.
 for _,x in ipairs({-82,82}) do place("Plant",shell,x,0,-13) end
 place("Plant",shop,-84,0,21); place("Plant",cafe,85,0,37)
 -- Repeated accents use the existing blueprint library, with no running decor scripts.
 for _,x in ipairs({-85,85}) do
  decor(shell,"Electric blue ceiling ribbon",Vector3.new(0.18,0.12,146),Vector3.new(x,25.5,12),P.blue,Enum.Material.Neon)
 end
 for _,x in ipairs({-52,52}) do
  decor(elevators,"Emerald bank crown",Vector3.new(43,0.2,0.18),Vector3.new(x,22,-63),P.teal,Enum.Material.Neon)
 end
 for x=39,81,3 do
  decor(cafe,"Glossy teal backsplash tile",Vector3.new(2.8,2.3,0.12),Vector3.new(x,2,8.4),P.teal)
 end
 part(cafe,"Cafe canopy",Vector3.new(49,0.5,19),Vector3.new(60,16,16),P.forest)
 decor(cafe,"Cafe pink fascia inlay",Vector3.new(47,0.15,0.12),Vector3.new(60,15.7,25.6),P.pink,Enum.Material.Neon)
 sign(cafe,"Integrated cafe fascia","THE RALLY CAFE",Vector3.new(60,16,25.65),14,1.1,P.ivory,false)
 for _,x in ipairs({43,60,77}) do
  place("CafeChair",cafeSeats,x-5,0,45,-90)
  place("CafeChair",cafeSeats,x+5,0,45,90)
  place("Refreshments",cafeSeats,x,3.3,46.5)
 end
 -- Additional social island stays clear of the arrival spine and shop entrance.
 rug(lounges,-31,68,27,18)
 place("Sofa",lounges,-31,0,74)
 place("LoungeChair",lounges,-40,0,64,180)
 place("LoungeChair",lounges,-22,0,64,180)
 place("CoffeeTable",lounges,-31,0,67)
 place("Refreshments",lounges,-31,2.03,67)
 place("SideTable",lounges,-22,0,74); place("TableLamp",lounges,-22,2.5,74)
 place("BallSculpture",reception,-24,0,-12)
 place("BallSculpture",reception,24,0,-12)
 for _,x in ipairs({-10,10}) do
  part(reception,"Club paddle pedestal",Vector3.new(3.5,2.5,3.5),Vector3.new(x,1.25,-20),P.ivory,Enum.Material.Marble)
  local paddle=place("DisplayPaddle",reception,x,2.5,-20)
  paddle["Forest paddle face"].Color=x<0 and P.blue or P.pink
 end
 art(shop,-60,11,5.4,7,5,true)
 -- Soft lavender upholstery and pale stone balance the navy club palette.
 local index=0
 for _,model in ipairs(lounges:GetDescendants()) do
  if model:IsA("Model") and model.Name=="Sofa" then
   index+=1
   local color=({P.ivory,P.upholstery,P.linen,P.beige,P.ivory})[(index-1)%5+1]
   for _,piece in ipairs(model:GetChildren()) do
    if piece:IsA("BasePart") and (piece.Name=="Upholstered base" or piece.Name=="Back cushion" or piece.Name=="Soft armrest" or piece.Name=="Sofa cushion") then piece.Color=color end
   end
  end
 end
 furniture.destroyTemplates()
 -- Swap only this generated lobby; saved older geometry is refreshed automatically.
 if old then old:Destroy() end
 root.Parent=workspace
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation") or Instance.new("SpawnLocation")
 spawn.Name="SpawnLocation"; spawn.CFrame=Lobby.Spawn-Vector3.new(0,3.5,0)
 spawn.Size=Vector3.new(5,0.3,5); spawn.Transparency=1; spawn.CanCollide=false
 spawn.Neutral=true; spawn.Duration=0; spawn.Parent=workspace
 return require(script.Parent:WaitForChild("CitySurroundings")).build(Lobby.integrateCity(Lobby.encloseBuilding(Lobby.moveToFirstFloor(Lobby.lightInterior(root)))))
end
return Lobby
