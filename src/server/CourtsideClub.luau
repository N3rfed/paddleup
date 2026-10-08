-- Static courtside presentation. No roster, ranking, media, or gameplay controllers.
local Club={}
local VERSION=1
local P={ivory=Color3.fromRGB(248,240,220),beige=Color3.fromRGB(216,200,175),
 emerald=Color3.fromRGB(16,110,88),teal=Color3.fromRGB(32,143,139),
 walnut=Color3.fromRGB(55,34,31),gold=Color3.fromRGB(231,181,67),
 ink=Color3.fromRGB(28,37,61),blue=Color3.fromRGB(40,105,255),
 coral=Color3.fromRGB(243,130,99),warm=Color3.fromRGB(255,225,171)}
local function part(parent,name,size,frame,color,material,collide)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.CFrame=frame; p.Anchored=true
 p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
 p.CanCollide=collide==true; p.CanTouch=false; p.CanQuery=collide==true
 p.CastShadow=collide==true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent; return p
end
local function label(p,value,color)
 local gui=Instance.new("SurfaceGui")
 gui.Name="CourtFacingDisplay"; gui.Face=Enum.NormalId.Front
 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.PixelsPerStud=28
 gui.LightInfluence=0.15; gui.Parent=p
 local t=Instance.new("TextLabel",gui)
 t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
 t.Font=Enum.Font.GothamBold; t.TextScaled=true; t.TextWrapped=true
 t.TextColor3=color or P.ivory; t.Text=value
 local pad=Instance.new("UIPadding",t)
 pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8)
 pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
