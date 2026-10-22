-- Pure UTC calendar, XP, and idempotent reward transitions. No Roblox services.
local Config=require(script.Parent:WaitForChild("ProgressionConfig"))
local Rules={}
local function integer(value,minimum,maximum)
 return type(value)=="number" and value==value and value%1==0 and value>=minimum and value<=maximum
end
function Rules.day(timestamp) return math.floor(timestamp/86400) end
function Rules.required(level)
 local n=level-1
 return Config.BaseXP+Config.LinearXP*n+Config.QuadraticXP*n*n
end
function Rules.new()
 return {version=Config.SchemaVersion,level=1,xp=0,totalXP=0,lastDay=-1,streak=0,
  multiplierUntil=0,weeklyAwards=0,lastWeeklyDay=-1,history={},budgets={},receipts={}}
end
function Rules.validate(data)
 assert(type(data)=="table" and data.version==Config.SchemaVersion,"Unsupported progression data")
 assert(integer(data.level,1,100000) and integer(data.xp,0,Rules.required(data.level)-1),"Invalid XP or level")
 assert(integer(data.totalXP,data.xp,9007199254740991),"Invalid lifetime XP")
 assert(integer(data.lastDay,-1,1000000) and integer(data.streak,0,1000000),"Invalid check-in data")
 assert(type(data.multiplierUntil)=="number" and data.multiplierUntil>=0 and data.multiplierUntil<1e12,"Invalid multiplier")
 assert(integer(data.weeklyAwards,0,1000000) and integer(data.lastWeeklyDay,-1,1000000),"Invalid weekly data")
 assert(type(data.history)=="table" and type(data.budgets)=="table" and type(data.receipts)=="table","Invalid history")
 for key,entry in pairs(data.history) do
  assert(type(key)=="string" and integer(tonumber(key),0,1000000),"Invalid date")
  assert(type(entry)=="table" and type(entry.at)=="number" and entry.at>=0 and entry.at<1e12
   and Rules.day(entry.at)==tonumber(key)
   and type(entry.multiplier)=="number" and entry.multiplier>=1 and entry.multiplier<=100,"Invalid check-in history")
 end
 for key,value in pairs(data.budgets) do
  assert(type(key)=="string" and integer(tonumber(key),0,1000000) and integer(value,0,1000000000),"Invalid daily budget")
 end
 for key,receipt in pairs(data.receipts) do
  assert(type(key)=="string" and type(receipt)=="table" and type(receipt.at)=="number" and receipt.at>=0 and receipt.at<1e12
   and type(receipt.kind)=="string" and integer(receipt.amount,0,9007199254740991)
   and integer(receipt.weekly,0,9007199254740991),"Invalid receipt")
 end
 return data
end
local function copy(data)
 local result=table.clone(Rules.validate(data))
 for _,name in ipairs({"history","budgets","receipts"}) do result[name]=table.clone(data[name]) end
 return result
end
local function grant(data,amount)
 amount=math.max(0,math.floor(amount))
 data.totalXP+=amount; data.xp+=amount
 while data.xp>=Rules.required(data.level) do
  data.xp-=Rules.required(data.level); data.level+=1
 end
 return amount
