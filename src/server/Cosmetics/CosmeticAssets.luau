-- Native Roblox geometry: the identical builders power shop viewports, boutique displays and equipment.
-- All decoration is nonphysical. Existing paddle and character parts are never resized or re-welded.
local Catalog=require(script.Parent:WaitForChild("CosmeticCatalog"))
local Textures=require(script.Parent:WaitForChild("CosmeticTextures"))
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
 for _,child in ipairs(face:GetChildren()) do if child.Name=="ShopPrintFront" or child.Name=="ShopPrintBack" then child:Destroy() end end
 if face:GetAttribute("ShopOriginalColor")==nil then
  face:SetAttribute("ShopOriginalColor",face.Color); face:SetAttribute("ShopOriginalMaterial",face.Material.Name)
 end
 face.Color=face:GetAttribute("ShopOriginalColor"); face.Material=Enum.Material[face:GetAttribute("ShopOriginalMaterial")]
 local item=Catalog.ById[id]; if not item or item.category~="Paddles" then return end
 local texture=Textures[item.asset]; assert(texture,"Missing paddle print")
 local art=model(face,"ShopPaddleArt"); face.Color=item.colors[1]; face.Material=Enum.Material.SmoothPlastic
 -- One decal on each real face: no coplanar art pieces or arbitrary hardcoded Z offsets.
 for _,side in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
  local decal=Instance.new("Decal"); decal.Name=side==Enum.NormalId.Front and "ShopPrintFront" or "ShopPrintBack"
  decal.Face=side; decal.Texture=texture; decal.Parent=face
 end
 local size=face.Size
 for _,side in ipairs({-1,1}) do
  attach(art,face,"Carbon side edge",V(0.035,size.Y,math.max(0.05,size.Z-0.035)),CFrame.new(side*(size.X/2+0.018),0,0),item.colors[2])
  attach(art,face,"Carbon end edge",V(size.X+0.07,0.035,math.max(0.05,size.Z-0.035)),CFrame.new(0,side*(size.Y/2+0.018),0),item.colors[2])
 end
 art:SetAttribute("PrintDesign",item.asset)
end
local function legacyWear(character,id)
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
local function restoreClothing(character)
 local previous=character:FindFirstChild("ShopWearable")
 if previous then
  local stored=previous:FindFirstChild("OriginalClothing")
  if stored then for _,item in ipairs(stored:GetChildren()) do item.Parent=character end end
 end
 for _,p in ipairs(character:GetDescendants()) do
  if p:IsA("BasePart") and p:GetAttribute("ShopWearOriginalColor") then
   p.Color=p:GetAttribute("ShopWearOriginalColor"); p:SetAttribute("ShopWearOriginalColor",nil)
  end
  if (p:IsA("BasePart") or p:IsA("Decal")) and p:GetAttribute("ShopHiddenTransparency")~=nil then
   p.Transparency=p:GetAttribute("ShopHiddenTransparency"); p:SetAttribute("ShopHiddenTransparency",nil)
  end
 end
 if previous then previous:Destroy() end
end
local function headband(art,head,colors)
 if not head then return end
 local w,h,d=head.Size.X,head.Size.Y,head.Size.Z
 local radiusX,radiusZ=w*0.52+0.035,d*0.52+0.035
 for i=1,40 do
  local a,b=(i-1)*math.pi*2/40,i*math.pi*2/40
  local p1=V(math.cos(a)*radiusX,h*0.25,math.sin(a)*radiusZ)
  local p2=V(math.cos(b)*radiusX,h*0.25,math.sin(b)*radiusZ)
  local middle=(p1+p2)/2
  local offset=CFrame.lookAt(middle,p2)
  attach(art,head,"Fitted woven headband",V(0.045,0.19,(p2-p1).Magnitude+0.003),offset,colors[1],Enum.Material.Fabric)
  attach(art,head,"Headband contrast piping",V(0.056,0.028,(p2-p1).Magnitude+0.003),CFrame.new(0,-0.064,0)*offset,colors[3],Enum.Material.Fabric)
 end
 attach(art,head,"Embroidered club tab",V(w*0.13,0.1,0.018),CFrame.new(0,h*0.25,-radiusZ-0.033),colors[3],Enum.Material.Fabric)
