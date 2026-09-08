# Live Challenge Multiplayer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build V1 1-vs-1 Game Center real-time friend races with deterministic shared-course synchronization, live ghost rendering, fail-closed verification, rematches, and separate local multiplayer records without changing protected Classic gameplay.

**Architecture:** Add a new `spritybird/Challenge` subsystem that owns race contracts, deterministic course generation, transport, ghost state, result verification, records, lobby/results UI, and orchestration. Integrate Challenge Friend through the existing root `ViewController` and Xcode project while keeping `Scene.m`, `BirdNode.m`, `SKScrollingNode.m`, and `Score.m` behavior unchanged unless a separately approved protected-hook gate is opened.

**Tech Stack:** Objective-C, SpriteKit, UIKit, GameKit/Game Center real-time multiplayer, Foundation persistence, XCTest when full Xcode is available, static/Foundation harnesses on CommandLineTools-only hosts.

**Spec:** `docs/superpowers/specs/2026-09-07-live-challenge-multiplayer-design.md`

## Global Constraints

- V1 is live 1-vs-1 Game Center friend multiplayer only.
- Shared course must be deterministic and identical for both peers.
- Local bird physics remain locally authoritative.
- Opponent ghost is visual only and cannot affect physics, score, collision, or course state.
- First crash starts a 3-second finish window.
- Reconnect grace is 5 seconds.
- One-player disconnect beyond grace is a forfeit; both-player disconnect is void.
- Exact ties become draws.
- Unverified or mismatched outcomes become void and do not affect records.
- Challenge Friend is a first-class main-menu destination alongside Classic and Academy.
- Multiplayer records remain separate from Classic high score and Academy progression.
- No custom backend, public matchmaking, chat, tournaments, wagering, paid advantage, or Flight DNA integration in V1.
- Do not silently modify or re-baseline protected Classic gameplay.
- Protected files and expected hashes:
  - `spritybird/Classes/Scenes/Scene.m` → `50c6f4542d0a849f1122dcee726280bd867b049fd651dbd8b5e0df4ade2bc4f9`
  - `spritybird/Classes/Scenes/BirdNode.m` → `a0c050e3d2fba192fa0584a6d035306f235f690e7924be192b9d7d1db73d63b4`
  - `spritybird/Classes/Scenes/SKScrollingNode.m` → `5594f59de2c920747012fc977d2bf62aea9d4ffb0bb64e475785a2511d5c435f`
  - `spritybird/Classes/Models/Score.m` → `3276c37c32479aa793b940a8b218787f6753cd9a9e74c03dbc7746bf0aad2ac4`
- Before implementation, verify current Apple GameKit APIs from official Apple documentation; do not reintroduce deprecated APIs.
- Do not ship Challenge Friend from CommandLineTools-only validation.
- No push, merge, deploy, App Store mutation, production service call, or monetization work unless separately authorized.

---

## File Structure

### New Challenge subsystem

- `spritybird/Challenge/FGChallengeRules.h/.m` — canonical constants and result-rule helpers.
- `spritybird/Challenge/FGChallengeRaceContract.h/.m` — immutable race contract and compatibility validation.
- `spritybird/Challenge/FGChallengeCourseGenerator.h/.m` — deterministic obstacle sequence generation for Challenge only.
- `spritybird/Challenge/FGChallengePacket.h/.m` — compact serialized peer state with sequence ordering.
- `spritybird/Challenge/FGChallengeResultVerifier.h/.m` — independent final-result derivation.
- `spritybird/Challenge/FGChallengeRecordStore.h/.m` — versioned on-device multiplayer record/history.
- `spritybird/Challenge/FGChallengeTransport.h/.m` — GameKit real-time transport wrapper.
- `spritybird/Challenge/FGChallengeGhostRenderer.h/.m` — visual-only remote bird interpolation.
- `spritybird/Challenge/FGChallengeCoordinator.h/.m` — match lifecycle state machine.
- `spritybird/Challenge/FGChallengeLobbyViewController.h/.m` — invitation, ready, rules, and connection UI.
- `spritybird/Challenge/FGChallengeResultsViewController.h/.m` — result, record, rematch, exit UI.
- `spritybird/Challenge/FGChallengeRaceScene.h/.m` — Challenge-specific SpriteKit race scene consuming the deterministic course contract.

