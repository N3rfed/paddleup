return function(Deck)
 local ids={"speedCleats","bigPaddle","heatseeker"}
 local copy=assert(Deck.validate(ids))
 ids[1]="zeroG"
 assert(copy[1]=="speedCleats","Server retains its own validated deck")
 for _,invalid in ipairs({{}, {"speedCleats"}, {"speedCleats","speedCleats","zeroG"},
  {"speedCleats","unknown","zeroG"}, {"speedCleats","bigPaddle","zeroG","heatseeker"},
  {[1]="speedCleats",[2]="bigPaddle",[4]="zeroG"},
  {[1]="speedCleats",[2]="bigPaddle",[3]="zeroG",extra=true}}) do
  assert(not Deck.validate(invalid),"Reject malformed, duplicate, or unknown deck entries")
 end
 assert(not Deck.validate("speedCleats"))
 assert(#Deck.cards==8 and Deck.SIZE==3)
end
