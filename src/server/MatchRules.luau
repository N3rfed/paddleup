-- Court coordinates match the painted lines in World.
local Rules={HALF_WIDTH=20,BASELINE=40,KITCHEN=14,HIT_RANGE=12,PERFECT_RANGE=9,SLAM_RANGE=16,SLAM_HORIZONTAL=8,REAR_REACH=1.5,SLAM_MIN_HEIGHT=0.5,SLAM_EXTRA_HEIGHT=5,BACK_LIMIT=60,CHARGE_TIME=1,CHARGE_SPEED_BONUS=0.3}

function Rules.chargeAmount(elapsed)
 return math.clamp(elapsed/Rules.CHARGE_TIME,0,1)
end

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

-- Shared by server validation and the developer hitbox overlay.
function Rules.slamBounds(character,root)
 local head=character:FindFirstChild("Head")
 local headTop=head and head.Position.Y+head.Size.Y*0.5 or root.Position.Y+3
 local armLength=0
 for _,name in ipairs({"RightUpperArm","RightLowerArm","RightHand","Right Arm"}) do
  local part=character:FindFirstChild(name)
  if part then armLength+=part.Size.Y end
 end
 armLength=math.clamp(armLength,2,6)
 return headTop+Rules.SLAM_MIN_HEIGHT,headTop+armLength+Rules.SLAM_EXTRA_HEIGHT
end

-- Generous vertical reach, while preserving the horizontal limit.
function Rules.overheadReach(ballPosition,rootPosition,minY,maxY)
 local offset=ballPosition-rootPosition
 return Vector3.new(offset.X,0,offset.Z).Magnitude<=Rules.SLAM_HORIZONTAL
  and ballPosition.Y>=minY
  and ballPosition.Y<=maxY
end

-- Overhead contact is the timing window for lobs near the kitchen line.
function Rules.kitchenLobWindow(lob,overhead,position,side)
 local depth=position.Z*side
 return lob==true and overhead and side~=0
  and depth>Rules.KITCHEN+1 and depth<=Rules.KITCHEN+Rules.SLAM_HORIZONTAL
  and math.abs(position.X)<=Rules.HALF_WIDTH
end

-- Deterministic movement influence, shared by the crosshair and server shots.
function Rules.shotAim(rootFrame,velocity,ballPosition)
 local look=rootFrame.LookVector
 local forward=Vector3.new(look.X,0,look.Z).Unit
 local right=Vector3.new(-forward.Z,0,forward.X)
 local movement=Vector3.new(velocity.X,0,velocity.Z)
 local lateral=math.clamp(movement:Dot(right)/18,-1,1)
 local angle=lateral*math.rad(4)
 local direction=forward*math.cos(angle)+right*math.sin(angle)
 local toward=ballPosition and Vector3.new(ballPosition.X-rootFrame.Position.X,0,ballPosition.Z-rootFrame.Position.Z) or forward
 toward=toward.Magnitude>0.1 and toward.Unit or forward
 local momentum=math.clamp(movement:Dot(toward)/18,0,1)
 return direction,momentum,angle
end

function Rules.contactInFront(ballPosition,rootFrame)
 local look=rootFrame.LookVector
 local forward=Vector3.new(look.X,0,look.Z)
 if forward.Magnitude<0.001 then return false end
 return (ballPosition-rootFrame.Position):Dot(forward.Unit)>=-Rules.REAR_REACH
end

function Rules.shotQuality(clean,timeToBounce,timeSinceBounce)
 if clean then return "perfect" end
 if math.min(timeToBounce,timeSinceBounce)>0.65 then return "net" end
 return "lob"
end

function Rules.softShot(position,side)
 -- A drop from behind the kitchen line lands inside the opponent's kitchen.
 return position.Z*side<=Rules.KITCHEN+8 and "dink" or "drop"
end

function Rules.kitchenHitFault(rootPosition,ballPosition,side,isDiving)
 if Rules.inKitchen(rootPosition,0) then return true end
 return isDiving==true and Rules.inKitchen(ballPosition,0)
end

function Rules.diveDirection(moveDirection,lookDirection,ballDirection)
 local moving=Vector3.new(moveDirection.X,0,moveDirection.Z)
 if moving.Magnitude>0.15 then return moving.Unit end
 local looking=Vector3.new(lookDirection.X,0,lookDirection.Z)
 if looking.Magnitude>0.1 then return looking.Unit end
 local ball=Vector3.new(ballDirection.X,0,ballDirection.Z)
 return ball.Magnitude>0.1 and ball.Unit or Vector3.new(0,0,-1)
end

function Rules.slamSpeedScale(rallySpeed)
 return rallySpeed*math.clamp(0.9+0.2*math.max(0,rallySpeed-1),0.9,1.3)
end

function Rules.returnSpeed(speed,clean,slam)
 if not clean then return speed*0.95 end
 if speed<1 then return 1 end
 return speed*(slam and 1.10 or 1.05)
end

return Rules