### Existing files to modify

- `spritybird/Classes/Controllers/ViewController.h`
- `spritybird/Classes/Controllers/ViewController.m`
- `Flappy Gratata.xcodeproj/project.pbxproj`

### Tests

- `tests/challenge/FGChallengeRulesTests.m`
- `tests/challenge/FGChallengeRaceContractTests.m`
- `tests/challenge/FGChallengeCourseGeneratorTests.m`
- `tests/challenge/FGChallengePacketTests.m`
- `tests/challenge/FGChallengeResultVerifierTests.m`
- `tests/challenge/FGChallengeRecordStoreTests.m`
- `tests/challenge/FGChallengeCoordinatorTests.m`
- `tests/challenge/FGChallengeTransportTests.m`
- `tests/challenge/FGChallengeSourceContractTests.py`

---

### Task 1: Establish the isolated Challenge implementation worktree and API baseline

**Files:**
- Create: `.worktrees/r10-live-challenge` via worktree workflow
- Read: `docs/superpowers/specs/2026-09-07-live-challenge-multiplayer-design.md`
- Read: `spritybird/Classes/Controllers/ViewController.h`
- Read: `spritybird/Classes/Controllers/ViewController.m`
- Read: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: approved spec.
- Produces: isolated implementation branch, verified Classic hash baseline, current GameKit API notes.

- [ ] **Step 1: Create an isolated worktree**

Use `superpowers:using-git-worktrees`. Create a branch named:

```text
modernization/flappy-gratata-3.0-live-challenge
```

with worktree:

```text
.worktrees/live-challenge
```

- [ ] **Step 2: Verify clean baseline**

Run:

```bash
git status --short
git rev-parse HEAD
```

Expected: clean worktree and recorded base HEAD.

- [ ] **Step 3: Verify protected Classic hashes**

Run:

```bash
shasum -a 256 \
  spritybird/Classes/Scenes/Scene.m \
  spritybird/Classes/Scenes/BirdNode.m \
  spritybird/Classes/Scenes/SKScrollingNode.m \
  spritybird/Classes/Models/Score.m
```

Expected: all four hashes match the Global Constraints exactly.

- [ ] **Step 4: Verify active Game Center integration and supported API surface**

Search the repo:

```bash
rg -n "GameKit|GKLocalPlayer|GKMatch|GKMatchmaker|GKMatchmakerViewController|authenticateHandler" spritybird
```

Then consult current official Apple GameKit documentation and record which supported real-time matchmaking/invitation/session APIs fit this deployment target.

Do not edit code in this step.

- [ ] **Step 5: Record implementation baseline**

Create:

```text
docs/superpowers/plans/2026-09-07-live-challenge-api-baseline.md
```

containing only:
- base HEAD;
- GameKit APIs selected from current official docs;
- any deployment-target compatibility limits;
- protected hashes.

Commit:

```bash
git add docs/superpowers/plans/2026-09-07-live-challenge-api-baseline.md
git commit -m "Document Live Challenge GameKit baseline"
```

---

### Task 2: Add canonical Challenge race rules

**Files:**
- Create: `spritybird/Challenge/FGChallengeRules.h`
- Create: `spritybird/Challenge/FGChallengeRules.m`
- Test: `tests/challenge/FGChallengeRulesTests.m`

**Interfaces:**
- Produces:
  - `FGChallengeFinishWindowSeconds`
  - `FGChallengeReconnectGraceSeconds`
  - `FGChallengeOutcome`
  - `FGChallengeCompareProgress(...)`

- [ ] **Step 1: Write failing tests**

Test:
- finish window equals 3.0;
- reconnect grace equals 5.0;
- greater progress wins;
- equal progress compares score;
- exact tie returns draw;
- void/unverified is not competitive.

- [ ] **Step 2: Run the focused test target**

With full Xcode:

```bash
xcodebuild test \
  -project "Flappy Gratata.xcodeproj" \
  -scheme "Flappy Gratata" \
  -only-testing:FlappyGratataTests/FGChallengeRulesTests
```

Expected: FAIL because Challenge rules do not exist yet.

