return function(MatchIntro)
 local parent=Instance.new("Folder")
 local signal=Instance.new("BindableEvent")
 local player={UserId=42,WaitForChild=function() return parent end}
 local network={WaitForChild=function() return {OnClientEvent=signal.Event,FireServer=function() end} end}
 local ok,err=pcall(function()
  assert(MatchIntro.countdown(3.1)==nil)
  assert(MatchIntro.countdown(3)==3 and MatchIntro.countdown(2.1)==3)
  assert(MatchIntro.countdown(2)==2 and MatchIntro.countdown(1)==1 and MatchIntro.countdown(0)==nil)
  assert(MatchIntro.roundLabel({})=="ROUND 1","Do not invent a best-of-three series")
  assert(MatchIntro.roundLabel({round=2,totalRounds=3})=="ROUND 2 / 3")
  local grounding=Instance.new("Model",parent)
  local foot=Instance.new("Part",grounding); foot.Name="RightFoot"; foot.Size=Vector3.new(1,1,2); foot.CFrame=CFrame.new(0,10,0)
  local hanging=Instance.new("Part",grounding); hanging.Name="PaddleFace"; hanging.CFrame=CFrame.new(2,6,0)
  MatchIntro.groundActor(grounding,3)
  assert(math.abs(foot.Position.Y-foot.Size.Y/2-3)<0.001,"Feet sit on the court even when the paddle hangs below them")
  grounding:Destroy()
  local rig=Instance.new("Model",parent)
  local hand=Instance.new("Part",rig);hand.Name="RightHand";hand.CFrame=CFrame.new(0,4,0)
  local face=assert(MatchIntro.ensurePaddle(rig))
  assert(face.Name=="PaddleFace" and rig:FindFirstChild("PaddleGrip") and face.Anchored,"Intro avatars hold their paddle before replication finishes")
  assert(MatchIntro.ensurePaddle(rig)==face and #rig:GetChildren()==3,"Existing paddles are reused")
  local head=Instance.new("Part",rig); head.Name="Head"; head.CFrame=CFrame.new(0,6,0); head.Anchored=true
  local actor=MatchIntro.prepareActor(rig,0)
  local animationRoot=Instance.new("Frame",parent); Instance.new("Frame",animationRoot).Name="Canvas"
  local scene={root=animationRoot,portraits={{actors={actor}}}}
  local paddleOffset=hand.CFrame:ToObjectSpace(face.CFrame)
  MatchIntro.animateScenes(scene,0); local headStart=head.CFrame
  MatchIntro.animateScenes(scene,0.8)
  assert(head.CFrame.LookVector:Dot(headStart.LookVector)<0.999,"VS characters glance instead of freezing")
  assert((hand.CFrame:ToObjectSpace(face.CFrame).Position-paddleOffset.Position).Magnitude<0.001,"Paddles stay in the animated hand")
  animationRoot:Destroy()
  rig:Destroy()
  MatchIntro.start(player,network)
  local gui=assert(parent:FindFirstChild("MatchIntro"))
  assert(gui.DisplayOrder>70,"The intro covers gameplay and draft UI")
  local function member(id) return {userId=id,name=id==42 and "A Very Long Local Player Name" or "Opponent "..id} end
  for index,counts in ipairs({{1,1},{2,2},{1,2}}) do
   local home,away={},{}
   for i=1,counts[1] do table.insert(home,member(i)) end
   for i=1,counts[2] do table.insert(away,member(i==1 and 42 or i+10)) end
   local data={id=index,endsAt=workspace:GetServerTimeNow()+30,home=home,away=away,
    variant="Arcade",round=1,environmentTitle="SKYLINE CLUB"}
   signal:Fire({matchIntro=data}); task.wait()
   local reveal=assert(gui:FindFirstChild("TeamReveal"))
   local canvas=reveal.Canvas
   assert(canvas.MatchFormat.Text==counts[1].."V"..counts[2])
   assert(canvas.Mode.Text:gsub(" ","")=="ARCADEMODE" and canvas.Round.Text=="ROUND 1")
   local names,markers=0,0
   for _,item in ipairs(canvas:GetChildren()) do
    if item.Name=="PlayerName" then
     names+=1
     if item:GetAttribute("UserId")==42 then assert(item.Position.X.Offset>1000,"Local player is always on the right") end
    end
    if item.Name=="YouBadge" then
     markers+=1
     assert(item.YouLabel.Position==UDim2.fromScale(0.5,0.5) and item.YouLabel.AnchorPoint==Vector2.new(0.5,0.5),"YOU stays centered in its badge")
    end
   end
   assert(names==counts[1]+counts[2] and markers==1,"Every teammate is named and only the local player gets YOU")
   assert(reveal.CourtBackground:FindFirstChildOfClass("UIGradient"),"A night sky sits behind the court")
   for side=1,2 do
    local shot=reveal:FindFirstChild("CharacterPortrait"..side)
    assert(shot and shot:IsA("ViewportFrame") and shot.CurrentCamera and shot:FindFirstChild("DiagonalMask"),"Each diagonal half renders a player standing in the court")
    local scenery=reveal:FindFirstChild("CourtScenery"..side)
    assert(scenery and scenery.CurrentCamera==shot.CurrentCamera,"Bright actors and dark scenery share the exact camera")
    assert(shot.Ambient.R>scenery.Ambient.R and reveal.CourtTint.ZIndex<shot.ZIndex,"Background tint cannot dim the characters")
   end
   assert(reveal.InputCover.Modal and canvas.DiagonalSplit.Image~="")
   signal:Fire({matchIntro=data}); task.wait()
   assert(gui.TeamReveal==reveal,"Repeated snapshots update the deadline without rebuilding")
  end
  local left,right=MatchIntro.viewTeams({home={member(1),member(42)},away={member(3),member(4)}},42)
  assert(left[1].userId==3 and right[1].userId==42 and right[2].userId==1,"Home-side players are moved to the right without mutating teams")
  signal:Fire({matchIntro={id=4,endsAt=workspace:GetServerTimeNow()+30,
   environmentTitle="LUNAR CLUB",home={member(42)},away={{userId=0,name="Practice Partner",bot=true}}}})
  task.wait()
  assert(gui.TeamReveal.Canvas.EnvironmentTitle.Text=="LUNAR CLUB")
  local foundBot=false
  for _,item in ipairs(gui.TeamReveal.Canvas:GetChildren()) do
   if item.Name=="PlayerName" and item.Text=="Practice Partner" then foundBot=true end
  end
  assert(foundBot,"Practice uses the actual bot name")
  if game:GetService("RunService"):IsClient() and game:GetService("RunService"):IsRunning() then
   local camera=workspace.CurrentCamera
   local kind=camera.CameraType
   signal:Fire({matchIntro={id=5,endsAt=workspace:GetServerTimeNow()+2.1,home={member(42)},away={member(2)}}})
   task.wait(0.2)
   assert(gui.TeamReveal.Canvas.CountdownText.Text=="STARTING IN 2","Countdown follows the shared server deadline")
   assert(camera.CameraType==kind,"The new slate does not take over the gameplay camera")
   signal:Fire({matchIntro={id=5,endsAt=workspace:GetServerTimeNow()-1,home={member(42)},away={member(2)}}})
   task.wait(0.1)
   assert(not gui:FindFirstChild("TeamReveal"),"Countdown clears when play unlocks")
  end
  local pending={id=6,loading=true,endsAt=workspace:GetServerTimeNow()+3,home={member(42)},away={member(2)}}
  signal:Fire({matchIntro=pending}); task.wait()
  local cover=assert(gui:FindFirstChild("PreparingCourt"))
  signal:Fire({matchIntro=pending}); task.wait()
  assert(gui.PreparingCourt==cover,"Loading snapshots do not restart preparation")
  signal:Fire({}); task.wait()
  assert(not gui:FindFirstChild("PreparingCourt") and not gui:FindFirstChild("TeamReveal"),"Leaving clears both loading and VS UI")
 end)
 parent:Destroy(); signal:Destroy()
 assert(ok,err)
 return "VS layouts, rosters, local badge, practice bot, shared countdown, loading cancellation, and cleanup passed"
end
