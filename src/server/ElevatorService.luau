-- Coordinates physical parties and consent-based vacancy offers. The update guard protects yielding court admission.
local Players=game:GetService("Players")
local Config=require(script.Parent.ElevatorConfig)
local Party=require(script.Parent.ElevatorParty)
local Service={}
Service.__index=Service
function Service.new(context)
 local self=setmetatable({ctx=context,parties={},members={},offers={},attempts={},matches={},serial=0,blocked={},closed=false},Service)
 self.geometry=require(script.Parent.ElevatorGeometry).build(context.lobby,Config)
 for _,entry in ipairs(Config.Elevators) do
  assert((entry.format=="1V1" and entry.capacity==2) or (entry.format=="2V2" and entry.capacity==4),"Invalid elevator capacity")
  assert(self.geometry[entry.id],"Missing configured elevator "..entry.id)
  local settings=table.clone(entry); settings.voteSeconds=Config.VoteSeconds; settings.maps=Config.MapIds; settings.mapVoteSeconds=Config.MapVoteSeconds; settings.revealSeconds=Config.RevealSeconds
  self.parties[entry.id]=Party.new(settings,context.clock)
  self:publish(self.parties[entry.id])
 end
 self.connection=context.remote.OnServerEvent:Connect(function(player,action,value)
  if self.closed or type(action)~="string" then return end
  if action=="Response" and type(value)=="table" then self:respond(player,value.id,value.accept==true); return end
  local party=self.members[player]
  if not party then return end
  if action=="Leave" then self:leave(player,true)
  elseif action=="Ready" and type(value)=="table" and value.revision==party.revision then
   if party:readyUp(player) then
    if party.stage=="Voting" then self:cancelTarget(party) end
    self:publish(party)
   end
  elseif action=="Vote" and type(value)=="table" and value.revision==party.revision and type(value.mode)=="string" then
   if party:vote(player,value.mode) then self:publish(party) end
  elseif action=="MapVote" and type(value)=="table" and value.revision==party.revision and type(value.map)=="string" then
   if party:voteMap(player,value.map) then self:publish(party) end
  end
 end)
 return self
end
function Service:send(player,data)
 if player.Parent==Players then self.ctx.remote:FireClient(player,data) end
end
function Service:publish(party)
 local data=party:snapshot(); data.kind="Party"
 self.geometry[party.config.id].label.Text=party.config.format:gsub("V","v").."  "..data.count.."/"..data.capacity.."  "..data.stage
 for _,p in ipairs(party.players) do self:send(p,data) end
end
function Service:cancelOffer(player)
 local offer=self.offers[player]; if not offer then return end
 self.offers[player]=nil
 self.ctx.queue:release(player,offer.id)
 self:send(player,{kind="InvitationClosed",id=offer.id})
end
function Service:cancelTarget(target)
 local list={}
 for p,offer in pairs(self.offers) do if offer.target==target then table.insert(list,p) end end
 for _,p in ipairs(list) do self:cancelOffer(p) end
end
function Service:leave(player,exit)
 self:cancelOffer(player)
 local party=self.members[player]; if not party then return end
 self:cancelTarget(party)
 self.members[player]=nil; party:leave(player)
 player:SetAttribute("ElevatorId",nil)
 self.blocked[player]=self.ctx.clock()+2
 self:send(player,{kind="Closed"})
 if exit and player.Character then player.Character:PivotTo(self.geometry[party.config.id].exit) end
 self:publish(party)
end
function Service:join(player,party,preference)
 if self.members[player] or self.ctx.owner(player)~=0 or player:GetAttribute("SessionMode")~="Lobby"
  or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
 local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return false end
 if not party:join(player,preference) then return false end
 self:cancelTarget(party)
 self.ctx.queue:remove(player); self:cancelOffer(player)
 self.members[player]=party; player:SetAttribute("ElevatorId",party.config.id)
 self:publish(party); return true
