# Elevator party architecture

## Existing systems inspected
- `Lobby.build()` builds two elevator banks with three decorative fronts each (six total, also confirmed in the connected Studio place). Frames are solid blocks; doors have no movement or occupancy behavior.
- `MatchQueue` groups Play-menu players by exact ruleset and format, then votes on map and dispatches a complete group. Rulesets are `Classic`, `Arcade`, and `Chaos`; Chaotic UI must map to `Chaos` internally.
- `init.server` owns exclusive court membership, runtime allocation, queue dispatch, and lobby return. Courts are reused at vertical offsets; there is no cross-place teleport.
- `CourtSession` owns physics, serving, teams, intro, scoreboard, spawning, and gameplay. Spectators have side zero and use the existing `Spectator` presentation module.
- Existing departures immediately eject remaining active players; replacement must intercept this behavior and pause the authoritative simulation.
- Progression, shop, check-in, and gameplay rules remain outside this feature.

## Implementation contract
Use all six existing fronts: three left-bank 1v1 elevators and three right-bank 2v2 elevators. Recess enclosed cabins through matching openings in the bank backdrops and structural rear wall layers. Retain bank architecture and lighting, split each original metal door into two telescoping leaves, and replace mode labels with capacity labels. Configuration owns assignments and timing.

Elevator state progresses Waiting -> Voting (ruleset) -> MapVoting -> Departing (winning-map reveal) -> court admission -> loading-ready barrier -> four-second overview. Queue players retain their original preference while invited; acceptance atomically removes queue membership. Specific preferences constrain allowed votes before readiness. A reservation temporarily prevents normal queue dispatch from racing an invitation.

Match records track original players, active seats, and approved replacements separately from spectators. Vacancy handling pauses first, offers queued players sequentially, then spectators sequentially, and terminates with a five-second lobby countdown when exhausted.

## Delivered experience

All six existing fronts are operational. LeftA, Left, and LeftB are 1v1 (two players each); RightA, RightC, and RightB are 2v2 (four players each). The cabins sit behind their original doorway plane, with localized openings through walnut backdrops, the reception feature wall, and structural rear wall. Each recessed shaft has its own enclosed walls, ceiling, and supporting floor. Wall segments outside the openings retain their original materials and collision. Sconces, bank headers, and lobby furniture remain.

Each elevator detects live character roots on the server every 0.15 seconds. Four metal door leaves per elevator telescope into depth-separated stacks behind fixed pocket covers. TweenService keeps every panel within the original twelve-stud frame throughout motion. Doors remain open for occupants/nearby players, and use a 1.5-second hold to avoid boundary chatter. Capacity signs initialize at zero and update with authoritative state. Physical exit, Leave Elevator, disconnect, or character removal clears membership and resets readiness/voting. Waiting has no timeout.

A full party can ready up. Everyone must be ready; only current roster revisions may send valid ready/vote requests. Voting lasts up to 15 seconds, resolves early when all have voted, and chooses randomly between tied eligible modes. UI calls Chaotic the existing internal Chaos ruleset. Physical entrants without a menu preference accept either mode. Any accepted specific preference restricts the eligible vote options for everyone; conflicting preferences cannot join. This prevents a vote from putting an invited solo player into an incompatible match.

After mode voting, every party member gets colorful map cards with live scenery previews, names, vote counts, and their selection indicator. Each member may vote once for Rooftop or Moon. Map voting lasts up to 15 seconds and resolves early when all votes arrive; ties are randomly resolved by the server between tied maps. Mode and map are independent. The winner is revealed while the doors close, then all members enter the selected existing court environment. Every active player must acknowledge scenery loading before the same four-second live map overview begins. A smooth camera move and fades hand off to regular gameplay. Classic serves and the existing Chaos draft remain gated until the overview ends. The elevator movement animation, avatar showcase, movement sound, and arrival ding have been removed.

## Play-menu integration

The menu files and design are unchanged. Existing mode/format selection, map voting, practice, 1v2, and independent court dispatch remain. A separate Elevator RemoteEvent carries the new flow.

Only queued lobby players with matching 1v1/2v2 format and a compatible Classic/Chaos preference are invited into parties. An outstanding offer reserves the candidate in their existing queue for at most ten seconds, preventing normal queue dispatch from racing acceptance. Decline/timeout retains the original queue; accept atomically removes that queue membership and admits the player. Existing active map-setup groups cannot be recruited. Arcade remains outside elevator-party voting; selected-mode replacement offers for existing Arcade matches still support the Arcade queue. Any Mode is supported for physical elevator entrants; the existing Play menu has no Any Mode choice and was not redesigned to add one.

