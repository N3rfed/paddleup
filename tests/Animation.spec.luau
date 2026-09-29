-- Run with the SportsPose module supplied by the Studio animation check.
return function(Pose)
 local cases=0
 for _,lengths in ipairs({{1,1},{1.2,0.85},{1.5,1.3}}) do
  for _,direction in ipairs({Vector2.new(1,0),Vector2.new(-1,0),Vector2.new(0,1),Vector2.new(0,-1),Vector2.new(0.707,0.707)}) do
   for step=0,100 do
    local phase=step/100
    local hip,knee,ankle,bend,planted=Pose.leg(phase,direction.X,direction.Y,1,lengths[1],lengths[2],(lengths[1]+lengths[2])*0.08)
    assert(bend<=0 and bend>math.rad(-120),"Knee hyperextended or folded too far")
    if planted then
     assert(((hip*knee*ankle).UpVector-Vector3.yAxis).Magnitude<0.0001,"Planted sole is tilted")
    end
    local _,_,otherPlanted=Pose.step(phase+0.5)
    assert(planted or otherPlanted,"Both walking feet are in swing phase")
    cases+=1
   end
  end
 end
 for _,direction in ipairs({Vector3.new(0,0,-1),Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1)}) do
  local lean=Pose.diveTilt(direction).UpVector
  assert(lean:Dot(direction)>0.5,"Dive body leans away from travel")
  local _,weight=Pose.dive("root",direction,0.66)
  assert(weight==0,"Dive pose does not fully recover")
 end
 for _,name in ipairs({"waist","neck","rightshoulder","rightelbow","leftshoulder","leftelbow"}) do
  for _,kind in ipairs({"forehand","backhand","slam"}) do
   local pose,weight=Pose.stroke(name,0.08,kind=="backhand",kind=="slam",true)
   assert(pose and weight>0,"Missing coordinated stroke joint: "..name)
   local _,finished=Pose.stroke(name,0.5,kind=="backhand",kind=="slam",true)
   assert(finished==0,"Stroke does not blend back to locomotion")
  end
 end
 return string.format("%d gait samples: knee direction, planted soles, alternating contact; four dive directions; stroke recovery passed",cases)
end
