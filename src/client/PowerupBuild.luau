-- Persistent inventory of drafted cards, with server-reported activation state.
local Art=require(script.Parent:WaitForChild("PowerupArt"))
local Build={}
function Build.start(player,network)
 local UIS=game:GetService("UserInputService")
 local RunService=game:GetService("RunService")
 local GuiService=game:GetService("GuiService")
 local colors={Color3.fromRGB(198,213,230),Color3.fromRGB(255,211,93),Color3.fromRGB(197,137,255)}
 local gui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
 gui.Name="PowerupBuild"; gui.ResetOnSpawn=false; gui.DisplayOrder=14
 player:SetAttribute("PowerupDetailsOpen",false)
 local entries,ordered={},{}
 local effects,progress,stats={},{},{}
 local selected,previousSelection
 local function label(parent,text,size)
  local t=Instance.new("TextLabel",parent); t.BackgroundTransparency=1; t.Text=text; t.TextSize=size
  t.Font=Enum.Font.GothamMedium; t.TextColor3=Color3.fromRGB(232,238,250); t.TextWrapped=true
  return t
 end
 local function round(parent)
  local r=Instance.new("UICorner",parent); r.CornerRadius=UDim.new(0,10)
 end
 local strip=Instance.new("ScrollingFrame",gui)
 strip.Name="ChosenPowerupIcons"; strip.AnchorPoint=Vector2.new(0,1); strip.Position=UDim2.new(0,16,1,-50)
 strip.Size=UDim2.fromOffset(540,60); strip.BackgroundTransparency=1; strip.BorderSizePixel=0
 strip.ScrollBarThickness=3; strip.ScrollingDirection=Enum.ScrollingDirection.X
 strip.AutomaticCanvasSize=Enum.AutomaticSize.X; strip.CanvasSize=UDim2.new()
 local layout=Instance.new("UIListLayout",strip); layout.FillDirection=Enum.FillDirection.Horizontal; layout.Padding=UDim.new(0,7)
 local inspect=Instance.new("TextButton",gui)
 inspect.Name="InspectPowerups"; inspect.AnchorPoint=Vector2.new(0,1); inspect.Position=UDim2.new(0,16,1,-16)
 inspect.Size=UDim2.fromOffset(180,25); inspect.BackgroundColor3=Color3.fromRGB(22,32,47); round(inspect)
 inspect.Text="POWERUPS  [B / SELECT]"; inspect.TextColor3=Color3.fromRGB(209,221,245); inspect.Font=Enum.Font.GothamBold; inspect.TextSize=11
 local panel=Instance.new("Frame",gui); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
 panel.Size=UDim2.fromOffset(560,420); panel.BackgroundColor3=Color3.fromRGB(13,21,34); panel.Visible=false; round(panel)
 local scale=Instance.new("UIScale",panel)
 local heading=label(panel,"YOUR POWERUPS",22); heading.Position=UDim2.fromOffset(18,15); heading.Size=UDim2.fromOffset(480,34)
 local hint=label(panel,"Select an icon to inspect. The match continues while this panel is open.",12)
 hint.Position=UDim2.fromOffset(18,52); hint.Size=UDim2.new(1,-36,0,32)
 local close=Instance.new("TextButton",panel); close.Text="X"; close.TextSize=18; close.TextColor3=Color3.new(1,1,1)
 close.Size=UDim2.fromOffset(32,32); close.Position=UDim2.new(1,-42,0,12); close.BackgroundTransparency=1
 local grid=Instance.new("ScrollingFrame",panel); grid.BackgroundTransparency=1; grid.BorderSizePixel=0
 grid.Position=UDim2.fromOffset(18,94); grid.Size=UDim2.fromOffset(200,302); grid.ScrollBarThickness=3
 grid.CanvasSize=UDim2.new(); grid.AutomaticCanvasSize=Enum.AutomaticSize.Y
 local gridLayout=Instance.new("UIGridLayout",grid); gridLayout.CellSize=UDim2.fromOffset(54,54); gridLayout.CellPadding=UDim2.fromOffset(7,7)
 local name=label(panel,"",20); name.Position=UDim2.fromOffset(238,96); name.Size=UDim2.fromOffset(300,64)
 local rarity=label(panel,"",12); rarity.Position=UDim2.fromOffset(238,162); rarity.Size=UDim2.fromOffset(300,28)
 local description=label(panel,"",16); description.Position=UDim2.fromOffset(238,194); description.Size=UDim2.fromOffset(300,112)
 local status=label(panel,"",14); status.Position=UDim2.fromOffset(238,314); status.Size=UDim2.fromOffset(300,76)
 local function available()
  return player:GetAttribute("MatchVariant")=="Chaos" and not player:GetAttribute("PowerupDraftOpen") and not player:GetAttribute("LeaveConfirmationOpen") and #ordered>0
 end
 local function setOpen(open)
  open=open and available()
  if panel.Visible==open then return end
  panel.Visible=open; player:SetAttribute("PowerupDetailsOpen",open)
  if open then
   previousSelection=GuiService.SelectedObject
   if UIS.GamepadEnabled then GuiService.SelectedObject=selected and selected.detailButton or close end
  elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(panel) then
   GuiService.SelectedObject=previousSelection and previousSelection.Parent and previousSelection or nil
  end
 end
 local function icon(parent,entry)
  local b=Instance.new("TextButton",parent); b.Name=entry.card.name; b.Size=UDim2.fromOffset(54,54)
  b.Text=""; b.BackgroundColor3=Color3.fromRGB(23,34,51); round(b)
  local border=Instance.new("UIStroke",b); border.Color=colors[entry.card.tier]; border.Thickness=1.5
  local art=Instance.new("Frame",b); art.BackgroundTransparency=1; art.Size=UDim2.fromOffset(126,126)
  local artScale=Instance.new("UIScale",art); artScale.Scale=54/126
  Art.draw(art,entry.card,colors[entry.card.tier])
  local count=label(b,"",11); count.Position=UDim2.new(1,-23,1,-17); count.Size=UDim2.fromOffset(23,17)
  local dot=Instance.new("Frame",b); dot.Size=UDim2.fromOffset(6,6); dot.Position=UDim2.fromOffset(5,5)
  dot.BackgroundColor3=Color3.fromRGB(111,255,170); dot.BorderSizePixel=0; round(dot); dot.Visible=false
  table.insert(entry.views,{border=border,dot=dot,count=count})
  b.Activated:Connect(function() selected=entry; setOpen(true) end)
  return b
 end
 inspect.Activated:Connect(function() setOpen(not panel.Visible) end)
 close.Activated:Connect(function() setOpen(false) end)
 UIS.InputBegan:Connect(function(input,processed)
  if processed or UIS:GetFocusedTextBox() then return end
  if input.KeyCode==Enum.KeyCode.B or input.KeyCode==Enum.KeyCode.ButtonSelect then setOpen(not panel.Visible) end
 end)
 network:WaitForChild("Powerup").OnClientEvent:Connect(function(data)
  if data.kind=="reset" then
   setOpen(false)
   for _,entry in ipairs(ordered) do entry.button:Destroy(); entry.detailButton:Destroy() end
   table.clear(entries); table.clear(ordered); effects={}; progress={}; stats={}; selected=nil
  elseif data.kind=="offer" then setOpen(false)
  elseif data.kind=="chosen" and data.card then
   stats=data.stats or stats
   local entry=entries[data.card.id]
   if entry then entry.count+=1 else
    entry={card=data.card,count=1,views={}}; entries[data.card.id]=entry; table.insert(ordered,entry)
    entry.button=icon(strip,entry); entry.detailButton=icon(grid,entry)
   end
   selected=entry
  end
 end)
 network:WaitForChild("State").OnClientEvent:Connect(function(data)
  effects=data.powerupEffects or {}; progress=data.powerupProgress or {}
 end)
 RunService.RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera then
   strip.Size=UDim2.fromOffset(math.min(420,camera.ViewportSize.X-32),60)
   scale.Scale=math.min(1,(camera.ViewportSize.X-20)/560,(camera.ViewportSize.Y-30)/420)
  end
  local show=available(); strip.Visible=show; inspect.Visible=show
  if not show then setOpen(false) end
  for _,entry in ipairs(ordered) do
   local active=effects[entry.card.id] or (entry.card.stat and (stats[entry.card.stat] or 0)>0)
   for _,view in ipairs(entry.views) do
    view.dot.Visible=active==true
    view.border.Thickness=active and 2.5+math.sin(os.clock()*6)*0.5 or 1
    view.border.Transparency=active and 0 or 0.5
    view.count.Text=entry.count>1 and ("x"..entry.count) or ""
   end
  end
  if panel.Visible and selected then
   local card=selected.card
   name.Text=card.name; name.TextColor3=colors[card.tier]
   rarity.Text=({"SILVER","GOLD","PRISMATIC"})[card.tier].." / "..Art.badge(card)
   description.Text=card.description
   local info=effects[card.id] and "ACTIVE" or "WAITING FOR TRIGGER"
   if card.stat then info=string.format("PASSIVE / Total %s: %d%%",card.stat,math.floor((stats[card.stat] or 0)*100+0.5))
   elseif card.id=="secondServe" then info=progress.secondServeUsed and "USED THIS MATCH" or "READY / 1 RETRY"
   elseif card.id=="dinkSpecialist" then info=info.." / TENSION "..(progress.tension or 0).."/3"
   elseif card.id=="momentumShift" then info=info.." / PERFECT CHAIN "..(progress.perfectChain or 0).."/3"
   elseif card.id=="vampiricReach" then info="PERMANENT REACH +"..(progress.reachStacks or 0).."%"
   elseif card.id=="terminalVelocity" then info=info.." / PERMANENT MOVE +"..((progress.speedWins or 0)*5).."%" end
   status.Text=info.."\nSelected "..selected.count.." time"..(selected.count==1 and "" or "s")
   status.TextColor3=effects[card.id] and Color3.fromRGB(111,255,170) or Color3.fromRGB(182,198,222)
  end
 end)
end
return Build
