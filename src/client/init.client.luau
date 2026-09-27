local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local TweenService=game:GetService("TweenService")
local player=Players.LocalPlayer
local DiveController=require(script:WaitForChild("DiveController"))
local network=ReplicatedStorage:WaitForChild("PaddleUp")
local input,state,feedback=network:WaitForChild("Input"),network:WaitForChild("State"),network:WaitForChild("Feedback")
local cream=Color3.fromRGB(247,239,215)
local mint=Color3.fromRGB(92,233,190)
local coral=Color3.fromRGB(249,139,109)
local dark=Color3.fromRGB(19,37,44)
local gui=Instance.new("ScreenGui")
gui.Name="PaddleUpHUD"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
local canvas=Instance.new("Frame",gui)
canvas.Size=UDim2.fromOffset(1280,800); canvas.AnchorPoint=Vector2.new(0.5,0.5); canvas.Position=UDim2.fromScale(0.5,0.5); canvas.BackgroundTransparency=1
local scale=Instance.new("UIScale",canvas)
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
local brand=panel(Vector2.new(28,32),Vector2.new(295,82))
text(brand,"PADDLE UP!",Vector2.new(18,9),Vector2.new(260,34),29).Font=Enum.Font.GothamBlack
text(brand,"SKYLINE CLUB  /  ROOFTOP 18",Vector2.new(19,47),Vector2.new(270,20),11,mint)
local scorePanel=panel(Vector2.new(451,32),Vector2.new(378,82))
local scoreText=text(scorePanel,"00    :    00",Vector2.new(0,23),Vector2.new(378,48),33); scoreText.TextXAlignment=Enum.TextXAlignment.Center; scoreText.Font=Enum.Font.GothamBold
local sides=text(scorePanel,"HOME                         PRACTICE",Vector2.new(0,8),Vector2.new(378,18),11,mint); sides.TextXAlignment=Enum.TextXAlignment.Center
local badge=panel(Vector2.new(967,32),Vector2.new(285,82))
local speedText=text(badge,"1.00x  RALLY SPEED",Vector2.new(17,12),Vector2.new(260,27),20,mint)
local volleyText=text(badge,"0 PERFECT RETURNS",Vector2.new(17,46),Vector2.new(260,18),11)
local toast=text(canvas,"WELCOME TO SKYLINE CLUB",Vector2.new(240,144),Vector2.new(800,40),25)
toast.TextXAlignment=Enum.TextXAlignment.Center; toast.Font=Enum.Font.GothamBold; toast.TextStrokeTransparency=0.65
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
text(hitPanel,"LMB  SWING   /   Strafe to place your shot",Vector2.new(20,61),Vector2.new(490,23),16).TextXAlignment=Enum.TextXAlignment.Center
local staminaLabel=text(hitPanel,"STAMINA",Vector2.new(20,97),Vector2.new(75,18),10)
local staminaTrack=Instance.new("Frame",hitPanel); staminaTrack.Position=UDim2.fromOffset(95,103); staminaTrack.Size=UDim2.fromOffset(415,4); staminaTrack.BackgroundColor3=Color3.fromRGB(52,70,73); staminaTrack.BorderSizePixel=0
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
local snapshot,receivedAt,toastUntil=nil,0,os.clock()+4
local function swing()
 local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 input:FireServer("Swing",h and h.MoveDirection or Vector3.zero)