## Match departures and substitution

Both elevator and existing-menu 1v1/2v2 matches receive records containing immutable original user IDs, current active seat assignments, and approved substitutes. Spectators stay outside the active roster.

Before removing a departing active player, the owning court pauses input, serving, physics, effects, movement, and associated deadlines. Remaining players retain their team. Offers proceed one candidate at a time: matching queued solo players first, then spectators of that specific court. Each offer expires after ten seconds. Only the outstanding offer ID can accept; stale or duplicate acceptance cannot claim a seat. A substitute leaves spectator presentation, receives the exact vacant team and slot, and spawns through existing court code. Existing roster-change preparation runs; the scoreboard survives replacement. Play resumes only when every vacancy is filled.

Exhausted candidates produce a five-second termination notification. All remaining participants and spectators return to the lobby; the runtime, court instance, ownership, and temporary pause/spectator state are cleaned up.

## Files

Created:
- src/server/ElevatorConfig.luau: centralized assignments, sizes, door hold/tween, poll, offer/mode-vote/map-vote/reveal/overview/termination timings.
- src/server/ElevatorGeometry.luau: wall opening conversion, recessed cabins, themed interior fittings, capacity signs, contained telescoping doors, and world-space detection bounds.
- src/server/ElevatorParty.luau: isolated authoritative membership, readiness, preference intersection, voting, and departure state.
- src/server/ElevatorService.luau: physical occupancy, exclusive memberships, consent offers, original/active/substitute records, and replacement coordination.
- src/client/ElevatorUI.luau: responsive party, voting, invitations, status/countdown, colorful map cards, live selections, winning-map reveal, and admission fade.
- src/server/MapCatalog.luau: central map IDs, names, colors, descriptions, and overview camera positions; shared with clients.
- src/client/MapOverview.luau: selected-environment loading acknowledgement, synchronized four-second camera overview, fades, and camera cleanup.
- tests/ElevatorParty.spec.luau, tests/ElevatorService.spec.luau, tests/ElevatorGeometry.spec.luau, tests/CourtReplacement.spec.luau, tests/ElevatorMapTransition.spec.luau.
- ELEVATOR_PARTIES.md: inspection, implementation, setup, evidence, and remaining verification.

Modified:
- src/server/MatchQueue.luau: invitation reservation/release and dispatch exclusion while reserved.
- src/server/CourtSession.luau: replacement pause/resume, exact-seat admission, paused deadlines, and cleanup.
- src/server/init.server.luau: Elevator remote, coordinator startup, shared court admission, tracked departures, and termination cleanup.
- src/client/init.client.luau: additional UI startup.
- src/client/MatchIntro.luau: delegates elevator overview packets; existing Play-menu VS/loading presentation remains.
- default.project.json: shared map catalog mapping.

No Play-menu implementation, MatchSetup rules, Classic/Chaos mechanics modules, progression, XP, shop, check-in, or Spectator module was changed.

## Studio setup and assets

Sync with the existing Rojo project and start Play. Server/client folders already include the new modules through default.project.json; no manual RemoteEvent placement, elevator tags, external dependencies, or asset uploads are required. Geometry is configured at runtime from the retained bank fronts rather than saved over the edit-mode lobby.

Adjust ElevatorConfig for assignments and timings. Assignments reference original fronts sorted left-to-right in each bank; capacities must agree with 1v1/2v2 formats. MapCatalog owns map metadata and camera endpoints. New maps need a catalog entry plus their actual environment builder, preview, and shared MatchSetup/environment validation support. Existing MapThumbnail/MapPreviews assets supply card imagery without uploads. Server bootstrap publishes the catalog through the existing shared-module convention. No elevator travel audio is played.

Studio progression logged its existing API-access/DataStore rejection during Play. This feature does not require enabling Studio DataStore access, and that setting was not changed.

## Verification results

