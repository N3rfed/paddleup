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
  q.limits["1v1"]=1
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
  q:finish(match.id)
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
  local singles=q:takeMatch()
  expect(singles.mode=="1v1","Incomplete doubles does not block ready singles")
  q:finish(singles.id)
  q:enqueue(4,"2v2"); q:enqueue(5,"2v2"); q:enqueue(6,"2v2")
  expect(q:takeMatch().mode=="2v2","Waiting doubles eventually starts")
  q:remove(4)
  expect(next(q.matches)==nil and q.players[4]==nil,"Disconnect releases match and removes player")
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
   q:finish(match.id)
  end
  party(q,1,{2})
  expect(not q:enqueue(1,"Practice","Easy"),"Practice does not split friend parties")
 end
 do
  local q=new(3)
  q:enqueue(1,"1v1"); q:enqueue(2,"1v1"); q:enqueue(3,"Practice","Hard")
  local match=q:takeMatch()
  expect(match.mode=="1v1","Practice does not jump a ready older queue")
  q:finish(match.id)
  expect(q:takeMatch().difficulty=="Hard","Practice starts when the court is free")
 end
 do
  local q=new(128)
  for id=1,42 do q:enqueue(id,"1v1") end
  for id=43,126 do q:enqueue(id,"2v2") end
  local singles,doubles={},{}
  while true do
   local match=q:takeMatch()
   if not match then break end
   table.insert(match.mode=="1v1" and singles or doubles,match)
  end
  expect(#singles==20 and #doubles==20,"Both pools support twenty concurrent games")
  expect(#q.queue==6,"Overflow players remain queued")
  expect(q:takeMatch()==nil,"Forty games is the hard limit")
  local survivor=doubles[1]
  expect(q:watch(127,true,survivor.id),"Spectators can choose a specific match")
  expect(q:match(127)==survivor,"Spectator is routed to the selected match")
  expect(q:watch(128,true,singles[1].id),"Spectator can watch singles independently")
  local released=singles[1]
  q:finish(released.id)
  expect(q:playing(survivor.members[1]) and q:match(127)==survivor,"Finishing singles leaves doubles and its spectators intact")
  expect(not q.players[128].watching,"Only spectators of the finished match return")
  local replacement=q:takeMatch()
  expect(replacement.mode=="1v1" and replacement.slot==released.slot and replacement.id~=released.id,"Freed singles slot is reused with a new match identity")
  q:remove(survivor.members[1])
  expect(q.matches[survivor.id]==nil and q:playing(replacement.members[1]),"Disconnect ends only the player's match")
  expect(q:takeMatch().mode=="2v2","Freed doubles slot admits the waiting doubles game")
  expect(not q:watch(127,true,survivor.id),"Ended match cannot be spectated")
 end
 do
  local q=new(25)
  for id=1,21 do q:enqueue(id,"Practice","Normal") end
  for id=22,25 do q:enqueue(id,"2v2") end
  local practice=0
  local doubles=0
  while true do
   local match=q:takeMatch()
   if not match then break end
   if match.bot then practice+=1 else doubles+=1 end
  end
  expect(practice==20 and doubles==1,"Practice shares the singles cap and cannot block available doubles courts")
  expect(#q.queue==1,"Overflow practice stays queued")
 end
 return tostring(checks).." lobby matchmaking, capacity, isolation, party, practice and spectator checks passed"
end
