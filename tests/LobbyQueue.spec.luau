return function(Lobby)
 local checks=0
 local function expect(value,message) assert(value,message); checks+=1 end
 local function new(count,clock)
  local q=Lobby.new(clock)
  for id=1,count do q:add(id) end
  return q
 end
 local function party(q,leader,members)
  for _,id in ipairs(members) do
   expect(q:invite(leader,id),"Leader can invite")
   expect(q:accept(id),"Invite can be accepted")
  end
 end
 do
  local q=new(4)
  expect(q:enqueue(1,"1v1"),"Solo can queue")
  expect(q:takeMatch()==nil,"Singles requires two")
  expect(not q:enqueue(1,"1v1"),"No duplicate queue entries")
  q:enqueue(2,"1v1")
  local match=q:takeMatch()
  expect(#match.home==1 and #match.away==1,"Singles must stay 1v1")
  expect(not q:enqueue(1,"2v2"),"Active players cannot requeue")
  expect(q:watch(3,true),"Lobby player can spectate")
  expect(not q:watch(1,true),"Active player cannot spectate")
  q:enqueue(3,"1v1"); q:enqueue(4,"1v1")
  expect(q:takeMatch()==nil,"One active match per court")
  q:finish()
  expect(not q.players[3].watching,"Spectators return after match")
  local nextMatch=q:takeMatch()
  expect(table.find(nextMatch.members,3) and table.find(nextMatch.members,4),"Next queue starts after court is released")
 end
 do
  local q=new(4)
  for id=1,3 do q:enqueue(id,"2v2") end
  expect(q:takeMatch()==nil,"No 2v1 starts")
  q:enqueue(4,"2v2")
  local match=q:takeMatch()
  expect(#match.home==2 and #match.away==2,"Doubles needs four players")
 end
 do
  local q=new(4)
  party(q,2,{3})
  q:enqueue(1,"2v2"); q:enqueue(2,"2v2"); q:enqueue(4,"2v2")
  local match=q:takeMatch()
  expect(table.find(match.home,2) and table.find(match.home,3),"Friend pair stays together even behind a solo")
  expect(not q:invite(1,4),"Cannot invite during match")
 end
 do
  local q=new(4)
  party(q,1,{2,3,4})
  expect(not q:enqueue(1,"1v1"),"Four-player party cannot enter singles")
  expect(not q:enqueue(2,"2v2"),"Only leader queues")
  q:enqueue(1,"2v2")
  local match=q:takeMatch()
  expect(match.home[1]==1 and match.home[2]==2 and match.away[1]==3 and match.away[2]==4,"Full friend group uses party order")
 end
 do
  local q=new(4)
  party(q,1,{2,3}); q:enqueue(1,"2v2"); q:enqueue(4,"2v2")
  expect(#q:takeMatch().members==4,"Party of three fills with a solo")
 end
 do
  local q=new(2)
  party(q,1,{2}); q:enqueue(1,"1v1")
  local match=q:takeMatch()
  expect(match.home[1]==1 and match.away[1]==2,"Friends face each other in singles")
 end
 do
  local q=new(4)
  party(q,1,{2}); q:enqueue(1,"2v2")
  q:leaveParty(2)
  expect(#q.queue==0,"Leaving party cancels the group queue")
  party(q,1,{2,3})
  q:remove(1)
  expect(q:party(2).leader==2 and q:party(3).leader==2,"Disconnect promotes next leader")
  expect(q.players[1]==nil,"Disconnected member is removed")
 end
 do
  local now=0
  local q=new(3,function() return now end)
  q:invite(1,2); now=31
  expect(not q:accept(2),"Expired invite rejected")
  q:invite(1,2); q:enqueue(1,"1v1")
  expect(not q:accept(2),"Cannot join a queued party through stale invite")
  expect(not q:enqueue(3,"bogus"),"Invalid modes rejected")
  expect(not q:watch(3,true),"Cannot watch an empty court")
 end
 do
  local q=new(6)
  q:enqueue(1,"2v2"); q:enqueue(2,"1v1"); q:enqueue(3,"1v1")
  expect(q:takeMatch().mode=="1v1","Incomplete doubles does not block ready singles")
  q:finish()
  q:enqueue(4,"2v2"); q:enqueue(5,"2v2"); q:enqueue(6,"2v2")
  expect(q:takeMatch().mode=="2v2","Waiting doubles eventually starts")
  q:remove(4)
  expect(q.active==nil and q.players[4]==nil,"Disconnect releases match and removes player")
 end
 do
  local q=new(2)
  expect(not q:enqueue(1,"Practice","Impossible"),"Invalid difficulty rejected")
  for _,difficulty in ipairs({"Easy","Normal","Hard"}) do
   expect(q:enqueue(1,"Practice",difficulty),"Solo practice can queue")
   local match=q:takeMatch()
   expect(match.bot and match.away[1]==0 and match.home[1]==1,"Practice uses one human and a bot")
   expect(#match.members==1 and match.difficulty==difficulty,"Bot is not treated as a connected player")
   expect(q:watch(2,true),"Practice can be spectated")
   q:finish()
  end
  party(q,1,{2})
  expect(not q:enqueue(1,"Practice","Easy"),"Practice does not split friend parties")
 end
 do
  local q=new(3)
  q:enqueue(1,"1v1"); q:enqueue(2,"1v1"); q:enqueue(3,"Practice","Hard")
  expect(q:takeMatch().mode=="1v1","Practice does not jump a ready older queue")
  q:finish()
  expect(q:takeMatch().difficulty=="Hard","Practice starts when the court is free")
 end
 return tostring(checks).." lobby matchmaking, party, queue, practice and spectator checks passed"
end
