return function(Rules)
 for _,height in ipairs({0,240}) do
  local scoped=Rules.withHeight(height)
  for _,handY in ipairs({181,184,190}) do
   for _,r6 in ipairs({false,true}) do
    local character=Instance.new("Model")
    local right=Instance.new("Part",character)
    right.Name=r6 and "Right Arm" or "RightHand"
    right.CFrame=CFrame.new(3,handY+height,12)*CFrame.Angles(0.3,0.5,0.2)
    local left=Instance.new("Part",character)
    left.Name=r6 and "Left Arm" or "LeftHand"
    left.CFrame=CFrame.new(-3,handY+height,12)
    for _,name in ipairs({"PaddleFace","PaddleGrip"}) do
     local part=Instance.new("Part",character); part.Name=name
     local weld=Instance.new("Weld",part); weld.Name="PaddleWeld"
     weld.Part0=right; weld.Part1=part
    end
    scoped.updatePaddle(character)
    local face=right.CFrame*character.PaddleFace.PaddleWeld.C0
    assert((face.Position-(right.CFrame*CFrame.new(0,-2,0)).Position).Magnitude<0.001,"Grounded paddle stays in the hand")
    local ball=scoped.heldBallPosition(character)
    assert((ball-left.CFrame:PointToWorldSpace(Vector3.new(0,-left.Size.Y/2-0.3,-0.2))).Magnitude<0.001,"Grounded ball stays in the hand")
    assert((ball-Rules.heldBallPosition(character,height)).Magnitude<0.001,"Client and server must agree")
    local root=Instance.new("Part",character); root.Name="HumanoidRootPart"
    local humanoid=Instance.new("Humanoid",character)
    humanoid.HipHeight=2
    local standing=root.Size.Y/2+humanoid.HipHeight
    if humanoid.RigType==Enum.HumanoidRigType.R6 then standing+=2 end
    root.Position=Vector3.new(0,181.24+height+standing+7,0)
    scoped.updatePaddle(character)
    face=right.CFrame*character.PaddleFace.PaddleWeld.C0
    assert(character.PaddleFace.PaddleWeld.C0==CFrame.new(0,-2,0),"Airborne paddle uses the hand grip")
    assert((scoped.heldBallPosition(character)-left.CFrame:PointToWorldSpace(Vector3.new(0,-left.Size.Y/2-0.3,-0.2))).Magnitude<0.001,"Airborne ball follows the hand")
    -- Remote observers may still report a floor during takeoff.
    local observer={
     FindFirstChild=function(_,name) return character:FindFirstChild(name) end,
     FindFirstChildOfClass=function() return {HipHeight=humanoid.HipHeight,RigType=humanoid.RigType,FloorMaterial=Enum.Material.Concrete} end,
    }
    assert(math.abs(Rules.jumpHeight(observer,height)-7)<0.001,"Stale floor material cannot pin equipment to the court")
    for _,rise in ipairs({12,5,1,0}) do
     root.Position=Vector3.new(0,181.24+height+standing+rise,0)
     right.CFrame=CFrame.new(3,handY+height+rise,12)*CFrame.Angles(1.4,0.5,0.2)
     left.CFrame=CFrame.new(-3,handY+height+rise,12)*CFrame.Angles(0.7,0,0)
     scoped.updatePaddle(character)
     face=right.CFrame*character.PaddleFace.PaddleWeld.C0
     assert((face.Position-(right.CFrame*CFrame.new(0,-2,0)).Position).Magnitude<0.001,"Paddle stays attached to the animated hand")
     assert((scoped.heldBallPosition(character)-left.CFrame:PointToWorldSpace(Vector3.new(0,-left.Size.Y/2-0.3,-0.2))).Magnitude<0.001,"Ball stays attached to the animated hand")
    end
    character:Destroy()
   end
  end
 end
end
