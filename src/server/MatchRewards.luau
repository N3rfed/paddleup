-- Only validated completed games award XP. No XP for clicks, joins, idle time, or early exits.
local Config=require(script.Parent:WaitForChild("ProgressionConfig"))
local Rewards={}
Rewards.__index=Rewards
function Rewards.new(progression,clock,id)
 return setmetatable({progression=progression,clock=clock or os.clock,id=id or function()
  return game:GetService("HttpService"):GenerateGUID(false)
 end},Rewards)
end
function Rewards:begin(users,mode)
 self.started=self.clock(); self.mode=mode; self.contested=0; self.finished=false; self.eventId=self.id(); self.players={}
 for player,data in pairs(users) do if data.side~=0 then self.players[player]={side=data.side,returns=0} end end
end
function Rewards:contact(player)
 local entry=self.players and self.players[player]
 if entry and not self.finished then entry.returns+=1 end
end
function Rewards:rally(shots)
 if self.started and not self.finished and shots>=3 then self.contested+=1 end
end
function Rewards:complete(winner)
 if not self.started or self.finished then return end
 self.finished=true
 if self.clock()-self.started<Config.MinimumMatchSeconds or self.contested<Config.MinimumContestedRallies then return end
 local count=0; for _ in pairs(self.players) do count+=1 end
 local required=({Practice=1,["1V1"]=2,["1V2"]=3,["2V2"]=4})[self.mode]
 if count~=required then return end
 for player,entry in pairs(self.players) do
  if entry.returns>=Config.MinimumReturns then
   local reward=self.mode=="Practice" and "PracticeCompleted" or entry.side==winner and "MatchWon" or "MatchCompleted"
   self.progression:award(player,reward,self.eventId..":"..player.UserId)
  end
 end
end
return Rewards
