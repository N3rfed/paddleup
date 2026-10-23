-- Write-through transactions merge with the latest record on every server. No cached SetAsync saves.
local Config=require(script.Parent:WaitForChild("ProgressionConfig"))
local Rules=require(script.Parent:WaitForChild("ProgressionRules"))
local Repository={}
Repository.__index=Repository
function Repository.new(store,clock,sleep)
 return setmetatable({store=store,clock=clock or function() return DateTime.now().UnixTimestampMillis/1000 end,
  sleep=sleep or task.wait},Repository)
end
function Repository.errorInfo(err)
 local message=tostring(err)
 if message:find("StudioAccessToApisNotAllowed",1,true) or message:find("API access is not enabled",1,true) then
  return {code="StudioAPI",retryable=false,message="Studio API access is disabled. Enable Studio Access to API Services in a published test experience, then Retry."}
 end
 if message:find("Time-zone",1,true) then
  return {code="TimeZoneData",retryable=false,message="Time-zone data needs an update. No progress was changed. Please contact the game team."}
 end
 if message:find("Unsupported progression data",1,true) or message:find("Invalid ",1,true) then
  return {code="InvalidData",retryable=false,message="Your saved progression could not be validated. No progress was changed. Retry or contact the game team."}
 end
 return {code="Unavailable",retryable=true,message="Couldn't load or save check-in data. Please Retry."}
end
function Repository:commit(userId,operation,deadline)
 local lastError
 for attempt=1,Config.RetryAttempts do
  if deadline and self.clock()>=deadline then break end
  local outcome
  local ok,result=pcall(function()
   return self.store:UpdateAsync("player_"..userId,function(current)
    local updated,receipt=Rules.apply(current,operation,self.clock())
    outcome=receipt
    return updated
   end)
  end)
  if ok and result~=nil then
   local valid,err=pcall(Rules.validate,result)
   if valid then return result,result.receipts[operation.id] or outcome end
   lastError=err
  else lastError=result end
  if not Repository.errorInfo(lastError).retryable then break end
  if attempt<Config.RetryAttempts then
   local delay=Config.RetryBaseSeconds*2^(attempt-1)+math.random()*0.2
   if deadline and self.clock()+delay>=deadline then break end
   self.sleep(delay)
  end
 end
 return nil,nil,tostring(lastError or "Progression deadline reached")
end
return Repository
