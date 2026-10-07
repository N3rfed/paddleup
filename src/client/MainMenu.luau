-- Presentation only: server owns admission and existing court gameplay.
local MainMenu={}
function MainMenu.start(player,network)
 local TweenService=game:GetService("TweenService")
 local gui=Instance.new("ScreenGui")
 gui.Name="PaddleUpMenu"; gui.ResetOnSpawn=false; gui.DisplayOrder=20
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
 local back=Instance.new("TextButton",gui)
 back.AnchorPoint=Vector2.new(0.5,0); back.Position=UDim2.new(0.5,0,0,12)
 back.Size=UDim2.fromOffset(180,36); back.BackgroundColor3=dark; back.TextColor3=cream
 back.Text="LOBBY  /  M"; back.Font=Enum.Font.GothamBold; back.TextSize=12
 local c=Instance.new("UICorner",back); c.CornerRadius=UDim.new(0,10)
 back.Activated:Connect(function() request:FireServer("Lobby") end)
 game:GetService("UserInputService").InputBegan:Connect(function(key,processed)
  if not processed and key.KeyCode==Enum.KeyCode.M and back.Visible then request:FireServer("Lobby") end
 end)
 local function refresh()
  local inLobby=player:GetAttribute("SessionMode")=="Lobby" or player:GetAttribute("SessionMode")==nil
  panel.Visible=inLobby; back.Visible=not inLobby
  if inLobby then pending=false; status.Text="Choose a court experience. Elevators open in a future update." end
 end
 player:GetAttributeChangedSignal("SessionMode"):Connect(refresh)
 request.OnClientEvent:Connect(function(ok,message)
  pending=false; status.Text=message
  if ok then refresh() end
 end)
 local function resize()
  local camera=workspace.CurrentCamera
  if camera then scale.Scale=math.min(1,(camera.ViewportSize.Y-40)/500,(camera.ViewportSize.X-48)/350) end
 end
 game:GetService("RunService").RenderStepped:Connect(resize)
 refresh(); resize()
end
return MainMenu
