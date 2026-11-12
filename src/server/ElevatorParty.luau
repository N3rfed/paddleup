-- Pure authoritative party state. No client supplied roster, capacity, or deadlines.
local Party={}
Party.__index=Party
local modes={"Classic","Chaos"}
function Party.new(config,clock,random)
 return setmetatable({config=config,clock=clock,random=random or Random.new(),players={},preferences={},
  ready={},votes={},stage="Waiting",revision=0},Party)
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
 self.stage="Waiting"; self.ready={}; self.votes={}; self.endsAt=nil; self.mode=nil; self.revision+=1
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
function Party:update()
 if self.stage~="Voting" then return end
 local count=0; local totals={Classic=0,Chaos=0}
 for _,mode in pairs(self.votes) do count+=1; totals[mode]+=1 end
 if count<#self.players and self.clock()<self.endsAt then return end
 local highest=-1; local candidates={}
 for _,mode in ipairs(modes) do
  if self:allowed()[mode] then
   if totals[mode]>highest then highest=totals[mode]; candidates={mode}
   elseif totals[mode]==highest then table.insert(candidates,mode) end
  end
 end
 self.mode=candidates[self.random:NextInteger(1,#candidates)]
 self.stage="Departing"; self.endsAt=self.clock()+self.config.departureSeconds
 return true
end
function Party:snapshot()
 local roster,ready,counts={},0,{Classic=0,Chaos=0}
 for _,p in ipairs(self.players) do
  if self.ready[p] then ready+=1 end
  if self.votes[p] then counts[self.votes[p]]+=1 end
  table.insert(roster,{userId=p.UserId,name=p.DisplayName,ready=self.ready[p]==true,vote=self.votes[p]})
 end
 return {id=self.config.id,format=self.config.format,capacity=self.config.capacity,count=#self.players,
  stage=self.stage,revision=self.revision,roster=roster,ready=ready,counts=counts,allowed=self:allowed(),mode=self.mode,endsAt=self.endsAt}
end
return Party
