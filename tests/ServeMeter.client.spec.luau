-- Run from the lobby with an empty practice court. Unfocused Studio hides all meters;
-- allowUnfocused skips only the positive visibility check, retaining receiver checks.
return function(player,allowUnfocused)
 local network=game.ReplicatedStorage.PaddleUp
 local latest
 local connection=network.State.OnClientEvent:Connect(function(data) latest=data end)
 local function waitFor(predicate,timeout)
  local deadline=os.clock()+timeout
  repeat task.wait() until predicate() or os.clock()>deadline
  assert(predicate(),"Timed out waiting for serve transition")
 end
 local ok,result=pcall(function()
  network.Session:FireServer("Practice","PowerUp")
  waitFor(function() return latest and latest.canServe and not latest.matchIntro end,40)
  task.wait(0.4)
  local meter=player.PlayerGui.PaddleUpHUD.ServeTimingMeter
  assert(latest.serverId==player.UserId and latest.canServe,"Server must retain serving access")
  local serverMeterVisible=meter.Visible
  assert(allowUnfocused or serverMeterVisible,"Focused server must see their meter")
  -- Deliberately undercharge to hand service to the practice opponent.
  network.Input:FireServer("ServeChargeStart")
  task.wait(0.05)
  network.Input:FireServer("ServeTimingStop")
  waitFor(function() return latest and latest.serveReady and latest.serverId==0 end,8)
  task.wait(0.1)
  assert(not latest.canServe and not meter.Visible,"Receiver must not see the opponent's meter")
  local botDeadline=latest.serveDeadline
  network.Input:FireServer("ServeChargeStart")
  task.wait(0.05)
  network.Input:FireServer("ServeTimingStop")
  task.wait(0.1)
  assert(latest.serveReady and latest.serveDeadline==botDeadline,"Receiver input cannot control the bot's serve")
  waitFor(function() return latest and latest.live and latest.last==-1 end,4)
  assert(not meter.Visible,"Bot auto-serve must keep receiver's meter hidden")
  return {serverMeterVisible=serverMeterVisible,receiverMeterHidden=true,receiverInputRejected=true,botAutoServe=true}
 end)
 connection:Disconnect()
 network.Session:FireServer("Lobby")
 assert(ok,result)
 return result
end
