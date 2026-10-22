-- Render the real interface into a detached Folder using server-generated snapshots.
return function(source,Rules)
 local function signal()
  local callbacks={}
  local event={}
  function event:Connect(fn)
   local c={Connected=true}; function c:Disconnect() self.Connected=false end
   table.insert(callbacks,{fn=fn,c=c}); return c
  end
  function event:Fire(...)
   for _,item in ipairs(callbacks) do if item.c.Connected then item.fn(...) end end
  end
  return event
 end
 local folder=Instance.new("Folder")
 local attributes={SessionMode="Lobby"}
 local changed={}
 local player={}
 function player:WaitForChild() return folder end
 function player:SetAttribute(key,value)
  attributes[key]=value; if changed[key] then changed[key]:Fire() end
 end
 function player:GetAttribute(key) return attributes[key] end
 function player:GetAttributeChangedSignal(key) changed[key]=changed[key] or signal(); return changed[key] end
 local requests={}
 local remote={OnClientEvent=signal(),FireServer=function(_,action,id,openId) table.insert(requests,{action=action,id=id,openId=openId}) end}
 local input={InputBegan=signal()}
 local render=signal()
 local actions={BindActionAtPriority=function() end,UnbindAction=function() end}
 local services={TweenService=game:GetService("TweenService"),UserInputService=input,ContextActionService=actions,RunService={RenderStepped=render}}
 local captures={}
 local instrumented,count=source:gsub("connect%(claim.Activated,",
  "connect({Connect=function(_,fn) captures.claim=fn; return claim.Activated:Connect(fn) end},")
 assert(count==1)
 instrumented,count=instrumented:gsub("connect%(retry.Activated,",
  "connect({Connect=function(_,fn) captures.retry=fn; return retry.Activated:Connect(fn) end},")
 assert(count==1)
 local clock=100
 local viewport={ViewportSize=Vector2.new(1280,800)}
 local chunk=assert(loadstring(instrumented))
 setfenv(chunk,setmetatable({captures=captures,os={clock=function() return clock end},game={GetService=function(_,name) return assert(services[name],name) end},
  workspace={CurrentCamera=viewport}},{__index=getfenv()}))
 local UI=chunk()
 local ok,err=pcall(function()
  UI.start(player,{WaitForChild=function() return remote end})
  UI.start(player,{WaitForChild=function() return remote end})
  assert(#folder:GetChildren()==1,"UI startup is idempotent")
  local gui=folder.PaddleUpProgression
  local today=20000*86400+3600
  local panel=gui.DailyCheckInOverlay.WeeklyCheckIn
  local claim=panel.TodayReward.ClaimReward
  local retry=panel.DataStatus.RetryLoad
  local serial=0
  local function publish(state,extra)
   serial+=1
   local packet={state=state,revision=serial,ackId=requests[#requests].id,openId=1}
   for key,value in pairs(extra or {}) do packet[key]=value end
   remote.OnClientEvent:Fire(packet)
   return packet
  end
  assert(panel.DataStatus.Visible and not panel.Calendar.Visible and not claim.Active,"Initial loading contains no fake calendar or enabled claim")
  for index=1,7 do assert(panel.Calendar["Day"..index].Date.Text=="") end
  clock+=16; render:Fire()
  assert(retry.Visible and retry.Active,"A missing response exposes Retry rather than an indefinite wait")
  publish({ready=false,status="Error",error="Studio API access is disabled.",retryAfter=0},{open=true})
  assert(gui.DailyCheckInOverlay.Visible and not gui.XPProfile.Visible)
  assert(panel.DataStatus.StatusMessage.Text=="Studio API access is disabled." and panel.Calendar.Visible==false)
  captures.retry()
  assert(requests[#requests].action=="Retry" and not retry.Visible and not claim.Active,"Retry shows one loading indicator and keeps claims disabled")
  local pendingSerial=serial
  remote.OnClientEvent:Fire({revision=0,state={ready=false,status="Error",error="stale"},open=true,openId=1})
  assert(panel.DataStatus.StatusMessage.Text=="Loading check-in data...","Stale errors cannot replace a newer loading state")
  local state=Rules.snapshot(Rules.new(),today)
  publish(state)
  assert(not panel.DataStatus.Visible and panel.Calendar.Visible and claim.Active)
  assert(panel.TodayReward.DailyBonus.Text=="+10% BONUS XP" and claim.Text=="CHECK IN & ACTIVATE")
  for index,day in ipairs(state.days) do
   assert(panel.Calendar["Day"..index].Date.Text==day.shortDate and panel.Calendar["Day"..index].Weekday.Text==day.label:upper(),"Calendar dates come only from the server")
  end
  local count=#requests
  captures.claim(); captures.claim()
  assert(#requests==count+1 and requests[#requests].action=="Claim" and not claim.Active,"A double click creates one claim request")
  local saving=table.clone(state); saving.pending=true; saving.status="Saving"; saving.pendingSince=today-16
  publish(saving)
  assert(retry.Visible and not claim.Active,"A slow write exposes recovery without allowing another claim")
  local saved=Rules.apply(nil,{kind="CheckIn",id="ui-claim",at=today},today)
  local success=publish(Rules.snapshot(saved,today),{notice={amount=150,levelUp=true,level=saved.level}})
  assert(claim.Text=="CHECKED IN "..utf8.char(10003) and not claim.Active and panel.WeeklyStreak.Text=="WEEKLY STREAK: 1/7 DAYS")
  assert(gui.XPNotification.Visible)
  remote.OnClientEvent:Fire({revision=pendingSerial,state=state})
  assert(not claim.Active and claim.Text=="CHECKED IN "..utf8.char(10003),"Late unclaimed data cannot overwrite confirmation")
  task.wait(0.4)
  assert(gui.XPProfile.XPTrack.XPProgress.Size.X.Offset>0)
  input.InputBegan:Fire({KeyCode=Enum.KeyCode.Escape})
  assert(not gui.DailyCheckInOverlay.Visible and requests[#requests].action=="Close")
  publish(Rules.snapshot(saved,today),{open=true,openId=1})
  assert(not gui.DailyCheckInOverlay.Visible,"A late opening response cannot reopen a dismissed interaction")
  publish(Rules.snapshot(saved,today),{open=true,openId=2})
  assert(gui.DailyCheckInOverlay.Visible,"A new confirmed desk interaction can open again")
  viewport.ViewportSize=Vector2.new(390,844); render:Fire()
  assert(panel.Size.X.Offset==366 and panel.Calendar.Size.X.Offset<panel.Calendar.CanvasSize.X.Offset,"Phone layout preserves readable calendar cards with horizontal scrolling")
  local week=Rules.new()
  for day=20000-6,20000 do week=Rules.apply(week,{kind="CheckIn",id="week-"..day,at=day*86400+3600},day*86400+3600) end
  publish(Rules.snapshot(week,today),{notice={amount=200,weekly=50,level=week.level}})
  assert(panel.WeeklyStreak.Text=="WEEKLY STREAK: 7/7 DAYS")
  for index=1,7 do assert(panel.StreakProgress["Segment"..index].BackgroundColor3==Color3.fromRGB(255,214,138)) end
  assert(panel.WeeklyReward:GetChildren()[2]~=nil and gui.XPNotification.Visible)
  assert(panel.WeeklyReward:FindFirstChildWhichIsA("TextLabel").Text:find("CONFIRMED",1,true))
 end)
 folder:Destroy()
 assert(ok,err)
 return "Single loading/error state, Retry, real dates, +10% action, duplicate/stale/closed-response guards, claim confirmation, phone layout, and seven streak segments passed"
end
