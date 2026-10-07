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
local lobbyCamera=require(script:WaitForChild("LobbyCamera")).new(player,UIS)
local Rules
local network=ReplicatedStorage:WaitForChild("PaddleUp")
local input,state,feedback=network:WaitForChild("Input"),network:WaitForChild("State"),network:WaitForChild("Feedback")
require(script:WaitForChild("MainMenu")).start(player,network)
local function playing() return (player:GetAttribute("CourtSide") or 0)~=0 and not player:GetAttribute("LeaveConfirmationOpen") end
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
local electric=Color3.fromRGB(68,225,255)
-- CanvasGroup fades the track, target and glow together; its padding contains the needle.
local serveMeter=Instance.new("CanvasGroup",gui)
serveMeter.Name="ServeTimingMeter"; serveMeter.AnchorPoint=Vector2.new(0.5,0.5)
serveMeter.Size=UDim2.fromOffset(40,152); serveMeter.BackgroundTransparency=1
serveMeter.GroupTransparency=1; serveMeter.Visible=false
local meterScale=Instance.new("UIScale",serveMeter); meterScale.Scale=0.85
local function pill(object,radius)
 local corner=Instance.new("UICorner",object); corner.CornerRadius=UDim.new(0,radius)
end
local track=Instance.new("Frame",serveMeter)
track.Name="Track"; track.AnchorPoint=Vector2.new(0.5,0.5); track.Position=UDim2.fromScale(0.5,0.5)
track.Size=UDim2.fromOffset(10,140); track.BackgroundColor3=Color3.fromRGB(15,20,25)
track.BackgroundTransparency=0.35; track.BorderSizePixel=0; pill(track,8)
local trackStroke=Instance.new("UIStroke",track)
trackStroke.Color=Color3.fromRGB(157,207,218); trackStroke.Thickness=1.5; trackStroke.Transparency=0.65
local lane=Instance.new("Frame",track)
lane.Name="Zones"; lane.AnchorPoint=Vector2.new(0.5,0.5); lane.Position=UDim2.fromScale(0.5,0.5)
lane.Size=UDim2.new(1,-4,1,-6); lane.BackgroundColor3=Color3.new(1,1,1)
lane.BackgroundTransparency=0.35; lane.BorderSizePixel=0; pill(lane,8)
local gradient=Instance.new("UIGradient",lane); gradient.Rotation=90
gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(112,73,67)),
 ColorSequenceKeypoint.new(0.3,Color3.fromRGB(78,99,108)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(53,146,166)),
 ColorSequenceKeypoint.new(0.7,Color3.fromRGB(78,99,108)),ColorSequenceKeypoint.new(1,Color3.fromRGB(112,73,67))})
