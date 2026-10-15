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
## Power-up pickups
Choose Practice, 1V1, 1V2, or 2V2, then choose **Power-Up** or **Augmented**. The shared court accepts players with the same format and ruleset; Spectate skips this choice.

## Augmented matches
Augmented replaces pickups and the Power/Slow abilities with match-long upgrades. After the intro and every three rallies, play pauses for a three-card draft. Everyone shares one rarity roll: **Silver 60%, Gold 30%, Prismatic 10%**. Offers are disjoint across players. The twelve original stat upgrades remain available at each tier alongside nine Silver, ten Gold, and nine Prismatic named effects, keeping four-player drafts possible. Named effects are unique and are excluded from your future offers once acquired; original stat upgrades still stack to their existing caps.

Click/tap a card, press 1–3, or select with a controller. After 20 seconds, the server chooses the first card for anyone still waiting. The bottom-left HUD shows acquired augment icons; active effects pulse with a green status dot. Click an icon or the Augments button, press B, or press controller Select to inspect descriptions, rarity, selection counts, and live progress. The match continues while details are open. Active effects produce a character-attached silver, gold, or prismatic particle aura and glow; triggered bursts also follow the character. Effects disappear when inactive or the character leaves the court. The stamina HUD displays tension, stun, lava, and overcharge status. Builds, reach stacks, and the consumed mulligan reset on a new match or roster change. Rally effects reset before each serve.

| Silver | Gold | Prismatic |
| --- | --- | --- |
| Kitchen Camper: +15% movement within 2 feet of the kitchen line; baseline retreat disables it for that rally. | The Third-Shot Drop: guided third shot with 40% less lateral error and heavy topspin. | Erne Executioner: legal airborne sideline volley at 300% power, winning on opponent paddle contact. |
| Dink Specialist: three consecutive landed dinks arm a +20% baseline drive. | Serve and Volley: +75% movement for 3 seconds after serving. | Phantom Paddle: 8 inches of backhand-only reach. |
| Carbon Fiber Core: +15% sweet spot radius. | Vampiric Reach: net wins grant +1% reach, capped at +10%. | Kitchen is Lava: touching the kitchen line doubles stamina spending for the rally. |
| Second Serve: one fault retry per match, preserving service rotation and refilling stamina. | ATP Assassin: a successful around-post landing drains 30% max stamina from the opposing team. | Rally Overcharge: after 15 total shots, a glowing paddle ignores spin and grants one unreturnable smash. |
| Slice and Dice: slice bounce height is 10% lower. | Bait and Switch: lob during an overhead windup produces a perfect drop and stuns retreating opponents for 1 second. | Deflector Shield: legal torso-drive contacts automatically return at twice the incoming speed. |

**Controls:** hold/release LMB or F to wind up/hit, RMB for dink/drop, **R for lob**, **X for slice**. Lob and slice also have touch buttons and controller Y/X bindings. Hold Left Shift, touch Dive, or controller B while swinging to use Deceptive Drop. For Bait and Switch, hold hit while an overhead is in reach, then press lob. Ordinary kitchen and two-bounce rules still apply to automatic returns and Ernes, including kitchen takeoff and landing faults.

Additional augments:

| Silver | Gold | Prismatic |
| --- | --- | --- |
| Perfect Vision: 20% wider pre/post-bounce perfect timing. | Momentum Shift: three personal perfect hits prime a +15% fourth return. | Apex Predator: contact within 60ms of a bounce apex hides accelerated flight from opponents until net crossing. |
| Quick Recovery: half-length dive movement and pose locks. | Offensive Dive: dive contacts apply maximum topspin; gravity increases by 80% after net crossing. | Rhythm Master: perfect hits after 10 total rally hits hide the paddle throughout the swing. |
| Baseline Sentinel: +15% lateral movement inside the two-foot baseline band. | Kitchen Warden: a planted player at the kitchen line gains a forward-shifted hit sphere, extending reach by 25% of normal radius. | Afterimage: a two-second visual dive clone; hitting within one second adds a decoy reticle for 0.65 seconds. |
| Calculated Return: standard serve returns use 80% of incoming velocity. | Deceptive Drop: hold dive while swinging for a smash feint, soft drop, and 0.5-second opponent reticle delay. | Terminal Velocity: uncapped +8% perfect acceleration; winning a rally whose peak exceeded 1.5x adds permanent +5% movement. |

Momentum Shift takes precedence over Terminal Velocity on the primed fourth hit. Permanent speed stacks reset with the match. Tracking deception affects opponents only; teammates and spectators retain normal tracking. Crosshairs, landing reticles, bounce countdowns, and out-landing markers are developer-only; normal play keeps these indicators hidden. Reticle-related augment effects apply when developer indicators are enabled. Clones are solid-looking, noncolliding local visuals and are removed on rally end or character removal. The old generic cooldown card is now called **Fast Reset**, reserving **Afterimage** for the Prismatic effect.

