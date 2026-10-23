-- Fixed UTC boundary tests. No local clock, live DataStore, or saved-data migration.
return function(Rules,Config,Repository,serviceSource)
 local friday=DateTime.fromUniversalTime(2026,10,23,0,0,0).UnixTimestamp
 local thursday=friday-1
 local function card(snapshot,date)
  for _,item in ipairs(snapshot.days) do if item.date==date then return item end end
  error("Missing calendar date "..date)
 end
 local fresh=Rules.new()
 local thu=Rules.snapshot(fresh,thursday)
 assert(thu.todayDate=="2026-10-22" and thu.todayLabel=="Thu, Oct 22" and thu.nextReset==friday)
 assert(card(thu,"2026-10-22").today and card(thu,"2026-10-22").status=="Available")
 assert(card(thu,"2026-10-23").label=="Fri" and card(thu,"2026-10-23").status=="Upcoming","Friday is unavailable one second before midnight UTC")
 local early,denied=Rules.apply(fresh,{kind="CheckIn",id="future-friday",at=friday},thursday)
 assert(early.lastDay==-1 and early.totalXP==0 and denied.amount==0,"A future timestamp inside the existing clock tolerance still cannot claim the next UTC date")
 local ok=pcall(Rules.apply,fresh,{kind="CheckIn",id="far-future",at=friday+86400},thursday)
 assert(not ok and fresh.totalXP==0,"Far future operations cannot award XP")
 local checked=Rules.apply(fresh,{kind="CheckIn",id="thursday",at=thursday},thursday)
 assert(checked.lastDay==Rules.day(thursday) and checked.multiplierUntil==friday)
 local repeated=Rules.apply(checked,{kind="CheckIn",id="thursday-repeat",at=thursday+0.5},thursday+0.5)
 assert(repeated.totalXP==checked.totalXP and repeated.streak==1)
 local _,boost=Rules.apply(checked,{kind="Gameplay",reward="MatchCompleted",id="before-reset",at=friday-0.25},friday-0.25)
 local _,plain=Rules.apply(checked,{kind="Gameplay",reward="MatchCompleted",id="after-reset",at=friday},friday)
 assert(boost.amount==math.floor(Config.Rewards.MatchCompleted*Config.DailyMultiplier) and plain.amount==Config.Rewards.MatchCompleted,"The multiplier expires on the same UTC midnight as the calendar")
 local fri=Rules.snapshot(checked,friday)
 assert(fri.todayDate=="2026-10-23" and fri.todayLabel=="Fri, Oct 23" and not fri.checkedIn and fri.multiplier==1 and fri.streak==1)
 assert(card(fri,"2026-10-22").status=="Done" and card(fri,"2026-10-23").status=="Available")
 assert(card(fri,"2026-10-24").status=="Upcoming" and fri.nextReset==friday+86400)
 local record=checked
 local store={UpdateAsync=function(_,_,callback) record=callback(record); return record end}
 local clock=friday
 local repository=Repository.new(store,function() return clock end,function() end)
 local rejoined=repository:commit(42,{kind="Load",id="rejoin-before-friday-claim",at=clock})
 assert(rejoined.lastDay==checked.lastDay and rejoined.totalXP==checked.totalXP,"Rejoin reads Thursday without promoting it to Friday")
 local fridayClaim=repository:commit(42,{kind="CheckIn",id="friday",at=clock})
 assert(fridayClaim.streak==2 and fridayClaim.lastDay==Rules.day(friday) and fridayClaim.multiplierUntil==friday+86400)
 local otherServer=Repository.new(store,function() return clock end,function() end)
 local duplicate=otherServer:commit(42,{kind="CheckIn",id="other-server-friday",at=clock})
 assert(duplicate.totalXP==fridayClaim.totalXP and duplicate.streak==2,"Repeated/rejoined Friday claims cannot pay twice")
 -- A pre-existing future history entry stays stored but never appears completed before its UTC day.
 local preserved=table.clone(fridayClaim); preserved.history=table.clone(fridayClaim.history)
 preserved.history[tostring(Rules.day(friday)+1)]={at=friday+86400,multiplier=Config.DailyMultiplier}
 local guarded=Rules.snapshot(preserved,friday)
 assert(card(guarded,"2026-10-24").status=="Upcoming" and preserved.history[tostring(Rules.day(friday)+1)],"Future cards remain unavailable without rewriting stored history")
 local run=Rules.new()
 for offset=6,1,-1 do
  local at=friday-offset*86400+3600
  run=Rules.apply(run,{kind="CheckIn",id="run-"..offset,at=at},at)
 end
 assert(run.streak==6 and run.weeklyAwards==0)
 local tooEarly=Rules.apply(run,{kind="CheckIn",id="early-seventh",at=friday},thursday)
 assert(tooEarly.streak==6 and tooEarly.weeklyAwards==0 and tooEarly.totalXP==run.totalXP,"The seventh-day bonus cannot be granted on Thursday")
 local level,xp=run.level,run.xp+Config.DailyXP
 while xp>=Rules.required(level) do xp-=Rules.required(level); level+=1 end
 local seventh,bonus=Rules.apply(run,{kind="CheckIn",id="seventh-friday",at=friday},friday)
 assert(seventh.streak==7 and seventh.weeklyAwards==1 and bonus.weekly==math.floor(Rules.required(level)*Config.WeeklyFraction))
 local again=Rules.apply(seventh,{kind="CheckIn",id="seventh-repeat",at=friday+1},friday+1)
 assert(again.totalXP==seventh.totalXP and again.weeklyAwards==1)
 -- Verify the actual publish function cannot mix Thursday's calendar with Friday's serverNow.
 local first=assert(serviceSource:find("local function publish(entry,notice,open)",1,true))
 local last=assert(serviceSource:find("local startWorker",first,true))
 local players={}
 local player={Parent=players,SetAttribute=function() end}
 local packet,calls=nil,0
 local environment=setmetatable({Rules=Rules,Config=Config,Players=players,
  now=function() calls+=1; return calls==1 and friday-0.001 or friday end,
  remote={FireClient=function(_,_,value) packet=value end}},{__index=getfenv()})
 local chunk=assert(loadstring(serviceSource:sub(first,last-1).."\nreturn publish")); setfenv(chunk,environment)
 chunk()({player=player,data=fresh,queue={},revision=0,ackId=0,openId=0})
 assert(calls==1 and packet.state.serverNow==friday-0.001 and packet.state.todayDate=="2026-10-22","A snapshot has one authoritative timestamp even at midnight")
 return "Thursday/Friday UTC labels, future-day denial, midnight reset, multiplier expiry, rejoin, repeated claims, seventh-day bonus, preserved records, and single-clock snapshots passed"
end