end
function Assets.wear(character,id)
 restoreClothing(character)
 local item=Catalog.ById[id]
 if not item or item.category~="Wearables" then return end
 if item.asset~="outfit" and item.asset~="headband" then return legacyWear(character,id) end
 local art=model(character,"ShopWearable"); local c=item.colors
 local head=character:FindFirstChild("Head")
 if item.asset=="headband" then headband(art,head,c); return art end
 local stored=Instance.new("Folder"); stored.Name="OriginalClothing"; stored.Parent=art
 local bodyNames={UpperTorso=true,LowerTorso=true,Torso=true,LeftUpperArm=true,RightUpperArm=true,
  LeftLowerArm=true,RightLowerArm=true,LeftHand=true,RightHand=true,LeftUpperLeg=true,RightUpperLeg=true,
  LeftLowerLeg=true,RightLowerLeg=true,LeftFoot=true,RightFoot=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true}
 local clothingTypes={TShirt=true,Shirt=true,Pants=true,Jacket=true,Sweater=true,Shorts=true,DressSkirt=true,LeftShoe=true,RightShoe=true}
 for _,child in ipairs(character:GetChildren()) do
  if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic")
   or (child:IsA("Accessory") and clothingTypes[child.AccessoryType.Name]) then
   for _,p in ipairs(child:GetDescendants()) do
    if p:IsA("BasePart") or p:IsA("Decal") then p:SetAttribute("ShopHiddenTransparency",p.Transparency); p.Transparency=1 end
   end
   child.Parent=stored
  elseif child:IsA("BasePart") and bodyNames[child.Name] then
   child:SetAttribute("ShopWearOriginalColor",child.Color)
   child.Color=head and head.Color or Color3.fromRGB(214,177,145)
  end
 end
 local function shell(target,name,color,scale,offset)
  if not target then return end
  local saved=target.Archivable; target.Archivable=true; local copy=target:Clone(); target.Archivable=saved
  for _,child in ipairs(copy:GetChildren()) do
   if child:IsA("DataModelMesh") then
    if child:IsA("SpecialMesh") then child.TextureId="" end
   else child:Destroy() end
  end
  if copy:IsA("MeshPart") then copy.TextureID="" end
  copy:SetAttribute("ShopWearOriginalColor",nil)
  copy.Name=name; copy.Size=target.Size*(scale or V(1.025,1.025,1.025))
  copy.CFrame=target.CFrame*(offset or CFrame.identity); copy.Color=color; copy.Material=Enum.Material.Fabric
  copy.Anchored=false; copy.CanCollide=false; copy.CanTouch=false; copy.CanQuery=false; copy.Massless=true; copy.CastShadow=false
  copy.Parent=art
  local weld=Instance.new("WeldConstraint"); weld.Part0=target; weld.Part1=copy; weld.Parent=copy
  return copy
 end
 local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
 local hips=character:FindFirstChild("LowerTorso")
 shell(torso,"Fitted court top",c[1]); shell(hips,"Tailored waist",c[1])
 local female=item.fit=="Female"
 if not female then
  for _,side in ipairs({"Left","Right"}) do
   local arm=character:FindFirstChild(side.."UpperArm")
   if arm then shell(arm,"Polo short sleeve",c[1])
   else
    arm=character:FindFirstChild(side.." Arm")
    if arm then shell(arm,"Polo short sleeve",c[1],V(1.025,0.45,1.025),CFrame.new(0,arm.Size.Y*0.275,0)) end
   end
  end
 end
 for _,side in ipairs({"Left","Right"}) do
  local leg=character:FindFirstChild(side.."UpperLeg") or character:FindFirstChild(side.." Leg")
  if leg then
   local length=female and 0.52 or 0.72
   shell(leg,"Tailored court shorts",c[2],V(1.025,length,1.025),CFrame.new(0,leg.Size.Y*(1-length)/2,0))
  end
  local shin=character:FindFirstChild(side.."LowerLeg")
  if shin then shell(shin,"White court sock",Color3.fromRGB(244,241,231),V(1.03,0.38,1.03),CFrame.new(0,-shin.Size.Y*0.31,0)) end
  local foot=character:FindFirstChild(side.."Foot")
  if foot then
   shell(foot,"Clean court sneaker",Color3.fromRGB(242,239,229),V(1.06,1.08,1.06))
   attach(art,foot,"Sneaker heel accent",V(foot.Size.X*0.7,0.065,0.025),CFrame.new(0,foot.Size.Y*0.2,foot.Size.Z/2+0.045),c[3])
  end
 end
 if female and (hips or torso) then
  local target=hips or torso; local w,h,d=target.Size.X,target.Size.Y,target.Size.Z
  local y=-h/2-0.24
  for _,side in ipairs({-1,1}) do
   attach(art,target,"Court skort front",V(w*1.13,0.7,0.09),CFrame.new(0,y,side*(d/2+0.075))*CFrame.Angles(math.rad(-side*10),0,0),c[2],Enum.Material.Fabric)
   attach(art,target,"Court skort side",V(0.09,0.7,d*1.15),CFrame.new(side*(w/2+0.045),y,0)*CFrame.Angles(0,0,math.rad(side*10)),c[2],Enum.Material.Fabric)
  end
 end
 if torso then
  local w,h,d=torso.Size.X,torso.Size.Y,torso.Size.Z
  local front=-d/2-0.065
  attach(art,torso,"Embroidered chest mark",V(w*0.17,h*0.06,0.015),CFrame.new(-w*0.24,h*0.22,front),c[3],Enum.Material.Fabric)
  attach(art,torso,"Club accent stitch",V(w*0.035,h*0.13,0.015),CFrame.new(-w*0.15,h*0.15,front),c[3],Enum.Material.Fabric)
  if not female then
   for _,side in ipairs({-1,1}) do
    attach(art,torso,"Polo collar detail",V(w*0.13,h*0.12,0.025),CFrame.new(side*w*0.1,h*0.34,front)*CFrame.Angles(0,0,math.rad(side*20)),c[3],Enum.Material.Fabric)
   end
  end
 end
 headband(art,head,c)
 art:SetAttribute("Fit",item.fit); art:SetAttribute("Theme",item.theme)
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
function Assets.preview(id,fit)
 local item=assert(Catalog.ById[id],"Unknown cosmetic")
 local root=model(nil,"Preview_"..id)
 if item.category=="Paddles" then
  local grip=part(root,"PaddleGrip",V(1.2,0.3,0.3),CFrame.new(0,-1.3,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(35,39,47))
  grip.Shape=Enum.PartType.Cylinder
  for i=1,7 do
   local ring=part(root,"Grip wrap",V(0.027,0.31,0.31),CFrame.new(0,-1.83+i*0.145,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(63,67,73))
   ring.Shape=Enum.PartType.Cylinder
  end
  local face=part(root,"PaddleFace",V(1.65,2,0.3),CFrame.new(0,0.2,0),Color3.fromRGB(31,193,180))
  Assets.paddle(face,id); grip.Anchored=true
 elseif item.category=="Wearables" then
  local folder=game:GetService("ReplicatedStorage"):FindFirstChild("ShopMannequins")
  if not folder and game:GetService("RunService"):IsServer() then
   folder=require(game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Cosmetics"):WaitForChild("ShopMannequins")).prepare()
  end
  folder=folder or game:GetService("ReplicatedStorage"):WaitForChild("ShopMannequins",20)
  local template=folder and folder:FindFirstChild(item.fit or fit or "Male")
  assert(template,"Standard shop mannequin unavailable")
  root:Destroy(); root=template:Clone(); root.Name="Preview_"..id
  if item.asset~="outfit" then
   for _,p in ipairs(root:GetChildren()) do
    if p:IsA("BasePart") then
     if p.Name=="UpperTorso" or p.Name=="LowerTorso" then p.Color=Color3.fromRGB(244,241,231)
     elseif p.Name:find("UpperLeg") then p.Color=Color3.fromRGB(42,48,58) end
    end
   end
  end
  Assets.wear(root,id)
  if item.asset=="headband" then
   -- Headband cards are headshots; hide the unused body instead of showing
   -- an untextured torso/neck below the product.
   for _,p in ipairs(root:GetChildren()) do
    if p:IsA("BasePart") and p.Name~="Head" then p.Transparency=1 end
   end
  end
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