On CommandLineTools-only host, compile the Foundation-only files with the existing Foundation harness pattern and record XCTest as NOT_PERFORMED.

- [ ] **Step 3: Implement minimal rules**

Define:

```objc
typedef NS_ENUM(NSInteger, FGChallengeOutcome) {
    FGChallengeOutcomeWin,
    FGChallengeOutcomeLoss,
    FGChallengeOutcomeDraw,
    FGChallengeOutcomeVoid,
    FGChallengeOutcomeUnverified
};

FOUNDATION_EXPORT const NSTimeInterval FGChallengeFinishWindowSeconds;
FOUNDATION_EXPORT const NSTimeInterval FGChallengeReconnectGraceSeconds;
```

Set values to `3.0` and `5.0`.

- [ ] **Step 4: Re-run tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeRules.h \
        spritybird/Challenge/FGChallengeRules.m \
        tests/challenge/FGChallengeRulesTests.m
git commit -m "Add Live Challenge race rules"
```

---

### Task 3: Implement immutable Race Contract

**Files:**
- Create: `spritybird/Challenge/FGChallengeRaceContract.h`
- Create: `spritybird/Challenge/FGChallengeRaceContract.m`
- Test: `tests/challenge/FGChallengeRaceContractTests.m`

**Interfaces:**
- Consumes: `FGChallengeRules`.
- Produces:
  - `FGChallengeRaceContract`
  - `-isCompatibleWithContract:reason:`
  - `-dictionaryRepresentation`

- [ ] **Step 1: Write failing contract tests**

Cover equality/mismatch for:
- race ID;
- seed;
- course generation version;
- gameplay/ruleset version;
- protocol version;
- both player IDs;
- synchronized start;
- finish window;
- reconnect grace;
- compatibility fingerprint.

- [ ] **Step 2: Verify RED**

Expected: contract class missing.

- [ ] **Step 3: Implement immutable contract**

Use readonly properties and a designated initializer requiring all contract fields.

Compatibility validation must fail closed and provide a machine-readable mismatch reason.

- [ ] **Step 4: Verify GREEN**

Run focused tests; expect PASS.

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeRaceContract.h \
        spritybird/Challenge/FGChallengeRaceContract.m \
        tests/challenge/FGChallengeRaceContractTests.m
git commit -m "Add deterministic Challenge race contract"
```

---

### Task 4: Build deterministic Challenge course generation

**Files:**
- Create: `spritybird/Challenge/FGChallengeCourseGenerator.h`
- Create: `spritybird/Challenge/FGChallengeCourseGenerator.m`
- Test: `tests/challenge/FGChallengeCourseGeneratorTests.m`

**Interfaces:**
- Consumes: race seed + course-generation version.
- Produces:
  - `FGChallengeObstacleDescriptor`
  - `-obstaclesForSeed:count:`

- [ ] **Step 1: Write failing deterministic tests**

Assert:
- same seed + same version → byte-for-byte equivalent obstacle descriptors;
- different seed → different valid descriptor sequence;
- generated values obey Challenge course bounds;
- generator never reads network state or mutable global randomness.

- [ ] **Step 2: Verify RED**

Expected: generator not defined.

- [ ] **Step 3: Implement minimal deterministic PRNG-backed generator**

Use a fixed, documented integer PRNG algorithm owned by Challenge code rather than `arc4random()` or process-global randomness.

Do not modify Classic obstacle generation.

- [ ] **Step 4: Verify GREEN**

Run test repeatedly with same seeds and confirm stable output.

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeCourseGenerator.h \
        spritybird/Challenge/FGChallengeCourseGenerator.m \
        tests/challenge/FGChallengeCourseGeneratorTests.m