Initial implementation passed eight suites in Studio Play using the repository's injected-module/function-spec convention:
1. ElevatorParty: two/four-player capacity, indefinite waiting, readiness, membership validation, duplicate votes, deadline rejection, reset, compatible preferences, majority/ties, and queue reservation races.
2. ElevatorService: accept/decline, exclusive membership, invalidated invitation IDs, current/stale roster tokens, queue-first replacement, sequential spectator offers, ten-second expiry, exact approval, and five-second termination.
3. ElevatorGeometry: six recessed elevators, assigned capacities, unobstructed structural wall openings, interior/exit bounds, themed fittings, metal door materials, and completed telescoping door tweens constrained to the original frame.
4. CourtReplacement: authoritative pause and blocked serve, spectator approval, occupied-seat rejection, exact team/slot restoration, scoreboard preservation, resume, and cleanup.
5. Existing MatchQueue suite.
6. Existing QueueEarlyStart suite.
7. Existing CourtSession suite (concurrent courts, practice isolation, independent scores/balls, Arcade selection, rejoin, and shutdown cleanup).
8. Existing MatchQueueAdmission suite (winning settings, one dispatch, failed admission rollback, and departed-player fallback).

Studio disables loadstring in Play. Tests were executed with compiled source factories injected into the same existing spec environments instead of changing that server setting. Temporary factory state was removed by stopping Play. Detached test instances were destroyed by their specs.

Live single-client smoke checks passed: cabin entry, server ElevatorId, opening door positions, sign 1/2, replicated party roster, Ready hidden below capacity, premature requests ignored, Leave Elevator clearing occupancy/UI, doors returning closed, and existing Classic/1V1 menu queue joining/cancelling afterward.

All changed scripts compiled in Studio; rojo build -o tmp/elevator-validation.rbxlx passed; git diff --check passed.

## Remaining acceptance work

The server paths above are implemented and tested, but these are not substitutes for a real multi-client session. Before publishing, run Studio Server & Clients with four clients and verify:
- Friends physically entering the same 2v2 cabin, crowd collision/comfort, overcapacity ejection, independent doors, and simultaneous leave/reset races.
- Real-client invitation countdowns/accept/decline, preference restrictions, full-party readiness, live vote indicators, and majority/tie outcomes.
- Real-client map voting and winner reveal, simultaneous scenery readiness, the four-second overview and fades on both maps, and Classic/Chaos gameplay afterward.
- Real disconnections during voting/departure/live rallies, queued replacements before spectators, sequential spectator decline/timeout/accept, multiple vacancies, and five-second return of every viewer.
- Device layouts, controller/touch behavior, slow networking/streaming, reset during replacement, failed runtime admission, and server shutdown.

No real multi-client transition is claimed. No cloud publish was performed.


## Six-elevator interior update

All six cabins now include walnut wall lining, smoked-metal mirror panels, champagne handrails and brackets, navy floor insets with marble borders, rear club plaques, decorative elevator button panels, warm ceiling diffusers, and cyan/pink lighting accents. These are code-built assets and require no uploads. CabinDepth, DoorStackX, DoorPanelDepth, ApproachForward, and all six assignments are centralized in ElevatorConfig.

Validation for this update: geometry, authoritative party, and invitation/replacement coordinator specs passed with the six-elevator configuration. Live Studio verified three functioning elevators per side, four contained door leaves per elevator, clear cabin paths in all six shafts, successful entry and occupancy signage, and the arrival overlay clearing with matching 1,904 descendant counts. The interior was visually inspected in Play. Multi-client crowd testing remains outstanding.


## Map voting and overview update

The elevator party and coordinator tests now cover mode/map separation, per-member map ballots, invalid/stale/duplicate rejection, published totals, both random tie outcomes, abstentions, leave/disconnect resets, selected-map admission, and reentrant update protection. Court simulation covers all four combinations of Classic/Chaos and Rooftop/Moon, per-player loading acknowledgements, the full shared four-second overview, normal Classic serve or Chaos draft afterward, and a map-load timeout callback.

Map loading uses the existing IntroReady channel with an elevator-only overview payload. A failed preparation returns the whole group through normal lobby ownership rather than leaving players in a stuck intro. Court slots are reserved while either queue or elevator admission builds scenery; reservations are released on success/failure, and elevator roster validity is checked across yielding initialization.

Live single-client checks: map cards and real scenery previews displayed correctly; no old ElevatorRide object remained; the rooftop readiness/overview smoke test completed; an isolated actual Moon environment replicated all 11,028 descendants, acknowledged readiness, rendered 240 frames during its four-second camera move, then restored the normal camera. Temporary scenes/UI were removed. These checks do not replace a real multi-client session.

Final map-update verification: nine suites passed (party, coordinator, selected-map transition, geometry, court sessions, replacements, queue, early start, and queue admission). Rojo packaging and whitespace checks passed.
