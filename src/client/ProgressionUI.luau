-- Presentation only. The server supplies all dates, eligibility, rewards, and progression.
local UI={}
-- Use a server timestamp with the device's local conversion; the device never supplies a reward date.
function UI.deviceOffset(timestamp,api)
 api=api or DateTime
 local ok,result=pcall(function()
  local utc=math.floor(timestamp)
  local localTime=api.fromUnixTimestamp(utc):ToLocalTime()
  local shifted=api.fromUniversalTime(localTime.Year,localTime.Month,localTime.Day,localTime.Hour,localTime.Minute,localTime.Second)
  local minutes=math.floor((shifted.UnixTimestamp-utc)/60+0.5)
  if minutes%15~=0 or minutes < -720 or minutes > 840 then return nil end
  return minutes
 end)
 return ok and result or nil
end
function UI.start(player,network)
 local playerGui=player:WaitForChild("PlayerGui")
 if playerGui:FindFirstChild("PaddleUpProgression") then return end
 local TweenService=game:GetService("TweenService")
 local UIS=game:GetService("UserInputService")
 local CAS=game:GetService("ContextActionService")
 local RunService=game:GetService("RunService")
 local remote=network:WaitForChild("Progression")
 local dark=Color3.fromRGB(27,27,64)
 local cyan=Color3.fromRGB(80,232,255)
 local white=Color3.fromRGB(246,246,255)
 local muted=Color3.fromRGB(181,187,225)
 local green=Color3.fromRGB(111,239,185)
 local gold=Color3.fromRGB(255,214,138)
 local gui=Instance.new("ScreenGui")
 gui.Name="PaddleUpProgression"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
 gui.DisplayOrder=60; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=playerGui
 local connections={}
 local function connect(signal,callback) table.insert(connections,signal:Connect(callback)) end
 local function round(parent,radius)
  local item=Instance.new("UICorner"); item.CornerRadius=UDim.new(0,radius); item.Parent=parent
 end
 local function frame(parent,name,x,y,w,h,color,z)
  local item=Instance.new("Frame"); item.Name=name; item.Position=UDim2.fromOffset(x,y); item.Size=UDim2.fromOffset(w,h)
  item.BorderSizePixel=0; item.BackgroundColor3=color; item.ZIndex=z or 1; item.Parent=parent
  return item
 end
 local function text(parent,value,x,y,w,h,size,color,z)
  local item=Instance.new("TextLabel"); item.Text=value; item.Position=UDim2.fromOffset(x,y); item.Size=UDim2.fromOffset(w,h)
  item.BackgroundTransparency=1; item.Font=Enum.Font.GothamBold; item.TextSize=size; item.TextColor3=color or white
  item.TextXAlignment=Enum.TextXAlignment.Left; item.TextWrapped=true; item.ZIndex=z or 2; item.Parent=parent
  return item
 end
 local function button(parent,value,x,y,w,h,color,z)
  local item=Instance.new("TextButton"); item.Text=value; item.Position=UDim2.fromOffset(x,y); item.Size=UDim2.fromOffset(w,h)
  item.BackgroundColor3=color; item.TextColor3=dark; item.Font=Enum.Font.GothamBold; item.TextSize=14
  item.BorderSizePixel=0; item.ZIndex=z; item.Parent=parent; round(item,12)
  return item
 end
 local function stroke(parent,color)
  local item=Instance.new("UIStroke"); item.Color=color; item.Transparency=0.35; item.Parent=parent; return item
 end
 local profile=frame(gui,"XPProfile",0,78,224,78,dark,1)
 profile.AnchorPoint=Vector2.new(1,0); profile.Position=UDim2.new(1,-16,0,78); round(profile,16); stroke(profile,Color3.fromRGB(85,88,139))
 local profileScale=Instance.new("UIScale",profile)
 local levelLabel=text(profile,"CLUB PROFILE",14,10,196,19,13,cyan)
 local xpLabel=text(profile,"Loading progress...",14,31,196,18,11,muted)
 local profileTrack=frame(profile,"XPTrack",14,58,196,5,Color3.fromRGB(60,61,96),2); round(profileTrack,3)
 local profileFill=frame(profileTrack,"XPProgress",0,0,0,5,cyan,3); round(profileFill,3)
 local overlay=Instance.new("TextButton")
 overlay.Name="DailyCheckInOverlay"; overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(0,0,0)
 overlay.BackgroundTransparency=0.45; overlay.Text=""; overlay.AutoButtonColor=false; overlay.Modal=true
 overlay.BorderSizePixel=0; overlay.Visible=false; overlay.ZIndex=10; overlay.Parent=gui
 local checkmark=utf8.char(10003)
 local panel=frame(overlay,"WeeklyCheckIn",0,0,760,572,dark,11)
 panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5); round(panel,20); stroke(panel,Color3.fromRGB(85,88,139))
 local panelScale=Instance.new("UIScale",panel)
 local brand=text(panel,"P A D D L E U P   /   CLUB REWARDS",28,22,570,22,12,cyan,12)
 local title=text(panel,"Daily Check-In",28,52,640,40,30,white,12)
 local close=button(panel,"CLOSE",636,22,96,32,Color3.fromRGB(60,61,96),12); close.Name="CloseCheckIn"; close.TextColor3=white
 local summary=text(panel,"",28,101,704,24,14,white,12)
 local bar=frame(panel,"XPTrack",28,132,704,6,Color3.fromRGB(60,61,96),12); round(bar,4)
 local fill=frame(bar,"XPProgress",0,0,0,6,cyan,13); round(fill,4)
 local daily=frame(panel,"TodayReward",28,156,704,144,Color3.fromRGB(35,48,78),12); round(daily,14); stroke(daily,cyan)
 text(daily,"DAILY REWARD",18,10,390,20,12,cyan,13)
 local bonus=text(daily,"",18,34,420,36,28,white,13); bonus.Name="DailyBonus"
 local flatReward=text(daily,"",18,116,420,17,11,muted,13)
 local claim=button(daily,"CHECK IN",468,45,218,46,cyan,13); claim.Name="ClaimReward"
 local streak=text(panel,"",28,316,470,24,14,gold,12); streak.Name="WeeklyStreak"
 local calendarHeading=text(panel,"",548,316,184,24,11,muted,12); calendarHeading.Name="UTCToday"; calendarHeading.TextXAlignment=Enum.TextXAlignment.Right
 local progress=frame(panel,"StreakProgress",28,346,704,5,dark,12)
 local segments={}
 for index=1,7 do
  segments[index]=frame(progress,"Segment"..index,(index-1)*102,0,92,5,Color3.fromRGB(60,61,96),13); round(segments[index],3)
 end
 local calendar=Instance.new("ScrollingFrame")
 calendar.Name="Calendar"; calendar.Position=UDim2.fromOffset(28,367); calendar.Size=UDim2.fromOffset(704,104)
 calendar.BackgroundTransparency=1; calendar.BorderSizePixel=0; calendar.ZIndex=12
 calendar.CanvasSize=UDim2.fromOffset(704,0); calendar.ScrollBarThickness=4; calendar.ScrollBarImageColor3=cyan
 calendar.ScrollingDirection=Enum.ScrollingDirection.X; calendar.Parent=panel
 local cards={}
 for index=1,7 do
  local card=frame(calendar,"Day"..index,(index-1)*102,0,92,100,Color3.fromRGB(43,45,82),12); round(card,13)
  cards[index]={frame=card,stroke=stroke(card,Color3.fromRGB(85,88,139)),
   label=text(card,"",10,8,72,18,12,muted,13),date=text(card,"",10,29,72,18,12,white,13),
   mark=text(card,"",10,50,72,23,20,muted,13),status=text(card,"",7,77,78,18,9,muted,13)}
  cards[index].label.Name="Weekday"; cards[index].date.Name="Date"; cards[index].mark.Name="Mark"; cards[index].status.Name="Status"
  for _,name in ipairs({"label","date","mark","status"}) do cards[index][name].TextXAlignment=Enum.TextXAlignment.Center end
 end
 local weeklyBox=frame(panel,"WeeklyReward",28,485,704,64,Color3.fromRGB(39,36,66),12); round(weeklyBox,12)
 local weeklyTitle=text(weeklyBox,"WEEKLY REWARD",16,7,672,18,11,gold,13)
 local weekly=text(weeklyBox,"20% of the XP needed for your next level.",16,27,672,32,12,muted,13)
 local message=text(panel,"",28,555,704,18,11,muted,12)
 local reset=text(panel,"",28,576,704,18,11,muted,12)
 local loading=frame(panel,"DataStatus",28,156,704,390,dark,14)
 local statusLabel=text(loading,"Loading check-in data...",22,94,660,90,15,muted,15); statusLabel.Name="StatusMessage"; statusLabel.TextXAlignment=Enum.TextXAlignment.Center
 local retry=button(loading,"RETRY",267,204,170,44,cyan,15); retry.Name="RetryLoad"; retry.Visible=false
 local toast=frame(gui,"XPNotification",0,0,360,86,dark,20)
 toast.AnchorPoint=Vector2.new(0.5,0); toast.Position=UDim2.new(0.5,0,0,180); toast.Visible=false; round(toast,16); stroke(toast,cyan)
 local toastScale=Instance.new("UIScale",toast)
 local toastTitle=text(toast,"",20,13,320,26,20,cyan,21)
 local toastDetail=text(toast,"",20,43,320,28,12,white,21)
 local state,receivedAt,lastRefresh=nil,os.clock(),0
 local revision,requestId,pendingId,lastOpenId,closedOpenId=0,0,0,0,0
 local contentWidth=704
 local function send(action,value)
  requestId+=1
  remote:FireServer(action,requestId,lastOpenId,value)
  return requestId
 end
 local pending=false
 local requestSentAt=0
 local noticeText
 local toastUntil=0
 local tweens={}
 local function tween(key,item,properties,duration)
  if tweens[key] then tweens[key]:Cancel() end
  local animation=TweenService:Create(item,TweenInfo.new(duration or 0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),properties)
  tweens[key]=animation; animation:Play()
 end
 local function resize()
  local camera=workspace.CurrentCamera
  if not camera then return end
  local compact=camera.ViewportSize.X<620
  local width=compact and math.max(280,camera.ViewportSize.X-24) or 760
  local height=compact and 640 or 572
  local previousWidth=contentWidth
  contentWidth=width-56
  panel.Size=UDim2.fromOffset(width,height)
  panelScale.Scale=math.min(1,(camera.ViewportSize.Y-24)/height,(camera.ViewportSize.X-24)/width)
  profileScale.Scale=math.min(1,math.max(0.6,camera.ViewportSize.X/900))
  brand.Size=UDim2.fromOffset(contentWidth-78,22); brand.TextSize=compact and 9 or 12
  title.Size=UDim2.fromOffset(contentWidth,40); title.TextSize=compact and 25 or 30
  close.Position=UDim2.fromOffset(width-106,22); close.Size=UDim2.fromOffset(78,30)
  summary.Size=UDim2.fromOffset(contentWidth,24); summary.TextSize=compact and 11 or 14
  bar.Size=UDim2.fromOffset(contentWidth,6)
  daily.Size=UDim2.fromOffset(contentWidth,compact and 176 or 124)
  bonus.Size=UDim2.fromOffset(contentWidth-(compact and 36 or 270),36); bonus.TextSize=compact and 24 or 28
  flatReward.Position=UDim2.fromOffset(18,compact and 84 or 88); flatReward.Size=UDim2.fromOffset(contentWidth-36,17)
  claim.Position=UDim2.fromOffset(compact and 18 or contentWidth-236,compact and 118 or 43)
  claim.Size=UDim2.fromOffset(compact and contentWidth-36 or 218,44)
  local streakY=compact and 342 or 292
  streak.Position=UDim2.fromOffset(28,streakY); streak.Size=UDim2.fromOffset(contentWidth,24); streak.TextSize=compact and 13 or 14
  calendarHeading.Visible=true
  calendarHeading.Position=UDim2.fromOffset(compact and 28 or 548,compact and streakY+36 or streakY)
  calendarHeading.Size=UDim2.fromOffset(compact and contentWidth or 184,compact and 12 or 24)
  calendarHeading.TextSize=compact and 9 or 11
  progress.Position=UDim2.fromOffset(28,streakY+30); progress.Size=UDim2.fromOffset(contentWidth,5)
  local segmentWidth=(contentWidth-48)/7
  for index,segment in ipairs(segments) do
   segment.Position=UDim2.fromOffset((index-1)*(segmentWidth+8),0); segment.Size=UDim2.fromOffset(segmentWidth,5)
  end
  calendar.Position=UDim2.fromOffset(28,streakY+51); calendar.Size=UDim2.fromOffset(contentWidth,104)
  weeklyBox.Position=UDim2.fromOffset(28,streakY+169); weeklyBox.Size=UDim2.fromOffset(contentWidth,compact and 80 or 60)
  weeklyTitle.Size=UDim2.fromOffset(contentWidth-32,18); weekly.Size=UDim2.fromOffset(contentWidth-32,compact and 58 or 32)
  message.Position=UDim2.fromOffset(28,height-44); message.Size=UDim2.fromOffset(contentWidth,18)
  reset.Position=UDim2.fromOffset(28,height-23); reset.Size=UDim2.fromOffset(contentWidth,18); reset.TextSize=compact and 10 or 11
  loading.Size=UDim2.fromOffset(contentWidth,height-190)
  statusLabel.Size=UDim2.fromOffset(contentWidth-44,100)
  retry.Position=UDim2.fromOffset((contentWidth-170)/2,214)
  if previousWidth~=contentWidth and state and state.ready then fill.Size=UDim2.fromOffset(contentWidth*math.clamp(state.xp/state.required,0,1),6) end
 end
 local gameplayModes={Practice=true,Spectate=true,["1V1"]=true,["1V2"]=true,["2V2"]=true}
 local function inGameplay()
  return (player:GetAttribute("CourtSide") or 0)~=0 or gameplayModes[player:GetAttribute("SessionMode")]==true
 end
 local function updateVisibility()
  local visible=not inGameplay()
  gui.Enabled=visible
  profile.Visible=visible and not overlay.Visible
 end
 local function setOpen(value)
  if value and inGameplay() then return end
  if overlay.Visible==value then updateVisibility(); return end
  overlay.Visible=value; updateVisibility(); player:SetAttribute("CheckInOpen",value)
  if value then
   resize(); panel.Position=UDim2.new(0.5,0,0.5,18)
   tween("open",panel,{Position=UDim2.fromScale(0.5,0.5)},0.22)
   CAS:BindActionAtPriority("CheckInControls",function() return Enum.ContextActionResult.Sink end,false,
    Enum.ContextActionPriority.High.Value+20,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
    Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Space,Enum.KeyCode.Thumbstick1)
   UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
  else
   closedOpenId=math.max(closedOpenId,lastOpenId)
   CAS:UnbindAction("CheckInControls"); send("Close")
  end
 end
 local automaticRequest,automaticSentAt
 local nextAutomaticAttempt,nextOffsetCheck=0,0
 local function syncDeviceTime()
  if not state or not state.ready or state.pending or pending or automaticRequest or os.clock()<nextAutomaticAttempt then return end
  local offset=UI.deviceOffset(state.serverNow)
  if offset==nil or offset==state.utcOffsetMinutes or offset==state.pendingUtcOffsetMinutes then return end
  local available=state.zoneChangeAvailableAt or 0
  if available>(state.serverNow or 0) then
   nextAutomaticAttempt=os.clock()+available-state.serverNow
   return
  end
  automaticSentAt=os.clock()
  automaticRequest=send("AutoTimeZone",offset)
  nextAutomaticAttempt=os.clock()+60
 end
 local function updateReset()
  if not state or not state.ready or not state.nextReset then reset.Text=""; return end
  local seconds=math.max(0,state.nextReset-(state.serverNow or 0)-(os.clock()-receivedAt))
  reset.Text=string.format("Resets in %dh %02dm",math.floor(seconds/3600),math.floor(seconds%3600/60))
 end
 local function render()
  local estimatedNow=(state and state.serverNow or 0)+(os.clock()-receivedAt)
  local timedOut=state and state.pendingSince and estimatedNow-state.pendingSince>15
   or (not state or state.status=="Loading") and os.clock()-receivedAt>15
   or pending and os.clock()-requestSentAt>15
  local ready=state~=nil and state.ready==true and not timedOut
  loading.Visible=not ready
  daily.Visible=ready; streak.Visible=ready; progress.Visible=ready; calendar.Visible=ready; weeklyBox.Visible=ready; bar.Visible=ready
  summary.Text=""; message.Text=""; message.Visible=false; reset.Text=""; calendarHeading.Text=""
  if not ready then
   levelLabel.Text="CLUB PROFILE"; xpLabel.Text="Progress unavailable"
   local failed=timedOut or state and state.status=="Error" or false
   statusLabel.Text=timedOut and "Taking longer than expected. Please retry."
    or failed and state.error or "Loading check-in data..."
   if not failed then xpLabel.Text="Loading progress..." end
   retry.Visible=failed==true
   local remaining=state and math.max(0,(state.retryAfter or 0)-(os.clock()-receivedAt)) or 0
   retry.Active=failed and remaining==0; retry.AutoButtonColor=retry.Active
   retry.Text=remaining>0 and "RETRY IN "..math.ceil(remaining).."s" or "RETRY"
   claim.Active=false
   for _,card in ipairs(cards) do card.label.Text=""; card.date.Text=""; card.mark.Text=""; card.status.Text="" end
   return
  end
  local ratio=math.clamp(state.xp/state.required,0,1)
  local percent=state.dailyBonusPercent
  levelLabel.Text="LEVEL "..state.level..(state.multiplier>1 and " / +"..percent.."% XP" or "")
  xpLabel.Text=string.format("%d / %d XP",state.xp,state.required)
  summary.Text=string.format("LEVEL %d  /  %d / %d XP",state.level,state.xp,state.required)
  tween("profile",profileFill,{Size=UDim2.fromOffset(196*ratio,5)})
  tween("progress",fill,{Size=UDim2.fromOffset(contentWidth*ratio,6)})
  bonus.Text="+"..percent.."% MATCH XP"
  flatReward.Text="+"..state.dailyXP.." XP FOR CHECKING IN"
  calendarHeading.Text=state.todayLabel:upper()
  streak.Text=string.format("STREAK %d/7",state.cycle)
  for index,segment in ipairs(segments) do segment.BackgroundColor3=index<=state.cycle and gold or Color3.fromRGB(60,61,96) end
  local names={Done="COMPLETED",TodayDone="TODAY / DONE",Available="TODAY",Missed="MISSED",Upcoming="UPCOMING"}
  for index,day in ipairs(state.days) do
   local card=cards[index]
   local done=day.status=="Done" or day.status=="TodayDone"
   local color=done and green or day.status=="Available" and cyan or day.status=="Missed" and Color3.fromRGB(174,135,150) or muted
   card.label.Text=day.label:upper(); card.date.Text=day.shortDate
   card.status.Text=names[day.status]; card.status.TextColor3=color
   card.mark.Text=done and checkmark or day.status=="Available" and "+" or "-"
   card.mark.TextColor3=color; card.stroke.Color=day.status=="Available" and cyan or done and green or Color3.fromRGB(85,88,139)
   card.stroke.Thickness=day.status=="Available" and 2 or 1
   card.frame.BackgroundColor3=day.today and Color3.fromRGB(40,65,93) or Color3.fromRGB(43,45,82)
  end
  weeklyTitle.Text=state.weeklyCompletedToday and "WEEKLY BONUS CLAIMED "..checkmark or "7-DAY BONUS / +"..state.weeklyPreview.." XP"
  weeklyTitle.TextColor3=state.weeklyCompletedToday and green or gold
  local busy=pending or state.pending or automaticRequest~=nil
  local available=state.canCheckIn and not busy
  claim.Text=state.checkedIn and "CLAIMED "..checkmark or busy and "SAVING..." or not state.canCheckIn and "NEXT RESET" or "CHECK IN"
  claim.Active=available; claim.AutoButtonColor=available
  claim.BackgroundColor3=available and cyan or Color3.fromRGB(60,61,96)
  claim.TextColor3=available and dark or state.checkedIn and green or muted
  message.Text=noticeText or ""; message.Visible=message.Text~=""
  updateReset()
 end
 connect(close.Activated,function() setOpen(false) end)
 connect(claim.Activated,function()
  if not state or not state.ready or not state.canCheckIn or state.pending or pending or automaticRequest then return end
  pending=true; noticeText=nil; requestSentAt=os.clock(); pendingId=send("Claim"); render()
 end)
 connect(retry.Activated,function()
  if not retry.Active then return end
  pending=true; requestSentAt=os.clock(); pendingId=send("Retry")
  receivedAt=os.clock(); if state then state=table.clone(state); state.status="Loading"; state.ready=false; state.pendingSince=nil end
  render()
 end)
 connect(UIS.InputBegan,function(input)
  if overlay.Visible and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then setOpen(false) end
 end)
 connect(player:GetAttributeChangedSignal("SessionMode"),function()
  if player:GetAttribute("SessionMode")~="Lobby" or inGameplay() then setOpen(false) end
  updateVisibility()
 end)
 connect(player:GetAttributeChangedSignal("CourtSide"),function()
  if inGameplay() then setOpen(false) end
  updateVisibility()
 end)
 connect(remote.OnClientEvent,function(packet)
  if type(packet.revision)~="number" or packet.revision<=revision then return end
  revision=packet.revision
  if state and state.nextReset~=packet.state.nextReset then noticeText=nil end
  state=packet.state; receivedAt=os.clock()
  if (packet.ackId or 0)>=pendingId then pending=false end
  if automaticRequest and (packet.ackId or 0)>=automaticRequest then automaticRequest=nil end
  if packet.notice then
   local notice=packet.notice
   noticeText=(notice.amount or 0)==0 and notice.message or nil
   if (notice.amount or 0)>0 then
    local weeklyReward=(notice.weekly or 0)>0
    toastTitle.Text=weeklyReward and "7-DAY STREAK COMPLETE!" or notice.levelUp and "LEVEL UP  /  "..notice.level or "+"..notice.amount.." XP"
    toastTitle.TextColor3=weeklyReward and gold or cyan
    toastDetail.Text=(notice.levelUp and "Welcome to level "..notice.level..". " or "").."+"..notice.amount.." XP"..(weeklyReward and " / includes +"..notice.weekly.." bonus XP" or "")
    toast.Visible=true; toastUntil=os.clock()+4; toastScale.Scale=0.93
    tween("toast",toastScale,{Scale=1},0.3)
    if overlay.Visible then
     tween("streak",streak,{TextColor3=weeklyReward and green or gold},0.25)
    end
   end
  end
  if packet.open and packet.openId and packet.openId>closedOpenId and player:GetAttribute("SessionMode")=="Lobby" then
   lastOpenId=packet.openId; noticeText=nil; setOpen(true)
  end
  syncDeviceTime(); render()
 end)
 connect(RunService.RenderStepped,function()
  resize()
  if automaticRequest and os.clock()-automaticSentAt>10 then automaticRequest=nil; render() end
  if os.clock()>=nextOffsetCheck then nextOffsetCheck=os.clock()+60; syncDeviceTime(); render() end
  updateReset()
  if toast.Visible and os.clock()>toastUntil then toast.Visible=false end
  if not state or not state.ready then render(); return end
  local estimatedNow=(state.serverNow or 0)+(os.clock()-receivedAt)
  if state.pending or pending then
   if (state.pendingSince and estimatedNow-state.pendingSince>15 or pending and os.clock()-requestSentAt>15) and not loading.Visible then render() end
   return
  end
  if (state.nextReset and estimatedNow>=state.nextReset)
   and os.clock()-lastRefresh>2 then
   lastRefresh=os.clock(); send("Sync")
  end
 end)
 connect(gui.Destroying,function()
  CAS:UnbindAction("CheckInControls"); player:SetAttribute("CheckInOpen",false)
  for _,connection in ipairs(connections) do connection:Disconnect() end
  for _,animation in pairs(tweens) do animation:Cancel() end
 end)
 send("Sync")
 resize(); render(); updateVisibility()
end
return UI