Cards use native vector illustrations, numeric effect badges, silver/gold/prismatic accents, orbiting frames, pulsing halos, and hover elevation. `src/client/AugmentArt.luau` owns the illustrations; `src/client/AugmentVisuals.luau` handles temporary clones and paddle visibility.

Balance distances use the court width scale of two studs per foot: the camper band is four studs, Phantom adds 1⅓ studs, net wins count within four studs of the kitchen line, and baseline drives within four studs of the baseline. Lava doubles dive costs and ATP stamina damage; it does not create a new passive stamina drain. Practice partners can be stunned and lose to unreturnable shots, but do not draft augments or spend stamina on dives.

`src/server/Augments.luau` owns the catalog, draft validation, and reusable effect rules. `tests/Augments.spec.luau` covers multiplayer drafts, ownership, rarity, and caps. `tests/AugmentEffects.spec.luau` covers rally reset boundaries, tension, mulligans, reach, spin, overcharge, and exact-speed reflection. `tests/AdvancedAugments.spec.luau` takes Augments and MatchRules and checks the additional effects, thresholds, recipient filtering, and split-gravity topspin. `tests/AugmentServer.spec.luau` executes the actual launch and point-resolution functions in an isolated fixture; pass the server source, Augments, MatchRules, and Comeback to its returned function. Run the two pure suites with the Augments module in Studio or the standalone Luau CLI.

## Power-Up pickup behavior
Pickups descend over 2.4 seconds with a gentle spiral and orbiting gold sparks, then pulse and bob while available. Collection plays a short shrinking burst; the six-second pickup lifetime starts after the descent.
Join Practice, 1V1, or 2V2 to try the placeholder pickups. A glowing 3D orb drops onto each occupied court half after two seconds. Walk into it to collect it and see floating confirmation text. Orbs idle for six seconds before expiring; a collected or expired orb is replaced after eight seconds. Lobby players and spectators cannot collect them. Roster changes clear the pickups.

These are test objects only: they grant no buffs and do not change the existing abilities. `PowerupsCollected` and `LastCollectedPowerup` player attributes record collection for the current server session. `src/server/Powerups.luau` owns spawn timing, positions, distance validation, and cleanup; its `onCollected(player, kind)` callback is the extension point for future inventory/effects. No inventory slot is reserved yet, so test pickups remain repeatable.

## Environment
The rooftop cycles through sunrise, daylight, sunset, and night every 12 real-world minutes. Each server starts at 06:00 and shares the same lighting with all players. Court lights remain on for nighttime play. Adjust CYCLE_SECONDS and START_HOUR in src/server/DayNightCycle.luau to change the duration or starting time.

## Serve charge
Hold left click (or hold the touch Swing button/F) and release using the dedicated serve meter. The marker cycles up over two seconds and down over two seconds until release or the 15-second deadline. The broad gold **Good** zone spans 30–70% charge; the tighter green **Perfect** zone spans 47–53%. Both produce legal diagonal serves. On the first upward sweep, Good spans 0.6–1.4 seconds and Perfect spans 0.94–1.06 seconds; both windows recur on the downward sweep. Below Good, very weak serves hit the net and stronger short serves land in the kitchen. Above Good, serves go beyond the baseline. The server measures the hold duration and validates faults. Only the designated server sees or controls the serve meter and countdown. Human players who do not release within the 15-second deadline lose the serve; the practice bot auto-serves after two seconds without giving the receiver a meter. Crosshair and landing indicators remain developer-only.

## Jump slams

Jumps use normal gravity by default. The Gold **Air Time** augment adds one second of slow descent after the apex, keeping normal ascent and lateral movement. Diving cancels the assisted descent; leaving the match or resetting augments restores regular jumps. A normal airborne swing within eight studs behind the kitchen line (or over the kitchen after a legal takeoff) attempts a slam. Timing is measured as the incoming ball passes the strike zone: early slams hit the net, a 60ms window on either side produces a clean slam, and late slams land beyond the baseline. Perfect Vision widens that window by 20%. Lob, slice, and soft-shot inputs keep their own shots. Kitchen takeoff/landing faults and the two-bounce rule still apply.

`tests/JumpSlam.spec.luau` covers eligibility and timing; `tests/JumpSlamServer.spec.luau` checks actual server return/launch trajectories. `tests/JumpHang.client.spec.luau` measures added airtime and force cleanup on a live Studio client avatar.

## Comeback boost
At exactly 9–3 (or 3–9), the trailing team receives +15% movement speed, +15% normal/perfect contact reach, and +15% return-shot velocity. The team keeps the boost across rallies until it ties the score or the match ends. It triggers once per match and resets with a new match or roster change. Both rulesets and the practice partner use this rule. Serve timing and fault rules still apply normally. A cyan character aura and stamina-HUD label identify the boosted players. `tests/Comeback.spec.luau` covers activation, team isolation, catchup, expiry, and resets.
