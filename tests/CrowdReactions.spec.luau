return function(Crowd)
 local now=0
 local crowd=Crowd.new(function() return now end)
 assert(not crowd:streakEnded(4),"Small streaks should not trigger a gasp")
 assert(crowd:streakEnded(5),"A five-hit streak ending should trigger a gasp")
 assert(not crowd:streakEnded(10),"Simultaneous streak endings should not overlap")
 now=4
 assert(not crowd:shot(1,true),"An ordinary lob should not trigger a gasp")
 for _=1,3 do assert(not crowd:shot(1.3,false)) end
 assert(crowd:shot(1.2,true),"A slower lob after a fast rally should trigger a gasp")
 assert(not crowd:shot(1.2,true),"Consecutive lobs should not repeat the gasp")
 now=8
 for _=1,3 do crowd:shot(1.6,false) end
 crowd:reset()
 assert(not crowd:shot(1,true),"A new rally must not inherit fast-hit history")
 for _=1,3 do crowd:shot(1.6,false) end
 crowd:shot(1,false)
 assert(not crowd:shot(1,true),"A slow exchange must interrupt the fast rally")
 assert(crowd:streakEnded(10))
 crowd:reset()
 assert(not crowd:streakEnded(10),"Rally resets must preserve the cooldown")
 now=12
 assert(crowd:streakEnded(5),"Gasps should resume after the cooldown")
 return "Big streak endings, fast-rally lobs, cooldown and rally reset checks passed"
end
