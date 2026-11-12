local TweenService=game:GetService("TweenService")
local Geometry={}
local P={
 ivory=Color3.fromRGB(217,216,227),navy=Color3.fromRGB(29,31,57),
 walnut=Color3.fromRGB(82,67,83),brass=Color3.fromRGB(181,179,194),
 cyan=Color3.fromRGB(80,232,255),pink=Color3.fromRGB(255,85,200),
 warm=Color3.fromRGB(255,246,235),steel=Color3.fromRGB(164,164,183),
}
-- Split only the intersecting rectangle; retain each wall's material and collision.
local function cutOpening(wall,origin,width,height,depth)
 local localOrigin=wall.CFrame:PointToObjectSpace(origin.Position)
 if math.abs(localOrigin.Z)>wall.Size.Z/2+depth/2 then return end
 local x0=math.max(-wall.Size.X/2,localOrigin.X-width/2)
 local x1=math.min(wall.Size.X/2,localOrigin.X+width/2)
 local y0=math.max(-wall.Size.Y/2,localOrigin.Y-height/2)
 local y1=math.min(wall.Size.Y/2,localOrigin.Y+height/2)
 if x1<=x0 or y1<=y0 then return end
 local size,cf,parent=wall.Size,wall.CFrame,wall.Parent
 local function segment(x,y,w,h)
  if w<0.01 or h<0.01 then return end
  local p=wall:Clone(); p.Size=Vector3.new(w,h,size.Z)
  p.CFrame=cf*CFrame.new(x,y,0); p.Parent=parent
 end
 segment((-size.X/2+x0)/2,0,x0+size.X/2,size.Y)
 segment((x1+size.X/2)/2,0,size.X/2-x1,size.Y)
 segment((x0+x1)/2,(-size.Y/2+y0)/2,x1-x0,y0+size.Y/2)
 segment((x0+x1)/2,(y1+size.Y/2)/2,x1-x0,size.Y/2-y1)
 wall:Destroy()
