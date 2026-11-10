-- Native Roblox geometry: the identical builders power shop viewports, boutique displays and equipment.
-- All decoration is nonphysical. Existing paddle and character parts are never resized or re-welded.
local Catalog=require(script.Parent:WaitForChild("CosmeticCatalog"))
local Assets={}
local V=Vector3.new
local function part(parent,name,size,cf,color,material,anchor)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic; p.Anchored=anchor~=false
 p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=parent
 return p
end
local function model(parent,name) local m=Instance.new("Model"); m.Name=name; m.Parent=parent; return m end
local function attach(parent,target,name,size,offset,color,material)
 local p=part(parent,name,size,target.CFrame*offset,color,material,false)
 local weld=Instance.new("WeldConstraint"); weld.Part0=target; weld.Part1=p; weld.Parent=p
 return p
end
-- Geometry lettering also renders inside ViewportFrames (SurfaceGui text does not).
local function number07(parent,target,offset,width,height,color)
 local segments={a={0,0.42,0.68,0.1},b={0.34,0.21,0.1,0.42},c={0.34,-0.21,0.1,0.42},
  d={0,-0.42,0.68,0.1},e={-0.34,-0.21,0.1,0.42},f={-0.34,0.21,0.1,0.42}}
 for digit,keys in ipairs({{"a","b","c","d","e","f"},{"a","b","c"}}) do
  for _,key in ipairs(keys) do
   local v=segments[key]
   attach(parent,target,"Woven 07",V(width*0.44*v[3],height*v[4],0.014),
    offset*CFrame.new((digit==1 and -0.26 or 0.26)*width+v[1]*width*0.44,v[2]*height,0),color)
  end
 end
end
function Assets.paddle(face,id)
 local old=face:FindFirstChild("ShopPaddleArt"); if old then old:Destroy() end
 if face:GetAttribute("ShopOriginalColor")==nil then
  face:SetAttribute("ShopOriginalColor",face.Color); face:SetAttribute("ShopOriginalMaterial",face.Material.Name)
 end
 face.Color=face:GetAttribute("ShopOriginalColor"); face.Material=Enum.Material[face:GetAttribute("ShopOriginalMaterial")]
 local item=Catalog.ById[id]; if not item or item.category~="Paddles" then return end
 local art=model(face,"ShopPaddleArt"); local c=item.colors; face.Color=c[1]
 face.Material=item.asset=="luxury" and Enum.Material.Metal or Enum.Material.SmoothPlastic
 local function ink(name,x,y,w,h,color,angle,side,material)
  return attach(art,face,name,V(w,h,0.012),CFrame.new(x,y,(side or -1)*0.158)*CFrame.Angles(0,0,math.rad(angle or 0)),color,material)
 end
 for _,side in ipairs({-1,1}) do
  if item.asset=="minimal" then
   ink("Graphite spine",-0.54,0,0.1,1.8,c[2],0,side); ink("Mint signature",0,-0.65,0.65,0.09,c[3],0,side)
  elseif item.asset=="arcade" then
   for _,x in ipairs({-0.72,0.72}) do ink("Neon rail",x,0,0.055,1.86,c[2],0,side,Enum.Material.Neon) end
   for i=-2,2 do ink("Circuit step",i*0.22,i*0.28,0.32,0.075,c[3],0,side) end
   ink("Arcade diamond",0,0,0.5,0.5,c[2],45,side)
  elseif item.asset=="geometric" then
   for x=-1,1 do for y=-2,2 do ink("Coral diamond",x*0.48,y*0.36,0.27,0.27,c[2],45,side) end end
   ink("Golden axis",0,0,0.055,1.9,c[3],0,side)
  elseif item.asset=="sport" then
   for _,x in ipairs({-0.57,-0.37}) do ink("Speed stripe",x,0,0.09,1.9,c[2],0,side) end
   ink("Tour badge",0.25,0.2,0.57,0.7,c[3],0,side)
   number07(art,face,CFrame.new(0.25,0.2,side*0.178),0.43,0.5,c[1])
  elseif item.asset=="playful" then
   for x=-1,1 do for y=-2,2 do
    ink("Confetti tile",x*0.47,y*0.35,0.29,0.19,c[(x+y+9)%3+1],(x+y)*15,side)
   end end
  elseif item.asset=="luxury" then
   for _,x in ipairs({-0.74,0.74}) do ink("Brass frame",x,0,0.035,1.86,c[2],0,side,Enum.Material.Metal) end
   for _,y in ipairs({-0.92,0.92}) do ink("Brass frame",0,y,1.51,0.035,c[2],0,side,Enum.Material.Metal) end
   for i=-2,2 do ink("Deco fan",i*0.16,0.13,0.025,1.25,c[2],i*13,side,Enum.Material.Metal) end
   ink("Reserve seal",0,-0.65,0.25,0.25,c[3],45,side)
  end
 end
