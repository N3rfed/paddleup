-- A floating circular plaza well away from the rooftop courts.
local LobbyWorld={}
local CENTER=Vector3.new(-850,250,0)

function LobbyWorld.build()
 local existing=workspace:FindFirstChild("SkylineLobby")
 if existing and existing:GetAttribute("Version")==4 then return existing end
 if existing then existing:Destroy() end

 local root=Instance.new("Model")
 root.Name="SkylineLobby"
 root:SetAttribute("Version",4)
 root.Parent=workspace

 local function part(name,size,position,color,material,parent)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Position=position
  p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=parent or root
  return p
 end

 local dark=Color3.fromRGB(23,43,50)
 local mint=Color3.fromRGB(92,233,190)
 local cream=Color3.fromRGB(231,223,202)
 local coral=Color3.fromRGB(243,130,99)
 local floorY=CENTER.Y+4
 local island=part("Circular floating lobby",Vector3.new(8,400,400),CENTER,cream,Enum.Material.Concrete)
 island.Shape=Enum.PartType.Cylinder
 island.CFrame=CFrame.new(CENTER)*CFrame.Angles(0,0,math.pi/2)
 local hull=part("Floating island hull",Vector3.new(14,300,300),CENTER+Vector3.new(0,-11,0),dark,Enum.Material.Metal)
 hull.Shape=Enum.PartType.Cylinder
 hull.CFrame=CFrame.new(hull.Position)*CFrame.Angles(0,0,math.pi/2)

 -- Low planting beds and seating frame the plaza without enclosing it.
 for _,x in ipairs({CENTER.X-145,CENTER.X+145}) do
  for _,z in ipairs({-91,91}) do
   part("Planter",Vector3.new(20,2,18),Vector3.new(x,floorY+1,z),dark,Enum.Material.Concrete)
   local tree=part("Topiary",Vector3.new(11,12,11),Vector3.new(x,floorY+8,z),Color3.fromRGB(57,113,82),Enum.Material.Grass)
   tree.Shape=Enum.PartType.Ball
   part("Lounge bench",Vector3.new(22,1,5),Vector3.new(x+(x<CENTER.X and 22 or -22),floorY+1, z),cream,Enum.Material.Fabric)
   part("Bench back",Vector3.new(22,4,1),Vector3.new(x+(x<CENTER.X and 22 or -22),floorY+3,z-2),coral,Enum.Material.Fabric)
  end
 end
 for _,z in ipairs({-117,117}) do
  part("Plaza edge light",Vector3.new(2,8,2),Vector3.new(CENTER.X,floorY+4,z),dark,Enum.Material.Metal)
  local lamp=part("Plaza glow",Vector3.new(2.5,0.25,2.5),Vector3.new(CENTER.X,floorY+8,z),mint,Enum.Material.Neon)
  local light=Instance.new("PointLight",lamp); light.Color=mint; light.Range=26; light.Brightness=1
 end

 for _,station in ipairs({
  {x=CENTER.X-108,name="Singles",mode="1v1",color=mint},
  {x=CENTER.X-36,name="Doubles",mode="2v2",color=Color3.fromRGB(107,182,249)},
  {x=CENTER.X+36,name="Practice",mode="Practice",color=Color3.fromRGB(249,177,109)},
  {x=CENTER.X+108,name="Spectate",mode="Spectate",color=Color3.fromRGB(184,157,244)},
 }) do
  part(station.name.." queue pad",Vector3.new(12,0.15,12),Vector3.new(station.x,floorY+0.58,-42),station.color,Enum.Material.Neon)
  local kiosk=part(station.name.." station",Vector3.new(7,6,2),Vector3.new(station.x,floorY+3,-52),dark,Enum.Material.Metal)
  kiosk.CFrame=CFrame.new(kiosk.Position)*CFrame.Angles(0,math.pi,0)
  kiosk:SetAttribute("LobbyStation",station.mode)
  local board=Instance.new("SurfaceGui",kiosk)
  board.Face=Enum.NormalId.Front; board.CanvasSize=Vector2.new(420,300)
  local title=Instance.new("TextLabel",board)
  title.Size=UDim2.fromScale(1,1); title.BackgroundTransparency=1
  title.Text=string.upper(station.name).."\n"..(station.mode=="Practice" and "EASY / NORMAL / HARD" or station.mode=="Spectate" and "WATCH A MATCH" or "SOLO OR WITH FRIENDS")
  title.TextColor3=station.color; title.Font=Enum.Font.GothamBold; title.TextSize=30; title.TextWrapped=true
  local prompt=Instance.new("ProximityPrompt",kiosk)
  prompt.ObjectText=station.name; prompt.ActionText=station.mode=="Spectate" and "Watch match" or "Open queue"
  prompt.HoldDuration=0; prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false
 end

 local spawn=Instance.new("SpawnLocation")
 spawn.Name="Lobby arrival"; spawn.Size=Vector3.new(10,0.2,10)
 spawn.Position=Vector3.new(CENTER.X,floorY+0.1,32)
 spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0
 spawn.Color=mint; spawn.Material=Enum.Material.Neon; spawn.Parent=root
 return root
end
return LobbyWorld
