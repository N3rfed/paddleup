local Config=require(script.Parent:WaitForChild("ProgressionConfig"))
local Rules=require(script.Parent:WaitForChild("ProgressionRules"))
local Repository=require(script.Parent:WaitForChild("ProgressionRepository"))
local Service={}
function Service.start(network,lobby)
 -- Module-level reuse also protects the prompt and lifecycle connections from duplicate starts.
 if Service.active then return Service.active end
 local Players=game:GetService("Players")
 local HttpService=game:GetService("HttpService")
 local function now() return DateTime.now().UnixTimestampMillis/1000 end
 local remote=network:FindFirstChild("Progression") or Instance.new("RemoteEvent")
 remote.Name="Progression"; remote.Parent=network
 local api={entries={},closing=false,connections={}}
 Service.active=api
 local store=game:GetService("DataStoreService"):GetDataStore(Config.StoreName)
 local repository=Repository.new(store,now)
 local function guid() return HttpService:GenerateGUID(false) end
 local function connect(signal,callback) table.insert(api.connections,signal:Connect(callback)) end
 local desk=lobby:FindFirstChild("Reception stone top",true) or lobby:FindFirstChild("Reception desk",true)
 assert(desk and desk:IsA("BasePart"),"Daily check-in reception table not found")
 local attachment=desk:FindFirstChild("DailyCheckInPoint") or Instance.new("Attachment")
 attachment.Name="DailyCheckInPoint"; attachment.Position=Vector3.new(0,desk.Size.Y/2+0.7,desk.Size.Z/2+1); attachment.Parent=desk
 local prompt=attachment:FindFirstChild("DailyCheckIn") or Instance.new("ProximityPrompt")
 prompt.Name="DailyCheckIn"; prompt.ActionText="Daily Check-In"; prompt.ObjectText="Paddle Up Club"
 prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
 prompt.HoldDuration=0; prompt.MaxActivationDistance=Config.PromptDistance; prompt.RequiresLineOfSight=false; prompt.Parent=attachment
 local function near(player)
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  return player.Parent==Players and player:GetAttribute("SessionMode")=="Lobby"
   and root and humanoid and humanoid.Health>0 and (root.Position-attachment.WorldPosition).Magnitude<=Config.PromptDistance
 end
 local function publish(entry,notice,open)
  local player=entry.player
  if player.Parent~=Players then return end
  local publishedAt=now()
  local snapshot={ready=false}
  if entry.data then
   local ok,result=pcall(Rules.snapshot,entry.data,publishedAt)
   if ok then snapshot=result else entry.failed=true; entry.failure=Repository.errorInfo(result) end
  end
  snapshot.ready=entry.data~=nil and not entry.failed
  snapshot.pending=entry.running==true or not entry.failed and #entry.queue>0
  snapshot.pendingSince=entry.workStartedAt
  snapshot.status=entry.running and (entry.data and not entry.failed and "Saving" or "Loading")
   or entry.failed and "Error" or entry.data and "Ready" or "Loading"
  snapshot.error=snapshot.status=="Error" and entry.failure.message or nil
  snapshot.errorCode=entry.failure and entry.failure.code or nil
  snapshot.serverNow=publishedAt
  snapshot.retryAfter=math.max(0,(entry.lastRetry or -math.huge)+Config.ManualRetrySeconds-publishedAt)
  snapshot.canRetry=snapshot.status=="Error" and snapshot.retryAfter==0
  entry.revision+=1
  if snapshot.ready then
   player:SetAttribute("Level",snapshot.level); player:SetAttribute("XP",snapshot.xp)
   player:SetAttribute("XPRequired",snapshot.required)
  end
  player:SetAttribute("XPDataReady",snapshot.ready)
  remote:FireClient(player,{state=snapshot,notice=notice,open=open==true,
   revision=entry.revision,ackId=entry.ackId,openId=entry.openId})
 end
 local startWorker
 local function enqueue(entry,operation)
  if #entry.queue>=Config.MaximumPending then return false end
  table.insert(entry.queue,operation)
  startWorker(entry)
  return true
 end
 startWorker=function(entry,manual)
  if entry.running or #entry.queue==0 then return end
  if entry.failure and not entry.failure.retryable and not manual then return end
  if entry.nextRetry and now()<entry.nextRetry and not api.closing then return end
  entry.running=true; entry.workStartedAt=now()
  publish(entry)
  task.spawn(function()
   while #entry.queue>0 do
    local operation=entry.queue[1]
    local data,receipt,err=repository:commit(entry.player.UserId,operation,api.deadline)
    if not data then
     entry.failed=true; entry.failure=Repository.errorInfo(err); entry.nextRetry=now()+Config.RetryInterval
     warn("Paddle Up progression transaction failed for "..entry.player.UserId..": "..tostring(err))
     break
    end
    entry.data=data; entry.failed=false; entry.failure=nil; entry.nextRetry=nil; entry.lastVerified=now()
    table.remove(entry.queue,1)
    if operation.kind=="Load" then entry.loading=false end
    local notice
    if operation.kind~="Load" then
     local kind=receipt and receipt.kind
     notice={amount=receipt and receipt.amount or 0,weekly=receipt and receipt.weekly or 0,
      levelUp=receipt and receipt.levelAfter and receipt.levelBefore and receipt.levelAfter>receipt.levelBefore or false,
      level=data.level,
      message=kind=="ZoneCooldown" and "Time-zone changes are limited to once every "..Config.TimeZoneChangeDays.." days."
       or kind=="ZoneUnchanged" and "That time zone is already selected."
       or operation.kind=="SetTimeZone" and (data.pendingTimeZone and "Time-zone change saved for your next daily reset." or "Time zone saved.")
       or kind=="Already" and "Already checked in for this reward day!" or kind=="Reset" and "A new day started in your selected time zone. Please check in again."
       or kind=="Expired" and "This reward request expired." or operation.kind=="CheckIn" and "Checked in! Your daily XP boost is active."
       or receipt and receipt.amount==0 and "Daily gameplay XP limit reached." or nil}
    end
    publish(entry,notice)
   end
   entry.running=false; entry.workStartedAt=nil
   if entry.player.Parent==Players then publish(entry)
   elseif #entry.queue==0 then api.entries[entry.player]=nil end
  end)
 end
 local function load(entry)
  if entry.loading then startWorker(entry); return end
  entry.loading=true
  if not enqueue(entry,{kind="Load",id=guid(),at=now()}) then entry.loading=false end
 end
 local function add(player)
  if api.closing or api.entries[player] then return end
  local entry={player=player,queue={},running=false,failed=false,requests={},lastPrompt=-math.huge,
   lastRetry=-math.huge,revision=0,ackId=0,openId=0}
  api.entries[player]=entry; player:SetAttribute("XPDataReady",false)
  load(entry)
 end
 function api:award(player,reward,eventId)
  if self.closing or not Config.Rewards[reward] then return false end
  local entry=self.entries[player]
  -- No optimistic rewards or replacement defaults when loading/validation fails.
  if not entry or not entry.data or entry.failed or player.Parent~=Players then return false end
  local earnedAt=now()
  local zone=Rules.zone(entry.data,earnedAt)
  local today=Rules.day(earnedAt,zone)
  if (entry.data.budgets[tostring(today)] or 0)>=Config.GameplayDailyCap then
   if entry.capNoticeDay~=today then
    entry.capNoticeDay=today; publish(entry,{message="Daily gameplay XP limit reached. More XP is available after your next daily reset."})
   end
   return false
  end
  return enqueue(entry,{kind="Gameplay",id=eventId,reward=reward,at=earnedAt,zone=zone})
 end
 connect(Players.PlayerAdded,add)
 connect(Players.PlayerRemoving,function(player)
  local entry=api.entries[player]
  if not entry then return end
  entry.openUntil=nil; entry.departedAt=now(); startWorker(entry)
  if not entry.running and #entry.queue==0 then api.entries[player]=nil end
 end)
 connect(prompt.Triggered,function(player)
  local entry=api.entries[player]
  if api.closing or not entry or not near(player) or now()-entry.lastPrompt<Config.RemoteCooldown then return end
  if entry.openUntil and now()<entry.openUntil then return end
  entry.openId+=1
  entry.lastPrompt=now(); entry.openUntil=now()+Config.InteractionSeconds
  publish(entry,nil,true)
  -- Refresh periodically; repeated prompt interactions cannot consume a write per opening.
  if not entry.lastVerified or now()-entry.lastVerified>=Config.RefreshSeconds then load(entry) end
 end)
 connect(remote.OnServerEvent,function(player,action,requestId,openId,value)
  local entry=api.entries[player]
  if api.closing or not entry or type(action)~="string" then return end
  if requestId~=nil then
   if type(requestId)~="number" or requestId%1~=0 or requestId<=entry.ackId or requestId>1e9 then return end
   entry.ackId=requestId
  end
  if action=="Close" then
   if openId==entry.openId then entry.openUntil=nil end
   return
  end
  if action~="Sync" and action~="Claim" and action~="Retry" and action~="SetTimeZone" then return end
  if now()-(entry.requests[action] or -math.huge)<Config.RemoteCooldown then publish(entry); return end
  entry.requests[action]=now()
  if action=="Sync" then
   if not entry.data then load(entry) end
   publish(entry)
  elseif action=="Retry" then
   if now()-entry.lastRetry<Config.ManualRetrySeconds or entry.running then publish(entry); return end
   entry.lastRetry=now(); entry.nextRetry=nil
   if #entry.queue>0 then startWorker(entry,true)
   elseif not entry.data or entry.failed then load(entry)
   end
   publish(entry)
  elseif action=="SetTimeZone" then
   if openId~=entry.openId then publish(entry); return end
   if not entry.data or entry.failed or not entry.openUntil or now()>entry.openUntil or not near(player) then publish(entry); return end
   if not Rules.validTimeZone(value) then publish(entry,{message="Select a supported time zone."}); return end
   for _,operation in ipairs(entry.queue) do if operation.kind=="SetTimeZone" then return end end
   if enqueue(entry,{kind="SetTimeZone",id=guid(),at=now(),zone=value}) then publish(entry) end
  elseif action=="Claim" then
   if openId~=nil and openId~=entry.openId then publish(entry); return end
   if not entry.openUntil or now()>entry.openUntil or not near(player) then
    publish(entry,{message="Return to the check-in desk and press E."}); return
   end
   if not entry.data or entry.failed then publish(entry); return end
   local claimAt=now()
   if not Rules.canClaim(entry.data,claimAt) then
    publish(entry,{message="Already checked in today!"}); return
   end
   -- One queued claim at a time, including failures with an unknown backend outcome.
   for _,operation in ipairs(entry.queue) do if operation.kind=="CheckIn" then return end end
   if enqueue(entry,{kind="CheckIn",id=guid(),at=claimAt}) then publish(entry) end
  end
 end)
 local maintenance=task.spawn(function()
  while not api.closing do
   task.wait(5)
   for player,entry in pairs(api.entries) do
    if entry.departedAt and now()-entry.departedAt>Config.ShutdownSeconds and not entry.running then
     if #entry.queue>0 then warn("Unconfirmed progression operation abandoned after disconnect for "..player.UserId) end
     api.entries[player]=nil
    else
     startWorker(entry)
     -- Recompute midnight expiry even when no gameplay or UI requests occur.
     if entry.data and player.Parent==Players then publish(entry) end
    end
   end
  end
 end)
 game:BindToClose(function()
  if api.closing then return end
  api.closing=true; api.deadline=now()+Config.ShutdownSeconds; prompt.Enabled=false
  for _,connection in ipairs(api.connections) do connection:Disconnect() end
  pcall(task.cancel,maintenance)
  repeat
   local pending=false
   for _,entry in pairs(api.entries) do
    startWorker(entry)
    if entry.running or #entry.queue>0 and (not entry.failure or entry.failure.retryable) then pending=true end
   end
   if not pending then break end
   task.wait(0.25)
  until now()>=api.deadline
  for player,entry in pairs(api.entries) do
   if #entry.queue>0 then warn("Shutdown ended with an unconfirmed progression operation for "..player.UserId) end
  end
 end)
 for _,player in ipairs(Players:GetPlayers()) do add(player) end
 return api
end
return Service
