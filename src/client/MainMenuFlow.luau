local Flow={}
function Flow.start(player,network,panel,status)
 local queue=network:WaitForChild("Queue")
 local mode,format,group
 local stage,view="Modes",nil
 local controls,buttons,rows={},{},{}
 local white=Color3.fromRGB(246,246,255)
 local muted=Color3.fromRGB(181,187,225)
 local cyan=Color3.fromRGB(80,232,255)
 local pink=Color3.fromRGB(255,85,200)
 local navy=Color3.fromRGB(27,27,64)
 local heading=panel:FindFirstChild("Heading")
 local step=panel:FindFirstChild("Step")
 local render,updateVote
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
  b.BackgroundColor3=navy; b.Text=""; b.Selectable=enabled~=false
  b.AutoButtonColor=false; b.Active=enabled~=false
  local corner=Instance.new("UICorner",b); corner.CornerRadius=UDim.new(0,7)
  local stroke=Instance.new("UIStroke",b); stroke.Name="Accent"; stroke.Color=accent or cyan; stroke.Transparency=0.35; stroke.Thickness=1.5
  text(b,"Title",title,8,24,18,accent or white)
  local detail=text(b,"Detail",description,34,20,12,muted); detail.Font=Enum.Font.GothamMedium
  b.Activated:Connect(function() if b.Active then action() end end)
  local function hover(on)
   b.BackgroundColor3=on and b.Active and Color3.fromRGB(43,43,86) or navy
  end
  b.MouseEnter:Connect(function() hover(true) end); b.MouseLeave:Connect(function() hover(false) end)
  b.SelectionGained:Connect(function() hover(true) end); b.SelectionLost:Connect(function() hover(false) end)
  return b
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
   status.Text=progress>=1 and "Next stop: "..group.map..". Your match is starting..." or "Votes are locked. Picking the court..."
  end
 end
 updateVote=function()
  local own=ownVote()
  for _,map in ipairs({"Rooftop","Moon"}) do
   local card=buttons[map]
   local count=group.counts and group.counts[map] or 0
   card.Title.Text=string.upper(map).."  /  "..count..(count==1 and " VOTE" or " VOTES")
   card.Detail.Text=(own and own.map==map and "YOUR PICK  /  " or "")..(map=="Moon" and "SELENE LUNAR COURT" or "SKYLINE CLUB")
   card.Active=stage=="Setup"; card.Selectable=card.Active
   card.Accent.Thickness=own and own.map==map and 3 or 1.5
   card.Accent.Transparency=own and own.map==map and 0 or 0.35
  end
  for index,label in ipairs(rows) do
   local entry=group.roster and group.roster[index]
   label.Text=entry and ((entry.player==player and "YOU" or entry.name).."  >  "..(entry.map and string.upper(entry.map) or "CHOOSING...")) or ""
   label.TextColor3=entry and entry.map and (entry.map=="Moon" and cyan or pink) or muted
  end
  if buttons.LowGravity then
   local modifier=stage=="Reveal" and group.modifier or (own and own.modifier or group.modifier)
   buttons.LowGravity.Title.Text="LOW GRAVITY  /  "..(modifier=="LowGravity" and "ON" or "OFF")
   buttons.LowGravity.Detail.Text=stage=="Reveal" and "Selected match modifier" or (mode=="Chaos" and "Required for Chaos" or "Your modifier vote / majority wins")
   buttons.LowGravity.Active=stage=="Setup" and mode=="Arcade"; buttons.LowGravity.Selectable=buttons.LowGravity.Active
  end
  status.Text=mode=="Arcade" and "Low Gravity uses a majority vote; ties stay off. Arcade features arrive later."
   or "Starts when everyone picks a map. Tied maps enter a random draw."
  timer()
 end
 render=function()
  local nextView=(stage=="Setup" or stage=="Reveal") and "Vote" or stage
  if view==nextView and nextView=="Vote" then updateVote(); return end
  for _,control in ipairs(controls) do control:Destroy() end
  table.clear(controls); table.clear(buttons); table.clear(rows); view=nextView
  if heading then heading.Text=stage=="Modes" and "CHOOSE YOUR MODE" or stage=="Players" and "BUILD YOUR MATCH" or nextView=="Vote" and "PICK YOUR COURT" or "FINDING PLAYERS" end
  if step then step.Text=mode and (string.upper(mode).."  /  "..(format or "PLAYER COUNT")) or "01  /  GAME MODE" end
  if stage=="Modes" then
   status.Text="Pick your rules. Find your team. Own the court."
   for index,item in ipairs({{"Classic","Pure pickleball. Every point is yours.",cyan},{"Arcade","Standard play now. More features coming.",Color3.fromRGB(190,197,255)},{"Chaos","Draft powerups. Rewrite the rally.",pink}}) do
    button(item[1],string.upper(item[1]),item[2],140+(index-1)*82,function() mode=item[1]; stage="Players"; render() end,true,item[3],68)
   end
   button("Spectate","SPECTATE","Catch the action from courtside",408,function() network.Session:FireServer("Spectate") end,true,cyan)
  elseif stage=="Players" then
   status.Text=mode.." / Choose your player count to enter the queue."
   for index,item in ipairs({{"Practice","You and the practice partner"},{"1V1","2 players / singles"},{"1V2","3 players / asymmetric teams"},{"2V2","4 players / doubles"}}) do
    button(item[1],string.upper(item[1]),item[2],140+(index-1)*74,function()
     format=item[1]; stage="Joining"; render(); queue:FireServer("Join",mode,format)
    end,true,index%2==0 and pink or cyan)
   end
   button("Back","< BACK","Choose game mode",450,function() stage="Modes"; render() end)
  elseif stage=="Queued" or stage=="Joining" then
   status.Text=stage=="Joining" and "Joining queue..." or mode.." / "..format.." / Waiting for players and an available court."
   local count=text(panel,"QueueCount",stage=="Joining" and "CONNECTING..." or group.count.." / "..group.required.." PLAYERS",190,64,30,cyan)
   table.insert(controls,count)
   button("CancelQueue","LEAVE QUEUE","Return to game modes",350,function() queue:FireServer("Cancel") end,true,pink)
  elseif nextView=="Vote" then
   for index,map in ipairs({"Rooftop","Moon"}) do
    button(map,string.upper(map),"",140+(index-1)*78,function() queue:FireServer("Vote",map) end,stage=="Setup",index==1 and pink or cyan,68)
   end
   local title=text(panel,"LivePicks","LIVE PLAYER PICKS",300,22,12,muted); table.insert(controls,title)
   for index=1,4 do
    local row=text(panel,"VotePlayer"..index,"",328+(index-1)*27,24,14,white)
    table.insert(rows,row); table.insert(controls,row)
   end
   if mode~="Classic" then
    button("LowGravity","",mode=="Chaos" and "Required for Chaos" or "Your modifier vote / majority wins",450,function()
     local own=ownVote(); local modifier=own and own.modifier or "None"
     queue:FireServer("Vote",nil,modifier=="LowGravity" and "None" or "LowGravity")
    end,stage=="Setup" and mode=="Arcade",cyan)
   end
   button("CancelQueue","LEAVE QUEUE","Return to game modes",524,function() queue:FireServer("Cancel") end,true,pink)
   updateVote()
  end
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
 local function destroy()
  if connection then connection:Disconnect(); connection=nil end
  if frames then frames:Disconnect(); frames=nil end
 end
 panel.Destroying:Connect(destroy)
 render()
 return {reset=function()
  if group or stage=="Joining" then return end
  stage="Modes"; render()
 end,destroy=destroy}
end
return Flow
