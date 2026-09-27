# Paddle Up! — Skyline Club

Arcade pickleball on an apartment rooftop. Press Play in Studio. The first
player faces a practice partner; a second player replaces it. Additional
players spectate and enter when a court slot opens.

| Input | Action |
| --- | --- |
| WASD / arrow keys | Move; movement at impact directs the shot |
| Space | Jump |
| Left mouse button | Swing with a 9-stud sphere around the paddle |
| Left Shift | Dive toward the ball; 35 stamina, 1.6-second cooldown |
| Q | Arm a power shot for 5 seconds; 10-second cooldown |
| E | Slow the opponent for 2.5 seconds; 12-second cooldown |

Dives travel toward the ball (or the character's facing direction between
rallies), slow to a stop over 0.46 seconds, and recover from a full-body pose
by 0.72 seconds. Movement stays on the owning client, with server-validated
stamina and cooldowns. Braking keeps dives inside the court. Procedural poses
support both Motor6D and upgraded AnimationConstraint avatar joints.

The landing ring pulses red, yellow, then green. Returns within 0.23 seconds
before a bounce or 0.28 seconds afterward count as perfect. Perfect hits have
no swing cooldown and multiply rally speed by 1.05. Other swings have a
0.28-second cooldown. A point resets rally speed. Stamina regenerates at
22 per second. Power shots add a temporary 22% speed boost.

First to 11, win by two. Net faults, out balls, and double bounces score points.
Serves and new games start automatically. This is arcade scoring: formal
serving rotations, the two-bounce rule, and kitchen volley faults are not
implemented.

The HUD includes clickable abilities and touch swing/dive buttons.

- `src/server/init.server.luau`: ball simulation, hit validation, scoring,
  abilities, player slots, and practice partner.
- `src/server/World.luau`: repeat-safe rooftop, court, pool, lounge, and skyline.
- `src/client/init.client.luau`: input, camera, ball visuals, landing assist, HUD.
- `src/client/DiveController.luau`: smooth dive movement, boundary braking,
  avatar pose, and recovery.

Build with `rojo build -o PaddleUp.rbxlx`, or sync with `rojo serve`.
A fresh build creates the environment when Play starts. To create it in
edit mode, run `require(game.ServerScriptService.Server.World).build()`.

The authoritative source is under `src/`, as mapped in
`default.project.json`. The loose service folders are not mapped by Rojo.
