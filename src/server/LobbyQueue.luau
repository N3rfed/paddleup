-- Server-owned lobby state. No Instances or network calls, so matchmaking can be tested independently.
local Lobby={}
Lobby.__index=Lobby
function Lobby.new(clock)
 return setmetatable({players={},parties={},queue={},invites={},active=nil,serial=0,clock=clock or os.clock},Lobby)
end
function Lobby:add(id)
 if self.players[id] then return end
 self.players[id]={party=id,watching=false}
 self.parties[id]={leader=id,members={id}}
end
function Lobby:party(id)
 local p=self.players[id]
 return p and self.parties[p.party]
end
function Lobby:queued(id)
 local party=self:party(id)
 for _,entry in ipairs(self.queue) do if entry.party==party then return entry end end
end
function Lobby:playing(id)
 return self.active and table.find(self.active.members,id)~=nil
end
function Lobby:cancel(id)
 local party=self:party(id)
 for i=#self.queue,1,-1 do if self.queue[i].party==party then table.remove(self.queue,i) end end
end
function Lobby:invite(id,target)
 local party=self:party(id)
 local other=self:party(target)
 if not party or not other or id==target then return false,"Choose a player in this lobby." end
 if party.leader~=id then return false,"Only the party leader can invite." end
 if self:queued(id) or self:queued(target) or self:playing(id) or self:playing(target) then return false,"Leave the queue or finish your match first." end
 if #party.members>=4 or #other.members~=1 then return false,"That player is already in a party, or your party is full." end
 self.invites[target]={leader=id,expires=self.clock()+30}
 return true
end
function Lobby:accept(id)
 local invite=self.invites[id]
 self.invites[id]=nil
 local party=invite and self:party(invite.leader)
 local own=self:party(id)
 if not invite or invite.expires<self.clock() or not party or party.leader~=invite.leader then return false,"That invitation expired." end
 if not own or #own.members~=1 or #party.members>=4 or self:playing(id) or self:playing(party.leader) or self:queued(id) or self:queued(party.leader) then return false,"Party changed. Ask for another invitation." end
 self.parties[own.leader]=nil
 table.insert(party.members,id); self.players[id].party=party.leader
 return true
end
function Lobby:leaveParty(id)
 local party=self:party(id)
 if not party or self:playing(id) then return false,"Finish or leave your match first." end
 self:cancel(id)
 table.remove(party.members,table.find(party.members,id))
 self.parties[party.leader]=nil
 if #party.members>0 then
  party.leader=party.members[1]; self.parties[party.leader]=party
  for _,member in ipairs(party.members) do self.players[member].party=party.leader end
 end
 self.parties[id]={leader=id,members={id}}; self.players[id].party=id
 self.invites[id]=nil
 return true
end
function Lobby:enqueue(id,mode,difficulty)
 if mode~="1v1" and mode~="2v2" and mode~="Practice" then return false,"Choose 1v1, 2v2, or Practice." end
 local party=self:party(id)
 if not party or party.leader~=id then return false,"Your party leader selects the queue." end
 for _,member in ipairs(party.members) do if self:playing(member) then return false,"Your party is still playing." end end
 if mode=="Practice" then
  if #party.members~=1 then return false,"Leave your party to start solo practice." end
  if difficulty~="Easy" and difficulty~="Normal" and difficulty~="Hard" then return false,"Choose Easy, Normal, or Hard." end
 end
 if mode=="1v1" and #party.members>2 then return false,"1v1 supports solo players or a party of two." end
 if self:queued(id) then return false,"Already queued. Leave the queue to change modes." end
 self.serial+=1
 table.insert(self.queue,{party=party,mode=mode,order=self.serial,difficulty=difficulty})
 return true
end
function Lobby:takeMatch()
 if self.active then return end
 -- Pick the oldest queue that can form a complete match. Never split a doubles pair.
 local candidates={}
 for _,entry in ipairs(self.queue) do
  if entry.mode=="Practice" then
   table.insert(candidates,{mode="Practice",entries={entry},order=entry.order,difficulty=entry.difficulty})
   break
  end
 end
 for _,mode in ipairs({"1v1","2v2"}) do
  local needed=mode=="1v1" and 2 or 4
  local function choose(start,remaining,picked)
   if remaining==0 then return picked end
   for i=start,#self.queue do
    local entry=self.queue[i]
    if entry.mode==mode and #entry.party.members<=remaining then
     local nextPicked=table.clone(picked); table.insert(nextPicked,entry)
     local result=choose(i+1,remaining-#entry.party.members,nextPicked)
     if result then return result end
    end
   end
  end
  local picked=choose(1,needed,{})
  if picked then table.insert(candidates,{mode=mode,entries=picked,order=picked[1].order}) end
 end
 table.sort(candidates,function(a,b) return a.order<b.order end)
 local selected=candidates[1]
 if not selected then return end
 local home,away,members={},{},{}
 -- Largest groups go first, keeping pairs together; full friend groups split in join order.
 table.sort(selected.entries,function(a,b)
  if #a.party.members==#b.party.members then return a.order<b.order end
  return #a.party.members>#b.party.members
 end)
 local capacity=selected.mode=="1v1" and 1 or 2
 for _,entry in ipairs(selected.entries) do
  for _,id in ipairs(entry.party.members) do
   table.insert(#home<capacity and home or away,id); table.insert(members,id)
   self.players[id].watching=false
  end
  table.remove(self.queue,table.find(self.queue,entry))
 end
 local practice=selected.mode=="Practice"
 if practice then away={0} end
 self.active={mode=selected.mode,home=home,away=away,members=members,bot=practice,difficulty=selected.difficulty}
 return self.active
end
function Lobby:finish()
 local active=self.active; self.active=nil
 for _,p in pairs(self.players) do p.watching=false end
 return active
end
function Lobby:watch(id,watching)
 if not self.players[id] or self:playing(id) then return false,"Players cannot spectate their own match." end
 if watching and not self.active then return false,"No match is running yet." end
 self.players[id].watching=watching
 return true
end
function Lobby:remove(id)
 if not self.players[id] then return end
 self:cancel(id)
 if self:playing(id) then self:finish() end
 self:leaveParty(id)
 self.parties[id]=nil; self.players[id]=nil; self.invites[id]=nil
 for target,invite in pairs(self.invites) do if invite.leader==id then self.invites[target]=nil end end
end
return Lobby
