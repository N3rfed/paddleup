-- Real service with a fake atomic backend and detached lobby/avatar objects. No live stores are used.
return function(source,modules)
 local function signal()
  local listeners={}
  local event={}
  function event:Connect(callback)
   local c={Connected=true}; function c:Disconnect() self.Connected=false end
   table.insert(listeners,{callback=callback,connection=c}); return c
  end
  function event:Fire(...)
   for _,item in ipairs(listeners) do if item.connection.Connected then item.callback(...) end end
  end
  return event
 end
 local time=20000*86400+3600
 local record
 local failure=true
 local writes=0
 local blocked=false
 local backend={UpdateAsync=function(_,_,callback)
  writes+=1
  if failure then error("403: Cannot write to DataStore from studio if API access is not enabled.") end
  while blocked do task.wait() end
  record=callback(record); return record
 end}
 local players={PlayerAdded=signal(),PlayerRemoving=signal()}
 local attributes={SessionMode="Lobby"}
 local character=Instance.new("Model")
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Parent=character; root.Position=Vector3.zero
 local humanoid=Instance.new("Humanoid"); humanoid.Parent=character
 local player={UserId=42,Parent=players,Character=character}
 function player:GetAttribute(key) return attributes[key] end
 function player:SetAttribute(key,value) attributes[key]=value end
 function players:GetPlayers() return {player} end
 local packets={}
 local remote={OnServerEvent=signal(),FireClient=function(_,_,packet) table.insert(packets,packet) end}
 local network={FindFirstChild=function() return remote end}
 local lobby=Instance.new("Model")
 local desk=Instance.new("Part"); desk.Name="Reception stone top"; desk.Size=Vector3.new(33,0.35,7); desk.Parent=lobby
 local close
 local counter=0
 local fakeGame={GetService=function(_,name)
  if name=="Players" then return players end
  if name=="HttpService" then return {GenerateGUID=function() counter+=1; return "service-"..counter end} end
  if name=="DataStoreService" then return {GetDataStore=function() return backend end} end
  error(name)
 end,BindToClose=function(_,callback) close=callback end}
 local captures={}
 local instrumented,count=source:gsub("connect%(prompt.Triggered,",
  "connect({Connect=function(_,fn) captures.prompt=fn; return prompt.Triggered:Connect(fn) end},")
 assert(count==1,"Capture the real desk event handler")
 local chunk=assert(loadstring(instrumented))
 setfenv(chunk,setmetatable({captures=captures,warn=function() end,game=fakeGame,DateTime={now=function() return {UnixTimestampMillis=time*1000} end},
  script={Parent={WaitForChild=function(_,name) return name end}},require=function(name) return assert(modules[name],name) end},{__index=getfenv()}))
 local serviceModule=chunk()
 local api=serviceModule.start(network,lobby)
 local ok,err=pcall(function()
  task.wait()
  assert(api==serviceModule.start(network,lobby),"Duplicate starts reuse the existing service")
  local prompt=desk.DailyCheckInPoint.DailyCheckIn
  assert(prompt.KeyboardKeyCode==Enum.KeyCode.E and prompt.ActionText=="Daily Check-In")
  assert(not attributes.XPDataReady and record==nil and writes==1,"Disabled API access fails explicitly without replacement defaults or repeated permanent retries")
  assert(packets[#packets].state.status=="Error" and packets[#packets].state.errorCode=="StudioAPI" and packets[#packets].state.canRetry)
  local pendingId=api.entries[player].queue[1].id
  captures.prompt(player)
  local opened=packets[#packets].openId
  assert(packets[#packets].open and opened==1)
  local openCount=0
  for _,packet in ipairs(packets) do if packet.open then openCount+=1 end end
  time+=2; captures.prompt(player)
  local newCount=0; for _,packet in ipairs(packets) do if packet.open then newCount+=1 end end
  assert(newCount==openCount,"Repeated prompts do not reopen the panel")
  remote.OnServerEvent:Fire(player,"Retry",1,opened); task.wait()
  assert(writes==2 and api.entries[player].queue[1].id==pendingId,"Retry preserves the original transaction ID")
  remote.OnServerEvent:Fire(player,"Retry",2,opened); task.wait()
  assert(writes==2,"Retry is rate-limited")
  failure=false; time+=modules.ProgressionConfig.ManualRetrySeconds+1
  remote.OnServerEvent:Fire(player,"Retry",3,opened); task.wait()
  assert(attributes.XPDataReady and attributes.Level==1 and #api.entries[player].queue==0,"Retry recovers after API access returns")
  assert(packets[#packets].state.status=="Ready")
  time+=2; root.Position=Vector3.new(1000,0,0)
  remote.OnServerEvent:Fire(player,"Claim",4,opened); task.wait()
  assert(record.totalXP==0,"Distance validation is preserved")
  time+=2; root.Position=Vector3.zero; blocked=true
  remote.OnServerEvent:Fire(player,"Claim",5,opened)
  local queuedId=api.entries[player].queue[1].id
  time+=2; remote.OnServerEvent:Fire(player,"Claim",6,opened)
  assert(#api.entries[player].queue==1 and api.entries[player].queue[1].id==queuedId,"In-flight duplicate claims do not queue a second reward")
  blocked=false; task.wait(); task.wait()
  assert(record.totalXP==modules.ProgressionConfig.DailyXP and attributes.Level==record.level,"First-time claim confirms XP and activates the bonus")
  time+=2; remote.OnServerEvent:Fire(player,"Claim",7,opened); task.wait()
  assert(record.totalXP==modules.ProgressionConfig.DailyXP,"Repeated confirmed claims are harmless")
  time+=2
  assert(api:award(player,"MatchWon","verified-match")); task.wait()
  assert(record.totalXP==modules.ProgressionConfig.DailyXP+math.floor(modules.ProgressionConfig.Rewards.MatchWon*modules.ProgressionConfig.DailyMultiplier))
  -- Exercise a failed write with existing cached data: Sync is not allowed to fake recovery.
  local confirmed=record.totalXP
  failure=true; assert(api:award(player,"MatchWon","retry-cached")); task.wait()
  assert(not attributes.XPDataReady and record.totalXP==confirmed,"Cached data does not authorize claims after a failed transaction")
  local cachedId=api.entries[player].queue[1].id
  failure=false; time+=4; remote.OnServerEvent:Fire(player,"Retry",8,opened); task.wait()
  assert(attributes.XPDataReady and #api.entries[player].queue==0 and record.receipts[cachedId],"Retry resumes a failed transaction even when cached data exists")
  local savedXP=record.totalXP
  player.Parent=nil; players.PlayerRemoving:Fire(player); task.wait()
  player.Parent=players; players.PlayerAdded:Fire(player); task.wait()
  assert(api.entries[player].data.totalXP==savedXP and api.entries[player].data.lastDay==modules.ProgressionRules.day(time),"Rejoin loads committed progress without another check-in")
  -- Seed six prior UTC days in the fake store, then exercise the real seventh-day service claim.
  local today=modules.ProgressionRules.day(time)
  record=modules.ProgressionRules.new()
  for day=today-6,today-1 do record=modules.ProgressionRules.apply(record,{kind="CheckIn",id="seed-"..day,at=day*86400+100},day*86400+100) end
  player.Parent=nil; players.PlayerRemoving:Fire(player); task.wait()
  player.Parent=players; players.PlayerAdded:Fire(player); task.wait()
  captures.prompt(player)
  local expected,weekly=modules.ProgressionRules.apply(record,{kind="CheckIn",id="expected",at=time},time)
  remote.OnServerEvent:Fire(player,"Claim",9,api.entries[player].openId); task.wait()
  assert(record.weeklyAwards==1 and record.totalXP==expected.totalXP and weekly.weekly>0,"Seventh-day claim pays the unchanged weekly formula once")
  assert(packets[#packets].state.weeklyCompletedToday and packets[#packets].state.cycle==7)
  time+=2; remote.OnServerEvent:Fire(player,"Claim",10,api.entries[player].openId); task.wait()
  assert(record.weeklyAwards==1 and record.totalXP==expected.totalXP)
  assert(not api:award(player,"UntrustedReward","fake"))
  local midnight=DateTime.fromUniversalTime(2026,10,23,0,0,0).UnixTimestamp
  time=midnight-1
  captures.prompt(player)
  local utcOpen=api.entries[player].openId
  remote.OnServerEvent:Fire(player,"Claim",11,utcOpen,"2026-10-23"); task.wait()
  assert(record.lastDay==modules.ProgressionRules.day(midnight-1),"A client-supplied future date is ignored; only server Thursday is claimed")
  time=midnight
  remote.OnServerEvent:Fire(player,"Sync",12,utcOpen); task.wait()
  assert(packets[#packets].state.todayDate=="2026-10-23" and not packets[#packets].state.checkedIn and packets[#packets].state.multiplier==1)
  remote.OnServerEvent:Fire(player,"Claim",13,utcOpen); task.wait()
  assert(record.lastDay==modules.ProgressionRules.day(midnight) and record.streak==2)
  for _,packet in ipairs(packets) do
   if packet.state.ready then
    assert(packet.state.todayDate==os.date("!%Y-%m-%d",math.floor(packet.state.serverNow)),"Every calendar and published timestamp agree on UTC today")
   end
  end
  -- The real remote accepts only a zone ID; server clocks and atomic storage decide eligibility.
  time+=2
  local zoneOpen=api.entries[player].openId
  local beforeZoneXP=record.totalXP
  remote.OnServerEvent:Fire(player,"SetTimeZone",14,zoneOpen,"Not/AZone"); task.wait()
  assert(record.timeZone=="UTC" and not record.pendingTimeZone,"Unknown zones cannot enter saved data")
  time+=2
  remote.OnServerEvent:Fire(player,"SetTimeZone",15,zoneOpen-1,"America/New_York"); task.wait()
  assert(not record.pendingTimeZone,"Stale panel interactions cannot change settings")
  time+=2; root.Position=Vector3.new(1000,0,0)
  remote.OnServerEvent:Fire(player,"SetTimeZone",16,zoneOpen,"America/New_York"); task.wait()
  assert(not record.pendingTimeZone,"Zone selection requires the existing desk interaction and proximity")
  time+=2; root.Position=Vector3.zero
  remote.OnServerEvent:Fire(player,"SetTimeZone",17,zoneOpen,"America/New_York"); task.wait()
  assert(record.timeZone=="UTC" and record.pendingTimeZone=="America/New_York" and record.totalXP==beforeZoneXP)
  local effective=record.zoneEffectiveAt
  local expiration=record.multiplierUntil
  time+=2
  remote.OnServerEvent:Fire(player,"SetTimeZone",18,zoneOpen,"Asia/Tokyo"); task.wait()
  assert(record.pendingTimeZone=="America/New_York" and record.multiplierUntil==expiration,"Atomic cooldown preserves the saved change and boost deadline")
  player.Parent=nil; players.PlayerRemoving:Fire(player); task.wait()
  time=effective
  player.Parent=players; players.PlayerAdded:Fire(player); task.wait()
  assert(record.timeZone=="America/New_York" and not record.pendingTimeZone and record.totalXP==beforeZoneXP,"Rejoin persists and activates the setting without rewards")
  assert(packets[#packets].state.timeZone=="America/New_York" and packets[#packets].state.todayDate=="2026-10-23")
  player.Parent=nil; players.PlayerRemoving:Fire(player); task.wait()
  assert(api.entries[player]==nil,"Player departure cleans idle profile resources")
 end)
 close(); character:Destroy(); lobby:Destroy()
 assert(ok,err)
 return "Disabled API failure, safe/rate-limited Retry, cached-write recovery, single opening/claim, +5% gameplay, rejoin, seven-day reward, and shutdown passed"
end
