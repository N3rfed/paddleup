return function(Powerups)
 local low={NextNumber=function() return 0 end}
 local mid={NextNumber=function() return 0.6 end}
 local high={NextNumber=function() return 0.9 end}
 assert(Powerups.roll(low)==1 and Powerups.roll(mid)==2 and Powerups.roll(high)==3,"Rarity boundaries")
 local random={seed=741}
 function random:NextNumber() self.seed=self.seed*16807%2147483647; return self.seed/2147483647 end
 function random:NextInteger(low,high) return low+math.floor(self:NextNumber()*(high-low+1)) end
 local counts={0,0,0}
 local all={}
 for _,card in ipairs(Powerups.catalog) do
  assert(not all[card.id],"Unique effect IDs")
  counts[card.tier]+=1; all[card.id]=true
 end
 assert(counts[1]==9 and counts[2]==10 and counts[3]==9,"Air Time joins the Gold catalog")
 assert(not Powerups.slowFall({},1,"Chaos"),"Normal jumps are the default")
 assert(Powerups.slowFall({airTime=true},1,"Chaos"),"Air Time grants slow fall")
 assert(not Powerups.slowFall({airTime=true},0,"Chaos"),"No powerup effect in the lobby")
 assert(not Powerups.slowFall({airTime=true},1,"Classic"),"Effect is exclusive to its powerup-based build")
 for pass=1,300 do
  local builds=pass%2==0 and {all,all,all,all} or nil
  local tier,offers=Powerups.deal(random,4,builds)
  local seen={}
  for _,offer in ipairs(offers) do
   assert(#offer==3,"Three cards per player")
   for _,card in ipairs(offer) do
    assert(card.tier==tier,"Shared rarity")
    assert(not seen[card.id],"Globally disjoint offers")
    assert(not builds or card.stat,"Owned unique effects are excluded")
    seen[card.id]=true
   end
  end
  local stats={}
  assert(not Powerups.choose(offers[1],offers[2][1].id,stats),"Reject another player's card")
  assert(not Powerups.choose(nil,offers[1][1].id,stats),"Reject a consumed offer")
  assert(not Powerups.choose(offers[1],{},stats),"Reject malformed selection")
  assert(next(stats)==nil,"Invalid selection cannot grant effects")
  local card=Powerups.choose(offers[1],offers[1][1].id,stats)
  for _=1,100 do Powerups.choose(offers[1],card.id,stats) end
  if card.stat then assert(stats[card.stat]==Powerups.caps[card.stat],"Stats remain capped")
  else assert(stats[card.id]==true,"Unique effects cannot stack") end
 end
 for _,card in ipairs(Powerups.catalog) do
  local build={}
  assert(Powerups.choose({card},card.id,build)==card and Powerups.has(build,card.id),"Every named effect is selectable")
 end
 return "Catalog, rarity, exhausted builds, multiplayer uniqueness, selection validation and caps passed"
end
