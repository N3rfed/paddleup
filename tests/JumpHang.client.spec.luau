-- Run on a live Studio client with JumpController loaded and the avatar on flat ground.
return function(player)
 local c=player.Character
 local h,r=c.Humanoid,c.HumanoidRootPart
 local RunService=game:GetService("RunService")
 local prior=c:GetAttribute("Diving")
 local previous={enabled=player:GetAttribute("SlowFallEnabled"),side=player:GetAttribute("CourtSide"),variant=player:GetAttribute("MatchVariant")}
 local function sample(slowFall)
  player:SetAttribute("SlowFallEnabled",slowFall)
  h.Jump=false; task.wait(0.3)
  local base=r.Position.Y
  h:ChangeState(Enum.HumanoidStateType.Jumping)
  local airborne=false
  local elapsed,airTime,peak=0,0,base
  local descentStart,descentDrop,downwardFrames=nil,0,0
  while elapsed<4 do
   local dt=RunService.Heartbeat:Wait()
   elapsed+=dt; peak=math.max(peak,r.Position.Y)
   if r:FindFirstChild("JumpHangForce") then
    assert(slowFall,"Normal jumps must not get an assisted force")
    descentStart=descentStart or r.Position.Y
    descentDrop=math.max(descentDrop,descentStart-r.Position.Y)
    if r.AssemblyLinearVelocity.Y< -0.1 then downwardFrames+=1 end
   end
   if h.FloorMaterial==Enum.Material.Air then airborne=true; airTime+=dt
   elseif airborne then break end
  end
  assert(airborne and elapsed<4,"Jump must take off and land")
  assert(not r:FindFirstChild("JumpHangForce"),"Landing must clean hang force")
  return airTime,peak-base,descentDrop,downwardFrames
 end
 local ok,result=pcall(function()
  c:SetAttribute("Diving",nil)
  player:SetAttribute("CourtSide",1); player:SetAttribute("MatchVariant","Chaos")
  local normal,normalHeight=sample(false)
  assert(normal<0.6,"Normal jump must use regular gravity")
  local extended,extendedHeight,drop,downwardFrames=sample(true)
  assert(math.abs(extended-normal-1)<0.2,"Slow descent must retain roughly one extra second airborne")
  assert(drop>1 and downwardFrames>10,"Avatar must visibly descend during the assisted second")
  assert(math.abs(extendedHeight-normalHeight)<0.5,"Jump height must remain consistent")
  task.wait(0.3)
  h:ChangeState(Enum.HumanoidStateType.Jumping)
  local deadline=os.clock()+2
  repeat RunService.Heartbeat:Wait() until r:FindFirstChild("JumpHangForce") or os.clock()>deadline
  assert(r:FindFirstChild("JumpHangForce"),"Jump must reach hang phase")
  require(player.PlayerScripts.Client.DiveController).play(player.UserId,Vector3.new(1,0,0))
  RunService.Heartbeat:Wait()
  assert(not r:FindFirstChild("JumpHangForce"),"Dive must cancel jump hold")
  task.wait(0.8)
  assert(not c:GetAttribute("Diving") and not r:FindFirstChild("JumpHangForce"),"Dive must finish cleanly")
  local restored=sample(false)
  assert(math.abs(restored-normal)<0.1,"Removing Air Time must restore normal jumps")
  return {normal=normal,extended=extended,restored=restored,added=extended-normal,descentDrop=drop,diveCleanup=true}
 end)
 player:SetAttribute("SlowFallEnabled",false)
 player:SetAttribute("CourtSide",previous.side); player:SetAttribute("MatchVariant",previous.variant)
 player:SetAttribute("SlowFallEnabled",previous.enabled)
 c:SetAttribute("Diving",prior)
 assert(ok,result)
 return result
end
