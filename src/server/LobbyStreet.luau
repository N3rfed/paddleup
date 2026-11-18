-- Street furniture and planting for the public block directly outside reception.
local Street={}
local V=Vector3.new
local asphaltTrim=Color3.fromRGB(46,51,56)
local iron=Color3.fromRGB(54,68,67)
local cream=Color3.fromRGB(227,222,195)
local red=Color3.fromRGB(194,62,44)
function Street.build(district,origin)
 local old=district:FindFirstChild("Clubhouse block")
 if old then
  if old:GetAttribute("FrontageVersion")==3 then return end
  old:Destroy()
 end
 local block=Instance.new("Model")
 block.Name="Clubhouse block"
 local function piece(name,size,x,y,z,color,material,shape)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Position=origin+V(x,y,z); p.Color=color
  p.Material=material; p.Shape=shape or Enum.PartType.Block
  p.Anchored=true; p.CanTouch=false
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=block
  return p
 end
 local grass=Enum.Material.Grass
 local metal=Enum.Material.Metal
 local sphere=Enum.PartType.Ball
 local wood=Enum.Material.Wood
 local paving=Color3.fromRGB(158,156,146)
 for _,side in ipairs({-1,1}) do
  -- The park fills the block from the west sidewalk to the tower setback.
  -- Its center aisle and both ends meet paved paths at the same height.
  local width=side==-1 and 97.5 or 22.5
  piece("Pocket park lawn",V(width,0.4,43),side*(2.5+width/2),0.2,148.5,Color3.fromRGB(101,146,84),grass)
  for i=1,(side==-1 and 3 or 2) do
   local x=side==-1 and -i*26 or 8+i*4
   local z=i%2==1 and 151 or 132
   piece("Street tree trunk",V(1.3,9,1.3),x,4.7,z,Color3.fromRGB(104,78,54),wood)
   piece("Tree crown",V(9,10,9),x,11,z,Color3.fromRGB(63,116,77),grass,sphere)
   piece("Tree crown",V(7,7,7),x+2.5,10,z+1.8,Color3.fromRGB(81,132,81),grass,sphere)
  end
  local x=side==-1 and -42 or 13
  piece("Bench seat",V(7,0.4,2),x,1.85,122,Color3.fromRGB(146,99,64),wood)
  piece("Bench back",V(7,1.5,0.35),x,2.8,122.9,Color3.fromRGB(146,99,64),wood)
  for _,dx in ipairs({-2.4,2.4}) do
   piece("Bench leg",V(0.45,1.5,1.4),x+dx,1.03,122,iron,metal)
  end
  x=side*52
  piece("Hydrant barrel",V(1.1,2.2,1.1),x,1.1,87,red,metal)
  piece("Hydrant bonnet",V(1.4,1,1.4),x,2.22,87,red,metal,sphere)
  piece("Hydrant outlets",V(2,0.62,0.65),x,1.4,87,cream,metal,Enum.PartType.Cylinder)
  for _,z in ipairs({87,126}) do
   local pad=z==126 and 0.4 or 0
   piece("Streetlamp post",V(0.38,11,0.38),side*27,5.5+pad,z,iron,metal)
   piece("Lantern",V(1.3,1.6,1.3),side*27,11.55+pad,z,cream,Enum.Material.Neon)
   piece("Lantern cap",V(1.7,0.3,1.7),side*27,12.5+pad,z,iron,metal)
  end
 end
 piece("Garden walk",V(5,0.4,43),0,0.2,148.5,paving,Enum.Material.Concrete)
 for _,x in ipairs({-102.5,27.5}) do
  piece("Park perimeter walk",V(5,0.4,43),x,0.2,148.5,paving,Enum.Material.Concrete)
 end
 piece("Garden terrace",V(135,0.4,8),-37.5,0.2,123,paving,Enum.Material.Concrete)
 piece("Rear garden walk",V(135,0.4,5),-37.5,0.2,172.5,paving,Enum.Material.Concrete)
 for _,side in ipairs({-1,1}) do
  piece("Building side walk",V(5,0.4,170),side*96,0.2,4,paving,Enum.Material.Concrete)
 end
 piece("Building rear walk",V(197,0.4,5),0,0.2,-83.5,paving,Enum.Material.Concrete)
 for z=96,112,3 do
  piece("Crosswalk stripe",V(8,0.04,1.35),0,0.26,z,cream,Enum.Material.SmoothPlastic).CanCollide=false
 end
 local function car(x,z,paint,direction)
  piece("Car body",V(10.2,1.55,4.45),x,1.87,z,paint,metal)
  piece("Car glazing",V(5.6,1.45,3.94),x-direction*0.35,3.22,z,Color3.fromRGB(66,90,100),Enum.Material.Glass)
  piece("Car roof",V(5.7,0.27,4),x-direction*0.35,4.05,z,paint,metal)
  for _,side in ipairs({-1,1}) do
   piece("Window pillar",V(0.25,1.5,0.1),x,3.2,z+side*1.97,paint,metal)
   for _,axle in ipairs({-3.2,3.2}) do
    local wheel=piece("Tire",V(0.63,1.9,1.9),x+axle,1.18,z+side*2.04,asphaltTrim,Enum.Material.Rubber,Enum.PartType.Cylinder)
    wheel.Orientation=V(0,90,0)
   end
   for _,endSign in ipairs({-1,1}) do
    piece("Car lamp",V(0.1,0.44,0.9),x+endSign*5.1,2,z+side*1.53,endSign==direction and cream or red,Enum.Material.SmoothPlastic)
   end
  end
 end
 car(-64,98,Color3.fromRGB(60,108,127),1)
 car(40,110,Color3.fromRGB(191,137,77),-1)
 car(78,98,Color3.fromRGB(110,138,115),1)
 block:SetAttribute("FrontageVersion",3)
 block.Parent=district
end
return Street
