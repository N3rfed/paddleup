return function(Practice)
 local p=Practice.new()
 assert(p.difficulty=="Normal" and not p.paused)
 local easy,normal,hard=Practice.Profiles.Easy,Practice.Profiles.Normal,Practice.Profiles.Hard
 assert(easy.reactionMin>normal.reactionMin and normal.reactionMin>hard.reactionMin)
 assert(easy.move<normal.move and normal.move<hard.move)
 assert(easy.errorX>normal.errorX and normal.errorX>hard.errorX)
 assert(easy.speed<normal.speed and normal.speed<hard.speed)
 assert(easy.miss>normal.miss and normal.miss>hard.miss)
 assert(not p:step("serve-1",0))
 assert(p.remaining==3)
 assert(not p:step("serve-1",0.8))
 local remaining=p.remaining
 local revision=p.revision
 assert(not p:select("Normal") and p.remaining==remaining and p.revision==revision)
 assert(not p:select("Invalid"))
 assert(p:setPaused(true))
 assert(p:snapshot().countdown==nil)
 for _=1,100 do assert(not p:step("serve-1",10)) end
 assert(p.remaining==remaining)
 assert(not p:setPaused(true))
 assert(p:setPaused(false))
 assert(not p:step("serve-1",remaining-0.01))
 assert(p:step("serve-1",0.02))
 assert(p:snapshot().serve)
 for _=1,100 do assert(not p:step("serve-1",1),"A serve may fire only once") end
 p:step(nil,0)
 assert(not p:step("serve-2",0) and p.remaining==3)
 assert(not p:step("serve-3",1) and p.remaining==3,"A new server invalidates the old countdown")
 assert(p:select("Hard") and p.remaining==nil and p.key==nil)
 assert(p.difficulty=="Hard")
 for _=1,30 do
  p:step("serve-4",0)
  assert(p:setPaused(true))
  local saved=p.remaining
  assert(not p:step("serve-4",100))
  assert(p.remaining==saved)
  assert(p:setPaused(false))
 end
 p:reset()
 assert(p.difficulty=="Normal" and p.remaining==nil and not p.paused)
 assert(p:select("Easy"))
 assert(p:select("Normal"))
 return "Difficulty, same-selection preservation, countdown cancellation, pause/resume and duplicate-serve tests passed"
end
