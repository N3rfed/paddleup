-- Presentation only: server owns admission and existing court gameplay.
local MainMenu={}
function MainMenu.start(player,network)
 local TweenService=game:GetService("TweenService")
 local gui=Instance.new("ScreenGui")
 gui.Name="PaddleUpMenu"; gui.ResetOnSpawn=false; gui.DisplayOrder=20; gui.IgnoreGuiInset=true
 gui.Parent=player:WaitForChild("PlayerGui")
 local cream=Color3.fromRGB(240,232,213)
 local dark=Color3.fromRGB(28,47,49)
 local gold=Color3.fromRGB(190,153,91)
 local panel=Instance.new("Frame",gui)
 panel.AnchorPoint=Vector2.new(0,0.5); panel.Position=UDim2.new(0,24,0.5,0)
 panel.Size=UDim2.fromOffset(350,500); panel.BackgroundColor3=dark; panel.BackgroundTransparency=0.06
 local corner=Instance.new("UICorner",panel); corner.CornerRadius=UDim.new(0,16)
 local stroke=Instance.new("UIStroke",panel); stroke.Color=gold; stroke.Transparency=0.4
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
 label("Skyline Club",55,40,30)
 label("THE PENTHOUSE  /  PLAY & UNWIND",99,22,11,gold)
 local status=label("Choose a court experience. Elevators open in a future update.",410,65,13)
 local request=network:WaitForChild("Session")
 local pending=false
 local buttons={}
 for index,item in ipairs({
  {"PRACTICE","Warm up with the practice partner","Practice"},
  {"1V1","Join this server's singles court","1V1"},
  {"2V2","Join this server's doubles court","2V2"},
  {"SPECTATE","Watch the rooftop court","Spectate"},
 }) do
  local b=Instance.new("TextButton",panel)
  b.Position=UDim2.fromOffset(24,140+(index-1)*66); b.Size=UDim2.new(1,-48,0,56)
  b.BackgroundColor3=Color3.fromRGB(43,65,66); b.Text=""; b.AutoButtonColor=false
  b.Selectable=true; buttons[index]=b
  local c=Instance.new("UICorner",b); c.CornerRadius=UDim.new(0,10)
  for line=1,2 do
   local t=Instance.new("TextLabel",b); t.BackgroundTransparency=1
   t.Position=UDim2.fromOffset(16,line==1 and 7 or 29); t.Size=UDim2.new(1,-32,0,20)
   t.Font=line==1 and Enum.Font.GothamBold or Enum.Font.GothamMedium
   t.TextSize=line==1 and 17 or 11; t.TextColor3=line==1 and cream or gold
   t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=item[line]
  end
  local function hover(on)
   TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(62,99,95) or Color3.fromRGB(43,65,66)}):Play()
  end
  b.MouseEnter:Connect(function() hover(true) end); b.MouseLeave:Connect(function() hover(false) end)
  b.SelectionGained:Connect(function() hover(true) end); b.SelectionLost:Connect(function() hover(false) end)
  b.Activated:Connect(function()
   if pending then return end
   pending=true; status.Text="Connecting to the rooftop..."
   request:FireServer(item[3])
   task.delay(5,function() if pending then pending=false; status.Text="No response yet. Please try again." end end)
  end)
 end
 local UIS=game:GetService("UserInputService")
 local exit=Instance.new("ImageButton",gui)
 exit.Name="ExitMatch"; exit.AnchorPoint=Vector2.new(1,0); exit.Position=UDim2.new(1,-24,0,24)
 exit.Size=UDim2.fromOffset(42,42); exit.BackgroundColor3=Color3.fromRGB(15,23,30)
 exit.BackgroundTransparency=0.2; exit.BorderSizePixel=0; exit.Image=""; exit.AutoButtonColor=false
 local exitCorner=Instance.new("UICorner",exit); exitCorner.CornerRadius=UDim.new(1,0)
 local exitStroke=Instance.new("UIStroke",exit); exitStroke.Color=Color3.fromRGB(34,50,66); exitStroke.Thickness=1.5
 -- Draw the log-out symbol directly so its silhouette does not depend on an asset.
 local icon=Instance.new("Frame",exit)
 icon.Name="ExitIcon"; icon.AnchorPoint=Vector2.new(0.5,0.5); icon.Position=UDim2.fromScale(0.5,0.5)
 icon.Size=UDim2.fromOffset(24,24); icon.BackgroundTransparency=1
 local function iconLine(name,from,to)
  local delta=to-from
  local line=Instance.new("Frame",icon); line.Name=name; line.AnchorPoint=Vector2.new(0.5,0.5)
  line.Position=UDim2.fromOffset((from.X+to.X)/2,(from.Y+to.Y)/2)
  line.Size=UDim2.fromOffset(delta.Magnitude+2,2); line.Rotation=math.deg(math.atan2(delta.Y,delta.X))
  line.BackgroundColor3=Color3.fromRGB(255,255,255); line.BorderSizePixel=0
  local cap=Instance.new("UICorner",line); cap.CornerRadius=UDim.new(1,0)
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
  TweenService:Create(exit,TweenInfo.new(0.15),{BackgroundColor3=on and Color3.fromRGB(50,20,24) or Color3.fromRGB(15,23,30)}):Play()
  TweenService:Create(exitStroke,TweenInfo.new(0.15),{Color=on and Color3.fromRGB(112,137,155) or Color3.fromRGB(34,50,66)}):Play()
 end
 exit.MouseEnter:Connect(function() exitHover(true) end); exit.MouseLeave:Connect(function() exitHover(false) end)
 exit.SelectionGained:Connect(function() exitHover(true) end); exit.SelectionLost:Connect(function() exitHover(false) end)
 local overlay=Instance.new("TextButton",gui)
 overlay.Name="LeaveMatchOverlay"; overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0)
 overlay.BackgroundTransparency=0.5; overlay.BorderSizePixel=0; overlay.Text=""; overlay.AutoButtonColor=false
 overlay.Modal=true; overlay.Visible=false; overlay.ZIndex=10
 local card=Instance.new("Frame",overlay)
 card.Name="LeaveMatchDialog"; card.AnchorPoint=Vector2.new(0.5,0.5); card.Position=UDim2.fromScale(0.5,0.5)
 card.Size=UDim2.fromOffset(420,238); card.BackgroundColor3=Color3.fromRGB(15,23,30); card.BorderSizePixel=0; card.ZIndex=11
 local cardCorner=Instance.new("UICorner",card); cardCorner.CornerRadius=UDim.new(0,18)
 local cardStroke=Instance.new("UIStroke",card); cardStroke.Color=Color3.fromRGB(34,50,66); cardStroke.Thickness=1.5
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
 local stay=dialogButton("STAY",28,Color3.fromRGB(25,35,45))
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
 gui.Destroying:Connect(function() player:SetAttribute("LeaveConfirmationOpen",false) end)
 local function refresh()
  local inLobby=player:GetAttribute("SessionMode")=="Lobby" or player:GetAttribute("SessionMode")==nil
  panel.Visible=inLobby; exit.Visible=not inLobby
  if inLobby then closeDialog(); leaving=false end
  if inLobby then pending=false; status.Text="Choose a court experience. Elevators open in a future update." end
 end
 player:GetAttributeChangedSignal("SessionMode"):Connect(refresh)
 request.OnClientEvent:Connect(function(ok,message)
  pending=false; status.Text=message
  if leaving then
   leaving=false; leave.Text="LEAVE"; leave.Active=true
   if ok then closeDialog() else detail.Text=message end
  end
  if ok then refresh() end
 end)
 local function resize()
  local camera=workspace.CurrentCamera
  if camera then
   scale.Scale=math.min(1,(camera.ViewportSize.Y-40)/500,(camera.ViewportSize.X-48)/350)
   dialogScale.Scale=math.min(1,(camera.ViewportSize.X-32)/420,(camera.ViewportSize.Y-32)/238)
  end
 end
 game:GetService("RunService").RenderStepped:Connect(resize)
 refresh(); resize()
end
return MainMenu
