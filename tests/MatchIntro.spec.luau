return function(MatchIntro)
 local parent=Instance.new("Folder")
 local signal=Instance.new("BindableEvent")
 local player={UserId=1,WaitForChild=function() return parent end}
 local network={WaitForChild=function() return {OnClientEvent=signal.Event,FireServer=function() end} end}
 local ok,err=pcall(function()
  MatchIntro.start(player,network)
  local gui=parent:FindFirstChild("MatchIntro")
  assert(gui,"Intro UI is created")
  local court=Instance.new("Model",parent)
  local surface=Instance.new("Part",court)
  surface.Name="Playing surface"; surface.Size=Vector3.new(40,0.16,80)
  surface.CFrame=CFrame.new(0,181.16,0)
  local furniture=Instance.new("Model",court); furniture.Name="Courtside furniture"
  local bench=Instance.new("Part",furniture); bench.Name="Bench"
  local scenery=MatchIntro.copyCourt(parent,court)
  assert(scenery["Playing surface"].CFrame==surface.CFrame,"Court shots preserve real world positions")
  assert(scenery["Playing surface"].Size==surface.Size,"Court shots preserve court dimensions")
  assert(scenery["Courtside furniture"].Bench,"Intro includes the full map scenery")
  scenery:Destroy(); court:Destroy()
  local from=MatchIntro.panFrame(Vector3.new(0,184,28),15,0,1)
  local to=MatchIntro.panFrame(Vector3.new(0,184,28),15,1,1)
  assert(to.Position.X>from.Position.X,"Team camera arcs across players")
  local center=Vector3.new(0,184,28)
  local middle=MatchIntro.panFrame(center,15,0.5,1)
  assert(middle.Position.Z<from.Position.Z,"Arc moves in depth instead of sliding sideways")
  assert(math.abs((from.Position-center).Magnitude-(middle.Position-center).Magnitude)<0.001,"Arc maintains its radius")
  assert(middle.LookVector:Dot((center-middle.Position).Unit)>0.999,"Camera aims at the stationary players")
  assert(MatchIntro.panFrame(Vector3.new(0,184,-28),15,1,-1).Position.X<0,"Opposing camera pans in reverse")
  for _,side in ipairs({1,-1}) do
   for _,distance in ipairs({10,30,150}) do
    for _,progress in ipairs({0,0.5,1}) do
     local frame=MatchIntro.panFrame(Vector3.new(10,184,side*40),distance,progress,side,28)
     assert(frame.Position.Z*side>=2 and frame.Position.Z*side<28,"Camera stays between the net and both players")
     assert(math.abs(frame.Position.X)<=18,"Camera stays inside the sidelines")
     assert(frame.LookVector.Z*side>0,"Camera looks away from the net toward its team")
    end
   end
  end
  assert(MatchIntro.countdown(3.1)==nil)
  assert(MatchIntro.countdown(3)==3 and MatchIntro.countdown(2.1)==3)
  assert(MatchIntro.countdown(2)==2 and MatchIntro.countdown(1)==1)
  assert(MatchIntro.countdown(0)==nil,"Countdown ends exactly when play unlocks")
  local member={userId=1,name="Test Player"}
  for index,counts in ipairs({{1,1},{2,2},{1,2}}) do
   local home,away={},{}
   for _=1,counts[1] do table.insert(home,member) end
   for _=1,counts[2] do table.insert(away,member) end
   local data={id=index,endsAt=workspace:GetServerTimeNow()+30,home=home,away=away}
   signal:Fire({matchIntro=data}); task.wait()
   local reveal=gui:FindFirstChild("TeamReveal")
   assert(reveal and reveal:IsA("Frame"),"Intro must render directly without CanvasGroup downsampling")
   assert(reveal and reveal.DiagonalSplit.Rotation~=0,"Team backgrounds have a diagonal split")
   local portraits,names=0,0
   for _,item in ipairs(reveal:GetDescendants()) do
    assert(not item:IsA("CanvasGroup"),"No flattened low-resolution layer in the reveal")
    if item:IsA("ViewportFrame") then
     portraits+=1; assert(item.CurrentCamera,"Team shots need cameras")
     assert(item.Size==UDim2.fromScale(1,1),"Team shots fill the screen")
     assert(item:FindFirstChild("DiagonalMask"),"Camera images must be clipped diagonally")
    end
    if item.Name=="PlayerName" then names+=1 end
   end
   assert(portraits==2 and names==counts[1]+counts[2],"Both teams get 3D shots and every player is named")
   signal:Fire({matchIntro=data}); task.wait()
   assert(gui.TeamReveal==reveal,"State broadcasts must not restart the animation")
  end
  signal:Fire({matchIntro={id=4,endsAt=workspace:GetServerTimeNow()+30,
   home={member},away={{userId=0,name="Practice Partner",bot=true}}}}); task.wait()
  local botPortrait=false
  for _,item in ipairs(gui.TeamReveal:GetDescendants()) do
   if item:IsA("ViewportFrame") then botPortrait=true end
  end
  assert(botPortrait,"Practice partner uses a 3D portrait instead of a user thumbnail")
  if game:GetService("RunService"):IsClient() and game:GetService("RunService"):IsRunning() then
   signal:Fire({matchIntro={id=5,endsAt=workspace:GetServerTimeNow()+5.9,home={member},away={member}}})
   task.wait(0.1)
   assert(gui.CourtPan.Visible and not gui.TeamReveal.Visible,"Three-second court pan follows the split")
   assert(gui.CourtPan:IsA("Frame"),"Wide shot exposes the live map instead of a viewport replica")
   local first=workspace.CurrentCamera.CFrame
   task.wait(0.1)
   assert(workspace.CurrentCamera.CFrame~=first,"Live court camera moves")
   signal:Fire({matchIntro={id=6,endsAt=workspace:GetServerTimeNow()+2.9,home={member},away={member}}})
   task.wait(0.1)
   assert(gui.Countdown.Visible and not gui.CourtPan.Visible,"Countdown follows the court pan")
  end
  local pending={id=7,loading=true,endsAt=workspace:GetServerTimeNow()+9.5,home={member},away={member}}
  signal:Fire({matchIntro=pending}); task.wait()
  local cover=gui:FindFirstChild("PreparingCourt")
  assert(cover and cover.BackgroundTransparency==0,"Loading hides incomplete moon scenery")
  signal:Fire({matchIntro=pending}); task.wait()
  assert(gui.PreparingCourt==cover,"Repeated loading broadcasts must not restart preparation")
  signal:Fire({}); task.wait()
  assert(not gui:FindFirstChild("PreparingCourt"),"Leaving cancels the loading transition")
  assert(not gui:FindFirstChild("TeamReveal"),"Leaving or ending the intro dismisses it")
  assert(not gui:FindFirstChild("Countdown"),"Leaving also dismisses the countdown")
  assert(not gui:FindFirstChild("CourtPan"),"Leaving cleans up the wide court shot")
 end)
 parent:Destroy(); signal:Destroy()
 assert(ok,err)
 return "Practice, 1v1, 2v2, 1v2 intros, countdown timing, repeat broadcasts, and dismissal passed"
end
