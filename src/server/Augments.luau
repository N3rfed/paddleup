-- Draft catalog and pure effect rules. Distances use the painted 20 x 44 foot court.
-- The court is 40 x 80 studs; width defines two studs per foot.
local Augments={DURATION=20}
local archetypes={
 {"Fleet Foot", "speed", 0.08, "Move %d%% faster", "WIND"},
 {"Second Wind", "regen", 0.18, "Recover stamina %d%% faster", "PULSE"},
 {"Long Reach", "reach", 0.06, "Extend contact range by %d%%", "ORBIT"},
 {"Quick Reset", "dive", 0.08, "Reduce dive cooldown by %d%%", "WIND"},
 {"Light Steps", "speed", 0.07, "Move %d%% faster", "ORBIT"},
 {"Deep Breath", "regen", 0.20, "Recover stamina %d%% faster", "PULSE"},
 {"Wide Guard", "reach", 0.07, "Extend contact range by %d%%", "SHIELD"},
 {"Acrobat", "dive", 0.09, "Reduce dive cooldown by %d%%", "ORBIT"},
 {"Court Runner", "speed", 0.09, "Move %d%% faster", "WIND"},
 {"Endless Rhythm", "regen", 0.16, "Recover stamina %d%% faster", "PULSE"},
 {"Sweet Spot", "reach", 0.08, "Extend contact range by %d%%", "SHIELD"},
 {"Fast Reset", "dive", 0.10, "Reduce dive cooldown by %d%%", "WIND"},
}
Augments.catalog={
 {id="kitchenCamper",tier=1,name="Kitchen Camper",symbol="WIND",description="Move 15% faster within 2 feet of the kitchen line. Retreating to baseline disables it this rally."},
 {id="dinkSpecialist",tier=1,name="Dink Specialist",symbol="PULSE",description="Land 3 consecutive dinks to boost your next baseline drive speed by 20%."},
 {id="carbonFiber",tier=1,name="Carbon Fiber Core",symbol="SHIELD",description="Your paddle sweet spot is 15% wider, reducing off-center mishits."},
 {id="secondServe",tier=1,name="Second Serve",symbol="PULSE",description="Once per match, a serve fault grants a free retry and fully restores stamina."},
 {id="sliceDice",tier=1,name="Slice and Dice",symbol="ORBIT",description="Slice shots bounce 10% lower. Press X to slice."},
 {id="thirdShot",tier=2,name="The Third-Shot Drop",symbol="ORBIT",description="Your third shot is guided to the kitchen with +40% accuracy and heavy topspin."},
 {id="serveVolley",tier=2,name="Serve and Volley",symbol="WIND",description="Gain 75% movement speed for 3 seconds after serving."},
 {id="vampiricReach",tier=2,name="Vampiric Reach",symbol="PULSE",description="Win a point at the net to permanently gain 1% reach, up to 10%."},
 {id="atpAssassin",tier=2,name="ATP (Around the Post) Assassin",symbol="ORBIT",description="Land a shot around a net post to drain 30% of opponents' max stamina."},
 {id="baitSwitch",tier=2,name="Bait and Switch",symbol="WIND",description="Press lob (R) during a smash windup for a perfect drop. Retreating opponents are stunned for 1 second."},
 {id="erne",tier=3,name="Erne Executioner",symbol="PULSE",description="A legal jumping volley outside the sideline has 300% power and wins on paddle contact."},
 {id="phantom",tier=3,name="Phantom Paddle",symbol="SHIELD",description="Gain 8 inches of invisible paddle reach on your backhand side."},
 {id="lava",tier=3,name="Kitchen is Lava",symbol="PULSE",description="Opponents touching their kitchen line suffer double stamina drain for the rest of the rally."},
 {id="overcharge",tier=3,name="Rally Overcharge",symbol="WIND",description="After 15 shots, ignite your paddle, ignore incoming spin, and unleash one unreturnable smash."},
 {id="deflector",tier=3,name="Deflector Shield",symbol="SHIELD",description="Torso drives automatically deflect into the opponent's court at twice their incoming speed."},
 {id="perfectVision",tier=1,name="Perfect Vision",symbol="EYE",description="The green perfect-hit timing window is 20% longer, before and after a bounce."},
 {id="quickRecovery",tier=1,name="Quick Recovery",symbol="RESET",description="Recover from dive movement and animation locks 50% faster."},
 {id="baselineSentinel",tier=1,name="Baseline Sentinel",symbol="COURT",description="Move sideways 15% faster within 2 feet of the baseline."},
 {id="calculatedReturn",tier=1,name="Calculated Return",symbol="TARGET",description="Standard returns of serve send the ball back at 80% of its incoming velocity."},
 {id="momentumShift",tier=2,name="Momentum Shift",symbol="BOLT",description="Three consecutive perfect hits charge your fourth return with +15% rally acceleration."},
 {id="offensiveDive",tier=2,name="Offensive Dive",symbol="DIVE",description="Dive hits apply maximum topspin, sharply increasing descent after crossing the net."},
 {id="kitchenWarden",tier=2,name="Kitchen Warden",symbol="SHIELD",description="Stand still at the kitchen line to extend your hit sphere forward by 25%."},
 {id="deceptiveDrop",tier=2,name="Deceptive Drop",symbol="MASK",description="Hold dive while swinging to fake a smash and hit a soft drop. Enemy reticles disappear for 0.5s."},
 {id="apexPredator",tier=3,name="Apex Predator",symbol="APEX",description="Hit at the bounce apex to disguise accelerated ball speed until it crosses the net."},
 {id="rhythmMaster",tier=3,name="Rhythm Master",symbol="RHYTHM",description="After 10 rally hits, perfect swings hide your paddle and its angle."},
 {id="afterimage",tier=3,name="Afterimage",symbol="CLONE",description="Dives leave a solid visual clone for 2s. Hit within 1s to show opponents a decoy landing spot."},
 {id="terminalVelocity",tier=3,name="Terminal Velocity",symbol="INFINITY",description="Uncapped +8% perfect-hit acceleration. Win a rally exceeding 1.5x speed for permanent +5% movement."},
}
function Augments.has(build,id) return build~=nil and build[id]==true end
function Augments.newRally()
 return {perfectChain=0,diveStarted=-math.huge,tension=0,camperActive=false,camperLost=false,lava=false,burstUntil=0,stunUntil=0,overchargeUsed=false}
