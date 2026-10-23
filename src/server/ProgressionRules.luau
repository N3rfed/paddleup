-- Pure server-time calendar, XP, and idempotent transitions; IANA data stays on the server.
local Config=require(script.Parent:WaitForChild("ProgressionConfig"))
local Zones=require(script.Parent:WaitForChild("TimeZones"))
local Rules={}
local function integer(value,minimum,maximum)
 return type(value)=="number" and value==value and value%1==0 and value>=minimum and value<=maximum
end
function Rules.day(timestamp,zone) return Zones.day(timestamp,zone or "UTC") end
function Rules.required(level)
 local n=level-1
 return Config.BaseXP+Config.LinearXP*n+Config.QuadraticXP*n*n
end
function Rules.new()
 return {version=Config.SchemaVersion,level=1,xp=0,totalXP=0,lastDay=-1,streak=0,
  multiplierUntil=0,weeklyAwards=0,lastWeeklyDay=-1,history={},budgets={},receipts={},
  timeZone=Config.DefaultTimeZone,claims={},zoneChangedAt=0}
end
function Rules.validate(data)
 assert(type(data)=="table" and (data.version==1 or data.version==Config.SchemaVersion),"Unsupported progression data")
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
 if data.version==Config.SchemaVersion then
  assert(Zones.valid(data.timeZone) and type(data.claims)=="table","Invalid time-zone data")
  assert(type(data.zoneChangedAt)=="number" and data.zoneChangedAt>=0 and data.zoneChangedAt<1e12,"Invalid zone change date")
  if data.pendingTimeZone then
   assert(Zones.valid(data.pendingTimeZone) and type(data.zoneEffectiveAt)=="number" and data.zoneEffectiveAt>=0 and data.zoneEffectiveAt<1e12,"Invalid pending time zone")
  end
  if data.lastClaimAt then assert(type(data.lastClaimAt)=="number" and data.lastClaimAt>=0 and type(data.lastClaimEnd)=="number" and data.lastClaimEnd>data.lastClaimAt and data.lastClaimEnd<1e12,"Invalid claim window") end
  for id,claim in pairs(data.claims) do
   assert(type(id)=="string" and type(claim)=="table" and type(claim.at)=="number"
    and claim.at>=0 and type(claim.expires)=="number" and claim.expires>claim.at and claim.expires<1e12 and Zones.valid(claim.zone)
    and integer(claim.day,0,1000000),"Invalid local check-in history")
  end
 end
 return data
end
local function copy(data)
 local result=table.clone(Rules.validate(data))
 for _,name in ipairs({"history","budgets","receipts","claims"}) do result[name]=table.clone(data[name] or {}) end
 if data.version==1 then
  result.version=Config.SchemaVersion; result.timeZone=Config.DefaultTimeZone; result.zoneChangedAt=0
  for day,entry in pairs(data.history) do
   local number=tonumber(day)
   result.claims["legacy:"..day]={at=entry.at,expires=(number+1)*86400,zone="UTC",day=number,
    weekly=data.lastWeeklyDay==number}
   if not result.lastClaimAt or entry.at>result.lastClaimAt then result.lastClaimAt=entry.at end
  end
  if not result.lastClaimAt and data.lastDay>=0 then result.lastClaimAt=data.lastDay*86400 end
  if result.lastClaimAt then result.lastClaimEnd=math.max(data.multiplierUntil,(data.lastDay+1)*86400) end
 end
 return result
end
function Rules.validTimeZone(id) return Zones.valid(id) end
function Rules.zone(data,now)
 if data.pendingTimeZone and now>=data.zoneEffectiveAt then return data.pendingTimeZone end
 return data.timeZone or Config.DefaultTimeZone
end
local function calendar(data,now) return Zones.calendar(now,Rules.zone(data,now)) end
local function nextClaim(data,zone)
 if not data.lastClaimAt then return 0 end
 local nextDay=Zones.day(data.lastClaimAt,zone)+1
 return math.max(data.lastClaimEnd,Zones.dayStart(nextDay,zone))
