-- All progression tuning is server-owned and lives here.
return {
 StoreName="PaddleUpProgression_v1", SchemaVersion=2,
 DefaultTimeZone="UTC", TimeZoneChangeDays=7,
 BaseXP=100, LinearXP=50, QuadraticXP=10,
 DailyXP=150, DailyMultiplier=1.05, MultiplyDailyReward=false, MultiplyWeeklyReward=false,
 WeeklyFraction=0.20, StreakDays=7, HistoryDays=35,
 Rewards={MatchCompleted=80,MatchWon=120,PracticeCompleted=30},
 GameplayDailyCap=600, MinimumMatchSeconds=90, MinimumContestedRallies=12, MinimumReturns=6,
 PromptDistance=12, InteractionSeconds=120, RemoteCooldown=1, RefreshSeconds=30, ManualRetrySeconds=3,
 RetryAttempts=3, RetryBaseSeconds=0.75, RetryInterval=15, ShutdownSeconds=25,
 ReceiptSeconds=172800, MaximumReceipts=128, MaximumPending=8,
}
