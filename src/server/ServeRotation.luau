-- Side-out scoring and service positions, independent of characters and physics.
-- Server numbers are turns within a possession, not permanent player numbers.
local Rotation={}
Rotation.__index=Rotation
local function index(side) return side==1 and 1 or 2 end
local function contains(team,id) return id~=nil and table.find(team,id)~=nil end
local function other(team,id) return team[1]==id and team[2] or team[1] end

function Rotation.new()
 return setmetatable({score={0,0},teams={[1]={},[-1]={}},right={},side=1,number=1,opening=true},Rotation)
end

function Rotation:setTeams(home,away)
 for _,side in ipairs({1,-1}) do
  local team=table.clone(side==1 and home or away)
  assert(#team<=2,"A court supports at most two players per team")
  local previous=self.teams[side]
  if #previous==1 and #team==2 and contains(team,previous[1]) then
   self.right[side]=self.score[index(side)]%2==0 and previous[1] or other(team,previous[1])
  elseif not contains(team,self.right[side]) then self.right[side]=team[1] end
  self.teams[side]=team
 end
 if #self.teams[self.side]==0 then self.side=-self.side end
 local team=self.teams[self.side]
 if not contains(team,self.serverId) then self.serverId=self.right[self.side]; self.number=1 end
 if #team<2 then self.number=1
 elseif self.opening then self.number=2 end
end

function Rotation:serveX()
 local team=self.teams[self.side]
 local right=#team<2 and self.score[index(self.side)]%2==0
  or (#team==2 and self.serverId==self.right[self.side])
 return self.side*(right and 10 or -10)
end

function Rotation:receiverId()
 local side=-self.side
 local team=self.teams[side]
 if #team<2 then return team[1] end
 return self:serveX()*self.side>0 and self.right[side] or other(team,self.right[side])
end

function Rotation:award(winner)
 if winner==self.side then
  self.score[index(winner)]+=1
  if #self.teams[winner]==2 then self.right[winner]=other(self.teams[winner],self.right[winner]) end
  return "point"
 end
 local team=self.teams[self.side]
 if #team==2 and self.number==1 then
  self.serverId=other(team,self.serverId); self.number=2
  return "secondServer"
 end
 self.opening=false; self.side=-self.side; self.number=1
 self.serverId=self.right[self.side]
 return "sideOut"
end

function Rotation:reset()
 self.score={0,0}; self.side=1; self.opening=true
 for _,side in ipairs({1,-1}) do self.right[side]=self.teams[side][1] end
 self.serverId=self.right[1]; self.number=#self.teams[1]==2 and 2 or 1
end

return Rotation