end
function Club.buildHall()
 local building=workspace:FindFirstChild("SkylineLobby")
 if not building then
  building=Instance.new("Model"); building.Name="SkylineLobby"; building.Parent=workspace
  part(building,"Lobby tower",Vector3.new(58,176,72),CFrame.new(112,90,0),P.walnut,Enum.Material.Concrete,true)
  part(building,"Lobby terrace",Vector3.new(62,3,76),CFrame.new(112,179.5,0),P.ivory,Enum.Material.Marble,true)
  for _,x in ipairs({81,143}) do part(building,"Terrace railing",Vector3.new(0.5,4,76),CFrame.new(x,183,0),P.gold,Enum.Material.Metal,true) end
  for _,z in ipairs({-38,38}) do part(building,"End railing",Vector3.new(62,4,0.5),CFrame.new(112,183,z),P.gold,Enum.Material.Metal,true) end
 end
 local old=building:FindFirstChild("HallOfFame")
 if old and old:GetAttribute("Version")==VERSION then return old end
 -- Retain the existing building envelope and its collision boundaries.
 for _,item in ipairs(building:GetChildren()) do
  if item.Name=="Club lobby sign" or item.Name=="Lobby arrival" or item.Name=="Lounge bench" or item.Name=="Bench cushion"
   or item.Name:match(" station$") or item.Name:match(" queue pad$") then item:Destroy()
  elseif item:IsA("BasePart") then
   if item.Name=="Lobby tower" then item.Color=P.walnut; item.Material=Enum.Material.Concrete
   elseif item.Name=="Lobby terrace" then item.Color=P.ivory; item.Material=Enum.Material.Marble
   elseif item.Name=="Mint rail" then item.Color=P.teal; item.Material=Enum.Material.Neon
   elseif item.Name=="Terrace railing" or item.Name=="End railing" then
    item.Color=P.beige; item.Material=Enum.Material.Glass; item.Transparency=0.65
   elseif item.Name=="Planter" then item.Color=P.ivory; item.Material=Enum.Material.Marble end
   if item.Name=="Planter" or item.Name=="Topiary" then
    -- Keep the reused planting in the terrace corners, clear of the ranking displays.
    local x=item.Position.X<112 and 89 or 137
    item.Position=Vector3.new(x,item.Position.Y,math.sign(item.Position.Z)*32)
   end
  end
 end
 local hall=Instance.new("Model"); hall.Name="HallOfFame"; hall:SetAttribute("Version",VERSION)
 hall:SetAttribute("PresentationOnly",true)
 -- Local -Z is the display front and points directly toward the court at -X.
 local origin=CFrame.new(112,181,0)*CFrame.Angles(0,math.pi/2,0)
 local function fixture(name,size,pos,color,material)
  return part(hall,name,size,origin*CFrame.new(pos),color,material,false)
 end
 fixture("Champions terrace inlay",Vector3.new(66,0.06,47),Vector3.new(0,0.05,2),P.beige,Enum.Material.Marble)
 fixture("Emerald presentation wall",Vector3.new(68,32,1),Vector3.new(0,16,25),P.emerald)
 for _,x in ipairs({-34,34}) do
  fixture("Marble gallery pier",Vector3.new(2.2,36,3),Vector3.new(x,18,24),P.ivory,Enum.Material.Marble)
  fixture("Brass pier reveal",Vector3.new(0.15,33,0.12),Vector3.new(x,18,22.45),P.gold,Enum.Material.Metal)
 end
 for _,x in ipairs({-34,34}) do
  fixture("Front canopy column",Vector3.new(1.4,36,1.4),Vector3.new(x,18,-25),P.ivory,Enum.Material.Marble)
  fixture("Canopy column brass foot",Vector3.new(1.6,0.45,1.6),Vector3.new(x,0.25,-25),P.gold,Enum.Material.Metal)
 end
 fixture("Walnut gallery crown",Vector3.new(73,1.2,55),Vector3.new(0,36,0),P.walnut,Enum.Material.Wood)
 fixture("Champions crown brass lip",Vector3.new(73,0.25,0.2),Vector3.new(0,35.5,-27.5),P.gold,Enum.Material.Metal)
 fixture("Teal canopy edge",Vector3.new(71,0.12,0.12),Vector3.new(0,35.9,-27.65),P.teal,Enum.Material.Neon)
 -- The screen is an inert, named media surface for a future system.
 fixture("Billboard brass surround",Vector3.new(60,19.6,1),Vector3.new(0,23,23.9),P.gold,Enum.Material.Metal)
 fixture("Billboard dark bezel",Vector3.new(59.4,19,1),Vector3.new(0,23,23.3),P.ink,Enum.Material.Metal)
 local screen=fixture("HighlightsScreen",Vector3.new(57.5,17.2,0.12),Vector3.new(0,23,22.73),Color3.fromRGB(36,48,52))
 screen:SetAttribute("MediaReady",true); screen:SetAttribute("DisplayFace","Front")
 for _,x in ipairs({-29,29}) do
  fixture("Electric blue screen corner",Vector3.new(0.18,2,0.12),Vector3.new(x,15,22.65),P.blue,Enum.Material.Neon)
 end
 local gui=Instance.new("SurfaceGui",screen)
 gui.Name="FutureMediaSurface"; gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(1920,1080); gui.LightInfluence=0
 local placeholder=Instance.new("Frame",gui)
 placeholder.Name="NeutralPlaceholder"; placeholder.Size=UDim2.fromScale(1,1)
 placeholder.BackgroundColor3=screen.Color; placeholder.BorderSizePixel=0
 local title=fixture("Hall of Fame fascia",Vector3.new(64,2.8,0.15),Vector3.new(0,34,22.8),P.emerald)
 label(title,"TOP PLAYERS  /  HALL OF FAME",P.ivory)
 local sub=fixture("Tournament subtitle",Vector3.new(47,1.2,0.1),Vector3.new(0,12.4,24.25),P.emerald)
 label(sub,"PADDLEUP  /  CHAMPIONS GALLERY",P.gold)
 -- Reusable podium blueprint; every copy shares the same layout and court-facing labels.
 local template=Instance.new("Model"); template.Name="Ranking podium"
 part(template,"Marble podium",Vector3.new(13,2,9),CFrame.new(0,1,0),P.ivory,Enum.Material.Marble)
 part(template,"Brass podium foot",Vector3.new(13.2,0.2,9.2),CFrame.new(0,0.1,0),P.gold,Enum.Material.Metal)
 part(template,"Emerald podium inset",Vector3.new(11.5,1.25,0.1),CFrame.new(0,1,-4.56),P.emerald)
 template.WorldPivot=CFrame.identity
 for _,entry in ipairs({{rank=2,x=-19,rise=0.5},{rank=1,x=0,rise=1.5},{rank=3,x=19,rise=0}}) do
  local x,rise=entry.x,entry.rise
  fixture("Podium riser",Vector3.new(13.4,rise+0.12,9.4),Vector3.new(x,(rise+0.12)/2,1),P.walnut,Enum.Material.Wood)
  local podium=template:Clone(); podium.Name="Rank "..entry.rank.." podium"
  podium:SetAttribute("Rank",entry.rank); podium:PivotTo(origin*CFrame.new(x,rise,1)); podium.Parent=hall
  label(podium["Emerald podium inset"],"#"..entry.rank,P.gold)
  local portrait=fixture("Player portrait placeholder",Vector3.new(7.5,6,0.4),Vector3.new(x,7+rise,3.5),P.walnut,Enum.Material.Wood)
  label(portrait,"TOP "..entry.rank.."\nPLAYER --",P.ivory)
  local stats=fixture("Player stat display",Vector3.new(12,2.3,0.2),Vector3.new(x,3.5+rise,-3.5),P.ink)
  label(stats,"WINS --  /  RANK --\nRECORDS PENDING",P.beige)
  -- Gold pickleball trophy: anchored prop, never a player or bot.
  local trophy=fixture("Golden pickleball trophy",Vector3.new(2,2,2),Vector3.new(x,4+rise,0),P.gold,Enum.Material.Metal)
  trophy.Shape=Enum.PartType.Ball
  fixture("Trophy pedestal",Vector3.new(2.8,0.35,2.8),Vector3.new(x,2.3+rise,0),P.ink,Enum.Material.Marble)
  fixture("Trophy stem",Vector3.new(0.25,1,0.25),Vector3.new(x,2.95+rise,0),P.gold,Enum.Material.Metal)
 end
 template:Destroy()
 for _,x in ipairs({-29,29}) do
  fixture("Display walnut slat wall",Vector3.new(8,10,0.3),Vector3.new(x,6,24.3),P.walnut,Enum.Material.Wood)
  for dx=-3,3,1.5 do fixture("Vertical brass gallery slat",Vector3.new(0.1,9,0.15),Vector3.new(x+dx,6,24.05),P.gold,Enum.Material.Metal) end
  local lamp=fixture("Gallery opal sconce",Vector3.new(1,4,0.5),Vector3.new(x,8,23.7),P.warm,Enum.Material.Neon)
  local light=Instance.new("PointLight",lamp); light.Color=P.warm; light.Range=16; light.Brightness=0.45; light.Shadows=false
 end
 -- Architectural details tie the reused tower to the new terrace feature.
 for _,z in ipairs({-33,33}) do
  fixture("Tower brass seam",Vector3.new(0.18,155,0.12),Vector3.new(z,-85,-29.1),P.gold,Enum.Material.Metal)
 end
 fixture("Front gallery cornice",Vector3.new(74,0.6,0.6),Vector3.new(0,0.25,-30.8),P.gold,Enum.Material.Metal)
 if old then old:Destroy() end
 hall.Parent=building; building:SetAttribute("CourtsideUse","HallOfFame")
 return hall
