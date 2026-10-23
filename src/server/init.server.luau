-- One public place. Roblox allocates public server instances; this script owns only this instance.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
-- Set before the first yield so duplicate bootstrap scripts cannot connect twice.
if game:GetAttribute("PaddleUpServerInitialized") then return end
game:SetAttribute("PaddleUpServerInitialized",true)
game:GetService("StarterPlayer").EnableMouseLockOption=false
local root=require(script:WaitForChild("World")).build()
require(script:WaitForChild("Lobby")).build()
require(script:WaitForChild("DayNightCycle")).start()
local template=root:Clone(); template.Parent=nil
local folder=ReplicatedStorage:FindFirstChild("PaddleUp") or Instance.new("Folder")
folder.Name="PaddleUp"; folder.Parent=ReplicatedStorage
for _,name in ipairs({"Input","State","Feedback","Session","Queue","IntroReady","Powerup","Practice"}) do
 if not folder:FindFirstChild(name) then
  local event=Instance.new("RemoteEvent"); event.Name=name; event.Parent=folder
 end
end
local shared=ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder")
shared.Name="Shared"; shared.Parent=ReplicatedStorage
for _,name in ipairs({"MatchRules","MatchSetup"}) do
 if not shared:FindFirstChild(name) then script:WaitForChild(name):Clone().Parent=shared end
end
local CourtSession=require(script:WaitForChild("CourtSession"))
local queueRemote,session=folder.Queue,folder.Session
local closing=false
local dispatching=false
local owners,runtimes,roots={},{},{}
local lastSessionRequest={}
-- A slot per allowed visitor supports the worst case: everyone practicing alone.
-- Start with MaxPlayers=8 and measure before raising it (each slot contains scenery).
local capacity=Players.MaxPlayers
local function owner(player) return owners[player] end
local function runtime(id)
 if runtimes[id] then return runtimes[id] end
 local court=root
 if id~=0 then
  court=template:Clone(); court.Name="PaddleUpCourt"..id
  local translation=CFrame.new(0,id*4096,0)
  for _,part in ipairs(court:GetDescendants()) do
   if part:IsA("BasePart") then part.CFrame=translation*part.CFrame end
  end
  court.Parent=workspace
 end
 roots[id]=court
 local cleanup={}
 local ok,result=pcall(CourtSession.new,{id=id,height=id*4096,root=court,network=folder,owner=owner,
  track=function(callback) table.insert(cleanup,callback) end})
 if not ok then
  for index=#cleanup,1,-1 do pcall(cleanup[index]) end
  if id~=0 then court:Destroy(); roots[id]=nil end
  error(result)
 end
 runtimes[id]=result
 return runtimes[id]
end
runtime(0)
local queue=require(script:WaitForChild("MatchQueue")).new(function(player,data)
 if not closing and player.Parent==Players then queueRemote:FireClient(player,data) end
end)
local function move(player,id)
 if owners[player]~=nil then runtimes[owners[player]]:remove(player) end
 owners[player]=id
 runtime(id):add(player)
end
local function lobby(player,message)
 if player.Parent~=Players then return end
 move(player,0)
 runtimes[0]:enter(player,"Lobby")
 if message then session:FireClient(player,false,message) end
end
local function freeSlot()
 for id=1,capacity do
  if not runtimes[id] or runtimes[id]:empty() then return id end
 end
