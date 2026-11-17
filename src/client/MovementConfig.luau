-- CourtLocomotion supplies custom procedural court poses without uploaded assets.
-- Optional animation assets can replace the procedural layer in a future art pass.
-- Author movement clips with lower-body keys only; swing clips use Action priority.
return {
 AimResponse=90, Acceleration=18, Deceleration=30, LeanDegrees=12,
 FOVBoost=5, ReferenceSpeed=18,
 -- Generated reference clip; runtime court poses are authored in CourtLocomotion.
 GeneratedReference="rbxassetid://72066484826532",
 SqueakId="",
 Animations={Ready="",Forward="",ForwardLeft="",ForwardRight="",Left="",Right="",
  Backward="",BackwardLeft="",BackwardRight="",Jump="",Fall="",Dive=""},
}
