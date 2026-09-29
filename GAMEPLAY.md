# Paddle Up! — Skyline Club

Arcade pickleball on an apartment rooftop. Press Play in Studio. The first
player faces a practice partner; a second player replaces it. Additional
players spectate and enter when a court slot opens.

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

The landing ring pulses red, yellow, then green. Returns within 0.23 seconds
before a bounce or 0.28 seconds afterward count as perfect. Perfect hits have
no swing cooldown and multiply rally speed by 1.05. Other swings have a
0.28-second cooldown. A point resets rally speed. Stamina regenerates at
22 per second. Power shots add a temporary 22% speed boost.

First to 11, win by two. Net faults, out balls, and double bounces score points.
Serves start on click or tap; points reset the court for the next serve.
The two-bounce rule and diagonal serving are enforced. Kitchen faults apply
when contact occurs inside the kitchen, or a dive contacts the ball there.
Only the serving side scores; a receiving-side win transfers serve.

The HUD includes clickable abilities and touch swing/dive buttons.

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

Only the serving side scores. A receiving-side rally win transfers serve without
adding a point. Ball gravity remains 45 studs/s? for every shot; speed affects
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

Team labels show each side's current player display name.

Hold left mouse to charge, then release to serve or swing. The meter below the
center crosshair fills in one second. Full charge gives a well-timed hit up to
30% extra launch speed (subject to net clearance), without changing rally speed
or gravity. Quick taps swing on release. Mistimed hits still lob or hit low;
right-click still selects dink/drop. Charging cancels on a dive, right-click,
menu/chat focus, window focus loss, death/respawn, or the end of a rally.

Athletic movement uses directional footwork, bent knees, torso lean, a ready
paddle arm, and a charge windup. Stride cadence follows actual movement speed,
including strafing and backward movement. The pose blends away in the air;
dives and strokes layer over it. Both R6 and R15/upgraded avatar joints are
supported. The camera and centered crosshair remain stable during footwork.

Animation review: articulated legs use separate foot-contact and lifted-step
phases, backward knee hinges, and ankle counter-rotation to keep soles level.
Leg lengths come from the avatar joints, with a simpler rigid-leg gait for R6.
Strafing no longer drives both legs inward. Ready and charge poses use moderate
elbow flexion; strokes coordinate torso rotation, gaze, and the balancing arm.
Slams emphasize an early contact and follow-through. Dive poses lean in their
travel direction, with a reaching arm and a bent supporting arm. The existing
jump animation blends through while airborne. These poses use sports-anime
anticipation and follow-through with human joint directions.
