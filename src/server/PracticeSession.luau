-- Practice-only configuration and authoritative countdown state; no asynchronous timers.
local Practice={}
Practice.__index=Practice
Practice.Profiles={
 Easy={reactionMin=0.4,reactionMax=0.65,think=0.25,move=13,errorX=5,errorZ=4,
  miss=0.2,clean=0.3,wide=0.12,width=10,depthMin=20,depthMax=28,speed=0.8},
 Normal={reactionMin=0.22,reactionMax=0.42,think=0.18,move=18,errorX=3,errorZ=2,
  miss=0.1,clean=0.55,wide=0.07,width=15,depthMin=20,depthMax=34,speed=1},
 Hard={reactionMin=0.12,reactionMax=0.22,think=0.1,move=23,errorX=1.5,errorZ=1,
  miss=0.035,clean=0.8,wide=0.025,width=18,depthMin=25,depthMax=37,speed=1.15},
}
function Practice.new()
 return setmetatable({difficulty="Normal",paused=false,revision=0,remaining=nil,key=nil,served=false,flash=0},Practice)
end
function Practice:reset(difficulty)
 self.difficulty=difficulty or "Normal"
 self.paused=false; self.revision+=1
 self.remaining=nil; self.key=nil; self.served=false; self.flash=0
end
function Practice:select(difficulty)
 if not self.Profiles[difficulty] or difficulty==self.difficulty then return false end
 self:reset(difficulty)
 return true
end
function Practice:setPaused(paused)
 if type(paused)~="boolean" or paused==self.paused then return false end
 self.paused=paused; self.revision+=1
 return true
end
function Practice:step(key,dt)
 if self.paused then return false end
 self.flash=math.max(0,self.flash-dt)
 if not key then self.key=nil; self.remaining=nil; self.served=false; return false end
 if key~=self.key then
  self.key=key; self.remaining=3; self.served=false
  return false
 end
 if self.served then return false end
 self.remaining=math.max(0,self.remaining-dt)
 if self.remaining>0 then return false end
 self.served=true; self.remaining=nil; self.flash=0.6
 return true
end
function Practice:snapshot()
 return {difficulty=self.difficulty,paused=self.paused,revision=self.revision,
  countdown=not self.paused and self.remaining and math.ceil(self.remaining) or nil,
  remaining=self.remaining,serve=self.flash>0 and not self.paused}
end
return Practice
