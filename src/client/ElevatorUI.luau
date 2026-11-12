local UI={}
function UI.start(player,network)
 local RunService=game:GetService("RunService")
 local TweenService=game:GetService("TweenService")
 local UIS=game:GetService("UserInputService")
 local remote=network:WaitForChild("Elevator")
 local gui=Instance.new("ScreenGui"); gui.Name="ElevatorParty"; gui.ResetOnSpawn=false
 gui.DisplayOrder=90; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
 local dark=Color3.fromRGB(27,27,64); local cream=Color3.fromRGB(246,246,255); local cyan=Color3.fromRGB(80,232,255)
 local party,offer,notice
 local function box(name,size,position)
  local f=Instance.new("Frame"); f.Name=name; f.Size=size; f.Position=position; f.AnchorPoint=Vector2.new(0.5,0.5)
  f.BackgroundColor3=dark; f.BorderSizePixel=0; f.Visible=false; f.Parent=gui
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,18); corner.Parent=f
  local stroke=Instance.new("UIStroke"); stroke.Color=cyan; stroke.Transparency=0.4; stroke.Parent=f
  return f
 end
 local panel=box("Party",UDim2.fromOffset(440,340),UDim2.fromScale(0.5,0.5))
 local invitation=box("Invitation",UDim2.fromOffset(440,210),UDim2.fromScale(0.5,0.5))
 local message=box("Status",UDim2.fromOffset(520,100),UDim2.fromScale(0.5,0.12))
 local function label(parent,name,y,height,text,size)
  local t=Instance.new("TextLabel"); t.Name=name; t.Position=UDim2.new(0,20,0,y); t.Size=UDim2.new(1,-40,0,height)
  t.BackgroundTransparency=1; t.TextColor3=cream; t.TextWrapped=true; t.Font=Enum.Font.GothamBold
  t.TextSize=size or 18; t.Text=text or ""; t.Parent=parent; return t
 end
 local function button(parent,name,text,x,y,width,callback)
  local b=Instance.new("TextButton"); b.Name=name; b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(width,44)
  b.BackgroundColor3=cyan; b.TextColor3=dark; b.Font=Enum.Font.GothamBold; b.TextSize=17; b.Text=text
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=b
  b.Parent=parent; b.Activated:Connect(callback); return b
 end
 local title=label(panel,"Title",16,32,"",24)
 local status=label(panel,"Status",52,40)
 local roster=label(panel,"Roster",96,100,"",16)
 local ready=button(panel,"Ready","READY UP",20,210,400,function() if party then remote:FireServer("Ready",{revision=party.revision}) end end)
 local classic=button(panel,"Classic","Classic",20,210,194,function() if party then remote:FireServer("Vote",{revision=party.revision,mode="Classic"}) end end)
 local chaos=button(panel,"Chaotic","Chaotic",226,210,194,function() if party then remote:FireServer("Vote",{revision=party.revision,mode="Chaos"}) end end)
 button(panel,"Leave","Leave Elevator",20,274,400,function() remote:FireServer("Leave") end)
 local inviteTitle=label(invitation,"Title",16,44,"",22)
 local inviteDetail=label(invitation,"Detail",64,65,"",16)
 local function respond(accept)
  if offer then remote:FireServer("Response",{id=offer.id,accept=accept}); offer=nil; invitation.Visible=false end
 end
 button(invitation,"Accept","Accept",20,144,194,function() respond(true) end)
 button(invitation,"Decline","Decline",226,144,194,function() respond(false) end)
 local messageText=label(message,"Message",8,84,"",17)
 local Maps=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MapCatalog"))
 local Thumbnail=require(script.Parent:WaitForChild("MapThumbnail"))
 local mapPanel=box("MapVoting",UDim2.fromOffset(660,460),UDim2.fromScale(0.5,0.5))
 local mapTitle=label(mapPanel,"Title",16,34,"CHOOSE YOUR NEXT ARENA",25)
 local mapStatus=label(mapPanel,"Mode",53,28,"",17)
 local mapTimer=label(mapPanel,"Timer",84,22,"",14); mapTimer.TextColor3=cyan
 local cardList=Instance.new("ScrollingFrame"); cardList.Name="Maps"; cardList.Position=UDim2.fromOffset(20,113)
 cardList.Size=UDim2.new(1,-40,0,280); cardList.BackgroundTransparency=1; cardList.BorderSizePixel=0
 cardList.ScrollBarThickness=3; cardList.ScrollBarImageColor3=cyan; cardList.CanvasSize=UDim2.new()
 cardList.AutomaticCanvasSize=Enum.AutomaticSize.X; cardList.ScrollingDirection=Enum.ScrollingDirection.X; cardList.Parent=mapPanel
 local layout=Instance.new("UIListLayout"); layout.FillDirection=Enum.FillDirection.Horizontal
 layout.Padding=UDim.new(0,14); layout.HorizontalAlignment=#Maps.list<=2 and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left; layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=cardList
 local cards={}
 for index,map in ipairs(Maps.list) do
  local card=Instance.new("TextButton"); card.Name=map.id; card.Size=UDim2.fromOffset(300,270)
  card.Text=""; card.BackgroundColor3=Color3.fromRGB(43,42,78); card.BorderSizePixel=0
  card.AutoButtonColor=false; card.LayoutOrder=index; card.Parent=cardList
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,14); corner.Parent=card
  local stroke=Instance.new("UIStroke"); stroke.Color=map.accent; stroke.Thickness=1.5; stroke.Transparency=0.45; stroke.Parent=card
  local glow=Instance.new("UIGradient"); glow.Rotation=45
  glow.Color=ColorSequence.new(Color3.new(1,1,1),map.secondary); glow.Parent=card
  local badge=label(card,"Badge",9,22,map.badge,11); badge.TextColor3=map.accent
  local preview=Thumbnail.mount(card,map.id); preview.Position=UDim2.fromOffset(10,41); preview.Size=UDim2.new(1,-20,0,143)
  local name=label(card,"MapName",188,28,map.name,24)
  local detail=label(card,"Tagline",218,21,map.tagline,13); detail.TextColor3=Color3.fromRGB(205,204,231)
  local votes=label(card,"Votes",243,22,"0 VOTES",13); votes.TextColor3=map.accent
  card.Activated:Connect(function()
   if party then remote:FireServer("MapVote",{revision=party.revision,map=map.id}) end
  end)
  cards[map.id]={button=card,stroke=stroke,votes=votes}
 end
 button(mapPanel,"Leave","Leave Elevator",20,403,620,function() remote:FireServer("Leave") end)
 local mapFade=Instance.new("Frame"); mapFade.Name="MapFade"; mapFade.Size=UDim2.fromScale(1,1)
 mapFade.BackgroundColor3=dark; mapFade.BorderSizePixel=0; mapFade.Visible=false; mapFade.ZIndex=10; mapFade.Parent=gui
 local fadeUntil=0
 local function renderMap()
  if not party or (party.stage~="MapVoting" and party.stage~="Departing") then mapPanel.Visible=false; return end
  mapPanel.Visible=true
  local winning=party.stage=="Departing"
  local selected=party.map and Maps.get(party.map)
  mapTitle.Text=winning and ("NEXT STOP: "..string.upper(selected.name)) or "CHOOSE YOUR NEXT ARENA"
  mapStatus.Text=(party.mode=="Chaos" and "CHAOTIC" or "CLASSIC").."  /  "..party.format:gsub("V","v")
  mapTimer.Text=winning and "WINNING MAP / SEE YOU ON THE COURT"
   or "ONE PICK EACH  /  "..math.max(0,math.ceil(party.endsAt-workspace:GetServerTimeNow())).."s"
  local mine
  for _,entry in ipairs(party.roster) do if entry.userId==player.UserId then mine=entry.mapVote end end
  for id,card in pairs(cards) do
   local picked=winning and id==party.map or not winning and id==mine
   card.stroke.Thickness=picked and 3 or 1.5; card.stroke.Transparency=picked and 0 or 0.5
   card.button.Interactable=not winning and not mine
   local count=party.mapCounts[id] or 0
   card.votes.Text=(picked and (winning and "WINNER  /  " or "YOUR PICK  /  ") or "")..count..(count==1 and " VOTE" or " VOTES")
  end
  if winning and party.endsAt-workspace:GetServerTimeNow()<0.35 and not mapFade.Visible then
   mapFade.Visible=true; mapFade.BackgroundTransparency=1; fadeUntil=workspace:GetServerTimeNow()+5
   TweenService:Create(mapFade,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
  end
 end
 network:WaitForChild("State").OnClientEvent:Connect(function(data)
  if data.matchIntro and data.matchIntro.overview then mapFade.Visible=false end
 end)
 local function renderParty()
  if not party then panel.Visible=false; return end
  panel.Visible=party.stage=="Waiting" or party.stage=="Voting"
  title.Text=party.format:gsub("V","v").." ELEVATOR  /  "..party.count.."/"..party.capacity
  local names={}; local mine
  for _,entry in ipairs(party.roster) do
   table.insert(names,entry.name..(entry.ready and "  / READY" or "  / WAITING"))
   if entry.userId==player.UserId then mine=entry end
  end
  roster.Text=table.concat(names,"\n")
  local voting=party.stage=="Voting"
  ready.Visible=party.stage=="Waiting" and party.count==party.capacity
  ready.Text=mine and mine.ready and "READY  /  "..party.ready.."/"..party.capacity or "READY UP  /  "..party.ready.."/"..party.capacity
  ready.Active=not (mine and mine.ready)
  classic.Visible=voting; chaos.Visible=voting
  classic.Active=voting and party.allowed.Classic==true and not (mine and mine.vote)
  chaos.Active=voting and party.allowed.Chaos==true and not (mine and mine.vote)
  classic.BackgroundTransparency=classic.Active and 0 or 0.65; chaos.BackgroundTransparency=chaos.Active and 0 or 0.65
  classic.Text="Classic  /  "..party.counts.Classic; chaos.Text="Chaotic  /  "..party.counts.Chaos
  status.Text=voting and "VOTE / "..math.max(0,math.ceil(party.endsAt-workspace:GetServerTimeNow())).."s"
   or party.count<party.capacity and "Waiting for friends or invited solo players"
   or party.ready.."/"..party.capacity.." READY"
  if voting and (not party.allowed.Classic or not party.allowed.Chaos) then
   status.Text..=" / Matching the party's mode preferences"
  end
 end
 remote.OnClientEvent:Connect(function(data)
  if type(data)~="table" then return end
  if data.kind=="Party" then
   party=data; renderParty(); renderMap()
   if data.stage~="Departing" then mapFade.Visible=false end
  elseif data.kind=="Closed" then
   party=nil; panel.Visible=false; mapPanel.Visible=false
   mapFade.Visible=data.enteringMap==true; mapFade.BackgroundTransparency=0
   fadeUntil=workspace:GetServerTimeNow()+5
  elseif data.kind=="Invitation" then
   offer=data; invitation.Visible=true
   inviteTitle.Text="An opening is available in a "..data.format:gsub("V","v").." "..(data.replacement and "match!" or "party!")
  elseif data.kind=="InvitationClosed" then if offer and offer.id==data.id then offer=nil; invitation.Visible=false end
  elseif data.kind=="Notice" or data.kind=="Terminated" then
   notice=data; notice.untilAt=data.endsAt or workspace:GetServerTimeNow()+5; message.Visible=true
  end
 end)
 RunService.RenderStepped:Connect(function()
  local now=workspace:GetServerTimeNow()
  if party then renderParty() end
  if offer then
   local seconds=math.max(0,math.ceil(offer.endsAt-now))
   inviteDetail.Text=(offer.mode=="Chaos" and "Chaotic" or offer.mode=="Any" and "Any Mode" or offer.mode)
    .." / "..seconds.."s to respond\nYour current queue is retained until you accept."
   if seconds==0 then invitation.Visible=false end
  end
  if notice then
   messageText.Text=notice.message..(notice.endsAt and " ("..math.max(0,math.ceil(notice.endsAt-now))..")" or "")
   if now>=notice.untilAt then notice=nil; message.Visible=false end
  elseif player:GetAttribute("MatchPaused") then
   message.Visible=true; messageText.Text="MATCH PAUSED / Finding an approved replacement"
  else message.Visible=false end
  if party then renderMap() end
  if mapFade.Visible and now>=fadeUntil then mapFade.Visible=false end
  if party or offer then UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true end
 end)
 local function resize()
  local camera=workspace.CurrentCamera; if not camera then return end
  local scale=math.min(1,(camera.ViewportSize.X-20)/520,(camera.ViewportSize.Y-30)/360)
  local mapScale=mapPanel:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",mapPanel)
  mapScale.Scale=math.min(1,(camera.ViewportSize.X-20)/660,(camera.ViewportSize.Y-30)/460)
  for _,f in ipairs({panel,invitation,message}) do
   local scaler=f:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",f); scaler.Scale=scale
  end
 end
 workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
 RunService.RenderStepped:Connect(resize)
end
return UI
