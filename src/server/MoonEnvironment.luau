-- Visual scenery only. Court geometry and all gameplay physics belong to World/MatchRules.
local Moon={}
local V=Vector3.new
local P={dust=Color3.fromRGB(143,146,156),rim=Color3.fromRGB(164,169,181),shadow=Color3.fromRGB(84,89,105),
 white=Color3.fromRGB(224,231,236),metal=Color3.fromRGB(55,65,81),dark=Color3.fromRGB(23,30,44),
 orange=Color3.fromRGB(245,145,65),cyan=Color3.fromRGB(92,219,237),blue=Color3.fromRGB(35,74,125)}
local function part(parent,name,size,frame,color,material,solid)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.CFrame=typeof(frame)=="CFrame" and frame or CFrame.new(frame)
 p.Anchored=true; p.CanCollide=solid==true; p.CanTouch=false; p.CanQuery=solid==true
 p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent
 return p
end
local function model(parent,name)
 local m=Instance.new("Model"); m.Name=name; m.Parent=parent; return m
end
local function sphere(parent,name,size,frame,color,material)
 local p=part(parent,name,size,frame,color,material)
 -- Sphere meshes preserve elliptical proportions; Ball parts use a round collision shape.
 local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=p
 return p
end
local function cylinder(parent,name,radius,height,frame,color,material)
 local p=part(parent,name,V(height,radius*2,radius*2),frame*CFrame.Angles(0,0,math.pi/2),color,material)
 p.Shape=Enum.PartType.Cylinder; return p
