## Prerequisites
[Invoke-RestMethod](https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1)

[curl](https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh) -sSf

Roblox Studio

[rokit](https://github.com/rojo-rbx/rokit)

Follow these instructions for [rojo](https://rojo.space/docs/v7/getting-started/installation/)

Use the command `npm install -g @openai/codex` to install codex

Visual Studio Code

## Getting Started
1. Clone the repository
2. Using command prompt, change the directory to the destination where the repository was cloned
3. In the repository folder, use the command `rokit install`
4. On the top right of Roblox Studio, there should be an icon for an AI Assistant (looks like a star)
5. Click the 3 dots in the AI Assistant menu
6. Click "Manage MCP Servers"
7. Enable Studio as MCP server"
8. Quick Connect both codex and VS Code
9. Restart VS Code
10. After installing rokit, use the command `rojo serve`
11. On Roblox Studio, there should be a popup to connect to localhost
12. In a different command prompt window, type the command `codex` in the repository destination
13. Sign in with ChatGPT using the credentials provided in the pinned messages
14. Use default configuration when setting up
See [server scaling and live verification](SERVER_SCALING.md) for place settings, lifecycle behavior, and the multi-client test checklist.

## Modes and queue flow
Choose **Classic**, **Arcade**, or **Chaos**, then Practice, 1V1 (2 players), 1V2 (3 players), or 2V2 (4 players). This joins a queue for that mode and format. Complete groups enter an independent court session; other matches and solo practice sessions can continue at the same time. Every player gets a map vote; leaving setup returns the remaining players to the queue until a replacement joins. Spectate skips the queue.

Arcade players choose their three powerups on the court after the match intro, rather than before joining the queue. The first serve waits for every player to confirm. Selection lasts up to 45 seconds; unfinished selections receive a default loadout. Players can leave the match from the selection screen.

Press Q/E or click a ready power slot during the serve countdown to arm it. Armed powers show **ARMED** and activate when the serve actually launches, for servers and receivers alike. Press or click again to cancel. Arming consumes no charges or duration until launch; live-rally presses still activate immediately.

Chaos upgrades the original eight powers for the whole match. Choose after the intro and every three rallies; repeated picks increase each power through level 5. Chaos uses the build inventory instead of consumable Q/E slots. During live play, a shared court event triggers after four seconds, then every 10–14 seconds of rally time: Speed Frenzy, Giant Paddles, Gravity Surge, Lights Out, or Pickle Storm. Events last eight seconds, affect both teams, never repeat consecutively, and appear in a countdown banner. Practice pauses freeze active effects; changing the roster or resetting the match clears the build, events, and hazards.

- **Classic:** queue -> map selection -> game.
- **Arcade:** queue -> map selection and optional Low Gravity on the same screen -> game. Arcade gameplay features will be added later; it currently uses standard rules.
- **Chaos:** queue -> map selection and exactly one required environmental modifier (Low Gravity) on the same screen -> game, with powerup drafts.

Each player picks Rooftop or Moon during a shared 15-second countdown. All players see the live vote counts and each other's picks, and can change their selection until voting closes. The map with the most votes wins; tied maps enter a short roulette reveal with a server-selected random winner. If everyone abstains, both maps enter the draw. The group enters the match automatically after the reveal. Arcade players also vote on Low Gravity; it needs a majority and stays off on a tie. Chaos always requires Low Gravity. Low Gravity halves ball and player gravity on the court. Lobby players and spectators retain normal gravity. Gravity settings belong to each court. Classic has no pickups, Power Shot, Slow, or drafts; Arcade's abilities and test pickups remain disabled pending its later implementation.

`src/server/MatchQueue.luau` owns queue membership, voting deadlines, and random tie resolution; `MatchSetup.luau` validates shared mode/map/modifier rules. `tests/MatchQueue.spec.luau` covers queue isolation, capacity, live picks, voting deadlines, departures, majority results, randomized ties, admission, and modifier constraints.

## Chaos matches
Chaos uses the original eight powerups as permanent, automatic upgrades. Choose from three cards after the intro and every three rallies. A first pick unlocks level 1; repeated picks strengthen that power through level 5. Maxed powers leave the offer pool. Cards show the current-to-next level and the exact new effect. No Q/E activation is required in Chaos.

| Power | Level 1 | Level 5 |
| --- | --- | --- |
| Speed Cleats | +15% movement, 4% shorter swing cooldown | +75% movement, 20% shorter swing cooldown |
| Big Paddle | +20% paddle size and reach | +100% paddle size and reach |
| Drop Pickles | 1 automatic hazard every 12.5s | 3 automatic hazards every 6.5s |
| Heatseeker | Homing return recharges in 12.5s | Homing return recharges in 6.5s |
| Slip Stream | 8-stud slick every 14s | 16-stud slick every 6s |
| Small Paddle | Opponents lose 6% paddle size/reach | Opponents lose 30% paddle size/reach |
| Glow Ball | 19-stud light range, brightness 4 | 39-stud light range, brightness 8 |
| Zero-G Pulse | 20% less court gravity | 40% less court gravity |

Hazard timers advance only during live rallies. Hazards expire after six seconds; Heatseeker recharges automatically, with practice pauses preserving its timer. The strongest Small Paddle on the opposing team applies, and the strongest Zero-G upgrade affects the shared court. Random Chaos events still run alongside permanent upgrades.

Click/tap a card, press 1-3, or use a controller. After 20 seconds the first card is selected automatically. The build inventory displays each original icon and its level; B or controller Select opens descriptions. Levels survive rallies and drafts, and reset with a new match or roster change. Arcade retains its consumable Q/E powers and pre-serve arming.

ArcadeDeck.luau defines level tuning and card descriptions; ArcadePowers.luau runs permanent effects, automatic hazards, and court events. 	ests/ChaosLevels.spec.luau checks all eight upgrades, caps, timing, persistence, and reset. 	ests/ChaosBuildServer.spec.luau checks the actual draft and selection flow.

## Power-Up pickup behavior
Pickups descend over 2.4 seconds with a gentle spiral and orbiting gold sparks, then pulse and bob while available. Collection plays a short shrinking burst; the six-second pickup lifetime starts after the descent.
Placeholder pickups are currently disabled while Arcade functionality is deferred. When enabled for development, they behave as follows: A glowing 3D orb drops onto each occupied court half after two seconds. Walk into it to collect it and see floating confirmation text. Orbs idle for six seconds before expiring; a collected or expired orb is replaced after eight seconds. Lobby players and spectators cannot collect them. Roster changes clear the pickups.

These are test objects only: they grant no buffs and do not change the existing abilities. `PowerupsCollected` and `LastCollectedPowerup` player attributes record collection for the current server session. `src/server/CourtPickups.luau` owns spawn timing, positions, distance validation, and cleanup; its `onCollected(player, kind)` callback is the extension point for future inventory/effects. No inventory slot is reserved yet, so test pickups remain repeatable.

## Environment
The rooftop stays at a permanent arcade sunset (17:48), shared by all players. Peach atmospheric haze, violet ambient shadows, and a subtle pink color grade match the cyan and magenta HUD. Six neutral floodlights remain on at a 2.2 brightness baseline; rally pulses add light above that baseline. Six soft overhead fill lights keep the matte teal playing surface visible between rallies. The surround is muted purple to match the lobby upholstery, with no ground-level LED borders. The lobby keeps nine warm ceiling fills on, with extra lighting under the cafe and shop canopies. Its pale lavender stone, navy feature panels, muted upholstery, smoked wood, and champagne hardware echo the HUD; cyan and pink remain accent colors. Adjust START_HOUR and the lighting palette in src/server/DayNightCycle.luau; the clock no longer advances.

After choosing a game format and ruleset, choose **Rooftop** or **Moon**. The shared court accepts players using the same format, ruleset, and environment; Spectate watches the active court. Return to the lobby and empty the court before changing environments.

Moon is the Selene lunar outpost: a rocket and landing pad, crater fields, moon rocks and ridges, a rover with tracks, habitat, solar arrays, communications dish, mission flag, stars, Earth, and distant planets. It uses normal gravity, jump behavior, ball physics, court dimensions, and collision surfaces. Space lighting and scenery are cosmetic. `src/server/CourtEnvironments.luau` swaps scenery while preserving the live court, and `src/server/MoonEnvironment.luau` builds the lunar scene.

The moon has recessed craters, scattered basalt, and continuous eroded highlands outside the court. Earth uses globe and cloud texture references from [Realistic Earth (PBR) by 1980svg](https://create.roblox.com/store/asset/11372170772); no asset scripts are included. Moon intros show a preparation screen until each participant has received the complete scenery, preloaded its assets, and built both team camera views. The server then starts the full 9.5-second intro together. Players who cannot finish preparation within 30 seconds return to the lobby and can retry.

The moon is prepared in the server cache while players browse the lobby. The initial ReplicatedFirst arrival screen covers lobby/city streaming and character placement. `EnvironmentLighting.luau` gives moon players a fixed neutral lighting profile and separate sky, disables city sunset effects, and hides the lobby building/city locally so their roofs cannot protrude through the lunar floor. Lobby players retain the permanent arcade sunset; returning restores that lighting and city scenery. The sky uses [plain black by riproar4](https://create.roblox.com/store/asset/134011289) behind small point stars with subtle local twinkling. Earth has a faint blue limb glow. Saturn uses a banded globe texture from [Saturn [Realistic] by jacobthiagobonito](https://create.roblox.com/store/asset/15246961312), layered ice rings with dark divisions, and two small companions. Floor rocks mix flat slabs, elongated shards, chipped stones, broad fragments, jagged fragments, and lopsided stones, with varied proportions and orientations. Rock mesh geometry is from [Low Poly Rock Pack by FracturedSkies](https://create.roblox.com/store/asset/2128776869). The rocket uses a tapered paneled hull, capsule windows, hatch, ladder, articulated landing gear, radiators, and flared engine nozzles. Mountain footings and slopes remain outside all crater cutouts.

## Serve charge
Hold left click (or hold the touch Swing button/F) and release using the dedicated serve meter. The marker cycles up over two seconds and down over two seconds until release or the 15-second deadline. The broad gold **Good** zone spans 30–70% charge; the tighter green **Perfect** zone spans 47–53%. Both produce legal diagonal serves. On the first upward sweep, Good spans 0.6–1.4 seconds and Perfect spans 0.94–1.06 seconds; both windows recur on the downward sweep. Below Good, very weak serves hit the net and stronger short serves land in the kitchen. Above Good, serves go beyond the baseline. The server measures the hold duration and validates faults. Only the designated server sees or controls the serve meter and countdown. Human players who do not release within the 15-second deadline lose the serve; the practice bot auto-serves after two seconds without giving the receiver a meter. Crosshair and landing indicators remain developer-only.

## Jump slams

Jumps use normal gravity by default. The Gold **Air Time** powerup adds one second of slow descent after the apex, keeping normal ascent and lateral movement. Diving cancels the assisted descent; leaving the match or resetting powerups restores regular jumps. A normal airborne swing within eight studs behind the kitchen line (or over the kitchen after a legal takeoff) attempts a slam. Timing is measured as the incoming ball passes the strike zone: early slams hit the net, a 60ms window on either side produces a clean slam, and late slams land beyond the baseline. Perfect Vision widens that window by 20%. Lob, slice, and soft-shot inputs keep their own shots. Kitchen takeoff/landing faults and the two-bounce rule still apply.

`tests/JumpSlam.spec.luau` covers eligibility and timing; `tests/JumpSlamServer.spec.luau` checks actual server return/launch trajectories. `tests/JumpHang.client.spec.luau` measures added airtime and force cleanup on a live Studio client avatar.

## Comeback boost
At exactly 9–3 (or 3–9), the trailing team receives +15% movement speed, +15% normal/perfect contact reach, and +15% return-shot velocity. The team keeps the boost across rallies until it ties the score or the match ends. It triggers once per match and resets with a new match or roster change. Both rulesets and the practice partner use this rule. Serve timing and fault rules still apply normally. A cyan character aura and stamina-HUD label identify the boosted players. `tests/Comeback.spec.luau` covers activation, team isolation, catchup, expiry, and resets.

## XP and daily check-in
Press **E** at the existing lobby reception table for daily rewards and the weekly check-in calendar. Your profile shows level and XP toward the next level. Qualified completed games award XP; checking in activates the daily gameplay multiplier. See [progression rules, persistence, setup, and verification](PROGRESSION.md).

## PaddleUp Goods shop
Press **E** at the existing lobby boutique counter to preview, buy and equip 18 real paddle, wearable and court designs. Spendable XP is separate from lifetime leveling XP. See [shop assets, currency architecture, migration, tests and rollout](SHOP.md).