git commit -m "Add deterministic Challenge course generator"
```

---

### Task 5: Add compact ordered peer packets

**Files:**
- Create: `spritybird/Challenge/FGChallengePacket.h`
- Create: `spritybird/Challenge/FGChallengePacket.m`
- Test: `tests/challenge/FGChallengePacketTests.m`

**Interfaces:**
- Produces packet fields:
  - race ID;
  - player ID;
  - sequence number;
  - timestamp;
  - progress checkpoint;
  - score;
  - bird Y;
  - motion hint;
  - alive/crashed state;
  - disconnect state;
  - optional final record.

- [ ] **Step 1: Write failing serialization/order tests**

Cover:
- round trip serialization;
- malformed packet rejection;
- missing race ID rejection;
- duplicate sequence rejection;
- stale sequence rejection.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement packet serializer/parser**

Use a small Foundation representation with explicit versioning and strict field-type validation.

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengePacket.h \
        spritybird/Challenge/FGChallengePacket.m \
        tests/challenge/FGChallengePacketTests.m
git commit -m "Add ordered Challenge peer packets"
```

---

### Task 6: Implement independent result verification

**Files:**
- Create: `spritybird/Challenge/FGChallengeResultVerifier.h`
- Create: `spritybird/Challenge/FGChallengeResultVerifier.m`
- Test: `tests/challenge/FGChallengeResultVerifierTests.m`

**Interfaces:**
- Consumes: Race Contract + both final race records.
- Produces:
  - `FGChallengeVerifiedResult`
  - `-verifyLocalRecord:remoteRecord:contract:`

- [ ] **Step 1: Write failing verifier tests**

Cover:
- greater progress wins;
- equal progress + greater score wins;
- exact tie draws;
- one-player disconnect after grace forfeits;
- both disconnect voids;
- contradictory final records return unverified;
- mismatched contract returns unverified;
- malformed final record returns unverified.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement fail-closed verifier**

Never accept a remote `winner` field as authority. Derive result independently from validated fields.

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeResultVerifier.h \
        spritybird/Challenge/FGChallengeResultVerifier.m \
        tests/challenge/FGChallengeResultVerifierTests.m
git commit -m "Add fail-closed Challenge result verification"
```

---

### Task 7: Add versioned local Multiplayer Record store

**Files:**
- Create: `spritybird/Challenge/FGChallengeRecordStore.h`
- Create: `spritybird/Challenge/FGChallengeRecordStore.m`
- Test: `tests/challenge/FGChallengeRecordStoreTests.m`

**Interfaces:**
- Produces:
  - aggregate wins/losses/draws/current streak/best streak/total races;
  - per-friend W/L/D;
  - recent race history;
  - `-recordVerifiedMatch:`
  - `-recordVoidDiagnostic:`

- [ ] **Step 1: Write failing persistence tests**

Verify:
- win increments wins and streak;
- loss resets current streak;
- draw increments draw/total but not streak;
- void/unverified changes no competitive totals;
- per-friend records remain isolated by Game Center player ID;
- corrupt records fail safely;
- schema version is persisted.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement minimal Foundation-backed versioned store**

Use on-device storage only. Do not add backend calls.

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeRecordStore.h \
        spritybird/Challenge/FGChallengeRecordStore.m \
        tests/challenge/FGChallengeRecordStoreTests.m
git commit -m "Add local Challenge multiplayer records"
```

---

### Task 8: Wrap Game Center real-time transport

**Files:**
- Create: `spritybird/Challenge/FGChallengeTransport.h`
- Create: `spritybird/Challenge/FGChallengeTransport.m`
- Test: `tests/challenge/FGChallengeTransportTests.m`

**Interfaces:**
- Consumes: current GameKit APIs selected in Task 1.
- Produces delegate/callback events:
  - authenticated/unavailable;
  - invitation accepted/declined;
  - match connected;
  - peer connected/disconnected;
  - packet received;
  - transport error.

- [ ] **Step 1: Write transport contract tests with a fake transport seam**

Test state mapping without requiring live Game Center:
- unavailable Game Center;
- peer connect;
- peer disconnect;
- duplicate packet handling delegated correctly;
- send failure surfaced to coordinator.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement GameKit wrapper**

Keep GameKit calls in this one subsystem. Do not let UI or race scene call GameKit directly.

- [ ] **Step 4: Verify GREEN with fake transport tests**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeTransport.h \
        spritybird/Challenge/FGChallengeTransport.m \
        tests/challenge/FGChallengeTransportTests.m