end
function Rules.canClaim(data,now)
 data=copy(data)
 local zone=Rules.zone(data,now)
 return now>=nextClaim(data,zone)
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
 if data.pendingTimeZone and now>=data.zoneEffectiveAt then
  data.timeZone=data.pendingTimeZone; data.pendingTimeZone=nil; data.zoneEffectiveAt=nil
 end
 local current=calendar(data,now)
 if operation.kind=="Load" then return data,{kind="Load",amount=0} end
 assert(type(operation.id)=="string" and #operation.id<=100,"Invalid operation ID")
 assert(type(operation.at)=="number" and operation.at<=now+5,"Invalid reward time")
 if data.receipts[operation.id] then return data,data.receipts[operation.id] end
 if now-operation.at>Config.ReceiptSeconds then return data,{kind="Expired",amount=0} end
 local today,earnedDay=current.day,Rules.day(operation.at,current.zone)
 local receipt={at=operation.at,kind=operation.kind,amount=0,weekly=0,levelBefore=data.level}
 if operation.kind=="SetTimeZone" then
  assert(Zones.valid(operation.zone),"Invalid time zone")
  Zones.calendar(now,operation.zone)
  if data.pendingTimeZone==operation.zone or not data.pendingTimeZone and data.timeZone==operation.zone then return data,{kind="ZoneUnchanged",amount=0} end
  if data.zoneChangedAt>0 and now<data.zoneChangedAt+Config.TimeZoneChangeDays*86400 then return data,{kind="ZoneCooldown",amount=0} end
  if data.lastClaimAt then
   data.pendingTimeZone=operation.zone; data.zoneEffectiveAt=current.nextReset
  else
   data.timeZone=operation.zone
  end
  data.zoneChangedAt=now
 elseif operation.kind=="CheckIn" then
  -- The date is derived from the stored zone and server timestamp, never a client date.
  if earnedDay~=today then return data,{kind="Reset",amount=0} end
  if not Rules.canClaim(data,now) then return data,{kind="Already",amount=0} end
  local expected=data.lastClaimAt and Zones.day(nextClaim(data,current.zone),current.zone) or today
  data.streak=data.lastClaimAt and today==expected and data.streak+1 or 1
  data.lastDay=today; data.multiplierUntil=current.nextReset
  data.lastClaimAt=now; data.lastClaimEnd=current.nextReset
  data.claims[operation.id]={at=now,expires=current.nextReset,zone=current.zone,day=today,weekly=false}
  local daily=Config.DailyXP*(Config.MultiplyDailyReward and Config.DailyMultiplier or 1)
  receipt.amount=grant(data,daily)
  if data.streak%Config.StreakDays==0 and data.lastWeeklyDay~=today then
   -- Daily XP is granted first. Use the level at the instant the weekly bonus is granted.
   local bonus=math.floor(Rules.required(data.level)*Config.WeeklyFraction)
   if Config.MultiplyWeeklyReward then bonus*=Config.DailyMultiplier end
   receipt.weekly=grant(data,bonus); receipt.amount+=receipt.weekly
   data.lastWeeklyDay=today; data.weeklyAwards+=1
   data.claims[operation.id].weekly=true
  end
 elseif operation.kind=="Gameplay" then
  local base=assert(Config.Rewards[operation.reward],"Unknown gameplay reward")
  local active=false
  for _,claim in pairs(data.claims) do
   if operation.at>=claim.at and operation.at<claim.expires then active=true; break end
  end
  local multiplier=active and Config.DailyMultiplier or 1
  earnedDay=Rules.day(operation.at,operation.zone or current.zone)
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
 for id,claim in pairs(data.claims) do if claim.at<now-Config.HistoryDays*86400 then data.claims[id]=nil end end
 for key in pairs(data.budgets) do if tonumber(key)<today-3 then data.budgets[key]=nil end end
 return data,receipt
end
function Rules.snapshot(data,now)
 data=copy(data)
 local current=calendar(data,now)
 local today=current.day
 local eligibleAt=nextClaim(data,current.zone)
 local streak=data.lastClaimAt and today<=Zones.day(eligibleAt,current.zone) and data.streak or 0
 local completed,active,weeklyToday={},false,false
 for _,claim in pairs(data.claims) do
  local day=Zones.day(claim.at,current.zone)
  if claim.at<=now then completed[day]=true end
  if claim.at<=now and now<claim.expires then active=true end
  if claim.weekly and day==today then weeklyToday=true end
 end
 local monday=today-(today+3)%7
 local days={}
 for offset=0,6 do
  local day=monday+offset
  local done=day<=today and completed[day]==true
  table.insert(days,{date=os.date("!%Y-%m-%d",day*86400),label=os.date("!%a",day*86400),
   shortDate=os.date("!%b %d",day*86400),today=day==today,
   status=done and (day==today and "TodayDone" or "Done") or day<today and "Missed" or day==today and "Available" or "Upcoming"})
 end
 return {ready=true,level=data.level,xp=data.xp,required=Rules.required(data.level),totalXP=data.totalXP,
  streak=streak,cycle=streak>0 and (streak-1)%Config.StreakDays+1 or 0,weeklyAwards=data.weeklyAwards,
  weeklyCompletedToday=weeklyToday,
  weeklyPreview=math.floor(Rules.required(data.level)*Config.WeeklyFraction),weeklyPercent=Config.WeeklyFraction*100,
  dailyXP=Config.DailyXP,configuredMultiplier=Config.DailyMultiplier,
  dailyBonusPercent=math.floor((Config.DailyMultiplier-1)*100+0.5),
  multiplier=active and Config.DailyMultiplier or 1,multiplierUntil=data.multiplierUntil,
  todayDate=current.date,todayLabel=current.label,timeZone=current.zone,timeZones=Zones.options(),
  pendingTimeZone=data.pendingTimeZone and now<data.zoneEffectiveAt and data.pendingTimeZone or nil,
  zoneChangeDays=Config.TimeZoneChangeDays,
  zoneEffectiveAt=data.zoneEffectiveAt,zoneChangeAvailableAt=data.zoneChangedAt>0 and data.zoneChangedAt+Config.TimeZoneChangeDays*86400 or 0,
  eligibleAt=eligibleAt,canCheckIn=now>=eligibleAt,
  checkedIn=completed[today]==true,nextReset=current.nextReset,serverNow=now,days=days,
  resetLabel=os.date("!%b %d, %H:%M",current.nextReset+Zones.offset(current.nextReset,current.zone)).." / "..current.zone}
end
return Rules
