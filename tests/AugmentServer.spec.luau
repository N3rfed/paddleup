-- Execute the real launch/scoring functions in an isolated server fixture.
-- Pass init.server.Source, Augments, MatchRules, and Comeback from Studio's command bar.
-- Vector3 components use float precision; trajectory tolerances stay below 0.0001 studs.
return function(source,A,Rules,Comeback)
 local first=assert(source:find("local function launch(",1,true))
 local last=assert(source:find("local function paddle(",first,true))
 local server={UserId=42,DisplayName="Server"}
 local receiver={UserId=43,DisplayName="Receiver"}
 local users={
  [server]={side=1,augments={secondServe=true},augmentMatch={},augmentRally=A.newRally()},
  [receiver]={side=-1,augments={vampiricReach=true},augmentMatch={},augmentRally=A.newRally()},
 }
 local awards,events=0,{}
 local ball={live=false,p=Vector3.new(0,184,40),v=Vector3.zero,speed=1,last=1,shots=0}
 local rotation={award=function() awards+=1; return "point" end}
 local environment=setmetatable({
  Comeback=Comeback,comeback=Comeback.new(),Augments=A,Rules=Rules,Vector3=Vector3,FLOOR=181.7,GRAVITY=45,BASE_SPEED=56,
  ball=ball,users=users,serverId=42,servingSide=1,score={0,0},rotation=rotation,
  courtVariant="Augmented",rallies=0,lastHitter={},
  Players={GetPlayerByUserId=function(_,id) return id==42 and server or receiver end},
  feedback={FireAllClients=function(_,data,kind) table.insert(events,{data=data,kind=kind}) end},
  syncServing=function() end,tell=function() end,activateAugment=function() end,resetAugments=function() end,
  occupant=function(side) return side==1 and server or receiver end,
  rootOf=function() return {Position=Vector3.new(0,184,-16)} end,
  lobCrossesSlamZone=function() return false end,
  practicePaused=function() return false end,
  matchStatus=function(data,kind) table.insert(events,{data=data,kind=kind}) end,
 },{__index=getfenv()})
 local chunk=assert(loadstring(source:sub(first,last-1).."\nreturn launch,point"))
 setfenv(chunk,environment)
 local launch,point=chunk()
 local from,target=Vector3.new(0,184,39),Vector3.new(0,181.7,-27)
 local function shot(multiplier,extra)
  ball.speed=1; ball.last=1
  local contact=extra or {}; contact.speedMultiplier=multiplier
  launch(from,target,false,false,false,0,nil,false,0,contact)
  return ball.v,ball.flightGravity
 end
 local base,g=shot(1)
 for _,factor in ipairs({1.2,3}) do
  local boosted,gravity=shot(factor)
  assert(math.abs(boosted.Magnitude/base.Magnitude-factor)<1e-5,"Net clearance cannot erase augment speed")
  assert(math.abs(gravity/g-factor*factor)<1e-5,"Speed boosts preserve the legal trajectory")
 end
 shot(1,{reflectedSpeed=160})
 assert(math.abs(ball.v.Magnitude-160)<1e-4,"Shield returns at exactly double an 80-speed drive")
 local t=(target.Z-from.Z)/ball.v.Z
 local y=from.Y+ball.v.Y*t-0.5*ball.flightGravity*t*t
 assert(math.abs(y-target.Y)<1e-4,"Shield lands in the opposing court")
 local tc=-from.Z/ball.v.Z
 assert(from.Y+ball.v.Y*tc-0.5*ball.flightGravity*tc*tc>=185.2,"Shield clears the net")
 ball.speed=1
 launch(from,target,false,false,false,0,nil,false,0,{uncapped=true})
 local terminalBase=ball.v.Magnitude
 ball.speed=100
 launch(from,target,false,false,false,0,nil,false,0,{uncapped=true})
 assert(math.abs(ball.v.Magnitude/terminalBase-100)<1e-4,"Terminal actual velocity is not capped by net-clearance assist")
 assert(ball.shotMultiplier==1,"Terminal rally speed is not counted twice in HUD or win thresholds")
 ball.speed=1
 for _,incoming in ipairs({20,40,100}) do
  shot(1,{reflectedSpeed=incoming*0.8})
  assert(math.abs(ball.v.Magnitude-incoming*0.8)<1e-4,"Calculated return preserves exactly 80% incoming speed, even for slow serves")
 end
 launch(from,target,false,false,false,0,nil,false,0,{offensive=true,spin="topspin",heavy=true,deceptive=true,afterimage=true})
 local duration=(target.Z-from.Z)/ball.v.Z
 local at=Rules.advanceFlight(from,ball.v,ball.flightGravity,duration,false,false,true,1)
 assert((at-target).Magnitude<1e-5,"Offensive dive still lands on its solved target")
 assert(ball.heavy and ball.offensive and ball.trackingHiddenUntil>os.clock() and ball.trackingGlitchUntil>os.clock(),"Deception metadata accompanies the accepted shot")
 launch(Vector3.new(25,183,5),Vector3.new(18,181.7,-27),false,false,false,0,nil,false,0,{atp=true,spin="slice",sliceBoost=true,deadly=true,userId=42})
 assert(ball.atp and ball.deadly and ball.spin=="slice" and ball.hitter==42,"Shot metadata reaches simulation")
 launch(from,target,false,false,false,0,nil,false,0,{})
 assert(not ball.atp and not ball.deadly and not ball.spin and not ball.hitter and not ball.heavy and not ball.offensive and ball.trackingHiddenUntil==0 and ball.trackingGlitchUntil==0,"Shot metadata cannot leak to the next hitter")
 for _,side in ipairs({1,-1}) do
  for _,held in ipairs({0,0.3,0.59,0.7,0.879,0.88,1,1.12,1.121,1.6,4}) do
   local _,offset,_,grade=Rules.serveTiming(100,100+held)
   local origin=Vector3.new(10,184,46*side)
   local destination=Rules.timedServeTarget(side,10,offset)
   ball.speed=Rules.servePower(offset+1); ball.last=side
   launch(origin,destination,false,false,false,0,nil,offset<Rules.SERVE_NET_OFFSET,0,{maxVelocity=offset>=Rules.SERVE_NET_OFFSET and Rules.MAX_SERVE_VELOCITY or nil})
   local crossing=-origin.Z/ball.v.Z
   local atNet=Rules.advanceBall(origin,ball.v,ball.flightGravity,crossing,false,false)
   if offset<Rules.SERVE_NET_OFFSET then
    assert(atNet.Y<184.65 and atNet.Y>181.7,"Weak serve physically strikes the net")
   else
    assert(atNet.Y>=184.65,"Charged serve clears the net")
    local duration=Rules.ballLandingTime(origin.Y-181.7,ball.v.Y,ball.flightGravity,false,false)
    local impact=Rules.advanceBall(origin,ball.v,ball.flightGravity,duration,false,false)
    assert((impact-destination).Magnitude<1e-5,"Serve velocity cap preserves intended fault or legal landing")
    assert(Rules.serveLandingValid(impact,side,10)==(grade=="PERFECT!" or grade=="GOOD"),"Good and perfect releases produce legal serves")
   end
  end
 end
 ball.last=1
 ball.shots=0; ball.live=true; users[server].stamina=4
 point(-1,"Net")
 assert(awards==0 and users[server].stamina==100,"Serve mulligan refills stamina without awarding or rotating")
 assert(users[server].augmentMatch.secondServeUsed and not ball.live,"Mulligan consumed, rally stopped")
 assert(environment.rallies==0,"Mulligan does not advance draft cadence")
 ball.live=true
 point(-1,"Serve fault: land in the diagonal service court")
 assert(awards==1,"Second serve fault follows normal scoring")
 assert(users[receiver].augmentMatch.reachStacks==1,"Net winner gains reach on actual point resolution")
 point(-1,"Net")
 assert(awards==1 and users[receiver].augmentMatch.reachStacks==1,"Repeated dead-ball scoring cannot stack reach")
 ball.shots=2; ball.live=true; users[server].augmentMatch={}
 users[receiver].augments.terminalVelocity=true; ball.peakSpeed=1.6
 point(-1,"Out")
 assert(users[receiver].augmentMatch.speedWins==1,"Terminal win reads peak rally speed before scoring resets it")
 assert(awards==2 and not users[server].augmentMatch.secondServeUsed,"Rally faults never consume serve retry")
 environment.score={9,3}; ball.live=true; ball.shots=2
 point(1,"Double bounce")
 assert(Comeback.active(environment.comeback,-1),"Score resolution activates the trailing team's comeback")
 environment.score={9,9}; ball.live=true
 point(-1,"Double bounce")
 assert(environment.comeback.side==0,"Score resolution clears comeback when tied")
 environment.comeback=Comeback.new(); environment.score={9,3}; ball.live=true
 point(1,"Double bounce")
 environment.score={11,3}; ball.live=true
 point(1,"Double bounce")
 assert(environment.comeback.side==0 and ball.resetScore,"Winning the match clears comeback")
 return "Server launch speed, shield trajectory, shot cleanup, mulligan scoring and net-win integration passed"
end