end
local function beam(parent,name,a,b,width,color,material)
 return part(parent,name,V(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material)
end
local function ring(parent,name,frame,radius,width,height,count,color,material)
 for i=1,count do
  local angle=i*2*math.pi/count
  local at=V(math.cos(angle)*radius,0,math.sin(angle)*radius)
  part(parent,name,V(2*radius*math.sin(math.pi/count)+0.2,height,width),
   frame*CFrame.lookAt(at,Vector3.zero),color,material)
 end
end
local function sign(parent,name,frame,size,title,subtitle)
 local board=part(parent,name,size,frame*CFrame.Angles(0,math.pi,0),P.dark,Enum.Material.Metal)
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Front; gui.CanvasSize=Vector2.new(900,220)
 gui.LightInfluence=0; gui.Parent=board
 for index,value in ipairs({title,subtitle}) do
  local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(0.92,index==1 and 0.5 or 0.27)
  label.Position=UDim2.fromScale(0.04,index==1 and 0.1 or 0.65); label.BackgroundTransparency=1
  label.Text=value; label.Font=Enum.Font.GothamBold; label.TextScaled=true
  label.TextColor3=index==1 and P.white or P.cyan; label.Parent=gui
 end
 return board
end
local function crater(parent,x,z,radius,random)
 local m=model(parent,"Impact crater")
 cylinder(m,"Shadowed crater floor",radius*0.86,0.14,CFrame.new(x,179.58,z),P.shadow,Enum.Material.Slate)
 cylinder(m,"Crater basin",radius*0.56,0.16,CFrame.new(x,179.68,z),P.dust:Lerp(P.shadow,0.45),Enum.Material.Slate)
 for i=1,32 do
  local angle=i*math.pi*2/32
  local at=V(x+math.cos(angle)*radius,180.35+random:NextNumber(-0.2,0.2),z+math.sin(angle)*radius)
  local frame=CFrame.lookAt(at,V(x,at.Y,z))*CFrame.Angles(math.rad(-14),0,0)
  part(m,"Raised impact rim",V(radius*0.22,1.1,radius*0.35),frame,P.rim:Lerp(P.dust,random:NextNumber()),Enum.Material.Slate)
 end
end
local function rock(parent,position,size,random)
 local m=model(parent,"Moon rock")
 local frame=CFrame.new(position)*CFrame.Angles(random:NextNumber(-0.25,0.25),random:NextNumber(0,6.28),random:NextNumber(-0.25,0.25))
 local base=sphere(m,"Fractured basalt",V(size,size*0.65,size*0.8),frame,P.shadow:Lerp(P.rim,random:NextNumber()),Enum.Material.Slate)
 local cap=Instance.new("WedgePart"); cap.Name="Angular rock face"; cap.Size=V(size*0.9,size*0.55,size*0.85)
 cap.CFrame=frame*CFrame.new(0,size*0.4,0); cap.Anchored=true; cap.CanCollide=false; cap.CanTouch=false; cap.CanQuery=false
 cap.Material=Enum.Material.Slate; cap.Color=base.Color:Lerp(P.rim,0.2); cap.Parent=m
end
local function rocket(parent)
 local m=model(parent,"SELENE Rocket and landing pad")
 local origin=V(-112,180,-126)
 cylinder(m,"Landing pad",37,0.7,CFrame.new(origin),P.dark,Enum.Material.Concrete)
 ring(m,"Pad safety markings",CFrame.new(origin+V(0,0.5,0)),32,1.4,0.1,48,P.orange)
 for i=1,12 do
  local angle=i*math.pi/6
  local p=origin+V(math.cos(angle)*36,0.75,math.sin(angle)*36)
  cylinder(m,"Landing beacon",0.75,0.4,CFrame.new(p),P.cyan,Enum.Material.Neon)
 end
 cylinder(m,"Rocket fuselage",7,40,CFrame.new(origin+V(0,35,0)),P.white,Enum.Material.Metal)
 sphere(m,"Rounded nose cone",V(14,22,14),origin+V(0,55,0),P.white,Enum.Material.Metal)
 for _,height in ipairs({17,28,49}) do
  cylinder(m,"Orange identification band",7.08,1.4,CFrame.new(origin+V(0,height,0)),P.orange)
 end
 for _,height in ipairs({35,43}) do
  local at=origin+V(0,height,7)
  local frame=CFrame.new(at)*CFrame.Angles(math.pi/2,0,0)
  cylinder(m,"Porthole housing",2.15,0.65,frame,P.dark,Enum.Material.Metal)
  cylinder(m,"Blue porthole glass",1.65,0.75,frame,P.cyan,Enum.Material.Neon)
 end
 for i=1,4 do
  local angle=(i-1)*math.pi/2
  local radial=V(math.cos(angle),0,math.sin(angle))
  beam(m,"Landing strut",origin+radial*5+V(0,18,0),origin+radial*15+V(0,2,0),1.1,P.metal,Enum.Material.Metal)
  cylinder(m,"Landing foot",3,0.7,CFrame.new(origin+radial*15+V(0,1.4,0)),P.dark,Enum.Material.Metal)
  local fin=Instance.new("WedgePart"); fin.Name="Stabilizer fin"; fin.Size=V(1,12,9)
  fin.CFrame=CFrame.new(origin+radial*8+V(0,18,0))*CFrame.Angles(0,-angle-math.pi/2,0)
  fin.Color=P.orange; fin.Material=Enum.Material.Metal; fin.Anchored=true; fin.CanCollide=false; fin.CanQuery=false; fin.CanTouch=false; fin.Parent=m
 end
 for _,x in ipairs({-3,3}) do
  cylinder(m,"Engine bell",2.2,6,CFrame.new(origin+V(x,12,0)),P.metal,Enum.Material.Metal)
  cylinder(m,"Engine throat",1.65,0.2,CFrame.new(origin+V(x,8.9,0)),P.dark)
 end
 sign(m,"Rocket mission plate",CFrame.new(origin+V(0,23,7.2)),V(8,3,0.2),"SELENE","LUNAR EXPLORER  /  07")
 sign(m,"Launch control board",CFrame.new(origin+V(26,4,23)),V(10,5,0.5),"LANDING ZONE 01","MISSION STATUS / DOCKED")
end
local function outpost(parent)
 local m=model(parent,"Lunar research outpost")
 -- A pressurized habitat, scientific equipment, and a fixed flag in the vacuum.
 local base=V(106,181,-82)
 cylinder(m,"Habitat pressure vessel",8,24,CFrame.new(base+V(0,8,0))*CFrame.Angles(0,0,math.pi/2),P.white,Enum.Material.Metal)
 for _,x in ipairs({-12,12}) do
  sphere(m,"Habitat end cap",V(4,16,16),base+V(x,8,0),P.white,Enum.Material.Metal)
  part(m,"Habitat support",V(4,4,12),base+V(x,0,0),P.metal,Enum.Material.Metal)
 end
 sign(m,"Research station lettering",CFrame.new(base+V(0,10,8.1)),V(16,4,0.3),"SELENE RESEARCH","HABITAT 02 / SCIENCE DIVISION")
 part(m,"Airlock",V(5,7,2),base+V(0,3.5,8),P.dark,Enum.Material.Metal)
 part(m,"Airlock window",V(3,2,0.2),base+V(0,5,9.1),P.cyan,Enum.Material.Neon)
 for _,x in ipairs({85,109,133}) do
  beam(m,"Solar array support",V(x,180,-119),V(x,187,-119),0.6,P.metal,Enum.Material.Metal)
  local frame=CFrame.new(x,188,-119)*CFrame.Angles(math.rad(22),0,0)
  part(m,"Solar panel frame",V(20,0.6,12),frame,P.white,Enum.Material.Metal)
  for i=-2,2 do for j=-1,1 do
   part(m,"Photovoltaic cell",V(3.6,0.12,3.4),frame*CFrame.new(i*3.9,0.36,j*3.8),P.blue,Enum.Material.Glass)
  end end
 end
 local dish=V(137,191,-51)
 beam(m,"Communications mast",V(137,180,-51),dish,0.8,P.metal,Enum.Material.Metal)
 local dishFrame=CFrame.new(dish)*CFrame.Angles(math.rad(28),0,math.rad(12))
 sphere(m,"Satellite dish",V(13,1.5,13),dishFrame,P.white,Enum.Material.Metal)
 ring(m,"Dish lip",dishFrame,6,0.4,0.4,28,P.metal,Enum.Material.Metal)
 beam(m,"Dish receiver",dish,dish+V(0,5,0),0.35,P.metal,Enum.Material.Metal)
 sphere(m,"Receiver tip",V(1,1,1),dish+V(0,5,0),P.orange)
 beam(m,"Flag mast",V(-53,180,-87),V(-53,198,-87),0.3,P.white,Enum.Material.Metal)
 beam(m,"Flag crossbar",V(-53,198,-87),V(-45,198,-87),0.2,P.white,Enum.Material.Metal)
 sign(m,"Mission flag",CFrame.new(-49,195.5,-87),V(8,5,0.12),"PADDLE UP","LUNAR EXPEDITION")
 for i=1,7 do
  local at=V(75+i*3,180.4,-55+i*2)
  cylinder(m,"Sample canister",0.7,1.6,CFrame.new(at),i%2==0 and P.orange or P.white,Enum.Material.Metal)
 end
end
local function rover(parent)
 local m=model(parent,"Lunar rover")
 local origin=V(-93,181,64)
 part(m,"Rover chassis",V(13,2.4,8),origin+V(0,2,0),P.white,Enum.Material.Metal)
 part(m,"Rover battery pack",V(4,2,7),origin+V(-4,4,0),P.orange,Enum.Material.Metal)
 for _,x in ipairs({-4.5,0,4.5}) do for _,z in ipairs({-5,5}) do
  local frame=CFrame.new(origin+V(x,0.6,z))*CFrame.Angles(math.pi/2,0,0)
  cylinder(m,"Wire mesh rover wheel",2.2,1.4,frame,P.dark,Enum.Material.DiamondPlate)
  cylinder(m,"Wheel hub",0.8,1.6,frame,P.metal,Enum.Material.Metal)
 end end
 for _,z in ipairs({-2,2}) do
  part(m,"Rover seat",V(3,1,2.6),origin+V(1,4,z),P.dark)
  part(m,"Rover seat back",V(0.8,3,2.6),origin+V(-0.5,5,z),P.dark)
 end
 beam(m,"Rover camera mast",origin+V(5,3,0),origin+V(5,11,0),0.3,P.white,Enum.Material.Metal)
 part(m,"Stereo survey camera",V(1.5,1,3),origin+V(5,11,0),P.dark)
 for _,z in ipairs({-1,1}) do sphere(m,"Camera lens",V(0.2,0.6,0.6),origin+V(5.8,11,z),P.cyan,Enum.Material.Neon) end
 for i=1,20 do for _,z in ipairs({-5,5}) do
  part(m,"Rover track",V(0.6,0.025,1.8),V(-105-i*1.8,179.55,64+z),P.shadow,Enum.Material.Slate)
 end end
end
local function sky(parent,random)
 local m=model(parent,"Lunar sky")
 -- Keep the sky visible even when distant geometry would normally stream out.
 m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local center=V(0,180,0)
 for _,axis in ipairs({V(1,0,0),V(0,1,0),V(0,0,1)}) do for _,side in ipairs({-1,1}) do
  local size=V(axis.X==1 and 2 or 2000,axis.Y==1 and 2 or 2000,axis.Z==1 and 2 or 2000)
  local wall=part(m,"Black space backdrop",size,center+axis*1000*side,Color3.new(0,0,0),Enum.Material.Neon)
  wall.CastShadow=false
 end end
 for i=1,420 do
  local y=random:NextNumber(0.06,1)
  local angle=random:NextNumber(0,math.pi*2)
  local direction=V(math.sqrt(1-y*y)*math.cos(angle),y,math.sqrt(1-y*y)*math.sin(angle))
  local size=random:NextNumber(0.5,1.4)
  local star=sphere(m,"Distant star",V(size,size,size),center+direction*random:NextNumber(820,940),
   i%7==0 and Color3.fromRGB(160,197,255) or Color3.fromRGB(242,239,220),Enum.Material.Neon)
  star.CastShadow=false
 end
 local earth=model(m,"Earth")
 local earthCenter=V(-265,430,-920)
 local radius=67
 sphere(earth,"Blue oceans",V(radius*2,radius*2,radius*2),earthCenter,Color3.fromRGB(40,118,190))
 -- Overlapping land shapes suggest the major continents rather than isolated dots.
 for _,region in ipairs({
  {52,-53,24,18},{44,-40,27,22},{32,-37,20,25},{23,-28,14,18},{15,-20,10,17},
  {4,-18,19,23},{-8,-13,24,25},{-21,-16,18,27},{-35,-20,12,24},{-47,-23,8,17},
  {30,18,26,15},{17,22,30,26},{3,28,25,27},{-12,29,21,24},{-25,33,13,22},
  {43,21,21,18},{54,29,22,17},{52,46,31,20},{43,59,29,25},{28,61,26,24},{17,52,15,21},
  {-25,68,24,17},{-33,76,20,15},{66,-12,13,18},
 }) do
  local latitude,longitude=math.rad(region[1]),math.rad(region[2])
  local normal=V(math.sin(longitude)*math.cos(latitude),math.sin(latitude),math.cos(longitude)*math.cos(latitude))
  local frame=CFrame.lookAt(earthCenter+normal*(radius-0.6),earthCenter+normal*(radius+10))*CFrame.Angles(math.pi/2,0,0)
  sphere(earth,"Continental landmass",V(region[3],3,region[4]),frame,Color3.fromRGB(103,163,135))
 end
 for i=1,30 do
  local normal=V(random:NextNumber(-1,1),random:NextNumber(-0.9,0.9),random:NextNumber(-1,1)).Unit
  local frame=CFrame.lookAt(earthCenter+normal*(radius+0.8),earthCenter+normal*(radius+10))*CFrame.Angles(math.pi/2,0,0)
  local cloud=sphere(earth,"Cloud band",V(random:NextNumber(15,35),1.5,random:NextNumber(3,8)),frame,P.white)
  cloud.Transparency=0.15
 end
 local halo=sphere(earth,"Blue atmospheric rim",V(138,138,138),earthCenter,P.cyan,Enum.Material.Neon); halo.Transparency=0.96
 local saturn=model(m,"Ringed planet")
 local at=V(620,480,700)
 sphere(saturn,"Golden planet",V(75,75,75),at,Color3.fromRGB(195,159,109),Enum.Material.Neon)
 local frame=CFrame.new(at)*CFrame.Angles(math.rad(24),0,math.rad(-18))
 ring(saturn,"Outer planetary ring",frame,66,12,0.8,80,Color3.fromRGB(151,135,122),Enum.Material.Neon)
 ring(saturn,"Inner planetary ring",frame,53,6,0.8,64,Color3.fromRGB(217,194,157),Enum.Material.Neon)
 sphere(m,"Distant red planet",V(25,25,25),V(830,350,-690),Color3.fromRGB(166,83,63),Enum.Material.Neon)
 for _,item in ipairs(m:GetDescendants()) do if item:IsA("BasePart") then item.CastShadow=false end end
 -- Keep the complete backdrop inside the draw distance of lower graphics settings.
 m.WorldPivot=CFrame.new(center)
 m:ScaleTo(0.35)
end
function Moon.build()
 local root=Instance.new("Model"); root.Name="MoonEnvironment"; root:SetAttribute("Version",1)
 local random=Random.new(709)
 part(root,"Lunar regolith",V(1300,8,1000),V(0,175.5,0),P.dust,Enum.Material.Slate,true)
 -- All objects remain outside the court's existing 132 x 180 stud platform.
 for _,entry in ipairs({{-90,5,17},{85,60,20},{-173,-40,31},{-72,155,23},{137,143,32},{-210,133,28},{30,-179,30},{230,-180,41},{-272,-233,46},{35,254,46}}) do
  crater(root,entry[1],entry[2],entry[3],random)
 end
 for i=1,110 do
  local x,z=random:NextNumber(-430,430),random:NextNumber(-360,360)
  if (math.abs(x)>165 or math.abs(z)>200) or (x>70 and z>100) then
   local size=random:NextNumber(1.5,8)
   rock(root,V(x,179.5+size*0.22,z),size,random)
  end
 end
 for i=1,25 do
  local angle=i*math.pi*2/25; local radius=random:NextNumber(450,560)
  local size=random:NextNumber(30,80)
  sphere(root,"Distant lunar ridge",V(size*1.8,size*0.8,size*1.4),
   CFrame.new(math.cos(angle)*radius,179+size*0.05,math.sin(angle)*radius*0.75)*CFrame.Angles(0,angle,0),P.shadow,Enum.Material.Slate)
 end
 for _,x in ipairs({-65,65}) do
  part(root,"Outpost platform edge",V(1,1.2,180),V(x,181.4,0),P.metal,Enum.Material.Metal)
  for z=-80,80,20 do part(root,"Platform navigation light",V(0.3,0.15,5),V(x,182.1,z),P.cyan,Enum.Material.Neon) end
 end
 for _,z in ipairs({-89,89}) do part(root,"Platform end edge",V(132,1.2,1),V(0,181.4,z),P.metal,Enum.Material.Metal) end
 for _,z in ipairs({-26,0,26}) do
  local frame=CFrame.new(48,183,z)*CFrame.Angles(0,-math.pi/2,0)
  part(root,"Lounge seat",V(10,1,4),frame,P.white,Enum.Material.Metal)
  part(root,"Lunar bench back",V(10,3,0.5),frame*CFrame.new(0,1,-1.8),P.metal,Enum.Material.Metal)
  for _,x in ipairs({-4,4}) do part(root,"Bench support",V(0.5,2,3),frame*CFrame.new(x,-1,0),P.metal,Enum.Material.Metal) end
 end
 sign(root,"Lunar court identity",CFrame.new(0,188,-90),V(29,5.5,0.5),"SELENE / LUNAR COURT","OUTPOST 07  /  SEA OF TRANQUILITY")
 for _,x in ipairs({-12,12}) do beam(root,"Sign support",V(x,180,-90),V(x,188,-90),0.4,P.metal,Enum.Material.Metal) end
 rocket(root); outpost(root); rover(root); sky(root,random)
 return root
end
return Moon
