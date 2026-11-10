return function(Repository,Rules,Config)
 local now=20000*86400+3600
 local record=nil
 local writes=0
 local unknown=true
 local store={UpdateAsync=function(_,_,callback)
  -- Mimic a transform retry: the abandoned candidate must have no external effects.
  callback(record)
  record=callback(record); writes+=1
  if unknown then unknown=false; error("response lost after commit") end
  return record
 end}
 local repository=Repository.new(store,function() return now end,function() end)
 local operation={kind="CheckIn",id="atomic-claim",at=now}
 local saved,receipt=repository:commit(42,operation)
 assert(saved and writes==2 and saved.totalXP==Config.DailyXP and receipt.amount==Config.DailyXP,"Unknown commit outcome retries the same ID exactly once")
 local otherServer=Repository.new(store,function() return now end,function() end)
 local switched=otherServer:commit(42,{kind="CheckIn",id="new-server",at=now})
 assert(switched.totalXP==saved.totalXP,"Switching servers cannot duplicate today's reward")
 now+=30
 local event={kind="Gameplay",reward="MatchWon",id="completed-match",at=now}
 local earned=repository:commit(42,event)
 local replay=otherServer:commit(42,event)
 assert(replay.totalXP==earned.totalXP,"Gameplay operation IDs are idempotent across repositories")
 local rejoined=otherServer:commit(42,{kind="Load",id="rejoin",at=now})
 assert(rejoined.level==earned.level and rejoined.xp==earned.xp and rejoined.lastDay==earned.lastDay,"Rejoin reads committed XP and check-in state")
 local original=record
 local unavailable=Repository.new({UpdateAsync=function() error("throttled") end},function() return now end,function() end)
 assert(unavailable:commit(42,{kind="Load",id="unavailable",at=now})==nil and record==original,"Load failure never creates or saves replacement defaults")
 local bad={version=999,important="keep me"}
 local malformed=Repository.new({UpdateAsync=function(_,_,callback) bad=callback(bad); return bad end},function() return now end,function() end)
 assert(malformed:commit(42,{kind="Load",id="bad",at=now})==nil and bad.important=="keep me","Unsupported saved data is preserved")
 local old=record
 assert(repository:commit(42,event,now)==nil and record==old,"Shutdown deadline stops fresh writes")
 return "Atomic retries, unknown outcomes, cross-server deduplication, rejoin, throttling, corrupt-data preservation, and shutdown deadline passed"
end
