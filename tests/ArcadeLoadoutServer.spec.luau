-- Exercises the live server's pre-serve loadout phase with isolated players.
return function(source,Deck)
 local first=assert(source:find("local function updateDraft(now)",1,true))
 local last=assert(source:find("local botSlowUntil",first,true))
 local listenerFirst=assert(source:find("loadoutRemote.OnServerEvent:Connect",1,true))
 local listenerLast=assert(source:find("local function choosePowerup",listenerFirst,true))
 local chunk=assert(loadstring(source:sub(listenerFirst,listenerLast-1)..source:sub(first,last-1).."\nreturn updateDraft"))
 local attributes,events={},{}
 local function player(name)
  local p={name=name}
  function p:SetAttribute(key,value)
   attributes[self]=attributes[self] or {}; attributes[self][key]=value
  end
  return p
 end
 local a,b=player("A"),player("B")
 local users={[a]={side=1},[b]={side=-1}}
 local receive,clock
 local env=setmetatable({users=users,ArcadeDeck=Deck,loadoutPending=true,loadoutSerial=7,
  introUntil=10,draftDue=false,courtVariant="Arcade",os={clock=function() return clock or 10 end},
  loadoutRemote={OnServerEvent={Connect=function(_,fn) receive=fn end},FireClient=function(_,p,data) table.insert(events,{player=p,data=data}) end},
 },{__index=getfenv()})
 setfenv(chunk,env)
 local update=chunk()
 update(5)
 assert(#events==0 and env.loadoutPending,"Selection waits until the match intro finishes")
 update(10)
 assert(#events==2 and env.loadoutDeadline==55,"Each participant gets one 45-second selection phase")
 assert(attributes[a].PowerupDraftOpen and attributes[b].PowerupDraftOpen,"Gameplay stays blocked during selection")
 update(11)
 assert(#events==2,"Heartbeat must not reopen the picker")
 local ids={Deck.cards[1].id,Deck.cards[2].id,Deck.cards[3].id}
 receive(a,6,ids)
 assert(not users[a].arcadeDeck,"Stale selection tokens are rejected")
 receive(a,7,{ids[1],ids[1],ids[1]})
 assert(not users[a].arcadeDeck,"Duplicate powers are rejected")
 receive(a,7,ids)
 assert(Deck.validate(users[a].arcadeDeck),"Valid selection is accepted")
 local accepted=users[a].arcadeDeck
 receive(a,7,{ids[3],ids[2],ids[1]})
 assert(users[a].arcadeDeck==accepted,"Confirmed decks cannot be changed")
 update(12)
 assert(env.loadoutPending,"One ready player cannot start the match")
 receive(b,7,ids)
 update(13)
 assert(not env.loadoutPending and env.nextServe==14,"Everyone ready releases the first serve")
 assert(not attributes[a].PowerupDraftOpen and not attributes[b].PowerupDraftOpen)
 users[a].arcadeDeck=nil; users[b].arcadeDeck=nil
 env.loadoutPending=true; env.loadoutDeadline=nil
 update(20); update(65)
 assert(not env.loadoutPending and Deck.validate(users[a].arcadeDeck) and Deck.validate(users[b].arcadeDeck),"Timeout supplies valid defaults and releases the match")
 return "Post-intro loadouts, one-time offers, all-player readiness, input blocking and timeout defaults passed"
end
