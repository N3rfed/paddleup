-- Server-only IANA offsets. Shift epoch seconds only for civil-date formatting, never client clocks.
local Data=require(script.Parent:WaitForChild("TimeZoneData"))
local Zones={version=Data.version,start=Data.start,finish=Data.finish}
local ids={}; for id in pairs(Data.zones) do table.insert(ids,id) end; table.sort(ids)
function Zones.valid(id) return type(id)=="string" and Data.zones[id]~=nil end
function Zones.options() return table.clone(ids) end
function Zones.offset(timestamp,id)
 assert(Zones.valid(id),"Invalid time zone")
 if id=="UTC" then return 0 end
 assert(timestamp>=Data.start and timestamp<Data.finish,"Time-zone data outside supported range; refresh IANA data")
 local segments=Data.zones[id]
 local low,high=1,#segments
 while low<high do
  local mid=math.ceil((low+high)/2)
  if segments[mid][1]<=timestamp then low=mid else high=mid-1 end
 end
 return segments[low][2]
end
function Zones.day(timestamp,id) return math.floor((timestamp+Zones.offset(timestamp,id))/86400) end
function Zones.dayStart(day,id)
 if id=="UTC" then return day*86400 end
 assert(Zones.valid(id),"Invalid time zone")
 local segments=Data.zones[id]
 local earliest
 for index,segment in ipairs(segments) do
  local begins,offset=segment[1],segment[2]
  local ends=segments[index+1] and segments[index+1][1] or Data.finish
  -- Intersect this UTC offset segment with the requested civil day's interval.
  -- This handles skipped/repeated midnight and 23/25/23.5/24.5-hour DST days.
  local candidate=math.max(begins,day*86400-offset)
  if candidate<math.min(ends,(day+1)*86400-offset) then earliest=math.min(earliest or candidate,candidate) end
 end
 assert(earliest,"Time-zone date outside supported range; refresh IANA data")
 return earliest
end
function Zones.calendar(timestamp,id)
 local day=Zones.day(timestamp,id)
 local nextReset=Zones.dayStart(day+1,id)
 return {zone=id,day=day,start=Zones.dayStart(day,id),nextReset=nextReset,
  date=os.date("!%Y-%m-%d",day*86400),label=os.date("!%a, %b %d",day*86400),offset=Zones.offset(timestamp,id)}
end
return Zones
