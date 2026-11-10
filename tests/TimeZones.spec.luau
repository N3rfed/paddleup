return function(Zones,Rules,Config,Repository)
 local function utc(y,m,d,h,min) return DateTime.fromUniversalTime(y,m,d,h or 0,min or 0,0).UnixTimestamp end
 local function selectZone(zone,at)
  return Rules.apply(nil,{kind="SetTimeZone",id="zone-"..zone,zone=zone,at=at},at)
 end
 local function claim(data,at,id) return Rules.apply(data,{kind="CheckIn",id=id,at=at},at) end
 assert(#Zones.options()>400 and Zones.version=="2026e")
 local at=utc(2026,10,23)
 local ny=selectZone("America/New_York",at)
 local tokyo=selectZone("Asia/Tokyo",at)
 assert(Rules.snapshot(ny,at).todayDate=="2026-10-22" and Rules.snapshot(tokyo,at).todayDate=="2026-10-23","The same server instant has different selected-zone civil dates")
 local home=claim(ny,at,"ny-thursday")
 assert(home.multiplierUntil==utc(2026,10,23,4))
 local again=claim(home,at+120,"ny-repeat")
 assert(again.totalXP==home.totalXP and again.streak==1)
 local early=Rules.apply(home,{kind="CheckIn",id="future-local-day",at=utc(2026,10,23,4)},utc(2026,10,23,4)-1)
 assert(early.totalXP==home.totalXP,"Future local dates cannot be claimed inside clock tolerance")
 local friday=claim(home,utc(2026,10,23,4),"ny-friday")
 assert(friday.streak==2 and friday.lastDay==Rules.day(utc(2026,10,23,4),"America/New_York"))
 local _,noBoost=Rules.apply(home,{kind="Gameplay",id="expired-ny",reward="MatchCompleted",at=home.multiplierUntil},home.multiplierUntil)
 assert(noBoost.amount==Config.Rewards.MatchCompleted)
 local function length(zone,y,m,d,expected)
  local day=math.floor(utc(y,m,d)/86400)
  assert(Zones.dayStart(day+1,zone)-Zones.dayStart(day,zone)==expected,zone.." DST day length")
 end
 length("America/New_York",2026,3,8,23*3600)
 length("America/New_York",2026,11,1,25*3600)
 length("Europe/London",2026,3,29,23*3600)
 length("Europe/London",2026,10,25,25*3600)
 length("Australia/Sydney",2026,10,4,23*3600)
 length("Australia/Sydney",2026,4,5,25*3600)
 length("Australia/Lord_Howe",2026,10,4,23.5*3600)
 length("Australia/Lord_Howe",2026,4,5,24.5*3600)
 assert(Zones.offset(utc(2026,3,8,7)-1,"America/New_York")==-18000 and Zones.offset(utc(2026,3,8,7),"America/New_York")==-14400)
 assert(Zones.offset(at,"Asia/Kathmandu")==20700 and Zones.offset(utc(2026,1,1),"Pacific/Chatham")==49500)
 local fall=selectZone("America/New_York",utc(2026,11,1,5,30))
 local once=claim(fall,utc(2026,11,1,5,30),"first-130")
 local twice=claim(once,utc(2026,11,1,6,30),"second-130")
 assert(twice.totalXP==once.totalXP and once.multiplierUntil==utc(2026,11,2,5),"Repeated DST hours do not pay twice")
 for _,zone in ipairs(Zones.options()) do
  local calendar=Zones.calendar(at,zone)
  assert(calendar.nextReset>at and Zones.day(calendar.nextReset-0.001,zone)==calendar.day
   and Zones.day(calendar.nextReset,zone)==calendar.day+1,"Local midnight is consistent for "..zone)
 end
 -- Existing production-format v1 record: retain original XP, UTC history, streak, and expiry.
 local legacy={version=1,level=3,xp=40,totalXP=300,lastDay=20749,streak=2,multiplierUntil=1792800000,
  weeklyAwards=0,lastWeeklyDay=-1,history={["20748"]={at=1792713140.601,multiplier=1.10},["20749"]={at=1792713671.279,multiplier=1.05}},budgets={},receipts={}}
 local migrated=Rules.apply(legacy,{kind="Load"},at+120)
 assert(legacy.version==1 and migrated.version==2 and migrated.timeZone=="UTC")
 assert(migrated.level==3 and migrated.xp==40 and migrated.totalXP==300 and migrated.streak==2 and migrated.multiplierUntil==legacy.multiplierUntil)
 assert(migrated.history["20748"].at==legacy.history["20748"].at and migrated.claims["legacy:20749"],"Migration preserves audit dates and adds timestamp-based claims")
 local zoneAt=utc(2026,10,23,1)
 local changed=Rules.apply(migrated,{kind="SetTimeZone",id="switch-ny",zone="America/New_York",at=zoneAt},zoneAt)
 local before=Rules.snapshot(changed,zoneAt)
 assert(before.timeZone=="UTC" and before.pendingTimeZone=="America/New_York" and changed.multiplierUntil==legacy.multiplierUntil)
 assert(changed.zoneEffectiveAt==utc(2026,10,24) and not Rules.canClaim(changed,zoneAt),"Zone changes do not unlock an immediate reward or extend a boost")
 local denied,result=Rules.apply(changed,{kind="SetTimeZone",id="zone-hop",zone="Asia/Tokyo",at=zoneAt+5},zoneAt+5)
 assert(result.kind=="ZoneCooldown" and denied.pendingTimeZone=="America/New_York" and denied.totalXP==changed.totalXP)
 local record=changed
 local clock=changed.zoneEffectiveAt
 local store={UpdateAsync=function(_,_,transform) record=transform(record); return record end}
 local repo=Repository.new(store,function() return clock end,function() end)
 local loaded=repo:commit(42,{kind="Load",id="rejoin-zone",at=clock})
 assert(loaded.timeZone=="America/New_York" and loaded.pendingTimeZone==nil and loaded.totalXP==300,"Rejoin activates the persisted deferred setting without an XP change")
 local effective=Rules.snapshot(loaded,clock)
 assert(effective.todayDate=="2026-10-23" and effective.canCheckIn and effective.streak==2)
 local awarded=repo:commit(42,{kind="CheckIn",id="local-after-change",at=clock})
 assert(awarded.streak==3 and awarded.totalXP==300+Config.DailyXP)
 local second=Repository.new(store,function() return clock end,function() end):commit(42,{kind="CheckIn",id="cross-server-repeat",at=clock})
 assert(second.totalXP==awarded.totalXP,"Atomic state prevents duplicate local claims across instances")
 local invalid=pcall(Rules.apply,awarded,{kind="SetTimeZone",id="fake-zone",zone="client/pretend",at=clock},clock)
 assert(not invalid and awarded.totalXP==second.totalXP)
 -- Eastward moves cannot claim again on the local date that already contains the prior claim.
 local west=selectZone("America/Los_Angeles",at-8*86400)
 local westClaim=claim(west,at,"west-claim")
 local east=Rules.apply(westClaim,{kind="SetTimeZone",id="move-east",zone="Asia/Tokyo",at=at+60},at+60)
 assert(east.zoneEffectiveAt==utc(2026,10,23,7))
 local earlyEast=Rules.snapshot(east,east.zoneEffectiveAt)
 assert(earlyEast.timeZone=="Asia/Tokyo" and not earlyEast.canCheckIn and earlyEast.eligibleAt==utc(2026,10,23,15),"A forward zone change must also wait for a new local claim date")
 local noExtra=claim(east,east.zoneEffectiveAt,"east-too-soon")
 assert(noExtra.totalXP==westClaim.totalXP and noExtra.multiplierUntil==westClaim.multiplierUntil)
 local nextEast=claim(noExtra,earlyEast.eligibleAt,"east-next-day")
 assert(nextEast.streak==2 and nextEast.totalXP==westClaim.totalXP+Config.DailyXP)
 -- Seven consecutive selected-zone dates, including the 23-hour spring-forward day.
 local run=selectZone("America/New_York",utc(2026,3,4))
 local last
 for offset=0,6 do
  local day=math.floor(utc(2026,3,4)/86400)+offset
  local when=Zones.dayStart(day,"America/New_York")+3600
  run,last=claim(run,when,"spring-run-"..offset)
 end
 assert(run.streak==7 and run.weeklyAwards==1 and last.weekly>0)
 local replay=claim(run,run.lastClaimAt+60,"weekly-replay")
 assert(replay.weeklyAwards==1 and replay.totalXP==run.totalXP)
 local missed=claim(run,Zones.dayStart(Rules.day(run.lastClaimAt,"America/New_York")+3,"America/New_York")+3600,"missed-local-days")
 assert(missed.streak==1 and missed.weeklyAwards==1)
 return "419 zones, selected local dates, DST 23/25/half-hour days, repeated hours, midnight expiry, v1 migration, deferred changes/cooldown, rejoin, cross-server duplicates, and weekly streaks passed"
end