end
function Assets.wear(character,id)
 local old=character:FindFirstChild("ShopWearable"); if old then old:Destroy() end
 local item=Catalog.ById[id]; if not item or item.category~="Wearables" then return end
 local art=model(character,"ShopWearable"); local c=item.colors
 local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
 local head=character:FindFirstChild("Head")
 local function piece(target,name,size,offset,color)
  return attach(art,target,name,size,offset,color,Enum.Material.Fabric)
 end
 if (item.asset=="jersey" or item.asset=="sunset") and torso then
  local w,h,d=torso.Size.X,torso.Size.Y,torso.Size.Z
  for _,side in ipairs({-1,1}) do
   local panel=piece(torso,"Technical jersey panel",V(w*1.025,h*0.91,0.06),CFrame.new(0,-h*0.035,side*(d/2+0.04)),c[1])
   for i=1,3 do piece(torso,"Woven chest stripe",V(w*0.87,0.07,0.015),CFrame.new(0,h*(0.27-i*0.1),side*(d/2+0.079)),c[2]) end
   if item.asset=="jersey" then
    number07(art,torso,CFrame.new(0,-h*0.23,side*(d/2+0.097)),w*0.38,h*0.28,c[3])
   else
    for i=-2,2 do
     piece(torso,"Stepped sunset",V(w*0.1,h*(0.13-0.025*math.abs(i)),0.018),CFrame.new(i*w*0.11,-h*0.25,side*(d/2+0.1)),c[2])
    end
   end
  end
  for _,x in ipairs({-1,1}) do piece(torso,"Shoulder piping",V(0.07,h*0.85,d+0.08),CFrame.new(x*(w/2+0.025),0,0),c[3]) end
 elseif (item.asset=="headband" or item.asset=="visor") and head then
  local w,h,d=head.Size.X,head.Size.Y,head.Size.Z
  for _,side in ipairs({-1,1}) do
   piece(head,"Woven headband",V(w+0.09,0.22,0.08),CFrame.new(0,h*0.24,side*(d/2+0.045)),c[1])
   piece(head,"Band side",V(0.08,0.22,d+0.16),CFrame.new(side*(w/2+0.045),h*0.24,0),c[1])
  end
  piece(head,"Signature piping",V(w*0.8,0.045,0.02),CFrame.new(0,h*0.24-0.06,-d/2-0.09),c[2])
  piece(head,"Club mark",V(0.15,0.17,0.025),CFrame.new(0,h*0.24,-d/2-0.105),c[3])
  if item.asset=="visor" then piece(head,"Cyan visor brim",V(w*1.05,0.075,d*0.85),CFrame.new(0,h*0.18,-d*0.76),c[2]) end
 elseif item.asset=="wristbands" then
  for index,names in ipairs({{"LeftHand","Left Arm"},{"RightHand","Right Arm"}}) do
   local limb=character:FindFirstChild(names[1]) or character:FindFirstChild(names[2])
   if limb then
    local w,h,d=limb.Size.X,limb.Size.Y,limb.Size.Z
    local y=names[1]==limb.Name and h*0.25 or -h*0.32
    for _,side in ipairs({-1,1}) do
     piece(limb,"Terry cuff",V(w+0.12,0.3,0.08),CFrame.new(0,y,side*(d/2+0.04)),c[index])
     piece(limb,"Cuff edge",V(0.08,0.3,d+0.16),CFrame.new(side*(w/2+0.04),y,0),c[index])
    end
    piece(limb,"Cuff score stripe",V(w*0.75,0.055,0.02),CFrame.new(0,y,-d/2-0.09),c[3])
   end
  end
 elseif item.asset=="towel" and torso then
  local w,h,d=torso.Size.X,torso.Size.Y,torso.Size.Z
  piece(torso,"Shoulder towel",V(w*0.35,0.09,d+0.16),CFrame.new(-w*0.27,h/2+0.04,0),c[1])
  for _,side in ipairs({-1,1}) do
   piece(torso,"Towel fall",V(w*0.35,h*0.9,0.09),CFrame.new(-w*0.27,h*0.06,side*(d/2+0.08)),c[1])
   piece(torso,"Forest hem",V(w*0.35,0.11,0.025),CFrame.new(-w*0.27,-h*0.34,side*(d/2+0.14)),c[2])
   for i=1,3 do piece(torso,"Woven gold stripe",V(w*0.32,0.04,0.02),CFrame.new(-w*0.27,-h*0.19+i*0.07,side*(d/2+0.14)),c[3]) end
  end
 end
 return art