local sweetSpot=Instance.new("Frame",track)
sweetSpot.Name="SweetSpot"; sweetSpot.Position=UDim2.fromScale(0,0.44); sweetSpot.Size=UDim2.fromScale(1,0.12)
sweetSpot.BackgroundTransparency=0.1; sweetSpot.BackgroundColor3=electric; sweetSpot.BorderSizePixel=0; pill(sweetSpot,8)
local sweetStroke=Instance.new("UIStroke",sweetSpot)
sweetStroke.Color=electric; sweetStroke.Thickness=3; sweetStroke.Transparency=0.7
local needle=Instance.new("Frame",track)
needle.Name="Needle"; needle.AnchorPoint=Vector2.new(0.5,0.5); needle.Size=UDim2.fromOffset(20,4)
needle.BackgroundColor3=Color3.new(1,1,1); needle.BorderSizePixel=0; needle.ZIndex=3; pill(needle,8)
local needleStroke=Instance.new("UIStroke",needle)
needleStroke.Color=electric; needleStroke.Thickness=1.5; needleStroke.Transparency=0.25
local glow=Instance.new("Frame",needle)
glow.Name="Glow"; glow.AnchorPoint=Vector2.new(0.5,0.5); glow.Position=UDim2.fromScale(0.5,0.5)
glow.Size=UDim2.fromOffset(28,10); glow.BackgroundColor3=electric; glow.BackgroundTransparency=0.85
glow.BorderSizePixel=0; glow.ZIndex=2; pill(glow,8)
local meterShowing=false
local meterFade,meterResize
local meterExitRequested=false
local function setMeterShown(shown,immediate)
 if meterShowing==shown and not immediate then return end
 meterShowing=shown
 if meterFade then meterFade:Cancel() end
 if meterResize then meterResize:Cancel() end
 if immediate then
  serveMeter.GroupTransparency=shown and 0 or 1; meterScale.Scale=shown and 1 or 0.85
  serveMeter.Visible=shown
  return
 end
 serveMeter.Visible=true
 local info=TweenInfo.new(shown and 0.2 or 0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
 meterFade=TweenService:Create(serveMeter,info,{GroupTransparency=shown and 0 or 1})
 meterResize=TweenService:Create(meterScale,info,{Scale=shown and 1 or 0.85})
 meterFade:Play(); meterResize:Play()
end
local meterFeedback=Instance.new("TextLabel",gui)
meterFeedback.AnchorPoint=Vector2.new(0.5,0.5)
meterFeedback.Size=UDim2.fromOffset(180,30); meterFeedback.BackgroundTransparency=1
meterFeedback.Font=Enum.Font.GothamBold; meterFeedback.TextSize=20; meterFeedback.Visible=false
meterFeedback.TextStrokeColor3=dark; meterFeedback.TextStrokeTransparency=0.25
local meterFeedbackUntil=0
local meterFeedbackTween
local meterInput,meterPending,meterDeadline
local function showServeTiming(grade)
 meterFeedback.Text=grade; meterFeedback.TextColor3=grade=="PERFECT!" and mint or grade=="GOOD" and Color3.fromRGB(255,220,75) or coral
 if meterFeedbackTween then meterFeedbackTween:Cancel() end
 meterFeedback.TextTransparency=0; meterFeedback.TextStrokeTransparency=0.25
 meterFeedbackTween=TweenService:Create(meterFeedback,TweenInfo.new(0.45,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,0.15),
  {TextTransparency=1,TextStrokeTransparency=1})
 meterFeedbackTween:Play()
 meterFeedbackUntil=os.clock()+0.6; meterFeedback.Visible=true
end
local serveCountdownCapsule=Instance.new("Frame",gui)
serveCountdownCapsule.Name="ServeCountdownCapsule"; serveCountdownCapsule.AnchorPoint=Vector2.new(0.5,0)
serveCountdownCapsule.Position=UDim2.new(0.5,0,1,10); serveCountdownCapsule.Size=UDim2.fromOffset(186,34)
serveCountdownCapsule.BackgroundColor3=Color3.fromRGB(13,22,31)
serveCountdownCapsule.BackgroundTransparency=0.35; serveCountdownCapsule.BorderSizePixel=0
serveCountdownCapsule.Visible=false
local countdownCorner=Instance.new("UICorner",serveCountdownCapsule); countdownCorner.CornerRadius=UDim.new(1,0)
local countdownBorder=Instance.new("UIStroke",serveCountdownCapsule)
countdownBorder.Color=Color3.fromRGB(34,50,66); countdownBorder.Thickness=1.5
local serveCountdown=Instance.new("TextLabel",serveCountdownCapsule)
serveCountdown.Name="ServeCountdown"; serveCountdown.Size=UDim2.fromScale(1,1)
serveCountdown.BackgroundTransparency=1; serveCountdown.Font=Enum.Font.GothamBold
serveCountdown.TextSize=18; serveCountdown.TextColor3=Color3.new(1,1,1)
local countdownTextStroke=Instance.new("UIStroke",serveCountdown)
countdownTextStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
countdownTextStroke.Color=Color3.fromRGB(11,17,24); countdownTextStroke.Thickness=2.5; countdownTextStroke.Transparency=0
local chargeStarted,chargeCanShow,chargeInput
local function cancelCharge(preserveMeterFade)
 if chargeCanShow then DiveController.charge(player.UserId,false) end
 if chargeStarted then input:FireServer("ChargeCancel") end
 chargeStarted=nil; chargeInput=nil; chargeCanShow=false; chargeTrack.Visible=false
 if preserveMeterFade==true then setMeterShown(false) else setMeterShown(false,true) end
 meterInput=nil
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
local developerLabel=text(canvas,"",Vector2.new(28,590),Vector2.new(820,58),12,mint)
developerLabel.TextWrapped=true
developerLabel.Text="DEV HITBOXES [HOME]  /  Gold: hit  |  Green: perfect range  |  Blue: overhead zone  |  Purple: slam distance cap\nSlams need blue/purple overlap. Contact behind the red rear-limit plane is rejected."
developerLabel.Visible=false
local brand=panel(Vector2.new(28,32),Vector2.new(295,82))
text(brand,"PADDLE UP!",Vector2.new(18,9),Vector2.new(260,34),29).Font=Enum.Font.GothamBlack
text(brand,"SKYLINE CLUB  /  ROOFTOP 18",Vector2.new(19,47),Vector2.new(270,20),11,mint)
local scorePanel=panel(Vector2.new(528,24),Vector2.new(224,62))
scorePanel.Name="Score"
serveCountdownCapsule.Parent=scorePanel
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
 local dash=text(scorePanel,"–",Vector2.new(x,12),Vector2.new(20,34),20,Color3.fromRGB(104,139,146))
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
local staminaPanel=panel(Vector2.new(490,720),Vector2.new(300,60))
staminaPanel.Name="Stamina"
local staminaLabel=text(staminaPanel,"STAMINA",Vector2.new(12,3),Vector2.new(270,18),10)
local staminaTrack=Instance.new("Frame",staminaPanel); staminaTrack.Position=UDim2.fromOffset(12,28); staminaTrack.Size=UDim2.fromOffset(276,5); staminaTrack.BackgroundColor3=Color3.fromRGB(52,70,73); staminaTrack.BorderSizePixel=0
local staminaFill=Instance.new("Frame",staminaTrack); staminaFill.Size=UDim2.fromScale(1,1); staminaFill.BackgroundColor3=mint; staminaFill.BorderSizePixel=0
local diveGray=Color3.fromRGB(58,64,72)
local diveLabel=text(staminaPanel,"DIVE READY",Vector2.new(12,33),Vector2.new(270,14),10,electric)
local diveTrack=Instance.new("Frame",staminaPanel)
diveTrack.Name="DiveCooldown"; diveTrack.Position=UDim2.fromOffset(12,51); diveTrack.Size=UDim2.fromOffset(276,5)
diveTrack.BackgroundColor3=electric; diveTrack.BorderSizePixel=0; round(diveTrack,3)
local diveOverlay=Instance.new("Frame",diveTrack)
diveOverlay.Name="CooldownSweep"; diveOverlay.AnchorPoint=Vector2.new(1,0); diveOverlay.Position=UDim2.fromScale(1,0)
diveOverlay.Size=UDim2.fromScale(0,1); diveOverlay.BackgroundColor3=Color3.fromRGB(20,25,32)
diveOverlay.BackgroundTransparency=0.15; diveOverlay.BorderSizePixel=0; round(diveOverlay,3)
local diveReadyAt=0
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
devToggle.Position=UDim2.new(1,-80,0,24); devToggle.Size=UDim2.fromOffset(190,32)
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
local function dive()
 if not playing() or workspace:GetServerTimeNow()<diveReadyAt or (snapshot and snapshot.stamina<(Rules and Rules.DIVE_STAMINA_COST or 35)) then return end
 cancelCharge()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 input:FireServer("Dive",humanoid and humanoid.MoveDirection or Vector3.zero)
end
local function stopServeMeter()
 if meterPending or not snapshot or not snapshot.canServe or not Rules then return end
 local _,_,accuracy=Rules.serveTiming(snapshot.serveDeadline-Rules.SERVE_TIMEOUT,workspace:GetServerTimeNow())
 meterPending=true; meterInput=nil
 animateSwing(false,accuracy)
 input:FireServer("ServeTimingStop")
end
local function beginCharge(key)
 if snapshot and snapshot.canServe then
  if not hitInputReady() then return end
  if meterPending or not playing() then return end
  if meterInput then stopServeMeter() else meterInput=key end
  return
 end
 if chargeStarted or not playing() or not hitInputReady() then return end
 if not snapshot or (not snapshot.live and not snapshot.canServe) then return end
 chargeInput=key; chargeStarted=os.clock()
 local readyAt=player.Character and player.Character:GetAttribute("ChargedShotReadyAt")
 chargeCanShow=snapshot.canServe or not readyAt or workspace:GetServerTimeNow()>=readyAt
 local started=chargeStarted
 task.delay(0.4,function()
  if chargeStarted==started and chargeCanShow then DiveController.charge(player.UserId,true,started) end
 end)
 input:FireServer("ChargeStart")
end
local function releaseCharge(key)
 if key==meterInput then stopServeMeter(); return end
 if key~=chargeInput or not chargeStarted then return end
 local held=os.clock()-chargeStarted
 if not hitInputReady() then cancelCharge(); return end
 animateSwing(false,chargeCanShow and math.clamp((held-0.4)/0.6,0,1) or 0)
 chargeStarted=nil; chargeInput=nil; chargeTrack.Visible=false
 chargeCanShow=false; input:FireServer("ChargeRelease")
end
touchSwing.InputBegan:Connect(function(key)
 if key.UserInputType==Enum.UserInputType.Touch then beginCharge(key) end
end)
touchDive.Activated:Connect(dive)
UIS.InputBegan:Connect(function(key,processed)
 if UIS:GetFocusedTextBox() then return end
 if key.KeyCode==Enum.KeyCode.Home then setDeveloperMode(not developerMode); return end
 if processed or not playing() then return end
 if key.UserInputType==Enum.UserInputType.MouseButton1 or key.KeyCode==Enum.KeyCode.F or key.UserInputType==Enum.UserInputType.Touch then
  beginCharge(key)
 elseif key.UserInputType==Enum.UserInputType.MouseButton2 then
  cancelCharge()
  if hitInputReady() then animateSwing(true); input:FireServer("SoftShot") end
 elseif key.KeyCode==Enum.KeyCode.LeftShift then dive()
 elseif key.KeyCode==Enum.KeyCode.Q then input:FireServer("Power")
 elseif key.KeyCode==Enum.KeyCode.E then input:FireServer("Slow") end
end)
UIS.InputEnded:Connect(releaseCharge)
UIS.WindowFocusReleased:Connect(cancelCharge)
UIS.TextBoxFocused:Connect(cancelCharge)
game:GetService("GuiService").MenuOpened:Connect(cancelCharge)
player.CharacterRemoving:Connect(cancelCharge)
player:GetAttributeChangedSignal("LeaveConfirmationOpen"):Connect(function()
 if player:GetAttribute("LeaveConfirmationOpen") then cancelCharge() end
end)
local arrows={}
CAS:BindActionAtPriority("PaddleUpArrows",function(_,status,key)
 if not playing() or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
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
 if not snapshot or snapshot.shotId~=data.shotId or not data.live then trail:Clear() end
 if snapshot and snapshot.canServe and not data.canServe then cancelCharge(data.live==true) end
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
 staminaFill.Size=UDim2.fromScale(data.stamina/100,1)
 diveReadyAt=data.diveReadyAt or (workspace:GetServerTimeNow()+data.dive)
 powerButton.Text=data.armed>0 and string.format("Q   POWER ARMED    %.1fs",data.armed) or (data.power>0 and string.format("Q   POWER SHOT     %.1fs",data.power) or "Q   POWER SHOT      READY")
 powerButton.TextColor3=data.armed>0 and mint or cream
 slowButton.Text=data.slow>0 and string.format("E   SLOW OPPONENT  %.1fs",data.slow) or "E   SLOW OPPONENT   READY"
end)
feedback.OnClientEvent:Connect(function(message,kind)
 if kind=="serveTiming" then showServeTiming(message.grade); meterPending=true; meterExitRequested=true; setMeterShown(false); meterInput=nil; return end
 if kind=="playerText" then
  local actor=message.userId~=0 and Players:GetPlayerByUserId(message.userId)
  local world=workspace:FindFirstChild("PaddleUp")
  local character=actor and actor.Character or (message.userId==0 and world and world:FindFirstChild("Practice Partner"))
  FloatingText.show(character,message.text,message.tone)
  return
 end
 effects:feedback(message,kind)
 if kind=="ballBounce" then
  if message.onCourt~=false then
   local shared=ReplicatedStorage:FindFirstChild("Shared")
   local hello=shared and shared:FindFirstChild("Hello")
   local template=hello and (hello:FindFirstChild("pickleball bounce") or hello:FindFirstChild("pickleball hit"))
   if template and template:IsA("Sound") then
    local sound=template:Clone(); sound.Name="Pickleball bounce"
    sound.Looped=false; sound.TimePosition=0; sound.Volume=0.35; sound.PlaybackSpeed=0.8; sound.Parent=SoundService
    sound.Ended:Once(function() sound:Destroy() end); Debris:AddItem(sound,5); sound:Play()
   end
  end
  return
 end
 if kind=="fault" then cancelCharge(); meterPending=false; meterFeedbackUntil=0; return end
 if kind=="point" then
  announcement.Text=tostring(message); announcement.TextColor3=cream
  announcementUntil=os.clock()+2.5; announcement.Visible=true
  return
 end
 if kind=="rallyResult" then
  meterFeedbackUntil=0; meterInput=nil; setMeterShown(false,true)
  cancelCharge()
  announcement.Text=kind=="rallyResult" and (message.title.."\n"..message.fault) or tostring(message)
  announcement.TextColor3=kind=="fault" and coral or cream
  announcementUntil=os.clock()+2.5; announcement.Visible=true
  return
 end
 if kind=="ballHit" then
  local shared=ReplicatedStorage:FindFirstChild("Shared")
  local hello=shared and shared:FindFirstChild("Hello")
  local template=hello and hello:FindFirstChild("pickleball hit")
  if template and template:IsA("Sound") then
   -- A separate voice per impact lets rapid rallies overlap naturally.
   local sound=template:Clone()
   sound.Looped=false; sound.TimePosition=0; sound.Parent=SoundService
   sound.Ended:Once(function() sound:Destroy() end)
   Debris:AddItem(sound,10)
   sound:Play()
  end
  return
 end
 if kind=="diveMotion" then
  if message.userId==player.UserId then diveReadyAt=message.diveReadyAt or (workspace:GetServerTimeNow()+(Rules and Rules.DIVE_COOLDOWN or 1.75)) end
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
 if not playing() or processed or touch.Position.X<workspace.CurrentCamera.ViewportSize.X*0.5 then return end
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
 local diveRemaining=math.max(0,diveReadyAt-workspace:GetServerTimeNow())
 local diveCooling=diveRemaining>0
 diveTrack.BackgroundColor3=diveCooling and diveGray or electric
 diveOverlay.Visible=diveCooling
 diveOverlay.Size=UDim2.fromScale(math.clamp(diveRemaining/(Rules and Rules.DIVE_COOLDOWN or 1.75),0,1),1)
 diveLabel.Text=diveCooling and string.format("DIVE %.1fs",diveRemaining) or "DIVE READY"
 diveLabel.TextColor3=diveCooling and Color3.fromRGB(147,155,165) or electric
 touchDive.BackgroundColor3=diveCooling and diveGray or electric
 touchDive.AutoButtonColor=not diveCooling
 serveCountdownCapsule.Visible=playing() and snapshot~=nil and snapshot.canServe==true
 if serveCountdownCapsule.Visible then
  local remaining=math.max(0,(snapshot.serveDeadline or workspace:GetServerTimeNow())-workspace:GetServerTimeNow())
  serveCountdown.Text="SERVE IN "..math.ceil(remaining).."s"
 end
 local canTime=playing() and snapshot and snapshot.canServe and Rules
 if canTime and meterDeadline~=snapshot.serveDeadline then
  meterDeadline=snapshot.serveDeadline; meterPending=false; meterInput=nil
  meterExitRequested=false; setMeterShown(false,true); meterFeedbackUntil=0
 end
 local meterActive=canTime and not meterExitRequested and windowFocused and not UIS:GetFocusedTextBox() and not game:GetService("GuiService").MenuIsOpen or false
 setMeterShown(meterActive)
 serveMeter.Visible=meterShowing or serveMeter.GroupTransparency<0.999
 if meterActive and not meterPending then
  local position=Rules.serveTiming(snapshot.serveDeadline-Rules.SERVE_TIMEOUT,workspace:GetServerTimeNow())
  needle.Position=UDim2.fromScale(0.5,position)
  if workspace:GetServerTimeNow()>=snapshot.serveDeadline then
   meterPending=true; meterInput=nil
  end
 end
 if not canTime then meterInput=nil; meterDeadline=nil; meterPending=false end
 meterFeedback.Visible=playing() and now<meterFeedbackUntil
 if chargeStarted and (not playing() or not snapshot or (not snapshot.live and not snapshot.canServe)) then cancelCharge() end
 if chargeStarted then
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health<=0 then cancelCharge()
  else
   chargeTrack.Visible=chargeCanShow==true and now-chargeStarted>=0.4
   chargeFill.Size=UDim2.fromScale(math.clamp((now-chargeStarted-0.4)/0.6,0,1),1)
  end
 end
 announcement.Visible=now<announcementUntil
 local c=player.Character
 local r=c and c:FindFirstChild("HumanoidRootPart")
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local courtSide=player:GetAttribute("CourtSide") or 0
 local inLobby=player:GetAttribute("SessionMode")==nil or player:GetAttribute("SessionMode")=="Lobby"
 canvas.Visible=not inLobby; devToggle.Visible=not inLobby
 if not inLobby then lobbyCamera:disable() end
 local side=courtSide~=0 and courtSide or 1
 local age=snapshot and math.min(now-receivedAt,0.12) or 0
 local predicted
 if snapshot then
  if Rules then predicted=Rules.advanceBall(snapshot.p,snapshot.v,45,age,snapshot.lob,(snapshot.bounces or 0)>0)
  else predicted=snapshot.p+snapshot.v*age+Vector3.new(0,-0.5*(snapshot.g or 45)*age*age,0) end
  predicted=Vector3.new(predicted.X,math.max(181.7,predicted.Y),predicted.Z)
  if snapshot.serveReady and Rules then
   local server=snapshot.serverId and Players:GetPlayerByUserId(snapshot.serverId)
   local world=workspace:FindFirstChild("PaddleUp")
   local holder=server and server.Character or (snapshot.bot and world and world:FindFirstChild("Practice Partner"))
   predicted=Rules.heldBallPosition(holder) or predicted
  end
 end
 if inLobby then
  cancelCharge()
  lobbyCamera:update(camera,r,h,dt)
  crosshair.Visible=false; aim.Transparency=1
  cameraRoot=nil
 elseif r then
  lobbyCamera:disable()
  camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=65
  local reset=cameraRoot~=r or cameraSide~=courtSide or trackedCamera~=camera
  if reset then
   yaw=side==1 and 0 or math.pi
   pitch=math.rad(-18)
  end
  local locked=courtSide~=0 and h and h.Health>0
  local aiming=locked and not player:GetAttribute("LeaveConfirmationOpen") and not UIS:IsKeyDown(Enum.KeyCode.LeftAlt) and not UIS:IsKeyDown(Enum.KeyCode.RightAlt) and windowFocused and not UIS:GetFocusedTextBox() and not game:GetService("GuiService").MenuIsOpen
  UIS.MouseBehavior=aiming and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
  UIS.MouseIconEnabled=not aiming
  crosshair.Visible=aiming==true and not (snapshot and snapshot.canServe)
  if aiming and UIS.MouseEnabled then
   local delta=UIS:GetMouseDelta()
   yaw-=delta.X*0.004
   pitch=math.clamp(pitch-delta.Y*0.004,math.rad(-65),math.rad(30))
  end
  if h then h.AutoRotate=not locked end
  local desired,focus
  if courtSide==0 then
   focus=Vector3.new(r.Position.X*0.2,181,side*9)
   desired=CFrame.lookAt(Vector3.new(r.Position.X*0.35,225,side*79),focus)
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
  -- Project a camera-relative offset so the compact bar stays to the avatar's right.
  local meterAt,meterOnScreen=camera:WorldToViewportPoint(r.Position+Vector3.new(0,1,0)+camera.CFrame.RightVector*3.5)
  serveMeter.Position=UDim2.fromOffset(meterAt.X,meterAt.Y)
  serveMeter.Visible=serveMeter.Visible and meterOnScreen and h~=nil and h.Health>0
  local feedbackAt,feedbackOnScreen=camera:WorldToViewportPoint(r.Position+Vector3.new(0,4.5,0))
  meterFeedback.Position=UDim2.fromOffset(feedbackAt.X,feedbackAt.Y)
  meterFeedback.Visible=meterFeedback.Visible and feedbackOnScreen
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
  setMeterShown(false,true); meterFeedback.Visible=false
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
 sub.Text=snapshot.side==0 and "SPECTATING  /  Return to lobby to choose a mode" or (snapshot.slowed>0 and "SLOWED!  Keep the rally alive" or "FIRST TO 11, WIN BY 2")
end)
