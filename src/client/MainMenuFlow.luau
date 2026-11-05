local Flow={}
local Assets=require(script.Parent:WaitForChild("FigmaAssets"))
local Thumbnail=require(script.Parent:WaitForChild("MapThumbnail"))
function Flow.start(player,network,panel,status)
 local TweenService=game:GetService("TweenService")
 local queue=network:WaitForChild("Queue")
 local mode,format,group
 local stage,view="Modes",nil
 local controls,buttons,rows={},{},{}
 local headshots={}
 local function updateHeads(card,map)
  local heads=card:FindFirstChild("Voters")
  if not heads then return end
  local present={}
  local index=0
  for _,entry in ipairs(group.roster or {}) do
   if entry.map==map then
    index+=1
    local id=entry.player.UserId
    local key=tostring(id or entry.name)
    present[key]=true
    local head=heads:FindFirstChild(key)
    if not head then
     head=Instance.new("ImageLabel"); head.Name=key; head.Size=UDim2.fromOffset(30,30)
     head.BackgroundColor3=Color3.fromRGB(55,54,95); head.BorderSizePixel=0; head.Parent=heads
     local corner=Instance.new("UICorner",head); corner.CornerRadius=UDim.new(1,0)
     local stroke=Instance.new("UIStroke",head); stroke.Color=entry.player==player and Color3.fromRGB(80,232,255) or Color3.fromRGB(181,187,225)
     stroke.Thickness=entry.player==player and 2 or 1
     local initial=Instance.new("TextLabel",head); initial.Name="Fallback"
     initial.BackgroundTransparency=1; initial.Size=UDim2.fromScale(1,1)
     initial.Text=string.upper(string.sub(entry.name or "?",1,1)); initial.Font=Enum.Font.GothamBold
     initial.TextSize=16; initial.TextColor3=Color3.fromRGB(246,246,255)
     if id and id>0 then
      task.spawn(function()
       local url=headshots[id]
       for attempt=1,3 do
        if url or not head.Parent then break end
        local ok,result,ready=pcall(function()
         return game:GetService("Players"):GetUserThumbnailAsync(id,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
        end)
        if ok and ready then url=result; headshots[id]=url else task.wait(1) end
       end
       if url and head.Parent then head.Image=url; initial.Visible=false end
      end)
     end
    end
    head.Position=UDim2.fromOffset((index-1)*36,0)
   end
  end
  for _,head in ipairs(heads:GetChildren()) do if not present[head.Name] then head:Destroy() end end
 end
 local white=Color3.fromRGB(246,246,255)
 local muted=Color3.fromRGB(181,187,225)
 local cyan=Color3.fromRGB(80,232,255)
 local pink=Color3.fromRGB(255,85,200)
 local navy=Color3.fromRGB(27,27,64)
 local heading=panel:FindFirstChild("Heading")
 local step=panel:FindFirstChild("Step")
 local render,updateVote
 local function fitContent()
  local bottom=120
  for _,control in ipairs(controls) do
   if control.Visible then bottom=math.max(bottom,control.Position.Y.Offset+control.Size.Y.Offset) end
  end
  status.Visible=status.Text~=""
  status.Position=UDim2.fromOffset(24,bottom+16)
  status.Size=UDim2.new(1,-48,0,40)
  panel.Size=UDim2.fromOffset(420,bottom+(status.Visible and 72 or 24))
 end
 local function text(parent,name,value,y,height,size,color)
  local label=Instance.new("TextLabel",parent); label.Name=name
  label.Position=UDim2.fromOffset(16,y); label.Size=UDim2.new(1,-32,0,height)
  label.BackgroundTransparency=1; label.Text=value; label.TextColor3=color or white
  label.TextXAlignment=Enum.TextXAlignment.Left; label.TextSize=size; label.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Bold)
  label.TextTruncate=Enum.TextTruncate.AtEnd
  return label
 end
 local function neon(parent,accent)
  local key=accent==pink and "panelPink" or accent==Color3.fromRGB(169,151,255) and "panelPurple" or "panelCyan"
  local skin=Assets.image(parent,key,-10,-10,1,1)
  skin.Name="NeonFrame"; skin.Size=UDim2.new(1,20,1,20)
  skin.ScaleType=Enum.ScaleType.Slice; skin.SliceCenter=Rect.new(48,48,208,208); skin.SliceScale=0.5
  skin.ImageTransparency=0.12; skin.ZIndex=1
  return skin
 end
 local function button(name,title,description,y,action,enabled,accent,height)
  local b=Instance.new("TextButton",panel); table.insert(controls,b); buttons[name]=b
  b.Name=name; b.Position=UDim2.fromOffset(24,y); b.Size=UDim2.new(1,-48,0,height or 58)
  b.BackgroundColor3=navy; b.Text=""; b.Selectable=enabled~=false; b.BorderSizePixel=0
  b.AutoButtonColor=false; b.Active=enabled~=false
  local corner=Instance.new("UICorner",b); corner.CornerRadius=UDim.new(0,12)
  local stroke=Instance.new("UIStroke",b); stroke.Name="Accent"; stroke.Color=accent or cyan; stroke.Transparency=0.65; stroke.Thickness=1.5
  b.BackgroundColor3=navy; b.BackgroundTransparency=0
  stroke.Enabled=true; neon(b,accent or cyan).Visible=false
  local primary=text(b,"Title",title,9,22,17,white)
  primary.Position=UDim2.fromOffset(58,9); primary.Size=UDim2.new(1,-96,0,22); primary.ZIndex=3
  primary.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
  local detail=text(b,"Detail",description,34,24,13,muted); detail.Font=Enum.Font.GothamBold
  detail.Position=UDim2.fromOffset(58,33); detail.Size=UDim2.new(1,-76,0,18); detail.ZIndex=3
  detail.TextWrapped=true; detail.TextTruncate=Enum.TextTruncate.None
  local badge=Instance.new("Frame",b); badge.Name="ModeIcon"
  badge.Position=UDim2.fromOffset(14,13); badge.Size=UDim2.fromOffset(44,36)
  badge.BackgroundColor3=accent or cyan; badge.BackgroundTransparency=1; badge.BorderSizePixel=0; badge.ZIndex=2
  local badgeCorner=Instance.new("UICorner",badge); badgeCorner.CornerRadius=UDim.new(0,8)
  local icons={Classic="",Arcade="",Chaos="",Practice="",["1V1"]="1v1",["1V2"]="1v2",["2V2"]="2v2",Spectate="",Back="<",CancelQueue="<",LowGravity="",Rooftop="",Moon=""}
  local icon=text(badge,"Symbol",icons[name] or "+",0,36,14,accent or cyan)
  icon.Position=UDim2.fromOffset(0,0); icon.Size=UDim2.fromScale(1,1); icon.TextXAlignment=Enum.TextXAlignment.Center
  if icon.Text=="" then
   -- A miniature court keeps the menu artwork native and crisp at any scale.
   local court=Instance.new("Frame",badge); court.Name="Court"
   court.Position=UDim2.fromOffset(9,7); court.Size=UDim2.fromOffset(26,22)
   court.BackgroundColor3=accent or cyan; court.BackgroundTransparency=0.75; court.BorderSizePixel=0; court.Rotation=-8
   local outline=Instance.new("UIStroke",court); outline.Color=accent or cyan; outline.Thickness=1.5
   for _,spec in ipairs({{0,10,26,2},{12,0,1,22},{0,5,26,1},{0,16,26,1}}) do
    local line=Instance.new("Frame",court); line.BorderSizePixel=0; line.BackgroundColor3=accent or cyan
    line.Position=UDim2.fromOffset(spec[1],spec[2]); line.Size=UDim2.fromOffset(spec[3],spec[4])
   end
   local ball=Instance.new("Frame",badge); ball.Position=UDim2.fromOffset(31,5); ball.Size=UDim2.fromOffset(7,7)
   ball.BackgroundColor3=white; ball.BorderSizePixel=0
   local round=Instance.new("UICorner",ball); round.CornerRadius=UDim.new(1,0)
  end
  local arrow=text(b,"Arrow",utf8.char(8250),9,24,24,accent or cyan)
  arrow.ZIndex=3
  arrow.Position=UDim2.new(1,-30,0,9); arrow.Size=UDim2.fromOffset(18,24)
  local pop=Instance.new("UIScale",b); pop.Name="HoverScale"
  b.Activated:Connect(function() if b.Active then action() end end)
  local function hover(on)
   local active=on and b.Active
   TweenService:Create(pop,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{Scale=active and not b:GetAttribute("MatchChoice") and 1.012 or 1}):Play()
   TweenService:Create(b.NeonFrame,TweenInfo.new(0.16),{ImageTransparency=active and 0 or 0.12}):Play()
   if b:GetAttribute("VoteCard") then
    if not b.Active then return end
    local selected=b:GetAttribute("Selected")
    TweenService:Create(b,TweenInfo.new(0.16),{BackgroundColor3=selected and Color3.fromRGB(27,48,60) or active and Color3.fromRGB(38,48,69) or Color3.fromRGB(24,31,48)}):Play()
    TweenService:Create(stroke,TweenInfo.new(0.16),{Transparency=selected and 0.1 or active and 0.35 or 0.85}):Play()
    return
   end
   if b:GetAttribute("GameTile") then
    TweenService:Create(b,TweenInfo.new(0.16),{BackgroundColor3=active and Color3.fromRGB(38,48,69) or Color3.fromRGB(24,31,48)}):Play()
    TweenService:Create(b.Accent,TweenInfo.new(0.16),{Transparency=active and 0.05 or (b:GetAttribute("MatchChoice") and 0.85 or 0.6)}):Play()
    TweenService:Create(arrow,TweenInfo.new(0.16),{TextColor3=active and white or (accent or cyan)}):Play()
    return
   end
   TweenService:Create(b,TweenInfo.new(0.14),{BackgroundColor3=active and Color3.fromRGB(65,66,111)
    or b:GetAttribute("Selected") and Color3.fromRGB(53,55,101) or navy}):Play()
   arrow.TextColor3=active and white or (accent or cyan)
  end
  b.MouseEnter:Connect(function() hover(true) end); b.MouseLeave:Connect(function() hover(false) end)
  b.SelectionGained:Connect(function() hover(true) end); b.SelectionLost:Connect(function() hover(false) end)
  return b
 end
 local function textAction(name,title,y,action)
  local b=Instance.new("TextButton",panel); b.Name=name
  b.Position=UDim2.fromOffset(24,y); b.Size=UDim2.fromOffset(180,44)
  b.BackgroundTransparency=1; b.BorderSizePixel=0; b.AutoButtonColor=false
  b.Text=utf8.char(8592).."  "..title; b.TextColor3=muted
  b.Font=Enum.Font.GothamMedium; b.TextSize=15; b.TextXAlignment=Enum.TextXAlignment.Left
  table.insert(controls,b); buttons[name]=b
  local function highlight(active)
   TweenService:Create(b,TweenInfo.new(0.15),{TextColor3=active and white or muted}):Play()
  end
  b.MouseEnter:Connect(function() highlight(true) end); b.MouseLeave:Connect(function() highlight(false) end)
  b.SelectionGained:Connect(function() highlight(true) end); b.SelectionLost:Connect(function() highlight(false) end)
  b.Activated:Connect(action)
  return b
 end
 local function modeCard(card,accent)
  card:SetAttribute("GameTile",true)
  card.ModeIcon.Visible=false; card.Arrow.Visible=true
  card.BackgroundColor3=Color3.fromRGB(24,31,48)
  local rail=Instance.new("Frame",card); rail.Name="ColorRail"
  rail.Position=UDim2.fromOffset(0,14); rail.Size=UDim2.new(0,3,1,-28)
  rail.BackgroundColor3=accent; rail.BorderSizePixel=0; rail.ZIndex=2
  local railCorner=Instance.new("UICorner",rail); railCorner.CornerRadius=UDim.new(1,0)
  card.Accent.Color=accent; card.Accent.Thickness=1.5; card.Accent.Transparency=0.6
  card.Title.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy); card.Title.TextColor3=white
  card.Title.Rotation=0; card.Title.ZIndex=3
  card.Detail.TextColor3=muted; card.Detail.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Bold); card.Detail.ZIndex=3
 end
 local function ownVote()
  for _,entry in ipairs(group and group.roster or {}) do if entry.player==player then return entry end end
 end
 local function timer()
  if not group or (stage~="Setup" and stage~="Reveal") then return end
  local now=workspace:GetServerTimeNow()
  if stage=="Setup" then
   if step then step.Text="VOTE CLOSES IN "..math.ceil(math.max(0,group.endsAt-now)).."s" end
  else
   local candidates=group.candidates or {group.map}
   local duration=group.revealEndsAt-group.revealAt
   local progress=math.clamp((now-group.revealAt)/math.max(0.1,duration-1),0,1)
   local winner=table.find(candidates,group.map) or 1
   local ticks=20+winner-1
   local index=math.floor(ticks*(1-(1-progress)^2))%#candidates+1
   local highlighted=progress>=1 and group.map or candidates[index]
   for _,map in ipairs({"Rooftop","Moon"}) do
    local card=buttons[map]
    if card then
     card.Accent.Color=map==highlighted and cyan or Color3.fromRGB(113,146,171)
     card.Accent.Thickness=map==highlighted and 2 or 1
     card.Accent.Transparency=map==highlighted and 0.1 or 0.85
     card.NeonFrame.ImageTransparency=map==highlighted and 0 or 0.45
     card.BackgroundColor3=map==highlighted and Color3.fromRGB(27,48,60) or Color3.fromRGB(24,31,48)
    end
   end
   local title=progress>=1 and string.upper(group.map).." SELECTED" or (#candidates>1 and "TIE / RANDOM DRAW" or "MAP SELECTED")
   if step then step.Text=title end
   status.Text=progress>=1 and "Starting on "..group.map.."..." or "Choosing between tied maps..."
  end
 end
 updateVote=function()
  local own=ownVote()
  for _,map in ipairs({"Rooftop","Moon"}) do
   local card=buttons[map]
   local count=group.counts and group.counts[map] or 0
   card.Title.Text=string.upper(map)
   card.Detail.Text=count..(count==1 and " VOTE" or " VOTES")
   if card:FindFirstChild("Selection") then card.Selection.Visible=own~=nil and own.map==map end
   updateHeads(card,map)
   card.Active=stage=="Setup"; card.Selectable=card.Active
   card.Accent.Color=own and own.map==map and cyan or Color3.fromRGB(113,146,171)
   card.Accent.Thickness=own and own.map==map and 2 or 1
   card.Accent.Transparency=own and own.map==map and 0.1 or 0.85
   card:SetAttribute("Selected",own~=nil and own.map==map)
   card.NeonFrame.ImageTransparency=own and own.map==map and 0 or 0.25
   card.BackgroundColor3=own and own.map==map and Color3.fromRGB(27,48,60) or Color3.fromRGB(24,31,48)
   card.Arrow.Text=own and own.map==map and utf8.char(10003) or ">"
  end
  for index,label in ipairs(rows) do
   local entry=group.roster and group.roster[index]
   label.Text=entry and ((entry.player==player and "YOU" or entry.name).."  >  "..(entry.map and string.upper(entry.map) or "CHOOSING...")) or ""
   label.TextColor3=entry and entry.map and (entry.map=="Moon" and cyan or pink) or muted
  end
  if buttons.LowGravity then
   local modifier=stage=="Reveal" and group.modifier or (own and own.modifier or group.modifier)
   buttons.LowGravity.Title.Text="Low gravity"
   local setting=buttons.LowGravity:FindFirstChild("Setting")
   if setting then
    setting.Text=mode=="Chaos" and "ALWAYS ON" or modifier=="LowGravity" and "ON" or "OFF"
    setting.TextColor3=modifier=="LowGravity" and cyan or muted
   end
   buttons.LowGravity.Detail.Text=stage=="Reveal" and "Match setting" or (mode=="Chaos" and "Always on in Chaos" or "Toggle before choosing a map")
   buttons.LowGravity.Active=stage=="Setup" and mode=="Arcade"; buttons.LowGravity.Selectable=buttons.LowGravity.Active
  end
  status.Text=mode=="Arcade" and "Gravity is decided by majority vote."
   or "Starts when everyone votes. Ties are random."
  timer()
 end
 render=function()
  local nextView=(stage=="Setup" or stage=="Reveal") and "Vote" or stage
  if view==nextView and nextView=="Vote" then updateVote(); return end
  for _,control in ipairs(controls) do control:Destroy() end
  table.clear(controls); table.clear(buttons); table.clear(rows); view=nextView
  local current=stage=="Modes" and 1 or stage=="Players" and 2 or 3
  for index=1,3 do
   local marker=panel:FindFirstChild("Progress"..index)
   if marker then marker.BackgroundColor3=index<=current and cyan or Color3.fromRGB(60,61,96) end
  end
  if heading then heading.Text=stage=="Modes" and "SELECT MODE" or stage=="Players" and "SELECT MATCH" or nextView=="Vote" and "SELECT COURT" or "FINDING PLAYERS" end
  if step then step.Text=stage=="Players" and (string.upper(mode).."  /  Choose a format") or mode and (string.upper(mode)..(format and " / "..format or "")) or "Choose how you want to play." end
  if stage=="Modes" then
   status.Text=""
   for index,item in ipairs({{"Classic","Standard pickleball rules",cyan},{"Arcade","Choose 3 powerups",Color3.fromRGB(186,167,255)},{"Chaos","Stack upgrades for the whole match",Color3.fromRGB(255,134,109)}}) do
    local card=button(item[1],string.upper(item[1]),item[2],132+(index-1)*100,function() mode=item[1]; stage="Players"; render() end,true,item[3],88)
    modeCard(card,item[3])
    card.Title.TextSize=25; card.Title.Position=UDim2.fromOffset(22,15); card.Title.Size=UDim2.new(1,-64,0,30)
    card.Detail.Position=UDim2.fromOffset(22,51); card.Detail.Size=UDim2.new(1,-64,0,20); card.Detail.TextSize=13
    card.Arrow.Position=UDim2.new(1,-30,0,31)
   end
   local watch=button("Spectate","WATCH","Spectate a match",436,function() network.Session:FireServer("Spectate") end,true,cyan,58)
   watch.BackgroundTransparency=1; watch.Accent.Transparency=0.85
  elseif stage=="Players" then
   status.Text=""
   local section=text(panel,"MatchSection","MULTIPLAYER",128,16,10,muted)
   section.Position=UDim2.fromOffset(24,128); section.Font=Enum.Font.GothamMedium
   table.insert(controls,section)
   for index,item in ipairs({{"1V1","Singles","One player on each side","1 v 1"},{"1V2","One against two","Take on a team of two","1 v 2"},{"2V2","Doubles","Two players on each side","2 v 2"},{"Practice","Practice","Warm up against the practice partner","SOLO"}}) do
    local solo=item[1]=="Practice"
    local y=solo and 420 or 156+(index-1)*80
    local card=button(item[1],item[2],item[3],y,function()
     format=item[1]
     stage="Joining"; render(); queue:FireServer("Join",mode,format)
    end,true,cyan,solo and 64 or 68)
    card:SetAttribute("GameTile",true); card:SetAttribute("MatchChoice",true)
    card.ModeIcon.Visible=false; card.Arrow.Visible=true
    card.BackgroundColor3=Color3.fromRGB(24,31,48)
    card.Accent.Color=Color3.fromRGB(113,146,171); card.Accent.Thickness=1; card.Accent.Transparency=0.85
    card:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,8)
    card.Title.Position=UDim2.fromOffset(18,11); card.Title.Size=UDim2.fromOffset(218,25); card.Title.TextSize=20
    card.Title.Font=Enum.Font.GothamBold
    card.Detail.Position=UDim2.fromOffset(18,38); card.Detail.Size=UDim2.fromOffset(228,18); card.Detail.TextSize=12
    card.Detail.Font=Enum.Font.GothamMedium; card.Detail.TextColor3=Color3.fromRGB(163,178,196)
    card.Detail.TextWrapped=false; card.Detail.TextTruncate=Enum.TextTruncate.AtEnd
    card.Arrow.Position=UDim2.new(1,-28,0,22); card.Arrow.TextColor3=Color3.fromRGB(163,178,196)
    local mark=text(card,"MatchFormat",item[4],0,28,solo and 10 or 17,white)
    mark.Position=UDim2.new(1,-114,0,20); mark.Size=UDim2.fromOffset(72,28)
    mark.TextXAlignment=Enum.TextXAlignment.Center; mark.Font=Enum.Font.GothamMedium; mark.ZIndex=3
    mark.BackgroundTransparency=0; mark.BackgroundColor3=Color3.fromRGB(33,44,61)
    Instance.new("UICorner",mark).CornerRadius=UDim.new(0,5)
   end
   local practiceSection=text(panel,"PracticeSection","WARM UP",396,16,10,muted)
   practiceSection.Position=UDim2.fromOffset(24,396); practiceSection.Font=Enum.Font.GothamMedium
   table.insert(controls,practiceSection)
   textAction("Back","Back",488,function() stage="Modes"; render() end)
  elseif stage=="Queued" or stage=="Joining" then
   status.Text=stage=="Joining" and "Joining queue..." or mode.." / "..format.." / Waiting for players and an available court."
   local queueCard=Instance.new("Frame",panel); queueCard.Name="QueueStatus"; queueCard.BackgroundTransparency=1
   queueCard.Position=UDim2.fromOffset(24,156); queueCard.Size=UDim2.new(1,-48,0,128); neon(queueCard,cyan); table.insert(controls,queueCard)
   local count=text(queueCard,"QueueCount",stage=="Joining" and "CONNECTING..." or group.count.." / "..group.required.." PLAYERS",32,64,30,cyan)
   table.insert(controls,count)
   textAction("CancelQueue","Leave queue",350,function() queue:FireServer("Cancel") end)
  elseif nextView=="Vote" then
   for index,map in ipairs({"Rooftop","Moon"}) do
    local card=button(map,string.upper(map),"",136,function() queue:FireServer("Vote",map) end,stage=="Setup",cyan,248)
    card.Position=UDim2.fromOffset(24+(index-1)*196,136); card.Size=UDim2.fromOffset(176,248)
    card:SetAttribute("VoteCard",true); card:SetAttribute("MatchChoice",true)
    card.BackgroundColor3=Color3.fromRGB(24,31,48)
    card.Accent.Color=Color3.fromRGB(113,146,171); card.Accent.Transparency=0.85; card.Accent.Thickness=1
    card:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,8)
    card.ModeIcon.Visible=false; card.Arrow.Visible=false
    Thumbnail.mount(card,map)
    card.Title.Position=UDim2.fromOffset(14,156); card.Title.Size=UDim2.new(1,-28,0,24); card.Title.TextSize=17; card.Title.Font=Enum.Font.GothamBold
    card.Detail.Position=UDim2.fromOffset(14,184); card.Detail.Size=UDim2.new(1,-28,0,18); card.Detail.TextSize=12; card.Detail.Font=Enum.Font.GothamMedium
    local selected=text(card,"Selection","YOUR PICK",18,20,10,cyan)
    selected.Position=UDim2.fromOffset(20,20); selected.Size=UDim2.fromOffset(92,22)
    selected.BackgroundTransparency=0; selected.BackgroundColor3=Color3.fromRGB(13,19,31); selected.TextXAlignment=Enum.TextXAlignment.Center
    local pill=Instance.new("UICorner",selected); pill.CornerRadius=UDim.new(0,6)
    selected.ZIndex=4; selected.Visible=false
    local heads=Instance.new("Frame",card); heads.Name="Voters"; heads.BackgroundTransparency=1
    heads.Position=UDim2.fromOffset(14,208); heads.Size=UDim2.new(1,-28,0,30)
   end
   local footerY=400
   if mode~="Classic" then
    local gravity=button("LowGravity","Low gravity","",footerY,function()
     local own=ownVote(); local modifier=own and own.modifier or "None"
     queue:FireServer("Vote",nil,modifier=="LowGravity" and "None" or "LowGravity")
    end,stage=="Setup" and mode=="Arcade",cyan,64)
    gravity:SetAttribute("GameTile",true); gravity:SetAttribute("MatchChoice",true)
    gravity.BackgroundColor3=Color3.fromRGB(24,31,48)
    gravity.Accent.Color=Color3.fromRGB(113,146,171); gravity.Accent.Transparency=0.85; gravity.Accent.Thickness=1
    gravity:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,8)
    gravity.ModeIcon.Visible=false; gravity.Arrow.Visible=false
    gravity.Title.Position=UDim2.fromOffset(16,10); gravity.Title.Size=UDim2.fromOffset(220,24)
    gravity.Title.Font=Enum.Font.GothamBold; gravity.Title.TextSize=16
    gravity.Detail.Position=UDim2.fromOffset(16,36); gravity.Detail.Size=UDim2.fromOffset(244,18)
    gravity.Detail.Font=Enum.Font.GothamMedium; gravity.Detail.TextSize=11
    local setting=text(gravity,"Setting","",0,28,10,cyan)
    setting.Position=UDim2.new(1,-104,0,18); setting.Size=UDim2.fromOffset(88,28)
    setting.TextXAlignment=Enum.TextXAlignment.Center; setting.Font=Enum.Font.GothamBold
    setting.BackgroundTransparency=0; setting.BackgroundColor3=Color3.fromRGB(33,44,61)
    Instance.new("UICorner",setting).CornerRadius=UDim.new(0,5)
    footerY+=76
   end
   textAction("CancelQueue","Leave queue",footerY,function() queue:FireServer("Cancel") end)
   updateVote()
  end
  fitContent()
 end
 local connection=queue.OnClientEvent:Connect(function(data)
  if data.stage=="Error" then
   if stage=="Joining" then stage="Players"; render() end
   status.Text=data.message; return
  end
  if data.stage=="Cancelled" then group=nil; mode=nil; format=nil; stage="Modes"
  else group=data; mode=data.mode; format=data.format; stage=data.stage end
  render()
 end)
 local frames=game:GetService("RunService").RenderStepped:Connect(timer)
 local statusChanged=status:GetPropertyChangedSignal("Text"):Connect(fitContent)
 local function destroy()
  if connection then connection:Disconnect(); connection=nil end
  if frames then frames:Disconnect(); frames=nil end
  if statusChanged then statusChanged:Disconnect(); statusChanged=nil end
 end
 panel.Destroying:Connect(destroy)
 render()
 return {reset=function()
  if group or stage=="Joining" then return end
  stage="Modes"; render()
 end,destroy=destroy}
end
return Flow
