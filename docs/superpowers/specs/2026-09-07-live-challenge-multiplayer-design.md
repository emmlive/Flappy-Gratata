# Flappy Gratata — Live Challenge Multiplayer Architecture

**Date:** 2026-09-07  
**Status:** Approved design; awaiting repository commit and user review  
**Project:** Flappy Gratata 3.0  
**Scope:** V1 1-vs-1 Game Center real-time multiplayer

## Product intent

Live Challenge adds true simultaneous head-to-head races between Game Center friends while preserving Classic and Academy gameplay integrity.

**Challenge Friend → Invite → Lobby → Ready → 3…2…1…FLY → Shared-Course Race → Finish Window → Verified Result → Rematch**

V1 must be fast, fair, simple, and premium. It must not create pay-to-win mechanics, change Classic physics, interfere with Academy progression, or require a custom multiplayer backend.

## Architecture

Use **Game Center real-time multiplayer + deterministic shared-course synchronization**.

Game Center owns player identity, friend invitation/acceptance, and the live peer session. Flappy Gratata owns the immutable race contract, deterministic course generation, local bird simulation, opponent ghost rendering, validation, result verification, and local multiplayer records.

Each device is authoritative only for its own bird. Neither peer may control the other player's physics, collision decisions, score, or local course.

## Match lifecycle

**Home → Challenge Friend → Game Center Invitation → Friend Accepts → Pre-Race Lobby → Both Ready → Contract Lock → Countdown → Live Race → First Crash → 3-Second Finish Window → Verification → Results → Rematch / Exit**

The match must not start unless both peers establish the same Race Contract.

## Race Contract

Before countdown, both devices must agree on:
- unique race ID;
- deterministic course seed;
- course-generation version;
- gameplay/ruleset version;
- multiplayer protocol version;
- both Game Center player IDs;
- synchronized start target;
- 3-second finish window;
- 5-second reconnect grace;
- tie-breaking rules;
- compatibility fingerprint for protected gameplay constants.

Any material mismatch fails closed before race start.

## Live race rules

- V1 is 1-vs-1 only.
- Opponent is an invited Game Center friend.
- Both players receive the same deterministic obstacle sequence and ruleset.
- Both must be connected and Ready before countdown.
- Challenge cannot alter flap impulse, gravity, gap size, obstacle speed, hitboxes, collision rules, scoring, or other protected gameplay physics.
- Opponent is shown as a semi-transparent live ghost with a subtle ahead/behind indicator.
- Ghosts never collide with or affect each other.
- First crash starts a 3-second finish window.
- Surviving player may continue during that window.
- Greater verified synchronized progress wins.
- If progress is equal, compare score.
- If still exactly equal, record a draw.
- No unilateral pause during an active race.
- Backgrounding enters reconnect handling instead of pausing the opponent.
- Intentionally leaving an active verified race counts as a forfeit unless the system is already in a valid void state.
- A rematch always creates a fresh race ID and synchronized start.
- Cosmetics are visual only and cannot alter collision geometry or performance.
- Academy rank, skill bands, Flight DNA, cosmetics, ownership, or monetization may not alter Challenge difficulty or physics.
- No wagering, paid rematch, power purchase, or other pay-to-win mechanic.

## Disconnect/reconnect rules

During a race:
- a disconnected player receives 5 seconds to reconnect;
- return inside grace resumes the same race contract;
- failure to return causes that player to forfeit;
- if both disconnect, the match is void;
- void/unverified matches do not affect competitive records;
- late/stale packets may not rewind race progress.

Before start, connection loss cancels the lobby without a result.

## Synchronization

Use **local authority + shared contract**.

Each device simulates its own bird, derives the same course from the shared seed, sends compact opponent-state snapshots, and independently verifies the result.

Packets may contain:
- race ID;
- player ID;
- monotonic sequence number;
- timestamp;
- progress/checkpoint;
- score;
- bird Y position;
- velocity/motion hint for ghost interpolation;
- alive/crashed state;
- disconnect state;
- final race record.

Do not stream or remotely drive local bird physics.

## Packet ordering and ghost rendering

- Sequence numbers increase monotonically.
- Duplicates are ignored.
- Older packets are ignored.
- Stale packets cannot change verified progress.
- Ghost motion is interpolated visually.
- Interpolation cannot affect local physics, scoring, collision, or result logic.
- Network jitter may degrade ghost smoothness only.

## Result verification

Neither peer trusts a claimed winner status directly.

At completion:
1. each device produces a final race record;
2. both exchange records;
3. each independently derives the outcome from the shared contract and verified progress;
4. both derived outcomes must agree.

If they disagree, the result is **UNVERIFIED_VOID** and the UI says:

**“Race could not be verified — no result recorded.”**

No competitive totals change.

## Fair-play safeguards

- Progress must move forward monotonically.
- Score must match valid obstacle progress.
- A crashed player cannot become alive again in the same race.
- Reported progress must be compatible with the deterministic course.
- Impossible/inconsistent timing or state is rejected.
- Malformed, out-of-contract, or version-incompatible data fails closed.
- Neither peer has authority to declare the other player's result.
- No hidden host advantage.
- One suspicious race never triggers an automatic ban in V1.

## Multiplayer Record

Keep multiplayer separate from Classic high score and Academy progression.

Aggregate:
- Wins
- Losses
- Draws
- Current Win Streak
- Total Live Races
- Best Win Streak

Per-friend head-to-head:
**You vs SkyRider — 7W • 4L • 1D**

Void/unverified races do not change totals.

## Local history

