local Crowd={}
Crowd.__index=Crowd
Crowd.BIG_STREAK=5
Crowd.FAST_SPEED=1.3
Crowd.FAST_HITS=3
Crowd.COOLDOWN=4

function Crowd.new(clock)
 return setmetatable({clock=clock or os.clock,lastGasp=-math.huge,fastHits=0},Crowd)
end

function Crowd:gasp()
 local now=self.clock()
 if now-self.lastGasp<Crowd.COOLDOWN then return false end
 self.lastGasp=now
 return true
end

function Crowd:streakEnded(count)
 return count>=Crowd.BIG_STREAK and self:gasp()
end

function Crowd:shot(speed,lob)
 local surprising=lob and self.fastHits>=Crowd.FAST_HITS
 self.fastHits=not lob and speed>=Crowd.FAST_SPEED and self.fastHits+1 or 0
 return surprising and self:gasp()
end

function Crowd:reset()
 -- Preserve the audio cooldown across rally boundaries.
 self.fastHits=0
end

return Crowd
