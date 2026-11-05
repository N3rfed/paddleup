-- Server-timed VS slate using the uploaded assets/figma/vs_screen artwork.
local MatchIntro={}
local Assets=require(script.Parent:WaitForChild("FigmaAssets"))
local navy=Color3.fromRGB(16,19,46)
local white=Color3.fromRGB(246,246,255)
function MatchIntro.countdown(remaining)
 return remaining>0 and remaining<=3 and math.ceil(remaining) or nil
end
function MatchIntro.roundLabel(data)
 local round=data.round or 1
 return data.totalRounds and string.format("ROUND %d / %d",round,data.totalRounds) or "ROUND "..round
end
function MatchIntro.viewTeams(data,userId)
 local localHome=false
 for _,member in ipairs(data.home) do if member.userId==userId then localHome=true end end
 local left=localHome and data.away or data.home
 local right=table.clone(localHome and data.home or data.away)
 for index,member in ipairs(right) do
  if member.userId==userId then table.remove(right,index); table.insert(right,1,member); break end
 end
 return left,right
end
local function staticClone(source)
 local archivable=source.Archivable; source.Archivable=true
 local ok,clone=pcall(function() return source:Clone() end)
 source.Archivable=archivable
 if not ok or not clone then return nil end
 for _,item in ipairs(clone:GetDescendants()) do
  if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("BillboardGui") then item:Destroy()
  elseif item:IsA("BasePart") then item.Anchored=true; item.CanCollide=false; item.LocalTransparencyModifier=0 end
 end
 if clone:IsA("BasePart") then clone.Anchored=true; clone.CanCollide=false end
 return clone
end
function MatchIntro.copyCourt(parent,court)
 local scenery=Instance.new("Model"); scenery.Name="Court scenery"
 if court then
  for index,item in ipairs(court:GetChildren()) do
   if item.Name~="Practice Partner" and item.Name~="PowerupPickups" then
    local clone=staticClone(item)
    if clone then clone.Parent=scenery end
   end
   if index%50==0 then task.wait() end
  end
 end
 if parent.Parent then scenery.Parent=parent else scenery:Destroy() end
 return scenery
end
local function viewport(parent,name,position,size)
 local frame=Instance.new("ViewportFrame",parent)
 frame.Name=name; frame.Position=position; frame.Size=size; frame.BackgroundTransparency=1
 frame.Ambient=Color3.fromRGB(190,197,215); frame.LightColor=Color3.fromRGB(255,247,235)
 frame.LightDirection=Vector3.new(-0.4,-0.6,-1); frame.ZIndex=3
 local world=Instance.new("WorldModel",frame)
 local camera=Instance.new("Camera",frame); camera.FieldOfView=35; frame.CurrentCamera=camera
 return {viewport=frame,world=world,camera=camera,loaded={}}
end
function MatchIntro.groundActor(model,floorY)
 local lowest
 for _,part in ipairs(model:GetDescendants()) do
  local name=string.lower(part.Name)
  if part:IsA("BasePart") and (name=="leftfoot" or name=="rightfoot" or name=="left leg" or name=="right leg") then
   local frame,size=part.CFrame,part.Size
   local halfY=(math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z)/2
   local bottom=part.Position.Y-halfY
   lowest=lowest and math.min(lowest,bottom) or bottom
  end
 end
 if not lowest then local bounds,size=model:GetBoundingBox(); lowest=bounds.Position.Y-size.Y/2 end
 model:PivotTo(model:GetPivot()+Vector3.new(0,floorY-lowest,0))
