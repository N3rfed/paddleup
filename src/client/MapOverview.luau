-- Elevator-only, server-timed live environment overview. Play-menu intros keep their existing presentation.
local Overview={}
function Overview.camera(map,height,progress)
 local offset=Vector3.new(0,height,0)
 local t=math.clamp(progress,0,1); t=t*t*(3-2*t)
 return CFrame.lookAt(map.from:Lerp(map.to,t)+offset,map.focus+offset)
end
function Overview.start(player,network)
 local RunService=game:GetService("RunService")
 local TweenService=game:GetService("TweenService")
 local Maps=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MapCatalog"))
 local CourtView=require(script.Parent:WaitForChild("CourtView"))
 local gui=Instance.new("ScreenGui"); gui.Name="MapOverview"; gui.IgnoreGuiInset=true
 gui.ResetOnSpawn=false; gui.DisplayOrder=95; gui.Enabled=false; gui.Parent=player:WaitForChild("PlayerGui")
 local dark=Color3.fromRGB(20,20,48)
 local fade=Instance.new("Frame"); fade.Name="Fade"; fade.Size=UDim2.fromScale(1,1)
 fade.BackgroundColor3=dark; fade.BorderSizePixel=0; fade.Parent=gui
 local heading=Instance.new("TextLabel"); heading.Name="MapName"; heading.BackgroundTransparency=1
 heading.Size=UDim2.new(1,-40,0,60); heading.Position=UDim2.new(0,20,1,-145)
 heading.Font=Enum.Font.GothamBold; heading.TextSize=38; heading.TextColor3=Color3.fromRGB(80,232,255)
 heading.TextStrokeTransparency=0.5; heading.TextWrapped=true; heading.Parent=gui
 local sub=heading:Clone(); sub.Name="Details"; sub.TextSize=16; sub.Position=UDim2.new(0,20,1,-78)
 sub.Size=UDim2.new(1,-40,0,48); sub.TextColor3=Color3.fromRGB(246,246,255); sub.Parent=gui
 local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,38); top.BackgroundColor3=dark; top.BorderSizePixel=0; top.Parent=gui
 local active,token,finishing,savedFov,fadeTween
 local binding="PaddleUpMapOverview"
 local function releaseCamera()
  RunService:UnbindFromRenderStep(binding)
  if workspace.CurrentCamera and savedFov then workspace.CurrentCamera.FieldOfView=savedFov end
  savedFov=nil
 end
 local function clear()
  token=nil; active=nil; finishing=false
  if fadeTween then fadeTween:Cancel(); fadeTween=nil end
  releaseCamera(); gui.Enabled=false
 end
 local function finish()
  token=nil; active=nil; finishing=true; releaseCamera()
  heading.Visible=false; sub.Visible=false; fade.BackgroundTransparency=0
  fadeTween=TweenService:Create(fade,TweenInfo.new(0.3),{BackgroundTransparency=1})
  fadeTween:Play()
  fadeTween.Completed:Once(function()
   if finishing then finishing=false; gui.Enabled=false end
  end)
 end
 local function beginLoading(data)
  clear(); active=data; token={}
  local request=token
  local map=Maps.get(data.environment)
  if not map then clear(); return end
  gui.Enabled=true; fade.BackgroundTransparency=0; heading.Visible=true; sub.Visible=true
  heading.Text=string.upper(map.name); heading.TextColor3=map.accent
  sub.Text="PREPARING "..map.title.." / WAITING FOR EVERY PLAYER"
  task.spawn(function()
   task.spawn(function()
    pcall(function() player:RequestStreamAroundAsync(map.focus+Vector3.new(0,CourtView.height(),0),20) end)
   end)
   local deadline=os.clock()+27
   local environment
   while token==request and os.clock()<deadline do
    local court=CourtView.root()
    environment=court and court:FindFirstChild(data.environmentModel)
    local floor=court and court:FindFirstChild("Playing surface")
    if environment and floor and #environment:GetDescendants()>=(data.environmentExpected or 0) then break end
    task.wait(0.1)
   end
   if token~=request or os.clock()>=deadline then return end
   -- Asset requests may fail or stall; geometry readiness and the server's timeout remain authoritative.
   local preloaded=false
   task.spawn(function()
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({environment}) end)
    preloaded=true
   end)
   local assetDeadline=math.min(deadline,os.clock()+8)
   while token==request and not preloaded and os.clock()<assetDeadline do task.wait(0.1) end
   if token~=request then return end
   RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
   if token==request then network:WaitForChild("IntroReady"):FireServer(data.id) end
  end)
 end
 local function showOverview(data)
  local map=Maps.get(data.environment)
  if not map then clear(); return end
  token=nil; active=data; finishing=false
  if fadeTween then fadeTween:Cancel(); fadeTween=nil end
  gui.Enabled=true; heading.Visible=true; sub.Visible=true
  heading.Text=map.title; heading.TextColor3=map.accent
  sub.Text=(data.variant=="Chaos" and "CHAOTIC" or "CLASSIC").." / "..data.format:gsub("V","v").." / "..map.tagline
  savedFov=workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView
  RunService:BindToRenderStep(binding,Enum.RenderPriority.Last.Value+10,function()
   if not active or active.loading then return end
   local remaining=active.endsAt-workspace:GetServerTimeNow()
   if remaining<=0 then finish(); return end
   local elapsed=(active.overviewSeconds or 4)-remaining
   fade.BackgroundTransparency=math.clamp(math.min(elapsed,remaining)/0.45,0,1)
   local camera=workspace.CurrentCamera
   if camera then
    camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=62
    camera.CFrame=Overview.camera(map,CourtView.height(),elapsed/(active.overviewSeconds or 4))
    camera.Focus=CFrame.new(map.focus+Vector3.new(0,CourtView.height(),0))
   end
  end)
 end
 local connection=network:WaitForChild("State").OnClientEvent:Connect(function(state)
  if state.matchSessionId~=nil and state.matchSessionId~=player:GetAttribute("MatchSessionId") then return end
  local data=state.matchIntro
  if not data or not data.overview then
   if active then finish() end
   return
  end
  if data.loading then
   if not active or active.id~=data.id then beginLoading(data) end
  elseif not active or active.id~=data.id or active.loading then
   showOverview(data)
  else active=data end
 end)
 local session=player:GetAttributeChangedSignal("MatchSessionId"):Connect(clear)
 gui.Destroying:Connect(function() connection:Disconnect(); session:Disconnect(); clear() end)
end
return Overview
