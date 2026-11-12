return function(Rules,Repository,Config,Catalog)
 local now=20000*86400+3600
 local serial=0
 local function op(kind,item,category,id) serial+=1; return {kind=kind,item=item,category=category,id=id or "shop-test-"..serial,at=now} end
 local legacy=Rules.new(); legacy.version=2; legacy.spendableXP=nil; legacy.inventory=nil; legacy.equipped=nil
 legacy.totalXP=2000; legacy.level=3; legacy.xp=31; legacy.streak=2
 local migrated=Rules.apply(legacy,op("Load"),now)
 assert(migrated.version==3 and migrated.spendableXP==2000*Config.ShopCurrencyRatio and migrated.level==3 and migrated.xp==31 and migrated.streak==2)
 assert(legacy.version==2 and legacy.inventory==nil,"Migration cannot mutate its input")
 local loaded=Rules.apply(migrated,op("Load"),now)
 assert(loaded.spendableXP==migrated.spendableXP,"Repeated migration cannot mint currency")
 local lotus,lotusReceipt=Rules.apply(loaded,op("ShopBuy","paddle_lotus"),now)
 assert(lotusReceipt.kind=="Purchased" and lotus.inventory.paddle_lotus
  and lotus.spendableXP==loaded.spendableXP-Catalog.ById.paddle_lotus.price,"Lotus Lake can be purchased at its server catalog price")
 local item=Catalog.ById.paddle_porcelain
 local buy=op("ShopBuy",item.id)
 local purchased,receipt=Rules.apply(loaded,buy,now)
 assert(receipt.kind=="Purchased" and purchased.inventory[item.id] and purchased.spendableXP==migrated.spendableXP-item.price)
 assert(purchased.totalXP==2000 and purchased.level==3 and purchased.xp==31,"Spending cannot change lifetime XP or progression")
 assert(not loaded.inventory[item.id],"Transform retries must not mutate the previous record")
 local replay=Rules.apply(purchased,buy,now)
 local duplicate,owned=Rules.apply(replay,op("ShopBuy",item.id),now)
 assert(owned.kind=="Owned" and duplicate.spendableXP==purchased.spendableXP,"Same and different request IDs cannot double charge ownership")
 local equipped=Rules.apply(duplicate,op("ShopEquip",item.id),now)
 assert(equipped.equipped.Paddles==item.id)
 local denied,denial=Rules.apply(equipped,op("ShopEquip","paddle_noir"),now)
 assert(denial.kind=="NotOwned" and denied.equipped.Paddles==item.id)
 local unequipped=Rules.apply(denied,op("ShopUnequip",nil,"Paddles"),now)
 assert(unequipped.equipped.Paddles==nil and unequipped.inventory[item.id] and unequipped.spendableXP==purchased.spendableXP)
 local poor=Rules.new(); local insufficient,result=Rules.apply(poor,op("ShopBuy",item.id),now)
 assert(result.kind=="Insufficient" and insufficient.spendableXP==0 and next(insufficient.inventory)==nil)
 local invalid,invalidResult=Rules.apply(purchased,op("ShopBuy","missing"),now)
 assert(invalidResult.kind=="InvalidItem" and invalid.spendableXP==purchased.spendableXP)
 local expired=op("ShopBuy","paddle_noir"); expired.at=now-Config.ReceiptSeconds-1
 local expiredData=Rules.apply(purchased,expired,now); assert(expiredData.spendableXP==purchased.spendableXP)
 -- Every existing grant source, including multiplied gameplay and weekly bonuses, mints matching currency once.
 local rewards=Rules.new()
 for day=0,6 do
  now=(20000+day)*86400+3600
  local before=rewards.totalXP; local balance=rewards.spendableXP
  local claim=op("CheckIn")
  local nextData,claimReceipt=Rules.apply(rewards,claim,now)
  assert(nextData.spendableXP-balance==(nextData.totalXP-before)*Config.ShopCurrencyRatio)
  rewards=Rules.apply(nextData,claim,now); assert(rewards.totalXP==nextData.totalXP and rewards.spendableXP==nextData.spendableXP)
  if day==6 then assert(claimReceipt.weekly>0,"Weekly reward was exercised") end
 end
 local gameplay=op("Gameplay"); gameplay.reward="MatchWon"
 local previous=rewards
 rewards=Rules.apply(rewards,gameplay,now)
 local earned=math.floor(Config.Rewards.MatchWon*Config.DailyMultiplier)
 assert(rewards.totalXP-previous.totalXP==earned and rewards.spendableXP-previous.spendableXP==earned*Config.ShopCurrencyRatio)
 local repeatReward=Rules.apply(rewards,gameplay,now); assert(repeatReward.spendableXP==rewards.spendableXP)
 -- Shared fake backend simulates two servers, unknown outcomes, transform retries and rejoining.
 local record=equipped; local fail=false; local unknown=false
 local store={UpdateAsync=function(_,_,transform)
  if fail then error("unavailable") end
  local abandoned=transform(record); assert(record.inventory[item.id],"Existing ownership survives transform retry")
  record=transform(record)
  if unknown then unknown=false; error("response lost after commit") end
  return record
 end}
 local repoA=Repository.new(store,function() return now end,function() end)
 local repoB=Repository.new(store,function() return now end,function() end)
 local luxury=op("ShopBuy","paddle_noir")
 unknown=true
 local afterUnknown=assert(repoA:commit(10,luxury))
 assert(afterUnknown.inventory.paddle_noir and afterUnknown.spendableXP==equipped.spendableXP-Catalog.ById.paddle_noir.price)
 local otherServer=assert(repoB:commit(10,op("ShopBuy","paddle_noir")))
 assert(otherServer.spendableXP==afterUnknown.spendableXP)
 local rejoined=assert(repoB:commit(10,op("Load")))
 assert(rejoined.equipped.Paddles==item.id and rejoined.inventory.paddle_noir and rejoined.totalXP==2000)
 fail=true; local oldBalance=record.spendableXP
 local failed=repoA:commit(10,op("ShopBuy","wear_headband"))
 assert(failed==nil and record.spendableXP==oldBalance and not record.inventory.wear_headband,"Failed stores cannot charge or grant")
 local corrupt=table.clone(record); corrupt.spendableXP=-1
 assert(not pcall(Rules.apply,corrupt,op("Load"),now),"Corrupt balances fail closed")
 local unknownSchema=table.clone(record); unknownSchema.version=4
 assert(not pcall(Rules.apply,unknownSchema,op("Load"),now),"Newer schemas are never reset")
 return "Migration, distinct currencies, all reward sources, buy/equip/unequip, insufficient funds, duplicate/expired/unknown requests, two servers, rejoin and failed stores passed"
end
