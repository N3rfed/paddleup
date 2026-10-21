-- Presentation only: server owns admission and existing court gameplay.
local MainMenu={}
function MainMenu.start(player,network)
 local TweenService=game:GetService("TweenService")
 local gui=Instance.new("ScreenGui")
 gui.Name="PaddleUpMenu"; gui.ResetOnSpawn=false; gui.DisplayOrder=20; gui.IgnoreGuiInset=true
 gui.Parent=player:WaitForChild("PlayerGui")
 local lobbyMusic=require(script.Parent:WaitForChild("LobbyMusic")).new()
 local courtMusic=Instance.new("Sound")
 courtMusic.Name="CourtMusic"
 courtMusic.SoundId="rbxassetid://1837768517"
 courtMusic.Looped=true; courtMusic.Volume=0.2
 courtMusic.Parent=game:GetService("SoundService")
 -- Current court sessions share the Classic/Arcade soundtrack.
 local musicModes={Practice=true,["1V1"]=true,["1V2"]=true,["2V2"]=true,Classic=true,Arcade=true,CLASSIC=true,ARCADE=true}
 local cream=Color3.fromRGB(246,246,255)
 local dark=Color3.fromRGB(27,27,64)
 local gold=Color3.fromRGB(80,232,255)
 local panel=Instance.new("Frame",gui)
 panel.AnchorPoint=Vector2.new(0,0.5); panel.Position=UDim2.new(0,24,0.5,0)
 panel.Name="MatchMenu"; panel.Size=UDim2.fromOffset(420,680); panel.BackgroundColor3=dark; panel.BackgroundTransparency=0.02
 local corner=Instance.new("UICorner",panel); corner.CornerRadius=UDim.new(0,12)
 local stroke=Instance.new("UIStroke",panel); stroke.Color=Color3.new(1,1,1); stroke.Thickness=2
 local edge=Instance.new("UIGradient",stroke)
 edge.Color=ColorSequence.new(gold,Color3.fromRGB(255,85,200)); edge.Rotation=35
 local scale=Instance.new("UIScale",panel)
 local function label(value,y,height,size,color)
  local t=Instance.new("TextLabel",panel)
  t.Position=UDim2.fromOffset(24,y); t.Size=UDim2.new(1,-48,0,height)
  t.BackgroundTransparency=1; t.Font=Enum.Font.GothamMedium; t.TextSize=size
  t.TextColor3=color or cream; t.TextXAlignment=Enum.TextXAlignment.Left
  t.Text=value; t.TextWrapped=true
  return t
 end
 label("P A D D L E U P",22,24,14,gold)
 label("CHOOSE YOUR MODE",55,40,26).Name="Heading"
 label("01  /  GAME MODE",99,22,12,gold).Name="Step"
 local status=label("Choose a court experience.",600,56,13)
 status.TextColor3=Color3.fromRGB(181,187,225)
 local request=network:WaitForChild("Session")
 local menu=require(script.Parent:WaitForChild("MainMenuFlow")).start(player,network,panel,status)
 local function showModes() menu.reset() end
 local UIS=game:GetService("UserInputService")
 local exit=Instance.new("ImageButton",gui)
 exit.Name="ExitMatch"; exit.AnchorPoint=Vector2.new(1,0); exit.Position=UDim2.new(1,-12,0,16)
 exit.Size=UDim2.fromOffset(44,44); exit.BackgroundColor3=Color3.fromRGB(27,27,64)
 exit.BackgroundTransparency=1; exit.BorderSizePixel=0; exit.Image=""; exit.AutoButtonColor=false
 local exitKey=Instance.new("TextLabel",exit)
 exitKey.Name="LeaveKeybind"; exitKey.AnchorPoint=Vector2.new(0.5,0)
 exitKey.Position=UDim2.new(0.5,0,1,6); exitKey.Size=UDim2.fromOffset(28,24)
 exitKey.BackgroundTransparency=1; exitKey.BorderSizePixel=0; exitKey.Text="M"; exitKey.Font=Enum.Font.GothamBlack
 exitKey.TextSize=20; exitKey.TextColor3=Color3.fromRGB(246,246,255); exitKey.Visible=UIS.KeyboardEnabled
 local keyStroke=Instance.new("UIStroke",exitKey); keyStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
 keyStroke.Color=Color3.fromRGB(12,12,30); keyStroke.Thickness=2; keyStroke.Transparency=0
 -- Outline the symbol itself for contrast against both bright rocks and dark sky.
 local icon=Instance.new("Frame",exit)
 icon.Name="ExitIcon"; icon.AnchorPoint=Vector2.new(0.5,0.5); icon.Position=UDim2.fromScale(0.5,0.5)
 icon.Size=UDim2.fromOffset(24,24); icon.BackgroundTransparency=1
 local iconScale=Instance.new("UIScale",icon); iconScale.Scale=1.4
 local function iconLine(name,from,to)
  local delta=to-from
  local line=Instance.new("Frame",icon); line.Name=name; line.AnchorPoint=Vector2.new(0.5,0.5)
  line.Position=UDim2.fromOffset((from.X+to.X)/2,(from.Y+to.Y)/2)
  line.Size=UDim2.fromOffset(delta.Magnitude+3,3); line.Rotation=math.deg(math.atan2(delta.Y,delta.X))
  line.BackgroundColor3=Color3.fromRGB(255,85,200); line.BorderSizePixel=0; line.ZIndex=2
  local cap=Instance.new("UICorner",line); cap.CornerRadius=UDim.new(1,0)
  local outline=line:Clone(); outline.Name=name.."Outline"; outline.ZIndex=1
  outline.Size=UDim2.fromOffset(delta.Magnitude+6,6); outline.BackgroundColor3=Color3.fromRGB(12,12,30)
  outline.Parent=icon
 end
 -- Open door frame on the left; arrow points out through the opening to the right.
 iconLine("DoorTop",Vector2.new(4,4),Vector2.new(10,4))
 iconLine("DoorLeft",Vector2.new(4,4),Vector2.new(4,20))
 iconLine("DoorBottom",Vector2.new(4,20),Vector2.new(10,20))
 iconLine("DoorTopEdge",Vector2.new(10,4),Vector2.new(10,7))
 iconLine("DoorBottomEdge",Vector2.new(10,17),Vector2.new(10,20))
 iconLine("ArrowShaft",Vector2.new(10,12),Vector2.new(21,12))
 iconLine("ArrowTop",Vector2.new(17,8),Vector2.new(21,12))
 iconLine("ArrowBottom",Vector2.new(17,16),Vector2.new(21,12))
 local function exitHover(on)
  local color=on and Color3.fromRGB(80,232,255) or Color3.fromRGB(255,85,200)
  for _,line in ipairs(icon:GetChildren()) do
   if line:IsA("Frame") and line.ZIndex==2 then
    TweenService:Create(line,TweenInfo.new(0.15),{BackgroundColor3=color}):Play()
   end
  end
 end
 exit.MouseEnter:Connect(function() exitHover(true) end); exit.MouseLeave:Connect(function() exitHover(false) end)
 exit.SelectionGained:Connect(function() exitHover(true) end); exit.SelectionLost:Connect(function() exitHover(false) end)
 local overlay=Instance.new("TextButton",gui)
 overlay.Name="LeaveMatchOverlay"; overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0)
 overlay.BackgroundTransparency=0.5; overlay.BorderSizePixel=0; overlay.Text=""; overlay.AutoButtonColor=false
 overlay.Modal=true; overlay.Visible=false; overlay.ZIndex=10
 local card=Instance.new("Frame",overlay)
 card.Name="LeaveMatchDialog"; card.AnchorPoint=Vector2.new(0.5,0.5); card.Position=UDim2.fromScale(0.5,0.5)
 card.Size=UDim2.fromOffset(420,238); card.BackgroundColor3=Color3.fromRGB(26,28,51); card.BorderSizePixel=0; card.ZIndex=11
 local cardCorner=Instance.new("UICorner",card); cardCorner.CornerRadius=UDim.new(0,18)
 local cardStroke=Instance.new("UIStroke",card); cardStroke.Color=Color3.fromRGB(91,97,135); cardStroke.Thickness=1.5
 local dialogScale=Instance.new("UIScale",card)
 local function dialogText(value,y,height,size)
  local t=Instance.new("TextLabel",card); t.Position=UDim2.fromOffset(28,y); t.Size=UDim2.new(1,-56,0,height)
  t.BackgroundTransparency=1; t.Text=value; t.TextColor3=Color3.new(1,1,1); t.TextSize=size
  t.Font=Enum.Font.GothamMedium; t.TextWrapped=true; t.ZIndex=12; return t
 end
 dialogText("LEAVE MATCH?",24,32,24).Font=Enum.Font.GothamBold
 local description="Are you sure you want to return to the lobby? Your current match progress will be lost."
 local detail=dialogText(description,70,72,15); detail.TextColor3=Color3.fromRGB(190,201,212)
 local function dialogButton(value,x,color)
  local b=Instance.new("TextButton",card); b.Position=UDim2.fromOffset(x,164); b.Size=UDim2.fromOffset(170,46)
  b.BackgroundColor3=color; b.BorderSizePixel=0; b.Text=value; b.Font=Enum.Font.GothamBold
  b.TextSize=16; b.TextColor3=Color3.new(1,1,1); b.ZIndex=12
  local c=Instance.new("UICorner",b); c.CornerRadius=UDim.new(1,0); return b
 end
 local stay=dialogButton("STAY",28,Color3.fromRGB(39,42,71))
 local leave=dialogButton("LEAVE",222,Color3.fromRGB(220,50,50))
 local leaving=false
 local function closeDialog()
  overlay.Visible=false; player:SetAttribute("LeaveConfirmationOpen",false)
 end
 local function openDialog()
  if not exit.Visible or overlay.Visible then return end
  leaving=false; leave.Text="LEAVE"; leave.Active=true; detail.Text=description
  overlay.Visible=true; player:SetAttribute("LeaveConfirmationOpen",true)
  UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
 end
 exit.Activated:Connect(openDialog)
 stay.Activated:Connect(function() if not leaving then closeDialog() end end)
 leave.Activated:Connect(function()
  if leaving then return end
  leaving=true; leave.Text="LEAVING..."; leave.Active=false
  request:FireServer("Lobby")
 end)
 UIS.InputBegan:Connect(function(key,processed)
  if not processed and not UIS:GetFocusedTextBox() and key.KeyCode==Enum.KeyCode.M then openDialog() end
 end)
 local sessionConnection
 gui.Destroying:Connect(function()
  if sessionConnection then sessionConnection:Disconnect() end
  lobbyMusic:destroy()
  courtMusic:Destroy()
  player:SetAttribute("LeaveConfirmationOpen",false)
 end)
 local function refresh()
  local inLobby=player:GetAttribute("SessionMode")=="Lobby" or player:GetAttribute("SessionMode")==nil
  panel.Visible=inLobby; exit.Visible=not inLobby
  lobbyMusic:setActive(inLobby)
  if musicModes[player:GetAttribute("SessionMode")] then
   if not courtMusic.IsPlaying then courtMusic:Resume() end
  elseif courtMusic.IsPlaying then
   courtMusic:Pause()
  end
  if inLobby then closeDialog(); leaving=false end
  if inLobby then showModes() end
 end
 sessionConnection=player:GetAttributeChangedSignal("SessionMode"):Connect(refresh)
 request.OnClientEvent:Connect(function(ok,message)
  status.Text=message
  if leaving then
   leaving=false; leave.Text="LEAVE"; leave.Active=true
   if ok then closeDialog() else detail.Text=message end
  end
  if ok then refresh() end
 end)
 local function resize()
  local camera=workspace.CurrentCamera
  if camera then
   scale.Scale=math.min(1,(camera.ViewportSize.Y-40)/680,(camera.ViewportSize.X-48)/420)
   dialogScale.Scale=math.min(1,(camera.ViewportSize.X-32)/420,(camera.ViewportSize.Y-32)/238)
  end
 end
 game:GetService("RunService").RenderStepped:Connect(resize)
 refresh(); resize()
end
return MainMenu
