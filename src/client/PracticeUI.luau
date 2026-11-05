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
 toolbar.Name="Toolbar"; toolbar.Size=UDim2.fromOffset(214,50)
 toolbar.BackgroundTransparency=1; toolbar.ZIndex=2
 local scale=Instance.new("UIScale",toolbar)
 local function button(parent,name,text,position,size)
  local b=Instance.new("TextButton",parent)
  b.Name=name; b.Text=text; b.Position=position; b.Size=size
  b.Font=Enum.Font.GothamBold; b.TextSize=12; b.TextColor3=white
  b.BackgroundColor3=dark; b.BorderSizePixel=0; b.ZIndex=3
  Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
  local stroke=Instance.new("UIStroke",b); stroke.Color=cyan; stroke.Transparency=0.25
  return b
 end
 local mode=button(toolbar,"Mode","NORMAL  v",UDim2.fromOffset(0,0),UDim2.fromOffset(126,34))
 local pause=button(toolbar,"Pause","PAUSE",UDim2.fromOffset(134,0),UDim2.fromOffset(80,34))
 local help=Instance.new("TextLabel",toolbar)
 help.Name="Help"; help.Text="Alt to click · P to pause"
 help.Position=UDim2.fromOffset(0,38); help.Size=UDim2.fromOffset(214,12)
 help.TextXAlignment=Enum.TextXAlignment.Right; help.TextTransparency=0.25
 help.Font=Enum.Font.GothamMedium; help.TextSize=9; help.TextColor3=white
 help.BackgroundTransparency=1; help.ZIndex=3
 local menu=Instance.new("Frame",toolbar)
 menu.Name="Dropdown"; menu.Position=UDim2.fromOffset(0,-122); menu.Size=UDim2.fromOffset(126,114)
 menu.BackgroundColor3=dark; menu.BorderSizePixel=0; menu.Visible=false; menu.ZIndex=4
 Instance.new("UICorner",menu).CornerRadius=UDim.new(0,8)
 local border=Instance.new("UIStroke",menu); border.Color=cyan; border.Transparency=0.25
 local latest,pendingRevision,pendingDifficulty=nil,nil,nil
 local function setOpen(open)
  menu.Visible=open; dismiss.Visible=open; help.Visible=not open
  help.Visible=not open and UIS.KeyboardEnabled
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
  local b=button(menu,name,name,UDim2.fromOffset(6,6+(index-1)*34),UDim2.fromOffset(114,32))
  b.ZIndex=5
  b:FindFirstChildOfClass("UIStroke").Enabled=false
  b.Activated:Connect(function()
   setOpen(false)
   if latest and latest.difficulty~=name and request("Difficulty",name) then
    pendingDifficulty=name; mode.Text=string.upper(name).."  v"
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
  mode.Text=string.upper(difficulty).."  v"
  pause.Text=latest.paused and "CONTINUE" or "PAUSE"
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
  scale.Scale=math.min(1,(viewport.X-24)/214)
  toolbar.AnchorPoint=Vector2.new(1,1)
  toolbar.Position=UDim2.new(1,-18,1,-18)
  indicator.Position=UDim2.fromOffset(viewport.X/2,viewport.Y*0.32)
 end)
 visibility()
end
return PracticeUI
