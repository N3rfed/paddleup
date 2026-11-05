local Help={}
local Assets=require(script.Parent:WaitForChild("FigmaAssets"))
function Help.start(player,network)
 local UIS=game:GetService("UserInputService")
 local CAS=game:GetService("ContextActionService")
 local GuiService=game:GetService("GuiService")
 local RunService=game:GetService("RunService")
 local gui=Instance.new("ScreenGui")
 gui.Name="HowToPlay"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=90
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild("PlayerGui")
 local help=Instance.new("ImageButton",gui)
 help.Name="HelpButton"; help.Image=""; help.Size=UDim2.fromOffset(36,36)
 help.AnchorPoint=Vector2.new(1,0); help.Position=UDim2.new(1,-52,0,16)
 help.BackgroundTransparency=1; help.AutoButtonColor=false; help.Visible=false
 local icon=Instance.new("ImageLabel",help)
 icon.Name="HelpIcon"; icon.Image=Assets.get("help"); icon.BackgroundTransparency=1
 icon.Position=UDim2.fromOffset(6,6); icon.Size=UDim2.fromOffset(24,24); icon.ZIndex=2
 icon.ScaleType=Enum.ScaleType.Fit
 -- Expand the alpha silhouette, outlining the circle and question mark rather than the button box.
 for index,offset in ipairs({{-1,-1},{0,-1},{1,-1},{-1,0},{1,0},{-1,1},{0,1},{1,1}}) do
  local outline=icon:Clone(); outline.Name="IconOutline"..index; outline.ZIndex=1
  outline.ImageColor3=Color3.fromRGB(12,12,30)
  outline.Position=UDim2.fromOffset(6+offset[1],6+offset[2]); outline.Parent=help
 end
 local hint=Instance.new("TextLabel",help)
 hint.Name="KeyHint"; hint.Text="H"; hint.Font=Enum.Font.GothamBlack; hint.TextSize=14
 hint.TextColor3=Color3.fromRGB(246,246,255); hint.BackgroundTransparency=1
 hint.AnchorPoint=Vector2.new(0.5,0); hint.Position=UDim2.new(0.5,0,1,2)
 hint.Size=UDim2.fromOffset(22,20); hint.Visible=UIS.KeyboardEnabled
 local keyStroke=Instance.new("UIStroke",hint); keyStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
 keyStroke.Color=Color3.fromRGB(12,12,30); keyStroke.Thickness=1.5
 local overlay=Instance.new("TextButton",gui)
 overlay.Name="Overlay"; overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.fromRGB(4,7,18)
 overlay.BackgroundTransparency=0.3; overlay.Text=""; overlay.AutoButtonColor=false
 overlay.Selectable=false; overlay.Modal=true; overlay.Visible=false; overlay.ZIndex=2
 local panel=Instance.new("Frame",overlay)
 panel.Name="Panel"; panel.BackgroundTransparency=1; panel.Size=UDim2.fromOffset(1715,856)
 panel.Position=UDim2.fromScale(0.5,0.5); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.ZIndex=3
 local scale=Instance.new("UIScale",panel)
 local art=Assets.image(panel,"howToPlay",0,0,1715,856); art.ScaleType=Enum.ScaleType.Fit; art.ZIndex=3
 task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({art,icon}) end) end)
 local function button(name,label,x,y,w,h)
  local b=Instance.new("TextButton",panel); b.Name=name; b.Text=label; b.TextTransparency=1
  b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(w,h); b.BackgroundTransparency=1
  b.AutoButtonColor=false; b.ZIndex=4
  return b
 end
 local close=button("Close","Close instructions",1620,25,75,75)
 local play=button("Play","Play",1338,724,328,52)
 local action="PaddleUpHelp_"..game:GetService("HttpService"):GenerateGUID(false)
 local opened,introducing,previousSelection=false,false,nil
 local playingModes={Practice=true,["1V1"]=true,["1V2"]=true,["2V2"]=true}
 local function blocked()
  return not playingModes[player:GetAttribute("SessionMode")] or introducing
   or player:GetAttribute("PowerupDraftOpen")==true or player:GetAttribute("LeaveConfirmationOpen")==true
 end
 local function setOpen(value)
  if value and blocked() then return end
  if opened==value then return end
  opened=value; overlay.Visible=value; player:SetAttribute("HowToPlayOpen",value)
  if value then
   previousSelection=GuiService.SelectedObject
   CAS:BindActionAtPriority(action,function() return Enum.ContextActionResult.Sink end,false,3000,
    Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,
    Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Space,Enum.KeyCode.LeftShift,
    Enum.KeyCode.Q,Enum.KeyCode.E,Enum.KeyCode.F,Enum.KeyCode.R,Enum.KeyCode.X,Enum.KeyCode.Thumbstick1)
   if UIS.GamepadEnabled then GuiService.SelectedObject=play end
  else
   CAS:UnbindAction(action)
   if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(panel) then
    GuiService.SelectedObject=previousSelection and previousSelection.Parent and previousSelection or nil
   end
  end
 end
 local function refresh()
  help.Visible=not blocked()
  if blocked() then setOpen(false) end
 end
 help.Activated:Connect(function() setOpen(not opened) end)
 close.Activated:Connect(function() setOpen(false) end)
 play.Activated:Connect(function() setOpen(false) end)
 local keys=UIS.InputBegan:Connect(function(input,processed)
  if UIS:GetFocusedTextBox() then return end
  if not processed and input.KeyCode==Enum.KeyCode.H then setOpen(not opened)
  elseif opened and input.KeyCode==Enum.KeyCode.ButtonB then setOpen(false) end
 end)
 local state=network:WaitForChild("State").OnClientEvent:Connect(function(data)
  introducing=data.matchIntro~=nil
  refresh()
 end)
 local attributes={}
 for _,name in ipairs({"SessionMode","PowerupDraftOpen","LeaveConfirmationOpen"}) do
  table.insert(attributes,player:GetAttributeChangedSignal(name):Connect(refresh))
 end
 local frames=RunService.RenderStepped:Connect(function()
  if not opened then return end
  local camera=workspace.CurrentCamera
  if camera then scale.Scale=math.max(0.1,math.min((camera.ViewportSize.X-48)/1715,(camera.ViewportSize.Y-48)/856)) end
 end)
 gui.Destroying:Connect(function()
  keys:Disconnect(); state:Disconnect(); frames:Disconnect()
  for _,connection in ipairs(attributes) do connection:Disconnect() end
  CAS:UnbindAction(action); player:SetAttribute("HowToPlayOpen",false)
 end)
 player:SetAttribute("HowToPlayOpen",false)
 refresh()
 return {setOpen=setOpen,isOpen=function() return opened end}
end
return Help