end
function Club.addStringLights(court)
 local old=court:FindFirstChild("FairyLights")
 if old and old:GetAttribute("Version")==VERSION then return old end
 local rig=Instance.new("Model"); rig.Name="FairyLights"; rig:SetAttribute("Version",VERSION)
 local wire=part(nil,"String cable",Vector3.new(0.045,0.045,1),CFrame.identity,P.walnut,Enum.Material.SmoothPlastic)
 local bulb=part(nil,"Warm fairy bulb",Vector3.new(0.32,0.43,0.32),CFrame.identity,P.warm,Enum.Material.Neon)
 bulb.Shape=Enum.PartType.Ball
 local cap=part(nil,"Brass bulb socket",Vector3.new(0.13,0.15,0.13),CFrame.identity,P.gold,Enum.Material.Metal)
 local spans={}
 -- Attach to the existing light-mast tops, well above gameplay and sightlines.
 for _,x in ipairs({-30,30}) do
  for _,z in ipairs({-54,0}) do table.insert(spans,{Vector3.new(x,201,z),Vector3.new(x,201,z+54)}) end
 end
 for _,z in ipairs({-54,54}) do table.insert(spans,{Vector3.new(-30,201,z),Vector3.new(30,201,z)}) end
 for _,ends in ipairs(spans) do
  local a,b=ends[1],ends[2]
  local count=math.ceil((b-a).Magnitude/4.5)
  local function point(t) return a:Lerp(b,t)-Vector3.yAxis*(1.3*4*t*(1-t)) end
  local previous=point(0)
  for i=1,count do
   local at=point(i/count)
   local cable=wire:Clone(); cable.Size=Vector3.new(0.045,0.045,(at-previous).Magnitude)
   cable.CFrame=CFrame.lookAt((at+previous)/2,at); cable.Parent=rig
   local socket=cap:Clone(); socket.Position=at-Vector3.yAxis*0.08; socket.Parent=rig
   local lamp=bulb:Clone(); lamp.Position=at-Vector3.yAxis*0.34; lamp.Parent=rig
   -- Most bulbs glow as Neon; sparse, low-range lights keep rendering cost low.
   if i%5==0 then
    local light=Instance.new("PointLight",lamp); light.Color=P.warm; light.Brightness=0.18; light.Range=8; light.Shadows=false
   end
   previous=at
  end
 end
 wire:Destroy(); bulb:Destroy(); cap:Destroy()
 if old then old:Destroy() end
 rig.Parent=court; return rig
end
function Club.build(court)
 Club.buildHall(); Club.addStringLights(court)
end
return Club
