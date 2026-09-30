-- Detached fixtures test immediate input animation without changing a live game.
return function(source)
 local fixture=Instance.new("Folder")
 local character=Instance.new("Model"); character.Parent=fixture
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Parent=character
 local arm=Instance.new("Part"); arm.Parent=character
 local humanoid=Instance.new("Humanoid"); humanoid.Parent=character
 local shoulder=Instance.new("Motor6D")
 shoulder.Name="RightShoulder"; shoulder.Part0=root; shoulder.Part1=arm; shoulder.Parent=root
 local player={UserId=42,Character=character}
 local players={LocalPlayer=player}
 function players:GetPlayerByUserId(id) return id==42 and player or nil end
 function players:GetPlayers() return {player} end
 local clock=0
 local environment=setmetatable({
  game={GetService=function(_,name) assert(name=="Players"); return players end},
  os={clock=function() return clock end},
 },{__index=getfenv()})
 local ok,result=pcall(function()
  local loader=assert(loadstring(source)); setfenv(loader,environment)
  local Shots=loader()
  Shots.swing(42,false,false,nil,nil,0,nil,true); Shots.update()
  local normal=shoulder.Transform
  assert(normal~=CFrame.identity,"Click must move the arm without a server contact")
  Shots.restore(); clock=0.1
  Shots.swing(42,false,false,nil,nil,0,"dink",true); Shots.update()
  local dink=shoulder.Transform
  assert(dink~=normal,"Dink must have a distinct underhand pose")
  Shots.restore(); clock=0.2
  Shots.swing(42,false,false,nil,nil,0,"drop",true); Shots.update()
  assert(shoulder.Transform~=dink,"Drop must have a longer underhand stroke")
  Shots.restore(); clock=0.3
  Shots.swing(42,false,false,nil,nil,0,nil,true); Shots.update()
  assert(shoulder.Transform==normal,"Every click must restart its swing, including rapid misses")
  Shots.restore(); clock=0.4; Shots.update()
  local predicted=shoulder.Transform
  Shots.restore(); Shots.swing(42,false,false,nil,nil,0); Shots.update()
  assert(shoulder.Transform==predicted,"Server confirmation must not restart the swing")
  Shots.restore(); clock=1
  Shots.charge(42,true,0.3); Shots.update()
  assert(shoulder.Transform~=CFrame.identity,"Holding must transition into a charge windup")
  Shots.restore(); Shots.swing(42,false,false,nil,nil,0.5,nil,true); Shots.update()
  assert(shoulder.Transform~=CFrame.identity,"Charged release must swing immediately")
  Shots.restore(); clock=3; Shots.update()
  assert(shoulder.Transform==CFrame.identity,"Finished swings must restore locomotion")
  return "Immediate clicks, distinct dink/drop poses, rapid misses, server reconciliation, charging, and pose cleanup passed"
 end)
 fixture:Destroy()
 assert(ok,result)
 return result
end