end
function Augments.perfect(build,timeToBounce,sinceBounce)
 local scale=Augments.has(build,"perfectVision") and 1.2 or 1
 return timeToBounce<=0.23*scale or sinceBounce<=0.28*scale
end
function Augments.diveDuration(build)
 local scale=Augments.has(build,"quickRecovery") and 0.5 or 1
 return 0.48*scale,0.66*scale
end
function Augments.lateralScale(build,depth,x,lateral)
 return Augments.has(build,"baselineSentinel") and math.abs(depth-40)<=4 and math.abs(x)<=20
  and math.sqrt(1+(1.15^2-1)*math.clamp(lateral*lateral,0,1)) or 1
end
function Augments.warden(build,depth,x,speed,grounded)
 return Augments.has(build,"kitchenWarden") and grounded and math.abs(depth-14)<=1 and math.abs(x)<=20 and speed<=1
end
function Augments.acceleration(build,state,speed,clean,slam,charged,normal)
 local ready=Augments.has(build,"momentumShift") and state.perfectChain>=3
 state.perfectChain=clean and (ready and 0 or state.perfectChain+1) or 0
 if ready then return math.max(1,speed)*1.15,"MOMENTUM SHIFT! +15%" end
 if clean and Augments.has(build,"terminalVelocity") then return math.max(1,speed)*1.08,"TERMINAL VELOCITY! +8%" end
 return normal(speed,clean,slam,charged),nil
end
function Augments.terminalWin(build,state,peak)
 if Augments.has(build,"terminalVelocity") and peak>1.5 then state.speedWins=(state.speedWins or 0)+1 end
end
function Augments.apex(build,bounces,vy,gravity)
 return Augments.has(build,"apexPredator") and bounces>0 and math.abs(vy)<=gravity*0.06
