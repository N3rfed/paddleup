-- Exercise the actual server draft and selection functions with isolated players.
return function(source,Arcade,Powerups)
 local chooseFirst=assert(source:find("local function choosePowerup(",1,true))
 local chooseLast=assert(source:find("connect(powerupRemote.OnServerEvent,",chooseFirst,true))
 local updateFirst=assert(source:find("local function updateDraft(now)",1,true))
 local updateLast=assert(source:find("local botSlowUntil",updateFirst,true))
 local chunk=assert(loadstring(source:sub(chooseFirst,chooseLast-1)..source:sub(updateFirst,updateLast-1).."\nreturn choosePowerup,updateDraft"))
 local a={UserId=1,SetAttribute=function() end}
 local b={UserId=2,SetAttribute=function() end}
 local users={[a]={side=1,powerups={}},[b]={side=-1,powerups={}}}
 local events={}
 local engine=Arcade.new(Random.new(487)); engine:reset()
 local env=setmetatable({Powerups=Powerups,users=users,loadoutPending=false,courtVariant="Chaos",
  draftDue=true,draftSerial=0,nextServe=0,introUntil=0,ball={live=false},
  powerupRandom=Random.new(487),practicePaused=function() return false end,
  powerupRemote={FireClient=function(_,p,data) table.insert(events,{player=p,data=data}) end},
  arcade=engine,
 },{__index=getfenv()})
 setfenv(chunk,env)
 local choose,update=chunk()
 update(10)
 assert(env.draft and env.draft.offers[a] and env.draft.offers[b])
 assert(events[1].data.sharedPowers==false,"Chaos uses permanent upgrades")
 local card=env.draft.offers[a][1]
 assert(card.chaosUpgrade and card.art and card.level==1,"Chaos uses the original powerup artwork and levels")
 choose(a,"not-an-offer")
 assert(next(engine:data(a).levels)==nil and env.draft.offers[a],"Invalid picks cannot mutate the build")
 choose(a,card.id)
 local total=engine:data(a).levels[card.id]
 assert(total==1 and not env.draft.offers[a],"First choice becomes a permanent level")
 local chosen=events[#events].data
 assert(chosen.kind=="chosen" and not chosen.sharedPowers and not chosen.slot and chosen.stats[card.id]==total,"Client receives build levels, not a Q/E charge")
 choose(a,card.id)
 assert(engine:data(a).levels[card.id]==total,"A consumed offer cannot be replayed")
 choose(b,env.draft.offers[b][1].id)
 update(11)
 assert(not env.draft and engine:data(a).levels[card.id]==total,"Closing the draft preserves upgrades")
 local nextCard=table.clone(card); nextCard.previousLevel=1
 env.draft={offers={[a]={nextCard}}}
 choose(a,card.id)
 assert(engine:data(a).levels[card.id]==2,"Repeated pick levels up the existing original power")
 engine:reset()
 assert(next(engine:data(a).levels)==nil,"Match reset clears levels")
 return "Server Chaos drafts use original powers, preserve levels, upgrade repeat picks, reject invalid/replayed picks and report build levels"
end
