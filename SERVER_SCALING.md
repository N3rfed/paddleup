# Public servers and independent sessions

The repository maps **one place** (`default.project.json`). The connected Studio place inspected during implementation was Paddle Up! (107151775650265), with one server Script and MaxPlayers=60. No teleport destinations, reserved-server flow, MemoryStore coordination, or cross-server queue exist in the project. Publishing/dashboard configuration may contain other places; this implementation requires only this start place.

Previously `init.server.luau` held one ball, score, roster, practice session, environment, countdown, and queue admission target. Multiple queued groups waited for that shared court. Player joins initialized lobby state; Session requests left the court or spectated, and completed Queue votes admitted players. Departures changed the shared roster.

Now `init.server.luau` boots the lobby and remotes once and owns a local queue and player-to-court assignment. `CourtSession.luau` contains the existing authoritative simulation in a factory. Each multiplayer group and each solo practice session gets separate state, bot, court, environment cache, scores, drafts, serve rotation, countdowns, and event subscriptions. Court geometry is translated vertically in 4096-stud intervals; gameplay rules are unchanged apart from height-aware coordinate wrappers. Lobby court 0 retains the original scenery and publishes menu previews. New courts are allocated lazily and reused after their participants leave. At most MaxPlayers session slots exist, covering the worst case of every visitor practicing alone. This is a local court pool, not a Roblox server registry.

The queue retains its existing single voting/reveal workflow; groups can play concurrently after admission. Practice still uses its existing solo queue and voting flow. Spectate selects the first active local court, or the original empty court if none is active. There is no court picker. Empty sessions with spectators can be reused. Multiplayer games retain their existing rematch behavior until a participant leaves; that departure or voluntary exit returns the remaining participants to the lobby. Spectators remain spectators. Match/session attributes invalidate old HUD messages and intro IDs. Avatar connections disconnect on transfer/departure, and pending spawns recheck ownership after yielding. Admission errors return the group to the lobby; initialization failures are logged and allow retry. BindToClose stops admissions and disconnects queue, remote, avatar, and heartbeat resources. No persistent gameplay data needs flushing.

## Roblox allocation and Creator Dashboard

Roblox's standard public join service chooses eligible public servers and allocates additional instances as needed, subject to platform rules, availability, and the published configuration. Scripts do not create public servers, set MaxPlayers, force a fleet size, or guarantee a particular fill order. Independent instances have separate DataModels and memory; this code does not coordinate across them. The local queue only matches players already in the same instance. It does not move players between instances or optimize cross-server occupancy.

Before publishing:

1. In Creator Dashboard, select the experience and its start place (Places -> the place -> Access/server settings). Ensure the experience is published and its audience/access permits the intended testers or public players.
2. Set the place maximum player count. **Start at 8**, then profile concurrent matches and worst-case solo practice before raising it. The inspected Studio setting was **60**; it was not changed by this implementation. Court scenery is replicated per occupied slot and reused, so memory and replication costs can be substantial. Higher court heights also reduce floating-point precision.
3. Keep Roblox default matchmaking/server scoring. Review the place's server-fill/social-slot settings: social reservations can leave room for friends, and occupancy is only one matchmaking consideration. No custom matchmaking configuration is required. Avoid a low target occupancy if you want players to meet in the local queue.
4. Publish the Rojo-mapped scripts. Keep only one enabled bootstrap Script; the DataModel initialization guard also prevents duplicate bootstrap connections. Ensure an old saved legacy server Script is not still enabled elsewhere. No API-service access, HTTP permission, MemoryStore, MessagingService, or third-party teleport setting is needed.

