return function(source)
 local first=assert(source:find("local function dispatchQueue()",1,true))
 local last=assert(source:find("local function updateQueue()",first,true))
 local players={}
 local a,b={Parent=players},{Parent=players}
 local group={players={a,b},format="1V1",mode="Chaos",map="Moon",modifier="LowGravity"}
 local pending=group
 local owners={[a]=0,[b]=0}
 local entered,notifications={},{}
 local failed=false
 local controller={enter=function(_,player,format,mode,map,modifier)
  assert(format=="1V1" and mode=="Chaos" and map=="Moon" and modifier=="LowGravity")
  assert(notifications[player]=="Cancelled")
  if failed then return false end
  table.insert(entered,player); return true
 end}
 local returned={}
 local env=setmetatable({Players=players,owners=owners,closing=false,
  queue={update=function(_,available) assert(available); local result=pending; pending=nil; return result end},
  freeSlot=function() return 1 end,runtime=function() return controller end,runtimes={[1]=controller},roots={},
  move=function(player,id) owners[player]=id end,
  queueRemote={FireClient=function(_,player,data) notifications[player]=data.stage end},
  lobby=function(player) owners[player]=0; returned[player]=true end,warn=function() end},{__index=getfenv()})
 local chunk=assert(loadstring(source:sub(first,last-1).."\nreturn dispatchQueue")); setfenv(chunk,env)
 local dispatch=chunk()
 dispatch(); dispatch()
 assert(#entered==2 and owners[a]==1 and owners[b]==1,"The full group is admitted once")
 pending=group; owners[a]=0; owners[b]=0; failed=true
 dispatch()
 assert(returned[a] and returned[b] and owners[a]==0 and owners[b]==0,"Partial admission falls back to the lobby")
 table.clear(returned); failed=false; pending=group; b.Parent=nil
 dispatch()
 assert(returned[a] and returned[b],"Departed players cannot create an incomplete match")
 return "Completed groups, winning settings, duplicate dispatch, rejected admissions, and departed-player fallback passed"
end