end
function Service:offer(target,format,mode,spectators)
 for _,offer in pairs(self.offers) do if offer.target==target then return true end end
 target.attempted=target.attempted or {}
 local candidates={}
 if not spectators then
  for _,group in ipairs(self.ctx.queue.groups) do
   if group~=self.ctx.queue.active and group.format==format and (group.mode=="Classic" or group.mode=="Chaos" or (target.courtId and group.mode==mode)) then
    if (not mode or group.mode==mode) and (not target.allowed or target:allowed(group.mode)[group.mode]) then
     for _,p in ipairs(group.players) do table.insert(candidates,{player=p,preference=group.mode}) end
    end
   end
  end
 else
  for _,p in ipairs(Players:GetPlayers()) do
   if self.ctx.owner(p)==target.courtId and p:GetAttribute("SessionMode")=="Spectate" then
    table.insert(candidates,{player=p,preference=mode})
   end
  end
 end
 table.sort(candidates,function(a,b) return a.player.UserId<b.player.UserId end)
 for _,candidate in ipairs(candidates) do
  local p=candidate.player
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if p.Parent==Players and h and h.Health>0 and not target.attempted[p] and not self.offers[p] and not self.members[p]
   and (spectators or (self.ctx.owner(p)==0 and p:GetAttribute("SessionMode")=="Lobby")) then
   self.serial+=1
   local id=self.serial
   if not spectators and not self.ctx.queue:reserve(p,id) then continue end
   target.attempted[p]=true
   self.offers[p]={id=id,target=target,preference=candidate.preference,spectator=spectators,endsAt=self.ctx.clock()+Config.InvitationSeconds}
   self:send(p,{kind="Invitation",id=id,format=format,mode=mode or candidate.preference,
    replacement=target.courtId~=nil,endsAt=self.offers[p].endsAt})
   return true
  end
 end
 return false
end
function Service:respond(player,id,accept)
 local offer=self.offers[player]
 if not offer or offer.id~=id then return end
 local target=offer.target
 local valid=self.ctx.clock()<offer.endsAt and player.Parent==Players
 if not offer.spectator then valid=valid and self.ctx.queue:isReserved(player,id) end
 self:cancelOffer(player)
 if not accept or not valid then return end
 if target.courtId then
  local match=self.matches[target.courtId]
  if match~=target or not match.vacancies[1] or match.terminatesAt then return end
  if offer.spectator then
   if self.ctx.owner(player)~=target.courtId or player:GetAttribute("SessionMode")~="Spectate" then return end
  elseif self.ctx.owner(player)~=0 or not self.ctx.queue.members[player] then return end
  if self.ctx.replace(player,target,match.vacancies[1]) then
   self.ctx.queue:remove(player)
   match.approved[player]=true
   match.active[player]=table.remove(match.vacancies,1)
   match.attempted={}; match.phase="Queue"
   if #match.vacancies==0 then self.ctx.pause(target.courtId,false) end
  end
 else
  if target.stage~="Waiting" or #target.players>=target.config.capacity or not self.ctx.queue.members[player] then return end
  if self:join(player,target,offer.preference) then
   player.Character:PivotTo(self.geometry[target.config.id].entry)
  end
 end
end
function Service:track(id,group)
 local record={courtId=id,format=group.format,mode=group.mode,map=group.map,modifier=group.modifier,
  original={},approved={},active={},vacancies={},phase="Queue",attempted={}}
 for _,p in ipairs(group.players) do
  record.original[p.UserId]=true; record.active[p]={side=p:GetAttribute("CourtSide"),slot=p:GetAttribute("CourtSlot")}
 end
 self.matches[id]=record
end
function Service:departed(player,id)
 local match=self.matches[id]
 if not match then return end
 self:cancelOffer(player)
 local seat=match.active[player]
 if not seat then return end
 match.active[player]=nil
 table.insert(match.vacancies,seat)
 match.phase="Queue"; match.attempted={}
 self.ctx.pause(id,true)
end
function Service:update()
 if self.closed or self.updating then return end
 self.updating=true
 local ok,err=xpcall(function() self:updateParties() end,debug.traceback)
 self.updating=false
 if not ok then error(err) end
