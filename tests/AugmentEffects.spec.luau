return function(A)
 local state=A.newRally()
 assert(not A.camp(state,40,0,14,40),"Starting at baseline does not grant camper")
 assert(A.camp(state,18,0,14,40),"Two-foot boundary included")
 assert(not A.camp(state,19,0,14,40),"Outside camper radius")
 assert(A.camp(state,14,0,14,40),"Can reenter until baseline retreat")
 A.camp(state,40,0,14,40)
 assert(not A.camp(state,14,0,14,40),"Baseline retreat disables camper")
 assert(A.camp(A.newRally(),14,0,14,40),"New rally resets camper")
 A.dink(state,true); A.dink(state,true); A.dink(state,false)
 assert(state.tension==0 and not state.driveReady,"Consecutive dinks required")
 for _=1,3 do A.dink(state,true) end
 assert(A.drive(state,false)==1 and state.driveReady,"Only baseline drives consume tension")
 A.dink(state,false)
 assert(A.drive(state,true)==1.2 and A.drive(state,true)==1,"Armed drive survives other shots and fires once")
 assert(not A.newRally().driveReady,"Tension cannot carry across rallies")
 local match={}
 assert(not A.retryServe({},match),"Mulligan requires augment")
 assert(A.retryServe({secondServe=true},match),"First fault gets mulligan")
 assert(not A.retryServe({secondServe=true},match),"Only one mulligan per match")
 assert(A.retryServe({secondServe=true},{}),"Fresh match restores mulligan")
 A.netWin({vampiricReach=true},match,false)
 assert(not match.reachStacks,"Baseline wins grant no reach")
 for _=1,15 do A.netWin({vampiricReach=true},match,true) end
 assert(match.reachStacks==10,"Vampiric reach caps at ten wins")
 local reach,extension=A.extraReach({phantom=true},match,true)
 assert(reach==0.1 and math.abs(extension-4/3)<1e-9,"Reach stacks and backhand inches combine")
 local _,forehand=A.extraReach({phantom=true},match,false)
 assert(forehand==0,"Phantom never extends forehand")
 assert(math.abs(A.bounceScale("slice",true)^2-0.9)<1e-9,"Slice bounce height is exactly 10% lower")
 assert(A.bounceScale("slice",false)==1 and A.bounceScale(nil,true)==1,"Slice bonus only affects slice")
 assert(A.bounceScale("topspin",false)<1,"Heavy topspin lowers bounce")
 assert(not A.onFire({overcharge=true},state,15),"Fifteen shots is below threshold")
 assert(A.onFire({overcharge=true},state,16),"Sixteenth shot ignites")
 state.overchargeUsed=true
 assert(A.onFire({overcharge=true},state,17),"Spin immunity persists after smash consumption")
 assert(not A.onFire({},state,16),"Long rallies do not ignite unaugmented players")
 for _,speed in ipairs({50,112,300}) do
  local low,high=A.flightTimes(50,-3,speed,45)
  assert(low and high>=low,"A reflected shot can reach the court")
  for _,time in ipairs({low,high}) do
   local vx=50/time
   local vy=(-3+0.5*45*time*time)/time
   assert(math.abs(math.sqrt(vx*vx+vy*vy)-speed)<1e-6,"Deflection preserves exact requested speed")
   assert(math.abs(vy*time-22.5*time*time+3)<1e-6,"Deflection lands at target height")
  end
 end
 assert(not A.flightTimes(100,0,1,45),"Impossible launch is handled")
 return "Camper, tension, mulligans, reach, spin, overcharge and exact-speed reflection passed"
end
