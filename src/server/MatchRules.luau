-- Court coordinates match the painted lines in World.
local Rules={HALF_WIDTH=20,BASELINE=40,KITCHEN=14,HIT_RANGE=12,PERFECT_RANGE=9,SLAM_RANGE=16,SLAM_HORIZONTAL=8,BACK_LIMIT=60}

function Rules.serveX(side,score)
 return side*(score%2==0 and 10 or -10)
end

function Rules.inKitchen(position,margin)
 margin=margin or 0
 return math.abs(position.X)<=Rules.HALF_WIDTH+margin and math.abs(position.Z)<=Rules.KITCHEN+margin
end

function Rules.servePositionValid(position,side,serveX,grounded)
 return grounded and position.Z*side>Rules.BASELINE+1
  and math.abs(position.X)<Rules.HALF_WIDTH-1 and position.X*math.sign(serveX)>1
end

function Rules.serveLandingValid(position,side,serveX)
 return position.Z*side< -Rules.KITCHEN-0.09 and math.abs(position.Z)<=Rules.BASELINE+0.09
  and math.abs(position.X)<=Rules.HALF_WIDTH+0.09 and position.X*math.sign(serveX)<=0.09
end

function Rules.returnFault(bounces,shots,inKitchen)
 if bounces>0 then return nil end
 if shots<2 then return "Two-bounce rule: let the ball bounce" end
 if inKitchen then return "Kitchen volley fault" end
 return nil
end

function Rules.startPosition(side,servingSide,serveX,primary)
 local serving=side==servingSide
 local x=serving and serveX or -serveX
 if not primary then x=-x end
 local depth=(serving or primary) and 46 or Rules.KITCHEN+4
 return Vector3.new(x,185,side*depth)
end

-- Extra reach only applies to balls above the head and within overhead arm reach.
function Rules.overheadReach(ballPosition,rootPosition,headTop,armLength)
 local offset=ballPosition-rootPosition
 return Vector3.new(offset.X,0,offset.Z).Magnitude<=Rules.SLAM_HORIZONTAL
  and ballPosition.Y>=headTop+armLength*0.5
  and ballPosition.Y<=headTop+armLength+1
end

function Rules.returnSpeed(speed,clean,slam)
 if not clean then return speed*0.95 end
 if speed<1 then return 1 end
 return speed*(slam and 1.10 or 1.05)
end

return Rules