end
function Augments.tracking(opponent,live,now,hiddenUntil,glitchUntil,heavy,beforeNet)
 return opponent and live and now<(hiddenUntil or 0), opponent and live and now<(glitchUntil or 0),
  opponent and live and heavy==true and beforeNet
end
function Augments.camp(state,depth,x,kitchen,baseline)
 if state.camperActive and depth>=baseline then state.camperLost=true end
 local near=math.abs(depth-kitchen)<=4 and math.abs(x)<=20
 if near and not state.camperLost then state.camperActive=true end
 return near and not state.camperLost
end
function Augments.dink(state,landed)
 state.tension=landed and math.min(3,state.tension+1) or 0
 if state.tension==3 then state.driveReady=true end
end
function Augments.drive(state,baseline)
 if baseline and state.driveReady then state.tension=0; state.driveReady=false; return 1.2 end
 return 1
end
function Augments.onFire(build,state,shots)
 return Augments.has(build,"overcharge") and shots>15
end
function Augments.retryServe(build,state)
 if not Augments.has(build,"secondServe") or state.secondServeUsed then return false end
 state.secondServeUsed=true
 return true
end
function Augments.netWin(build,state,atNet)
 if atNet and Augments.has(build,"vampiricReach") then state.reachStacks=math.min(10,(state.reachStacks or 0)+1) end
end
function Augments.extraReach(build,state,backhand)
 return (state.reachStacks or 0)*0.01, (Augments.has(build,"phantom") and backhand) and 4/3 or 0
end
-- Solve flight time for a specified launch speed; low arc first, high arc if needed.
function Augments.flightTimes(horizontal,height,speed,gravity)
 local a=speed*speed-gravity*height
 local discriminant=a*a-gravity*gravity*(horizontal*horizontal+height*height)
 if discriminant<0 or a<=0 then return nil end
 local root=math.sqrt(discriminant)
 return math.sqrt(2*(a-root)/(gravity*gravity)),math.sqrt(2*(a+root)/(gravity*gravity))
end
function Augments.bounceScale(spin,sliceBoost)
 -- Scale velocity by sqrt(height ratio), since bounce height is proportional to v^2.
 return spin=="slice" and math.sqrt(sliceBoost and 0.9 or 1) or spin=="topspin" and math.sqrt(0.55) or 1
end
Augments.caps={speed=0.6,regen=1.5,reach=0.4,dive=0.5}
function Augments.roll(random)
 local roll=random:NextNumber()
 return roll<0.6 and 1 or roll<0.9 and 2 or 3
end
function Augments.deal(random,count,builds)
 assert(count>=1 and count<=4,"Draft supports one to four players")
 local tier=Augments.roll(random)
 local pool={}
 for index,base in ipairs(archetypes) do
  local amount=base[3]*tier
  table.insert(pool,{id=tostring(tier)..":"..index,name=base[1],stat=base[2],amount=amount,
   description=string.format(base[4],math.floor(amount*100+0.5)),symbol=base[5],tier=tier})
 end
 for _,card in ipairs(Augments.catalog) do
  if card.tier==tier then table.insert(pool,card) end
 end
 for index=#pool,2,-1 do
  local other=random:NextInteger(1,index)
  pool[index],pool[other]=pool[other],pool[index]
 end
 local offers={}
 for player=1,count do
  offers[player]={}
  for slot=1,3 do
   for index,card in ipairs(pool) do
    if card.stat or not Augments.has(builds and builds[player],card.id) then
     offers[player][slot]=table.remove(pool,index); break
    end
   end
   assert(offers[player][slot],"Insufficient draft cards")
  end
 end
 return tier,offers
end
function Augments.choose(offer,id,stats)
 if not offer or type(id)~="string" then return nil end
 for _,card in ipairs(offer) do
  if card.id==id then
   if card.stat then
    stats[card.stat]=math.min(Augments.caps[card.stat],(stats[card.stat] or 0)+card.amount)
   else stats[card.id]=true end
   return card
  end
 end
 return nil
end
return Augments