Store versioned Challenge history on-device only:
- race ID;
- opponent Game Center player ID;
- display name when available;
- result;
- score;
- distance/progress;
- timestamp;
- verification state;
- outcome: win/loss/draw/void.

V1 adds no custom accounts, passwords, friend database, chat, private messages, contacts access, location storage, or custom multiplayer backend.

Device-local history may not survive app deletion/device migration. This limitation is accepted for V1.

## Privacy boundary

Store only multiplayer identity references and race history required by the feature. Do not collect location, contacts, chat content, or unnecessary personal data.

If Game Center is unavailable or signed out, Challenge Friend is unavailable while Classic and Academy continue normally.

## Main menu and UX

**Challenge Friend** is a first-class main-menu destination alongside Classic and Academy.

Flow:
**Home → Challenge Friend → Game Center Friend Picker → Lobby → Ready → Countdown → Race → Result → Rematch / Home**

Surface Game Center identity, Multiplayer Record, Invite Friend, invitation state, Ready/Not Ready, and Rules.

## Rules card

Lobby and results include a visible **Rules** control explaining:
- same course;
- no player interference;
- synchronized start;
- 3-second finish window;
- 5-second reconnect grace;
- disconnect forfeits;
- both-disconnect void;
- draws;
- verification;
- rematches;
- no pay-to-win advantage.

## Result states

Support:
- **You Win**
- **You Lost**
- **Draw**
- **Unverified**

Show local/opponent progress, verified result, updated Multiplayer Record when applicable, Rematch, and Back to Home.

## Failure states

- Friend unavailable → return to invite flow.
- Invitation declined → no result/penalty.
- Game Center unavailable → Challenge unavailable only.
- Version mismatch → “Update required to race this friend.”
- Race contract mismatch → do not start.
- Connection lost before start → close lobby without result.
- Connection lost during race → use reconnect/forfeit/void rules.
- Final result mismatch → unverified void.
- Invalid/malformed race state → fail closed, never guess.

## Component boundaries

- **FGChallengeCoordinator** — match lifecycle.
- **FGChallengeRaceContract** — immutable seed, versions, timers, participants, compatibility fingerprint.
- **FGChallengeTransport** — Game Center real-time networking wrapper.
- **FGChallengeGhostRenderer** — opponent rendering/interpolation only.
- **FGChallengeResultVerifier** — independently derives/validates outcomes.
- **FGChallengeRecordStore** — versioned local records and head-to-head history.
- **FGChallengeLobbyController** — invite/lobby/ready/rules/reconnect UX.
- **FGChallengeResultsController** — result/rematch/exit UX.
- **FGChallengeRules** — canonical finish, reconnect, tie, forfeit, draw, and void rules.

## Protected Classic isolation

Challenge Friend must not silently modify or re-baseline protected Classic gameplay.

Use a dedicated deterministic Challenge course generator/configuration boundary.

If a protected gameplay source must later be touched, require a separate explicit gate with:
- narrowly justified hook;
- preserved Classic behavior;
- protected-hash review;
- targeted tests;
- real runtime validation.

No opportunistic Classic refactoring is authorized.

## Academy / Flight DNA boundary

Challenge Friend is not an Academy subfeature.

V1 does not:
- change Academy skill scores from multiplayer;
- change Academy rank;
- implement Flight DNA;
- alter Challenge physics based on Academy/DNA state.

Any future integration requires a separate approved design.

## Game Center boundary

Use Game Center for authentication/identity, friend invitation, and real-time peer session.

Exact low-level GameKit APIs are intentionally not frozen here. Before implementation, verify current official Apple GameKit documentation for supported authentication, invitation, real-time matchmaking/session, and deployment-target APIs. Do not reintroduce deprecated APIs just because legacy Flappy Gratata used them.

## Deterministic tests

Verify at least:
- same seed → same obstacle sequence;
- different seed → different valid sequence;
- contract mismatch prevents start;
- protocol/version mismatch prevents start;
- duplicate/stale packets ignored;
- progress cannot move backward;
- finish-window timing;
- draw/tie-break rules;
- reconnect grace;
- one-player disconnect forfeit;
- both-player disconnect void;
- malformed state fails closed;
- result verifier agrees from both perspectives;
- unverified results do not affect records;
- rematch creates a fresh race identity.

## Game Center integration tests

Cover invite, accept, decline, unavailable friend, both-ready synchronization, countdown synchronization, ghost updates, reconnect, backgrounding, rematch, version mismatch, result disagreement, and Game Center unavailable.

## Physical-device validation

Before release, use full Xcode and two physical iPhones. Validate same-network and different-network play, latency/jitter, backgrounding, disconnects, reconnect grace, near-simultaneous crash, exact draw, rematch, Game Center authentication/invitations, and protected Classic regression.

## Release gate

Do not ship Challenge Friend from CommandLineTools-only validation.

Require:
- full Xcode;
- successful iOS build;
- Game Center entitlement/signing validation;
- current GameKit API verification;
- XCTest/runtime validation where applicable;
- two-device multiplayer testing;
- deterministic contract verification;
- protected Classic regression verification.

## V1 non-goals

V1 excludes:
- more than two players;
- public matchmaking;
- invite codes/web links;
- custom multiplayer backend;
- custom friend system;
- chat/messaging;
- tournaments/leagues;
- wagering;
- paid competitive advantages;
- mandatory best-of-three;
- consumable power-ups;
- multiplayer-driven Academy mutations;
- Flight DNA implementation;
- cross-device Challenge-history sync.

## Product summary

**Classic** — master the original flight.  
**Academy** — understand and improve how you fly.  
**Challenge Friend** — prove it live against a friend.

**Same course. Same rules. Live race. Verified result. Instant rematch.**
