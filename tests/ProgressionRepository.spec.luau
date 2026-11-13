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
 local malformed=Repository.new({UpdateAsync=function(_,_,callback) local updated=callback(bad); if updated then bad=updated end; return updated end},function() return now end,function() end)
 assert(malformed:commit(42,{kind="Load",id="bad",at=now})==nil and bad.important=="keep me","Unsupported saved data is preserved")
 -- Mimic Roblox swallowing an exception from an UpdateAsync transform.
 local callbacks=0
 local swallowed=Repository.new({UpdateAsync=function(_,_,callback)
  callbacks+=1
  local ok,value=pcall(callback,bad)
  return ok and value or nil
 end},function() return now end,function() error("Permanent validation errors must not retry") end)
 local rejected,_,reason=swallowed:commit(42,{kind="Load",id="swallowed",at=now})
 assert(not rejected and reason:find("Unsupported progression data",1,true) and callbacks==1)
 assert(bad.version==999 and bad.important=="keep me","Cancelled validation never writes replacement defaults")
 local old=record
 assert(repository:commit(42,event,now)==nil and record==old,"Shutdown deadline stops fresh writes")
 -- Production shop profiles share this store but use version 3.
 local shop=Rules.new()
 shop.version=3; shop.spendableXP=23
 shop.inventory={cat_paddle=true}; shop.equipped={Paddle="cat_paddle"}
 shop.shopAudit={marker="retain"}
 local shopStore={UpdateAsync=function(_,_,callback) shop=callback(shop); return shop end}
 local shopRepo=Repository.new(shopStore,function() return now end,function() end)
 local loaded,_,loadError=shopRepo:commit(42,{kind="Load",id="shop-load",at=now})
 assert(loaded,loadError)
 assert(loaded.version==3 and loaded.spendableXP==23 and loaded.inventory.cat_paddle and loaded.equipped.Paddle=="cat_paddle")
 assert(loaded.shopAudit.marker=="retain" and loaded.totalXP==0,"Loading never downgrades or resets shop profiles")
 local zone=shopRepo:commit(42,{kind="SetTimeZone",id="shop-zone",zone="UTC+05:45",at=now})
 assert(zone.version==3 and zone.timeZone=="UTC+05:45" and zone.spendableXP==23)
 local claimed=shopRepo:commit(42,{kind="CheckIn",id="shop-claim",at=now})
 assert(claimed.totalXP==Config.DailyXP and claimed.spendableXP==23+Config.DailyXP)
 local duplicate=shopRepo:commit(42,{kind="CheckIn",id="shop-claim-rejoin",at=now})
 assert(duplicate.spendableXP==claimed.spendableXP and duplicate.inventory.cat_paddle)
 local snapshot=Rules.snapshot(duplicate,now)
 assert(snapshot.ready and snapshot.checkedIn and snapshot.inventory.cat_paddle and snapshot.equipped.Paddle=="cat_paddle")
 local corruptShop=table.clone(shop); corruptShop.spendableXP=-1
 assert(not pcall(Rules.apply,corruptShop,{kind="Load"},now),"Malformed shop balances fail safely")
 assert(Repository.errorInfo("Unsupported progression data").code=="UnsupportedVersion")
 return "Atomic retries, unknown outcomes, cross-server deduplication, rejoin, throttling, corrupt-data preservation, and shutdown deadline passed"
end
