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
local SURFACE=179.5
-- Each crater owns a square cutout in the regolith. No flat slab crosses its bowl.
local CRATERS={
 {-102,4,23,10},{103,66,24,6},{-180,-42,32,16},{-75,153,25,9},
 {142,151,34,19},{-215,139,29,7},{26,-182,32,14},{237,-181,42,23},
 {-278,-235,46,13},{35,258,47,25},{210,-15,23,11},{-30,-300,19,5},
}
local function triangle(parent,a,b,c,color)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local right=ac:Cross(ab).Unit
 local back=bc.Unit
 local up=bc:Cross(right).Unit
 local height=math.abs(ab:Dot(up))
 for _,entry in ipairs({{a,b,right,back,ab},{a,c,-right,-back,ac}}) do
  local wedge=Instance.new("WedgePart")
  wedge.Name="Regolith facet"; wedge.Size=V(0.08,height,math.abs(entry[5]:Dot(back)))
  wedge.CFrame=CFrame.fromMatrix((entry[1]+entry[2])/2,entry[3],up,entry[4])
  wedge.Anchored=true; wedge.CanCollide=true; wedge.CanTouch=false; wedge.CanQuery=true
  wedge.Material=Enum.Material.Slate; wedge.Color=color; wedge.Parent=parent
 end
end
local function craterHeight(entry,x,z)
 local dx,dz=(x-entry[1])/entry[3],(z-entry[2])/entry[3]
 local angle=math.atan2(dz,dx)
 local radius=math.sqrt(dx*dx+dz*dz)/(0.85+0.045*math.sin(angle*5)+0.025*math.cos(angle*3))
 if radius>=1 then return SURFACE end
 -- Broad low basin and steep, broken inner walls, entirely below ground level.
 return SURFACE-entry[4]*(1-radius*radius)^1.35
end
local function crater(parent,entry)
 local x,z,radius,depth=unpack(entry)
 local m=model(parent,"Impact crater")
 m:SetAttribute("Depth",depth); m:SetAttribute("Radius",radius); m:SetAttribute("Center",V(x,SURFACE,z))
 local steps=10
 for i=0,steps-1 do
  for j=0,steps-1 do
   local function vertex(u,v)
    local px,pz=x-radius+2*radius*u/steps,z-radius+2*radius*v/steps
    return V(px,craterHeight(entry,px,pz),pz)
   end
   local a,b,c,d=vertex(i,j),vertex(i+1,j),vertex(i,j+1),vertex(i+1,j+1)
   local shade=math.clamp((SURFACE-(a.Y+b.Y+c.Y+d.Y)/4)/depth,0,1)
   local color=P.dust:Lerp(P.shadow,shade*0.65)
   if shade==0 then
    -- Tiny overlap seals floating-point seams where level tiles meet the bowl.
    part(m,"Level crater shoulder",V(2*radius/steps+0.08,2,2*radius/steps+0.08),(a+d)/2-V(0,1,0),P.dust,Enum.Material.Slate,true)
   else
    triangle(m,a,b,c,color); triangle(m,b,d,c,color)
   end
  end
 end
end
local function ground(parent)
 local m=model(parent,"Excavated lunar surface")
 local rectangles={{-650,-500,650,500}}
 for _,entry in ipairs(CRATERS) do
  local x,z,r=entry[1],entry[2],entry[3]
  assert(math.abs(x)-r>72 or math.abs(z)-r>96,"Crater overlaps court clearance")
  local nextRects={}
  for _,rect in ipairs(rectangles) do
   local left,front,right,back=unpack(rect)
   local a,b,c,d=math.max(left,x-r),math.max(front,z-r),math.min(right,x+r),math.min(back,z+r)
   if a>=c or b>=d then table.insert(nextRects,rect)
   else
    for _,strip in ipairs({{left,front,a,back},{c,front,right,back},{a,front,c,b},{a,d,c,back}}) do
     if strip[3]>strip[1] and strip[4]>strip[2] then table.insert(nextRects,strip) end
    end
   end
  end
  rectangles=nextRects
  crater(m,entry)
 end
 for _,rect in ipairs(rectangles) do
  part(m,"Unbroken regolith",V(rect[3]-rect[1],2,rect[4]-rect[2]),
   V((rect[1]+rect[3])/2,SURFACE-1,(rect[2]+rect[4])/2),P.dust,Enum.Material.Slate,true)
 end
 part(m,"Deep lunar bedrock",V(1300,8,1000),V(0,145,0),P.shadow,Enum.Material.Slate,true)
