return function(Augments)
 local low={NextNumber=function() return 0 end}
 local mid={NextNumber=function() return 0.6 end}
 local high={NextNumber=function() return 0.9 end}
 assert(Augments.roll(low)==1 and Augments.roll(mid)==2 and Augments.roll(high)==3,"Rarity boundaries")
 local random=Random.new(741)
 for _=1,100 do
  local tier,offers=Augments.deal(random,4)
  local seen={}
  for _,offer in ipairs(offers) do
   assert(#offer==3,"Three cards per player")
   for _,card in ipairs(offer) do
    assert(card.tier==tier,"Everyone receives the same rarity")
    assert(not seen[card.id],"Offers must be different across all four players")
    seen[card.id]=true
   end
  end
  local stats={}
  assert(not Augments.choose(offers[1],offers[2][1].id,stats),"Reject another player's card")
  assert(not Augments.choose(nil,offers[1][1].id,stats),"Reject a consumed offer")
  assert(not Augments.choose(offers[1],{},stats),"Reject malformed selection")
  assert(next(stats)==nil,"Invalid selection cannot grant stats")
  local card=Augments.choose(offers[1],offers[1][1].id,stats)
  assert(stats[card.stat]==card.amount,"Selected card applies its effect")
  for _=1,100 do Augments.choose(offers[1],card.id,stats) end
  assert(stats[card.stat]==Augments.caps[card.stat],"Stacking is capped")
 end
 return "Augment rarity, disjoint multiplayer offers, validation, effects and caps passed"
end
