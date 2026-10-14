-- One 9–3 comeback activation per match. Side 1 is score[1], side -1 score[2].
local Comeback={MOVE=1.15,HIT=1.15}
function Comeback.new() return {side=0,used=false} end
function Comeback.update(state,score,finished)
 if finished then state.side=0; return end
 if state.side~=0 then
  local own=state.side==1 and 1 or 2
  if score[own]>=score[3-own] then state.side=0 end
 elseif not state.used then
  if score[1]==9 and score[2]==3 then state.side=-1; state.used=true
  elseif score[2]==9 and score[1]==3 then state.side=1; state.used=true end
 end
end
function Comeback.active(state,side) return side~=0 and state.side==side end
return Comeback
