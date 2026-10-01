# Paddle Up! — Skyline Club

Arcade pickleball on an apartment rooftop. Press Play in Studio to spawn on
the walkable Skyline Club lobby terrace beside the court. Walk to a Singles,
Doubles, Practice, or Spectate station and press E (or tap the prompt), or
open PLAY / PARTY. BACK TO TERRACE closes the menu so you can keep exploring.
The lobby uses the same shift-lock camera as the court. Left-click (or tap)
to swing your paddle; right-click performs a soft swing. Other players see
these swings, but they do not hit the match ball. Hold Alt to click PLAY /
PARTY; an open queue menu keeps the cursor free and blocks paddle swings.

Matchmaking uses players in the same server and one shared court. Singles
waits for two humans; doubles waits for four. Solo queues fill with random
players. Invite a player from the lobby list; they must accept within 30
seconds. The party leader chooses the mode and queues the group. Two friends
face each other in singles and stay together in doubles. Groups of three or
four split in party join order (first two on Team 1); a group of three fills
its final slot from the solo queue. Leaving a party cancels its queue.

Practice is solo against a bot, with Easy, Normal, or Hard difficulty. Easy
reacts and moves more slowly and makes more mistakes; Hard reacts faster,
tracks more accurately, and hits more perfect returns. Practice waits for
the court if another match is running. Leave a party before choosing practice.

Spectate a running match, including practice, without occupying a court slot.
You can watch while queued. BACK TO LOBBY returns to the terrace; accepting
a match automatically switches you into play. During play, hold Alt to click
LEAVE MATCH and confirm. A win or player departure ends the match and returns
its players and spectators to the lobby. The next ready queue can then play.
Friends remain in their party after a match; queue again when ready.

| Input | Action |
| --- | --- |
| WASD / arrow keys | Move relative to the camera |
| Mouse / right-side touch drag | Turn the character and aim |
| Right mouse button | Dink near the kitchen or drop from deeper court |
| Space | Jump |
| Left mouse button | Swing with a 9-stud sphere around the paddle |
| Left Shift | Dive toward the ball; 35 stamina, 1.1-second cooldown |
| Q | Arm a power shot for 5 seconds; 10-second cooldown |
| E | Slow the opponent for 2.5 seconds; 12-second cooldown |

Gameplay uses an always-on shift-lock camera. Serves and returns follow the
character's horizontal facing direction at impact, including during dives.
The ground marker shows that direction; shot height follows the arcade arc.
Aim serves into the diagonal service court. Shots are not clamped in bounds.
Shift remains the dive key.

Dives use current movement input, then facing direction, then ball direction.
They slow to a stop over 0.48 seconds and recover by 0.66 seconds. Movement
stays on the owning client, with server-validated stamina and cooldowns.
Procedural poses
support both Motor6D and upgraded AnimationConstraint avatar joints.
During a dive the body turns toward the travel direction, including sideways
and backward dives. The pose keeps that heading while the camera turns, then
blends back into locomotion during recovery; camera-based shot aim is retained.

The landing ring pulses red, yellow, then green. Returns within 0.23 seconds
before a bounce or 0.28 seconds afterward count as perfect. Perfect hits have
no swing cooldown and multiply rally speed by 1.05. Other swings have a
0.28-second cooldown. A point resets rally speed. Stamina regenerates at
8 per second, with a maximum of 70 and a cost of 35 per dive. Two quick dives
leave roughly 3.3 seconds before another dive is available. Power shots add
a temporary 22% speed boost.

