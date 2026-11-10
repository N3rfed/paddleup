-- Server-owned voting deadlines and lottery; clients only submit their own picks.
local Setup=require(script.Parent:WaitForChild("MatchSetup"))
local Queue={VOTE_SECONDS=15,REVEAL_SECONDS=4}
Queue.__index=Queue
function Queue.new(notify,clock,random)
 return setmetatable({groups={},members={},active=nil,notify=notify,
  clock=clock or function() return workspace:GetServerTimeNow() end,random=random or Random.new()},Queue)
end
function Queue:publish(group)
 local roster,counts={}, {Rooftop=0,Moon=0}
 for _,player in ipairs(group.players) do
  local map=group.votes[player]
  if map then counts[map]+=1 end
  table.insert(roster,{player=player,name=player.DisplayName,map=map,modifier=group.modifiers[player]})
 end
 for _,player in ipairs(group.players) do
  self.notify(player,{stage=group==self.active and group.stage or "Queued",mode=group.mode,
   format=group.format,count=#group.players,required=Setup.players[group.format],roster=roster,
   counts=counts,map=group.map,modifier=group.modifier,endsAt=group.endsAt,
   revealAt=group.revealAt,revealEndsAt=group.revealEndsAt,candidates=group.candidates})
 end
end
function Queue:remove(player)
 local group=self.members[player]
 if not group then return end
 self.members[player]=nil; group.votes[player]=nil; group.modifiers[player]=nil
 table.remove(group.players,table.find(group.players,player))
 if self.active==group then self.active=nil end
 group.stage="Queued"; group.endsAt=nil; group.revealAt=nil; group.revealEndsAt=nil
 group.map=nil; group.candidates=nil
 if #group.players==0 then table.remove(self.groups,table.find(self.groups,group))
 else self:publish(group) end
 self.notify(player,{stage="Cancelled"})
end
function Queue:join(player,mode,format)
 if not Setup.modes[mode] or not Setup.players[format] or self.members[player] then return false end
 local group
 for _,candidate in ipairs(self.groups) do
  if candidate~=self.active and candidate.mode==mode and candidate.format==format
   and #candidate.players<Setup.players[format] then group=candidate; break end
 end
 if not group then
  group={mode=mode,format=format,players={},votes={},modifiers={},modifier=mode=="Chaos" and "LowGravity" or "None"}
  table.insert(self.groups,group)
 end
 table.insert(group.players,player); self.members[player]=group
 group.modifiers[player]=mode=="Chaos" and "LowGravity" or "None"
 self:publish(group)
 return true
end
function Queue:configure(player,map,modifier)
 local group=self.active
 if not group or self.members[player]~=group or group.stage~="Setup" or self.clock()>=group.endsAt then return false end
 modifier=modifier or group.modifiers[player]
 if not Setup.valid(group.mode,map or group.votes[player] or "Rooftop",modifier) then return false end
 if map then group.votes[player]=map end
 group.modifiers[player]=modifier
 self:publish(group)
 return true
end
function Queue:update(available)
 if not available then return end
 local now=self.clock()
 local group=self.active
 if not group then
  for _,candidate in ipairs(self.groups) do
   if #candidate.players==Setup.players[candidate.format] then
    self.active=candidate; candidate.stage="Setup"; candidate.endsAt=now+Queue.VOTE_SECONDS
    self:publish(candidate); return
   end
  end
  return
 end
 local allSelected=true
 for _,player in ipairs(group.players) do
  if not group.votes[player] then allSelected=false; break end
 end
 if group.stage=="Setup" and (allSelected or now>=group.endsAt) then
  local counts={Rooftop=0,Moon=0}
  local lowGravity=0
  for _,player in ipairs(group.players) do
   local map=group.votes[player]; if map then counts[map]+=1 end
   if group.modifiers[player]=="LowGravity" then lowGravity+=1 end
  end
  group.candidates={}
  local highest=math.max(counts.Rooftop,counts.Moon)
  for _,map in ipairs({"Rooftop","Moon"}) do
   if counts[map]==highest then table.insert(group.candidates,map) end
  end
  group.map=group.candidates[self.random:NextInteger(1,#group.candidates)]
  group.modifier=(group.mode=="Chaos" or (group.mode=="Arcade" and lowGravity>#group.players/2)) and "LowGravity" or "None"
  group.stage="Reveal"; group.revealAt=now
  group.revealEndsAt=now+(#group.candidates>1 and Queue.REVEAL_SECONDS or (allSelected and now<group.endsAt and 0 or 2))
  self:publish(group)
 end
 if group.stage=="Reveal" and now>=group.revealEndsAt then
  self.active=nil; table.remove(self.groups,table.find(self.groups,group))
  for _,player in ipairs(group.players) do self.members[player]=nil end
  return group
 end
end
function Queue:destroy()
 local players={}; for player in pairs(self.members) do table.insert(players,player) end
 for _,player in ipairs(players) do self:remove(player) end
 table.clear(self.groups); table.clear(self.members); self.active=nil
end
return Queue
