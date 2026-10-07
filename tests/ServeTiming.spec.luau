return function(Rules)
 local start=100
 local period=Rules.SERVE_METER_PERIOD
 local n,o,a,g=Rules.serveTiming(start,start)
 assert(n==0 and o==-1 and a==0 and g=="EARLY")
 n,o,a,g=Rules.serveTiming(start,start+period/4)
 assert(math.abs(n-0.5)<1e-10 and math.abs(o)<1e-10 and math.abs(a-1)<1e-10 and g=="PERFECT!")
 n,o,a,g=Rules.serveTiming(start,start+period/2)
 assert(math.abs(n-1)<1e-10 and math.abs(o-1)<1e-10 and g=="LATE")
 local _,_,_,returnGrade=Rules.serveTiming(start,start+3*period/4)
 assert(returnGrade=="PERFECT!","Sweet spot must be reachable in both directions")
 local _,_,_,good=Rules.serveTiming(start,start+period*0.3)
 assert(good=="GOOD")
 for _,side in ipairs({1,-1}) do
  for _,x in ipairs({10,-10}) do
   assert(Rules.serveLandingValid(Rules.timedServeTarget(side,x,0),side,x))
   assert(not Rules.serveLandingValid(Rules.timedServeTarget(side,x,1),side,x),"Late edge must carry fault risk")
   assert(not Rules.serveLandingValid(Rules.timedServeTarget(side,x,-1),side,x),"Early edge must carry fault risk")
  end
 end
 assert(Rules.servePower(0)<Rules.servePower(0.5) and Rules.servePower(0.5)<Rules.servePower(1))
 assert(Rules.servePower(99)==Rules.servePower(1) and Rules.servePower(-99)==Rules.servePower(0))
 return "Serve timing cycles, grades, diagonal placement, edge faults, and power caps passed"
end
