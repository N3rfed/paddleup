-- Detached HUD verifies the actual countdown and responsive layout without a live match.
return function(source)
 local render,receive
 local function signal(callback) return {Connect=function(_,fn) callback(fn) end} end
 local playerGui=Instance.new("Folder")
 local legacyScore=Instance.new("Frame")
 local legacyStamina=Instance.new("Frame")
 local attributes={SessionMode="1V1",CourtSide=1}
 local player={UserId=42,DisplayName="Server"}
 function player:GetAttribute(name) return attributes[name] end
 function player:GetAttributeChangedSignal() return signal(function() end) end
 function player:WaitForChild(name) assert(name=="PlayerGui"); return playerGui end
 local state={OnClientEvent=signal(function(fn) receive=fn end)}
 local network={WaitForChild=function(_,name) assert(name=="State"); return state end}
 local assets={get=function() return "test" end}
 function assets.image(parent,name,x,y,w,h)
  local image=Instance.new("ImageLabel"); image.Name=name; image.Parent=parent; return image
 end
 local time=100
 local world={CurrentCamera={ViewportSize=Vector2.new(1920,1080)},GetServerTimeNow=function() return time end}
 local services={Players={GetPlayers=function() return {player} end},
  RunService={RenderStepped=signal(function(fn) render=fn end)}}
 local environment=setmetatable({workspace=world,game={GetService=function(_,name) return services[name] or game:GetService(name) end}},{__index=getfenv()})
 local code=source:gsub('local Assets = require%(script.Parent:WaitForChild%("FigmaAssets"%)%)','local Assets = ...',1)
 local loader=assert(loadstring(code)); setfenv(loader,environment)
 local ok,result=pcall(function()
  loader(assets).start(player,network,legacyScore,legacyStamina)
  local gui=playerGui.FigmaHUD
  local score=gui.Scoreboard
  local timer=gui.ServeCountdown
  local data={score={0,0},servingSide=1,serverNumber=1,serverId=42,serveReady=true,
   canServe=true,serveDeadline=108,live=false,stamina=100,dive=0}
  receive(data); render()
  assert(gui.Enabled and timer.Visible and timer.Timer.Text=="SERVE IN 8s","Serving player sees timeout countdown")
  receive(data)
  assert(timer.Timer.Text=="SERVE IN 8s","Snapshots cannot overwrite countdown text between frames")
  time=103.4; render()
  assert(timer.Timer.Text=="SERVE IN 5s","Countdown advances from server time without a snapshot")
  time=105.5; render()
  assert(timer.Timer.TextColor3==Color3.fromRGB(255,85,200),"Last three seconds use the HUD pink accent")
  data.serverId=43; receive(data); render()
  assert(not timer.Visible,"Receiver never sees their own timeout countdown")
  data.serverId=42; data.practicePaused=true; receive(data); render()
  assert(not timer.Visible,"Paused practice hides the countdown")
  data.practicePaused=false; data.live=true; receive(data); render()
  assert(not score.Serving.Visible and not timer.Visible,"Rally hides the serve badge and countdown")
  for _,size in ipairs({Vector2.new(1920,1080),Vector2.new(1280,720),Vector2.new(390,844),Vector2.new(844,390)}) do
   world.CurrentCamera.ViewportSize=size; render()
   local scale=score:FindFirstChildOfClass("UIScale").Scale
   assert(scale>0 and scale<=0.88,"Compact scoreboard has a maximum size")
   assert(892*scale<=size.X-127 and 173*scale<=size.Y*0.14+1,"Score fits screen and reserves corner-control space")
  end
  return "Server countdown, receiver isolation, pause/rally visibility, and desktop/mobile scaling passed"
 end)
 playerGui:Destroy(); legacyScore:Destroy(); legacyStamina:Destroy()
 assert(ok,result)
 return result
end
