-- Anchored furniture blueprints. Built once per lobby, then cloned into named zones.
-- No animation loops, scripts, external assets, or gameplay dependencies.
local Furniture={}
Furniture.Palette={
 ivory=Color3.fromRGB(229,222,206), linen=Color3.fromRGB(210,204,185),
 forest=Color3.fromRGB(40,69,58), teal=Color3.fromRGB(65,91,81),
 walnut=Color3.fromRGB(83,59,44), brass=Color3.fromRGB(157,133,88),
 sage=Color3.fromRGB(125,145,111), ink=Color3.fromRGB(38,45,40),
 warm=Color3.fromRGB(255,232,197),
}
function Furniture.new()
 local P=Furniture.Palette
 local templates={}
 local current
 local function part(name,size,pos,color,material,collide,class)
  local p=Instance.new(class or "Part")
  p.Name=name; p.Size=size; p.CFrame=CFrame.new(pos)
  p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
  p.CanCollide=collide==true; p.CanTouch=class=="Seat"; p.CanQuery=collide==true
  p.CastShadow=collide==true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=current
  return p
 end
 local function ball(name,size,pos,color,material)
  local p=part(name,size,pos,color,material)
  local mesh=Instance.new("SpecialMesh",p); mesh.MeshType=Enum.MeshType.Sphere
  return p
 end
 local function disc(name,diameter,height,pos,color,material,collide)
  local p=part(name,Vector3.new(height,diameter,diameter),pos,color,material,collide)
  p.Shape=Enum.PartType.Cylinder; p.CFrame*=CFrame.Angles(0,0,math.pi/2)
  return p
 end
 local function light(p,range,brightness)
  local l=Instance.new("PointLight",p); l.Color=P.warm
  l.Range=range; l.Brightness=brightness; l.Shadows=false
 end
 local function blueprint(name,build)
  current=Instance.new("Model"); current.Name=name
  build()
  current.WorldPivot=CFrame.identity
  templates[name]=current
 end
 local function legs(width,depth,height)
  for _,x in ipairs({-width/2+0.5,width/2-0.5}) do
   for _,z in ipairs({-depth/2+0.5,depth/2-0.5}) do
    part("Tapered walnut leg",Vector3.new(0.3,height,0.3),Vector3.new(x,height/2,z),P.walnut,Enum.Material.Wood)
   end
  end
 end
 local function seat(name,size,pos,color)
  local p=part(name,size,pos,color,Enum.Material.Fabric,true,"Seat")
  p:SetAttribute("LobbyFurniture",true)
  return p
 end
 blueprint("Sofa",function()
  legs(12,5,0.8)
  part("Upholstered base",Vector3.new(12,1,5),Vector3.new(0,1.1,0),P.forest,Enum.Material.Fabric,true)
  for _,x in ipairs({-3,3}) do
   seat("Sofa cushion",Vector3.new(5.2,0.65,4.2),Vector3.new(x,1.9,-0.2),P.teal)
   part("Back cushion",Vector3.new(5.2,2.8,1),Vector3.new(x,3,1.9),P.forest,Enum.Material.Fabric,true)
  end
  for _,x in ipairs({-5.9,5.9}) do
   part("Soft armrest",Vector3.new(1,2.5,5),Vector3.new(x,2.3,0),P.forest,Enum.Material.Fabric,true)
   local pillow=ball("Linen throw pillow",Vector3.new(2,2,0.9),Vector3.new(x*0.74,3,-0.1),P.linen,Enum.Material.Fabric)
   pillow.CFrame*=CFrame.Angles(0,0,x>0 and 0.15 or -0.15)
  end
  part("Sage blanket on cushion",Vector3.new(2.2,0.12,3.5),Vector3.new(-2.6,2.3,-0.3),P.sage,Enum.Material.Fabric)
  part("Blanket drape",Vector3.new(2.2,1.4,0.12),Vector3.new(-2.6,1.7,-2.25),P.sage,Enum.Material.Fabric)
 end)
 blueprint("LoungeChair",function()
  legs(4.8,4.8,0.8)
  part("Lounge base",Vector3.new(4.8,1,4.8),Vector3.new(0,1.1,0),P.walnut,Enum.Material.Wood,true)
  seat("Linen seat",Vector3.new(3.7,0.7,4),Vector3.new(0,1.95,-0.1),P.linen)
  local back=part("Linen back",Vector3.new(4,3,0.8),Vector3.new(0,3,1.95),P.linen,Enum.Material.Fabric,true)
  back.CFrame*=CFrame.Angles(math.rad(-8),0,0)
  for _,x in ipairs({-2.1,2.1}) do part("Walnut arm",Vector3.new(0.4,0.5,4.6),Vector3.new(x,2.7,0),P.walnut,Enum.Material.Wood,true) end
  ball("Sage cushion",Vector3.new(1.9,1.7,0.7),Vector3.new(0,2.7,1),P.sage,Enum.Material.Fabric)
 end)
 blueprint("CafeChair",function()
  legs(3.4,3.4,1.8)
  seat("Cafe seat",Vector3.new(3.4,0.5,3.4),Vector3.new(0,2,-0.1),P.teal)
  part("Curved look back",Vector3.new(3.4,2.5,0.6),Vector3.new(0,3.3,1.4),P.teal,Enum.Material.Fabric,true)
 end)
 blueprint("BarStool",function()
  disc("Stool foot",2.5,0.2,Vector3.new(0,0.1,0),P.ink,Enum.Material.Metal,true)
  part("Brass stem",Vector3.new(0.35,3,0.35),Vector3.new(0,1.6,0),P.brass,Enum.Material.Metal)
  disc("Footrest",1.8,0.15,Vector3.new(0,1.3,0),P.brass,Enum.Material.Metal)
  seat("Leather stool",Vector3.new(2.8,0.5,2.7),Vector3.new(0,3.25,0),P.forest)
  part("Stool back",Vector3.new(2.8,1.2,0.5),Vector3.new(0,4.1,1.15),P.forest,Enum.Material.Fabric,true)
 end)
 blueprint("CoffeeTable",function()
  legs(8,4.5,1.6)
  part("Walnut coffee table",Vector3.new(8,0.4,4.5),Vector3.new(0,1.8,0),P.walnut,Enum.Material.Wood,true)
  part("Brass edge",Vector3.new(8.1,0.1,4.6),Vector3.new(0,1.61,0),P.brass,Enum.Material.Metal)
 end)
 blueprint("SideTable",function()
  disc("Stone side table",3,0.3,Vector3.new(0,2.3,0),P.ivory,Enum.Material.Marble,true)
  part("Side table pedestal",Vector3.new(0.4,2.2,0.4),Vector3.new(0,1.1,0),P.brass,Enum.Material.Metal)
  disc("Side table base",2.2,0.2,Vector3.new(0,0.1,0),P.walnut,Enum.Material.Wood)
 end)
 blueprint("CafeTable",function()
  disc("Round cafe top",6.5,0.35,Vector3.new(0,3.1,0),P.ivory,Enum.Material.Marble,true)
  part("Cafe pedestal",Vector3.new(0.5,2.9,0.5),Vector3.new(0,1.45,0),P.brass,Enum.Material.Metal)
  disc("Cafe table foot",3,0.2,Vector3.new(0,0.1,0),P.ink,Enum.Material.Metal)
 end)
 blueprint("Books",function()
  for i,color in ipairs({P.linen,P.forest,P.sage}) do
   local p=part("Coffee table book",Vector3.new(2.1,0.22,1.6),Vector3.new(0,(i-0.5)*0.22,0),color)
   p.CFrame*=CFrame.Angles(0,math.rad(i*9-18),0)
  end
  part("Magazine pages",Vector3.new(1.5,0.08,1.9),Vector3.new(2,0.05,0),P.ivory)
 end)
 blueprint("Vase",function()
  ball("Ceramic vase",Vector3.new(1.1,1.5,1.1),Vector3.new(0,0.75,0),P.linen)
  disc("Vase neck",0.5,0.6,Vector3.new(0,1.6,0),P.linen)
  for _,x in ipairs({-0.35,0.15,0.4}) do
   part("Dried stem",Vector3.new(0.05,1.8,0.05),Vector3.new(x,2.5,0),P.walnut)
   ball("Sage sprig",Vector3.new(0.6,0.8,0.25),Vector3.new(x,3,0),P.sage)
  end
 end)
 blueprint("Candle",function()
  disc("Candle vessel",0.7,0.7,Vector3.new(0,0.35,0),P.linen)
  part("Warm candle tip",Vector3.new(0.12,0.18,0.12),Vector3.new(0,0.8,0),P.warm,Enum.Material.Neon)
 end)
 blueprint("TeaService",function()
  part("Walnut tray",Vector3.new(3,0.1,2),Vector3.new(0,0.08,0),P.walnut,Enum.Material.Wood)
  for _,x in ipairs({-0.75,0.75}) do
   disc("Saucer",1.1,0.1,Vector3.new(x,0.2,0),P.ivory)
   disc("Cup",0.7,0.7,Vector3.new(x,0.55,0),P.ivory)
   disc("Coffee",0.56,0.03,Vector3.new(x,0.91,0),P.walnut)
   part("Cup handle",Vector3.new(0.25,0.4,0.15),Vector3.new(x+0.42,0.55,0),P.ivory)
  end
 end)
 blueprint("TableLamp",function()
  disc("Lamp foot",1.2,0.15,Vector3.new(0,0.08,0),P.brass,Enum.Material.Metal)
  part("Lamp stem",Vector3.new(0.15,1.4,0.15),Vector3.new(0,0.8,0),P.brass,Enum.Material.Metal)
  disc("Linen shade",2,1.4,Vector3.new(0,2,0),P.linen,Enum.Material.Fabric)
  local bulb=part("Soft lamp glow",Vector3.new(1.5,0.08,1.5),Vector3.new(0,1.31,0),P.warm,Enum.Material.Neon)
  light(bulb,14,0.65)
 end)
 blueprint("FloorLamp",function()
  disc("Floor lamp foot",2.2,0.2,Vector3.new(0,0.1,0),P.ink,Enum.Material.Metal)
  part("Floor lamp stem",Vector3.new(0.17,8,0.17),Vector3.new(0,4.2,0),P.brass,Enum.Material.Metal)
  disc("Fabric floor shade",3.3,2.5,Vector3.new(0,8.5,0),P.linen,Enum.Material.Fabric)
  local bulb=part("Floor lamp glow",Vector3.new(2.6,0.1,2.6),Vector3.new(0,7.24,0),P.warm,Enum.Material.Neon)
  light(bulb,20,0.8)
 end)
 blueprint("Pendant",function()
  part("Pendant cord",Vector3.new(0.07,4,0.07),Vector3.new(0,2,0),P.ink)
  disc("Walnut pendant shade",3.6,1.1,Vector3.new(0,-0.4,0),P.walnut,Enum.Material.Wood)
  disc("Brass pendant rim",3.7,0.15,Vector3.new(0,-0.96,0),P.brass,Enum.Material.Metal)
  local diffuser=disc("Warm pendant diffuser",3.25,0.08,Vector3.new(0,-1.05,0),P.warm,Enum.Material.Neon)
  light(diffuser,23,0.75)
 end)
 blueprint("Sconce",function()
  part("Walnut wall plate",Vector3.new(1.5,4,0.25),Vector3.new(0,0,0),P.walnut,Enum.Material.Wood)
  part("Brass mount",Vector3.new(0.3,2,0.8),Vector3.new(0,0,0.45),P.brass,Enum.Material.Metal)
  local diffuser=part("Opal sconce",Vector3.new(0.8,2.8,0.6),Vector3.new(0,0,0.8),P.warm,Enum.Material.Neon)
  light(diffuser,19,0.6)
 end)
 blueprint("Plant",function()
  disc("Stone planter",4,3,Vector3.new(0,1.5,0),P.linen,Enum.Material.Concrete,true)
  disc("Planter brass foot",3.5,0.2,Vector3.new(0,0.1,0),P.brass,Enum.Material.Metal)
  disc("Planter soil",3.5,0.1,Vector3.new(0,3.05,0),P.walnut)
  part("Plant trunk",Vector3.new(0.35,6,0.35),Vector3.new(0,5.3,0),P.walnut,Enum.Material.Wood)
  for i=1,7 do
   local angle=i*math.pi*2/7
   local leaf=ball("Broad sage leaf",Vector3.new(2.6,0.6,5.8),Vector3.new(math.sin(angle)*1.7,7.8+(i%3)*0.6,math.cos(angle)*1.7),i%2==0 and P.sage or P.teal)
   leaf.CFrame*=CFrame.Angles(0,angle,0)*CFrame.Angles(math.rad(-20),0,0)
  end
 end)
 blueprint("Bookshelf",function()
  part("Walnut cabinet back",Vector3.new(10,10,0.5),Vector3.new(0,5,0.8),P.walnut,Enum.Material.Wood,true)
  for _,x in ipairs({-5,5}) do part("Cabinet frame",Vector3.new(0.4,10,2.5),Vector3.new(x,5,0),P.walnut,Enum.Material.Wood,true) end
  for _,y in ipairs({0.4,3.4,6.4,9.8}) do
   part("Display shelf",Vector3.new(10,0.3,2.5),Vector3.new(0,y,0),P.walnut,Enum.Material.Wood,true)
  end
  for row=1,3 do
   for i=1,5 do
    part("Book spine",Vector3.new(0.45,1.6+(i%2)*0.5,1.1),Vector3.new(-4+i*0.65,row*3-1.6,-0.3),({P.ivory,P.sage,P.forest})[(i%3)+1])
   end
   ball("Shelf ceramic",Vector3.new(1.7,1.9,1.3),Vector3.new(2.8,row*3-1.45,-0.1),P.linen)
  end
 end)
 -- Boutique display props are anchored decorations, with no avatar/bot controllers.
 blueprint("DisplayPaddle",function()
  part("Walnut paddle grip",Vector3.new(0.35,1.3,0.35),Vector3.new(0,0.65,0),P.walnut,Enum.Material.Wood)
  ball("Forest paddle face",Vector3.new(2.2,2.7,0.3),Vector3.new(0,2.25,0),P.forest)
  part("Paddle brass stripe",Vector3.new(1.3,0.12,0.06),Vector3.new(0,2.25,0.19),P.brass,Enum.Material.Metal)
 end)
 blueprint("HangingJersey",function()
  part("Display hanger",Vector3.new(2.1,0.1,0.1),Vector3.new(0,0.15,0),P.brass,Enum.Material.Metal)
  part("Hanger hook",Vector3.new(0.1,0.6,0.1),Vector3.new(0,0.45,0),P.brass,Enum.Material.Metal)
  part("Jersey body",Vector3.new(2.5,2.8,0.3),Vector3.new(0,-1.35,0),P.teal,Enum.Material.Fabric)
  for _,x in ipairs({-1.6,1.6}) do
   local sleeve=part("Jersey sleeve",Vector3.new(1,1.35,0.3),Vector3.new(x,-0.6,0),P.teal,Enum.Material.Fabric)
   sleeve.CFrame*=CFrame.Angles(0,0,x>0 and 0.3 or -0.3)
  end
  part("Jersey collar",Vector3.new(0.7,0.2,0.12),Vector3.new(0,-0.03,0.2),P.ivory,Enum.Material.Fabric)
  part("Club crest",Vector3.new(0.35,0.4,0.08),Vector3.new(0.55,-0.7,0.23),P.brass)
 end)
 blueprint("DisplayOutfit",function()
  disc("Mannequin base",3,0.2,Vector3.new(0,0.1,0),P.brass,Enum.Material.Metal)
  for _,x in ipairs({-0.55,0.55}) do
   part("Walnut display shoe",Vector3.new(0.9,0.5,1.35),Vector3.new(x,0.45,-0.2),P.walnut)
   part("Skin display trouser leg",Vector3.new(0.8,2.2,0.8),Vector3.new(x,1.7,0),P.forest,Enum.Material.Fabric)
  end
  part("Skin display jacket",Vector3.new(2.5,2.8,1),Vector3.new(0,4.1,0),P.teal,Enum.Material.Fabric)
  for _,x in ipairs({-1.6,1.6}) do
   local arm=part("Display sleeve",Vector3.new(0.7,2.5,0.8),Vector3.new(x,4.1,0),P.teal,Enum.Material.Fabric)
   arm.CFrame*=CFrame.Angles(0,0,x>0 and 0.12 or -0.12)
   ball("Linen mannequin hand",Vector3.new(0.6,0.6,0.6),Vector3.new(x*1.1,2.7,0),P.linen)
  end
  part("Jacket zip",Vector3.new(0.05,2.3,0.06),Vector3.new(0,4.15,-0.53),P.brass,Enum.Material.Metal)
  part("Mannequin neck",Vector3.new(0.45,0.6,0.45),Vector3.new(0,5.7,0),P.linen)
  ball("Linen mannequin head",Vector3.new(1.3,1.6,1.2),Vector3.new(0,6.6,0),P.linen)
 end)
 blueprint("Trophy",function()
  part("Trophy stone base",Vector3.new(2,0.4,1.6),Vector3.new(0,0.2,0),P.ink,Enum.Material.Marble)
  part("Trophy brass stem",Vector3.new(0.3,1,0.3),Vector3.new(0,0.9,0),P.brass,Enum.Material.Metal)
  ball("Trophy cup",Vector3.new(1.7,1.4,1.7),Vector3.new(0,1.9,0),P.brass,Enum.Material.Metal)
  disc("Trophy rim",1.7,0.12,Vector3.new(0,2.6,0),P.brass,Enum.Material.Metal)
  disc("Cup interior",1.4,0.03,Vector3.new(0,2.67,0),P.walnut)
  for _,x in ipairs({-1.1,1.1}) do
   part("Trophy handle",Vector3.new(0.17,0.8,0.5),Vector3.new(x,2.1,0),P.brass,Enum.Material.Metal)
   for _,y in ipairs({1.7,2.5}) do
    part("Handle return",Vector3.new(0.5,0.13,0.5),Vector3.new(x*0.85,y,0),P.brass,Enum.Material.Metal)
   end
  end
  part("Engraved trophy plate",Vector3.new(1.1,0.18,0.05),Vector3.new(0,0.22,0.83),P.brass,Enum.Material.Metal)
 end)
 local self={}
 function self.place(kind,parent,frame)
  local template=assert(templates[kind],"Unknown furniture: "..kind)
  local model=template:Clone()
  model:PivotTo(frame); model.Parent=parent
  return model
 end
 function self.destroyTemplates()
  for _,template in pairs(templates) do template:Destroy() end
  table.clear(templates)
 end
 return self
end
return Furniture
