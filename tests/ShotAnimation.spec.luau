-- Run with ShotAnimation and an R15 character in Studio.
return function(Shots,character)
 local root=character:FindFirstChild("HumanoidRootPart")
 local d={root=root,joints={}}
 local originals={}
 for _,j in ipairs(character:GetDescendants()) do
  if (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) and j.Part0 and j.Part1 then
   local name=j.Name:lower():gsub(" ","")
   if name=="rightshoulder" or name=="rightelbow" or name=="rightwrist" then
    d.joints[name]={instance=j}; originals[j]=j.Transform
   end
  end
 end
 local ok,result=pcall(function()
  local s,e,w=d.joints.rightshoulder.instance,d.joints.rightelbow.instance,d.joints.rightwrist.instance
  local origin=(s.Part0.CFrame*s.C0).Position
  local normal=root.CFrame.LookVector
  local contact=origin+normal*1.7-root.CFrame.UpVector*2
  assert(Shots.contactPose(d,contact,normal,1),"Expected reachable contact")
  local upper=s.Part0.CFrame*s.C0*s.Transform*s.C1:Inverse()
  local lower=upper*e.C0*e.Transform*e.C1:Inverse()
  local hand=lower*w.C0*w.Transform*w.C1:Inverse()
  local face=hand*CFrame.new(0,-2,0)
  assert((face.Position+face.LookVector*0.575-contact).Magnitude<0.01,"Paddle surface missed ball")
  assert(face.LookVector:Dot(normal)>0.999,"Paddle edge faces ball")
  assert(not Shots.contactPose(d,origin+normal*30,normal,1),"Unreachable target must clamp reach")
  for _,entry in pairs(d.joints) do
   assert(entry.instance.Transform.Position.Magnitude<0.001,"Arm joints must not stretch")
   for _,n in ipairs({entry.instance.Transform:GetComponents()}) do assert(n==n,"Invalid pose") end
  end
  return "Broad-face contact, contact position, finite rotations, and bounded arm reach passed"
 end)
 for j,cf in pairs(originals) do j.Transform=cf end
 assert(ok,result)
 return result
end