end
function Service:updateParties()
 if self.closed then return end
 local now=self.ctx.clock()
 local cancel={}
 for p,offer in pairs(self.offers) do
  if now>=offer.endsAt or p.Parent~=Players or (not offer.spectator and not self.ctx.queue:isReserved(p,offer.id)) then table.insert(cancel,p) end
 end
 for _,p in ipairs(cancel) do self:cancelOffer(p) end
 -- Remove in a separate pass so roster mutation cannot skip a member.
 local leave={}
 for p,party in pairs(self.members) do
  local c=p.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid")
  if p.Parent~=Players or self.ctx.owner(p)~=0 or p:GetAttribute("SessionMode")~="Lobby" or not root or not h or h.Health<=0
   or not self.geometry[party.config.id]:contains(root.Position) then table.insert(leave,p) end
 end
 for _,p in ipairs(leave) do self:leave(p,false) end
 for id,party in pairs(self.parties) do
  local geometry=self.geometry[id]
  local near=false
  for _,p in ipairs(Players:GetPlayers()) do
   local c=p.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid")
   if self.ctx.owner(p)==0 and p:GetAttribute("SessionMode")=="Lobby" and root and h and h.Health>0 then
    if geometry:contains(root.Position,true) then near=true end
    if geometry:contains(root.Position) and not self.members[p] and now>=(self.blocked[p] or 0) then
     -- Physical entry consumes the existing queue preference, never silently discards it.
     local queued=self.ctx.queue.members[p]
     local preference=queued and queued.mode or "Any"
     if not self:join(p,party,preference) then c:PivotTo(geometry.exit); self.blocked[p]=now+2 end
    end
   end
  end
  if near then geometry.lastNear=now end
  geometry:setOpen(party.stage~="Departing" and (near or #party.players>0 or now-geometry.lastNear<Config.DoorHoldSeconds))
  if party:update() then
   if party.stage=="Departing" then geometry:setOpen(false) end
   self:cancelTarget(party)
   self:publish(party)
  end
  if party.stage=="Waiting" and #party.players>0 and #party.players<party.config.capacity then self:offer(party,party.config.format) end
  if party.stage=="Departing" and now>=party.endsAt then
   local revision=party.revision
   local group={players=table.clone(party.players),format=party.config.format,mode=party.mode,map=party.map,overviewSeconds=Config.OverviewSeconds,
    modifier=party.mode=="Chaos" and "LowGravity" or "None",
    valid=function()
     if self.closed or party.revision~=revision or party.stage~="Departing" then return false end
     for _,p in ipairs(party.players) do if self.members[p]~=party then return false end end
     return #party.players==party.config.capacity
    end}
   local ok=self.ctx.start(group)
   if ok then
    for _,p in ipairs(group.players) do self.members[p]=nil; p:SetAttribute("ElevatorId",nil); self:send(p,{kind="Closed",enteringMap=true}) end
    party.players={}; party.preferences={}; party.attempted={}; party:reset(); self:publish(party)
   else
    party:reset(); self:publish(party)
    for _,p in ipairs(party.players) do self:send(p,{kind="Notice",message="Court unavailable. Your party can ready up again."}) end
   end
  end
 end
 for id,match in pairs(self.matches) do
  if #match.vacancies==0 then continue end
  if match.terminatesAt then
   if now>=match.terminatesAt then
    self:cancelTarget(match); self.matches[id]=nil; self.ctx.terminate(id)
   end
  else
   local offered=self:offer(match,match.format,match.mode,match.phase=="Spectators")
   if not offered and match.phase=="Queue" then
    match.phase="Spectators"; offered=self:offer(match,match.format,match.mode,true)
   end
   if not offered then
    match.terminatesAt=now+Config.TerminationSeconds
    for _,p in ipairs(Players:GetPlayers()) do
     if self.ctx.owner(p)==id then self:send(p,{kind="Terminated",endsAt=match.terminatesAt,
      message="A player left and no replacement was available. Returning to the lobby."}) end
    end
   end
  end
 end
end
function Service:remove(player)
 self:leave(player,false); self.blocked[player]=nil
 for _,party in pairs(self.parties) do if party.attempted then party.attempted[player]=nil end end
 for _,match in pairs(self.matches) do match.attempted[player]=nil; match.approved[player]=nil end
end
function Service:destroy()
 self.closed=true; self.connection:Disconnect()
 local list={}; for p in pairs(self.members) do table.insert(list,p) end
 for _,p in ipairs(list) do self:leave(p,false) end
 list={}; for p in pairs(self.offers) do table.insert(list,p) end
 for _,p in ipairs(list) do self:cancelOffer(p) end
 for _,g in pairs(self.geometry) do g:destroy() end
 table.clear(self.matches)
end
return Service
