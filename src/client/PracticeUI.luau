-- Server snapshots own difficulty, pause state, and bot countdown display.
local PracticeUI={}
function PracticeUI.start(player,network)
 local UIS=game:GetService("UserInputService")
 local remote=network:WaitForChild("Practice")
 local playerGui=player:WaitForChild("PlayerGui")
 local gui=Instance.new("ScreenGui")
 gui.Name="PracticeControls"; gui.ResetOnSpawn=false; gui.DisplayOrder=50
 gui.IgnoreGuiInset=true; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui.Parent=playerGui; gui.Enabled=false
 local dark=Color3.fromRGB(27,27,64)
 local cyan=Color3.fromRGB(80,232,255)
 local white=Color3.fromRGB(246,246,255)
 local dismiss=Instance.new("TextButton",gui)
 dismiss.Name="Dismiss"; dismiss.Size=UDim2.fromScale(1,1)
 dismiss.BackgroundTransparency=1; dismiss.Text=""; dismiss.Visible=false; dismiss.ZIndex=1
 local toolbar=Instance.new("Frame",gui)
 toolbar.Name="Toolbar"; toolbar.Size=UDim2.fromOffset(144,102)
 toolbar.BackgroundTransparency=1; toolbar.ZIndex=2
 local scale=Instance.new("UIScale",toolbar)
 local function button(parent,name,text,position,size)
  local b=Instance.new("TextButton",parent)
  b.Name=name; b.Text=text; b.Position=position; b.Size=size
  b.Font=Enum.Font.GothamBold; b.TextSize=14; b.TextColor3=white
  b.BackgroundColor3=dark; b.BorderSizePixel=0; b.ZIndex=3
  Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
  local stroke=Instance.new("UIStroke",b); stroke.Color=cyan; stroke.Transparency=0.25
  return b
 end
 local mode=button(toolbar,"Mode","Mode: Normal",UDim2.fromOffset(0,0),UDim2.fromOffset(144,34))
 local pause=button(toolbar,"Pause","Pause",UDim2.fromOffset(0,42),UDim2.fromOffset(144,34))
 local help=Instance.new("TextLabel",toolbar)
 help.Name="Help"; help.Text="Alt to click · P to pause"
 help.Position=UDim2.fromOffset(0,82); help.Size=UDim2.fromOffset(144,18)
 help.Font=Enum.Font.GothamMedium; help.TextSize=9; help.TextColor3=white
 help.BackgroundTransparency=1; help.ZIndex=3
 local menu=Instance.new("Frame",toolbar)
 menu.Name="Dropdown"; menu.Position=UDim2.fromOffset(0,40); menu.Size=UDim2.fromOffset(144,114)
 menu.BackgroundColor3=dark; menu.BorderSizePixel=0; menu.Visible=false; menu.ZIndex=4
 Instance.new("UICorner",menu).CornerRadius=UDim.new(0,8)
 local border=Instance.new("UIStroke",menu); border.Color=cyan; border.Transparency=0.25
 local latest,pendingRevision,pendingDifficulty=nil,nil,nil
 local function setOpen(open)
  menu.Visible=open; dismiss.Visible=open; help.Visible=not open
  pause.Position=UDim2.fromOffset(0,open and 162 or 42)
  player:SetAttribute("PracticeMenuOpen",open)
 end
 local function request(action,value)
  if pendingRevision or not latest or player:GetAttribute("SessionMode")~="Practice" then return false end
  pendingRevision=latest.revision
  remote:FireServer(action,value,latest.revision)
  return true
 end
 local buttons={}
 for index,name in ipairs({"Easy","Normal","Hard"}) do
  local b=button(menu,name,name,UDim2.fromOffset(6,6+(index-1)*34),UDim2.fromOffset(132,32))
  b.ZIndex=5
  b:FindFirstChildOfClass("UIStroke").Enabled=false
  b.Activated:Connect(function()
   setOpen(false)
   if latest and latest.difficulty~=name and request("Difficulty",name) then
    pendingDifficulty=name; mode.Text="Mode: "..name
   end
  end)
  buttons[name]=b
 end
 mode.Activated:Connect(function() setOpen(not menu.Visible) end)
 dismiss.Activated:Connect(function() setOpen(false) end)
 pause.Activated:Connect(function()
  setOpen(false)
  if latest then request("Paused",not latest.paused) end
 end)
 local indicator=Instance.new("TextLabel",gui)
 indicator.Name="Countdown"; indicator.Size=UDim2.fromOffset(340,100)
 indicator.AnchorPoint=Vector2.new(0.5,0.5); indicator.Position=UDim2.fromScale(0.5,0.32)
 indicator.BackgroundTransparency=1; indicator.TextColor3=white
 indicator.Font=Enum.Font.GothamBold; indicator.TextSize=44
 indicator.TextStrokeTransparency=0.25; indicator.Visible=false; indicator.ZIndex=2
 local function getScoreboard()
  local figma=playerGui:FindFirstChild("FigmaHUD")
  local score=figma and figma:FindFirstChild("Scoreboard")
  if not score then
   local legacy=playerGui:FindFirstChild("PaddleUpHUD")
   score=legacy and legacy:FindFirstChild("Score",true)
  end
  return score
 end
 local function scoreboardVisible(score)
  if not score then return false end
  local ancestor=score
  while ancestor and ancestor~=playerGui do
   if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
   if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
   ancestor=ancestor.Parent
  end
  return ancestor==playerGui
 end
 local function visibility(score)
  local inPractice=player:GetAttribute("SessionMode")=="Practice"
  gui.Enabled=inPractice and scoreboardVisible(score or getScoreboard())
  if not gui.Enabled then setOpen(false) end
  if not inPractice then
   latest=nil; pendingRevision=nil; pendingDifficulty=nil
   indicator.Visible=false
  end
 end
 player:GetAttributeChangedSignal("SessionMode"):Connect(visibility)
 network:WaitForChild("State").OnClientEvent:Connect(function(data)
  if player:GetAttribute("SessionMode")~="Practice" or not data.practice then return end
  latest=data.practice
  if pendingRevision and latest.revision~=pendingRevision then
   pendingRevision=nil; pendingDifficulty=nil
  end
  local difficulty=pendingDifficulty or latest.difficulty
  mode.Text="Mode: "..difficulty
  pause.Text=latest.paused and "Continue" or "Pause"
  for name,b in pairs(buttons) do
   b.BackgroundColor3=name==difficulty and Color3.fromRGB(48,99,132) or dark
   b.TextColor3=name==difficulty and cyan or white
  end
  indicator.Visible=latest.paused or latest.countdown~=nil or latest.serve
  indicator.Text=latest.paused and "PAUSED" or latest.serve and "Serve!" or latest.countdown and ("BOT SERVE\n"..latest.countdown) or ""
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if player:GetAttribute("SessionMode")~="Practice" then return end
  if input.KeyCode==Enum.KeyCode.Escape and menu.Visible then setOpen(false); return end
  if processed or UIS:GetFocusedTextBox() then return end
  if input.KeyCode==Enum.KeyCode.P and latest then setOpen(false); request("Paused",not latest.paused) end
 end)
 UIS.WindowFocusReleased:Connect(function() setOpen(false) end)
 game:GetService("RunService").RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if not camera then return end
  local score=getScoreboard()
  visibility(score)
  if not gui.Enabled then return end
  local viewport=camera.ViewportSize
  scale.Scale=math.clamp(viewport.X/1500,0.8,1)
  local width=144*scale.Scale
  local origin=gui.AbsolutePosition
  local x,y=viewport.X-width-16,20
  if score then
   local position,size=score.AbsolutePosition,score.AbsoluteSize
   local right=position.X+size.X
   x=right+12; y=math.max(position.Y+size.Y*0.33-17*scale.Scale,origin.Y+62)
   -- Leave the top-right corner to Roblox player-list controls.
   if x+width>viewport.X-170 then
    x=12 -- Keep the compact stack clear of centered match announcements.
    y=position.Y+size.Y+8
   end
  end
  toolbar.Position=UDim2.fromOffset(x-origin.X,y-origin.Y)
  -- Keep the countdown clear of the controls and popup on narrow viewports.
  local indicatorY=viewport.Y*0.32
  if x<viewport.X/2+170 and x+width>viewport.X/2-170 then
   local controlsHeight=menu.Visible and 196 or 76
   indicatorY=math.max(indicatorY,y-origin.Y+controlsHeight*scale.Scale+55)
  end
  indicator.Position=UDim2.fromOffset(viewport.X/2,indicatorY)
 end)
 visibility()
end
return PracticeUI