end
local function dispatchQueue()
 if closing then return end
 local id=freeSlot()
 local group=queue:update(id~=nil)
 if not group then return end
 -- Prepare the destination before moving any players. Failure leaves the group in the lobby.
 local ok,err=pcall(runtime,id)
 if not ok then
  warn("Court initialization failed: "..tostring(err))
  if roots[id] then roots[id]:Destroy(); roots[id]=nil end
  for _,player in ipairs(group.players) do
   queueRemote:FireClient(player,{stage="Cancelled"})
   lobby(player,"The court could not start. Please queue again.")
  end
  return
 end
 local success,reason=pcall(function()
  for _,player in ipairs(group.players) do
   assert(player.Parent==Players and owners[player]==0,"A queued player left")
  end
  for _,player in ipairs(group.players) do
   queueRemote:FireClient(player,{stage="Cancelled"})
   move(player,id)
   assert(runtimes[id]:enter(player,group.format,group.mode,group.map,group.modifier),"Admission rejected")
  end
 end)
 if not success then
  warn("Match admission failed: "..tostring(reason))
  for _,player in ipairs(group.players) do lobby(player,"The group changed. Please queue again.") end
 end
end
local function updateQueue()
 if closing or dispatching then return end
 dispatching=true
 local ok,err=xpcall(dispatchQueue,debug.traceback)
 dispatching=false
 if not ok then warn("Queue dispatch failed: "..tostring(err)) end
end
local function addPlayer(player)
 if closing or owners[player]~=nil or player.Parent~=Players then return end
 move(player,0)
end
local connections={}
local function connect(signal,callback) table.insert(connections,signal:Connect(callback)) end
connect(Players.PlayerAdded,addPlayer)
connect(Players.PlayerRemoving,function(player)
 queue:remove(player)
 lastSessionRequest[player]=nil
 local id=owners[player]
 if id~=nil then
  local wasPlaying=player:GetAttribute("CourtSide")~=0
  runtimes[id]:remove(player); owners[player]=nil
  if id~=0 and wasPlaying then
   local peers={}
   for peer,courtId in pairs(owners) do
    if courtId==id and peer:GetAttribute("CourtSide")~=0 then table.insert(peers,peer) end
   end
   for _,peer in ipairs(peers) do lobby(peer,"A player left the match. Please queue again.") end
  end
 end
end)
connect(session.OnServerEvent,function(player,mode)
 if closing or owners[player]==nil then return end
 if os.clock()-(lastSessionRequest[player] or -math.huge)<0.5 then return end
 lastSessionRequest[player]=os.clock()
 if mode~="Lobby" and mode~="Spectate" then
  session:FireClient(player,false,"Choose a mode and player count to join the queue."); return
 end
 queue:remove(player)
 local previous=owners[player]
 local peers={}
 if previous~=0 and player:GetAttribute("CourtSide")~=0 then
  for peer,courtId in pairs(owners) do
   if peer~=player and courtId==previous and peer:GetAttribute("CourtSide")~=0 then table.insert(peers,peer) end
  end
 end
 for _,peer in ipairs(peers) do lobby(peer,"A player left the match. Please queue again.") end
 local id=0
 if mode=="Spectate" then
  for candidate=1,capacity do
   if runtimes[candidate] and not runtimes[candidate]:empty() then id=candidate; break end
  end
 end
 move(player,id)
 runtimes[id]:enter(player,mode)
end)
connect(queueRemote.OnServerEvent,function(player,action,a,b)
 if closing or owners[player]==nil then return end
 if action=="Cancel" then queue:remove(player)
 elseif action=="Join" then
  if owners[player]~=0 or player:GetAttribute("SessionMode")~="Lobby" or not queue:join(player,a,b) then
   queueRemote:FireClient(player,{stage="Error",message="Return to the lobby and choose a valid mode and player count."})
  end
 elseif action=="Vote" then
  if not queue:configure(player,a,b) then
   queueRemote:FireClient(player,{stage="Error",message="Voting has closed, or this choice is unavailable."})
  end
 end
 updateQueue()
end)
connect(RunService.Heartbeat,updateQueue)
for _,player in ipairs(Players:GetPlayers()) do addPlayer(player) end
game:BindToClose(function()
 if closing then return end
 closing=true
 for _,connection in ipairs(connections) do connection:Disconnect() end
 queue:destroy()
 for _,controller in pairs(runtimes) do controller:destroy() end
 table.clear(owners)
 template:Destroy()
end)
