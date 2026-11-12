-- Exercise the actual coordinator with injected queue, clock, ownership, and geometry.
return function(source,Party,Queue,Config)
 local now=0
 local players={list={}}
 function players:GetPlayers() return self.list end
 local ownerMap,events,positions={},{},{}
 local geometry={}
 for _,entry in ipairs(Config.Elevators) do
  geometry[entry.id]={config=entry,lastNear=0,label={},exit=CFrame.new(0,0,100),entry=CFrame.new(),
   contains=function(_,position) return position.X==0 end,setOpen=function() end,destroy=function() end}
 end
 local signal={Connect=function(_,fn) positions.onRequest=fn; return {Disconnect=function() end} end}
 local q=Queue.new(function() end,function() return now end)
 local ctx={lobby={},clock=function() return now end,owner=function(p) return ownerMap[p] end,queue=q,
  remote={OnServerEvent=signal,FireClient=function(_,p,data) events[p]=data end},
  start=function(group) positions.group=group; if positions.controller then positions.controller:update() end; return false end,pause=function(id,value) positions.paused=value end,
  replace=function(p,match,seat) positions.replaced=p; ownerMap[p]=match.courtId; return true end,
  terminate=function(id) positions.terminated=id end}
 local env=setmetatable({game={GetService=function() return players end},
  script={Parent={ElevatorConfig="config",ElevatorParty="party",ElevatorGeometry="geometry"}},
  require=function(name) return ({config=Config,party=Party,geometry={build=function() return geometry end}})[name] end},{__index=getfenv()})
 local chunk=assert(loadstring(source)); setfenv(chunk,env); local Service=chunk()
 local function player(id)
  local p={UserId=id,DisplayName="P"..id,Parent=players,attrs={SessionMode="Lobby",CourtSide=0},position=Vector3.zero}
  function p:GetAttribute(key) return self.attrs[key] end
  function p:SetAttribute(key,value) self.attrs[key]=value end
  local root={Position=Vector3.zero}
  p.Character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return {Health=100} end,
   PivotTo=function(_,cf) root.Position=cf.Position end}
  ownerMap[p]=0; table.insert(players.list,p); return p
 end
 local a,b,c,d=player(1),player(2),player(3),player(4)
 local s=Service.new(ctx); positions.controller=s; local party=s.parties[Config.Elevators[1].id]
 assert(s:join(a,party),"Physical party admission")
 q:join(b,"Classic","1V1"); q:join(c,"Chaos","1V1")
 assert(s:offer(party,"1V1") and s.offers[b],"Invite a compatible queued player")
 local first=s.offers[b].id
 s:respond(b,first,false); assert(q.members[b] and not s.members[b],"Declining retains menu queue")
 assert(s:offer(party,"1V1") and s.offers[c],"Decline offers next candidate")
 local second=s.offers[c].id
 s:respond(b,first,true); assert(not s.members[b],"Stale acceptance is ignored")
 s:respond(c,second,true)
 assert(s.members[c]==party and not q.members[c],"Acceptance transfers exclusive membership")
 assert(not party:allowed().Classic,"Accepted specific preference constrains final mode")
 local revision=party.revision
 positions.onRequest(a,"Ready",{revision=revision-1})
 assert(not party.ready[a],"Stale ready packets cannot affect a new roster")
 positions.onRequest(a,"Ready",{revision=revision})
 positions.onRequest(c,"Ready",{revision=revision})
 assert(party.stage=="Voting","Current roster can ready through remote handler")
 positions.onRequest(a,"Vote",{revision=revision-1,mode="Chaos"})
 assert(not party.votes[a],"Stale voting session packets are rejected")
 positions.onRequest(a,"Vote",{revision=revision,mode="Chaos"})
 assert(party.votes[a]=="Chaos","Current member can cast one authoritative vote")
 positions.onRequest(c,"Vote",{revision=revision,mode="Chaos"})
 local savedPlayers=players.list; players.list={}
 s:update(); assert(party.stage=="MapVoting","Coordinator publishes the map phase after mode voting")
 positions.onRequest(a,"MapVote",{revision=revision-1,map="Moon"})
 assert(not party.mapVotes[a],"Stale map packets cannot affect the vote")
 positions.onRequest(a,"MapVote",{revision=revision,map="Moon"})
 positions.onRequest(c,"MapVote",{revision=revision,map="Moon"})
 s:update(); assert(party.stage=="Departing","Winning map advances to reveal")
 now+=Config.RevealSeconds; s:update()
 assert(positions.group and positions.group.map=="Moon" and positions.group.mode=="Chaos"
  and positions.group.overviewSeconds==4,"Selected map and independent ruleset reach match admission")
 players.list=savedPlayers
 assert(not positions.group.valid(),"A changed party invalidates an in-flight admission")
 s:leave(c,true); assert(not s.members[c] and party.stage=="Waiting","Explicit leave frees the slot")
 local group={players={a,d},format="1V1",mode="Classic",map="Rooftop",modifier="None"}
 a:SetAttribute("CourtSide",1); a:SetAttribute("CourtSlot",1)
 d:SetAttribute("CourtSide",-1); d:SetAttribute("CourtSlot",1)
 ownerMap[a]=5; ownerMap[d]=5
 s:track(5,group); s:departed(d,5)
 assert(positions.paused and #s.matches[5].vacancies==1,"Pause before replacement offers")
 assert(s:offer(s.matches[5],"1V1","Classic") and s.offers[b],"Solo queue has first priority")
 s:respond(b,s.offers[b].id,false)
 local spectator=player(9); ownerMap[spectator]=5; spectator:SetAttribute("SessionMode","Spectate")
 assert(s:offer(s.matches[5],"1V1","Classic",true),"Spectator receives next offer")
 assert(not positions.replaced,"Spectator remains inactive before approval")
 local nextSpectator=player(10); ownerMap[nextSpectator]=5; nextSpectator:SetAttribute("SessionMode","Spectate")
 local stale=s.offers[spectator].id
 assert(s:offer(s.matches[5],"1V1","Classic",true) and not s.offers[nextSpectator],"Only one spectator is asked at a time")
 players.list={spectator,nextSpectator}
 now+=10; s:update()
 assert(not s.offers[spectator] and s.offers[nextSpectator],"Ten-second timeout offers the next spectator")
 s:respond(spectator,stale,true); assert(not positions.replaced,"Timed-out invitation cannot claim the vacancy")
 s:respond(nextSpectator,s.offers[nextSpectator].id,true)
 assert(positions.replaced==nextSpectator and not positions.paused,"Approved spectator fills seat and resumes")
 assert(s.matches[5].original[a.UserId] and not s.matches[5].original[nextSpectator.UserId]
  and s.matches[5].approved[nextSpectator],"Original roster differs from approved substitutes")
 s:departed(nextSpectator,5)
 -- Exhaust all candidates and verify authoritative termination deadline.
 s.matches[5].attempted[b]=true; s.matches[5].attempted[spectator]=true
 players.list={b}; ownerMap[b]=0
 s:update()
 assert(s.matches[5].terminatesAt==now+5,"Exhausted offers trigger five-second termination")
 now+=5; s:update(); assert(positions.terminated==5,"Termination clears the match after countdown")
 s:destroy()
 return "Invitation decline/accept/stale races, exclusive membership, mode constraints, paused replacement priority, approved spectator seats, and termination passed"
end