end
-- Never touch lines, net, ball, lights, collision properties or dimensions.
function Assets.court(root,id)
 local old=root:FindFirstChild("ShopCourtArt"); if old then old:Destroy() end
 local surface=root:FindFirstChild("Playing surface",true)
 local item=Catalog.ById[id]; if not item or item.category~="Courts" then item=nil end
 for _,p in ipairs(root:GetDescendants()) do
  if p:IsA("BasePart") and (p.Name=="Playing surface" or p.Name=="Kitchen" or p.Name=="Court surround") then
   if p:GetAttribute("ShopCourtColor")==nil then p:SetAttribute("ShopCourtColor",p.Color); p:SetAttribute("ShopCourtMaterial",p.Material.Name) end
   p.Color=item and item.colors[p.Name=="Playing surface" and 1 or p.Name=="Kitchen" and 2 or 3] or p:GetAttribute("ShopCourtBaseColor") or p:GetAttribute("ShopCourtColor")
   p.Material=item and Enum.Material.SmoothPlastic or Enum.Material[p:GetAttribute("ShopCourtBaseMaterial") or p:GetAttribute("ShopCourtMaterial")]
  end
 end
 if not item or not surface then return end
 local art=model(root,"ShopCourtArt"); local c=item.colors
 local cf=surface.CFrame*CFrame.new(0,surface.Size.Y/2+0.015,0)
 local function inlay(name,x,z,w,d,color,angle,neon)
  return part(art,name,V(w,0.009,d),cf*CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(angle or 0),0),color,neon and Enum.Material.Neon)
 end
 if item.asset=="multicolor" then
  for _,x in ipairs({-10,10}) do for _,z in ipairs({-27,27}) do
   if x*z>0 then inlay("Lilac service panel",x,z,19.65,25.65,Color3.fromRGB(113,111,151)) end
  end end
 end
 -- Inlays sit beyond both sidelines; no patterns compete with the ball or court markings.
 for _,side in ipairs({-1,1}) do
  if item.asset=="neon" then
   inlay("Circuit perimeter",side*22.5,0,0.15,76,Color3.fromRGB(76,210,221),0,true)
   for z=-30,30,15 do inlay("Circuit node",side*23.4,z,1.5,0.18,Color3.fromRGB(214,111,183),0,true) end
  elseif item.asset=="tropical" then
   for z=-28,28,14 do for i=-2,2 do inlay("Palm frond inlay",side*(23+math.abs(i)*0.15),z+i*0.45,0.13,2.1,c[2],side*(i*19)) end end
  elseif item.asset=="premium" then
   inlay("Brass boundary inlay",side*23,0,0.07,76,Color3.fromRGB(190,159,98))
   for z=-32,32,16 do inlay("Reserve diamond",side*24,z,0.65,0.65,Color3.fromRGB(190,159,98),45) end
  elseif item.asset=="multicolor" then
   for z=-32,32,8 do inlay("Colorblock tile",side*23.4,z,2.6,4,c[(math.floor((z+32)/8)%3)+1]) end
  elseif item.asset=="modern" then
   for z=-32,32,8 do inlay("Studio tick",side*23,z,1.5,0.12,Color3.fromRGB(51,66,76)) end
  else
   inlay("Championship sideline band",side*23,0,0.13,76,Color3.fromRGB(229,225,204))
   for z=-30,30,15 do inlay("Club inset",side*24,z,0.5,1.8,c[1]) end
  end
 end
