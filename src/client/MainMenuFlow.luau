local Flow={}
local Art=require(script.Parent:WaitForChild("MenuArt"))
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
  label.TextXAlignment=Enum.TextXAlignment.Left; label.TextSize=size; label.Font=Enum.Font.GothamBold
  label.TextTruncate=Enum.TextTruncate.AtEnd
  return label
 end
 local function button(name,title,description,y,action,enabled,accent,height)
  local b=Instance.new("TextButton",panel); table.insert(controls,b); buttons[name]=b
  b.Name=name; b.Position=UDim2.fromOffset(24,y); b.Size=UDim2.new(1,-48,0,height or 58)
  b.BackgroundColor3=navy; b.Text=""; b.Selectable=enabled~=false; b.BorderSizePixel=0
  b.AutoButtonColor=false; b.Active=enabled~=false
  local corner=Instance.new("UICorner",b); corner.CornerRadius=UDim.new(0,12)
  local stroke=Instance.new("UIStroke",b); stroke.Name="Accent"; stroke.Color=accent or cyan; stroke.Transparency=0.65; stroke.Thickness=1.5
  b.BackgroundColor3=Color3.fromRGB(36,36,77)
  local primary=text(b,"Title",title,9,22,17,white)
  primary.Position=UDim2.fromOffset(72,9); primary.Size=UDim2.new(1,-108,0,22)
  local detail=text(b,"Detail",description,34,24,13,muted); detail.Font=Enum.Font.GothamBold
  detail.Position=UDim2.fromOffset(72,33); detail.Size=UDim2.new(1,-88,0,18)
  detail.TextWrapped=true; detail.TextTruncate=Enum.TextTruncate.None
  local badge=Instance.new("Frame",b); badge.Name="ModeIcon"
  badge.Position=UDim2.fromOffset(14,13); badge.Size=UDim2.fromOffset(44,36)
  badge.BackgroundColor3=accent or cyan; badge.BackgroundTransparency=0.9; badge.BorderSizePixel=0
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
  local arrow=text(b,"Arrow",">",9,24,18,accent or cyan)
  arrow.Position=UDim2.new(1,-30,0,9); arrow.Size=UDim2.fromOffset(18,24)
  local pop=Instance.new("UIScale",b); pop.Name="HoverScale"
  b.Activated:Connect(function() if b.Active then action() end end)
  local function hover(on)
   local active=on and b.Active
   TweenService:Create(pop,TweenInfo.new(0.16,Enum.EasingStyle.Quad),{Scale=active and 1.012 or 1}):Play()
   if b:GetAttribute("GameTile") then
    TweenService:Create(b,TweenInfo.new(0.16),{BackgroundColor3=active and Color3.fromRGB(45,45,88) or Color3.fromRGB(36,36,77)}):Play()
    TweenService:Create(b.Accent,TweenInfo.new(0.16),{Transparency=active and 0.05 or 0.6}):Play()
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
 local function gameTile(card,kind,accent)
  card:SetAttribute("GameTile",true)
  card.ModeIcon.Visible=false; card.Arrow.Visible=false
  card.BackgroundColor3=Color3.fromRGB(36,36,77)
  card.Accent.Color=accent; card.Accent.Thickness=1.5; card.Accent.Transparency=0.6
  card.Title.Font=Enum.Font.GothamBold; card.Title.TextColor3=white
  card.Title.Rotation=0; card.Title.ZIndex=3
  card.Detail.TextColor3=muted; card.Detail.Font=Enum.Font.GothamBold; card.Detail.ZIndex=3
  local art=Art.mount(card,kind,accent)
  art.ZIndex=2
  return art
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
     card.Accent.Thickness=map==highlighted and 3 or 1
     card.Accent.Transparency=map==highlighted and 0 or 0.7
     card.BackgroundColor3=map==highlighted and Color3.fromRGB(48,48,99) or navy
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
   card.Accent.Thickness=own and own.map==map and 3 or 1.5
   card.Accent.Transparency=own and own.map==map and 0 or 0.65
   card:SetAttribute("Selected",own~=nil and own.map==map)
   card.BackgroundColor3=own and own.map==map and Color3.fromRGB(53,55,101) or navy
   card.Arrow.Text=own and own.map==map and utf8.char(10003) or ">"
  end
  for index,label in ipairs(rows) do
   local entry=group.roster and group.roster[index]
   label.Text=entry and ((entry.player==player and "YOU" or entry.name).."  >  "..(entry.map and string.upper(entry.map) or "CHOOSING...")) or ""
   label.TextColor3=entry and entry.map and (entry.map=="Moon" and cyan or pink) or muted
  end
  if buttons.LowGravity then
   local modifier=stage=="Reveal" and group.modifier or (own and own.modifier or group.modifier)
   buttons.LowGravity.Title.Text="LOW GRAVITY  /  "..(modifier=="LowGravity" and "ON" or "OFF")
   buttons.LowGravity.Detail.Text=stage=="Reveal" and "Match setting" or (mode=="Chaos" and "Always on in Chaos" or "Toggle before choosing a map")
   buttons.LowGravity.Active=stage=="Setup" and mode=="Arcade"; buttons.LowGravity.Selectable=buttons.LowGravity.Active
  end
  status.Text=mode=="Arcade" and "Choose Low Gravity before picking your map."
   or "Starts when everyone picks a map. Tied maps enter a random draw."
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
  if heading then heading.Text=stage=="Modes" and "LET'S PLAY!" or stage=="Players" and "PICK YOUR MATCH!" or nextView=="Vote" and "PICK A COURT!" or "FINDING PLAYERS" end
  if step then step.Text=mode and (string.upper(mode)..(format and " / "..format or "")) or "CHOOSE A MODE" end
  if stage=="Modes" then
   status.Text=""
   for index,item in ipairs({{"Classic","Standard rules",cyan},{"Arcade","Low Gravity option",Color3.fromRGB(169,151,255)},{"Chaos","Powerups on!",pink}}) do
    local card=button(item[1],string.upper(item[1]),item[2],120+(index-1)*100,function() mode=item[1]; stage="Players"; render() end,true,item[3],88)
    local art=gameTile(card,item[1],item[3])
    art.Position=UDim2.fromOffset(214,0); art.Size=UDim2.fromOffset(150,88)
    card.Title.TextSize=26; card.Title.Position=UDim2.fromOffset(18,13); card.Title.Size=UDim2.fromOffset(190,34)
    card.Detail.Position=UDim2.fromOffset(18,50); card.Detail.Size=UDim2.fromOffset(190,24); card.Detail.TextSize=13
   end
   button("Spectate","WATCH","Spectate a match",420,function() network.Session:FireServer("Spectate") end,true,cyan,58)
  elseif stage=="Players" then
   status.Text=""
   for index,item in ipairs({{"Practice","Warm up your shots"},{"1V1","Singles"},{"1V2","One against two"},{"2V2","Doubles"}}) do
    local card=button(item[1],string.upper(item[1]),item[2],146+math.floor((index-1)/2)*164,function()
     format=item[1]; stage="Joining"; render(); queue:FireServer("Join",mode,format)
    end,true,index%2==0 and pink or cyan,150)
    card.Position=UDim2.fromOffset(24+((index-1)%2)*192,120+math.floor((index-1)/2)*144)
    card.Size=UDim2.fromOffset(180,132)
    local art=gameTile(card,item[1],index%2==0 and pink or cyan)
    art.Position=UDim2.fromOffset(0,0); art.Size=UDim2.fromOffset(180,84)
    card.Title.Position=UDim2.fromOffset(10,76); card.Title.Size=UDim2.new(1,-20,0,28); card.Title.TextSize=item[1]=="Practice" and 21 or 26
    card.Title.TextXAlignment=Enum.TextXAlignment.Center
    card.Detail.Position=UDim2.fromOffset(10,105); card.Detail.Size=UDim2.new(1,-20,0,20); card.Detail.TextXAlignment=Enum.TextXAlignment.Center
   end
   button("Back","BACK","Choose another mode",408,function() stage="Modes"; render() end,true,cyan,58)
  elseif stage=="Queued" or stage=="Joining" then
   status.Text=stage=="Joining" and "Joining queue..." or mode.." / "..format.." / Waiting for players and an available court."
   local count=text(panel,"QueueCount",stage=="Joining" and "CONNECTING..." or group.count.." / "..group.required.." PLAYERS",190,64,30,cyan)
   table.insert(controls,count)
   button("CancelQueue","LEAVE QUEUE","Return to game modes",350,function() queue:FireServer("Cancel") end,true,pink)
  elseif nextView=="Vote" then
   for index,map in ipairs({"Rooftop","Moon"}) do
    local card=button(map,string.upper(map),"",136,function() queue:FireServer("Vote",map) end,stage=="Setup",index==1 and pink or cyan,260)
    card.Position=UDim2.fromOffset(24+(index-1)*196,136); card.Size=UDim2.fromOffset(176,260)
    card.ModeIcon.Visible=false; card.Arrow.Visible=false
    Thumbnail.mount(card,map)
    card.Title.Position=UDim2.fromOffset(14,160); card.Title.Size=UDim2.new(1,-28,0,24); card.Title.TextSize=18
    card.Detail.Position=UDim2.fromOffset(14,190); card.Detail.Size=UDim2.new(1,-28,0,18); card.Detail.TextSize=12
    local selected=text(card,"Selection","YOUR PICK",18,20,10,cyan)
    selected.Position=UDim2.fromOffset(20,20); selected.Size=UDim2.fromOffset(92,22)
    selected.BackgroundTransparency=0.05; selected.BackgroundColor3=navy; selected.TextXAlignment=Enum.TextXAlignment.Center
    local pill=Instance.new("UICorner",selected); pill.CornerRadius=UDim.new(0,6)
    selected.ZIndex=4; selected.Visible=false
    local heads=Instance.new("Frame",card); heads.Name="Voters"; heads.BackgroundTransparency=1
    heads.Position=UDim2.fromOffset(14,216); heads.Size=UDim2.new(1,-28,0,30)
   end
   local footerY=416
   if mode~="Classic" then
    button("LowGravity","",mode=="Chaos" and "Required for Chaos" or "Your modifier vote / majority wins",footerY,function()
     local own=ownVote(); local modifier=own and own.modifier or "None"
     queue:FireServer("Vote",nil,modifier=="LowGravity" and "None" or "LowGravity")
    end,stage=="Setup" and mode=="Arcade",cyan)
    footerY+=78
   end
   button("CancelQueue","LEAVE QUEUE","Return to game modes",footerY,function() queue:FireServer("Cancel") end,true,pink)
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
