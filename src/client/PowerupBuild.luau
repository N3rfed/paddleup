-- Persistent inventory of drafted cards, with server-reported activation state.
local Art=require(script.Parent:WaitForChild("PowerupArt"))
local Deck=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ArcadeDeck"))
local Build={}
function Build.details(card)
 if not card.chaosUpgrade then return card.description,"", "" end
 local function effect(level)
  local v=Deck.chaosValues({[card.id]=level})
  local descriptions={
   speedCleats=string.format("You move %d%% faster and can swing %d%% sooner.",15*level,4*level),
   bigPaddle=string.format("Your paddle and hit range are %d%% larger, making the ball easier to reach.",20*level),
   dropPickles=string.format("Drops %d pickle%s on the opponent's court every %.1f seconds of play. Opponents who step on one slip.",v.pickleCount,v.pickleCount==1 and "" or "s",v.pickleInterval),
   heatseeker=string.format("Your return automatically aims for an open corner. Recharges every %.1f seconds.",v.heatInterval),
   slipStream=string.format("Creates a slippery patch on the opponent's court every %d seconds of play. The patch is %d studs wide.",v.slipInterval,v.slipSize),
   smallPaddle=string.format("Opponents' paddles and hit range are %d%% smaller.",level*6),
   glowBall=string.format("Keeps the ball lit so it is easier to follow. The light reaches %d studs.",v.lightRange),
   zeroG=string.format("Gravity is %d%% lower for everyone on the court. The strongest Zero-G upgrade sets the gravity.",math.floor((1-v.gravity)*100+0.5)),
  }
  return descriptions[card.id] or card.description
 end
 local maxed=card.level>=Deck.CHAOS_MAX_LEVEL
 return effect(card.level),maxed and "This powerup is fully upgraded." or effect(card.level+1),
  maxed and "Maximum level reached." or "Choose this powerup again at the next upgrade choice to level it up."
