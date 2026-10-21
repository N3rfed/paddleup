-- Roster-driven presentation; the server holds the serve until endsAt.
local MatchIntro={}
function MatchIntro.countdown(remaining)
 return remaining>0 and remaining<=3 and math.ceil(remaining) or nil
end
function MatchIntro.panFrame(target,distance,progress,direction,nearestDepth)
 local t=math.clamp(progress,0,1)
 local sweep=(t*t*(3-2*t)-0.5)*2*direction
 local depth=target.Z*direction
 local front=nearestDepth or depth
 -- A constant-radius arc on the net side; limit its angle to stay inside the court.
 local maxAngle=math.rad(24)
 local maxRadius=math.max(1,depth-2)
 local minRadius=math.min(maxRadius,math.max(1,(depth-front+2)/math.cos(maxAngle)))
 local radius=math.clamp(distance,minRadius,maxRadius)
 maxAngle=math.min(maxAngle,math.asin(math.clamp((18-math.abs(target.X))/radius,0,1)))
 local angle=sweep*maxAngle
 local position=target+Vector3.new(math.sin(angle)*radius,1.5,-math.cos(angle)*radius*direction)
 return CFrame.lookAt(position,target)
end
function MatchIntro.copyCourt(parent,court)
 local scenery=Instance.new("Model")
 scenery.Name="Court scenery"
 if court then
  for _,item in ipairs(court:GetChildren()) do
   if item.Name~="Practice Partner" and item.Name~="PowerupPickups" then
    local clone=item:Clone()
    if clone then
     for _,descendant in ipairs(clone:GetDescendants()) do
      if descendant:IsA("LuaSourceContainer") or descendant:IsA("Sound") then descendant:Destroy()
      elseif descendant:IsA("BasePart") then descendant.Anchored=true; descendant.CanCollide=false end
     end
     if clone:IsA("BasePart") then clone.Anchored=true; clone.CanCollide=false end
     clone.Parent=scenery
    end
   end
  end
 end
 scenery.Parent=parent
 return scenery