Official references: [Roblox matchmaking](https://create.roblox.com/docs/matchmaking), [default server scoring](https://create.roblox.com/docs/matchmaking/scoring), [Players.MaxPlayers](https://create.roblox.com/docs/reference/engine/classes/Players#MaxPlayers), [BindToClose](https://create.roblox.com/docs/reference/engine/classes/DataModel#BindToClose).

## Verification

Automated fixtures are regression checks, not proof of live public allocation. `tests/CourtSession.spec.luau` executes the actual controller with mock services/players and detached Instances. It checks two simultaneous multiplayer sessions plus practice, separate score tables and balls, practice pause isolation, departure, slot reuse, rejoin, duplicate joins, and idempotent shutdown/disconnection. `MatchQueueAdmission.spec.luau` exercises the real bootstrap dispatch function with destination mocks, including admission failure and a departure. Existing queue, practice, and gameplay fixtures remain applicable; source-extraction gameplay fixtures now take CourtSession source instead of bootstrap source. Run these with Luau/Studio test tooling; do not enable test scripts in the published game.

Studio manual multi-client acceptance:

1. Sync using Rojo and use Studio's Server & Clients testing mode (older versions: Test -> Start Server) with 6-8 clients. Confirm each arrives in the lobby once, sees the menu, and has CourtId=0.
2. With four clients queue two Classic 1V1 groups. Select different maps and admit both. Confirm each pair has its own CourtId, roster, ball, score, map, serve countdown, and intro. Play rallies on both courts and verify scoring/HUD isolation.
3. Use two more clients for separate solo practice sessions. Pause one, change difficulty, then resume. Confirm the other practice bot/countdown and both multiplayer games keep running. Check Moon and Rooftop lighting independently on different clients.
4. Leave during voting and reveal; remaining voters should wait for a replacement. Leave mid-match via the menu, then disconnect mid-match; peers should return to the lobby, other courts should continue. Cancel/requeue repeatedly and rejoin with a fresh client. Verify no duplicated intro, stale score/banner, retained freeze, duplicate paddle, or extra event response.
5. Spectate, leave spectate, respawn during an intro, and test Moon streaming/readiness timeout. Test with StreamingEnabled both as configured in the published place and with realistic network latency. Validate camera, held ball, bounce markers, shadows, audio/effects, and map previews at translated court heights.
6. Stop the local server with practice paused and active queues. Inspect Output for errors and verify a fresh test starts with a clean lobby. Profile server frame time, client memory, replication, and worst-case all-player solo practice before increasing capacity.

Published live acceptance (required):

1. Publish to a test experience with a small maximum player count and appropriate access. Join using Roblox's ordinary Play flow from enough distinct tester accounts to exceed a server's capacity. Do not use reserved servers as a substitute for this test.
2. Inspect the public server list and record distinct server JobIds and player counts (JobId is empty in some Studio contexts). Verify a second public instance appears as demand requires, every server stays within its configured maximum, and every instance initializes its lobby independently. Roblox may allocate servers earlier because of geography, social, or eligibility signals.
3. Play concurrent sessions in both instances. Change scores, pause practice, leave, and rejoin. Confirm no score, countdown, HUD, roster, or practice state crosses instances. Rejoin is allowed to land in a different instance and intentionally starts in its lobby.
4. Observe joins near capacity, server shutdown/disconnections, and empty-instance reclamation. Initial join failures/full-server routing happen before these game scripts run and are handled by Roblox's join flow. This project introduces no teleports, so there are no TeleportInitFailed/full-destination retry paths to implement.

Studio can validate local multi-client gameplay and simulated failures, but cannot establish public server creation, live routing/fill behavior, real instance capacity, regional placement, or cross-instance independence under production load. Those remain published-experience acceptance checks. Dashboard settings and publishing were not changed automatically.

## Implementation verification record

- Rojo build of `default.project.json`: passed.
- Luau syntax compilation: all 77 source/test files passed.
- Nine fixtures passed: CourtSession, CourtEnvironments, MatchQueue, QueueEarlyStart, MatchQueueAdmission, SharedModuleStartup, PracticeSession, PowerupServer, and JumpSlamServer. The fixtures ran in the Studio Luau executor with mock services and detached test objects; the open place's gameplay scripts/settings were not replaced.
- `git diff --check`: passed.
- No manual multi-client visual playtest, publishing, Dashboard changes, or live public allocation test was performed. These results do not prove dynamic public-server allocation or production performance.

## Files changed

Server implementation: `src/server/init.server.luau`, new `src/server/CourtSession.luau`, `src/server/CourtEnvironments.luau`, `src/server/CourtPickups.luau`, `src/server/MatchQueue.luau`, `src/server/MatchRules.luau`, `src/server/Spectator.luau`.

Client presentation and session filtering: new `src/client/CourtView.luau`, `src/client/init.client.luau`, `src/client/BallShadow.luau`, `src/client/EnvironmentLighting.luau`, `src/client/FigmaHUD.luau`, `src/client/MatchIntro.luau`, `src/client/PowerupDraft.luau`, `src/client/PracticeUI.luau`, `src/client/RallyEffects.luau`.

Regression fixtures: new `tests/CourtSession.spec.luau`, new `tests/CourtEnvironments.spec.luau`, `tests/MatchQueueAdmission.spec.luau`, `tests/SharedModuleStartup.spec.luau`, `tests/EnvironmentLighting.spec.luau`, `tests/JumpSlamServer.spec.luau`, `tests/PowerupServer.spec.luau`.

Documentation: `README.md`, new `SERVER_SCALING.md`.