git commit -m "Add Game Center Challenge transport"
```

---

### Task 9: Implement Challenge lifecycle coordinator

**Files:**
- Create: `spritybird/Challenge/FGChallengeCoordinator.h`
- Create: `spritybird/Challenge/FGChallengeCoordinator.m`
- Test: `tests/challenge/FGChallengeCoordinatorTests.m`

**Interfaces:**
- Consumes: transport, race contract, rules, verifier, record store.
- Produces explicit lifecycle states:
  - idle;
  - inviting;
  - lobby;
  - ready;
  - contractLocked;
  - countdown;
  - racing;
  - finishWindow;
  - verifying;
  - results;
  - voided.

- [ ] **Step 1: Write failing state-machine tests**

Cover:
- cannot start before both ready;
- contract mismatch blocks countdown;
- first crash starts finish window;
- surviving player may continue until timeout;
- reconnect inside 5 seconds preserves match;
- reconnect timeout forfeits;
- both disconnect voids;
- result disagreement becomes unverified;
- rematch returns to fresh contract/lobby.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement minimal explicit state machine**

Reject invalid transitions rather than silently correcting them.

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeCoordinator.h \
        spritybird/Challenge/FGChallengeCoordinator.m \
        tests/challenge/FGChallengeCoordinatorTests.m
git commit -m "Add Live Challenge match coordinator"
```

---

### Task 10: Add visual-only opponent ghost renderer

**Files:**
- Create: `spritybird/Challenge/FGChallengeGhostRenderer.h`
- Create: `spritybird/Challenge/FGChallengeGhostRenderer.m`

**Interfaces:**
- Consumes: accepted remote packets.
- Produces: SpriteKit node transform/animation only.
- Must not expose collision or scoring mutation APIs.

- [ ] **Step 1: Write source-contract test**

Add assertions to `tests/challenge/FGChallengeSourceContractTests.py` that ghost renderer:
- does not import or mutate `Score`;
- does not write to local bird physics body;
- does not create collision callbacks;
- only exposes render/update methods.

- [ ] **Step 2: Verify RED**

Run:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/challenge/FGChallengeSourceContractTests.py
```

Expected: FAIL because renderer is absent.

- [ ] **Step 3: Implement ghost renderer**

Use semi-transparent opponent bird sprite and interpolation between accepted snapshots.

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeGhostRenderer.h \
        spritybird/Challenge/FGChallengeGhostRenderer.m \
        tests/challenge/FGChallengeSourceContractTests.py
git commit -m "Add visual-only Challenge ghost rendering"
```

---

### Task 11: Build Challenge-specific race scene

**Files:**
- Create: `spritybird/Challenge/FGChallengeRaceScene.h`
- Create: `spritybird/Challenge/FGChallengeRaceScene.m`
- Modify: `tests/challenge/FGChallengeSourceContractTests.py`

**Interfaces:**
- Consumes: race contract, deterministic course generator, coordinator, ghost renderer.
- Produces: local Challenge race presentation and state events.
- Must not modify Classic scene files.

- [ ] **Step 1: Extend source-contract tests**

Assert:
- `FGChallengeRaceScene` consumes `FGChallengeCourseGenerator`;
- it does not import Classic `Scene.m`;
- protected source files remain byte-identical;
- remote packet processing routes only to ghost renderer/coordinator.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement minimal Challenge race scene**

Build a dedicated race scene using the approved protected physics values via explicit Challenge configuration constants copied from the compatibility contract, not by rewriting Classic source.

If identical Classic runtime behavior cannot be achieved without touching protected gameplay files, STOP and open the separately approved protected-hook gate rather than continuing.

- [ ] **Step 4: Verify static contract and protected hashes**

Run source contract plus four `shasum` checks.

Expected: all PASS/MATCH.

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeRaceScene.h \
        spritybird/Challenge/FGChallengeRaceScene.m \
        tests/challenge/FGChallengeSourceContractTests.py
