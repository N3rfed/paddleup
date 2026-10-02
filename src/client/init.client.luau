local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local TweenService=game:GetService("TweenService")
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local player=Players.LocalPlayer
local DiveController=require(script:WaitForChild("DiveController"))
local HitboxOverlay=require(script:WaitForChild("HitboxOverlay"))
local RallyEffects=require(script:WaitForChild("RallyEffects"))
local BallShadow=require(script:WaitForChild("BallShadow"))
local FloatingText=require(script:WaitForChild("FloatingText"))
local developerMode=false
local Rules
local network=ReplicatedStorage:WaitForChild("PaddleUp")
local input,state,feedback=network:WaitForChild("Input"),network:WaitForChild("State"),network:WaitForChild("Feedback")
task.spawn(function() require(script:WaitForChild("LobbyUI")).start(network) end)
local function playing() return player:GetAttribute("LobbyStatus")=="Playing" end
local function lobbyMenuOpen()
 local ui=player.PlayerGui:FindFirstChild("SkylineLobbyUI")
 return ui and ui:GetAttribute("MenuOpen")==true
end
local cream=Color3.fromRGB(247,239,215)
local mint=Color3.fromRGB(92,233,190)
local coral=Color3.fromRGB(249,139,109)
local dark=Color3.fromRGB(19,37,44)
local gui=Instance.new("ScreenGui")
gui.Name="PaddleUpHUD"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
local canvas=Instance.new("Frame",gui)
canvas.Size=UDim2.fromOffset(1280,800); canvas.AnchorPoint=Vector2.new(0.5,0.5); canvas.Position=UDim2.fromScale(0.5,0.5); canvas.BackgroundTransparency=1
local crosshair=Instance.new("Frame",gui)
crosshair.Name="Crosshair"; crosshair.AnchorPoint=Vector2.new(0.5,0.5); crosshair.Position=UDim2.fromScale(0.5,0.5)
crosshair.Size=UDim2.fromOffset(24,24); crosshair.BackgroundTransparency=1; crosshair.Visible=false
for _,shape in ipairs({{0,11,8,2},{16,11,8,2},{11,0,2,8},{11,16,2,8}}) do
 local bar=Instance.new("Frame",crosshair)
 bar.Position=UDim2.fromOffset(shape[1],shape[2]); bar.Size=UDim2.fromOffset(shape[3],shape[4])
 bar.BackgroundColor3=Color3.new(1,1,1); bar.BorderSizePixel=0
 local outline=Instance.new("UIStroke",bar); outline.Color=dark; outline.Thickness=1
end
local scale=Instance.new("UIScale",canvas)
local chargeTrack=Instance.new("Frame",crosshair)
chargeTrack.Name="Charge"; chargeTrack.Position=UDim2.fromOffset(-12,34); chargeTrack.Size=UDim2.fromOffset(48,4)
chargeTrack.BackgroundColor3=dark; chargeTrack.BorderSizePixel=0; chargeTrack.Visible=false
local chargeFill=Instance.new("Frame",chargeTrack)
chargeFill.BackgroundColor3=mint; chargeFill.BorderSizePixel=0; chargeFill.Size=UDim2.fromScale(0,1)
local chargeStarted,chargeCanShow
local function cancelCharge()
 if chargeCanShow then DiveController.charge(player.UserId,false) end
 if chargeStarted then input:FireServer("ChargeCancel") end
 chargeStarted=nil; chargeCanShow=false; chargeTrack.Visible=false
end
local function round(object,r)
 local c=Instance.new("UICorner",object); c.CornerRadius=UDim.new(0,r or 14)
end
local function panel(pos,size)
 local f=Instance.new("Frame",canvas); f.Position=UDim2.fromOffset(pos.X,pos.Y); f.Size=UDim2.fromOffset(size.X,size.Y); f.BackgroundColor3=dark; f.BackgroundTransparency=0.12; f.BorderSizePixel=0; round(f)
 local stroke=Instance.new("UIStroke",f); stroke.Color=Color3.fromRGB(77,111,112); stroke.Transparency=0.5
 return f
end
local function text(parent,value,pos,size,fontSize,color)
 local t=Instance.new("TextLabel",parent); t.BackgroundTransparency=1; t.Position=UDim2.fromOffset(pos.X,pos.Y); t.Size=UDim2.fromOffset(size.X,size.Y)
 t.Text=value; t.Font=Enum.Font.GothamMedium; t.TextSize=fontSize or 16; t.TextColor3=color or cream; t.TextXAlignment=Enum.TextXAlignment.Left
 return t