end
-- Presentation-only fallback while the server paddle is still replicating.
function MatchIntro.ensurePaddle(model)
 local face=model:FindFirstChild("PaddleFace")
 if face then
  face.Transparency=0
  local grip=model:FindFirstChild("PaddleGrip"); if grip then grip.Transparency=0 end
  return face
 end
 local hand=model:FindFirstChild("RightHand") or model:FindFirstChild("Right Arm")
 if not hand or not hand:IsA("BasePart") then return nil end
 local function part(name,size,offset,color)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=hand.CFrame*offset
  p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true
  p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=model
  return p
 end
 part("PaddleGrip",Vector3.new(0.3,1.2,0.3),CFrame.new(0,-0.7,0),Color3.fromRGB(35,47,52))
 face=part("PaddleFace",Vector3.new(1.65,2,0.3),CFrame.new(0,-2,0),Color3.fromRGB(31,193,180))
 face:SetAttribute("Paddle",true)
 return face
end
-- Pose only the presentation clones; live players keep their gameplay controls.
function MatchIntro.prepareActor(model,phase)
 local pivot=model:GetPivot()
 local head=model:FindFirstChild("Head")
 local hand=model:FindFirstChild("RightUpperArm") or model:FindFirstChild("Right Arm") or model:FindFirstChild("Paddle")
 local headParts,armParts={},{}
 if head then headParts[head]=true end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and (part.Name:match("^Right.*Arm$") or part.Name=="RightHand"
   or part.Name=="Right Arm" or part.Name=="PaddleFace" or part.Name=="PaddleGrip" or part.Name=="Paddle") then armParts[part]=true end
 end
 -- Include welded hair, hats and arm accessories in the same movement.
 for _=1,3 do
  for _,joint in ipairs(model:GetDescendants()) do
   if joint:IsA("Weld") or joint:IsA("WeldConstraint") then
    for _,group in ipairs({headParts,armParts}) do
     if group[joint.Part0] and joint.Part1 then group[joint.Part1]=true
     elseif group[joint.Part1] and joint.Part0 then group[joint.Part0]=true end
    end
   end
  end
 end
 local actor={model=model,pivot=pivot,phase=phase or 0,parts={},headParts=headParts,armParts=armParts}
 actor.neck=head and pivot:ToObjectSpace(head.CFrame*CFrame.new(0,-head.Size.Y/2,0)) or CFrame.identity
 actor.shoulder=hand and pivot:ToObjectSpace(hand.CFrame*CFrame.new(0,hand.Size.Y/2,0)) or CFrame.identity
 for _,joint in ipairs(model:GetDescendants()) do
  if joint:IsA("Motor6D") and joint.Part1 and armParts[joint.Part1] and joint.Part0 and not armParts[joint.Part0] then
   actor.shoulder=pivot:ToObjectSpace(joint.Part0.CFrame*joint.C0); break
  end
 end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then actor.parts[part]=pivot:ToObjectSpace(part.CFrame) end
 end
 return actor
end
function MatchIntro.animateScenes(scene,elapsed)
 if not scene or not scene.root.Parent then return end
 for _,shot in ipairs(scene.portraits) do
  for _,actor in pairs(shot.actors or {}) do
   local t=elapsed+actor.phase
   local body=actor.pivot*CFrame.new(0,math.sin(t*2.3)*0.025,0)
    *CFrame.Angles(0,math.sin(t*1.6)*math.rad(5),math.sin(t*1.8)*math.rad(0.7))
   local glance=math.sin(t*2.2)*math.rad(21)
   local head=actor.neck*CFrame.Angles(math.sin(t*1.7)*math.rad(3),glance,0)*actor.neck:Inverse()
   local arm=actor.shoulder*CFrame.Angles(math.sin(t*2)*math.rad(5),0,math.sin(t*1.6)*math.rad(3))*actor.shoulder:Inverse()
   for part,rest in pairs(actor.parts) do
    if part.Parent then part.CFrame=body*(actor.headParts[part] and head or actor.armParts[part] and arm or CFrame.identity)*rest end
   end
  end
  if shot.baseCamera then
   shot.camera.CFrame=shot.baseCamera*CFrame.new(math.sin(elapsed*0.8)*0.05,math.sin(elapsed)*0.025,0.65*math.exp(-elapsed*1.5))
  end
 end
 local badge=scene.root.Canvas:FindFirstChild("VersusBadge")
 if badge then badge.UIScale.Scale=1+math.sin(elapsed*2.8)*0.018 end