git commit -m "Add deterministic Live Challenge race scene"
```

---

### Task 12: Add Challenge lobby, Rules card, and invitation UX

**Files:**
- Create: `spritybird/Challenge/FGChallengeLobbyViewController.h`
- Create: `spritybird/Challenge/FGChallengeLobbyViewController.m`

**Interfaces:**
- Consumes: coordinator + Game Center identity/transport state.
- Produces: Invite Friend, incoming/pending invite, Ready/Not Ready, Rules, connection/version failure UI.

- [ ] **Step 1: Add source-contract assertions for required copy/states**

Require strings/surfaces for:
- Invite Friend;
- Ready;
- Not Ready;
- Rules;
- Update required to race this friend;
- Game Center unavailable;
- connection loss before start.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement lobby UI**

Programmatic UIKit, matching the current premium modernization style. No storyboard dependency.

- [ ] **Step 4: Verify source contract**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeLobbyViewController.h \
        spritybird/Challenge/FGChallengeLobbyViewController.m \
        tests/challenge/FGChallengeSourceContractTests.py
git commit -m "Add Live Challenge lobby and rules UI"
```

---

### Task 13: Add results, records, and instant rematch UI

**Files:**
- Create: `spritybird/Challenge/FGChallengeResultsViewController.h`
- Create: `spritybird/Challenge/FGChallengeResultsViewController.m`

**Interfaces:**
- Consumes: verified result + record store + coordinator.
- Produces:
  - You Win
  - You Lost
  - Draw
  - Unverified
  - Multiplayer Record
  - Rematch
  - Back to Home

- [ ] **Step 1: Add failing source-contract assertions**

Require:
- four result states;
- unverified copy exactly: `Race could not be verified — no result recorded.`;
- Rematch and Back to Home controls;
- no record increment on void/unverified presentation path.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement results UI**

Use local record store output; do not invent remote leaderboard/ranking.

- [ ] **Step 4: Verify GREEN**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Challenge/FGChallengeResultsViewController.h \
        spritybird/Challenge/FGChallengeResultsViewController.m \
        tests/challenge/FGChallengeSourceContractTests.py
git commit -m "Add Live Challenge results and rematch UI"
```

---

### Task 14: Add Challenge Friend to the main menu

**Files:**
- Modify: `spritybird/Classes/Controllers/ViewController.h`
- Modify: `spritybird/Classes/Controllers/ViewController.m`
- Modify: `tests/challenge/FGChallengeSourceContractTests.py`

**Interfaces:**
- Consumes: `FGChallengeLobbyViewController`.
- Produces: first-class Challenge Friend entry point alongside Classic and Academy.

- [ ] **Step 1: Write failing source-contract assertion**

Require a visible `Challenge Friend` action from the root menu and a route into `FGChallengeLobbyViewController`.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Implement minimal navigation integration**

Do not alter Classic launch behavior or Academy navigation beyond adding the sibling Challenge destination.

- [ ] **Step 4: Verify source contract and Classic hashes**

- [ ] **Step 5: Commit**

```bash
git add spritybird/Classes/Controllers/ViewController.h \
        spritybird/Classes/Controllers/ViewController.m \
        tests/challenge/FGChallengeSourceContractTests.py
git commit -m "Add Challenge Friend main menu entry"
```

---

### Task 15: Add all Challenge sources to the Xcode project

**Files:**
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: all Challenge source/header files.
- Produces: correct target membership.

- [ ] **Step 1: Add failing PBX membership audit**

Extend `FGChallengeSourceContractTests.py` to assert every new `.m` file has a PBX file reference, build file, and Sources build phase membership.

- [ ] **Step 2: Verify RED**

- [ ] **Step 3: Update project.pbxproj**

Add all Challenge files without unrelated project churn.

- [ ] **Step 4: Verify PBX syntax and membership**

Run:

```bash
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
PYTHONDONTWRITEBYTECODE=1 python3 tests/challenge/FGChallengeSourceContractTests.py
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add "Flappy Gratata.xcodeproj/project.pbxproj" \
        tests/challenge/FGChallengeSourceContractTests.py
git commit -m "Register Live Challenge sources"
```

---

### Task 16: Run the full static and Foundation integration gate

**Files:**
- Modify only if tests expose an approved in-scope defect.

**Interfaces:**
- Produces: static implementation evidence.

- [ ] **Step 1: Run Challenge source contract**

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/challenge/FGChallengeSourceContractTests.py
```

Expected: PASS.

- [ ] **Step 2: Run Academy source contract**

```bash
PYTHONDONTWRITEBYTECODE=1 python3 tests/academy/test_academy_source_contract.py
```

