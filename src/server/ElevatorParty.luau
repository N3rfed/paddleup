-- Pure authoritative party state. No client supplied roster, capacity, or deadlines.
local Party={}
Party.__index=Party
local modes={"Classic","Chaos"}
local function winner(choices,totals,random)
 local highest=-1; local candidates={}
 for _,id in ipairs(choices) do
  local count=totals[id] or 0
  if count>highest then highest=count; candidates={id}
  elseif count==highest then table.insert(candidates,id) end
 end
 return candidates[random:NextInteger(1,#candidates)]
end
function Party.new(config,clock,random)
 assert(config.maps and #config.maps>0,"Elevator map choices are required")
 return setmetatable({config=config,clock=clock,random=random or Random.new(),players={},preferences={},
  ready={},votes={},mapVotes={},stage="Waiting",revision=0},Party)
end
function Party:allowed(preference)
 local allowed={Classic=true,Chaos=true}
 for _,p in ipairs(self.players) do
  local selected=self.preferences[p]
  if selected and selected~="Any" then
   for mode in pairs(allowed) do if mode~=selected then allowed[mode]=nil end end
  end
 end
 if preference and preference~="Any" then
  for mode in pairs(allowed) do if mode~=preference then allowed[mode]=nil end end
 end
 return allowed
end
function Party:reset()
 self.stage="Waiting"; self.ready={}; self.votes={}; self.mapVotes={}
 self.endsAt=nil; self.mode=nil; self.map=nil; self.revision+=1
end
function Party:join(player,preference)
 preference=preference or "Any"
 if self.stage~="Waiting" or table.find(self.players,player) or #self.players>=self.config.capacity
  or (preference~="Any" and preference~="Classic" and preference~="Chaos") or not next(self:allowed(preference)) then return false end
 table.insert(self.players,player); self.preferences[player]=preference; self:reset()
 return true
end
function Party:leave(player)
 local index=table.find(self.players,player)
 if not index then return false end
 table.remove(self.players,index); self.preferences[player]=nil; self:reset()
 return true
end
function Party:readyUp(player)
 if self.stage~="Waiting" or #self.players~=self.config.capacity or not table.find(self.players,player) or self.ready[player] then return false end
 self.ready[player]=true
 local count=0; for _ in pairs(self.ready) do count+=1 end
 if count==self.config.capacity then self.stage="Voting"; self.endsAt=self.clock()+self.config.voteSeconds end
 return true
end
function Party:vote(player,mode)
 if self.stage~="Voting" or self.clock()>=self.endsAt or not table.find(self.players,player)
  or self.votes[player] or not self:allowed()[mode] then return false end
 self.votes[player]=mode; return true
end
function Party:voteMap(player,map)
 if self.stage~="MapVoting" or self.clock()>=self.endsAt or not table.find(self.players,player)
  or self.mapVotes[player] or not table.find(self.config.maps,map) then return false end
 self.mapVotes[player]=map; return true
end
function Party:update()
 if self.stage~="Voting" and self.stage~="MapVoting" then return end
 local selectingMap=self.stage=="MapVoting"
 local ballots=selectingMap and self.mapVotes or self.votes
 local count,totals=0,{}
 for _,id in pairs(ballots) do count+=1; totals[id]=(totals[id] or 0)+1 end
 if count<#self.players and self.clock()<self.endsAt then return end
 if selectingMap then
  self.map=winner(self.config.maps,totals,self.random)
  self.stage="Departing"; self.endsAt=self.clock()+self.config.revealSeconds
 else
  local allowed={}
  for _,mode in ipairs(modes) do if self:allowed()[mode] then table.insert(allowed,mode) end end
  self.mode=winner(allowed,totals,self.random)
  self.stage="MapVoting"; self.endsAt=self.clock()+self.config.mapVoteSeconds
 end
 return true
end
function Party:snapshot()
 local roster,ready,counts,mapCounts={},0,{Classic=0,Chaos=0},{}
 for _,id in ipairs(self.config.maps) do mapCounts[id]=0 end
 for _,p in ipairs(self.players) do
  if self.ready[p] then ready+=1 end
  if self.votes[p] then counts[self.votes[p]]+=1 end
  if self.mapVotes[p] then mapCounts[self.mapVotes[p]]+=1 end
  table.insert(roster,{userId=p.UserId,name=p.DisplayName,ready=self.ready[p]==true,vote=self.votes[p],mapVote=self.mapVotes[p]})
 end
 return {id=self.config.id,format=self.config.format,capacity=self.config.capacity,count=#self.players,
  stage=self.stage,revision=self.revision,roster=roster,ready=ready,counts=counts,mapCounts=mapCounts,
  maps=table.clone(self.config.maps),allowed=self:allowed(),mode=self.mode,map=self.map,endsAt=self.endsAt}
end
return Party