end
function MatchIntro.updateScenes(scene)
 if not scene or not scene.root.Parent or os.clock()<scene.nextCheck then return end
 scene.nextCheck=os.clock()+0.1
 local court=workspace:FindFirstChild("PaddleUp")
 local floor=court and court:FindFirstChild("Playing surface")
 for _,shot in ipairs(scene.portraits) do
  if floor and not shot.sceneryStarted then
   shot.sceneryStarted=true
   task.spawn(function() MatchIntro.copyCourt(shot.scenery.world,court) end)
  end
  if not floor then continue end
  local origin=floor.CFrame:PointToWorldSpace(Vector3.new(0,floor.Size.Y/2,18))
  local forward=floor.CFrame:VectorToWorldSpace(Vector3.new(0,0,1))
  for index,member in ipairs(shot.team) do
   if not shot.loaded[index] then
    local source
    if member.bot then source=court and court:FindFirstChild("Practice Partner")
    else
     local p=game:GetService("Players"):GetPlayerByUserId(member.userId)
     source=p and p.Character
    end
    if source and source:IsA("Model") and source:FindFirstChildWhichIsA("BasePart",true) then
     local model=staticClone(source)
     if model then
      if member.bot then
       for _,piece in ipairs(model:GetDescendants()) do if piece:IsA("BasePart") then piece.Transparency=0 end end
      else MatchIntro.ensurePaddle(model) end
      local x=(index-(#shot.team+1)/2)*4.5
      local spot=origin+floor.CFrame.RightVector*x+Vector3.new(0,3,0)
      model:PivotTo(CFrame.lookAt(spot,spot+forward))
      MatchIntro.groundActor(model,origin.Y)
      model.Parent=shot.world; shot.loaded[index]=model
      shot.actors=shot.actors or {}; shot.actors[index]=MatchIntro.prepareActor(model,shot.phase+index*0.6)
      shot.bounds=shot.bounds or {}; local center,extent=model:GetBoundingBox(); shot.bounds[index]={center=center,size=extent}
     end
    end
   end
  end
  local low,high
  for _,extent in pairs(shot.bounds or {}) do
   local bounds,size=extent.center,extent.size
   local a,b=bounds.Position-size/2,bounds.Position+size/2
   low=low and low:Min(a) or a; high=high and high:Max(b) or b
  end
  if low then
   local center=(low+high)/2; local size=high-low
   local width,height=shot.viewport.AbsoluteSize.X,math.max(1,shot.viewport.AbsoluteSize.Y)
   if width<1 or shot.viewport.AbsoluteSize.Y<1 then continue end
   local aspect=math.max(0.2,width/height)
   local scale=math.min(width/1920,height/1080)
   local heightFraction=570*scale/height
   local widthFraction=(#shot.team>1 and 720 or 610)*scale/math.max(1,width)
   local tangent=math.tan(math.rad(17.5))
   local distance=math.max(size.Y/(2*tangent*heightFraction),size.X/(2*tangent*aspect*widthFraction))*1.04
   local xFraction=((width-1920*scale)/2+shot.targetX*scale)/math.max(1,width)
   local yFraction=((height-1080*scale)/2+530*scale)/height
   local yaw=math.atan((0.5-xFraction)*2*tangent*aspect)
   local pitch=math.atan((0.5-yFraction)*2*tangent)
   shot.baseCamera=CFrame.lookAt(center+forward*distance,center)*CFrame.Angles(-pitch,-yaw,0)
   shot.camera.CFrame=shot.baseCamera
  end
 end
end
local function label(parent,name,value,x,y,width,height,size,weight)
 local item=Instance.new("TextLabel")
 item.Name=name; item.BackgroundTransparency=1
 item.Position=UDim2.fromOffset(x,y); item.Size=UDim2.fromOffset(width,height)
 item.Text=value; item.TextColor3=white; item.TextSize=size; item.TextScaled=false; item.TextWrapped=false
 item.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,weight or Enum.FontWeight.Heavy)
 item.ZIndex=4; item.Parent=parent
 return item
end
local function image(parent,key,x,y,width,height)
 local item=Assets.image(parent,key,x,y,width,height)
 item.ScaleType=Enum.ScaleType.Fit; item.ZIndex=3
 return item
end
function MatchIntro.createScreen(parent,data,userId)
 local root=Instance.new("Frame")
 root.Name="TeamReveal"; root.Size=UDim2.fromScale(1,1); root.BackgroundColor3=navy
 root.BorderSizePixel=0; root.Active=true; root.ClipsDescendants=true; root.Parent=parent
 local left,right=MatchIntro.viewTeams(data,userId)
 local sky=Instance.new("Frame",root)
 sky.Name="CourtBackground";sky.Size=UDim2.fromScale(1,1);sky.BorderSizePixel=0;sky.BackgroundColor3=Color3.new(1,1,1)
 local colors=Instance.new("UIGradient",sky);colors.Rotation=90
 colors.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(7,13,31)),
  ColorSequenceKeypoint.new(0.35,Color3.fromRGB(21,31,58)),ColorSequenceKeypoint.new(0.6,Color3.fromRGB(42,49,77)),
  ColorSequenceKeypoint.new(1,Color3.fromRGB(18,30,52))})
 local sun=Instance.new("Frame",sky);sun.Name="DistantMoon";sun.AnchorPoint=Vector2.new(0.5,0.5)
 sun.Position=UDim2.fromScale(0.65,0.23);sun.Size=UDim2.fromOffset(56,56);sun.BackgroundColor3=Color3.fromRGB(170,195,224)
 sun.BackgroundTransparency=0.22;sun.BorderSizePixel=0;Instance.new("UICorner",sun).CornerRadius=UDim.new(1,0)
 local moon=(data.environmentTitle or ""):find("LUNAR",1,true)
 if moon then sky.BackgroundColor3=Color3.fromRGB(3,6,15);colors.Enabled=false;sun.Visible=false end
 if not moon then
  local random=Random.new(73)
  for index=1,24 do
   local star=Instance.new("Frame",sky); star.Name="Star"..index
   star.Position=UDim2.fromScale(random:NextNumber(0.03,0.97),random:NextNumber(0.03,0.3))
   local size=index%7==0 and 2 or 1
   star.Size=UDim2.fromOffset(size,size); star.BorderSizePixel=0
   star.BackgroundColor3=Color3.fromRGB(200,219,242); star.BackgroundTransparency=random:NextNumber(0.35,0.7)
  end
 end
 local scene={root=root,portraits={},nextCheck=0,startedAt=os.clock()}
 for index,team in ipairs({left,right}) do
  local shot=viewport(root,"CharacterPortrait"..index,UDim2.fromScale(0,0),UDim2.fromScale(1,1))
  shot.team=team;shot.targetX=index==1 and 390 or 1530;shot.viewport.ZIndex=3;shot.phase=(index-1)*1.9
  local background=viewport(root,"CourtScenery"..index,UDim2.fromScale(0,0),UDim2.fromScale(1,1))
  background.viewport.ZIndex=1
  background.viewport.Ambient=Color3.fromRGB(65,79,108)
  background.viewport.LightColor=Color3.fromRGB(124,148,184)
  background.camera:Destroy(); background.camera=shot.camera
  background.viewport.CurrentCamera=shot.camera; shot.scenery=background
  local mask=Instance.new("UIGradient",shot.viewport);mask.Name="DiagonalMask";mask.Rotation=15
  local transparency=index==1 and 0 or 1
  mask.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,transparency),NumberSequenceKeypoint.new(0.499,transparency),
   NumberSequenceKeypoint.new(0.501,1-transparency),NumberSequenceKeypoint.new(1,1-transparency)})
  mask:Clone().Parent=background.viewport
  table.insert(scene.portraits,shot)
 end
 local tint=Instance.new("Frame",root); tint.Name="CourtTint"; tint.Size=UDim2.fromScale(1,1)
 tint.BackgroundColor3=Color3.fromRGB(8,16,32); tint.BackgroundTransparency=0.72; tint.BorderSizePixel=0; tint.ZIndex=2
 local blocker=Instance.new("TextButton",root)
 blocker.Name="InputCover"; blocker.Size=UDim2.fromScale(1,1); blocker.BackgroundTransparency=1
 blocker.Text=""; blocker.Modal=true; blocker.Selectable=false; blocker.AutoButtonColor=false; blocker.ZIndex=4
 local canvas=Instance.new("Frame",root)
 canvas.Name="Canvas"; canvas.Size=UDim2.fromOffset(1920,1080)
 canvas.Position=UDim2.fromScale(0.5,0.5); canvas.AnchorPoint=Vector2.new(0.5,0.5)
 canvas.BackgroundTransparency=1; canvas.ZIndex=5
 local scale=Instance.new("UIScale",canvas)
 image(canvas,"vsSplit",750,15,381,1075).Name="DiagonalSplit"
 image(canvas,"vsClub",655,35,610,205)
 local court=workspace:FindFirstChild("PaddleUp")
 local title=data.environmentTitle or (court and court:GetAttribute("EnvironmentTitle")) or "SKYLINE CLUB"
 if title~="SKYLINE CLUB" then
  canvas.Figma_vsClub.Visible=false
  label(canvas,"EnvironmentTitle",title,655,35,610,34,26)
 end
 label(canvas,"MatchFormat",#data.home.."V"..#data.away,760,71,400,136,100)
 local variant=data.variant or "Classic"
 local mode=variant=="Classic" and "NORMAL MODE" or string.upper(variant).." MODE"
 label(canvas,"Mode",(mode:gsub("([^ ])","%1 "):gsub(" $","")),655,207,610,31,24,Enum.FontWeight.Bold)
 image(canvas,"vsHomeFrame",269,62,362,98)
 image(canvas,"vsAwayFrame",1289,62,362,98)
 label(canvas,"HomeHeading",#left>1 and "TEAM 1" or "PLAYER 1",285,78,330,66,32)
 label(canvas,"AwayHeading",#right>1 and "TEAM 2" or "PLAYER 2",1305,78,330,66,32)
 local versus=image(canvas,"vsBadge",784,389,352,202); versus.Name="VersusBadge"
 versus.AnchorPoint=Vector2.new(0.5,0.5); versus.Position=UDim2.fromOffset(960,490)
 Instance.new("UIScale",versus)
 for teamIndex,team in ipairs({left,right}) do
  local x=teamIndex==1 and 100 or 1240
  for index,member in ipairs(team) do
   local y=#team==1 and 835 or 775+(index-1)*125
   local localPlayer=member.userId==userId
   local plate=image(canvas,teamIndex==1 and "vsHomeNameFrame" or "vsAwayNameFrame",x-16,y-16,612,132)
   plate.Name="Nameplate"..teamIndex.."_"..index
   local name=label(canvas,"PlayerName",member.name or "PLAYER",x+26,y+10,localPlayer and 410 or 528,80,54)
   name:SetAttribute("UserId",member.userId)
   name.TextScaled=true
   local limit=Instance.new("UITextSizeConstraint",name); limit.MaxTextSize=54; limit.MinTextSize=8
   if localPlayer then
    local you=image(canvas,"vsYouFrame",x+439,y+9,126.5,72.6); you.Name="YouBadge"
    you.AnchorPoint=Vector2.new(0.5,0.5); you.Position=UDim2.fromOffset(x+502.25,y+50)
    local youLabel=label(you,"YouLabel","YOU",0,0,100,52,32)
    youLabel.AnchorPoint=Vector2.new(0.5,0.5); youLabel.Position=UDim2.fromScale(0.5,0.5)
   end
  end
 end
 image(canvas,"vsRoundFrame",790,774,340,92)
 label(canvas,"Round",MatchIntro.roundLabel(data),806,790,308,62,30)
 image(canvas,"vsCountdownFrame",694,868,532,124)
 local countdown=label(canvas,"CountdownText","GET READY",710,884,500,92,44)
 local points,winBy=data.pointsToWin or 11,data.winBy or 2
 if points==11 and winBy==2 then image(canvas,"vsScoring",620,988,680,45)
 else label(canvas,"Scoring",string.format("FIRST TO %d / WIN BY %d",points,winBy),620,988,680,45,22) end
 return root,countdown,scale,scene
end
function MatchIntro.resize(root,scale)
 scale.Scale=math.min(root.AbsoluteSize.X/1920,root.AbsoluteSize.Y/1080)
 for _,item in ipairs(root.Canvas:GetChildren()) do
  if item.Name=="PlayerName" then
   local limit=item:FindFirstChildOfClass("UITextSizeConstraint")
   limit.MinTextSize=math.min(8,math.max(1,math.floor(54*scale.Scale)))
   limit.MaxTextSize=math.max(1,math.floor(54*scale.Scale))
  end
 end
end
function MatchIntro.start(player,network)
 local RunService=game:GetService("RunService")
 local gui=Instance.new("ScreenGui")
 gui.Name="MatchIntro"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=80
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild("PlayerGui")
 local current,countdown,scale,scene,lastId,endsAt
 local loading,pendingId,token
 local function clear()
  token=nil; pendingId=nil
  if current then current:Destroy(); current=nil end
  if loading then loading:Destroy(); loading=nil end
  countdown=nil; scale=nil; scene=nil
 end
 local function show(data)
  clear(); lastId=data.id; endsAt=data.endsAt
  current,countdown,scale,scene=MatchIntro.createScreen(gui,data,player.UserId)
 end
 local connection=network:WaitForChild("State").OnClientEvent:Connect(function(state)
  local data=state.matchIntro
  if not data then clear(); return end
  if data.loading then
   if pendingId==data.id then return end
   clear(); pendingId=data.id; token={}
   local requestToken=token
   loading=Instance.new("Frame",gui)
   loading.Name="PreparingCourt"; loading.Size=UDim2.fromScale(1,1)
   loading.BackgroundColor3=navy; loading.BorderSizePixel=0
   local text=label(loading,"LoadingText","PREPARING LUNAR COURT",0,0,800,80,28)
   text.AnchorPoint=Vector2.new(0.5,0.5); text.Position=UDim2.fromScale(0.5,0.5)
   task.spawn(function()
    task.spawn(function() pcall(function() player:RequestStreamAroundAsync(Vector3.new(0,185,0),20) end) end)
    local deadline=os.clock()+30
    local moon
    while token==requestToken and os.clock()<deadline do
     local court=workspace:FindFirstChild("PaddleUp")
     moon=court and court:FindFirstChild("MoonEnvironment")
     local expected=moon and moon:GetAttribute("ExpectedDescendants")
     if expected and #moon:GetDescendants()>=expected then break end
     task.wait(0.1)
    end
    if token~=requestToken or os.clock()>=deadline then return end
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({moon}) end)
    if token~=requestToken then return end
    RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
    if token==requestToken then network:WaitForChild("IntroReady"):FireServer(data.id) end
   end)
   return
  end
  if current and data.id==lastId then endsAt=data.endsAt; return end
  if data.id~=lastId and data.endsAt>workspace:GetServerTimeNow() then show(data) end
 end)
 local frames=RunService.RenderStepped:Connect(function()
  if not current then return end
  local remaining=endsAt-workspace:GetServerTimeNow()
  if remaining<=0 then clear(); return end
  MatchIntro.resize(current,scale)
  MatchIntro.updateScenes(scene)
  MatchIntro.animateScenes(scene,os.clock()-scene.startedAt)
  local count=MatchIntro.countdown(remaining)
  countdown.Text=count and "STARTING IN "..count or "GET READY"
 end)
 gui.Destroying:Connect(function() connection:Disconnect(); frames:Disconnect(); clear() end)
end
return MatchIntro
