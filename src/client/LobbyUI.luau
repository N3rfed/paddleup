local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ProximityPromptService=game:GetService("ProximityPromptService")
local LobbyUI={}
function LobbyUI.start(network)
 local player=Players.LocalPlayer
 local remote=network:WaitForChild("Lobby")
 local gui=Instance.new("ScreenGui"); gui.Name="SkylineLobbyUI"; gui.ResetOnSpawn=false
 gui.IgnoreGuiInset=true; gui.DisplayOrder=20; gui.Parent=player:WaitForChild("PlayerGui")
 local mint=Color3.fromRGB(92,233,190)
 local cream=Color3.fromRGB(247,239,215)
 local muted=Color3.fromRGB(160,187,189)
 local dark=Color3.fromRGB(17,32,40)
 local function frame(parent,x,y,w,h,color)
  local f=Instance.new("Frame"); f.Position=UDim2.fromOffset(x,y); f.Size=UDim2.fromOffset(w,h)
  f.BackgroundColor3=color or dark; f.BorderSizePixel=0; f.Parent=parent
  local corner=Instance.new("UICorner",f); corner.CornerRadius=UDim.new(0,14)
  return f
 end
 local function label(parent,value,x,y,w,h,size,color)
  local t=Instance.new("TextLabel"); t.BackgroundTransparency=1; t.Position=UDim2.fromOffset(x,y)
  t.Size=UDim2.fromOffset(w,h); t.Text=value; t.TextColor3=color or cream
  t.Font=Enum.Font.GothamMedium; t.TextSize=size or 16; t.TextXAlignment=Enum.TextXAlignment.Left
  t.TextWrapped=true; t.Parent=parent; return t
 end
 local function button(parent,value,x,y,w,h,callback,primary)
  local b=Instance.new("TextButton"); b.Name=value:gsub("[^%w]",""); b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(w,h)
  b.BackgroundColor3=primary and mint or Color3.fromRGB(37,61,69); b.TextColor3=primary and dark or cream
  b.BorderSizePixel=0; b.Text=value; b.Font=Enum.Font.GothamBold; b.TextSize=15; b.Parent=parent
  local corner=Instance.new("UICorner",b); corner.CornerRadius=UDim.new(0,10)
  b.Activated:Connect(callback); return b
 end
 local canvas=frame(gui,0,0,1040,660)
 canvas.Name="QueueMenu"; canvas.Visible=false
 canvas.AnchorPoint=Vector2.new(0.5,0.5); canvas.Position=UDim2.fromScale(0.5,0.5)
 canvas.BackgroundTransparency=0.04
 local scale=Instance.new("UIScale",canvas)
 label(canvas,"PADDLE UP!",30,20,550,48,34,mint).Font=Enum.Font.GothamBlack
 label(canvas,"SKYLINE CLUB  /  LOBBY",32,68,600,24,13,muted)
 local statusLabel=label(canvas,"Choose your next match.",30,105,980,28,18)
 local left=frame(canvas,24,150,465,394,Color3.fromRGB(24,44,52))
 left.Name="MatchControls"
 label(left,"01   FIND YOUR MATCH",20,16,420,25,13,mint)
 local mode="1v1"
 local difficulty="Normal"
 local menuOpen=false
 local data
 local render
 local singles=button(left,"1 v 1",20,55,132,56,function() mode="1v1"; if render then render() end end,true)
 local doubles=button(left,"2 v 2",165,55,132,56,function() mode="2v2"; if render then render() end end)
 local practice=button(left,"PRACTICE",310,55,132,56,function() mode="Practice"; if render then render() end end)
 local difficultyButtons={}
 for i,name in ipairs({"Easy","Normal","Hard"}) do
  difficultyButtons[name]=button(left,string.upper(name),20+(i-1)*145,122,132,30,function()
   difficulty=name; if render then render() end
  end)
  difficultyButtons[name].Visible=false
 end
 local modeDetail=label(left,"",20,130,422,57,15,muted)
 local queueButton=button(left,"QUEUE WITH RANDOMS",20,206,422,52,function()
  if data and data.queue then remote:FireServer("CancelQueue")
  elseif data and data.leader==player.UserId then
   if mode=="Practice" then remote:FireServer("Practice",difficulty) else remote:FireServer("Queue",mode) end
  end
 end,true)
 local counts=label(left,"",20,266,422,30,13,muted)
 local matchText=label(left,"Court available",20,301,422,38,14)
 local watch=button(left,"SPECTATE MATCH",20,345,422,34,function() if data and data.match then remote:FireServer("Spectate") end end)
 local right=frame(canvas,505,150,511,394,Color3.fromRGB(24,44,52))
 right.Name="PartyControls"
 label(right,"02   PARTY WITH FRIENDS",20,16,470,25,13,mint)
 local partyText=label(right,"",20,48,470,50,16)
 local partyHint=label(right,"Invite players from this lobby. Party limit: 4.",20,103,470,35,13,muted)
 local leaveParty=button(right,"LEAVE PARTY",326,16,165,29,function() remote:FireServer("LeaveParty") end)
 local list=Instance.new("ScrollingFrame"); list.Position=UDim2.fromOffset(20,148); list.Size=UDim2.fromOffset(471,226)
 list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=4; list.ScrollBarImageColor3=mint
 list.CanvasSize=UDim2.fromOffset(0,0); list.Parent=right
 local listKey
 local notice=label(canvas,"",30,552,980,33,15,mint)
 local inviteBar=frame(canvas,24,594,992,48,Color3.fromRGB(37,61,69)); inviteBar.Visible=false
 local inviteText=label(inviteBar,"",14,4,640,40,15)
 button(inviteBar,"ACCEPT",690,7,136,34,function() remote:FireServer("Accept") end,true)
 button(inviteBar,"DECLINE",838,7,136,34,function() remote:FireServer("Decline") end)
 local footer=label(canvas,"One rooftop court. Full teams only. First to 11, win by two.",30,601,965,30,13,muted)
 button(canvas,"BACK TO TERRACE",798,27,212,43,function() menuOpen=false; if render then render() end end)
 local lobbyBar=frame(gui,0,0,630,76)
 lobbyBar.Name="LobbyBar"
 lobbyBar.AnchorPoint=Vector2.new(0.5,0); lobbyBar.Position=UDim2.new(0.5,0,0,16)
 local lobbyBarScale=Instance.new("UIScale",lobbyBar)
 local lobbyHint=label(lobbyBar,"Walk to a station to play, practice, or spectate.",16,10,399,56,14)
 button(lobbyBar,"PLAY / PARTY",428,18,188,40,function() menuOpen=true; if render then render() end end,true)
 local bar=frame(gui,0,0,630,58)
 bar.Name="MatchBar"
 bar.AnchorPoint=Vector2.new(0.5,0); bar.Position=UDim2.new(0.5,0,0,110); bar.Visible=false
 local barScale=Instance.new("UIScale",bar)
 local viewing=label(bar,"",16,6,405,46,14)
 local leave
 leave=button(bar,"BACK TO LOBBY",428,10,188,38,function()
  if data and data.status=="Playing" then
   if leave.Text=="CONFIRM LEAVE" then remote:FireServer("LeaveMatch") else leave.Text="CONFIRM LEAVE" end
  else remote:FireServer("Back") end
 end)
 local lastStatus
 render=function()
  if not data then return end
  if lastStatus~=data.status then
   menuOpen=false
   leave.Text=data.status=="Playing" and "LEAVE MATCH" or "BACK TO LOBBY"; lastStatus=data.status
  end
  canvas.Visible=data.status=="Lobby" and menuOpen; bar.Visible=data.status~="Lobby"
  lobbyBar.Visible=data.status=="Lobby" and not menuOpen
  gui:SetAttribute("MenuOpen",canvas.Visible)
  lobbyHint.Text=data.queue and ("QUEUED: "..data.queue.."  /  Explore while you wait.")
   or "Walk to a station. Click to swing. Hold Alt to use menus."
  singles.BackgroundColor3=mode=="1v1" and mint or Color3.fromRGB(37,61,69)
  doubles.BackgroundColor3=mode=="2v2" and mint or Color3.fromRGB(37,61,69)
  singles.TextColor3=mode=="1v1" and dark or cream; doubles.TextColor3=mode=="2v2" and dark or cream
  practice.BackgroundColor3=mode=="Practice" and mint or Color3.fromRGB(37,61,69)
  practice.TextColor3=mode=="Practice" and dark or cream
  for name,b in pairs(difficultyButtons) do
   b.Visible=mode=="Practice"
   b.BackgroundColor3=difficulty==name and mint or Color3.fromRGB(37,61,69)
   b.TextColor3=difficulty==name and dark or cream
  end
  local names={}
  for _,p in ipairs(data.party) do table.insert(names,p.name..(p.id==data.leader and " (leader)" or "")) end
  partyText.Text=table.concat(names,"  +  ")
  leaveParty.Visible=#data.party>1
  local leader=data.leader==player.UserId
  modeDetail.Position=UDim2.fromOffset(20,mode=="Practice" and 158 or 130)
  modeDetail.Size=UDim2.fromOffset(422,mode=="Practice" and 41 or 57)
  modeDetail.Text=mode=="Practice" and (difficulty=="Easy" and "A slower bot with more forgiving mistakes." or difficulty=="Hard" and "Quick reactions, accurate returns, fewer mistakes." or "Balanced reactions and accuracy for a solid warm-up.")
   or mode=="1v1" and "Solo: find an opponent. Party of two: face your friend."
   or "Solo: find a teammate. Party of two: stay together. Party of 3 or 4: split in party order."
  if data.queue then
   statusLabel.Text="Queued for "..data.queue.."  /  "..(data.queue=="Practice" and "Waiting for the court" or "Waiting for a full match and an open court")
   queueButton.Text="LEAVE "..data.queue.." QUEUE"
  else
   statusLabel.Text=leader and "Choose a mode, then join the queue." or "Your party leader will choose the mode and queue."
   queueButton.Text=not leader and "WAITING FOR PARTY LEADER" or mode=="Practice" and ("PRACTICE / "..string.upper(difficulty)) or #data.party>1 and "QUEUE WITH PARTY" or "QUEUE WITH RANDOMS"
  end
  queueButton.Active=data.queue~=nil or leader; queueButton.AutoButtonColor=queueButton.Active
  counts.Text=string.format("IN QUEUE    1v1: %d players    /    2v2: %d players",data.counts["1v1"],data.counts["2v2"])
  local match=data.match
  local description="Court available / waiting for players"
  if match then
   local function team(teamPlayers)
    local result={}; for _,p in ipairs(teamPlayers) do table.insert(result,p.name) end
    return table.concat(result," + ")
   end
   description=match.mode..(match.difficulty and " ("..match.difficulty..")" or "").."  /  "..team(match.home).." vs "..team(match.away)
  end
  matchText.Text=description
  viewing.Text=(data.status=="Spectating" and "WATCHING  " or "Alt: menu  /  ")..description
  watch.Text=match and "SPECTATE MATCH" or "NO MATCH RUNNING"
  watch.Active=match~=nil; watch.AutoButtonColor=watch.Active
  inviteBar.Visible=data.invite~=nil; footer.Visible=not inviteBar.Visible
  if data.invite then inviteText.Text=data.invite.name.." invited you to their party." end
  local key=tostring(leader)..":"..tostring(data.queue)
  for _,p in ipairs(data.players) do key..=":"..p.id..":"..tostring(p.available) end
  if key~=listKey then
   listKey=key; list:ClearAllChildren()
   local row=0
   for _,person in ipairs(data.players) do
    if person.id~=player.UserId then
     local y=row*54; row+=1
     label(list,person.name.."  @"..person.username,0,y,326,44,14,person.available and cream or muted)
     local invite=button(list,person.available and "INVITE" or "BUSY",333,y+5,123,34,function()
      if data.leader==player.UserId and not data.queue and person.available then remote:FireServer("Invite",person.id) end
     end)
     invite.Active=leader and not data.queue and person.available
     invite.AutoButtonColor=invite.Active
    end
   end
   if row==0 then label(list,"Your friends will appear here when they join this server.",0,0,444,65,15,muted) end
   list.CanvasSize=UDim2.fromOffset(0,row*54)
  end
  partyHint.Text=#data.party>1 and "Doubles pairs stay on the same team. Leader controls the queue." or "Invite players from this lobby. Party limit: 4."
 end
 local lastInvite
 remote.OnClientEvent:Connect(function(update)
  data=update
  if update.message then notice.Text=update.message end
  render()
  local invitation=update.invite and update.invite.id
  if invitation and invitation~=lastInvite and update.status=="Lobby" then menuOpen=true; render() end
  lastInvite=invitation
 end)
 ProximityPromptService.PromptTriggered:Connect(function(prompt)
  local station=prompt.Parent and prompt.Parent:GetAttribute("LobbyStation")
  if not station or not data or data.status~="Lobby" then return end
  if station=="Spectate" and data.match then remote:FireServer("Spectate"); return end
  if station~="Spectate" then mode=station end
  menuOpen=true; render()
 end)
 RunService.RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera then
   scale.Scale=math.min(1,(camera.ViewportSize.X-24)/1040,(camera.ViewportSize.Y-40)/660)
   barScale.Scale=math.min(1,(camera.ViewportSize.X-24)/630)
   local hudScale=math.min(camera.ViewportSize.X/1280,camera.ViewportSize.Y/800)
   bar.Position=UDim2.new(0.5,0,0,(camera.ViewportSize.Y-800*hudScale)/2+98*hudScale)
   lobbyBarScale.Scale=barScale.Scale
  end
 end)
 remote:FireServer("Refresh")
 return gui
end
return LobbyUI