end
local announcement=text(gui,"",Vector2.zero,Vector2.new(760,120),32,cream)
announcement.Name="RallyAnnouncement"; announcement.AnchorPoint=Vector2.new(0.5,0.5)
announcement.Position=UDim2.fromScale(0.5,0.43); announcement.Size=UDim2.fromScale(0.8,0.18)
announcement.TextXAlignment=Enum.TextXAlignment.Center; announcement.TextWrapped=true
announcement.Font=Enum.Font.GothamBold; announcement.TextStrokeTransparency=0.3; announcement.Visible=false
local announcementUntil=0
local serveNotice=text(gui,"",Vector2.zero,Vector2.new(700,64),24,cream)
serveNotice.Name="ServeNotice"; serveNotice.AnchorPoint=Vector2.new(0.5,0)
serveNotice.Position=UDim2.fromScale(0.5,0.27); serveNotice.TextXAlignment=Enum.TextXAlignment.Center
serveNotice.Font=Enum.Font.GothamBold; serveNotice.TextStrokeTransparency=0.3; serveNotice.Visible=false
local serveNoticeScale=Instance.new("UIScale",serveNotice)
local developerLabel=text(canvas,"",Vector2.new(28,590),Vector2.new(820,58),12,mint)
developerLabel.TextWrapped=true
developerLabel.Text="DEV HITBOXES [HOME]  /  Gold: hit  |  Green: perfect range  |  Blue: overhead zone  |  Purple: slam distance cap\nSlams need blue/purple overlap. Contact behind the red rear-limit plane is rejected."
developerLabel.Visible=false
local brand=panel(Vector2.new(28,32),Vector2.new(295,82))
text(brand,"PADDLE UP!",Vector2.new(18,9),Vector2.new(260,34),29).Font=Enum.Font.GothamBlack
text(brand,"SKYLINE CLUB  /  ROOFTOP 18",Vector2.new(19,47),Vector2.new(270,20),11,mint)
local scorePanel=panel(Vector2.new(528,24),Vector2.new(224,62))
scorePanel.Name="Score"
scorePanel.BackgroundColor3=Color3.new(1,1,1); scorePanel.BackgroundTransparency=0.05
local scoreGradient=Instance.new("UIGradient",scorePanel)
scoreGradient.Color=ColorSequence.new(Color3.fromRGB(27,58,63),Color3.fromRGB(12,23,33)); scoreGradient.Rotation=25
local scoreDigits={}
for i,layout in ipairs({{8,64,cream},{93,64,cream},{177,36,mint}}) do
 local digit=text(scorePanel,i==3 and "1" or "0",Vector2.new(layout[1],8),Vector2.new(layout[2],43),i==3 and 24 or 34,layout[3])
 digit.Font=Enum.Font.GothamBlack; digit.TextXAlignment=Enum.TextXAlignment.Center
 scoreDigits[i]=digit
end
for _,x in ipairs({73,158}) do
 local dash=text(scorePanel,"-",Vector2.new(x,12),Vector2.new(20,34),20,Color3.fromRGB(104,139,146))
 dash.TextXAlignment=Enum.TextXAlignment.Center
