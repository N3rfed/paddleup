-- All moving segments are posed by the authoritative practice simulation. Trim
-- is welded to its segment so court effects and portrait clones share one model.
local Assets=require(game:GetService("ReplicatedStorage").Shared.CosmeticAssets)
local Partner={}
local V=Vector3.new
local C=CFrame.new
local A=CFrame.Angles
local shell=Color3.fromRGB(225,227,210)
local jersey=Color3.fromRGB(32,116,108)
local graphite=Color3.fromRGB(44,54,59)
local amber=Color3.fromRGB(255,189,82)

function Partner.new(parent)
 local model=Instance.new("Model")
 model.Name="Practice Partner"
 model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local function piece(name,size,color,shape)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Color=color; p.Shape=shape or Enum.PartType.Block
  p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=model
  return p
 end
 local function trim(base,name,size,offset,color,shape)
  local p=piece(name,size,color,shape)
  p.CFrame=base.CFrame*offset; p.Anchored=false; p.Massless=true
  local joint=Instance.new("WeldConstraint")
  joint.Part0=base; joint.Part1=p; joint.Parent=p
  return p
 end
 local oval=Enum.PartType.Ball
 local body=piece("Body",V(1.95,1.75,1.12),jersey,oval)
 model.PrimaryPart=body
 trim(body,"Waist bearing",V(1.28,0.55,0.84),C(0,-0.86,0),graphite,oval)
 trim(body,"Chest plate",V(1.32,0.9,0.32),C(0,0.1,-0.43),shell,oval)
 trim(body,"Charge indicator",V(0.45,0.1,0.09),C(0,0.13,-0.59),amber)
 local head=piece("Head",V(1.45,1.13,1.08),shell,oval)
 trim(head,"Visor",V(1.33,0.62,0.56),C(0,0,-0.36),graphite,oval)
 for _,x in ipairs({-0.29,0.29}) do
  trim(head,"Optic",V(0.2,0.21,0.09),C(x,0,-0.61),amber,oval).Material=Enum.Material.Neon
 end
 local sides={}
 for i,side in ipairs({"Left","Right"}) do
  local leg=piece(side.." shin",V(0.51,1.1,0.55),shell,oval)
  trim(leg,"Knee bearing",V(0.58,0.53,0.55),C(0,0.48,0),graphite,oval)
  sides[i]={
   thigh=piece(side.." thigh",V(0.62,0.95,0.65),jersey,oval),leg=leg,
   foot=piece(side.."Foot",V(0.72,0.42,1.1),graphite,oval),
   arm=piece(side.."UpperArm",V(0.58,0.94,0.6),shell,oval),
   forearm=piece(side.."LowerArm",V(0.46,0.83,0.5),jersey,oval),
   hand=piece(side.." gripper",V(0.47,0.45,0.43),graphite,oval),
  }
 end
 local paddle=piece("Paddle",V(1.5,2.2,0.3),graphite)
 paddle:SetAttribute("HandleDirection",-1)
 Assets.paddle(paddle,nil)
 local tag=Instance.new("BillboardGui")
 tag.Size=UDim2.fromOffset(180,35); tag.StudsOffset=V(0,1.5,0); tag.AlwaysOnTop=true; tag.Parent=head
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text="PRACTICE PARTNER"
 label.TextColor3=shell; label.Font=Enum.Font.GothamBold; label.TextSize=12; label.Parent=tag
 local rig={model=model}
 function rig:pose(position,stride,stumble,swing,reach)
  local base=C(position)*A(0,math.pi,0)
  local torso=base*C(0,2.98+0.06*math.abs(stride),0)*A(-0.08,swing*0.35,stumble*0.38)
  body.CFrame=torso
  head.CFrame=torso*C(0,1.38,-0.04)
  for i,limb in ipairs(sides) do
   local sign=i==1 and -1 or 1
   local step=sign*(stride*0.54+stumble*0.45)
   local hip=base*C(sign*0.48,2.22,0)*A(step+0.13,0,sign*0.08)
   limb.thigh.CFrame=hip*C(0,-0.46,0)
   local knee=hip*C(0,-0.90,0)*A(-0.23-math.max(0,-step)*0.5,0,0)
   limb.leg.CFrame=knee*C(0,-0.55,0)
   local ankle=knee*C(0,-1.10,0)
   limb.foot.CFrame=C(ankle.Position)*base.Rotation*C(0,0,-0.15)
   local shoulder=torso*C(sign*0.93,0.53,0)*A(-step*0.6+0.14,i==2 and -swing or 0,sign*(0.25+math.abs(stumble)*0.6))
   limb.arm.CFrame=shoulder*C(0,-0.43,0)
   local elbow=shoulder*C(0,-0.85,0)*A(0.95+(i==2 and swing or 0),0,0)
   limb.forearm.CFrame=elbow*C(0,-0.38,0)
   limb.hand.CFrame=elbow*C(0,-0.8,0)
   if i==2 then
    local grip=limb.hand.CFrame*A(-1.25,0,-0.6)
    paddle.Size=V(1.5,2.2,0.3)*reach
    paddle.CFrame=grip*C(0,paddle.Size.Y*0.86,0)
   end
  end
 end
 model.Parent=parent
 function rig:show(visible)
  local target=visible and parent or nil
  if model.Parent~=target then model.Parent=target end
 end
 return rig
end
return Partner
