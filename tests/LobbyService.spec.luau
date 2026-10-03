-- makeService injects fake Players and task scheduling into the service module.
return function(makeService)
 local players={}
 for id=1,6 do
  local p={UserId=id,DisplayName="Player "..id,Name="Player"..id,attributes={}}
  function p:SetAttribute(key,value) self.attributes[key]=value end
  players[id]=p
 end
 local provider={}
 function provider:GetPlayers() return players end
 function provider:GetPlayerByUserId(id) return players[id] end
 local pending={}
 local Service=makeService(provider,{delay=function(_,callback) table.insert(pending,callback) end})
 local handler
 local updates={}
 local remote={OnServerEvent={Connect=function(_,callback) handler=callback end}}
 function remote:FireClient(p,data) updates[p.UserId]=data end
 local network={FindFirstChild=function() return remote end}
 local starts,stops=0,0
 local service=Service.new(network,{
  score=function() return {0,0} end,
  start=function() starts+=1 end,
  stop=function() stops+=1 end,
 })
 for _,p in ipairs(players) do service:add(p) end
 handler(players[1],"Refresh")
 handler(players[1],"Queue","1v1")
 assert(updates[1].queue=="1v1","Refresh must not block the first queue request")
 assert(starts==0,"One singles player must wait for an opponent")
 handler(players[2],"Queue","1v1")
 assert(starts==1,"A full singles queue must start exactly one match")
 assert(updates[1].status=="Playing" and updates[2].status=="Playing","Match must replicate playing status")
 assert(updates[1].queue==nil and updates[2].queue==nil,"Matched players must leave the queue")
 local singlesId=service.model.players[1].matchId
 for id=3,6 do handler(players[id],"Queue","2v2") end
 local doublesId=service.model.players[3].matchId
 assert(starts==2 and singlesId~=doublesId,"Singles and doubles must start simultaneously")
 assert(updates[1].match.id==singlesId and updates[3].match.id==doublesId,"Each roster must receive its own match")
 assert(updates[1].activeCounts["1v1"]==1 and updates[1].activeCounts["2v2"]==1,"Both active pools must replicate")
 service:finish(service.model.players[1].matchId,"Finished")
 assert(stops==1 and updates[1].status=="Lobby","Finishing must return players to the lobby")
 assert(updates[3].status=="Playing" and service.model:match(3).id==doublesId,"Finishing singles must leave doubles playing")
 for _,callback in ipairs(pending) do callback() end
 assert(starts==2,"Completed players must not be automatically requeued")
 service.lastRequest[1]=nil
 handler(players[1],"Practice","Normal")
 assert(starts==3 and service.model:match(1).bot,"Solo practice must start with a bot alongside doubles")
 service:remove(players[1])
 assert(stops==2 and service.model.players[1]==nil,"Disconnect must end the match and remove queue state")
 assert(service.model:match(3).id==doublesId,"Practice disconnect must leave doubles running")
 return "Lobby synchronization, simultaneous matches, roster routing, isolated finish, practice and disconnect checks passed"
end