end
function Geometry.build(lobby,config)
 local banks=lobby:WaitForChild("Elevator Banks")
 local controllers={}
 local depth=config.CabinDepth
 for _,bank in ipairs(banks:GetChildren()) do
  if not bank:IsA("Model") then continue end
  local frames,doors={},{}
  for _,item in ipairs(bank:GetChildren()) do
   if item:IsA("BasePart") and item:GetAttribute("TeamFormat") then table.insert(frames,item)
   elseif item:IsA("BasePart") and item.Name=="Brushed elevator door" then table.insert(doors,item) end
   if item:IsA("BasePart") and (item.Name:find(" label",1,true) or item.Name=="Door brass seam" or item.Name=="Elevator indicator") then item:Destroy() end
   for _,label in ipairs(item:GetDescendants()) do
    if label:IsA("TextLabel") and item.Name:find("header",1,true) then label.Text=bank.Name=="1V1" and "1v1" or "2v2" end
   end
  end
  table.sort(frames,function(a,b) return a.Position.X<b.Position.X end)
  for index,frame in ipairs(frames) do
   local assigned
   for _,entry in ipairs(config.Elevators) do if entry.bank==bank.Name and entry.index==index then assigned=entry end end
   local pair={}
   for _,door in ipairs(doors) do if math.abs(door.Position.X-frame.Position.X)<5 then table.insert(pair,door) end end
   if not assigned then
    for _,door in ipairs(pair) do door:Destroy() end
    frame.Name="Retained bank stone panel"; frame:SetAttribute("TeamFormat",nil); frame:SetAttribute("Mode",nil)
    continue
   end
   assert(#pair==2,"Elevator "..assigned.id.." requires two original doors")
   table.sort(pair,function(a,b) return a.Position.X<b.Position.X end)
   local original=frame.CFrame
   local doorZ=original:PointToObjectSpace(pair[1].Position).Z
   local centerCF=original*CFrame.new(0,-1.05,doorZ-depth/2)
   -- Recess through the existing decorative and structural wall layers.
   for _,wall in ipairs(lobby:GetDescendants()) do
    if wall:IsA("BasePart") and (wall.Name=="Walnut bank backdrop" or wall.Name=="Reception feature wall" or wall.Name=="Ground floor rear wall") then
     cutOpening(wall,centerCF,10.8,11.4,depth)
    end
   end
   local model=Instance.new("Model"); model.Name="PartyElevator_"..assigned.id; model.Parent=bank
   local function part(name,size,offset,material,color,collide)
    local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=original*CFrame.new(offset)
    p.Anchored=true; p.Material=material or Enum.Material.SmoothPlastic; p.Color=color or P.ivory
    p.CanCollide=collide~=false; p.CanTouch=false; p.CanQuery=p.CanCollide
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=model; return p
   end
   local function surface(p,face,text,color)
    local gui=Instance.new("SurfaceGui"); gui.Face=face; gui.PixelsPerStud=60
    gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.LightInfluence=0.2; gui.Parent=p
    local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
    label.Font=Enum.Font.GothamBold; label.TextScaled=true; label.TextColor3=color or P.ivory
    label.Text=text; label.Parent=gui
    local padding=Instance.new("UIPadding"); padding.PaddingLeft=UDim.new(0,8); padding.PaddingRight=UDim.new(0,8)
    padding.PaddingTop=UDim.new(0,5); padding.PaddingBottom=UDim.new(0,5); padding.Parent=label
    return label
   end
   local back=doorZ-depth
   local mid=doorZ-depth/2
   -- The original stone frame stays at the wall plane rather than projecting into the lobby.
   frame.Parent=model; frame.Name="Original elevator transom"
   frame.Size=Vector3.new(12,2.6,1.2); frame.CFrame=original*CFrame.new(0,5.45,doorZ-0.25)
   frame:SetAttribute("Mode",nil); frame:SetAttribute("Placeholder",nil)
   part("Left jamb",Vector3.new(0.6,10.9,1.2),Vector3.new(-5.7,-1.3,doorZ-0.25),Enum.Material.Concrete)
   part("Right jamb",Vector3.new(0.6,10.9,1.2),Vector3.new(5.7,-1.3,doorZ-0.25),Enum.Material.Concrete)
   for _,side in ipairs({-1,1}) do
    part("Recessed shaft side",Vector3.new(0.5,11.4,depth),Vector3.new(side*5.35,-1.05,mid),Enum.Material.Concrete,P.walnut)
    part("Walnut cabin wall",Vector3.new(0.12,10.6,depth-0.4),Vector3.new(side*5.03,-1.15,mid),Enum.Material.Wood,P.walnut)
    -- Door leaves stack behind these fixed pocket covers, within the twelve-stud frame.
    part("Telescoping door pocket",Vector3.new(2.45,10.8,0.32),Vector3.new(side*4.775,-1.3,doorZ+0.3),Enum.Material.Metal,P.navy)
    part("Brass pocket edge",Vector3.new(0.08,10.65,0.06),Vector3.new(side*3.57,-1.3,doorZ+0.49),Enum.Material.Metal,P.brass,false)
    part("Cabin side handrail",Vector3.new(0.14,0.18,depth-2),Vector3.new(side*4.65,-2.75,mid),Enum.Material.Metal,P.brass,false)
    for _,z in ipairs({back+1.6,doorZ-1.6}) do
     part("Handrail wall bracket",Vector3.new(0.35,0.12,0.14),Vector3.new(side*4.83,-2.75,z),Enum.Material.Metal,P.brass,false)
    end
    for _,y in ipairs({-5.9,2.9}) do
     part("Cabin brass side inlay",Vector3.new(0.035,0.065,depth-0.7),Vector3.new(side*4.95,y,mid),Enum.Material.Metal,P.brass,false)
    end
    part("Cyan ceiling edge",Vector3.new(0.06,0.08,depth-1),Vector3.new(side*4.55,3.95,mid),Enum.Material.Neon,P.cyan,false)
   end
   part("Cabin floor",Vector3.new(10.8,0.25,depth+0.3),Vector3.new(0,-6.625,mid),Enum.Material.Marble,P.ivory)
   part("Cabin navy floor inset",Vector3.new(8.4,0.035,depth-1.25),Vector3.new(0,-6.48,mid),Enum.Material.SmoothPlastic,P.navy,false)
   for _,x in ipairs({-4.25,4.25}) do
    part("Floor champagne border",Vector3.new(0.07,0.045,depth-1.15),Vector3.new(x,-6.46,mid),Enum.Material.Metal,P.brass,false)
   end
   part("Cabin ceiling",Vector3.new(10.8,0.35,depth),Vector3.new(0,4.35,mid),Enum.Material.Metal,P.navy)
   part("Cabin rear",Vector3.new(10.8,11.4,0.5),Vector3.new(0,-1.05,back-0.1),Enum.Material.Concrete,P.walnut)
   part("Walnut rear lining",Vector3.new(10,10.6,0.12),Vector3.new(0,-1.15,back+0.23),Enum.Material.Wood,P.walnut)
   local mirror=part("Smoked metallic mirror",Vector3.new(7.8,5,0.08),Vector3.new(0,0.5,back+0.35),Enum.Material.Glass,P.brass,false)
   mirror.Reflectance=0.4; mirror.Transparency=0.16
   for _,x in ipairs({-4,4}) do
    part("Mirror champagne frame",Vector3.new(0.08,5.2,0.1),Vector3.new(x,0.5,back+0.41),Enum.Material.Metal,P.brass,false)
   end
   local plaque=part("Rooftop club plaque",Vector3.new(6.2,2.2,0.1),Vector3.new(0,0.7,back+0.5),Enum.Material.Metal,P.navy,false)
   surface(plaque,Enum.NormalId.Back,"P A D D L E  U P\nROOFTOP SOCIAL CLUB",P.cyan)
   part("Rear cabin handrail",Vector3.new(9.1,0.18,0.15),Vector3.new(0,-2.75,back+0.65),Enum.Material.Metal,P.brass,false)
   for _,x in ipairs({-3.6,3.6}) do
    part("Rear handrail bracket",Vector3.new(0.12,0.12,0.35),Vector3.new(x,-2.75,back+0.45),Enum.Material.Metal,P.brass,false)
   end
   for _,z in ipairs({back+1.3,doorZ-1.3}) do
    local light=part("Cabin warm diffuser",Vector3.new(7.6,0.1,0.65),Vector3.new(0,4.08,z),Enum.Material.Neon,P.warm,false)
    local lamp=Instance.new("SurfaceLight"); lamp.Face=Enum.NormalId.Bottom; lamp.Angle=120
    lamp.Color=P.warm; lamp.Brightness=0.65; lamp.Range=13; lamp.Shadows=false; lamp.Parent=light
   end
   part("Pink rear accent",Vector3.new(5.8,0.06,0.06),Vector3.new(0,2.25,back+0.57),Enum.Material.Neon,P.pink,false)
   local control=part("Automatic floor control panel",Vector3.new(0.16,3.4,1.3),Vector3.new(4.86,-0.8,doorZ-2),Enum.Material.Metal,P.navy,false)
   -- Decorative controls only: physical buttons, no prompts or input handlers.
   part("Control panel status light",Vector3.new(0.04,0.08,0.75),Vector3.new(4.75,0.45,doorZ-2),Enum.Material.Neon,P.cyan,false)
   for row=1,3 do
    for column=1,2 do
     local z=doorZ-2+(column==1 and -0.28 or 0.28)
     local y=0.5-row*0.6
     local bezel=part("Decorative button bezel",Vector3.new(0.1,0.43,0.43),Vector3.new(4.73,y,z),Enum.Material.Metal,P.brass,false)
     bezel.Shape=Enum.PartType.Cylinder
     local lit=row==3 and column==2
     local button=part("Decorative floor button",Vector3.new(0.12,0.3,0.3),Vector3.new(4.66,y,z),lit and Enum.Material.Neon or Enum.Material.Metal,lit and P.cyan or P.navy,false)
     button.Shape=Enum.PartType.Cylinder
    end
   end
   for _,zOffset in ipairs({-0.28,0.28}) do
    part("Decorative door button",Vector3.new(0.12,0.22,0.36),Vector3.new(4.68,-2,doorZ-2+zOffset),Enum.Material.Metal,P.brass,false)
   end
   local welcome=part("Cabin passenger notice",Vector3.new(3.3,0.75,0.08),Vector3.new(0,-4.4,back+0.36),Enum.Material.Metal,P.navy,false)
   surface(welcome,Enum.NormalId.Back,assigned.capacity.." PLAYERS  /  READY. SET. RALLY.",P.ivory)
   local sign=part("Party capacity sign",Vector3.new(9,1.1,0.15),Vector3.new(0,5.45,doorZ+0.4),Enum.Material.Metal,P.navy,false)
   local label=surface(sign,Enum.NormalId.Back,"",P.ivory)
   local controller={config=assigned,model=model,center=centerCF,doors={},open=false,lastNear=0,label=label,origin=original,doorZ=doorZ}
   controller.exit=centerCF*CFrame.new(0,-2,depth/2+6)
   controller.entry=centerCF*CFrame.new(0,-2,0.6)
   -- Two telescoping leaves per side. Both stack in depth behind the jamb;
   -- no point on any panel leaves the original +/-6 stud frame.
   local panelWidth=pair[1].Size.X/2
   assert(config.DoorStackX+panelWidth/2<=6,"Door stack exceeds the original frame")
   for sideIndex,baseDoor in ipairs(pair) do
    local side=sideIndex==1 and -1 or 1
    for leaf=1,2 do
     local door=leaf==1 and baseDoor or baseDoor:Clone()
     door.Name="Brushed elevator door"; door.Parent=model
     door.Size=Vector3.new(panelWidth,baseDoor.Size.Y,0.18)
     local closedX=side*(leaf==1 and panelWidth*1.5 or panelWidth*0.5)
     local z=doorZ-(leaf-1)*config.DoorPanelDepth
     door.CFrame=original*CFrame.new(closedX,-1.1,z); door.Anchored=true; door.CanCollide=true
     local closed=door.CFrame
     local target=original*CFrame.new(side*config.DoorStackX,-1.1,z)
     table.insert(controller.doors,{part=door,closed=closed,opened=target,closedSize=door.Size})
    end
   end
   function controller:contains(position,approach)
    local v=self.center:PointToObjectSpace(position)
    if approach then v-=Vector3.new(0,0,config.ApproachForward) end
    local size=approach and config.ApproachSize or config.InteriorSize
    return math.abs(v.X)<=size.X/2 and math.abs(v.Y)<=size.Y/2 and math.abs(v.Z)<=size.Z/2
   end
   function controller:setOpen(open)
    if self.open==open then return end
    self.open=open
    for _,d in ipairs(self.doors) do
     if d.tween then d.tween:Cancel() end
     d.tween=TweenService:Create(d.part,TweenInfo.new(config.DoorSeconds,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
      {CFrame=open and d.opened or d.closed})
     d.tween:Play()
    end
   end
   function controller:destroy()
    for _,d in ipairs(self.doors) do if d.tween then d.tween:Cancel() end end
   end
   model:SetAttribute("ElevatorId",assigned.id); model:SetAttribute("Capacity",assigned.capacity); model:SetAttribute("Format",assigned.format)
   model:SetAttribute("RecessedCabin",true); model:SetAttribute("TelescopingDoors",true)
   controllers[assigned.id]=controller
  end
 end
 lobby:SetAttribute("ExpectedDescendants",#lobby:GetDescendants())
 return controllers
end
return Geometry