end
function MatchIntro.start(player,network)
 local Players=game:GetService("Players")
 local TweenService=game:GetService("TweenService")
 local RunService=game:GetService("RunService")
 local gui=Instance.new("ScreenGui")
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui.Name="MatchIntro"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=30
 gui.Parent=player:WaitForChild("PlayerGui")
 local current,lastId,endsAt=nil,nil,0
 local loading,pendingId
 local countdown,countdownText,lastCount
 local courtPan
 local savedCamera
 local function restoreCamera()
  if savedCamera then
   local camera=savedCamera.camera
   camera.CameraType=savedCamera.kind; camera.CFrame=savedCamera.frame; camera.FieldOfView=savedCamera.fov
   savedCamera=nil
  end
 end
 local shots={}
 local function clear(keepLoading)
  if not keepLoading then
   pendingId=nil
   if loading then loading:Destroy(); loading=nil end
  end
  restoreCamera()
  if current then current:Destroy(); current=nil end
  if countdown then countdown:Destroy(); countdown=nil; countdownText=nil end
  if courtPan then courtPan:Destroy(); courtPan=nil end
  lastCount=nil
  table.clear(shots)
 end
 local function label(parent,text,position,size,fontSize)
  local item=Instance.new("TextLabel")
  item.BackgroundTransparency=1; item.Position=position; item.Size=size
  item.Text=text; item.TextColor3=Color3.fromRGB(255,247,224)
  item.Font=Enum.Font.GothamBold; item.TextSize=fontSize; item.TextScaled=true
  item.TextWrapped=true; item.ZIndex=4; item.Parent=parent
  local limit=Instance.new("UITextSizeConstraint",item); limit.MaxTextSize=fontSize; limit.MinTextSize=10
  return item
 end
 local function show(data)
  clear(true); lastId=data.id; endsAt=data.endsAt
  -- Keep text and both camera views out of CanvasGroup's downsampled texture.
  local root=Instance.new("Frame")
  root.Name="TeamReveal"; root.Size=UDim2.fromScale(1,1); root.BackgroundColor3=Color3.fromRGB(18,91,94)
  root.BorderSizePixel=0; root.ClipsDescendants=true; root.Parent=gui; current=root
  countdown=Instance.new("Frame",gui)
  countdown.Name="Countdown"; countdown.Size=UDim2.fromScale(1,1)
  countdown.BackgroundColor3=Color3.fromRGB(15,23,30); countdown.BackgroundTransparency=0.65
  countdown.Visible=false
  countdownText=label(countdown,"3",UDim2.fromScale(0.3,0.3),UDim2.fromScale(0.4,0.4),140)
  label(countdown,"GET READY",UDim2.fromScale(0.3,0.7),UDim2.fromScale(0.4,0.08),24)
  local diagonal=Instance.new("Frame",root)
  diagonal.Name="DiagonalSplit"; diagonal.AnchorPoint=Vector2.new(0.5,0.5)
  diagonal.Position=UDim2.fromScale(0.5,0.5); diagonal.Size=UDim2.new(0,4,3,0)
  diagonal.Rotation=15; diagonal.BorderSizePixel=0
  diagonal.BackgroundColor3=Color3.fromRGB(255,214,138); diagonal.ZIndex=4
  -- The wide pan reveals the live workspace, including its real lighting and scenery.
  courtPan=Instance.new("Frame",gui)
  courtPan.Name="CourtPan"; courtPan.Size=UDim2.fromScale(1,1)
  courtPan.BackgroundTransparency=1; courtPan.Visible=false
  local court=workspace:FindFirstChild("PaddleUp")
  local environmentTitle=court and court:GetAttribute("EnvironmentTitle") or "SKYLINE CLUB"
  label(root,environmentTitle.."  /  COURT INTRO",UDim2.fromScale(0.15,0.06),UDim2.fromScale(0.7,0.05),18)
  label(root,tostring(#data.home).." V "..tostring(#data.away),UDim2.fromScale(0.35,0.13),UDim2.fromScale(0.3,0.08),36)
  label(root,"VS",UDim2.fromScale(0.44,0.45),UDim2.fromScale(0.12,0.1),48)
  label(root,"GET READY",UDim2.fromScale(0.3,0.88),UDim2.fromScale(0.4,0.05),22)
  for teamIndex,team in ipairs({data.home,data.away}) do
   local x=teamIndex==1 and 0.05 or 0.59
   label(root,"TEAM "..teamIndex,UDim2.fromScale(x,0.26),UDim2.fromScale(0.36,0.05),22)
   local viewport=Instance.new("ViewportFrame",root)
   viewport.Name="TeamShot"..teamIndex
   viewport.Position=UDim2.fromScale(0,0); viewport.Size=UDim2.fromScale(1,1)
   viewport.BackgroundColor3=court and court:GetAttribute("Environment")=="Moon" and Color3.new(0,0,0) or Color3.fromRGB(111,160,186); viewport.ZIndex=2
   -- A sharp transparency gradient clips the full-screen camera image itself.
   local mask=Instance.new("UIGradient",viewport)
   mask.Name="DiagonalMask"; mask.Rotation=15
   local left=teamIndex==1 and 0 or 1
   mask.Transparency=NumberSequence.new({
    NumberSequenceKeypoint.new(0,left),NumberSequenceKeypoint.new(0.499,left),
    NumberSequenceKeypoint.new(0.501,1-left),NumberSequenceKeypoint.new(1,1-left),
   })
   viewport.Ambient=Color3.fromRGB(190,195,210); viewport.LightColor=Color3.fromRGB(255,237,205)
   viewport.LightDirection=Vector3.new(-1,-1,-1)
   local world=Instance.new("WorldModel",viewport)
   local camera=Instance.new("Camera",viewport); camera.FieldOfView=38; viewport.CurrentCamera=camera
   MatchIntro.copyCourt(world,workspace:FindFirstChild("PaddleUp"))
   local shot={viewport=viewport,world=world,camera=camera,team=team,loaded={},height=6,width=#team*4,
    direction=teamIndex==1 and 1 or -1,nextCheck=0}
   table.insert(shots,shot)
   for index,member in ipairs(team) do
    local name=label(root,member.name..(member.userId==player.UserId and "  (YOU)" or ""),
     UDim2.fromScale(x,0.8+(index-1)*0.04),UDim2.fromScale(0.36,0.04),20)
    name.Name="PlayerName"
   end
  end
  -- Fade a native overlay instead of flattening the full intro into another image.
  local fade=Instance.new("Frame",root)
  fade.Name="RevealFade"; fade.Size=UDim2.fromScale(1,1); fade.BorderSizePixel=0
  fade.BackgroundColor3=Color3.fromRGB(15,23,30); fade.ZIndex=10
  TweenService:Create(fade,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
  game:GetService("Debris"):AddItem(fade,0.3)
 end
 local stateConnection=network:WaitForChild("State").OnClientEvent:Connect(function(state)
  local data=state.matchIntro
  if not data then clear(); return end
  if data.loading then
   if pendingId==data.id then return end
   clear(); pendingId=data.id
   loading=Instance.new("Frame",gui)
   loading.Name="PreparingCourt"; loading.Size=UDim2.fromScale(1,1)
   loading.BackgroundColor3=Color3.fromRGB(8,13,23); loading.BorderSizePixel=0; loading.ZIndex=20
   local text=label(loading,"PREPARING LUNAR COURT",UDim2.fromScale(0.2,0.45),UDim2.fromScale(0.6,0.08),28)
   text.ZIndex=21
   task.spawn(function()
    -- Request the destination while the opaque transition covers replication.
    task.spawn(function() pcall(function() player:RequestStreamAroundAsync(Vector3.new(0,185,0),20) end) end)
    local moon
    while pendingId==data.id do
     local court=workspace:FindFirstChild("PaddleUp")
     moon=court and court:FindFirstChild("MoonEnvironment")
     local expected=moon and moon:GetAttribute("ExpectedDescendants")
     if expected and #moon:GetDescendants()>=expected then break end
     task.wait(0.1)
    end
    if pendingId~=data.id then return end
    local ok=pcall(function() game:GetService("ContentProvider"):PreloadAsync({moon,game:GetService("Lighting"):FindFirstChild("LunarSky")}) end)
    if not ok or pendingId~=data.id then return end
    show(data)
    -- Build both viewport scenes before acknowledging readiness to the server.
    RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
    if pendingId==data.id then network:WaitForChild("IntroReady"):FireServer(data.id) end
   end)
   return
  end
  if pendingId==data.id and current then
   pendingId=nil; endsAt=data.endsAt
   if loading then loading:Destroy(); loading=nil end
   return
  end
  if data.id==lastId then endsAt=data.endsAt end
  if data.endsAt>workspace:GetServerTimeNow() and data.id~=lastId then show(data) end
 end)
 local function updateShots(remaining)
  for _,shot in ipairs(shots) do
   -- Retry characters that have not replicated yet, without yielding the camera animation.
   if os.clock()>=shot.nextCheck then
    shot.nextCheck=os.clock()+0.2
    for index,member in ipairs(shot.team) do
     if not shot.loaded[index] then
      local source
      if member.bot then
       local court=workspace:FindFirstChild("PaddleUp")
       source=court and court:FindFirstChild("Practice Partner")
      else
       local memberPlayer=Players:GetPlayerByUserId(member.userId)
       source=memberPlayer and memberPlayer.Character
      end
      local body=source and (source:FindFirstChild("HumanoidRootPart") or source:FindFirstChild("Body"))
      if body and body.Position.Y>178 and body.Position.Z*shot.direction>0 then
       local archivable=source.Archivable
       source.Archivable=true
       local ok,model=pcall(function() return source:Clone() end)
       source.Archivable=archivable
       if ok and model then
        for _,item in ipairs(model:GetDescendants()) do
         if item:IsA("LuaSourceContainer") or item:IsA("BillboardGui") or item:IsA("Sound") then item:Destroy()
         elseif item:IsA("BasePart") then item.Anchored=true; item.CanCollide=false end
        end
        local bounds,size=model:GetBoundingBox()
        model.Parent=shot.world
        local low,high=bounds.Position-size/2,bounds.Position+size/2
        shot.low=shot.low and shot.low:Min(low) or low
        shot.high=shot.high and shot.high:Max(high) or high
        shot.height=math.max(6,shot.high.Y-shot.low.Y)
        shot.width=math.max(4,shot.high.X-shot.low.X)
        shot.loaded[index]={model=model,bot=member.bot}
       end
      end
     end
    end
   end
   local size=shot.viewport.AbsoluteSize
   local aspect=math.max(0.2,size.X/math.max(1,size.Y))
   local distance=math.max(shot.height/2+1,(shot.width/2+2)/(aspect*0.4))/math.tan(math.rad(19))+2
   local target=shot.low and (shot.low+shot.high)/2 or Vector3.new(0,184,shot.direction*28)
   local nearest=shot.low and (shot.direction==1 and shot.low.Z or -shot.high.Z) or 28
   local frame=MatchIntro.panFrame(target,distance,(9.5-remaining)/3.5,shot.direction,nearest)
   local actualDistance=math.max(1,(target-frame.Position).Magnitude)
   local extent=math.max(shot.height/2+1,(shot.width/2+2)/(aspect*0.4))
   local fov=math.clamp(math.deg(2*math.atan(extent/actualDistance)),38,90)
   shot.camera.FieldOfView=fov
   -- Aim into the diagonal half instead of sliding the camera off court.
   local yaw=math.atan(math.tan(math.rad(fov/2))*aspect*0.5)
   shot.camera.CFrame=frame*CFrame.Angles(0,-shot.direction*yaw,0)
   -- Preserve the captured character pose: only the camera moves around the team.
  end
 end
 local function renderIntro()
  if not current or loading then return end
  local remaining=endsAt-workspace:GetServerTimeNow()
  if remaining>6 then updateShots(remaining) end
  if remaining>3 and remaining<=6 then
   current.Visible=false; courtPan.Visible=true
   local progress=math.clamp((6-remaining)/3,0,1)
   local camera=workspace.CurrentCamera
   if not camera then return end
   if not savedCamera then savedCamera={camera=camera,kind=camera.CameraType,frame=camera.CFrame,fov=camera.FieldOfView} end
   camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=55
   local aspect=math.max(0.3,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y))
   -- A wide sideline sweep keeps both baselines and the net in view.
   local distance=math.max(76,60/aspect)
   local angle=-0.18+progress*0.36
   local target=Vector3.new(0,183,0)
   camera.CFrame=CFrame.lookAt(target+Vector3.new(math.cos(angle)*distance,38,math.sin(angle)*distance),target)
  end
  if remaining<=0 then clear()
  else
   local count=MatchIntro.countdown(remaining)
   if count then
    restoreCamera()
    current.Visible=false; courtPan.Visible=false; countdown.Visible=true
    if count~=lastCount then
     lastCount=count; countdownText.Text=tostring(count)
     local scale=countdownText:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",countdownText)
     scale.Scale=1.2
     TweenService:Create(scale,TweenInfo.new(0.22,Enum.EasingStyle.Back),{Scale=1}):Play()
    end
   end
  end
 end
 local binding="PaddleUpMatchIntro_"..game:GetService("HttpService"):GenerateGUID(false)
 RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+2,renderIntro)
 gui.Destroying:Connect(function()
  RunService:UnbindFromRenderStep(binding); stateConnection:Disconnect(); clear()
 end)
end
return MatchIntro