end
local serveAccent=Instance.new("Frame",scorePanel)
serveAccent.Size=UDim2.fromOffset(36,3); serveAccent.Position=UDim2.fromOffset(22,53)
serveAccent.BackgroundColor3=mint; serveAccent.BorderSizePixel=0; round(serveAccent,2)
local badge=panel(Vector2.new(967,32),Vector2.new(285,82))
local speedText=text(badge,"1.00x  RALLY SPEED",Vector2.new(17,12),Vector2.new(260,27),20,mint)
local volleyText=text(badge,"0 PERFECT RETURNS",Vector2.new(17,46),Vector2.new(260,18),11)
local sub=text(canvas,"",Vector2.new(290,184),Vector2.new(700,24),13)
sub.TextXAlignment=Enum.TextXAlignment.Center; sub.TextStrokeTransparency=0.6
local controls=panel(Vector2.new(28,659),Vector2.new(300,112))
text(controls,"MAKE YOUR MOVE",Vector2.new(16,10),Vector2.new(270,22),12,mint)
text(controls,"WASD / Arrows    Move",Vector2.new(16,38),Vector2.new(270,22),15)
text(controls,"SPACE    Jump     SHIFT    Dive",Vector2.new(16,69),Vector2.new(275,22),14)
local hitPanel=panel(Vector2.new(350,644),Vector2.new(530,127))
local timingText=text(hitPanel,"WATCH THE LANDING RING",Vector2.new(16,10),Vector2.new(498,26),15,mint)
timingText.TextXAlignment=Enum.TextXAlignment.Center
local timingTrack=Instance.new("Frame",hitPanel)
timingTrack.Position=UDim2.fromOffset(20,44); timingTrack.Size=UDim2.fromOffset(490,7); timingTrack.BackgroundColor3=Color3.fromRGB(52,70,73); timingTrack.BorderSizePixel=0; round(timingTrack,4)
local timingFill=Instance.new("Frame",timingTrack); timingFill.Size=UDim2.fromScale(0,1); timingFill.BorderSizePixel=0; timingFill.BackgroundColor3=mint; round(timingFill,4)
text(hitPanel,"HOLD LMB / RELEASE HIT  /  RMB SOFT",Vector2.new(20,61),Vector2.new(490,23),16).TextXAlignment=Enum.TextXAlignment.Center
local staminaPanel=panel(Vector2.new(490,738),Vector2.new(300,42))
staminaPanel.Name="Stamina"
local staminaLabel=text(staminaPanel,"STAMINA",Vector2.new(12,3),Vector2.new(270,18),10)
local staminaTrack=Instance.new("Frame",staminaPanel); staminaTrack.Position=UDim2.fromOffset(12,28); staminaTrack.Size=UDim2.fromOffset(276,5); staminaTrack.BackgroundColor3=Color3.fromRGB(52,70,73); staminaTrack.BorderSizePixel=0
local staminaFill=Instance.new("Frame",staminaTrack); staminaFill.Size=UDim2.fromScale(1,1); staminaFill.BackgroundColor3=mint; staminaFill.BorderSizePixel=0
local abilities=panel(Vector2.new(902,659),Vector2.new(350,112))
local function button(label,y,action)
 local b=Instance.new("TextButton",abilities); b.Position=UDim2.fromOffset(12,y); b.Size=UDim2.fromOffset(326,40); b.BackgroundColor3=Color3.fromRGB(38,66,72); b.BorderSizePixel=0; b.Text=label; b.TextColor3=cream; b.Font=Enum.Font.GothamMedium; b.TextSize=14; round(b,8)
 b.Activated:Connect(function() input:FireServer(action) end)
 return b
end
local powerButton=button("Q   POWER SHOT      READY",10,"Power")
local slowButton=button("E   SLOW OPPONENT   READY",61,"Slow")
local touchSwing=Instance.new("TextButton",canvas)
touchSwing.Position=UDim2.fromOffset(1070,525); touchSwing.Size=UDim2.fromOffset(180,60); touchSwing.Text="SWING"; touchSwing.Font=Enum.Font.GothamBold; touchSwing.TextSize=22; touchSwing.BackgroundColor3=mint; touchSwing.TextColor3=dark; round(touchSwing)
touchSwing.Visible=UIS.TouchEnabled
local touchDive=touchSwing:Clone(); touchDive.Parent=canvas; touchDive.Position=UDim2.fromOffset(1070,590); touchDive.Size=UDim2.fromOffset(180,45); touchDive.Text="DIVE"
local devToggle=Instance.new("TextButton",gui)
devToggle.Name="DeveloperToggle"; devToggle.AnchorPoint=Vector2.new(1,0)
devToggle.Position=UDim2.new(1,-16,0,16); devToggle.Size=UDim2.fromOffset(190,32)
devToggle.BackgroundColor3=dark; devToggle.TextColor3=cream; devToggle.Font=Enum.Font.GothamMedium; devToggle.TextSize=12
round(devToggle,8)
local function setDeveloperMode(enabled)
 developerMode=enabled
 gui:SetAttribute("DeveloperMode",enabled)
 for _,child in ipairs(canvas:GetChildren()) do
  if child:IsA("GuiObject") then child.Visible=child==scorePanel or child==staminaPanel or enabled end
 end
 touchSwing.Visible=enabled and UIS.TouchEnabled; touchDive.Visible=enabled and UIS.TouchEnabled
 devToggle.Text=enabled and "DEV ON  /  Alt to click" or "DEV OFF  /  Alt to click"
