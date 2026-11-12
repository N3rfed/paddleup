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
 local a,b,c=player(1),player(2),player(3)
 local first=court(1)
 owners[a]=1; owners[b]=1; owners[c]=1
 first:add(a); first:add(b); first:add(c)
 local ok,err=pcall(function()
  assert(first:enter(a,"1V1","Classic","Rooftop","None"))
  assert(first:enter(b,"1V1","Classic","Rooftop","None"))
  assert(first:enter(c,"Spectate"))
  assert(c:GetAttribute("CourtSide")==0,"Spectators start outside active roster")
  assert(not first:replace(c,"1V1","Classic","Rooftop","None",{side=1,slot=1}),"Approval path requires paused court")
  now+=5; heartbeat:Fire(0.1)
  local score=delivered[b].State.data.score; score[1]=7; score[2]=4
  local seat={side=a:GetAttribute("CourtSide"),slot=a:GetAttribute("CourtSlot")}
  first:pauseReplacement(true); first:remove(a); owners[a]=nil
  assert(b:GetAttribute("CourtSide")==-1,"Vacancy does not move the opponent onto the departing team")
  now+=12; heartbeat:Fire(12)
  assert(delivered[b].State.data.practicePaused and not delivered[b].State.data.canServe,"Authoritative match pause blocks serving")
  assert(not first:replace(c,"1V1","Classic","Rooftop","None",{side=-1,slot=1}),"Occupied seats reject replacement")
  assert(first:replace(c,"1V1","Classic","Rooftop","None",seat),"Approved spectator is admitted to vacancy")
  assert(c:GetAttribute("CourtSide")==seat.side and c:GetAttribute("CourtSlot")==seat.slot,"Replacement restores exact team and slot")
  assert(c:GetAttribute("SessionMode")=="1V1","Replacement exits spectator status")
  first:pauseReplacement(false)
  assert(not b:GetAttribute("MatchPaused") and not c:GetAttribute("MatchPaused"),"Resume clears participant pause state")
  now+=4; heartbeat:Fire(0.1)
  assert(delivered[b].State.data.score[1]==7 and delivered[b].State.data.score[2]==4,"Substitution preserves scoreboard")
  assert(not delivered[b].State.data.practicePaused,"Simulation resumes")
 end)
 for _,controller in ipairs(controllers) do controller:destroy() end
 for _,root in ipairs(roots) do root:Destroy() end
 assert(heartbeat:count()==0,"Shutdown disconnects every heartbeat")
 for _,event in pairs(network) do
  if type(event)=="table" then assert(event.OnServerEvent:count()==0,"Shutdown disconnects every remote") end
 end
 assert(ok,err)
 return "Paused serving, spectator approval, exact team/slot replacement, preserved scores, and resume passed"
end
