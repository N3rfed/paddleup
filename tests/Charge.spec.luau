return function(Rules)
 for _,held in ipairs({0,0.1,0.31}) do
  assert(Rules.serveCharge(held/Rules.SERVE_METER_SPEED)=="net","Very early serves must hit the net")
 end
 for _,held in ipairs({0.32,0.5,0.669}) do
  local quality,depth=Rules.serveCharge(held/Rules.SERVE_METER_SPEED)
  assert(quality=="short" and depth<Rules.KITCHEN,"Early serves must land in the kitchen")
 end
 for _,held in ipairs({Rules.SERVE_GOOD_START,0.80,1.10,Rules.SERVE_GOOD_END}) do
  local quality,depth=Rules.serveCharge(held/Rules.SERVE_METER_SPEED)
  assert(quality=="good" and depth>Rules.KITCHEN and depth<Rules.BASELINE)
 end
 for _,held in ipairs({Rules.SERVE_PERFECT_START,0.95,Rules.SERVE_PERFECT_END}) do
  local quality,depth=Rules.serveCharge(held/Rules.SERVE_METER_SPEED)
  assert(quality=="perfect" and depth>Rules.KITCHEN and depth<Rules.BASELINE,"Center timing must produce a fast legal serve")
 end
 assert(Rules.SERVE_PERFECT_START>Rules.SERVE_GOOD_START and Rules.SERVE_PERFECT_END<Rules.SERVE_GOOD_END)
 assert(Rules.SERVE_GREAT_SPEED*(1+0.22*(Rules.serveZoneCenter(1)+0.03)/Rules.SERVE_METER_TIME)<Rules.slamSpeedScale(1)*1.8,"Great serve speed must remain below slam speed")
 assert(Rules.SERVE_PERFECT_SPEED>Rules.SERVE_GREAT_SPEED)
 assert(Rules.SERVE_GREAT_SPEED>1,"Fast serves must receive a speed bonus")
 for _,held in ipairs({1.231,1.5,4.5}) do
  local quality,depth=Rules.serveCharge(held/Rules.SERVE_METER_SPEED)
  assert(quality=="out" and depth>Rules.BASELINE,"Overcharged serves must go long")
 end
 for category,expected in ipairs({"out","undercharged","good","perfect","great"}) do
  for _,variation in ipairs({0,0.5,1}) do
   local quality=Rules.serveCharge(Rules.randomServeHold(category,variation))
   assert(quality==expected or (expected=="undercharged" and (quality=="net" or quality=="short")),"Timeout category must match the rolled outcome")
  end
 end
 for _,incoming in ipairs({-5,-20,-40,-80}) do
  local low=Rules.bounceVelocity(incoming,true)
  assert(low>=5 and low<=8 and low<Rules.bounceVelocity(incoming,false),"Undercharged serves must bounce lower")
 end
 for _,roll in ipairs({0,0.25,0.5,0.75,1}) do
  local center=Rules.serveZoneCenter(roll)
  local goodStart,goodEnd,perfectStart,perfectEnd,greatStart,greatEnd=Rules.serveZoneBounds(center)
  assert(goodStart>0 and goodEnd<Rules.SERVE_METER_TIME,"Zones must not touch the bar edges")
  assert(greatStart>goodStart and greatEnd<goodEnd)
  assert(perfectStart>greatStart and perfectEnd<greatEnd)
  assert(perfectStart-greatStart>perfectEnd-perfectStart and greatEnd-perfectEnd>perfectEnd-perfectStart,"Each great-only section must be wider than perfect")
  assert(math.abs((greatStart+greatEnd)/2-center)<1e-8)
  assert(math.abs((perfectStart+perfectEnd)/2-(goodStart+goodEnd)/2)<1e-8,"Perfect must be centered")
  for category,expected in ipairs({"out","undercharged","good","perfect","great"}) do
   for _,variation in ipairs({0,0.5,1}) do
    local forward=Rules.randomServeHold(category,variation,center)
    for _,held in ipairs({forward,2*Rules.SERVE_METER_TIME/Rules.SERVE_METER_SPEED-forward,6*Rules.SERVE_METER_TIME/Rules.SERVE_METER_SPEED+forward}) do
     local quality=Rules.serveCharge(held,center)
     assert(quality==expected or (expected=="undercharged" and (quality=="net" or quality=="short")),"Both directions and later cycles must preserve every outcome")
    end
   end
  end
 end
 assert(Rules.serveMeterPosition(0)==0)
 assert(Rules.serveMeterPosition(1.5/Rules.SERVE_METER_SPEED)==1.5)
 assert(Rules.serveMeterPosition(3/Rules.SERVE_METER_SPEED)==0)
 assert(Rules.serveMeterPosition(4.5/Rules.SERVE_METER_SPEED)==1.5)
 assert(not Rules.hitReady(10,10.28,false),"Ordinary attempts must respect the hit cooldown")
 assert(Rules.hitReady(10,10.28,true),"Perfect timing must bypass an existing hit cooldown")
 assert(Rules.hitReady(10.28,10.28,false),"Hit cooldown must expire at its deadline")
 assert(Rules.chargeAmount(nil,10)==0)
 assert(Rules.chargeAmount(10,10.1)==0)
 assert(math.abs(Rules.chargeAmount(10,10.7)-0.5)<1e-8,"Half charge follows the 0.4-second hold threshold")
 assert(Rules.chargeAmount(10,20)==1)
 assert(math.abs(Rules.returnSpeed(2,true,false,true)-2.14)<1e-8)
 assert(Rules.returnSpeed(0.8,true,false,true)==1.07)
 assert(Rules.returnSpeed(1,true,true,true)==1.1)
 assert(Rules.returnSpeed(1,false,false,true)==0.95)
 local from,target=Vector3.new(0,184,25),Vector3.new(0,181.7,-27)
 assert(Rules.chargeTarget(from,target,0,1,1,1)==target)
 local full=Rules.chargeTarget(from,target,1,1,1,1)
 local half=Rules.chargeTarget(from,target,0.5,1,1,1)
 assert(full.Z < -40, 'Mistimed full charge must be able to sail out')
 assert(math.abs(full.X)==16 and full.Y==target.Y)
 assert((half-target).Magnitude<(full-target).Magnitude)
 local opposite=Rules.chargeTarget(from,target,1,1,-1,1)
 assert(opposite.X==-full.X)
 for _,rally in ipairs({1,1.5,2,4}) do
  assert(rally*1.22 < Rules.slamSpeedScale(rally)*1.8, 'Spike profile must stay faster')
 end
 return 'Charge timing, rally increments, spike priority, and out-of-bounds variance passed'
end