end
function Assets.preview(id)
 local item=assert(Catalog.ById[id],"Unknown cosmetic")
 local root=model(nil,"Preview_"..id)
 if item.category=="Paddles" then
  local grip=part(root,"PaddleGrip",V(0.3,1.2,0.3),CFrame.new(0,-1.3,0),Color3.fromRGB(35,47,52))
  local face=part(root,"PaddleFace",V(1.65,2,0.3),CFrame.new(0,0.2,0),Color3.fromRGB(31,193,180))
  Assets.paddle(face,id); grip.Anchored=true
 elseif item.category=="Wearables" then
  local skin=Color3.fromRGB(201,169,141); local base=Color3.fromRGB(58,72,78)
  for _,spec in ipairs({{"Head",V(1.3,1.1,1),V(0,2.05,0),skin},{"UpperTorso",V(2,1.6,1),V(0,0.6,0),base},
   {"LowerTorso",V(1.6,0.5,0.9),V(0,-0.4,0),base},{"LeftHand",V(0.65,0.75,0.8),V(-1.4,-0.3,0),skin},
   {"RightHand",V(0.65,0.75,0.8),V(1.4,-0.3,0),skin},{"Left Arm",V(0.7,1.3,0.8),V(-1.4,0.7,0),base},
   {"Right Arm",V(0.7,1.3,0.8),V(1.4,0.7,0),base},{"Left Leg",V(0.75,1.7,0.85),V(-0.45,-1.45,0),base},
   {"Right Leg",V(0.75,1.7,0.85),V(0.45,-1.45,0),base}}) do part(root,spec[1],spec[2],CFrame.new(spec[3]),spec[4]) end
  Assets.wear(root,id)
 else
  part(root,"Playing surface",V(40,0.16,80),CFrame.new(),Color3.fromRGB(43,123,134))
  part(root,"Court surround",V(52,0.12,96),CFrame.new(0,-0.1,0),Color3.fromRGB(136,128,163))
  for _,z in ipairs({-7,7}) do part(root,"Kitchen",V(40,0.02,14),CFrame.new(0,0.095,z),Color3.fromRGB(55,143,147)) end
  local white=Color3.fromRGB(246,244,220)
  for _,x in ipairs({-20,20}) do part(root,"Sideline",V(0.18,0.025,80.2),CFrame.new(x,0.13,0),white) end
  for _,z in ipairs({-40,-14,14,40}) do part(root,"Court line",V(40,0.025,0.18),CFrame.new(0,0.13,z),white) end
  for _,z in ipairs({-27,27}) do part(root,"Service center line",V(0.18,0.025,26),CFrame.new(0,0.13,z),white) end
  part(root,"Net",V(42,3.1,0.18),CFrame.new(0,1.7,0),Color3.fromRGB(43,54,61)).Transparency=0.5
  part(root,"Net tape",V(42,0.15,0.22),CFrame.new(0,3.3,0),white)
  Assets.court(root,id)
 end
 for _,p in ipairs(root:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true end end
 return root
end
return Assets
