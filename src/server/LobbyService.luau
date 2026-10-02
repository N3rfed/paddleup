local Players=game:GetService("Players")
local Queue=require(script.Parent:WaitForChild("LobbyQueue"))
local Service={}
function Service.new(network,hooks)
 local self={model=Queue.new(),hooks=hooks,lastRequest={},lastInvite={},lastRefresh={}}
 local remote=network:FindFirstChild("Lobby") or Instance.new("RemoteEvent")
 remote.Name="Lobby"; remote.Parent=network
 self.remote=remote
 local function describe(id)
  if id==0 then return {id=0,name="Practice Bot",username=""} end
  local player=Players:GetPlayerByUserId(id)
  return {id=id,name=player and player.DisplayName or "Player",username=player and player.Name or ""}
 end
 function self:broadcast(message,recipient)
  local model=self.model
  local people={}
  for _,p in ipairs(Players:GetPlayers()) do
   local party=model:party(p.UserId)
   if party then
    local person=describe(p.UserId)
    person.available=not model:playing(p.UserId) and not model:queued(p.UserId) and #party.members==1
    table.insert(people,person)
   end
  end
  table.sort(people,function(a,b) return a.username<b.username end)
  local counts={["1v1"]=0,["2v2"]=0,Practice=0}
  for _,entry in ipairs(model.queue) do counts[entry.mode]+=#entry.party.members end
  local match
  if model.active then
   match={mode=model.active.mode,difficulty=model.active.difficulty,home={},away={},score=hooks.score()}
   for _,id in ipairs(model.active.home) do table.insert(match.home,describe(id)) end
   for _,id in ipairs(model.active.away) do table.insert(match.away,describe(id)) end
  end
  for _,p in ipairs(Players:GetPlayers()) do
   local id=p.UserId
   local party=model:party(id)
   if party then
    local members={}
    for _,member in ipairs(party.members) do table.insert(members,describe(member)) end
    local entry=model:queued(id)
    local invite=model.invites[id]
    if invite and invite.expires<model.clock() then model.invites[id]=nil; invite=nil end
    local status=model:playing(id) and "Playing" or model.players[id].watching and "Spectating" or "Lobby"
    p:SetAttribute("LobbyStatus",status)
    remote:FireClient(p,{status=status,party=members,leader=party.leader,queue=entry and entry.mode,
     difficulty=entry and entry.difficulty,counts=counts,players=people,match=match,invite=invite and describe(invite.leader),
     message=(not recipient or recipient==id) and message or nil})
   end
  end
 end
 function self:pump()
  local match=self.model:takeMatch()
  if match then hooks.start(match) end
  self:broadcast()
 end
 function self:add(p)
  self.model:add(p.UserId); self:broadcast()
 end
 function self:finish(message)
  local match=self.model:finish()
  if match then hooks.stop(match) end
  self:broadcast(message)
  -- Give the result and lobby transition a moment before admitting the next queue.
  task.delay(2,function() self:pump() end)
 end
 function self:remove(p)
  if self.model:playing(p.UserId) then self:finish(p.DisplayName.." left. Match ended.") end
  self.model:remove(p.UserId); self.lastRequest[p.UserId]=nil; self.lastInvite[p.UserId]=nil
  self.lastRefresh[p.UserId]=nil
  self:pump()
 end
 remote.OnServerEvent:Connect(function(p,action,value)
  local id=p.UserId
  if type(action)~="string" or not self.model.players[id] then return end
  local now=os.clock()
  -- Initial UI synchronization must not swallow the player's first queue click.
  if action=="Refresh" then
   if now-(self.lastRefresh[id] or -100)>=0.15 then
    self.lastRefresh[id]=now; self:broadcast()
   end
   return
  end
  if now-(self.lastRequest[id] or -100)<0.15 then return end
  self.lastRequest[id]=now
  local model=self.model
  local ok,message=true,nil
  if action=="Queue" then ok,message=model:enqueue(id,value)
  elseif action=="Practice" then ok,message=model:enqueue(id,"Practice",value)
  elseif action=="CancelQueue" then model:cancel(id)
  elseif action=="Invite" then
   if type(value)~="number" or value~=value then return end
   if now-(self.lastInvite[id] or -100)<2 then ok,message=false,"Wait a moment before inviting again."
   else self.lastInvite[id]=now; ok,message=model:invite(id,value); if ok then message="Invitation sent." end end
  elseif action=="Accept" then ok,message=model:accept(id)
  elseif action=="Decline" then model.invites[id]=nil
  elseif action=="LeaveParty" then ok,message=model:leaveParty(id)
  elseif action=="Spectate" then ok,message=model:watch(id,true)
  elseif action=="Back" then ok,message=model:watch(id,false)
  elseif action=="LeaveMatch" then
   if model:playing(id) then self:finish(p.DisplayName.." left the match."); return end
  else return end
  if ok then self:pump() end
  self:broadcast(message,id)
 end)
 return self
end
return Service