end
-- Irregular rock geometry from Low Poly Rock Pack by FracturedSkies (2128776869).
-- Mesh bounds normalize each source before varying its proportions and orientation.
local ROCKS={
 {"Flat slab","2128764023",V(178.239075,123.664474,193.074112),V(1.2,0.28,0.85)},
 {"Elongated shard","2128758133",V(217.166626,225.670319,120.977753),V(1.3,0.42,0.48)},
 {"Chipped stone","2128758599",V(156.518799,156.467407,136.799103),V(0.88,0.68,0.75)},
 {"Broad fragment","2128764803",V(170.629242,138.953323,168.476837),V(1.05,0.38,1)},
 {"Jagged fragment","2128766734",V(184.914566,222.987625,158.861313),V(0.58,0.88,0.62)},
 {"Lopsided stone","2128764428",V(179.997101,199.488892,208.224518),V(1.05,0.6,0.8)},
}
local function rock(parent,position,size,random)
 local variant=ROCKS[random:NextInteger(1,#ROCKS)]
 local m=model(parent,"Moon rock"); m:SetAttribute("Shape",variant[1])
 local proportions=variant[4]
 local dimensions=V(proportions.X*random:NextNumber(0.85,1.12),proportions.Y*random:NextNumber(0.8,1.15),proportions.Z*random:NextNumber(0.85,1.15))*size
 local frame=CFrame.new(position+V(0,dimensions.Y*0.42,0))*CFrame.Angles(random:NextNumber(-0.15,0.15),random:NextNumber(0,math.pi*2),random:NextNumber(-0.15,0.15))
 local stone=part(m,variant[1],dimensions,frame,P.shadow:Lerp(P.rim,random:NextNumber(0.1,0.65)),Enum.Material.Slate)
 local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.FileMesh
 mesh.MeshId="rbxassetid://"..variant[2]
 mesh.Scale=V(dimensions.X/variant[3].X,dimensions.Y/variant[3].Y,dimensions.Z/variant[3].Z)
 mesh.Parent=stone
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
 -- A tapered, panel-built hull with a wider propulsion stage and compact capsule.
 local hull=model(m,"Paneled flight vehicle")
 local profile={{15,6.8},{20,8},{29,8},{43,6.8},{51,6.4},{58,4.6},{65,1.8},{67,0.15}}
 local facets=12
 for stage=1,#profile-1 do
  local lower,upper=profile[stage],profile[stage+1]
  for i=0,facets-1 do
   local a,b=i*math.pi*2/facets,(i+1)*math.pi*2/facets
   local function at(y,r,angle) return origin+V(math.cos(angle)*r,y,math.sin(angle)*r) end
   local p,q,r,t=at(lower[1],lower[2],a),at(lower[1],lower[2],b),at(upper[1],upper[2],a),at(upper[1],upper[2],b)
   local color=stage==1 and P.metal or (i%4==0 and P.white:Lerp(P.metal,0.24) or P.white)
   triangle(hull,p,q,r,color); triangle(hull,q,t,r,color)
   if stage>=2 and stage<=5 then
    beam(m,"Longitudinal panel seam",at(lower[1]+0.12,lower[2]+0.06,a),at(upper[1]-0.12,upper[2]+0.06,a),0.07,P.metal,Enum.Material.Metal)
   end
  end
 end
 for _,panel in ipairs(hull:GetChildren()) do
  panel.Name="Tapered hull panel"; panel.Material=Enum.Material.Metal; panel.CanCollide=false; panel.CanQuery=false
 end
 for _,entry in ipairs({{20,8.08},{29,8.08},{43,6.88},{51,6.48}}) do
  cylinder(m,"Stage separation collar",entry[2],0.45,CFrame.new(origin+V(0,entry[1],0)),P.metal,Enum.Material.Metal)
 end
 cylinder(m,"Mission orange belt",8.08,1.1,CFrame.new(origin+V(0,27,0)),P.orange,Enum.Material.Metal)
 for _,x in ipairs({-2.4,2.4}) do
  local frame=CFrame.new(origin+V(x,48,6.15))*CFrame.Angles(math.rad(12),0,0)
  part(m,"Recessed cockpit surround",V(4,3.5,0.5),frame,P.metal,Enum.Material.Metal)
  part(m,"Cockpit glazing",V(3.2,2.6,0.25),frame*CFrame.new(0,0,0.3),P.blue,Enum.Material.Glass)
  part(m,"Window reflection strip",V(0.14,2.3,0.05),frame*CFrame.new(-0.9,0,0.46),P.cyan,Enum.Material.Neon)
 end
 local hatch=CFrame.new(origin+V(0,36,7.65))
 part(m,"Crew hatch frame",V(4.2,7,0.6),hatch,P.metal,Enum.Material.Metal)
 part(m,"Pressure hatch",V(3.5,6.2,0.7),hatch*CFrame.new(0,0,0.15),P.white,Enum.Material.Metal)
 part(m,"Hatch handle",V(1.2,0.15,0.25),hatch*CFrame.new(0,0.5,0.6),P.orange,Enum.Material.Metal)
 for y=23,32,1.3 do
  beam(m,"Access ladder rung",origin+V(-1.7,y,8.2),origin+V(1.7,y,8.2),0.15,P.metal,Enum.Material.Metal)
 end
 for _,x in ipairs({-1.7,1.7}) do beam(m,"Ladder rail",origin+V(x,22,8.2),origin+V(x,33,8.2),0.16,P.metal,Enum.Material.Metal) end
 for i=1,4 do
  local angle=(i-1)*math.pi/2+math.pi/4
  local radial=V(math.cos(angle),0,math.sin(angle))
  local top=origin+radial*6+V(0,20,0)
  local knee=origin+radial*12+V(0,10,0)
  local foot=origin+radial*17+V(0,1.6,0)
  beam(m,"Articulated upper landing leg",top,knee,1.2,P.white,Enum.Material.Metal)
  beam(m,"Hydraulic landing piston",knee,foot,0.7,P.metal,Enum.Material.Metal)
  beam(m,"Landing leg brace",origin+radial*6+V(0,13,0),foot,0.4,P.orange,Enum.Material.Metal)
  sphere(m,"Landing knee joint",V(2,2,2),knee,P.metal,Enum.Material.Metal)
  cylinder(m,"Landing foot",3.4,0.6,CFrame.new(foot),P.metal,Enum.Material.Metal)
  local frame=CFrame.lookAt(origin+radial*8+V(0,21,0),origin+radial*20+V(0,21,0))
  part(m,"Thermal service pod",V(2.5,9,2),frame,P.metal,Enum.Material.Metal)
  for y=18,24,1.2 do part(m,"Service pod radiator fin",V(3,0.2,2.4),frame*CFrame.new(0,y-21,0),P.white,Enum.Material.Metal) end
 end
 for _,x in ipairs({-3,3}) do
  cylinder(m,"Engine turbopump",1.6,3,CFrame.new(origin+V(x,15,0)),P.orange,Enum.Material.Metal)
  for j=0,5 do
   local radius=1.3+j*0.25
   cylinder(m,"Flared nozzle segment",radius,0.85,CFrame.new(origin+V(x,12.8-j*0.8,0)),P.metal,Enum.Material.Metal)
  end
  cylinder(m,"Dark engine exhaust cavity",2.5,0.12,CFrame.new(origin+V(x,8.35,0)),P.dark)
  for _,z in ipairs({-1.6,1.6}) do beam(m,"Engine feed line",origin+V(x,19,z),origin+V(x,13,z),0.22,P.orange,Enum.Material.Metal) end
 end
 beam(m,"Capsule antenna",origin+V(0,64,0),origin+V(0,72,0),0.14,P.metal,Enum.Material.Metal)

end
local function outpost(parent)
 local m=model(parent,"Lunar research outpost")
 -- A pressurized habitat, scientific equipment, and a fixed flag in the vacuum.
 local base=V(106,181,-82)
 cylinder(m,"Habitat pressure vessel",8,24,CFrame.new(base+V(0,8,0))*CFrame.Angles(0,0,math.pi/2),P.white,Enum.Material.Metal)
 -- Break up the plain pressure shell with structural bands, thermal blankets, and service hardware.
 for _,x in ipairs({-10,-5,0,5,10}) do
  cylinder(m,"Pressure hull reinforcing collar",8.25,0.42,CFrame.new(base+V(x,8,0)),P.metal,Enum.Material.Metal)
  cylinder(m,"Collar insulation gasket",8.32,0.12,CFrame.new(base+V(x+0.28,8,0)),P.orange,Enum.Material.Metal)
 end
 -- Long insulated panels follow the habitat's sides and sit just above its curved hull.
 for _,side in ipairs({-1,1}) do
  for _,x in ipairs({-7.5,-2.5,2.5,7.5}) do
   local panelFrame=CFrame.new(base+V(x,8,side*6.65))*CFrame.Angles(side*math.rad(48),0,0)
   part(m,"Segmented thermal blanket",V(4.2,4.4,0.22),panelFrame,P.metal,Enum.Material.DiamondPlate)
   part(m,"Blanket edge latch",V(3.7,0.14,0.28),panelFrame*CFrame.new(0,2.05,0),P.orange,Enum.Material.Metal)
  end
 end
 -- Small observation ports with raised rims and inner glass give the habitat a human scale.
 for _,x in ipairs({-7,0,7}) do
  local portAt=base+V(x,9.5,7.35)
  cylinder(m,"Observation port bezel",1.35,0.28,CFrame.new(portAt)*CFrame.Angles(math.pi/2,0,0),P.metal,Enum.Material.Metal)
  cylinder(m,"Blue observation glass",0.96,0.32,CFrame.new(portAt+V(0,0,0.18))*CFrame.Angles(math.pi/2,0,0),P.cyan,Enum.Material.Glass)
  beam(m,"Port cross brace",portAt+V(-0.86,0,0.38),portAt+V(0.86,0,0.38),0.12,P.white,Enum.Material.Metal)
 end
 for _,x in ipairs({-12,12}) do
  sphere(m,"Habitat end cap",V(4,16,16),base+V(x,8,0),P.white,Enum.Material.Metal)
  part(m,"Habitat support",V(4,4,12),base+V(x,0,0),P.metal,Enum.Material.Metal)
  for _,z in ipairs({-4.5,4.5}) do
   beam(m,"Landing support strut",base+V(x,2,z),base+V(x,6,z*0.8),0.35,P.white,Enum.Material.Metal)
  end
 end
 part(m,"Airlock pressure vestibule",V(6,8,5),base+V(0,4,9),P.white,Enum.Material.Metal)
 part(m,"Airlock armored door",V(4.3,5.8,0.3),base+V(0,3.8,11.65),P.metal,Enum.Material.DiamondPlate)
 part(m,"Airlock window",V(1.7,1.3,0.18),base+V(0,5.3,11.88),P.cyan,Enum.Material.Glass)
 for _,x in ipairs({-1.55,1.55}) do
  cylinder(m,"Hatch locking wheel",0.34,0.16,CFrame.new(base+V(x,3.8,11.92))*CFrame.Angles(math.pi/2,0,0),P.orange,Enum.Material.Metal)
 end
 for _,x in ipairs({-2.8,2.8}) do beam(m,"Airlock frame",base+V(x,0.5,11.65),base+V(x,8,11.65),0.3,P.metal,Enum.Material.Metal) end
 part(m,"Airlock threshold",V(7,0.5,5),base+V(0,0.25,12),P.metal,Enum.Material.DiamondPlate)
 -- A short approach ladder and handrails make the raised hatch feel usable.
 for _,x in ipairs({-2.4,2.4}) do beam(m,"Airlock handrail",base+V(x,1.4,13),base+V(x,4.6,13),0.2,P.orange,Enum.Material.Metal) end
 for y=1.3,4.2,0.75 do beam(m,"Airlock ladder rung",base+V(-2.35,y,13),base+V(2.35,y,13),0.16,P.white,Enum.Material.Metal) end
 -- Equipment boxes, hoses, and a roof mounted instrument mast add visible mission hardware.
 for _,x in ipairs({-7,7}) do
  part(m,"External equipment locker",V(3.5,3.6,3.2),base+V(x,3.1,-5),P.metal,Enum.Material.DiamondPlate)
  part(m,"Locker safety panel",V(2.5,1.4,0.18),base+V(x,3.2,-6.7),P.orange,Enum.Material.Metal)
  for y=2.2,4.2,0.7 do beam(m,"Locker vent",base+V(x-0.9,y,-6.83),base+V(x+0.9,y,-6.83),0.09,P.white,Enum.Material.Metal) end
 end
 for _,x in ipairs({-4,4}) do
  beam(m,"Habitat roof equipment rail",base+V(x,14,-4),base+V(x,14,4),0.2,P.metal,Enum.Material.Metal)
 end
 beam(m,"Habitat weather mast",base+V(0,14,0),base+V(0,22,0),0.22,P.white,Enum.Material.Metal)
 for _,z in ipairs({-1,1}) do sphere(m,"Habitat sensor",V(0.9,0.9,0.9),base+V(0,22,z),P.orange,Enum.Material.Neon) end
 part(m,"Habitat roof antenna",V(0.18,0.15,8),CFrame.new(base+V(0,20,-5))*CFrame.Angles(0,0,math.rad(35)),P.metal,Enum.Material.Metal)
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
 part(m,"Expedition flag",V(8,5,0.12),V(-49,195.5,-87),P.orange,Enum.Material.Fabric)
 cylinder(m,"Flag moon emblem",1.5,0.15,CFrame.new(-49,195.5,-86.9)*CFrame.Angles(math.pi/2,0,0),P.white)
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
  part(m,"Rover seat",V(3,1,2.6),origin+V(1,4,z),P.dark,Enum.Material.SmoothPlastic,true)
  part(m,"Rover seat back",V(0.8,3,2.6),origin+V(-0.5,5,z),P.dark,Enum.Material.SmoothPlastic,true)
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
 for i=1,180 do
  -- Keep the star dome well behind the terrain and away from the horizon line.
  local y=random:NextNumber(0.32,1)
  local angle=random:NextNumber(0,math.pi*2)
  local direction=V(math.sqrt(1-y*y)*math.cos(angle),y,math.sqrt(1-y*y)*math.sin(angle))
  local size=random:NextNumber(0.65,1.3)
  local star=sphere(m,"Distant star",V(size,size,size),center+direction*random:NextNumber(1900,2350),
   i%7==0 and Color3.fromRGB(160,197,255) or Color3.fromRGB(242,239,220),Enum.Material.Neon)
  star.CastShadow=false; star.Transparency=random:NextNumber(0.08,0.35)
  -- A tiny screen-size core keeps stars visible without large skybox star shapes.
  local point=Instance.new("BillboardGui"); point.Name="Starlight"; point.Adornee=star
  point.Size=UDim2.fromOffset(i%5==0 and 3 or 2,i%5==0 and 3 or 2)
  point.LightInfluence=0; point.MaxDistance=4000; point.Parent=star
  local dot=Instance.new("Frame"); dot.Name="Point"; dot.Size=UDim2.fromScale(1,1)
  dot.BackgroundColor3=star.Color; dot.BackgroundTransparency=star.Transparency; dot.BorderSizePixel=0; dot.Parent=point
  if i%5==0 then star:SetAttribute("TwinklePhase",random:NextNumber(0,math.pi*2)) end
 end
 local earth=model(m,"Earth")
 local earthCenter=V(-265,430,-920)
 -- UV-mapped globe and cloud imagery from Creator Store's Realistic Earth (PBR),
 -- asset 11372170772 by 1980svg. Only mesh/texture references are used.
 local globeFrame=CFrame.new(earthCenter)*CFrame.Angles(0,math.rad(-96),math.rad(23.4))
 local function globe(name,diameter,texture,transparency)
  local p=part(earth,name,V(diameter,diameter,diameter),globeFrame,Color3.new(1,1,1))
  local mesh=Instance.new("SpecialMesh")
  mesh.MeshType=Enum.MeshType.FileMesh; mesh.MeshId="rbxassetid://6510695035"
  mesh.TextureId=texture; mesh.Scale=V(1,1,1)*(diameter/6.366715); mesh.Parent=p
  p.Transparency=transparency or 0
  return p
 end
 globe("Textured oceans and continents",134,"rbxassetid://11287088884")
 globe("Fine cloud systems",134.65,"rbxassetid://11286649227",0.18)
 local atmosphere=sphere(earth,"Atmospheric limb",V(138,138,138),globeFrame,P.cyan,Enum.Material.ForceField)
 atmosphere.Transparency=0.82
 local glow=sphere(earth,"Soft blue atmospheric glow",V(142,142,142),globeFrame,Color3.fromRGB(76,160,255),Enum.Material.Neon)
 glow.Transparency=0.965
 local rim=Instance.new("Highlight"); rim.Name="Earth limb glow"; rim.Adornee=earth
 rim.FillColor=Color3.fromRGB(120,177,255); rim.FillTransparency=0.97
 rim.OutlineColor=Color3.fromRGB(118,192,255); rim.OutlineTransparency=0.6
 rim.DepthMode=Enum.HighlightDepthMode.Occluded; rim.Parent=earth
 local saturn=model(m,"Ringed planet")
 local at=V(620,480,700)
 local frame=CFrame.new(at)*CFrame.Angles(math.rad(24),0,math.rad(-18))
 -- Banded globe texture from Saturn [Realistic], asset 15246961312 by jacobthiagobonito.
 local globe=part(saturn,"Saturn cloud bands",V(75,69,75),frame,Color3.new(1,1,1))
 local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.FileMesh
 mesh.MeshId="rbxassetid://453515873"; mesh.TextureId="rbxassetid://128239574"
 mesh.Scale=V(75/1.996349,69/1.995128,75/1.997565); mesh.Parent=globe
 local haze=sphere(saturn,"Saturn atmospheric haze",V(75.6,69.6,75.6),frame,Color3.fromRGB(242,213,169),Enum.Material.ForceField)
 haze.Transparency=0.94
 local rings=model(saturn,"Layered ice rings")
 -- Separate C/B/A rings and the narrow outer F ring leave real dark divisions.
 for index,band in ipairs({{44,3,0.38},{48,3,0.25},{53,5,0.12},{58,4,0.16},{65,4,0.2},{70,5,0.3},{75,2,0.4},{83,0.9,0.5}}) do
  local color=Color3.fromRGB(176,158,128):Lerp(Color3.fromRGB(231,218,190),(index%3)/3)
  local bandModel=model(rings,index<=4 and "Inner ice ring band" or "Outer ice ring band")
  ring(bandModel,"Fine ice ring segment",frame,band[1],band[2],0.16,96,color,Enum.Material.SmoothPlastic)
  for _,segment in ipairs(bandModel:GetChildren()) do segment.Transparency=band[3] end
 end
 -- A few tiny companions add scale without crowding the planet silhouette.
 sphere(saturn,"Titan",V(3.4,3.4,3.4),frame*V(101,8,-12),Color3.fromRGB(184,137,80))
 sphere(saturn,"Icy companion",V(1.5,1.5,1.5),frame*V(-92,-7,18),P.white)
 sphere(m,"Distant red planet",V(25,25,25),V(830,350,-690),Color3.fromRGB(166,83,63),Enum.Material.Neon)
 for _,item in ipairs(m:GetDescendants()) do if item:IsA("BasePart") then item.CastShadow=false end end
 -- Keep the complete backdrop inside the draw distance of lower graphics settings.
 m.WorldPivot=CFrame.new(center)
 m:ScaleTo(0.35)
end
function Moon.build()
 local root=Instance.new("Model"); root.Name="MoonEnvironment"; root:SetAttribute("Version",4)
 root.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local random=Random.new(709)
 ground(root)
 local function surfaceAt(x,z)
  for _,entry in ipairs(CRATERS) do
   if math.abs(x-entry[1])<entry[3] and math.abs(z-entry[2])<entry[3] then return craterHeight(entry,x,z) end
  end
  return SURFACE
 end
 local function clear(x,z,padding)
  if math.abs(x)<72+padding and math.abs(z)<96+padding then return false end
  -- Leave the landing pad, habitat, solar arrays and rover exposed.
  if (V(x,0,z)-V(-112,0,-126)).Magnitude<40+padding then return false end
  if x>76-padding and x<149+padding and z> -132-padding and z< -40+padding then return false end
  if math.abs(x+93)<15+padding and math.abs(z-64)<12+padding then return false end
  return true
 end
 local debris=model(root,"Basalt boulder fields")
 for i=1,420 do
  local x,z=random:NextNumber(-430,430),random:NextNumber(-360,360)
  local size=random:NextNumber(0.8,7)
  if clear(x,z,size) then
   rock(debris,V(x,surfaceAt(x,z),z),size,random)
  end
 end
 -- Local ejecta clusters break up the rims without constructing raised rings.
 for _,entry in ipairs(CRATERS) do
  for i=1,16 do
   local angle=random:NextNumber(0,math.pi*2)
   local radius=entry[3]*random:NextNumber(0.9,1.4)
   local x,z=entry[1]+math.cos(angle)*radius,entry[2]+math.sin(angle)*radius
   local size=random:NextNumber(0.5,2.4)
   if clear(x,z,size) then rock(debris,V(x,surfaceAt(x,z),z),size,random) end
  end
 end
 local gravel=model(root,"Scattered regolith fragments")
 for i=1,360 do
  local x,z=random:NextNumber(-260,260),random:NextNumber(-240,240)
  if clear(x,z,2) then
   local size=random:NextNumber(0.2,0.8)
   rock(gravel,V(x,surfaceAt(x,z),z),size,random)
  end
 end
 local ranges=model(root,"Fractured lunar highlands")
 -- Continuous eroded slopes replace separate wedge-shaped mountain blocks.
 local sectors,bands=80,6
 local function ridgePoint(i,j)
  local angle=(i%sectors)*math.pi*2/sectors
  local t=j/bands
  local radius=520+t*120
  local envelope=math.sin(math.pi*t)^1.5
  local peaks=42+14*math.sin(angle*7)+9*math.cos(angle*11+1)
  local erosion=math.noise(math.cos(angle)*5,math.sin(angle)*5,t*3)*17
  return V(math.cos(angle)*radius,SURFACE-0.15+envelope*(peaks+erosion),math.sin(angle)*radius*0.75)
 end
 for i=0,sectors-1 do
  local ridge=model(ranges,"Eroded ridge section")
  for j=0,bands-1 do
   local a,b,c,d=ridgePoint(i,j),ridgePoint(i+1,j),ridgePoint(i,j+1),ridgePoint(i+1,j+1)
   local color=P.shadow:Lerp(P.dust,0.45+0.08*math.sin(i*0.7+j))
   triangle(ridge,a,b,c,color); triangle(ridge,b,d,c,color)
  end
  -- Solid below-grade footings seal the underside and stay clear of crater cutouts.
  local angle=(i+0.5)*math.pi*2/sectors
  local radial=V(math.cos(angle),0,math.sin(angle)*0.75)
  local frame=CFrame.lookAt(V(radial.X*570,SURFACE-16,radial.Z*570),V(0,SURFACE-16,0))
  part(ridge,"Buried highland foundation",V(2*640*math.sin(math.pi/sectors)+2,32,150),frame,P.dust,Enum.Material.Slate)
  for _,face in ipairs(ridge:GetChildren()) do
   if face.Name~="Buried highland foundation" then face.Name="Eroded highland face" end
   face.CanCollide=false; face.CanQuery=false
  end
 end
 for _,x in ipairs({-65,65}) do
  part(root,"Outpost platform edge",V(1,1.2,180),V(x,181.4,0),P.metal,Enum.Material.Metal)
  for z=-80,80,20 do part(root,"Platform navigation light",V(0.3,0.15,5),V(x,182.1,z),P.cyan,Enum.Material.Neon) end
 end
 for _,z in ipairs({-89,89}) do part(root,"Platform end edge",V(132,1.2,1),V(0,181.4,z),P.metal,Enum.Material.Metal) end
 for _,z in ipairs({-26,0,26}) do
  local frame=CFrame.new(48,183,z)*CFrame.Angles(0,-math.pi/2,0)
  part(root,"Lounge seat",V(10,1,4),frame,P.white,Enum.Material.Metal,true)
  part(root,"Lunar bench back",V(10,3,0.5),frame*CFrame.new(0,1,-1.8),P.metal,Enum.Material.Metal,true)
  for _,x in ipairs({-4,4}) do part(root,"Bench support",V(0.5,2,3),frame*CFrame.new(x,-1,0),P.metal,Enum.Material.Metal,true) end
 end
 rocket(root); outpost(root); rover(root); sky(root,random)
 root:SetAttribute("ExpectedDescendants",#root:GetDescendants())
 return root
end
return Moon
