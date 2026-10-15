return function(Rules)
 assert(Rules.canServe(42,42,true),"Designated server can use the serve meter")
 assert(not Rules.canServe(43,42,true),"Receiver or doubles teammate cannot use the server's meter")
 assert(not Rules.canServe(42,0,true),"Practice receiver cannot charge the bot's serve")
 assert(not Rules.canServe(42,nil,true),"Missing server must not expose a meter")
 assert(not Rules.canServe(42,42,false),"Meter must close once serving ends")
 assert(Rules.canServe(-1,-1,true),"Studio test players retain serving access")
 assert(Rules.BOT_SERVE_DELAY==2 and Rules.SERVE_TIMEOUT==15)
 local start=100
 local n,o,a,g=Rules.serveTiming(start,start)
 assert(n==0 and o==-1 and a==0 and g=="UNDERCHARGED")
 for _,held in ipairs({0.94,1,1.06,2.94,3,3.06,5}) do
  local _,_,_,grade=Rules.serveTiming(start,start+held)
  assert(grade=="PERFECT!","Tight perfect zone is reachable on both sweeps")
 end
 for _,held in ipairs({0.6,0.8,0.93,1.07,1.4,2.6,3.4}) do
  local _,_,_,grade=Rules.serveTiming(start,start+held)
  assert(grade=="GOOD","Generous good zone surrounds perfect")
 end
 for _,held in ipairs({2,6,10}) do
  local needle,_,_,grade=Rules.serveTiming(start,start+held)
  assert(needle==1 and grade=="OVERCHARGED","Top of each cycle overcharges")
 end
 for _,held in ipairs({0,4,8,12}) do
  local needle,_,_,grade=Rules.serveTiming(start,start+held)
  assert(needle==0 and grade=="UNDERCHARGED","Meter cycles back to bottom")
 end
 for _,side in ipairs({1,-1}) do
  for _,x in ipairs({10,-10}) do
   for step=0,150 do
    local _,offset,_,grade=Rules.serveTiming(start,start+step/10)
    local target=Rules.timedServeTarget(side,x,offset)
    if grade=="PERFECT!" or grade=="GOOD" then
     assert(Rules.serveLandingValid(target,side,x),"Good and perfect serve targets are legal")
    elseif grade=="UNDERCHARGED" then
     assert(-target.Z*side<Rules.KITCHEN,"Undercharged releases stay short")
    else assert(-target.Z*side>Rules.BASELINE,"Overcharged releases go long") end
   end
  end
 end
 assert(Rules.SERVE_PERFECT_OFFSET<Rules.SERVE_GOOD_OFFSET)
 return "Cycling serves, two-direction perfect/good boundaries and legal/fault targets passed"
end