Expected: PASS.

- [ ] **Step 3: Lint PBX**

```bash
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
```

Expected: OK.

- [ ] **Step 4: Run Foundation warning-as-error harnesses**

Compile all Foundation-only Challenge models with:

```text
-Wall -Wextra -Werror
```

Expected: 0 diagnostics.

- [ ] **Step 5: Verify protected hashes**

Run the four `shasum` checks. Expected: 4/4 exact match.

- [ ] **Step 6: Run diff integrity checks**

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; worktree state understood.

- [ ] **Step 7: Commit any test-only harness additions**

Commit only if new harness files were required.

---

### Task 17: Full-Xcode Game Center and two-device validation gate

**Files:**
- No source edits unless a test exposes an in-scope defect.

**Interfaces:**
- Produces: runtime release evidence.

- [ ] **Step 1: Verify full Xcode**

Run:

```bash
xcode-select -p
xcodebuild -version
```

Expected: full Xcode, not CommandLineTools-only.

If unavailable, record this task as NOT_PERFORMED and do not claim runtime closure.

- [ ] **Step 2: Build**

Run the project/scheme build for an iOS Simulator or physical device.

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run all Challenge XCTest tests**

Expected: 0 failures.

- [ ] **Step 4: Validate Game Center entitlement/signing**

Confirm Game Center capability and signing on both physical devices.

- [ ] **Step 5: Execute two-device matrix**

Validate:
- invite/accept;
- decline;
- same-network race;
- different-network race;
- countdown synchronization;
- ghost updates;
- first-crash 3-second window;
- reconnect inside 5 seconds;
- disconnect beyond grace;
- both disconnect;
- app background/foreground;
- exact/near-simultaneous draw;
- result mismatch → unverified;
- rematch → fresh race ID;
- Game Center unavailable;
- version mismatch.

- [ ] **Step 6: Run Classic regression smoke**

Verify normal Classic start, flap, pipes, scoring, collision, restart, and game-over presentation remain unchanged.

- [ ] **Step 7: Recheck protected hashes**

Expected: 4/4 exact match.

---

### Task 18: Final whole-branch review and closure decision

**Files:**
- No edits except findings approved for correction.

**Interfaces:**
- Produces: final review disposition.

- [ ] **Step 1: Run fresh whole-branch review**

Use a fresh reviewer against the implementation base and inspect:
- spec coverage;
- GameKit API correctness;
- deterministic fairness;
- invalid-state fail-closed behavior;
- record integrity;
- Game Center unavailable isolation;
- Classic isolation;
- privacy/non-goals;
- UI rules/result copy.

- [ ] **Step 2: Fix only review findings inside approved scope**

Each fix requires focused regression evidence.

- [ ] **Step 3: Re-run verification**

Repeat Task 16, and Task 17 if full Xcode is available.

- [ ] **Step 4: Produce exact closure status**

Allowed dispositions:

```text
LIVE_CHALLENGE_STATIC_CLOSURE_PASS_RUNTIME_PENDING
```

when only static/Foundation evidence is available, or:

```text
LIVE_CHALLENGE_RUNTIME_CLOSURE_PASS
```

only after full Xcode + two-device Game Center validation passes.

- [ ] **Step 5: Do not merge or push without separate authorization**

End with clean status and exact HEAD.

---

## Plan Self-Review

### Spec coverage
Covered:
- Game Center friend invitations;
- live 1-vs-1;
- deterministic shared course;
- local-authority model;
- ghost rendering;
- 3-second finish window;
- 5-second reconnect;
- forfeit/void/draw rules;
- fail-closed result verification;
- rematch;
- rules UI;
- separate aggregate and per-friend records;
- device-local persistence;
- no custom backend;
- Game Center unavailable behavior;
- protected Classic isolation;
- Academy/Flight DNA isolation;
- GameKit API freshness;
- static, XCTest, integration, and two-device validation.

### Placeholder scan
No TBD/TODO/“implement later” placeholders are present.

### Type consistency
All planned Challenge component names and dependencies are used consistently across tasks.

### Scope
The plan stays within V1 Challenge Friend and does not add public matchmaking, backend services, chat, tournaments, monetization, Flight DNA, or Classic refactoring.
