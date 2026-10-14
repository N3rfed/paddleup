return function(C)
 for _,side in ipairs({1,-1}) do
  local state=C.new()
  C.update(state,{8,3},false)
  assert(state.side==0,"Only the requested 9-3 score triggers")
  local score=side==1 and {3,9} or {9,3}
  C.update(state,score,false)
  assert(C.active(state,side) and not C.active(state,-side) and not C.active(state,0),"Only trailing team is boosted")
  score=side==1 and {8,10} or {10,8}
  C.update(state,score,false)
  assert(C.active(state,side),"Boost persists until the trailing team catches up")
  C.update(state,{10,10},false)
  assert(state.side==0 and state.used,"Tie ends boost")
  C.update(state,{9,3},false)
  assert(state.side==0,"Cannot retrigger after catchup in the same match")
 end
 local state=C.new()
 C.update(state,{9,3},false); C.update(state,{11,3},true)
 assert(state.side==0,"Match end clears boost even if team never catches up")
 state=C.new(); C.update(state,{3,9},false)
 assert(state.side==1,"Fresh match can trigger independently")
 assert(C.MOVE==1.15 and C.HIT==1.15)
 return "Comeback score trigger, team isolation, persistence, tie, match end and reset passed"
end
