-- Run in Studio with loadRuntime(players, clock, taskScheduler) supplying mocked services.
-- All character/court Instances remain unparented and are destroyed after the check.
return function(loadRuntime)
 local checks=0
 local function expect(value,message) assert(value,message); checks+=1 end
 local now=0
 local people={}
 for id=1,8 do
  local character=Instance.new("Model")
  for _,name in ipairs({"HumanoidRootPart","Head","Right Arm","Left Arm"}) do
   local part=Instance.new("Part"); part.Name=name; part.Anchored=true; part.Parent=character
  end
  local humanoid=Instance.new("Humanoid",character)
  humanoid.Health=100
  local player={UserId=id,DisplayName="Player "..id,Character=character,attributes={}}
  function player:SetAttribute(key,value) self.attributes[key]=value end
  people[id]=player
 end
 local scheduled={}
 local Runtime=loadRuntime(people,function() return now end,{
  spawn=function(callback,...) callback(...) end,
  delay=function(_,callback) table.insert(scheduled,callback) end,
 })
 local snapshots={}
 local feedback={}
 local network={State={},Feedback={}}
 function network.State:FireClient(player,data) snapshots[player.UserId]=data end
 function network.Feedback:FireClient(player,message,kind)
  table.insert(feedback,{player=player,message=message,kind=kind})
 end
 local singles={id=1,offset=Vector3.new(1200,0,0),home={1},away={2},members={1,2}}
 local doubles={id=2,offset=Vector3.new(5200,0,0),home={3,4},away={5,6},members={3,4,5,6}}
 local practice={id=3,offset=Vector3.new(1400,0,0),home={8},away={0},members={8},bot=true,difficulty="Normal"}
 local matches={[1]=singles,[2]=doubles,[3]=practice}
 local function viewers(id)
  local result={}
  for _,member in ipairs(matches[id].members) do table.insert(result,people[member]) end
  if id==1 then table.insert(result,people[7]) end
  return result
 end
 local ended={}
 local function finish(id) ended[id]=true end
 local courtA=Instance.new("Model"); courtA.Name="MatchCourt_1"
 local courtB=Instance.new("Model"); courtB.Name="MatchCourt_2"
 local courtC=Instance.new("Model"); courtC.Name="MatchCourt_3"
 local a,b,c
 local ok,result=pcall(function()
  a=Runtime.new(singles,courtA,network,viewers,finish)
  b=Runtime.new(doubles,courtB,network,viewers,finish)
  c=Runtime.new(practice,courtC,network,viewers,finish)
  now=2
  a.step(0.05); b.step(0.05); c.step(0.05)
  expect(snapshots[1].serveReady and snapshots[3].serveReady,"Both courts prepare independent serves")
  expect(snapshots[1].matchId==1 and snapshots[3].matchId==2,"Snapshots route to the correct roster")
  expect(math.abs(snapshots[1].p.X-1200)<=20 and math.abs(snapshots[3].p.X-5200)<=20,"Ball positions use each court's world offset")
  expect(snapshots[7].side==0 and snapshots[7].p==snapshots[1].p and not snapshots[7].canServe,"Spectators receive their chosen match without becoming players")
  expect(snapshots[8].bot and math.abs(snapshots[8].p.X-1400)<=20,"Practice has an independent bot and court offset")
  a.input(people[3],"ChargeStart")
  expect(people[3].Character:GetAttribute("ShotChargeAt")==nil,"Foreign player input cannot affect another court")
  now=18
  a.step(0.05)
  expect(snapshots[1].live and snapshots[3].serveReady,"Advancing one court cannot advance the other's serve")
  b.step(0.05)
  c.step(0.05)
  expect(snapshots[3].live,"Doubles timeout starts its own serve")
  for _,event in ipairs(feedback) do
   if type(event.message)=="table" then
    local id=event.player.UserId
    local expected=(id<=2 or id==7) and 1 or id==8 and 3 or 2
    expect(event.message.matchId==expected,"Feedback is scoped to its match")
   end
  end
  a.destroy(); a=nil
  now=19; b.step(0.05)
  expect(snapshots[3].matchId==2 and not ended[2],"Destroying singles leaves doubles running")
  c.step(0.05)
  expect(snapshots[8].matchId==3 and not ended[3],"Practice keeps running independently")
  return tostring(checks).." runtime routing, coordinates, serve and cleanup checks passed"
 end)
 if a then a.destroy() else courtA:Destroy() end
 if b then b.destroy() else courtB:Destroy() end
 if c then c.destroy() else courtC:Destroy() end
 for _,player in pairs(people) do player.Character:Destroy() end
 assert(ok,result)
 return result
end
