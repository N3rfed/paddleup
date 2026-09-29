return function(Rotation)
 local r=Rotation.new()
 r:setTeams({11,12},{21,22})
 assert(r.side==1 and r.serverId==11 and r.number==2,"Doubles starts 0-0-2")
 assert(r:serveX()==10 and r:receiverId()==21)
 assert(r:award(1)=="point" and r.score[1]==1 and r.serverId==11)
 assert(r:serveX()==-10 and r:receiverId()==22,"Scoring must switch service courts and receivers")
 assert(r:award(-1)=="sideOut" and r.serverId==21 and r.number==1)
 assert(r.score[2]==0 and r:serveX()==-10 and r:receiverId()==12)
 assert(r:award(1)=="secondServer" and r.side==-1 and r.serverId==22 and r.number==2)
 assert(r:serveX()==10 and r:receiverId()==11,"Second server stays in their current court")
 assert(r:award(-1)=="point" and r.score[2]==1 and r.serverId==22)
 assert(r:serveX()==-10 and r:receiverId()==12)
 assert(r:award(1)=="sideOut" and r.serverId==12 and r.number==1,"Right-side teammate starts the next possession")
 assert(r:award(-1)=="secondServer" and r.serverId==11 and r.number==2)
 r:reset()
 assert(r.score[1]==0 and r.score[2]==0 and r.serverId==11 and r.number==2)

 -- A solo side gets one turn; the doubles side still gets both teammates.
 r=Rotation.new(); r:setTeams({11,12},{21})
 assert(r:award(-1)=="sideOut" and r.serverId==21 and r.number==1)
 assert(r:award(-1)=="point" and r:serveX()==10)
 assert(r:award(1)=="sideOut" and r.serverId==11 and r.number==1)
 assert(r:award(-1)=="secondServer" and r.serverId==12)
 assert(r:award(-1)=="sideOut" and r.serverId==21)
 r=Rotation.new(); r:setTeams({11},{21,22})
 assert(r.number==1 and r:award(-1)=="sideOut")
 assert(r:award(1)=="secondServer" and r.serverId==22)
 assert(r:award(1)=="sideOut" and r.serverId==11 and r.number==1)

 -- Practice and singles retain parity-based service courts and no second turn.
 r=Rotation.new(); r:setTeams({11},{0})
 assert(r.number==1 and r:receiverId()==0)
 r:award(1); assert(r:serveX()==-10)
 assert(r:award(-1)=="sideOut" and r.serverId==0)
 assert(r:award(1)=="sideOut" and r.serverId==11)
 r:setTeams({11},{21}); assert(r:receiverId()==21 and r.score[1]==1)
 r:setTeams({11,12},{21,22})
 assert(r.serverId==11 and r:serveX()==-10,"Joining teammates must preserve a live server's court")
 assert(r:award(-1)=="secondServer" and r.serverId==12)
 r:setTeams({11},{21,22})
 assert(r.serverId==11 and r.number==1 and r.score[1]==1,"Departing server must not strand service")
 r:setTeams({11},{22})
 assert(r:receiverId()==22)
 r:setTeams({},{}); r:reset(); r:setTeams({31},{0})
 assert(r.serverId==31 and r.side==1 and r.number==1)

 -- Long mixed rallies must never choose a missing/wrong-team server or receiver.
 r=Rotation.new(); r:setTeams({11,12},{21,22})
 for i=1,200 do
  local previousSide=r.side
  local a,b=r.score[1],r.score[2]
  local winner=i%3==0 and previousSide or -previousSide
  r:award(winner)
  assert(table.find(r.teams[r.side],r.serverId))
  assert(table.find(r.teams[-r.side],r:receiverId()))
  assert(r.number==1 or r.number==2)
  assert(r.score[1]+r.score[2]==a+b+(winner==previousSide and 1 or 0))
 end
 return "Doubles opening, second-server rotation, service courts, diagonal receivers, 2v1/1v2, singles/bot, roster changes, reset, and 200 rallies passed"
end
