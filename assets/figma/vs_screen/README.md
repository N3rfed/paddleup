# VS screen artwork

The SVGs in this folder are the user-supplied source artwork. `generated/` contains
transparent PNG conversions for Roblox, plus SVG frame derivatives that remove
the sample names and countdown text. Original borders, glow, divider, and VS badge
are retained. Live labels are rendered using Nunito in `src/client/MatchIntro.luau`.

The screen scales from a 1920 x 1080 canvas. The viewer's team is always on the
right, with the local player named first and marked YOU. Opponents appear on the
left. Each diagonal viewport contains both its character models and a copy of the
current court, with a warm sunset sky behind it. Characters stand on the saved
playing surface and hold their paddle. The court's colors are copied unchanged,
including moved or rotated maps. The server owns the three-second deadline.
Lunar map streaming completes before that deadline starts.

The round badge supports `round` and `totalRounds` when supplied. Current matches
do not track a best-of-three series, so they display ROUND 1 without a fictional total.
