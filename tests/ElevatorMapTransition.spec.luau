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
 local loadFailures=0
 local function court(id)
  local root=Instance.new("Model"); table.insert(roots,root)
  local controller=Court.new({id=id,height=id*4096,root=root,network=network,progression=progression,onOverviewFailure=function() loadFailures+=1 end,owner=function(p) return owners[p] end})
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
 local ok,err=pcall(function()
  for index,choice in ipairs({
   {map="Rooftop",variant="Classic",modifier="None"},{map="Rooftop",variant="Chaos",modifier="LowGravity"},
   {map="Moon",variant="Classic",modifier="None"},{map="Moon",variant="Chaos",modifier="LowGravity"},
  }) do
   local map,variant,modifier=choice.map,choice.variant,choice.modifier
   local first=court(index); local a,b=player(index*2),player(index*2+1)
   owners[a]=index; owners[b]=index
   first:prepareOverview(4); first:add(a); first:add(b)
   assert(first:enter(a,"1V1",variant,map,modifier))
   assert(first:enter(b,"1V1",variant,map,modifier))
   now+=0.1; heartbeat:Fire(0.1)
   local data=delivered[a].State.data.matchIntro
   assert(data and data.overview and data.loading and data.environment==map,"Selected environment owns the overview")
   assert(a:GetAttribute("CourtEnvironment")==map and b:GetAttribute("CourtEnvironment")==map,"Every participant enters the same selected map")
   assert(a:GetAttribute("MatchVariant")==variant and b:GetAttribute("MatchVariant")==variant,"Map does not change ruleset")
   network.IntroReady.OnServerEvent:Fire(a,data.id-1)
   network.IntroReady.OnServerEvent:Fire(a,data.id)
   now+=1; heartbeat:Fire(0.1)
   assert(delivered[b].State.data.matchIntro.loading,"One acknowledgement cannot start the match")
   network.IntroReady.OnServerEvent:Fire(b,data.id)
   heartbeat:Fire(0.1)
   local active=delivered[a].State.data.matchIntro
   assert(active.overview and not active.loading and active.endsAt==now+4,"All clients share the full four-second overview")
   now+=3.9; heartbeat:Fire(0.1)
   assert(delivered[a].State.data.matchIntro and not delivered[a].State.data.serveReady,"Gameplay stays blocked throughout overview")
   now+=0.2; heartbeat:Fire(0.1)
   assert(not delivered[a].State.data.matchIntro,"Overview releases the match at the deadline")
   if variant=="Chaos" then
    assert(a:GetAttribute("PowerupDraftOpen") and delivered[a].Powerup.data.kind=="offer","Existing Chaos draft begins after the overview")
   else assert(delivered[a].State.data.serveReady,"Classic prepares its serve after the overview") end
  end
  local first=court(5); local a,b=player(20),player(21); owners[a]=5; owners[b]=5
  first:prepareOverview(4); first:add(a); first:add(b)
  first:enter(a,"1V1","Classic","Rooftop","None"); first:enter(b,"1V1","Classic","Rooftop","None")
  now+=31; heartbeat:Fire(0.1)
  assert(loadFailures==1,"A failed load invokes whole-party recovery instead of leaving an infinite intro")
 end)
 for _,controller in ipairs(controllers) do controller:destroy() end
 for _,root in ipairs(roots) do root:Destroy() end
 assert(heartbeat:count()==0,"Shutdown disconnects every heartbeat")
 for _,event in pairs(network) do
  if type(event)=="table" then assert(event.OnServerEvent:count()==0,"Shutdown disconnects every remote") end
 end
 assert(ok,err)
 return "Both selected maps, independent Chaos rules, full-party loading acknowledgements, synchronized four-second overview, timeout callback, and gameplay handoff passed"
end
