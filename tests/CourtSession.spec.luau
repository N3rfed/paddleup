-- Pass CourtSession source and the actual pure gameplay modules. All Instances stay detached.
return function(source,modules)
 local function signal()
  local listeners={}
  local event={}
  function event:Connect(fn)
   local connection={Connected=true}
   function connection:Disconnect() self.Connected=false end
   table.insert(listeners,{fn=fn,connection=connection})
   return connection
  end
  function event:Fire(...)
   for _,item in ipairs(table.clone(listeners)) do if item.connection.Connected then item.fn(...) end end
  end
  function event:count()
   local n=0; for _,item in ipairs(listeners) do if item.connection.Connected then n+=1 end end
   return n
  end
  return event
 end
 local now=100
 local heartbeat=signal()
 local players={}
 function players:GetPlayerByUserId(id) return self[id] end
 local owners={}
 local delivered={}
 local network={}
 for _,name in ipairs({"Input","State","Feedback","Session","IntroReady","Powerup","Practice","Arcade","ArcadeLoadout"}) do
  local event={OnServerEvent=signal()}
  function event:FireClient(player,data,kind)
   delivered[player]=delivered[player] or {}
   delivered[player][name]={data=data,kind=kind}
  end
  network[name]=event
 end
 function network:WaitForChild(name) return assert(self[name],name) end
 local rewardRuns={}
 local progression={}
 local mocked=table.clone(modules)
 mocked.MatchRewards={new=function(service)
  assert(service==progression,"Courts share the profile service")
  local run={begins=0}
  function run:begin(users,mode) self.begins+=1; self.users=users; self.mode=mode end
  function run:rally() end
  function run:contact() end
  function run:complete() end
  table.insert(rewardRuns,run)
  return run
 end}
 mocked.Lobby={Spawn=CFrame.new()}
 mocked.Spectator={leave=function() end,enter=function() end}
 mocked.CourtEnvironments={valid=function(name) return name=="Rooftop" or name=="Moon" end,
  new=function() return {active="Rooftop",set=function(self,name) self.active=name end,destroy=function() end} end}
 mocked.CourtPickups={new=function() return {slots={},bursts={},reset=function() end,update=function() end} end}
 local scriptMock={Parent={WaitForChild=function(_,name) return name end}}
 local shared={WaitForChild=function(_,name) return name end}
 local services={Players=players,RunService={Heartbeat=heartbeat},ReplicatedStorage={WaitForChild=function() return shared end}}
 local environment=setmetatable({script=scriptMock,require=function(name) return assert(mocked[name],name) end,
  game={GetService=function(_,name) return assert(services[name],name) end},
  workspace={Gravity=196.2,GetServerTimeNow=function() return now end},os={clock=function() return now end}}, {__index=getfenv()})
 local chunk=assert(loadstring(source)); setfenv(chunk,environment)
 local Court=chunk()
 local roots,controllers={},{}
 local function court(id)
  local root=Instance.new("Model"); table.insert(roots,root)
  local controller=Court.new({id=id,height=id*4096,root=root,network=network,progression=progression,owner=function(p) return owners[p] end})
  table.insert(controllers,controller)
  return controller
 end
 local function player(id)
  local p={UserId=id,DisplayName="Player"..id,Parent=players,attributes={},Character=nil,
   CharacterAdded=signal(),CharacterRemoving=signal(),CharacterAppearanceLoaded=signal()}
  function p:SetAttribute(key,value) self.attributes[key]=value end
  function p:GetAttribute(key) return self.attributes[key] end
  players[id]=p
  return p
 end
 local a,b,c,d,e=player(1),player(2),player(3),player(4),player(5)
 local first,second,practice=court(1),court(2),court(3)
 local function join(controller,id,p,mode,variant)
  owners[p]=id; controller:add(p)
  assert(controller:enter(p,mode,variant or "Classic","Rooftop","None"))
 end
 local ok,err=pcall(function()
  join(first,1,a,"1V1"); join(first,1,b,"1V1")
  join(second,2,c,"1V1"); join(second,2,d,"1V1")
  join(practice,3,e,"Practice")
  assert(#rewardRuns==3 and rewardRuns[1]~=rewardRuns[2],"Every court owns an independent XP run")
  assert(rewardRuns[1].users[a] and not rewardRuns[1].users[c] and rewardRuns[2].users[c],"XP rosters stay inside their court")
  assert(rewardRuns[3].mode=="Practice","Practice uses its own reward mode")
  heartbeat:Fire(0.1)
  local firstState,secondState=delivered[a].State.data,delivered[c].State.data
  assert(firstState.homeName~=secondState.homeName and firstState.score~=secondState.score,"Rosters and score tables are isolated")
  assert(firstState.p.Y+4096==secondState.p.Y,"Balls occupy separate courts")
  local revision=delivered[e].State.data.practice.revision
  network.Practice.OnServerEvent:Fire(a,"Paused",true,revision)
  network.Practice.OnServerEvent:Fire(e,"Paused",true,revision)
  now+=12; heartbeat:Fire(0.1)
  assert(delivered[e].State.data.practicePaused,"Practice owner can pause")
  assert(not delivered[a].State.data.practicePaused and not delivered[c].State.data.practicePaused,"Practice pause cannot freeze either match")
  assert(delivered[a].State.data.serveReady and delivered[c].State.data.serveReady,"Both multiplayer matches advance concurrently")
  local otherState=delivered[c].State
  local otherRewardBegins=rewardRuns[2].begins
  local firstRewardBegins=rewardRuns[1].begins
  first:remove(a); owners[a]=nil
  assert(rewardRuns[1].begins>firstRewardBegins and rewardRuns[2].begins==otherRewardBegins,"Departure invalidates only its court reward run")
  assert(a.CharacterAdded:count()==0 and a.CharacterRemoving:count()==0,"Departure disconnects avatar handlers")
  assert(delivered[c].State==otherState,"A departure sends nothing to an unrelated court")
  first:remove(b); owners[b]=nil
  assert(first:empty(),"Last departure releases court capacity")
  owners[a]=1; first:add(a); first:add(a)
  assert(a.CharacterAdded:count()==1,"Repeated joins are idempotent")
  assert(first:enter(a,"Practice","Classic","Rooftop","None"))
  heartbeat:Fire(0.1)
  assert(delivered[a].State.data.score[1]==0 and delivered[a].State.data.score[2]==0,"Reused court starts with a fresh score")
  local f,g,h,i=player(6),player(7),player(8),player(9)
  local arcadeA,arcadeB=court(4),court(5)
  join(arcadeA,4,f,"1V1","Arcade"); join(arcadeA,4,g,"1V1","Arcade")
  join(arcadeB,5,h,"1V1","Arcade"); join(arcadeB,5,i,"1V1","Arcade")
  now+=12; heartbeat:Fire(0.1)
  local firstOffer=delivered[f].ArcadeLoadout.data
  local secondOffer=delivered[h].ArcadeLoadout.data
  assert(firstOffer.kind=="open" and secondOffer.kind=="open","Each Arcade court opens its own picker")
  local deck={"speedCleats","bigPaddle","heatseeker"}
  network.ArcadeLoadout.OnServerEvent:Fire(f,firstOffer.id,deck)
  network.ArcadeLoadout.OnServerEvent:Fire(g,firstOffer.id,deck)
  heartbeat:Fire(0.1)
  assert(delivered[f].ArcadeLoadout.data.kind=="close","Ready court finishes loadout selection")
  assert(delivered[h].ArcadeLoadout.data.kind=="open" and h:GetAttribute("PowerupDraftOpen"),"One court's picks cannot complete another court")
  assert(delivered[f].State.data.p.Y+4096==delivered[h].State.data.p.Y,"Arcade balls retain their court height")
  local before=delivered[c].State
  first:destroy(); first:destroy()
  now+=1; heartbeat:Fire(0.1)
  assert(delivered[c].State~=before and a.CharacterAdded:count()==0,"Destroy is idempotent and other sessions continue")
 end)
 for _,controller in ipairs(controllers) do controller:destroy() end
 for _,root in ipairs(roots) do root:Destroy() end
 assert(heartbeat:count()==0,"Shutdown disconnects every heartbeat")
 for _,event in pairs(network) do
  if type(event)=="table" then assert(event.OnServerEvent:count()==0,"Shutdown disconnects every remote") end
 end
 assert(ok,err)
 return "Concurrent matches, independent scores/balls, practice isolation, departure, rejoin, duplicate joins, and shutdown cleanup passed"
end
