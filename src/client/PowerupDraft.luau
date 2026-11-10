local PowerupDraft={}
local Art=require(script.Parent:WaitForChild("PowerupArt"))
local FigmaAssets=require(script.Parent:WaitForChild("FigmaAssets"))
function PowerupDraft.start(player,network)
 require(script.Parent:WaitForChild("PowerupBuild")).start(player,network)
 local TweenService=game:GetService("TweenService")
 local RunService=game:GetService("RunService")
 local UIS=game:GetService("UserInputService")
 local GuiService=game:GetService("GuiService")
 local remote=network:WaitForChild("Powerup")
 local gui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
 gui.Name="PowerupDraft"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=70
 local function frame(parent,size,position,color)
  local f=Instance.new("Frame",parent); f.Size=size; f.Position=position
  f.BackgroundColor3=color; f.BorderSizePixel=0; return f
 end
 local function text(parent,value,y,height,size,color)
  local t=Instance.new("TextLabel",parent); t.BackgroundTransparency=1
  t.Position=UDim2.new(0,16,0,y); t.Size=UDim2.new(1,-32,0,height)
  t.Font=Enum.Font.GothamBold; t.TextSize=size; t.TextColor3=color
  t.Text=value; t.TextWrapped=true; return t
 end
 local overlay=Instance.new("TextButton",gui)
 overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.fromRGB(16,19,46)
 overlay.BackgroundTransparency=0.03; overlay.Text=""; overlay.AutoButtonColor=false
 overlay.Modal=true; overlay.Selectable=false; overlay.Visible=false
 local panel=frame(overlay,UDim2.fromOffset(940,560),UDim2.fromScale(0.5,0.5),Color3.new())
 panel.AnchorPoint=Vector2.new(0.5,0.5); panel.BackgroundTransparency=1
 local scale=Instance.new("UIScale",panel)
 local eyebrow=text(panel,"C H A O S   P O W E R U P S",0,25,12,Color3.fromRGB(170,186,210))
 local title=text(panel,"CHOOSE A POWERUP",32,48,34,Color3.fromRGB(246,247,255))
 local subtitle=text(panel,"Choose an upgrade for your build.",83,30,14,Color3.fromRGB(170,186,210))
 local cards=frame(panel,UDim2.fromOffset(908,362),UDim2.fromOffset(16,132),Color3.new())
 cards.BackgroundTransparency=1
 local footer=text(panel,"",508,24,14,Color3.fromRGB(226,232,245))
 local hint=text(panel,"COLLECT POWERUPS  /  ACTIVATE WITH Q OR E",540,18,10,Color3.fromRGB(126,145,173))
 local active=nil
 local selected=false
 local buttons={}
 local previousSelection=nil
 local function choose(index)
  if player:GetAttribute("PracticePaused") or not active or selected or player:GetAttribute("LeaveConfirmationOpen") or not active.cards[index] then return end
  selected=true
  footer.Text="Confirming selection..."
  remote:FireServer(active.id,active.cards[index].id)
 end
 local function close()
  overlay.Visible=false; active=nil; selected=false
  if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(cards) then
   GuiService.SelectedObject=previousSelection and previousSelection.Parent and previousSelection or nil
  end
 end
 local function show(data)
  close(); cards:ClearAllChildren(); table.clear(buttons)
  active=data; overlay.Visible=true
  previousSelection=GuiService.SelectedObject
  local color=Color3.fromRGB(80,232,255)
  title.Text="CHOOSE A POWERUP"; title.TextColor3=Color3.fromRGB(246,247,255)
  subtitle.Text="CHOOSE A POWERUP"
  subtitle.TextColor3=color
  local arcade=data.mode=="Arcade"
  overlay.BackgroundTransparency=arcade and 0.03 or 0
  eyebrow.Visible=true; title.Visible=true; hint.Visible=true
  cards.Position=UDim2.fromOffset(16,132)
  subtitle.Position=UDim2.new(0,16,0,83); subtitle.Size=UDim2.new(1,-32,0,30); subtitle.TextSize=14
  footer.TextSize=14
  panel.Size=UDim2.fromOffset(arcade and 1100 or 940,arcade and 620 or 560)
  cards.Size=UDim2.fromOffset(arcade and 1060 or 908,arcade and 410 or 362)
  footer.Position=UDim2.new(0,16,0,arcade and 552 or 508)
  hint.Position=UDim2.new(0,16,0,arcade and 590 or 540)
  eyebrow.Text=arcade and "Y O U R   D E C K" or "C H A O S   P O W E R U P S"
  hint.Text=arcade and "CHOOSE A CARD  /  EQUIP A FREE SLOT  /  ACTIVATE WITH Q OR E" or "COLLECT POWERUPS  /  ACTIVATE WITH Q OR E"
  if arcade then
   title.Text="CHOOSE A POWERUP"
   subtitle.Text="Choose one card for your Q / E slots"; subtitle.TextColor3=Color3.fromRGB(181,187,225)
   for index,card in ipairs(data.cards) do
    local b=Instance.new("TextButton",cards); buttons[index]=b; b.Name="Powerup"..index
    b.Position=UDim2.fromOffset((index-1)*360,0); b.Size=UDim2.fromOffset(340,340*622/569)
    b.BackgroundTransparency=1; b.Text=""; b.AutoButtonColor=false
    local content=Instance.new("Frame",b); content.Name="Content"; content.Size=UDim2.fromOffset(569,622); content.BackgroundTransparency=1
    local contentScale=Instance.new("UIScale",content); contentScale.Scale=340/569
    FigmaAssets.card(content,569)
    local icon=FigmaAssets.image(content,card.art,144,55,280,280); if icon then icon.ScaleType=Enum.ScaleType.Fit end
    local name=text(content,card.name:upper(),350,84,46,Color3.fromRGB(246,246,255)); name.Font=Enum.Font.GothamBlack
    local description=text(content,card.blurb,445,46,34,Color3.fromRGB(202,215,232)); description.TextWrapped=false
    local action=text(content,"SELECT",510,74,30,Color3.fromRGB(246,246,255)); action.Name="CardAction"
    b.Activated:Connect(function() choose(index) end)
   end
   if UIS.GamepadEnabled then GuiService.SelectedObject=buttons[1] end
   return
  end
  -- Chaos drafts permanent upgrades into a match-long build.
  panel.Size=UDim2.fromOffset(1920,1080)
  cards.Position=UDim2.fromOffset(80,235); cards.Size=UDim2.fromOffset(1760,620)
  eyebrow.Visible=false; title.Visible=false; hint.Visible=false
  subtitle.Position=UDim2.fromOffset(16,175); subtitle.Size=UDim2.new(1,-32,0,34)
  local tierColor=Color3.fromRGB(80,232,255)
  subtitle.Text="CHAOS  /  UPGRADE YOUR POWERUPS  /  LASTS ALL MATCH"; subtitle.TextSize=24
  subtitle.TextColor3=tierColor
  footer.Position=UDim2.fromOffset(16,850); footer.TextSize=22
  for index,card in ipairs(data.cards) do
   local b=Instance.new("TextButton",cards); buttons[index]=b; b.Name="Powerup"..index
   b.Position=UDim2.fromOffset((index-1)*610,0); b.Size=UDim2.fromOffset(540,540*622/569)
   b.BackgroundTransparency=1; b.Text=""; b.AutoButtonColor=false
   local hoverScale=Instance.new("UIScale",b)
   local content=Instance.new("Frame",b); content.Name="Content"; content.Size=UDim2.fromOffset(569,622); content.BackgroundTransparency=1
   local contentScale=Instance.new("UIScale",content); contentScale.Scale=540/569
   FigmaAssets.card(content,569)
   local art=frame(content,UDim2.fromOffset(126,126),UDim2.fromOffset(144,40),color)
   art.Name="PowerupArt"; art.BackgroundTransparency=1
   local artScale=Instance.new("UIScale",art); artScale.Scale=280/126
   Art.draw(art,card,tierColor)
   local name=text(content,card.name:upper(),330,84,44,Color3.fromRGB(246,247,255)); name.Name="Title"; name.Font=Enum.Font.GothamBlack
   local level=text(content,card.levelLabel or "",404,25,18,tierColor); level.Name="Level"
   local description=text(content,card.description or card.blurb,438,66,20,Color3.fromRGB(202,215,232)); description.Name="Description"; description.Font=Enum.Font.GothamMedium
   local action=text(content,"ADD TO BUILD",510,74,30,Color3.fromRGB(246,246,255)); action.Name="CardAction"
   local function hover(on)
    TweenService:Create(hoverScale,TweenInfo.new(0.15),{Scale=on and not selected and 1.015 or 1}):Play()
   end
   b.MouseEnter:Connect(function() hover(true) end); b.MouseLeave:Connect(function() hover(false) end)
   b.SelectionGained:Connect(function() hover(true) end); b.SelectionLost:Connect(function() hover(false) end)
   b.Activated:Connect(function() choose(index) end)
  end
  if UIS.GamepadEnabled then GuiService.SelectedObject=buttons[1] end
 end
 network:WaitForChild("State").OnClientEvent:Connect(function(data)
 if data.matchSessionId~=nil and data.matchSessionId~=player:GetAttribute("MatchSessionId") then return end
  if active and data.practice and data.practice.draftRemaining then
   active.endsAt=workspace:GetServerTimeNow()+data.practice.draftRemaining
  end
 end)
 remote.OnClientEvent:Connect(function(data)
  if data.kind=="offer" then show(data)
  elseif data.kind=="chosen" then
   selected=true; title.Text=data.name:upper().." ACQUIRED"
   footer.Text=data.slot and ("Equipped in "..(data.slot==1 and "Q" or "E")..". Waiting for the other players...") or "Added to your build for this match. Waiting for the other players..."
   for index,b in ipairs(buttons) do
    b.Active=false
    local chosen=active and active.cards[index].name==data.name
    local selectedArt=b:FindFirstChild("SelectedArt",true)
    if selectedArt then selectedArt.Visible=chosen==true end
    local action=b:FindFirstChild("CardAction",true)
    if action and chosen then action.Text=data.mode=="Chaos" and "ADDED TO BUILD" or "EQUIPPED" end
   end
  elseif data.kind=="close" then
   if selected and active then
    local offer=active
    task.delay(0.5,function() if active==offer then close() end end)
   else close() end
  elseif data.kind=="reset" then close() end
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if processed or UIS:GetFocusedTextBox() or player:GetAttribute("LeaveConfirmationOpen") then return end
  local index=({[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3})[input.KeyCode]
  if index then choose(index) end
 end)
 RunService.RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera then
   scale.Scale=math.max(0.1,math.min(1,(camera.ViewportSize.X-24)/panel.Size.X.Offset,(camera.ViewportSize.Y-32)/panel.Size.Y.Offset))
  end
  if not overlay.Visible then return end
  if active and not selected then
   footer.Text=player:GetAttribute("PracticePaused") and "PAUSED / Continue to choose" or string.format("%ds TO CHOOSE  /  First card auto-selects on timeout",math.max(0,math.ceil(active.endsAt-workspace:GetServerTimeNow())))
  end
 end)
end
return PowerupDraft