end
devToggle.Activated:Connect(function() setDeveloperMode(not developerMode) end)
setDeveloperMode(false)
local snapshot,receivedAt=nil,0
local localHitReadyAt=0
local function hitInputReady()
 if not playing() then return false end
 local character=player.Character
 if character and character:GetAttribute("MissImmune") then return false end
 local readyAt=character and character:GetAttribute("HitReadyAt") or 0
 local perfect=snapshot and snapshot.live and (snapshot.green or snapshot.slamReady)
 return perfect or (os.clock()>=localHitReadyAt and workspace:GetServerTimeNow()>=readyAt)
end
local function animateSwing(softRequested,charge)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local backhand=snapshot and root.CFrame:PointToObjectSpace(snapshot.p).X<0 or false
 local side=player:GetAttribute("CourtSide") or 1
 local soft=softRequested and (Rules and Rules.softShot(root.Position,side) or "drop") or nil
 DiveController.swing(player.UserId,backhand,false,nil,nil,charge or 0,soft,true)
 localHitReadyAt=os.clock()+((snapshot and snapshot.live and (snapshot.green or snapshot.slamReady)) and 0 or 0.28)
end
local function swing(softRequested)
 if player:GetAttribute("LobbyStatus")=="Lobby" then
  if lobbyMenuOpen() or UIS:IsKeyDown(Enum.KeyCode.LeftAlt) or UIS:IsKeyDown(Enum.KeyCode.RightAlt) then return end
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health<=0 or os.clock()<localHitReadyAt then return end
  localHitReadyAt=os.clock()+0.28
  DiveController.swing(player.UserId,false,false,nil,nil,0,softRequested==true and "drop" or nil,true)
  input:FireServer("LobbySwing",softRequested==true)
  return
 end
 if not hitInputReady() then return end
 animateSwing(false)
 input:FireServer(snapshot and not snapshot.live and "Serve" or "Swing")
end
local function dive()
 if not playing() then return end
 cancelCharge()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 input:FireServer("Dive",humanoid and humanoid.MoveDirection or Vector3.zero)
end
UIS.TouchTapInWorld:Connect(function(_,processed) if not processed and not developerMode then swing() end end)
touchSwing.Activated:Connect(swing)
touchDive.Activated:Connect(dive)
UIS.InputBegan:Connect(function(key,processed)
 if UIS:GetFocusedTextBox() then return end
 if key.KeyCode==Enum.KeyCode.Home then
  setDeveloperMode(not developerMode); return
 end
 if processed then return end
 if not playing() then
  if key.UserInputType==Enum.UserInputType.MouseButton1 then swing()
  elseif key.UserInputType==Enum.UserInputType.MouseButton2 then swing(true) end
  return
 end
 if key.UserInputType==Enum.UserInputType.MouseButton1 then
  chargeStarted=os.clock()
  local readyAt=player.Character and player.Character:GetAttribute("ChargedShotReadyAt")
  chargeCanShow=(snapshot and snapshot.canServe) or not readyAt or workspace:GetServerTimeNow()>=readyAt
  local started=chargeStarted
  task.delay(0.4,function()
   if chargeStarted==started and chargeCanShow then DiveController.charge(player.UserId,true,started) end
  end)
  input:FireServer("ChargeStart")
 elseif key.UserInputType==Enum.UserInputType.MouseButton2 then
  cancelCharge()
  if hitInputReady() then animateSwing(true); input:FireServer("SoftShot") end
 elseif key.KeyCode==Enum.KeyCode.LeftShift then dive()
 elseif key.KeyCode==Enum.KeyCode.Q then input:FireServer("Power")
 elseif key.KeyCode==Enum.KeyCode.E then input:FireServer("Slow") end
end)
UIS.InputEnded:Connect(function(key)
 if key.UserInputType==Enum.UserInputType.MouseButton1 and chargeStarted then
  local held=os.clock()-chargeStarted
  if not hitInputReady() then cancelCharge(); return end
  animateSwing(false,chargeCanShow and math.clamp((held-0.4)/0.6,0,1) or 0)
  chargeStarted=nil; chargeTrack.Visible=false
  chargeCanShow=false; input:FireServer("ChargeRelease")
 end
end)
UIS.WindowFocusReleased:Connect(cancelCharge)
UIS.TextBoxFocused:Connect(cancelCharge)
game:GetService("GuiService").MenuOpened:Connect(cancelCharge)
player.CharacterRemoving:Connect(cancelCharge)
player:GetAttributeChangedSignal("LobbyStatus"):Connect(cancelCharge)
local arrows={}
player:GetAttributeChangedSignal("LobbyStatus"):Connect(function() table.clear(arrows) end)
CAS:BindActionAtPriority("PaddleUpArrows",function(_,status,key)
 if UIS:GetFocusedTextBox() or not playing() then return Enum.ContextActionResult.Pass end
 arrows[key.KeyCode]=status==Enum.UserInputState.Begin or status==Enum.UserInputState.Change
 return Enum.ContextActionResult.Sink
end,false,3000,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right)
UIS.WindowFocusReleased:Connect(function() table.clear(arrows) end)
local visual=Instance.new("Part")
visual.Name="LocalPickleball"; visual.Shape=Enum.PartType.Ball; visual.Size=Vector3.new(0.85,0.85,0.85); visual.Color=Color3.fromRGB(239,255,87); visual.Material=Enum.Material.Neon
visual.Anchored=true; visual.CanCollide=false; visual.CanQuery=false; visual.CanTouch=false; visual.CastShadow=false; visual.Parent=workspace
local ballShadow=BallShadow.new()
local a0=Instance.new("Attachment",visual); a0.Position=Vector3.new(0,0.48,0)
local a1=Instance.new("Attachment",visual); a1.Position=Vector3.new(0,-0.48,0)
local trail=Instance.new("Trail",visual); trail.Attachment0=a0; trail.Attachment1=a1; trail.Lifetime=0.35; trail.Color=ColorSequence.new(Color3.fromRGB(245,255,126)); trail.Transparency=NumberSequence.new(0.15,1)
local effects=RallyEffects.new(visual,trail)
script.Destroying:Connect(function()
 RunService:UnbindFromRenderStep("PaddleUpView")
 effects:destroy()
 ballShadow:destroy()
 FloatingText.destroy()
end)
local outMarker=Instance.new("Part",workspace)
outMarker.Name="Out landing"; outMarker.Anchored=true; outMarker.Transparency=1
outMarker.CanCollide=false; outMarker.CanTouch=false; outMarker.CanQuery=false
outMarker.Size=Vector3.new(3,0.02,3)
local outGui=Instance.new("SurfaceGui",outMarker)
outGui.Face=Enum.NormalId.Top; outGui.CanvasSize=Vector2.new(128,128); outGui.AlwaysOnTop=false; outGui.Enabled=false
local outX=text(outGui,"X",Vector2.zero,Vector2.new(128,128),110,coral)
outX.TextXAlignment=Enum.TextXAlignment.Center; outX.Font=Enum.Font.GothamBlack
local lastOutLanding
local ring={}
for i=1,40 do
 local p=Instance.new("Part")
 p.Name="Landing ring"; p.Transparency=1; p.Size=Vector3.new(0.12,0.06,0.45); p.Material=Enum.Material.Neon; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Parent=workspace
 ring[i]=p
