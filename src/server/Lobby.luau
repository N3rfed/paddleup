-- Separate versioned environment; menu admission, court, and elevator metadata are unchanged.
local Lobby={}
local Furniture=require(script.Parent:WaitForChild("LobbyFurniture"))
local P=Furniture.Palette
local VERSION=3
local O=Vector3.new(0,181,600)
-- Keep the established arrival point and its view of reception.
Lobby.Spawn=CFrame.lookAt(Vector3.new(0,185,650),Vector3.new(0,185,608))
function Lobby.build()
 local old=workspace:FindFirstChild("PaddleUpLobby")
 if old and old:GetAttribute("Version")==VERSION then return old end
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
  light.Range=range; light.Brightness=brightness; light.Angle=120; light.Shadows=false
 end
 local function rug(parent,x,z,width,depth)
  decor(parent,"Woven rug border",Vector3.new(width,0.05,depth),Vector3.new(x,0.04,z),P.linen,Enum.Material.Fabric)
  decor(parent,"Muted sage rug",Vector3.new(width-0.7,0.05,depth-0.7),Vector3.new(x,0.09,z),Color3.fromRGB(109,126,107),Enum.Material.Fabric)
  for _,dx in ipairs({-width/2+1.4,width/2-1.4}) do
   decor(parent,"Woven rug detail",Vector3.new(0.12,0.02,depth-2.8),Vector3.new(x+dx,0.13,z),P.linen,Enum.Material.Fabric)
  end
 end
 local function art(parent,x,y,z,width,height,style)
  decor(parent,"Walnut picture frame",Vector3.new(width,height,0.3),Vector3.new(x,y,z),P.walnut,Enum.Material.Wood)
  decor(parent,"Ivory art mat",Vector3.new(width-0.4,height-0.4,0.12),Vector3.new(x,y,z+0.21),P.ivory)
  decor(parent,"Sage abstract field",Vector3.new(width*0.58,height*0.52,0.05),Vector3.new(x-width*0.1,y+0.4,z+0.3),P.sage)
  local p=decor(parent,"Abstract forest shape",Vector3.new(width*0.25,height*0.7,0.07),Vector3.new(x+width*0.2,y-0.15,z+0.35),P.teal)
  if style then p.Shape=Enum.PartType.Ball end
  decor(parent,"Brass art line",Vector3.new(width*0.72,0.08,0.09),Vector3.new(x,y-height*0.25,z+0.42),P.brass,Enum.Material.Metal)
 end
 -- +32.4% usable floor area, preserving all original area relationships.
 part(shell,"Penthouse foundation",Vector3.new(182,180,158),Vector3.new(0,-91,12),P.walnut,Enum.Material.Concrete)
 part(shell,"Warm limestone floor",Vector3.new(180,2,156),Vector3.new(0,-1,12),P.ivory,Enum.Material.Concrete)
 part(shell,"Ivory ceiling",Vector3.new(180,1,156),Vector3.new(0,27,12),P.ivory)
 part(shell,"Reception feature wall",Vector3.new(180,26,2),Vector3.new(0,13,-65),P.ivory)
 for _,x in ipairs({-89,89}) do
  local glass=part(shell,"Panoramic window",Vector3.new(0.4,26,154),Vector3.new(x,13,12),Color3.fromRGB(185,198,186),Enum.Material.Glass)
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
   wash(lamp,43,0.7)
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
  sign(bankRoot,bank.name.." header",bank.name,Vector3.new(bank.x,17.5,wallZ+0.6),7,1.4,P.brass,false)
  for index,mode in ipairs({"CLASSIC","ARCADE","CHAOTIC"}) do
   local x=bank.x+(index-2)*14
   local frame=part(bankRoot,bank.name.." "..mode.." elevator",Vector3.new(12,13.5,2),Vector3.new(x,6.75,wallZ+1.5),P.ivory,Enum.Material.Concrete)
   frame:SetAttribute("TeamFormat",bank.name); frame:SetAttribute("Mode",mode); frame:SetAttribute("Placeholder",true)
   for _,dx in ipairs({-2.5,2.5}) do
    part(bankRoot,"Brushed elevator door",Vector3.new(4.85,10.5,0.25),Vector3.new(x+dx,5.65,wallZ+2.65),Color3.fromRGB(155,154,138),Enum.Material.Metal)
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
 furniture.destroyTemplates()
 -- Swap only this generated lobby; saved older geometry is refreshed automatically.
 if old then old:Destroy() end
 root.Parent=workspace
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation") or Instance.new("SpawnLocation")
 spawn.Name="SpawnLocation"; spawn.CFrame=Lobby.Spawn-Vector3.new(0,3.5,0)
 spawn.Size=Vector3.new(5,0.3,5); spawn.Transparency=1; spawn.CanCollide=false
 spawn.Neutral=true; spawn.Duration=0; spawn.Parent=workspace
 return root
end
return Lobby
