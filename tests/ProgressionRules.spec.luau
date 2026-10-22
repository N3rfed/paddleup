return function(Rules,Config)
 local function claim(data,day,id)
  return Rules.apply(data,{kind="CheckIn",id=id or "day-"..day,at=day*86400+3600},day*86400+3600)
 end
 local fresh=Rules.new()
 assert(fresh.level==1 and fresh.xp==0 and Rules.required(2)>Rules.required(1))
 local day=20000
 local before,game=Rules.apply(fresh,{kind="Gameplay",reward="MatchCompleted",id="before",at=day*86400+100},day*86400+100)
 assert(game.amount==Config.Rewards.MatchCompleted,"No multiplier before check-in")
 local checked,daily=claim(before,day)
 assert(daily.amount==Config.DailyXP and checked.level>fresh.level,"Daily reward is not multiplied and levels update immediately")
 assert(fresh.xp==0 and before.lastDay==-1,"Transitions never mutate saved input")
 local again,duplicate=claim(checked,day,"same-date-different-server")
 assert(duplicate.kind=="Already" and again.totalXP==checked.totalXP,"One claim per UTC date across sessions")
 local replay,replayed=claim(checked,day)
 assert(replay.totalXP==checked.totalXP and replayed.amount==daily.amount,"Same operation returns its persisted receipt")
 local pendingCheck=Rules.apply(before,{kind="CheckIn",id="slow-check",at=day*86400+200},day*86400+300)
 local earnedBeforeCommit,early=Rules.apply(pendingCheck,{kind="Gameplay",reward="MatchCompleted",id="before-commit",at=day*86400+250},day*86400+301)
 assert(early.amount==Config.Rewards.MatchCompleted,"Gameplay earned while a claim is still pending is not boosted")
 local boosted,boost=Rules.apply(checked,{kind="Gameplay",reward="MatchCompleted",id="boost",at=day*86400+7200},day*86400+7200)
 assert(boost.amount==Config.Rewards.MatchCompleted*Config.DailyMultiplier,"Eligible gameplay receives the daily multiplier")
 local oldRecord=table.clone(checked); oldRecord.history=table.clone(checked.history)
 oldRecord.history[tostring(day)]={at=day*86400+3600,multiplier=2}
 local tuned,tunedReceipt=Rules.apply(oldRecord,{kind="Gameplay",reward="MatchCompleted",id="legacy-boost",at=day*86400+7200},day*86400+7200)
 assert(tunedReceipt.amount==math.floor(Config.Rewards.MatchCompleted*1.10),"Existing claims follow the configured +10% tuning without resetting saved progress")
 local expired,plain=Rules.apply(boosted,{kind="Gameplay",reward="MatchCompleted",id="tomorrow",at=(day+1)*86400+1},(day+1)*86400+1)
 assert(plain.amount==Config.Rewards.MatchCompleted,"Multiplier expires at UTC midnight")
 local midnight=Rules.snapshot(checked,(day+1)*86400)
 assert(midnight.multiplier==1 and not midnight.checkedIn and midnight.streak==1)
 local broken=claim(expired,day+2)
 assert(broken.streak==1 and Rules.snapshot(checked,(day+2)*86400).streak==0,"A missed day breaks the streak")
 local run=Rules.new()
 for offset=0,5 do run=claim(run,day+offset) end
 local expected=table.clone(run)
 -- Evaluate the level after the daily grant, immediately before the seventh-day bonus.
 expected.xp+=Config.DailyXP
 while expected.xp>=Rules.required(expected.level) do expected.xp-=Rules.required(expected.level); expected.level+=1 end
 local weeklyAmount=math.floor(Rules.required(expected.level)*0.20)
 local seventh,weekly=claim(run,day+6)
 assert(seventh.streak==7 and seventh.weeklyAwards==1 and weekly.weekly==weeklyAmount,"Seven days across calendar-week boundaries grant exactly 20% of the current level requirement")
 assert(weekly.amount==Config.DailyXP+weeklyAmount,"Weekly bonus is not multiplied")
 local repeated=claim(seventh,day+6,"reconnect")
 assert(repeated.totalXP==seventh.totalXP and repeated.weeklyAwards==1,"Reconnect/open cannot repeat a weekly bonus")
 local fourteen=seventh
 for offset=7,13 do fourteen=claim(fourteen,day+offset) end
 assert(fourteen.streak==14 and fourteen.weeklyAwards==2,"Each complete seven-day block pays once")
 local lost=claim(fourteen,day+15)
 assert(lost.streak==1 and lost.weeklyAwards==2,"A broken run keeps historical award count")
 local limited=Rules.new()
 for index=1,30 do
  limited=Rules.apply(limited,{kind="Gameplay",reward="MatchWon",id="cap-"..index,at=day*86400+index},day*86400+index)
 end
 assert(limited.totalXP==Config.GameplayDailyCap,"Final gameplay XP is capped per UTC day")
 local delayed=Rules.apply(nil,{kind="CheckIn",id="late",at=day*86400+86399},(day+1)*86400)
 assert(delayed.totalXP==0 and delayed.lastDay==-1,"Delayed requests cannot claim yesterday")
 local snapshot=Rules.snapshot(seventh,(day+6)*86400+3600)
 assert(#snapshot.days==7 and snapshot.checkedIn and snapshot.nextReset==(day+7)*86400)
 local todayDone=false
 for _,item in ipairs(snapshot.days) do if item.today then todayDone=item.status=="TodayDone" end end
 assert(todayDone,"Calendar distinguishes today's completed claim")
 local states={}
 for _,item in ipairs(Rules.snapshot(Rules.new(),day*86400).days) do states[item.status]=true end
 assert(states.Available and states.Missed and states.Upcoming,"Calendar includes available, missed, and upcoming days")
 local corrupt=Rules.new(); corrupt.level="invalid"
 assert(not pcall(Rules.apply,corrupt,{kind="Load"},day*86400),"Invalid records never become defaults")
 return "XP, levels, UTC resets, multiplier, daily/weekly deduplication, missed days, 7/14-day streaks, calendar, and caps passed"
end
