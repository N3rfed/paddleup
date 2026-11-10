return function(Rewards,Config)
 local time=0
 local events={}
 local progression={award=function(_,player,reward,id) table.insert(events,{player=player,reward=reward,id=id}) end}
 local serial=0
 local tracker=Rewards.new(progression,function() return time end,function() serial+=1; return "match-"..serial end)
 local a,b={UserId=1},{UserId=2}
 local users={[a]={side=1},[b]={side=-1}}
 local function qualify()
  time+=Config.MinimumMatchSeconds
  for _=1,Config.MinimumContestedRallies do tracker:rally(3) end
  for _=1,Config.MinimumReturns do tracker:contact(a); tracker:contact(b) end
 end
 tracker:begin(users,"1V1"); tracker:complete(1)
 assert(#events==0,"Quick wins and idle joins earn no XP")
 tracker:begin(users,"1V1"); qualify(); tracker:complete(1); tracker:complete(1)
 assert(#events==2,"A qualifying completed match pays each participant once")
 local found={}; for _,event in ipairs(events) do found[event.player]=event.reward end
 assert(found[a]=="MatchWon" and found[b]=="MatchCompleted")
 table.clear(events); tracker:begin({[a]={side=1}},"Practice"); qualify(); tracker:complete(-1)
 assert(#events==1 and events[1].reward=="PracticeCompleted","Finished practice earns its lower reward")
 table.clear(events); tracker:begin(users,"1V1"); qualify(); tracker:begin({[a]={side=1}},"1V1"); tracker:complete(1)
 assert(#events==0,"Departures and roster changes invalidate unfinished reward runs")
 tracker:begin(users,"1V1"); time+=Config.MinimumMatchSeconds
 for _=1,100 do tracker:rally(0); tracker:contact(a) end
 tracker:complete(1)
 assert(#events==0,"Serve timeouts and unopposed repetitive actions earn no XP")
 tracker:begin(users,"1V1"); time+=Config.MinimumMatchSeconds
 for _=1,Config.MinimumContestedRallies do tracker:rally(3) end
 for _=1,Config.MinimumReturns do tracker:contact(a) end
 tracker:complete(1)
 assert(#events==1 and events[1].player==a,"Idle participants earn no completion XP")
 return "Completion, winner/practice values, repeat prevention, departures, timeouts, participation, and idle-player checks passed"
end
