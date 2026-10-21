return function(source)
 local first=assert(source:find("local function updateQueue()",1,true))
 local last=assert(source:find("queueRemote.OnServerEvent:Connect",first,true))
 local a,b={},{}
 local group={players={a,b},format="1V1",mode="Chaos",map="Moon",modifier="LowGravity"}
 local nextGroup=group
 local users={[a]={sessionAt=10},[b]={sessionAt=10}}
 local admitted,notifications={},{}
 local environment=setmetatable({users=users,courtMode=nil,
  matchmaking={update=function(_,available) assert(available); local result=nextGroup; nextGroup=nil; return result end},
  queueRemote={FireClient=function(_,player,data) notifications[player]=data.stage end},
  connectSession=function(player,format,mode,map,modifier)
   assert(format=="1V1" and mode=="Chaos" and map=="Moon" and modifier=="LowGravity","Winning settings reach the real admission entry point")
   assert(users[player].sessionAt==-math.huge and notifications[player]=="Cancelled")
   table.insert(admitted,player)
  end},{__index=getfenv()})
 local loader=assert(loadstring(source:sub(first,last-1).."\nreturn updateQueue")); setfenv(loader,environment)
 local update=loader()
 update(); update()
 assert(#admitted==2 and admitted[1]==a and admitted[2]==b,"The completed reveal admits the entire group exactly once")
 local heartbeat=assert(source:find("RunService.Heartbeat:Connect(function(dt)",1,true))
 assert(source:find("updateQueue()",heartbeat,true),"Heartbeat advances voting without a start request")
 return "Automatic result admission, shared winning settings, roster order, and heartbeat progression passed"
end