end
touchSwing.Activated:Connect(swing)
touchDive.Activated:Connect(function() input:FireServer("Dive") end)
UIS.InputBegan:Connect(function(key,processed)
 if processed or UIS:GetFocusedTextBox() then return end
 if key.UserInputType==Enum.UserInputType.MouseButton1 then swing()
 elseif key.KeyCode==Enum.KeyCode.LeftShift then input:FireServer("Dive")
 elseif key.KeyCode==Enum.KeyCode.Q then input:FireServer("Power")
 elseif key.KeyCode==Enum.KeyCode.E then input:FireServer("Slow") end
end)
local arrows={}
CAS:BindActionAtPriority("PaddleUpArrows",function(_,status,key)
 if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 arrows[key.KeyCode]=status==Enum.UserInputState.Begin or status==Enum.UserInputState.Change
 return Enum.ContextActionResult.Sink
end,false,3000,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right)
UIS.WindowFocusReleased:Connect(function() table.clear(arrows) end)
local visual=Instance.new("Part")
visual.Name="LocalPickleball"; visual.Shape=Enum.PartType.Ball; visual.Size=Vector3.new(0.85,0.85,0.85); visual.Color=Color3.fromRGB(239,255,87); visual.Material=Enum.Material.Neon
visual.Anchored=true; visual.CanCollide=false; visual.CanQuery=false; visual.CanTouch=false; visual.Parent=workspace
local a0=Instance.new("Attachment",visual); a0.Position=Vector3.new(0,0.2,0)
local a1=Instance.new("Attachment",visual); a1.Position=Vector3.new(0,-0.2,0)
local trail=Instance.new("Trail",visual); trail.Attachment0=a0; trail.Attachment1=a1; trail.Lifetime=0.17; trail.Color=ColorSequence.new(Color3.fromRGB(245,255,126)); trail.Transparency=NumberSequence.new(0.15,1)
local ring={}
for i=1,40 do
 local p=Instance.new("Part")
 p.Name="Landing ring"; p.Size=Vector3.new(0.12,0.06,0.45); p.Material=Enum.Material.Neon; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Parent=workspace
 ring[i]=p
