return function(Rules)
 assert(Rules.DIVE_COOLDOWN==3.5)
 assert(Rules.STAMINA_RECOVERY_DELAY==1.5)
 assert(math.abs(Rules.STAMINA_REGEN_RATE-12.1)<1e-10)
 local now=10
 local stamina=100-Rules.DIVE_STAMINA_COST
 local cooldown=now+Rules.DIVE_COOLDOWN
 local recoverAt=now+Rules.STAMINA_RECOVERY_DELAY
 assert(not Rules.canDive(100,cooldown,13.499999),"Cooldown blocks dives even with full stamina")
 assert(Rules.canDive(35,cooldown,13.5),"Dive becomes available at exactly 3.5 seconds")
 assert(not Rules.canDive(34.99,cooldown,20),"Dive must still require enough stamina")
 assert(Rules.recoverStamina(stamina,recoverAt,11,0.5)==stamina)
 assert(Rules.recoverStamina(stamina,recoverAt,11.5,0.5)==stamina)
 assert(math.abs(Rules.recoverStamina(stamina,recoverAt,11.6,0.2)-(stamina+1.21))<1e-8,
  "A frame spanning recovery delay must regenerate only its eligible portion")
 assert(math.abs(Rules.recoverStamina(stamina,recoverAt,12.5,1)-(stamina+12.1))<1e-8)
 assert(Rules.recoverStamina(99,recoverAt,20,1)==100)
 assert(Rules.recoverStamina(stamina,21.5,21,1)==stamina,"A subsequent spend restarts the delay")
 return "Exact dive cooldown, stamina cost, delayed recovery, 55% regeneration and frame boundary checks passed"
end
