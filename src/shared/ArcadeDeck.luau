-- Shared powers; Chaos stacks charges and uses a shorter activation cooldown.
local Deck={SIZE=3,COOLDOWN=18,HAZARD_LIFETIME=8,HAZARD_RADIUS=5,
 SMALL_PADDLE_SECONDS=8,GLOW_SECONDS=8,PICKLE_RECOVERY=1,SPEED_SWING_SCALE=0.75}
Deck.CHAOS_COOLDOWN=5
Deck.CHAOS_MAX_LEVEL=5
Deck.cards={
 {id="speedCleats",name="Speed Cleats",art="cleats",description="Move 40% faster for 8 seconds. Swing cooldown is shorter.",duration=8},
 {id="bigPaddle",name="Big Paddle",art="paddle",description="1.75x paddle size and hit range for 10 seconds.",duration=10},
 {id="dropPickles",name="Drop Pickles",art="pickles",description="Drop pickle hazards that trip opponents into a slide and recovery.",duration=8},
 {id="heatseeker",name="Heatseeker",art="heatseeker",description="Your next return curves toward the deepest open baseline corner.",duration=0},
 {id="slipStream",name="Slip Stream",art="slipstream",description="Create a slick zone on the opposing side. Contact causes a 1-second slide.",duration=8},
 {id="smallPaddle",name="Small Paddle",art="smallpaddle",description="Shrink opposing paddles and hit range to half size.",duration=8},
 {id="glowBall",name="Glow Ball",art="glowball",description="Dim the arena and illuminate the ball for easier tracking.",duration=8},
 {id="zeroG",name="Zero-G Pulse",art="zerog",description="Reduce gravity by 60% for 8 seconds.",duration=8},
}
local blurbs={speedCleats="Move much faster",bigPaddle="Reach farther shots",dropPickles="Trip your opponents",
 heatseeker="Curve toward corners",slipStream="Make opponents slide",smallPaddle="Shrink opponent paddles",
 glowBall="Light the ball",zeroG="Slow ball gravity"}
for _,card in ipairs(Deck.cards) do card.blurb=blurbs[card.id] end
function Deck.find(id)
 for _,card in ipairs(Deck.cards) do if card.id==id then return card end end
end
-- Match-long versions of the same eight powers. These values also drive card copy.
function Deck.chaosValues(levels)
 local function level(id) return math.clamp((levels or {})[id] or 0,0,Deck.CHAOS_MAX_LEVEL) end
 local speed,paddle,pickles,heat,slip,small,glow,gravity=level("speedCleats"),level("bigPaddle"),level("dropPickles"),level("heatseeker"),level("slipStream"),level("smallPaddle"),level("glowBall"),level("zeroG")
 return {speed=1+0.15*speed,swing=1-0.04*speed,reach=1+0.2*paddle,
  pickleInterval=14-1.5*pickles,pickleCount=1+math.floor(math.max(0,pickles-1)/2),
  heatInterval=14-1.5*heat,slipInterval=16-2*slip,slipSize=6+2*slip,
  shrink=1-0.06*small,lightRange=14+5*glow,lightBrightness=3+glow,
  gravity=gravity>0 and 0.85-0.05*gravity or 1}
end
function Deck.chaosCard(id,previousLevel)
 local base=Deck.find(id)
 if not base then return nil end
 local previous=math.clamp(previousLevel or 0,0,Deck.CHAOS_MAX_LEVEL)
 local level=math.min(Deck.CHAOS_MAX_LEVEL,previous+1)
 local values=Deck.chaosValues({[id]=level})
 local descriptions={
  speedCleats=string.format("Move %d%% faster all match. Swing cooldown is %d%% shorter.",level*15,level*4),
  bigPaddle=string.format("Paddle size and hit range stay %d%% larger all match.",level*20),
  dropPickles=string.format("Automatically drop %d pickle hazard%s every %.1fs of live play.",values.pickleCount,values.pickleCount==1 and "" or "s",values.pickleInterval),
  heatseeker=string.format("Your next return homes toward an open corner. Recharges every %.1fs.",values.heatInterval),
  slipStream=string.format("Automatically create a %d-stud slick zone every %ds of live play.",values.slipSize,values.slipInterval),
  smallPaddle=string.format("Opponents' paddle size and hit range stay %d%% smaller all match.",level*6),
  glowBall=string.format("Keep the ball illuminated all match. Light range: %d studs; brightness: %d.",values.lightRange,values.lightBrightness),
  zeroG=string.format("Reduce gravity for the whole court by %d%% all match. Strongest upgrade wins.",math.floor((1-values.gravity)*100+0.5)),
 }
 return {id=id,name=base.name,art=base.art,description=descriptions[id],chaosUpgrade=true,
  level=level,previousLevel=previous,tier=math.ceil(level/2),
  levelLabel=previous==0 and "NEW  /  LEVEL 1" or ("LEVEL "..previous.."  >  "..level)}
end
function Deck.validate(ids)
 if type(ids)~="table" then return nil end
 local copy,seen={},{}
 local count=0
 for key in pairs(ids) do
  if type(key)~="number" or key%1~=0 or key<1 or key>Deck.SIZE then return nil end
  count+=1
 end
 if count~=Deck.SIZE then return nil end
 for index=1,Deck.SIZE do
  local id=ids[index]
  if type(id)~="string" or not Deck.find(id) or seen[id] then return nil end
  seen[id]=true; copy[index]=id
 end
 return copy
end
return Deck