end
function Rules.apply(saved,operation,now)
 local data=saved==nil and Rules.new() or copy(saved)
 if operation.kind=="Load" then return data,{kind="Load",amount=0} end
 assert(type(operation.id)=="string" and #operation.id<=100,"Invalid operation ID")
 assert(type(operation.at)=="number" and operation.at<=now+5,"Invalid reward time")
 if data.receipts[operation.id] then return data,data.receipts[operation.id] end
 if now-operation.at>Config.ReceiptSeconds then return data,{kind="Expired",amount=0} end
 local today,earnedDay=Rules.day(now),Rules.day(operation.at)
 local receipt={at=operation.at,kind=operation.kind,amount=0,weekly=0,levelBefore=data.level}
 if operation.kind=="CheckIn" then
  -- A queued claim must still belong to the current UTC date; never backfill a missed day.
  if earnedDay~=today then return data,{kind="Reset",amount=0} end
  if data.lastDay>=today then return data,{kind="Already",amount=0} end
  data.streak=data.lastDay==today-1 and data.streak+1 or 1
  data.lastDay=today; data.multiplierUntil=(today+1)*86400
  data.history[tostring(today)]={at=now,multiplier=Config.DailyMultiplier}
  local daily=Config.DailyXP*(Config.MultiplyDailyReward and Config.DailyMultiplier or 1)
  receipt.amount=grant(data,daily)
  if data.streak%Config.StreakDays==0 and data.lastWeeklyDay~=today then
   -- Daily XP is granted first. Use the level at the instant the weekly bonus is granted.
   local bonus=math.floor(Rules.required(data.level)*Config.WeeklyFraction)
   if Config.MultiplyWeeklyReward then bonus*=Config.DailyMultiplier end
   receipt.weekly=grant(data,bonus); receipt.amount+=receipt.weekly
   data.lastWeeklyDay=today; data.weeklyAwards+=1
  end
 elseif operation.kind=="Gameplay" then
  local base=assert(Config.Rewards[operation.reward],"Unknown gameplay reward")
  local check=data.history[tostring(earnedDay)]
  local multiplier=check and operation.at>=check.at and operation.at<(earnedDay+1)*86400 and Config.DailyMultiplier or 1
  local key=tostring(earnedDay)
  local available=math.max(0,Config.GameplayDailyCap-(data.budgets[key] or 0))
  if available==0 then return data,{kind="Capped",amount=0} end
  receipt.amount=grant(data,math.min(available,math.floor(base*multiplier)))
  data.budgets[key]=(data.budgets[key] or 0)+receipt.amount
 else error("Unknown progression operation") end
 receipt.levelAfter=data.level
 -- Retain every non-expired receipt. Never evict a live idempotency key to make room.
 local count=0
 for id,item in pairs(data.receipts) do
  if now-item.at>Config.ReceiptSeconds then data.receipts[id]=nil else count+=1 end
 end
 assert(count<Config.MaximumReceipts,"Progression receipt capacity reached")
 data.receipts[operation.id]=receipt
 for key in pairs(data.history) do if tonumber(key)<today-Config.HistoryDays then data.history[key]=nil end end
 for key in pairs(data.budgets) do if tonumber(key)<today-3 then data.budgets[key]=nil end end
 return data,receipt
end
function Rules.snapshot(data,now)
 Rules.validate(data)
 local today=Rules.day(now)
 local streak=data.lastDay>=today-1 and data.streak or 0
 local monday=today-(today+3)%7
 local days={}
 for offset=0,6 do
  local day=monday+offset
  local completed=data.history[tostring(day)]~=nil
  table.insert(days,{date=os.date("!%Y-%m-%d",day*86400),label=os.date("!%a",day*86400),
   shortDate=os.date("!%b %d",day*86400),today=day==today,
   status=completed and (day==today and "TodayDone" or "Done") or day<today and "Missed" or day==today and "Available" or "Upcoming"})
 end
 return {ready=true,level=data.level,xp=data.xp,required=Rules.required(data.level),totalXP=data.totalXP,
  streak=streak,cycle=streak>0 and (streak-1)%Config.StreakDays+1 or 0,weeklyAwards=data.weeklyAwards,
  weeklyCompletedToday=data.lastWeeklyDay==today,
  weeklyPreview=math.floor(Rules.required(data.level)*Config.WeeklyFraction),weeklyPercent=Config.WeeklyFraction*100,
  dailyXP=Config.DailyXP,configuredMultiplier=Config.DailyMultiplier,
  dailyBonusPercent=math.floor((Config.DailyMultiplier-1)*100+0.5),
  multiplier=data.multiplierUntil>now and data.history[tostring(today)] and Config.DailyMultiplier or 1,multiplierUntil=data.multiplierUntil,
  checkedIn=data.lastDay>=today,nextReset=(today+1)*86400,serverNow=now,days=days,
  resetLabel=os.date("!%b %d, %H:%M UTC",(today+1)*86400)}
end
return Rules
