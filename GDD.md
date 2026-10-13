# Game Design Document: Paddle Up (Pickleball Arcade)

**References / Inspiration:**
* Roblox Volleyball 4.2 | Pick-up Game! Volleyball Legends
* [Nintendo Switch Sports Tennis](https://www.nintendo.com/my/switch/as8s/tennis/index.html?srsltid=AfmBOopNoXCwCHKTYsJfRUcvxmfsJ2gXJD0vyo7SD5468yETKq4RPKU6)

---

## 1. Game Overview & Mantra
* **Vision / Mantra:** Fast-paced rooftop pickleball with chaotic, round-altering power-ups.
* **Platform:** Roblox (PC).
* **Target Audience:** Casual-competitive friends looking for snappy, easy-to-learn rallies with party-game modifiers.
* **Core Philosophy:** Low barrier to entry with high clutch potential. Standard hits are forgiving, while power-ups dictate tempo and rally swings.

## 2. Core Movement & Controls
### Movement:
* **W, A, S, D or Arrow Keys** for directional movement.
* **Spacebar** for standard jump.
* **Left Shift** for a short dive/slide toward the ball (spends brief cooldown/stamina to save low drops).
* **Q and E** for powerups or debuff use.

### Hitting & Directional Aiming:
* **Left Click:** Swing
  * **Hit Registration:** Generous spherical hitbox around the paddle. If the ball enters the sphere when clicked, it registers as a clean return.
  * **Shot Placement:** Ball trajectory dynamically inherits player movement vector at the moment of impact. (e.g., strafing right while clicking aims cross-court right).

### Timing & Feedback Assist:
* A pulsing landing reticle on the court floor displays where and when the ball will bounce.
* The reticle changes color (Red -> Yellow -> Green) to signal the optimal hit timing window.
* No cooldown for hits on perfect hits.

### Rally Acceleration (Volley Escalation):
* Ball speed scales upward by +5% per perfect hit, resetting back to base speed whenever a point is scored.

## 3. Environment & Court
* **Map Concept:** A modern penthouse/high-rise rooftop overlooking a skyline.
  * LED lights around court / building.
  * Change color / oscillation depending on pace of game.
* **Boundary Rules:**
  * A default transparent safety railing borders the building perimeter.
  * *(Toggle / Casual Modifier):* Low railings where over-committing to a dive-slide can knock a player off the edge, instantly conceding the rally.
* **Weather Factors (Stretch Goal):**
  * Wind vectors and rain traction are deprioritized as post-launch stretch goals to ensure core physics and network stability are locked down first.

## 4. Power-Up System (Field Modifiers)
Power-ups spawn periodically during play, dropping from above onto random court tiles and idling as floating orbs for a few seconds (3-6?) before despawning. Players must balance court positioning with risking a detour to grab an orb. Walking into the power up with an empty slot picks up a new one. Debuffs are a stretch goal. Dual power up structure: get two, choose one. 3 minimum powerups & debuffs; Increase to 5 each if easy to integrate.

| Power-Up | Type | Visual Cue | Gameplay Effect |
| :--- | :--- | :--- | :--- |
| **Zero-G Pulse** *(Stretch?)* | Environmental | Pale Blue Glow / Sky Floats | Reduces gravity by 60% for 8 seconds. Ball floats slowly, offering a breather when rally speeds get out of hand. |
| **Big Paddle** | Buff | Bright Green Glow; bigger paddle | Paddle size increases by 1.75x for 10 seconds, drastically expanding the hit registration range. |
| **Heatseeker** *(Laser Dink)* | Buff | Fiery Red Trail on Ball; paddle on fire | The next hit gains a homing curve toward the deepest open corner of the opponent’s baseline. |
| **Glow Ball** *(Night Mode)* *(Stretch)* | Environmental | Arena dims to night; ball glows neon | High contrast makes tracking hyper-fast late-rally balls effortless while dimming opponent view. |
| **Slip Stream** | Debuff | Yellow Puddle | Drops a slick zone on the opponent’s side; running through it causes a 1-second slide delay. Slippery floor. |
| **Speed Cleats** | Buff | Cyan trail on player boots | Increases player movement speed by +40% for 8 seconds. Shorter swing cooldown. |
| **Small Paddle** | Debuff | (???) | Opponent paddle size decreases to half of its original size, making it harder to get a good hit. |
| **Drops Pickles** | Debuff | Pickles | Stepping on a pickle causes a slide/dive and the player has to recover to resume their play. |

## 5. Complete Rules Engine (UI "How to Play")
* **Underhand Serve:** The server must strike the ball below waist level diagonally cross-court into the opponent’s service box.
* **Two-Bounce Rule:**
  * The serve must bounce once before being returned.
  * The return-of-serve must also bounce once before being played.
  * After these two bounces, players may volley the ball out of the air or play it off a single bounce.
* **The Kitchen (Non-Volley Zone):**
  * The 7-foot box extending on either side of the net.
  * Players cannot hit the ball out of the air while contacting or stepping into the Kitchen. Volleying inside the Kitchen results in an immediate fault.
* **Faults:** A point/side-out is triggered if the ball lands out-of-bounds, hits the net without crossing, bounces twice on one side, or if a Kitchen violation occurs.
* **Scoring & Match Format:**
  * **Side-Out Scoring:** Only the serving team/player scores points upon winning a rally.
  * **Match Length:** Standard match played to 11 points (win by 2), or a Quick Match toggle to 7 points.

## 6. User Interface & Visual Effects
### Heads-Up Display (HUD):
* **Live Scoreboard:** Displays current score (e.g., Server - Receiver - Server #) and current game of a "Best of 3" session tracker.
* **Rally Speed Multiplier:** Speed indicator showing current ball velocity boost (1.0x, 1.2x, etc.).
* **Power-Up Inventory / Active Buffs:** Icons indicating current active buff and remaining duration timer.
* **"How to Play" Modal:** Expandable screen overlay breaking down Kitchen rules, Two-Bounce rule, and power-up icons.

### Match Banners & Alerts:
* Dynamic center-screen pop-ups: SERVE, FAULT!, KITCHEN VIOLATION, MATCH POINT, and VICTORY / DEFEAT.

### Visual Effects (VFX):
* Character aura tint corresponding to picked-up power-ups (e.g., green for Paddle, blue for Zero-G).
* Ball speed trails turning from white to orange/fire as the rally counter escalates.

## 7. Audio
* Background audio
* Foot steps
* Power ups obtained
* Menu sfx
* Ball hit
* Victory sfx
* Defeat sfx

## Development Roadmap
**Platform:** PC, Mac, Android, iOS | **Audience:** E

* **GDD v1.0:** 09/30/2026 *(Core movement)*
* **PROTOTYPE:** 10/15/2026 *(Core environment and swing mechanics)*
* **MIDTERM:** 10/31/2026 *(Powerups and UI)*
* **BETA:** 11/10/2026 *(Testing and improvements)*
* **FINAL:** 11/15/2026

## 8. Lobby & Meta Systems
* Standardizing hitting for every avatar and tweaking hitting hitbox.
* Standardize character model.

### Lobby Flow & Aesthetics:
* Apartment lobby look.
* Receptionist desk when you spawn in (daily check in).
* Shop (paddles, skins, court colors (only their view)).
* Cafe (powerups) - stretch.
* Achievements/stats screen.
* Elevator to queue; right before the elevator goes up, you can choose whichever map/modifier/etc.
* Players in that lobby vote on what they want.
* Different elevators (classic, arcade, chaotic) and (1v1, 2v2).
* Player presses elevator button to queue; once match is created, players are teleported into elevator for map selection.
* Barebones lobby system that allows players to queue 1v1, 2v2, spectate, or play w/ bots.
* Simultaneous games, multiple court lobbies.

### Miscellaneous Mechanics & Tweaks:
* Charging mechanic for serve, auto serve in 15 seconds.
* Highlighted name of server.
* Nerfed stamina system.
* Ball physics to be less floaty when receiving lobs.