end
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
 local connections={}
 local function connect(signal,callback) local c=signal:Connect(callback); table.insert(connections,c); return c end
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
 inspect.Text="MY POWERUPS  [B / SELECT]"; inspect.TextColor3=Color3.fromRGB(209,221,245); inspect.Font=Enum.Font.GothamBold; inspect.TextSize=11
 local panel=Instance.new("Frame",gui); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
 panel.Name="BuildPanel"; panel.Size=UDim2.fromOffset(640,466); panel.BackgroundColor3=Color3.fromRGB(13,21,34); panel.Visible=false; round(panel)
 local scale=Instance.new("UIScale",panel)
 local heading=label(panel,"MY CHAOS POWERUPS",22); heading.Position=UDim2.fromOffset(24,20); heading.Size=UDim2.fromOffset(540,30); heading.TextXAlignment=Enum.TextXAlignment.Left; heading.Font=Enum.Font.GothamBold
 local hint=label(panel,"These work automatically. No Q or E needed. They last for this match.",12)
 hint.Position=UDim2.fromOffset(24,56); hint.Size=UDim2.new(1,-48,0,22); hint.TextXAlignment=Enum.TextXAlignment.Left; hint.TextColor3=Color3.fromRGB(163,178,196)
 local close=Instance.new("TextButton",panel); close.Text="X"; close.TextSize=18; close.TextColor3=Color3.new(1,1,1)
 close.Size=UDim2.fromOffset(32,32); close.Position=UDim2.new(1,-42,0,12); close.BackgroundTransparency=1
 local grid=Instance.new("ScrollingFrame",panel); grid.BackgroundTransparency=1; grid.BorderSizePixel=0
 grid.Name="PowerupList"; grid.Position=UDim2.fromOffset(24,100); grid.Size=UDim2.fromOffset(198,318); grid.ScrollBarThickness=3
 grid.CanvasSize=UDim2.new(); grid.AutomaticCanvasSize=Enum.AutomaticSize.Y
 local gridLayout=Instance.new("UIListLayout",grid); gridLayout.Padding=UDim.new(0,8); gridLayout.SortOrder=Enum.SortOrder.LayoutOrder
 local name=label(panel,"",22); name.Name="SelectedPowerup"; name.Position=UDim2.fromOffset(246,100); name.Size=UDim2.fromOffset(370,30); name.TextXAlignment=Enum.TextXAlignment.Left; name.Font=Enum.Font.GothamBold
 local rarity=label(panel,"",12); rarity.Position=UDim2.fromOffset(246,138); rarity.Size=UDim2.fromOffset(370,22); rarity.TextXAlignment=Enum.TextXAlignment.Left; rarity.TextColor3=Color3.fromRGB(80,232,255)
 local function detailBox(title,y)
  local box=Instance.new("Frame",panel); box.Position=UDim2.fromOffset(246,y); box.Size=UDim2.fromOffset(370,108)
  box.BackgroundColor3=Color3.fromRGB(24,34,49); box.BorderSizePixel=0; round(box)
  local cap=label(box,title,10); cap.Position=UDim2.fromOffset(14,10); cap.Size=UDim2.fromOffset(342,16); cap.TextXAlignment=Enum.TextXAlignment.Left; cap.TextColor3=Color3.fromRGB(163,178,196); cap.Font=Enum.Font.GothamBold
  local body=label(box,"",14); body.Position=UDim2.fromOffset(14,34); body.Size=UDim2.fromOffset(342,64); body.TextXAlignment=Enum.TextXAlignment.Left; body.TextYAlignment=Enum.TextYAlignment.Top
  return body,cap
 end
 local description=detailBox("WHAT IT DOES",176); description.Name="CurrentEffect"
 local nextEffect,nextHeading=detailBox("NEXT LEVEL",296); nextEffect.Name="NextEffect"
 local status=label(panel,"",12); status.Name="UpgradeHelp"; status.Position=UDim2.fromOffset(246,416); status.Size=UDim2.fromOffset(370,36); status.TextXAlignment=Enum.TextXAlignment.Left
 local liveHint=label(panel,"Match keeps playing while this is open.",10); liveHint.Position=UDim2.fromOffset(24,430); liveHint.Size=UDim2.fromOffset(198,24); liveHint.TextColor3=Color3.fromRGB(163,178,196)
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
  local list=parent==grid
  local b=Instance.new("TextButton",parent); b.Name=entry.card.name; b.Size=UDim2.fromOffset(list and 190 or 54,list and 62 or 54); b.LayoutOrder=#ordered
  b.Text=""; b.BackgroundColor3=Color3.fromRGB(23,34,51); round(b)
  local border=Instance.new("UIStroke",b); border.Color=colors[entry.card.tier]; border.Thickness=1.5
  local art=Instance.new("Frame",b); art.BackgroundTransparency=1; art.Size=UDim2.fromOffset(126,126); art.Position=UDim2.fromOffset(list and 8 or 0,list and 10 or 0)
  local artScale=Instance.new("UIScale",art); artScale.Scale=(list and 40 or 54)/126
  Art.draw(art,entry.card,colors[entry.card.tier])
  local count=label(b,"",11); count.Position=UDim2.new(1,-23,1,-17); count.Size=UDim2.fromOffset(23,17)
  if list then
   local title=label(b,entry.card.name,12); title.Position=UDim2.fromOffset(58,10); title.Size=UDim2.fromOffset(122,22); title.TextXAlignment=Enum.TextXAlignment.Left; title.Font=Enum.Font.GothamBold
   count.Position=UDim2.fromOffset(58,34); count.Size=UDim2.fromOffset(120,18); count.TextXAlignment=Enum.TextXAlignment.Left
  end
  local dot=Instance.new("Frame",b); dot.Size=UDim2.fromOffset(6,6); dot.Position=UDim2.fromOffset(5,5)
  dot.BackgroundColor3=Color3.fromRGB(111,255,170); dot.BorderSizePixel=0; round(dot); dot.Visible=false
  table.insert(entry.views,{border=border,dot=dot,count=count,list=list})
  b.Activated:Connect(function() selected=entry; setOpen(true) end)
  return b
 end
 connect(inspect.Activated,function() setOpen(not panel.Visible) end)
 connect(close.Activated,function() setOpen(false) end)
 connect(UIS.InputBegan,function(input,processed)
  if processed or UIS:GetFocusedTextBox() then return end
  if input.KeyCode==Enum.KeyCode.B or input.KeyCode==Enum.KeyCode.ButtonSelect then setOpen(not panel.Visible) end
 end)
 connect(network:WaitForChild("Powerup").OnClientEvent,function(data)
  if data.kind=="reset" then
   setOpen(false)
   for _,entry in ipairs(ordered) do entry.button:Destroy(); entry.detailButton:Destroy() end
   table.clear(entries); table.clear(ordered); effects={}; progress={}; stats={}; selected=nil
  elseif data.kind=="offer" then setOpen(false)
  elseif data.kind=="chosen" and data.card and data.mode~="Arcade" and not data.sharedPowers then
   stats=data.stats or stats
   local entry=entries[data.card.id]
   if entry then entry.count=data.card.level or entry.count+1; entry.card=data.card else
    entry={card=data.card,count=data.card.level or 1,views={}}; entries[data.card.id]=entry; table.insert(ordered,entry)
    entry.button=icon(strip,entry); entry.detailButton=icon(grid,entry)
   end
   selected=entry
  end
 end)
 connect(network:WaitForChild("State").OnClientEvent,function(data)
  effects=data.powerupEffects or {}; progress=data.powerupProgress or {}
 end)
 connect(RunService.RenderStepped,function()
  local camera=workspace.CurrentCamera
  if camera then
   strip.Size=UDim2.fromOffset(math.min(420,camera.ViewportSize.X-32),60)
   scale.Scale=math.min(1,(camera.ViewportSize.X-24)/640,(camera.ViewportSize.Y-30)/466)
  end
  local show=available(); strip.Visible=show; inspect.Visible=show
  if not show then setOpen(false) end
  for _,entry in ipairs(ordered) do
   local active=effects[entry.card.id] or (entry.card.stat and (stats[entry.card.stat] or 0)>0)
   for _,view in ipairs(entry.views) do
    view.border.Color=selected==entry and Color3.fromRGB(80,232,255) or Color3.fromRGB(79,96,119)
    view.dot.Visible=active==true
    view.border.Thickness=selected==entry and 1.5 or 1
    view.border.Transparency=selected==entry and 0.15 or 0.6
    view.count.Text=entry.card.chaosUpgrade and ((view.list and "Level " or "Lv ")..entry.count..(view.list and " / 5" or "")) or entry.count>1 and ("x"..entry.count) or ""
   end
  end
  if panel.Visible and selected then
   local card=selected.card
   name.Text=card.name; name.TextColor3=Color3.fromRGB(246,246,255)
   rarity.Text=card.chaosUpgrade and ("LEVEL "..card.level.." OF 5  /  WORKS AUTOMATICALLY") or ({"SILVER","GOLD","PRISMATIC"})[card.tier].." / "..Art.badge(card)
   local current,nextDescription,upgradeHelp=Build.details(card)
   description.Text=current
   nextEffect.Text=nextDescription
   nextHeading.Text=card.chaosUpgrade and (card.level>=5 and "FULLY UPGRADED" or "AT LEVEL "..(card.level+1)) or "UPGRADES"
   local info=effects[card.id] and "ACTIVE" or "WAITING FOR TRIGGER"
   if card.stat then info=string.format("PASSIVE / Total %s: %d%%",card.stat,math.floor((stats[card.stat] or 0)*100+0.5))
   elseif card.id=="secondServe" then info=progress.secondServeUsed and "USED THIS MATCH" or "READY / 1 RETRY"
   elseif card.id=="dinkSpecialist" then info=info.." / TENSION "..(progress.tension or 0).."/3"
   elseif card.id=="momentumShift" then info=info.." / PERFECT CHAIN "..(progress.perfectChain or 0).."/3"
   elseif card.id=="vampiricReach" then info="PERMANENT REACH +"..(progress.reachStacks or 0).."%"
   elseif card.id=="terminalVelocity" then info=info.." / PERMANENT MOVE +"..((progress.speedWins or 0)*5).."%" end
   status.Text=card.chaosUpgrade and upgradeHelp or info
   status.TextColor3=Color3.fromRGB(163,178,196)
  end
 end)
 gui.Destroying:Connect(function()
  for _,connection in ipairs(connections) do connection:Disconnect() end
  player:SetAttribute("PowerupDetailsOpen",false)
 end)
 return {setOpen=setOpen,destroy=function() gui:Destroy() end}
end
return Build