end
local marker=Instance.new("Part",workspace)
marker.Name="Bounce countdown"; marker.Size=Vector3.new(0.1,0.1,0.1); marker.Anchored=true; marker.Transparency=1; marker.CanCollide=false; marker.CanQuery=false
local landingGui=Instance.new("BillboardGui",marker); landingGui.Size=UDim2.fromOffset(140,48); landingGui.StudsOffset=Vector3.new(0,1,0); landingGui.AlwaysOnTop=true; landingGui.Enabled=false
local countdown=text(landingGui,"",Vector2.zero,Vector2.new(140,48),16,mint); countdown.TextXAlignment=Enum.TextXAlignment.Center; countdown.Font=Enum.Font.GothamBold; countdown.TextStrokeTransparency=0.4
local aim=Instance.new("Part",workspace); aim.Name="Facing aim"; aim.CanTouch=false; aim.Size=Vector3.new(0.2,0.06,3); aim.Anchored=true; aim.CanCollide=false; aim.CanQuery=false; aim.Material=Enum.Material.Neon; aim.Color=mint; aim.Transparency=1
state.OnClientEvent:Connect(function(data)
 if snapshot and snapshot.serveReady and not data.serveReady then cancelCharge() end
 if not snapshot or snapshot.shotId~=data.shotId or not data.live then trail:Clear() end
 snapshot=data; receivedAt=os.clock()
 outGui.Enabled=data.outLanding~=nil
 if data.outLanding and data.outLanding~=lastOutLanding then
  local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={player.Character,outMarker}; params.RespectCanCollide=true
  local hit=workspace:Raycast(data.outLanding+Vector3.new(0,1,0),Vector3.new(0,-10,0),params)
  local groundY=hit and hit.Position.Y or 181.3
  outMarker.Position=Vector3.new(data.outLanding.X,groundY+0.015,data.outLanding.Z)
 end
 lastOutLanding=data.outLanding
 touchSwing.Text=data.live and "SWING" or (data.canServe and "SERVE" or "WAIT")
 scoreDigits[1].Text=tostring(data.score[1]); scoreDigits[2].Text=tostring(data.score[2]); scoreDigits[3].Text=tostring(data.serverNumber or 1)
 serveAccent.Position=UDim2.fromOffset(data.servingSide==1 and 22 or 107,53)
 speedText.Text=string.format("%.2fx  RALLY SPEED",data.speed)
 volleyText.Text=data.perfects.." PERFECT RETURNS"
 staminaFill.Size=UDim2.fromScale(math.clamp(data.stamina/(data.maxStamina or 100),0,1),1)
 staminaLabel.Text=data.dive>0 and string.format("DIVE %.1fs",data.dive) or "STAMINA"
 powerButton.Text=data.armed>0 and string.format("Q   POWER ARMED    %.1fs",data.armed) or (data.power>0 and string.format("Q   POWER SHOT     %.1fs",data.power) or "Q   POWER SHOT      READY")
 powerButton.TextColor3=data.armed>0 and mint or cream
 slowButton.Text=data.slow>0 and string.format("E   SLOW OPPONENT  %.1fs",data.slow) or "E   SLOW OPPONENT   READY"
end)
local studioSoundNames={
 ["pickleball floor"]="Pickleball Floor (Tire Drop Bounce 19 (SFX))",
 ["crowd gasp"]="Crowd Gasp",
}
local function playRallySound(name)
 local shared=ReplicatedStorage:FindFirstChild("Shared")
 local hello=shared and shared:FindFirstChild("Hello")
 local template=hello and hello:FindFirstChild(name)
 -- Existing Studio sessions may still have the imported assets in Workspace.
 if not template and studioSoundNames[name] then template=workspace:FindFirstChild(studioSoundNames[name]) end
 if not template or not template:IsA("Sound") then return end
 -- Independent voices preserve rapid impacts and the original sample's pitch.
 local sound=template:Clone()
 sound.Looped=false; sound.TimePosition=0; sound.Parent=SoundService
 sound.Ended:Once(function() sound:Destroy() end)
 Debris:AddItem(sound,30)
 sound:Play()