end
local marker=Instance.new("Part",workspace)
marker.Name="Bounce countdown"; marker.Size=Vector3.new(0.1,0.1,0.1); marker.Anchored=true; marker.Transparency=1; marker.CanCollide=false; marker.CanQuery=false
local landingGui=Instance.new("BillboardGui",marker); landingGui.Size=UDim2.fromOffset(140,48); landingGui.StudsOffset=Vector3.new(0,1,0); landingGui.AlwaysOnTop=true
local countdown=text(landingGui,"",Vector2.zero,Vector2.new(140,48),16,mint); countdown.TextXAlignment=Enum.TextXAlignment.Center; countdown.Font=Enum.Font.GothamBold; countdown.TextStrokeTransparency=0.4
local aim=Instance.new("Part",workspace); aim.Name="Movement aim"; aim.Size=Vector3.new(0.2,0.06,3); aim.Anchored=true; aim.CanCollide=false; aim.CanQuery=false; aim.Material=Enum.Material.Neon; aim.Color=mint; aim.Transparency=0.4
state.OnClientEvent:Connect(function(data)
 snapshot=data; receivedAt=os.clock()
 scoreText.Text=string.format("%02d    :    %02d",data.score[1],data.score[2])
 sides.Text="HOME                         "..(data.bot and "PRACTICE" or "AWAY")
 speedText.Text=string.format("%.2fx  RALLY SPEED",data.speed)
 volleyText.Text=data.perfects.." PERFECT RETURNS"
 staminaFill.Size=UDim2.fromScale(data.stamina/100,1)
 staminaLabel.Text=data.dive>0 and string.format("DIVE %.1fs",data.dive) or "STAMINA"
 powerButton.Text=data.armed>0 and string.format("Q   POWER ARMED    %.1fs",data.armed) or (data.power>0 and string.format("Q   POWER SHOT     %.1fs",data.power) or "Q   POWER SHOT      READY")
 powerButton.TextColor3=data.armed>0 and mint or cream
 slowButton.Text=data.slow>0 and string.format("E   SLOW OPPONENT  %.1fs",data.slow) or "E   SLOW OPPONENT   READY"
end)
feedback.OnClientEvent:Connect(function(message,kind)
 if kind=="diveMotion" then
  DiveController.play(message.userId,message.direction)
  return
 end
 if kind=="swing" then
  local p=Players:GetPlayerByUserId(message)
  if p and p.Character and not p.Character:GetAttribute("Diving") then
   local arm=p.Character:FindFirstChild("RightUpperArm") or p.Character:FindFirstChild("Torso")
   local shoulder=arm and (arm:FindFirstChild("RightShoulder") or arm:FindFirstChild("Right Shoulder"))
   if shoulder and shoulder:IsA("Motor6D") then
    local base=shoulder.C0
    if not shoulder:GetAttribute("Swinging") then
     shoulder:SetAttribute("Swinging",true)
     TweenService:Create(shoulder,TweenInfo.new(0.09),{C0=base*CFrame.Angles(-1.8,0,-0.5)}):Play()
     task.delay(0.1,function()
      if shoulder.Parent then TweenService:Create(shoulder,TweenInfo.new(0.18),{C0=base}):Play() end
      task.delay(0.2,function() if shoulder.Parent then shoulder:SetAttribute("Swinging",false) end end)
     end)
    end
   end
  end
  return
 end
 if kind=="miss" and os.clock()<toastUntil then return end
 toast.Text=tostring(message); toast.TextColor3=(kind=="perfect" or kind=="power") and mint or (kind=="miss" and coral or cream)
 toastUntil=os.clock()+(kind=="point" and 2.5 or 1.2)
 if kind=="perfect" then
  visual.Size=Vector3.new(1.4,1.4,1.4)
  TweenService:Create(visual,TweenInfo.new(0.25),{Size=Vector3.new(0.85,0.85,0.85)}):Play()
 end
end)
RunService:BindToRenderStep("PaddleUpView",Enum.RenderPriority.Camera.Value+1,function(dt)
 local camera=workspace.CurrentCamera
 if not camera then return end
 scale.Scale=math.min(camera.ViewportSize.X/1280,camera.ViewportSize.Y/800)
 local now=os.clock()
 local c=player.Character
 local r=c and c:FindFirstChild("HumanoidRootPart")
 local h=c and c:FindFirstChildOfClass("Humanoid")
 local side=(snapshot and snapshot.side~=0 and snapshot.side) or 1
 if r then
  camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=65
  local desired=CFrame.lookAt(Vector3.new(r.Position.X*0.35,225,side*79),Vector3.new(r.Position.X*0.2,181,side*9))
  camera.CFrame=camera.CFrame:Lerp(desired,1-math.exp(-dt*8))
  if h then
   local ax=(arrows[Enum.KeyCode.Right] and 1 or 0)-(arrows[Enum.KeyCode.Left] and 1 or 0)
   local az=(arrows[Enum.KeyCode.Down] and 1 or 0)-(arrows[Enum.KeyCode.Up] and 1 or 0)
   if ax~=0 or az~=0 then h:Move(Vector3.new(ax*side,0,az*side).Unit,false) end
   local direction=Vector3.new(h.MoveDirection.X*17,0,-side*(27-h.MoveDirection.Z*side*10))-Vector3.new(r.Position.X*0.7,0,r.Position.Z)
   if direction.Magnitude>0 then
    local at=Vector3.new(r.Position.X,181.42,r.Position.Z)
    aim.CFrame=CFrame.lookAt(at+direction.Unit*3,at+direction.Unit*6)
   end
  end
 end
 if not snapshot then return end
 local age=math.min(now-receivedAt,0.12)
 local predicted=snapshot.p+snapshot.v*age+Vector3.new(0,-0.5*(snapshot.g or 45)*age*age,0)
 predicted=Vector3.new(predicted.X,math.max(181.7,predicted.Y),predicted.Z)
 visual.Position=predicted; visual.Transparency=snapshot.live and 0 or 1; trail.Enabled=snapshot.live
 local eta=math.max(0,snapshot.eta-age)
 local color=snapshot.green and mint or (eta<0.6 and Color3.fromRGB(255,214,97) or coral)
 local visible=snapshot.live and math.abs(snapshot.landing.X)<=24 and math.abs(snapshot.landing.Z)<=46
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
 timingText.Text=not snapshot.live and "NEXT SERVE IN A MOMENT" or (snapshot.last==side and "YOUR RETURN  /  GET READY" or (snapshot.green and "GREEN WINDOW  /  SWING!" or "TRACK THE RING  /  GET INTO RANGE"))
 timingText.TextColor3=color
 sub.Text=snapshot.side==0 and "SPECTATING  /  You will join when a court slot opens" or (snapshot.slowed>0 and "SLOWED!  Keep the rally alive" or "YOUR SIDE: "..(side==1 and "HOME" or "AWAY").."   /   First to 11, win by 2")
 if now>toastUntil then
  toast.Text=snapshot.live and "" or snapshot.banner
  toast.TextColor3=cream
 end
end)
