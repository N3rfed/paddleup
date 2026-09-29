return function(Rules)
 assert(Rules.chargeAmount(nil,10)==0)
 assert(Rules.chargeAmount(10,10.1)==0)
 assert(math.abs(Rules.chargeAmount(10,10.6)-0.5)<1e-8)
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
