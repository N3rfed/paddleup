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
 mocked.PracticePartner={new=function(root) return {model=Instance.new("Model",root),pose=function() end,show=function() end} end}
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
  new=function() return {active="Rooftop",prepare=function(_,name) assert(name=="Rooftop" or name=="Moon") end,set=function(self,name) self.active=name end,destroy=function() end} end}
 mocked.CourtPickups={new=function() return {slots={},bursts={},reset=function() end,update=function() end} end}
 local scriptMock={Parent={PracticePartner="PracticePartner",WaitForChild=function(_,name) return name end}}
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
 local ok,err=pcall(function()
  for index,choice in ipairs({
   {map="Rooftop",variant="Classic",modifier="None"},{map="Rooftop",variant="Chaos",modifier="LowGravity"},
   {map="Moon",variant="Classic",modifier="None"},{map="Moon",variant="Chaos",modifier="LowGravity"},
  }) do
   local map,variant,modifier=choice.map,choice.variant,choice.modifier
   local first=court(index); local a,b=player(index*2),player(index*2+1)
   owners[a]=index; owners[b]=index
   first:prepareMap(map); first:add(a); first:add(b)
   assert(first:enter(a,"1V1",variant,map,modifier,true))
   assert(first:enter(b,"1V1",variant,map,modifier,true))
   heartbeat:Fire(0.1)
   local intro=delivered[a].State.data.matchIntro
   local peerIntro=delivered[b].State.data.matchIntro
   assert(intro and peerIntro and intro.id==peerIntro.id and intro.endsAt==now+8,"The whole party gets the original eight-second match intro")
   assert(not intro.loading and not intro.overview,"Elevator entry has no travel animation or scenery acknowledgment barrier")
   assert(intro.home[1].userId==a.UserId and intro.away[1].userId==b.UserId,"The original intro uses the selected match roster")
   assert(a:GetAttribute("CourtEnvironment")==map and b:GetAttribute("CourtEnvironment")==map,"Every participant enters the same selected map")
   assert(a:GetAttribute("MatchVariant")==variant and b:GetAttribute("MatchVariant")==variant,"Map does not change ruleset")
   now+=7.9; heartbeat:Fire(0.1)
   assert(delivered[a].State.data.matchIntro and not delivered[a].State.data.serveReady and not a:GetAttribute("PowerupDraftOpen"),"Gameplay stays gated until the intro ends")
   now+=0.2; heartbeat:Fire(0.1)
   assert(not delivered[a].State.data.matchIntro,"The original intro ends before gameplay begins")
   if variant=="Chaos" then
    assert(a:GetAttribute("PowerupDraftOpen") and delivered[a].Powerup.data.kind=="offer","Existing Chaos draft begins on the selected court")
   else assert(delivered[a].State.data.serveReady,"Classic prepares its serve on the selected court") end
  end
  local first=court(5); local a,b=player(20),player(21); owners[a]=5; owners[b]=5
  assert(not pcall(function() first:prepareMap("Unknown") end),"Invalid maps fail before admission")
  first:add(a); first:add(b)
  assert(first:enter(a,"1V1","Classic","Moon","None"))
  assert(first:enter(b,"1V1","Classic","Moon","None"))
  now+=0.1; heartbeat:Fire(0.1)
  local menuIntro=delivered[a].State.data.matchIntro
  assert(menuIntro and menuIntro.loading,"Play menu retains the Moon loading intro")
 end)
 for _,controller in ipairs(controllers) do controller:destroy() end
 for _,root in ipairs(roots) do root:Destroy() end
 assert(heartbeat:count()==0,"Shutdown disconnects every heartbeat")
 for _,event in pairs(network) do
  if type(event)=="table" then assert(event.OnServerEvent:count()==0,"Shutdown disconnects every remote") end
 end
 assert(ok,err)
 return "Both selected maps, Classic and Chaos, the original match intro, invalid map rejection, and the Play-menu Moon intro passed"
end
