-- Edit assignments here; identifiers are stable across saved lobby migrations.
return {
 Elevators={
  {id="Left",bank="1V1",index=2,format="1V1",capacity=2},
  {id="LeftA",bank="1V1",index=1,format="1V1",capacity=2},
  {id="LeftB",bank="1V1",index=3,format="1V1",capacity=2},
  {id="RightA",bank="2V2",index=1,format="2V2",capacity=4},
  {id="RightB",bank="2V2",index=3,format="2V2",capacity=4},
  {id="RightC",bank="2V2",index=2,format="2V2",capacity=4},
 },
 PollSeconds=0.15,DoorSeconds=0.65,DoorHoldSeconds=1.5,
 CabinDepth=9,DoorPanelDepth=0.23,DoorStackX=4.65,
 ApproachForward=4.5,ApproachSize=Vector3.new(14,14,18),InteriorSize=Vector3.new(9.7,11,8.4),
 InvitationSeconds=10,VoteSeconds=15,DepartureSeconds=6,TerminationSeconds=5,
 -- Replace with experience-owned audio if these built-in sounds are unsuitable.
 MovementSound="rbxasset://sounds/action_swim.mp3",
 ArrivalSound="rbxasset://sounds/electronicpingshort.wav",
}