First to 11, win by two. Net faults, out balls, and double bounces score points.
Serves start on click or tap; points reset the court for the next serve.
Each prepared serve gets a 15-second server-controlled deadline. Players and
spectators see "[DisplayName]'s serve" and the remaining seconds. Serving
manually clears the timer; otherwise a normal, uncharged serve launches into
the diagonal service court automatically. A human server who wandered away
is returned to the serving position. The timer also applies to practice bots,
and any held charge is canceled when the automatic serve starts.
The two-bounce rule and diagonal serving are enforced. Kitchen faults apply
when the player is inside the kitchen at volley contact. Reaching over the
kitchen during a dive does not itself cause a foot fault; bounced returns
remain legal from inside the kitchen.
Only the serving side scores. Doubles uses two service turns per possession:
a fault passes serve to the partner, then the next fault causes a side-out.
The opening doubles possession has only one turn, shown as 0-0-2. Solo sides
in singles or 2v1 get one turn. Scoring switches the serving teammates' court
positions; the diagonal receiver is enforced. On a side-out the doubles
player in the right court serves first. Server numbers describe the current
service turn, not a fixed player identity. These follow the
[USA Pickleball side-out rules](https://usapickleball.org/rules/summary/),
with one service turn for the solo side as the game's 2v1 adaptation.

The scoreboard always reads **Team 1 points - Team 2 points - server number**,
keeping team scores in fixed order. The compact gradient panel contains only
the three numbers, with a mint underline marking the serving team's score.
New games reset to Team 1's opening service turn.

A soft ground shadow stays directly beneath the rendered ball at its current
X/Z position during play and serve setup. It follows the court/deck height,
ignores players and the net, and works independently of lighting or shadow
quality. The developer landing marker remains a separate prediction.

The HUD includes clickable abilities and touch swing/dive buttons.

The court glass enclosure, uprights, and rails are removed, including from
saved courts on the next layout update. The invisible back and sideline
movement limits are removed. Players can move through the rooftop surround.
Shot feedback (lob, perfect, slam, dink, drop) floats above the player who
performed the shot and is visible to everyone. Labels pop, rise, and fade:
green for clean shots, gray for neutral feedback/lobs, and red for misses,
faults, or mistimed charges. Each player keeps only their latest label during
fast exchanges; the practice partner also shows shot labels. The fixed shot
toast is removed; rally-result announcements remain separate.
Labels use smaller 17px text and follow a smoothed root-position anchor instead
of the animated head, with a gentle rise and fade instead of a bouncing scale.
Left-click presses only begin charging; releasing plays the swing and attempts
the hit. A tap is a normal swing. Non-perfect attempts have a 0.28-second hit
cooldown; perfect timing bypasses it. Only an explicit missed click/release
shows "Miss!"; holding and automatic dive reach checks do not create misses.
Right-click always plays an underhand dink/drop motion, even on a miss.
Accepted contacts reconcile the animation without replaying it.
Each on-court bounce plays a separate, softer, lower-pitched voice of the
existing pickleball sample, configured as `pickleball bounce` in the project.

- `src/server/init.server.luau`: ball simulation, hit validation, scoring,
  abilities, player slots, and practice partner.
- `src/server/World.luau`: repeat-safe rooftop, court, pool, lounge, and skyline.
- `src/client/init.client.luau`: input, camera, ball visuals, landing assist, HUD.
- `src/client/DiveController.luau`: smooth dive movement,
  avatar pose, and recovery.

Build with `rojo build -o PaddleUp.rbxlx`, or sync with `rojo serve`.
A fresh build creates the environment when Play starts. To create it in
edit mode, run `require(game.ServerScriptService.Server.World).build()`.

The authoritative source is under `src/`, as mapped in
`default.project.json`. The loose service folders are not mapped by Rojo.

Court lighting reacts to rally speed and the interval between accepted hits.
Six overhead washes and perimeter strips rest in teal, then follow the ball's
yellow, green, orange, red, and violet speed tiers. Contact waves travel along
the sidelines; quick exchanges build a stronger, gently pulsing glow. Lighting
eases back to teal between points. Saved courts receive the rig on their next
world layout update without rebuilding the rooftop.

Every viewer sees contact sparks, stronger slam/charged/power impacts, bounce
ripples, ball glow, and high-speed embers. Slammable lobs preserve their blue
ball/trail cue. Players gain paddle charge sparks, brief contact highlights,
swing trails, and dive/movement streaks; the practice partner also shows hit
effects. These client-side visuals leave physics and hit validation unchanged,
limit temporary effects, and clean up after rallies and character removal.
`src/client/RallyEffects.luau` owns these effects and their speed palette.

Developer overlay: press Home to toggle player hitboxes and the UI legend.
Gold is normal hit reach, green is perfect-hit distance, blue is the overhead
cylinder, and purple is the slam paddle-distance cap. A slam must fit inside
both blue and purple volumes. Vertical reach starts 0.5 studs above the head
and ends five studs beyond arm length; timing and court rules still apply.

Lobs predicted to pass through an overhead opportunity at the receiving
kitchen line carry a lingering blue trail for the entire shot. This forecasts
positioning potential, not guaranteed perfect timing or a legal volley.

For incoming lobs, players outside the kitchen and within eight studs of its
line can earn a perfect slam throughout the overhead contact window. Bounce
timing is not required for this case; reach, two-bounce, and kitchen-contact
rules still apply. The HUD displays "SWING TO SLAM!" when the hit is available.

Normal play shows only the score, movement-aware crosshair, and Dev toggle.
Hold Alt to release the mouse and click Dev, or press Home. Developer mode
shows the full HUD, landing ring/countdown, ground aim marker, and hitboxes.
On touch screens, tap the court to swing when the developer HUD is hidden.
Strafing shifts aim up to four degrees in the movement direction. Moving
into the ball adds up to 12% shot speed and four studs of target depth, with
a small upward crosshair cue. This bonus does not accumulate as rally speed.
All player contacts, including dives and slams, reject balls more than
1.5 studs behind the character. The red developer plane marks this cutoff;
the portions of the displayed reach volumes behind it are excluded.

Dive tuning: 64 studs/second initial speed, 0.48-second movement,
0.66-second recovery, and 1.1-second cooldown. Slams use an overhead
windup/chop animation. Their shot speed starts at 90% of the previous base;
the multiplier grows by 0.2 for each extra 1x rally speed, capped at 1.3.

Only the serving side scores. A receiving-side rally win advances to the next
server or causes a side-out without adding a point. Ball gravity remains 45 studs/s? for every shot; speed affects
launch velocity and flight time. Net clearance can limit shot speed.
The camera stays toward the opponent, with 25? left/right aim limits and subtle
movement sway. Stamina stays visible in normal play. Out first landings show
an X until the next serve setup. Air dives briefly offset 80% of avatar gravity
for 0.34 seconds to extend horizontal travel, then resume full falling gravity.

Mouse/right-side touch movement adjusts the crosshair and character aim, not
the camera. The camera keeps a fixed forward pitch and heading with only
movement-based sway. Rally results appear centrally outside developer mode:
Side Out!, the scoring player's display name, and the fault that ended play.
Out markers use a top-facing ground surface rather than a camera-facing label.

Current aiming: the crosshair stays fixed at screen center. Mouse or right-side
touch drag rotates the shift-lock camera and character together. Crosshair
movement and camera sway are disabled; the floor-clearance camera remains.

Right-click soft shots: within eight studs of the kitchen line, perfect contact
produces a dink; farther back (including behind the transition area), it produces
a drop. Both target the opponent's kitchen. Imperfect contact produces a lob;
contact more than 0.65 seconds from the bounce timing window produces a low
mishit toward the net along the current aim. Swinging out of reach still misses.
Kitchen and two-bounce faults remain in force. Perfect overhead lob timing still
qualifies at the kitchen line. Right-click does not serve.
Ball trails are wider and longer, changing yellow ? green (1.1x) ? orange (1.3x)
? red (1.6x) ? purple (2x). Slammable lob forecasts retain their blue trail.

The score-only HUD keeps Team 1 and Team 2 in fixed order, followed by server number.
# Charged returns

Charging now winds the paddle arm back with torso rotation and a balancing off arm. Release swings continue across the body before easing into locomotion; slams use a longer downward follow-through. Charge poses replicate to opponents. Successful returns include contact position and launch direction so the R15 arm solve puts the broad paddle face against the ball, within natural arm reach. The existing generous gameplay hitboxes remain in place, so far contacts can exceed the visual arm reach.

Hold left mouse and release to hit. Taps remain normal returns; charge builds after 0.4 seconds and caps at one second, with a meter below the crosshair. Clean charged returns increase rally speed by 7% and gain up to 22% launch speed over normal returns, below the spike speed profile. Spikes retain their +10% rally increase. Serves accept the same charge-dependent launch boost, subject to net clearance. The ball stays in the designated server's off hand until release and launches from that hand; diagonal service and foot-fault checks still apply.

Mistimed charged returns keep the lob/net timing rules and -5% rally penalty. Higher charge adds progressively more sideways variance and long-distance overshoot; targets are not clamped to the court. Dive, focus loss, menus, respawn, and rally results cancel charging. Charge duration and random shot error are calculated by the server.

Body hits produce a short visible deflection, including hits on the practice
partner. Horizontal travel reverses, loses 85% of its speed, and caps at 8
studs per second. A 3-stud-per-second upward bump keeps the ball low. Body
contact locks out paddle returns and further body hits until the ball lands,
then awards the rally to the opposing team as a body-hit fault. Paddle parts
and spectators do not trigger body hits.
