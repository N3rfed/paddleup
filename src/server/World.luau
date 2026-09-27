-- Rooftop environment, shared by the edit-time builder and game startup.
local World = {}
function World.build()
 local existing = workspace:FindFirstChild("PaddleUp")
 if existing then return existing end
 local root = Instance.new("Model")
 root.Name = "PaddleUp"
 root.Parent = workspace
 local function part(name, size, position, color, material, parent)
  local p = Instance.new("Part")
  p.Name, p.Size, p.Position = name, size, position
  p.Anchored = true
  p.Color = color
  p.Material = material or Enum.Material.SmoothPlastic
  p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
  p.Parent = parent or root
  return p
 end
 local cream = Color3.fromRGB(231,223,202)
 local dark = Color3.fromRGB(27,46,52)
 local teal = Color3.fromRGB(30,111,113)
 local coral = Color3.fromRGB(243,130,99)
 local white = Color3.fromRGB(246,244,220)
 local apartment = part("Apartment tower", Vector3.new(126,176,138),Vector3.new(0,90,0),Color3.fromRGB(92,102,110),Enum.Material.Concrete)
 for y=12,168,12 do
  part("Balcony slab",Vector3.new(131,0.8,142),Vector3.new(0,y,0),cream,Enum.Material.Concrete)
  for x=-50,50,20 do
   for _,z in ipairs({-69.1,69.1}) do
    local w=part("Apartment glazing",Vector3.new(13,7,0.2),Vector3.new(x,y+5,z),Color3.fromRGB(75,121,139),Enum.Material.Glass)
    w.Reflectance=0.25
   end
  end
 end
 part("Roof deck",Vector3.new(132,3,144),Vector3.new(0,179.5,0),cream,Enum.Material.Concrete)
 part("Court surround",Vector3.new(52,0.12,96),Vector3.new(0,181.06,0),Color3.fromRGB(206,116,91))
 part("Playing surface",Vector3.new(40,0.16,80),Vector3.new(0,181.16,0),teal)
 for _,z in ipairs({-7,7}) do
  part("Kitchen",Vector3.new(40,0.02,14),Vector3.new(0,181.255,z),Color3.fromRGB(48,137,129))
 end
 for _,x in ipairs({-20,20}) do part("Sideline",Vector3.new(0.18,0.025,80.2),Vector3.new(x,181.28,0),white) end
 for _,z in ipairs({-40,-14,14,40}) do part("Court line",Vector3.new(40,0.025,0.18),Vector3.new(0,181.28,z),white) end
 for _,z in ipairs({-27,27}) do part("Service center line",Vector3.new(0.18,0.025,26),Vector3.new(0,181.28,z),white) end
 for _,x in ipairs({-21,21}) do part("Net post",Vector3.new(0.4,4,0.4),Vector3.new(x,183,0),dark,Enum.Material.Metal) end
 local net=part("Net collision",Vector3.new(42,3.1,0.18),Vector3.new(0,182.8,0),dark)
 net.Transparency=0.8
 part("Net white tape",Vector3.new(42,0.15,0.22),Vector3.new(0,184.4,0),white)
 for x=-20,20,1 do part("Net cord",Vector3.new(0.035,3,0.035),Vector3.new(x,182.8,0),dark).CanCollide=false end
 for y=181.5,184.25,0.5 do part("Net cord",Vector3.new(42,0.035,0.035),Vector3.new(0,y,0),dark).CanCollide=false end
 for _,x in ipairs({-26,26}) do
  local fence=part("Court glass fence",Vector3.new(0.18,10,96),Vector3.new(x,186,0),Color3.fromRGB(164,208,207),Enum.Material.Glass)
  fence.Transparency=0.8
  for z=-48,48,12 do part("Fence upright",Vector3.new(0.2,10,0.2),Vector3.new(x,186,z),dark,Enum.Material.Metal) end
  part("Fence top rail",Vector3.new(0.2,0.2,96),Vector3.new(x,191,0),dark)
 end
 for _,z in ipairs({-48,48}) do
  local f=part("Court end glass",Vector3.new(52,10,0.18),Vector3.new(0,186,z),Color3.fromRGB(164,208,207),Enum.Material.Glass)
  f.Transparency=0.85
  part("Fence top rail",Vector3.new(52,0.2,0.2),Vector3.new(0,191,z),dark)
 end
 for _,x in ipairs({-65,65}) do
  part("Rooftop parapet",Vector3.new(1,3,144),Vector3.new(x,182.5,0),cream)
  local g=part("Safety glass",Vector3.new(0.2,4,144),Vector3.new(x,186,0),Color3.fromRGB(164,208,207),Enum.Material.Glass)
  g.Transparency=0.55
 end
 for _,z in ipairs({-71,71}) do
  part("Rooftop parapet",Vector3.new(132,3,1),Vector3.new(0,182.5,z),cream)
 end
 part("Pool coping",Vector3.new(25,0.45,49),Vector3.new(-46,181.3,0),white)
 local water=part("Rooftop pool",Vector3.new(22,0.1,46),Vector3.new(-46,181.56,0),Color3.fromRGB(61,173,192),Enum.Material.Glass)
 water.Transparency=0.22
 water.Reflectance=0.25
 for z=-18,18,6 do part("Pool lane tile",Vector3.new(20,0.025,0.09),Vector3.new(-46,181.63,z),Color3.fromRGB(128,217,218)) end
 local function plant(x,z)
  part("Planter",Vector3.new(4,2.5,4),Vector3.new(x,182.25,z),dark,Enum.Material.Concrete)
  part("Tree trunk",Vector3.new(0.7,7,0.7),Vector3.new(x,185,z),Color3.fromRGB(111,83,58),Enum.Material.Wood)
  local crown=part("Topiary",Vector3.new(6,7,6),Vector3.new(x,189,z),Color3.fromRGB(57,108,77),Enum.Material.Grass)
  crown.Shape=Enum.PartType.Ball
 end
 for _,x in ipairs({-57,-33,34,57}) do for _,z in ipairs({-57,57}) do plant(x,z) end end
 for _,z in ipairs({-26,0,26}) do
  part("Lounge seat",Vector3.new(10,1,4),Vector3.new(45,183,z),white,Enum.Material.Fabric)
  part("Lounge back",Vector3.new(10,3,0.8),Vector3.new(45,184,z-2),coral,Enum.Material.Fabric)
  for _,x in ipairs({41,49}) do part("Lounge legs",Vector3.new(0.4,2,3),Vector3.new(x,182,z),dark) end
  part("Side table",Vector3.new(3,2,3),Vector3.new(54,182,z),dark)
 end
 for _,x in ipairs({35,57}) do for _,z in ipairs({-38,38}) do part("Pergola pillar",Vector3.new(0.5,12,0.5),Vector3.new(x,187,z),dark,Enum.Material.Metal) end end
 for z=-39,39,3 do part("Pergola slat",Vector3.new(25,0.35,0.8),Vector3.new(46,193,z),Color3.fromRGB(143,100,65),Enum.Material.Wood) end
 local sign=part("Club sign",Vector3.new(37,7,0.5),Vector3.new(0,193,-49),dark)
 local gui=Instance.new("SurfaceGui")
 gui.Face=Enum.NormalId.Back
 gui.CanvasSize=Vector2.new(1110,210)
 gui.Parent=sign
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1)
 label.BackgroundTransparency=1
 label.Text="PADDLE UP!  /  SKYLINE CLUB"
 label.TextColor3=white
 label.Font=Enum.Font.GothamBold
 label.TextScaled=true
 label.Parent=gui
 local rng=Random.new(82)
 for i=1,30 do
  local angle=i*math.pi*2/30
  local radius=rng:NextNumber(160,310)
  local x,z=math.cos(angle)*radius,math.sin(angle)*radius
  local height=rng:NextInteger(65,220)
  local width=rng:NextInteger(25,46)
  part("City tower",Vector3.new(width,height,width),Vector3.new(x,height/2-5,z),Color3.fromRGB(rng:NextInteger(66,104),rng:NextInteger(78,113),rng:NextInteger(90,123)),Enum.Material.Concrete)
  for y=12,height-8,14 do
   for _,dx in ipairs({-width/2-0.05,width/2+0.05}) do
    part("City window ribbon",Vector3.new(0.1,3,width-5),Vector3.new(x+dx,y,z),Color3.fromRGB(194,174,131),Enum.Material.Neon)
   end
   for _,dz in ipairs({-width/2-0.05,width/2+0.05}) do
    part("City window ribbon",Vector3.new(width-5,3,0.1),Vector3.new(x,y,z+dz),Color3.fromRGB(144,169,181),Enum.Material.Glass)
   end
  end
 end
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
 if not spawn then spawn=Instance.new("SpawnLocation"); spawn.Name="SpawnLocation"; spawn.Parent=workspace end
 if spawn then
  spawn.CFrame=CFrame.new(0,181.5,29)
  spawn.Size=Vector3.new(5,0.3,5)
  spawn.Transparency=1
  spawn.CanCollide=false
  spawn.Neutral=true
  spawn.Duration=0
  for _,v in ipairs(spawn:GetChildren()) do if v:IsA("Decal") then v.Transparency=1 end end
 end
 local base=workspace:FindFirstChild("Baseplate")
 if not base then base=part("Baseplate",Vector3.new(1200,2,1200),Vector3.new(0,-6,0),dark); base.Parent=workspace end
 if base then base.Position=Vector3.new(0,-6,0); base.Size=Vector3.new(1200,2,1200); base.Color=Color3.fromRGB(54,67,73) end
 local lighting=game:GetService("Lighting")
 lighting.ClockTime=17.3
 lighting.Brightness=2.5
 lighting.Ambient=Color3.fromRGB(132,145,166)
 lighting.OutdoorAmbient=Color3.fromRGB(153,158,173)
 lighting.GlobalShadows=true
 local atmosphere=lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",lighting)
 atmosphere.Density=0.26
 atmosphere.Color=Color3.fromRGB(239,210,181)
 atmosphere.Decay=Color3.fromRGB(130,148,174)
 local bloom=lighting:FindFirstChildOfClass("BloomEffect")
 if bloom then bloom.Intensity=0.15; bloom.Size=24; bloom.Threshold=1.5 end
 local dof=lighting:FindFirstChildOfClass("DepthOfFieldEffect")
 if dof then dof.Enabled=false end
 return root
end
return World
