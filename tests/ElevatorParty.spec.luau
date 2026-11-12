return function(Party,Queue)
 local time=0
 local random={NextInteger=function(_,low) return low end}
 local function player(id) return {UserId=id,DisplayName="P"..id} end
 local a,b,c,d,e=player(1),player(2),player(3),player(4),player(5)
 local function party(capacity)
  return Party.new({id="test",format=capacity==2 and "1V1" or "2V2",capacity=capacity,voteSeconds=15,departureSeconds=6},function() return time end,random)
 end
 local p=party(2)
 assert(p:join(a) and not p:readyUp(a),"Cannot ready before full")
 time=100000; p:update(); assert(p.stage=="Waiting","Partial parties wait indefinitely")
 assert(p:join(b) and not p:join(c),"Capacity enforced")
 assert(not p:vote(a,"Classic") and not p:readyUp(c),"Only members act in the correct stage")
 assert(p:readyUp(a) and not p:readyUp(a) and p:readyUp(b),"Ready is once per player")
 assert(p.stage=="Voting" and p.endsAt==time+15,"All ready starts shared voting deadline")
 assert(not p:join(c),"Locked parties reject arrivals")
 assert(not p:vote(c,"Chaos") and not p:vote(a,"Arcade"),"Validate membership and mode")
 assert(p:vote(a,"Classic") and not p:vote(a,"Chaos") and p:vote(b,"Chaos"),"One vote per member")
 p:update(); assert(p.stage=="Departing" and p.mode=="Classic","Tied allowed modes use server randomness")
 assert(p:leave(a) and p.stage=="Waiting" and not next(p.ready) and not next(p.votes),"Departure resets voting and readiness")
 p=party(4)
 assert(p:join(a,"Classic") and not p:join(b,"Chaos"),"Incompatible preferences cannot share a party")
 assert(p:join(b,"Any") and p:join(c) and p:join(d) and not p:join(e),"2v2 capacity")
 for _,v in ipairs({a,b,c,d}) do assert(p:readyUp(v)) end
 assert(not p:vote(b,"Chaos") and p:vote(a,"Classic"),"Specific queued preferences constrain every vote")
 time+=15; assert(not p:vote(b,"Classic"),"Reject votes at deadline")
 p:update(); assert(p.mode=="Classic","Abstentions cannot defeat preference compatibility")
 p=party(4)
 for _,v in ipairs({a,b,c,d}) do p:join(v); p:readyUp(v) end
 -- Joining later members resets earlier readiness.
 for _,v in ipairs({a,b,c,d}) do p:readyUp(v) end
 p:vote(a,"Chaos"); p:vote(b,"Chaos"); p:vote(c,"Classic"); p:vote(d,"Chaos")
 p:update(); assert(p.mode=="Chaos","Majority selects Chaotic")
 local q=Queue.new(function() end,function() return time end,random)
 q:join(a,"Classic","1V1"); q:join(b,"Classic","1V1")
 assert(q:reserve(a,1) and not q:reserve(a,2),"One invitation per queued player")
 q:update(true); assert(not q.active,"An invitation prevents simultaneous normal dispatch")
 q:release(a,2); assert(q:isReserved(a,1),"Stale responses cannot release another invitation")
 q:release(a,1); q:update(true)
 assert(q.active and not q:reserve(a,3),"Active menu setup cannot be recruited")
 q:remove(a); assert(not q:isReserved(a,1),"Queue cancellation clears reservations")
 return "Party capacity, indefinite waiting, readiness, departure reset, voting, majority/ties, deadlines, preferences, and queue reservation races passed"
end