end
feedback.OnClientEvent:Connect(function(message,kind)
 if kind=="crowdGasp" then playRallySound("crowd gasp"); return end
 if kind=="playerText" then
  local actor=message.userId~=0 and Players:GetPlayerByUserId(message.userId)
  local world=workspace:FindFirstChild("PaddleUp")
  local character=actor and actor.Character or (message.userId==0 and world and world:FindFirstChild("Practice Partner"))
  FloatingText.show(character,message.text,message.tone)
  return
 end
 effects:feedback(message,kind)
 if kind=="ballBounce" then
  playRallySound("pickleball floor")
  return
 end
 if kind=="fault" then cancelCharge(); return end
 if kind=="point" then
  announcement.Text=tostring(message); announcement.TextColor3=cream
  announcementUntil=os.clock()+2.5; announcement.Visible=true
  return
 end
 if kind=="rallyResult" then
  cancelCharge()
  announcement.Text=kind=="rallyResult" and (message.title.."\n"..message.fault) or tostring(message)
  announcement.TextColor3=kind=="fault" and coral or cream
  announcementUntil=os.clock()+2.5; announcement.Visible=true
  return
 end
 if kind=="ballHit" then
  playRallySound("pickleball hit")
  return
 end
 if kind=="diveMotion" then
  DiveController.play(message.userId,message.direction)
  return
 end
 if kind=="swing" then
  DiveController.swing(message.userId,message.backhand,message.slam,message.contact,message.direction,message.charge,message.soft)
  return
 end
 FloatingText.show(player.Character,tostring(message),(kind=="perfect" or kind=="slam" or kind=="power") and "good" or (kind=="miss" or kind=="slow") and "bad" or "neutral")
 if kind=="perfect" or kind=="slam" then
  visual.Size=Vector3.new(1.4,1.4,1.4)
  TweenService:Create(visual,TweenInfo.new(0.25),{Size=Vector3.new(0.85,0.85,0.85)}):Play()
 end
end)
local cameraRoot,cameraSide,trackedCamera
local yaw,pitch=0,math.rad(-18)
local windowFocused=true
UIS.WindowFocusReleased:Connect(function() windowFocused=false end)
UIS.WindowFocused:Connect(function() windowFocused=true end)
UIS.TouchMoved:Connect(function(touch,processed)
 if processed or player:GetAttribute("LobbyStatus")=="Spectating" or lobbyMenuOpen() or touch.Position.X<workspace.CurrentCamera.ViewportSize.X*0.5 then return end
 yaw-=touch.Delta.X*0.004
 pitch=math.clamp(pitch-touch.Delta.Y*0.004,math.rad(-65),math.rad(30))
end)
RunService:BindToRenderStep("PaddleUpView",Enum.RenderPriority.Camera.Value+1,function(dt)
 local camera=workspace.CurrentCamera
 if not camera then return end
 scale.Scale=math.min(camera.ViewportSize.X/1280,camera.ViewportSize.Y/800)
 if not Rules then
  local shared=ReplicatedStorage:FindFirstChild("Shared")
  local module=shared and shared:FindFirstChild("MatchRules")
  if module then Rules=require(module) end
 end
 local now=os.clock()
 if chargeStarted then
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health<=0 then cancelCharge()
  else
   chargeTrack.Visible=chargeCanShow==true and now-chargeStarted>=0.4
   chargeFill.Size=UDim2.fromScale(math.clamp((now-chargeStarted-0.4)/0.6,0,1),1)
  end
 end
 local lobbyStatus=player:GetAttribute("LobbyStatus") or "Lobby"
 canvas.Visible=lobbyStatus~="Lobby"
 devToggle.Visible=lobbyStatus=="Playing"
 staminaPanel.Visible=lobbyStatus=="Playing"
 announcement.Visible=lobbyStatus~="Lobby" and now<announcementUntil
 serveNoticeScale.Scale=scale.Scale
 serveNotice.Visible=lobbyStatus~="Lobby" and snapshot~=nil and snapshot.serveReady==true
 if serveNotice.Visible then
  local remaining=math.max(0,math.ceil((snapshot.serveDeadline or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
  serveNotice.Text=(snapshot.serverName or "Player").."'s serve\nAuto-serve in "..remaining.."s"
 end
 local c=player.Character
 local r=c and c:FindFirstChild("HumanoidRootPart")
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local courtSide=playing() and (player:GetAttribute("CourtSide") or 0) or 0
 local side=courtSide~=0 and courtSide or 1
 local age=snapshot and math.min(now-receivedAt,0.12) or 0
 local predicted
 if snapshot then
  predicted=snapshot.p+snapshot.v*age+Vector3.new(0,-0.5*(snapshot.g or 45)*age*age,0)
  predicted=Vector3.new(predicted.X,math.max(181.7,predicted.Y),predicted.Z)
  if snapshot.serveReady and Rules then
   local server=snapshot.serverId and Players:GetPlayerByUserId(snapshot.serverId)
   local world=workspace:FindFirstChild("PaddleUp")
   local holder=server and server.Character or (snapshot.bot and world and world:FindFirstChild("Practice Partner"))
   predicted=Rules.heldBallPosition(holder) or predicted
  end
 end
 if r then
  camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=65
  local reset=cameraRoot~=r or cameraSide~=courtSide or trackedCamera~=camera
  if reset then
   yaw=side==1 and 0 or math.pi
   pitch=math.rad(-18)
  end
  local locked=playing() and h and h.Health>0
  local aiming=locked and not lobbyMenuOpen() and not UIS:IsKeyDown(Enum.KeyCode.LeftAlt) and not UIS:IsKeyDown(Enum.KeyCode.RightAlt) and windowFocused and not UIS:GetFocusedTextBox() and not game:GetService("GuiService").MenuIsOpen
  UIS.MouseBehavior=aiming and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
  UIS.MouseIconEnabled=not aiming
  crosshair.Visible=aiming==true
  if aiming and UIS.MouseEnabled then
   local delta=UIS:GetMouseDelta()
   yaw-=delta.X*0.004
   pitch=math.clamp(pitch-delta.Y*0.004,math.rad(-65),math.rad(30))
  end
  if h then h.AutoRotate=not locked end
  local desired,focus
  if lobbyStatus=="Spectating" then
    focus=Vector3.new(0,182,0)
    desired=CFrame.lookAt(Vector3.new(50,235,72),focus)
  else
   local heading=CFrame.Angles(0,yaw,0)
   if locked then r.CFrame=CFrame.new(r.Position)*heading end
   local orbit=heading*CFrame.Angles(pitch,0,0)
   focus=r.Position+Vector3.new(0,2.5,0)
   -- Shorten the orbit when looking up so the camera stays above the roof.
   local distance=16
   if orbit.LookVector.Y>0 then
    distance=math.min(distance,math.max(0,(focus.Y-183)/orbit.LookVector.Y))
   end
   local position=focus-orbit.LookVector*distance+orbit.RightVector*2
   position=Vector3.new(position.X,math.max(183,position.Y),position.Z)
   desired=CFrame.lookAt(position,position+orbit.LookVector)
  end
  camera.CFrame=desired
  camera.Focus=CFrame.new(focus)
  cameraRoot,cameraSide,trackedCamera=r,courtSide,camera
  if h then
   local ax=(arrows[Enum.KeyCode.Right] and 1 or 0)-(arrows[Enum.KeyCode.Left] and 1 or 0)
   local az=(arrows[Enum.KeyCode.Down] and 1 or 0)-(arrows[Enum.KeyCode.Up] and 1 or 0)
   if ax~=0 or az~=0 then h:Move(Vector3.new(ax,0,az).Unit,true) end
   local look=r.CFrame.LookVector
   local direction=Vector3.new(look.X,0,look.Z)
   if Rules then direction=Rules.shotAim(r.CFrame,r.AssemblyLinearVelocity,predicted) end
   crosshair.Position=UDim2.fromScale(0.5,0.5)
   if direction.Magnitude>0 then
    local at=Vector3.new(r.Position.X,181.42,r.Position.Z)
    aim.CFrame=CFrame.lookAt(at+direction.Unit*3,at+direction.Unit*6)
   end
  end
 end
 aim.Transparency=developerMode and r and courtSide~=0 and 0.4 or 1
 if not r then
  UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true; crosshair.Visible=false
 end
 HitboxOverlay.update(developerMode)
 FloatingText.update(dt)
 effects:update(dt,snapshot,chargeCanShow and chargeStarted or nil)
 ballShadow:update(predicted,snapshot~=nil and (snapshot.live or snapshot.serveReady))
 if not snapshot then return end
 visual.Position=predicted; visual.Transparency=(snapshot.live or snapshot.serveReady) and 0 or 1; trail.Enabled=snapshot.live
 local eta=math.max(0,snapshot.eta-age)
 local color=snapshot.green and mint or (eta<0.6 and Color3.fromRGB(255,214,97) or coral)
 local visible=developerMode and snapshot.live and math.abs(snapshot.landing.X)<=24 and math.abs(snapshot.landing.Z)<=46
 local radius=1.6+math.sin(now*9)*0.2+math.min(eta,1.5)*0.6
 for i,p in ipairs(ring) do
  local angle=i*math.pi*2/#ring
  local pos=Vector3.new(snapshot.landing.X+math.cos(angle)*radius,181.37,snapshot.landing.Z+math.sin(angle)*radius)
  p.CFrame=CFrame.new(pos)*CFrame.Angles(0,-angle,0)
  p.Color=color; p.Transparency=visible and 0.1 or 1
 end
 marker.Position=Vector3.new(snapshot.landing.X,181.5,snapshot.landing.Z)
 landingGui.Enabled=visible
 countdown.Text=snapshot.green and "PERFECT" or string.format("%.1fs",eta)
 countdown.TextColor3=color
 timingFill.Size=UDim2.fromScale(snapshot.live and math.clamp(1-eta/1.5,0.03,1) or 0,1)
 timingFill.BackgroundColor3=color
 timingText.Text=not snapshot.live and (snapshot.canServe and (snapshot.bot and snapshot.servingSide==-1 and "CLICK / TAP WHEN READY FOR BOT SERVE" or "CLICK / TAP TO SERVE DIAGONALLY") or (snapshot.serveReady and "WAITING FOR SERVER" or "PREPARING NEXT SERVE")) or (snapshot.mustBounce and "TWO-BOUNCE RULE  /  LET IT BOUNCE" or snapshot.last==side and "YOUR RETURN  /  GET READY" or (snapshot.green and "GREEN WINDOW  /  SWING!" or "TRACK THE RING  /  GET INTO RANGE"))
 if snapshot.slamReady then timingText.Text="LOB OVERHEAD  /  SWING TO SLAM!" end
 timingText.TextColor3=snapshot.slamReady and Color3.fromRGB(55,155,255) or color
 sub.Text=courtSide==0 and "SPECTATING  /  Return to lobby to manage your queue" or (snapshot.slowed>0 and "SLOWED!  Keep the rally alive" or "FIRST TO 11, WIN BY 2")
end)
