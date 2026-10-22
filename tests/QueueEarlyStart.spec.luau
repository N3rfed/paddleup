return function(Queue)
 local time=0
 local a,b={DisplayName="A"},{DisplayName="B"}
 local q=Queue.new(function() end,function() return time end,
  {NextInteger=function(_,low) return low end})
 assert(q:join(a,"Classic","Practice"))
 q:update(true)
 assert(not q:update(true),"Solo players still get to choose their map")
 q:configure(a,"Moon")
 local solo=q:update(true)
 assert(solo and solo.map=="Moon" and time==0,"AI practice starts immediately after the human picks")
 q:join(a,"Classic","1V1"); q:join(b,"Classic","1V1")
 q:update(true); q:configure(a,"Moon")
 assert(not q:update(true) and q.active.stage=="Setup","Wait for the remaining human")
 q:configure(b,"Moon")
 assert(not q:update(false),"A busy court still prevents admission")
 local match=q:update(true)
 assert(match and match.map=="Moon","All human picks start the match without a countdown or reveal delay")
 q:join(a,"Classic","1V1"); q:join(b,"Classic","1V1")
 q:update(true); q:configure(a,"Moon"); q:configure(b,"Rooftop")
 assert(not q:update(true) and q.active.stage=="Reveal","Ties enter the draw immediately")
 time=Queue.REVEAL_SECONDS
 assert(q:update(true),"The tie draw completes without waiting for the voting deadline")
 return "Immediate solo AI and completed human votes, pending votes, busy courts, and ties passed"
end
