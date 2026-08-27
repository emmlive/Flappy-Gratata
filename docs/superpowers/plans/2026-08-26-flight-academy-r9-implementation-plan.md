# Flappy Gratata 3.0 — R9 Flight Academy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete on-device R9 Flight Academy that observes approved Classic flight signals, evaluates Rhythm / Precision / Recovery / Control / Nerve, coaches the player, recommends deterministic drills, runs certification progression, presents the premium Commander Gratata Academy UI, and records Academy progress without changing Classic gameplay mechanics.

**Architecture:** R9 is split into ten independently reviewable milestones, R9A through R9J. Domain logic is isolated in focused Objective-C classes under `spritybird/Academy/`; UI consumes Academy-domain outputs rather than reaching into `Scene` or `BirdNode`; persistence is local and versioned. Any future instrumentation that touches a protected Classic gameplay file is its own explicitly authorized, behavior-equivalence-gated step and may not be folded into unrelated Academy work.

**Tech Stack:** Objective-C, SpriteKit, UIKit, Foundation, NSUserDefaults/local plist-compatible Foundation objects, XCTest when a full Xcode/iOS SDK environment is available, shell/Python static contract checks on the current Monterey CommandLineTools-only Mac.

**Spec:** `docs/superpowers/specs/2026-08-26-flight-academy-r9-design.md`

## Global Constraints

- Classic gameplay remains authoritative and mechanically unchanged.
- R9 observes and interprets play; it must not secretly assist, handicap, or change physics.
- R9 is fully on-device: no backend, account, cloud sync, analytics service, or network dependency.
- Player-facing skill ratings use `Developing`, `Qualified`, `Advanced`, `Elite`, `Mastery`; exact scores remain internal.
- Certification ranks are `Cadet`, `Aviator`, `Wing Leader`, `Ace`, `Flight Master`.
- R9 may present a temporary Flight Signature but must not persist R10 Flight DNA traits.
- Commander Gratata is an Academy-only instructor identity, not the player's selected bird.
- Hangar remains the bird-selection destination.
- Any evaluator recommendation shown through “Why this?” must be explainable from available evidence.
- Insufficient evidence shows a calibration state rather than a fabricated rating.
- Durable certification progress must survive evaluator recalibration where safe.
- Any Academy subsystem failure must degrade to safe neutral Academy behavior while Classic play continues.
- R9 must not implement behavior-driven bird evolution, Echo Gratata evolution, Moonlight/Eclipse transformations, aura/trail/eye evolution, or gameplay power.
- Protected gameplay hash baseline:
  - `spritybird/Scene.m` = `50c6f4542d0a849f1122dcee726280bd867b049fd651dbd8b5e0df4ade2bc4f9`
  - `spritybird/BirdNode.m` = `a0c050e3d2fba192fa0584a6d035306f235f690e7924be192b9d7d1db73d63b4`
  - `spritybird/SKScrollingNode.m` = `5594f59de2c920747012fc977d2bf62aea9d4ffb0bb64e475785a2511d5c435f`
  - `spritybird/Score.m` = `3276c37c32479aa793b940a8b218787f6753cd9a9e74c03dbc7746bf0aad2ac4`
- Protected Classic baseline includes floor speed `3`, gap `120`, first obstacle padding `100`, minimum obstacle height `60`, obstacle interval `130`, bird physics body `26 x 18`, mass `0.1`, impulse `40`, flap animation `0.2` seconds/frame, and existing scoring/collision/restart behavior.
- The current Mac cannot perform a real iOS build. Every milestone must distinguish static validation from full-Xcode build/XCTest validation.
- Do not amend or rewrite existing commits.
- Each milestone ends in a focused commit and a clean-worktree verification.
- Do not push or deploy unless separately authorized.

---

## File Structure

The R9 implementation uses these focused units:

### Domain / measurement

- `spritybird/Academy/FGFlightSignal.h`
  - Immutable event vocabulary and signal record model.
- `spritybird/Academy/FGFlightSignalRecorder.h`
- `spritybird/Academy/FGFlightSignalRecorder.m`
  - Collects approved observable flight events only.
- `spritybird/Academy/FGRunSummary.h`
- `spritybird/Academy/FGRunSummary.m`
  - Compact per-run derived metrics.
- `spritybird/Academy/FGFlightSkillEvaluator.h`
- `spritybird/Academy/FGFlightSkillEvaluator.m`
  - Deterministic five-skill evaluation, confidence, calibration, and visible bands.

### Persistence / profile

- `spritybird/Academy/FGAcademyProfile.h`
- `spritybird/Academy/FGAcademyProfile.m`
  - Versioned in-memory Academy state.
- `spritybird/Academy/FGAcademyProfileStore.h`
- `spritybird/Academy/FGAcademyProfileStore.m`
  - NSUserDefaults serialization, validation, migration, safe fallback.

### Coaching / drills / certification

- `spritybird/Academy/FGAcademyCoach.h`
- `spritybird/Academy/FGAcademyCoach.m`
  - Evidence-backed positive observation, improvement cue, Flight Signature, “Why this?” text.
- `spritybird/Academy/FGAcademyDrill.h`
- `spritybird/Academy/FGAcademyDrill.m`
  - Drill model.
- `spritybird/Academy/FGAcademyDrillCatalog.h`
- `spritybird/Academy/FGAcademyDrillCatalog.m`
  - Handcrafted Technique / Pressure / Signature catalog.
- `spritybird/Academy/FGAcademyDrillSelector.h`
- `spritybird/Academy/FGAcademyDrillSelector.m`
  - Deterministic recommendation rules and repetition avoidance.
- `spritybird/Academy/FGAcademyCertificationEngine.h`
- `spritybird/Academy/FGAcademyCertificationEngine.m`
  - Readiness, three-segment certification, two-of-three baseline, promotion.

### Trace / session state

- `spritybird/Academy/FGFlightTrace.h`
- `spritybird/Academy/FGFlightTrace.m`
  - Short instructional trace only.
- `spritybird/Academy/FGAcademySession.h`
- `spritybird/Academy/FGAcademySession.m`
  - Briefing → flight → debrief / certification-session state without physics ownership.

### UI

- `spritybird/Academy/UI/FGAcademyViewController.h`
- `spritybird/Academy/UI/FGAcademyViewController.m`
  - Academy navigation shell.
- `spritybird/Academy/UI/FGAcademyHomeViewController.h`
- `spritybird/Academy/UI/FGAcademyHomeViewController.m`
  - Commander Gratata, rank, bands, focus, recommendation, recent trace/results.
- `spritybird/Academy/UI/FGAcademyTrainingViewController.h`
- `spritybird/Academy/UI/FGAcademyTrainingViewController.m`
  - Technique / Pressure / Signature catalog and briefing entry.
- `spritybird/Academy/UI/FGAcademyDebriefViewController.h`
- `spritybird/Academy/UI/FGAcademyDebriefViewController.m`
  - Positive observation, one cue, trend, trace, Echo retry.
- `spritybird/Academy/UI/FGAcademyCertificationViewController.h`
- `spritybird/Academy/UI/FGAcademyCertificationViewController.m`
  - Certification readiness / exam progress / result.
- `spritybird/Academy/UI/FGAcademyFlightRecordViewController.h`
- `spritybird/Academy/UI/FGAcademyFlightRecordViewController.m`
  - Skill history, recent coaching, traces, certification history, Flight Signature.
- `spritybird/Academy/UI/FGAcademyProgressViewController.h`
- `spritybird/Academy/UI/FGAcademyProgressViewController.m`
  - Certification progression, insignia, non-power accomplishments.
- `spritybird/Academy/UI/FGAcademyTheme.h`
- `spritybird/Academy/UI/FGAcademyTheme.m`
  - Shared premium navy/graphite/cyan/ice-blue/gold/orange styling constants.
- `spritybird/Academy/UI/FGCommanderGratataView.h`
- `spritybird/Academy/UI/FGCommanderGratataView.m`
  - Academy-only instructor presentation wrapper.

### Tests / contract audits

- `tests/academy/test_academy_source_contract.py`
  - Static source/PBX/R9-R10 boundary and gameplay-hash guard.
- `tests/academy/FGRunSummaryTests.m`
- `tests/academy/FGFlightSkillEvaluatorTests.m`
- `tests/academy/FGAcademyProfileStoreTests.m`
- `tests/academy/FGAcademyCoachTests.m`
- `tests/academy/FGAcademyDrillSelectorTests.m`
- `tests/academy/FGAcademyCertificationEngineTests.m`
  - XCTest suites to run on a full-Xcode machine.
- `tests/academy/fixtures/`
  - Small deterministic signal/profile fixtures only; no copied production telemetry.

---

# R9A — Flight Signal Contract and Instrumentation Boundary

### Task 1: Establish the Academy source contract and gameplay guard

**Files:**
- Create: `spritybird/Academy/FGFlightSignal.h`
- Create: `spritybird/Academy/FGFlightSignalRecorder.h`
- Create: `spritybird/Academy/FGFlightSignalRecorder.m`
- Create: `tests/academy/test_academy_source_contract.py`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`
- Do not modify: `spritybird/Scene.m`, `spritybird/BirdNode.m`, `spritybird/SKScrollingNode.m`, `spritybird/Score.m`

**Interfaces:**

```objc
typedef NS_ENUM(NSInteger, FGFlightSignalType) {
    FGFlightSignalTypeFlap = 1,
    FGFlightSignalTypeObstacleCrossing,
    FGFlightSignalTypeCorrection,
    FGFlightSignalTypeRiskEntry,
    FGFlightSignalTypeRunEnded
};

@interface FGFlightSignal : NSObject
@property (nonatomic, assign, readonly) FGFlightSignalType type;
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;
@property (nonatomic, assign, readonly) CGFloat birdY;
@property (nonatomic, assign, readonly) CGFloat gapCenterY;
@property (nonatomic, assign, readonly) CGFloat correctionMagnitude;
@property (nonatomic, assign, readonly) NSInteger obstacleIndex;
@end
```

```objc
@interface FGFlightSignalRecorder : NSObject
- (void)reset;
- (void)recordSignal:(FGFlightSignal *)signal;
- (NSArray *)snapshotSignals;
@end
```

- Produces an observation-only event vocabulary for R9B.
- Does not own or modify gameplay state.

- [ ] **Step 1: Write the static contract test first**

Create `tests/academy/test_academy_source_contract.py` with checks that:
1. all four protected hashes match;
2. `spritybird/Academy` source cannot contain `physicsBody.mass =`, `applyImpulse:`, obstacle-speed assignment, score increment, or collision mutation patterns;
3. `FGFlightSignalRecorder` exposes only reset/record/snapshot;
4. no R10 reserved strings (`Daredevil`, `Survivor`, `Comeback`, `Explorer`, `Legend`, `Moonlight`, `Eclipse`, `Echo Gratata`) occur in persistent Academy models.

Run:

```bash
python3 tests/academy/test_academy_source_contract.py
```

Expected: FAIL because the Academy source files do not exist yet.

- [ ] **Step 2: Add the minimal event model and recorder**

Implement `FGFlightSignal` as an immutable Foundation object and recorder as a mutable internal array that returns copied snapshots. Do not add timers, SpriteKit references, difficulty logic, score logic, or persistence.

- [ ] **Step 3: Add only the three new source files to PBX**

Add `FGFlightSignal.h`, `FGFlightSignalRecorder.h`, and `FGFlightSignalRecorder.m` to the source group; add only `.m` to Compile Sources.

Run:

```bash
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
python3 tests/academy/test_academy_source_contract.py
git diff --check
```

Expected: PBX syntax PASS; static contract PASS; gameplay hashes unchanged.

- [ ] **Step 4: Review the instrumentation boundary**

Run:

```bash
git diff -- spritybird/Scene.m spritybird/BirdNode.m spritybird/SKScrollingNode.m spritybird/Score.m
```

Expected: no output.

Document in the milestone result that no Classic hook has been installed yet. A later hook requires a separately reviewed task because current protected files remain immutable.

- [ ] **Step 5: Commit R9A**

```bash
git add spritybird/Academy/FGFlightSignal.h \
        spritybird/Academy/FGFlightSignalRecorder.h \
        spritybird/Academy/FGFlightSignalRecorder.m \
        tests/academy/test_academy_source_contract.py \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Flight Academy signal contract"
```

---

# R9B — Run Summary and Five-Skill Evaluator

### Task 2: Add deterministic run summarization

**Files:**
- Create: `spritybird/Academy/FGRunSummary.h`
- Create: `spritybird/Academy/FGRunSummary.m`
- Create: `tests/academy/FGRunSummaryTests.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
@interface FGRunSummary : NSObject
@property (nonatomic, assign, readonly) double rhythmConsistency;
@property (nonatomic, assign, readonly) double averageGapOffset;
@property (nonatomic, assign, readonly) NSInteger recoverySuccessCount;
@property (nonatomic, assign, readonly) double correctionVolatility;
@property (nonatomic, assign, readonly) double pressureStability;
@property (nonatomic, assign, readonly) NSInteger evidenceCount;
+ (instancetype)summaryFromSignals:(NSArray *)signals;
@end
```

- [ ] **Step 1: Write XCTest cases for known synthetic sequences**

Cover:
- evenly spaced flap timestamps → higher rhythmConsistency than bursty timestamps;
- centered crossings → lower averageGapOffset than edge crossings;
- risky entry followed by stable crossing → recoverySuccessCount increments;
- repeated large alternating corrections → higher correctionVolatility;
- stable later-run segments → higher pressureStability.

Expected on current Mac: source test committed but `xcodebuild` validation marked `NOT_PERFORMED_ON_THIS_MAC`.

- [ ] **Step 2: Implement only deterministic summary math**

Normalize each metric to `0.0 ... 1.0` except averageGapOffset, which remains a non-negative distance metric. Empty or insufficient input yields safe neutral values and `evidenceCount = 0`.

- [ ] **Step 3: Add PBX membership and static contract coverage**

Extend the static test to assert `FGRunSummary` does not import SpriteKit and does not call gameplay mutation APIs.

- [ ] **Step 4: Static verify**

```bash
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
python3 tests/academy/test_academy_source_contract.py
git diff --check
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add spritybird/Academy/FGRunSummary.h \
        spritybird/Academy/FGRunSummary.m \
        tests/academy/FGRunSummaryTests.m \
        tests/academy/test_academy_source_contract.py \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Academy run summary model"
```

### Task 3: Implement the five-skill evaluator and prestige bands

**Files:**
- Create: `spritybird/Academy/FGFlightSkillEvaluator.h`
- Create: `spritybird/Academy/FGFlightSkillEvaluator.m`
- Create: `tests/academy/FGFlightSkillEvaluatorTests.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
typedef NS_ENUM(NSInteger, FGAcademySkill) {
    FGAcademySkillRhythm = 0,
    FGAcademySkillPrecision,
    FGAcademySkillRecovery,
    FGAcademySkillControl,
    FGAcademySkillNerve
};

typedef NS_ENUM(NSInteger, FGAcademySkillBand) {
    FGAcademySkillBandCalibrating = 0,
    FGAcademySkillBandDeveloping,
    FGAcademySkillBandQualified,
    FGAcademySkillBandAdvanced,
    FGAcademySkillBandElite,
    FGAcademySkillBandMastery
};

@interface FGAcademySkillResult : NSObject
@property (nonatomic, assign, readonly) FGAcademySkill skill;
@property (nonatomic, assign, readonly) double internalScore;
@property (nonatomic, assign, readonly) double confidence;
@property (nonatomic, assign, readonly) FGAcademySkillBand visibleBand;
@end

@interface FGFlightSkillEvaluator : NSObject
- (NSDictionary *)evaluateSummary:(FGRunSummary *)summary
                    priorResults:(NSDictionary *)priorResults;
@end
```

- [ ] **Step 1: Write failing evaluator tests**

Test:
- five results always returned for valid summary;
- low evidence => `Calibrating`;
- one great summary cannot jump an established result directly to Elite/Mastery;
- one poor summary cannot immediately collapse an established high-confidence band;
- all internal scores clamp to `0...100`;
- confidence clamps to `0...1`.

- [ ] **Step 2: Implement conservative rolling evaluation**

Use bounded weighted updates, not raw replacement. Keep thresholds centralized in `FGFlightSkillEvaluator.m`; expose no exact score to UI-facing helpers.

- [ ] **Step 3: Add human-readable band helper**

Expose:

```objc
FOUNDATION_EXPORT NSString *FGAcademySkillBandDisplayName(FGAcademySkillBand band);
```

Exact player-facing names:
`Calibrating`, `Developing`, `Qualified`, `Advanced`, `Elite`, `Mastery`.

- [ ] **Step 4: Static verify and full-Xcode gate**

Current Mac:

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
```

Full Xcode later:

```bash
xcodebuild test -project "Flappy Gratata.xcodeproj" -scheme "Flappy Gratata" -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected on full Xcode: evaluator XCTest PASS.

- [ ] **Step 5: Commit**

```bash
git add spritybird/Academy/FGFlightSkillEvaluator.h \
        spritybird/Academy/FGFlightSkillEvaluator.m \
        tests/academy/FGFlightSkillEvaluatorTests.m \
        tests/academy/test_academy_source_contract.py \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add five-skill Academy evaluator"
```

---

# R9C — Versioned Academy Profile Persistence

### Task 4: Add versioned profile model and store

**Files:**
- Create: `spritybird/Academy/FGAcademyProfile.h`
- Create: `spritybird/Academy/FGAcademyProfile.m`
- Create: `spritybird/Academy/FGAcademyProfileStore.h`
- Create: `spritybird/Academy/FGAcademyProfileStore.m`
- Create: `tests/academy/FGAcademyProfileStoreTests.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
typedef NS_ENUM(NSInteger, FGAcademyRank) {
    FGAcademyRankCadet = 0,
    FGAcademyRankAviator,
    FGAcademyRankWingLeader,
    FGAcademyRankAce,
    FGAcademyRankFlightMaster
};

@interface FGAcademyProfile : NSObject
@property (nonatomic, assign) NSInteger schemaVersion;
@property (nonatomic, assign) FGAcademyRank rank;
@property (nonatomic, copy) NSDictionary *skillResults;
@property (nonatomic, copy) NSArray *completedDrillIDs;
@property (nonatomic, copy) NSDictionary *certificationProgress;
@property (nonatomic, copy) NSArray *recentCoachingHistory;
@end

@interface FGAcademyProfileStore : NSObject
- (FGAcademyProfile *)loadProfile;
- (BOOL)saveProfile:(FGAcademyProfile *)profile;
- (void)resetEvaluatorConfidencePreservingCertification;
@end
```

Persistence key:

```objc
FOUNDATION_EXPORT NSString * const FGAcademyProfileDefaultsKey;
```

Initial schema version: `1`.

- [ ] **Step 1: Write persistence tests**

Cover:
- missing key → safe default Cadet profile;
- valid schema 1 round-trip;
- malformed type → safe default;
- out-of-range skill values → rejected/clamped through model validation;
- unknown future schema → preserve no unsafe evaluator evidence and keep durable rank only when rank value itself is valid;
- recalibration clears/reduces confidence but preserves certification rank.

- [ ] **Step 2: Implement property-list-safe serialization**

Persist only NSString / NSNumber / NSArray / NSDictionary values under one Academy key. No archived arbitrary objects and no network storage.

- [ ] **Step 3: Add R9/R10 persistence guard**

Static test must fail if Academy profile/store contains reserved persistent DNA fields such as `dnaTrait`, `birdEvolution`, `aura`, `trail`, `moonlight`, `eclipse`.

- [ ] **Step 4: Verify**

```bash
python3 tests/academy/test_academy_source_contract.py
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
git diff --check
```

- [ ] **Step 5: Commit**

```bash
git add spritybird/Academy/FGAcademyProfile.h \
        spritybird/Academy/FGAcademyProfile.m \
        spritybird/Academy/FGAcademyProfileStore.h \
        spritybird/Academy/FGAcademyProfileStore.m \
        tests/academy/FGAcademyProfileStoreTests.m \
        tests/academy/test_academy_source_contract.py \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add versioned Academy profile storage"
```

---

# R9D — Academy Coach and Drill Selector

### Task 5: Add evidence-backed coaching

**Files:**
- Create: `spritybird/Academy/FGAcademyCoach.h`
- Create: `spritybird/Academy/FGAcademyCoach.m`
- Create: `tests/academy/FGAcademyCoachTests.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
@interface FGAcademyCoachingResult : NSObject
@property (nonatomic, copy, readonly) NSString *positiveObservation;
@property (nonatomic, copy, readonly) NSString *improvementCue;
@property (nonatomic, copy, readonly) NSString *whyText;
@property (nonatomic, copy, readonly) NSString *flightSignature;
@property (nonatomic, assign, readonly) FGAcademySkill focusSkill;
@property (nonatomic, assign, readonly) BOOL evidenceSufficient;
@end

@interface FGAcademyCoach : NSObject
- (FGAcademyCoachingResult *)coachingForProfile:(FGAcademyProfile *)profile
                                     runSummary:(FGRunSummary *)summary;
@end
```

- [ ] **Step 1: Write tests that prohibit fabricated claims**

If evidence is insufficient:
- `evidenceSufficient == NO`;
- neutral copy is `Complete another flight for analysis`;
- no specific “last three runs” claim may be generated.

When evidence exists:
- exactly one positive observation;
- exactly one improvement cue;
- `whyText` maps to actual metric evidence;
- Flight Signature is temporary coaching copy only.

- [ ] **Step 2: Implement deterministic templates**

Use a finite set of templates keyed to evaluator evidence. No generative AI, network calls, random behavior, or unsupported emotional inference.

- [ ] **Step 3: Verify and commit**

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
git add spritybird/Academy/FGAcademyCoach.h \
        spritybird/Academy/FGAcademyCoach.m \
        tests/academy/FGAcademyCoachTests.m \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add explainable Academy coaching"
```

### Task 6: Add handcrafted drill catalog and selector

**Files:**
- Create: `spritybird/Academy/FGAcademyDrill.h`
- Create: `spritybird/Academy/FGAcademyDrill.m`
- Create: `spritybird/Academy/FGAcademyDrillCatalog.h`
- Create: `spritybird/Academy/FGAcademyDrillCatalog.m`
- Create: `spritybird/Academy/FGAcademyDrillSelector.h`
- Create: `spritybird/Academy/FGAcademyDrillSelector.m`
- Create: `tests/academy/FGAcademyDrillSelectorTests.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
typedef NS_ENUM(NSInteger, FGAcademyDrillFamily) {
    FGAcademyDrillFamilyTechnique = 0,
    FGAcademyDrillFamilyPressure,
    FGAcademyDrillFamilySignature
};

@interface FGAcademyDrill : NSObject
@property (nonatomic, copy, readonly) NSString *drillID;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, assign, readonly) FGAcademyDrillFamily family;
@property (nonatomic, copy, readonly) NSArray *focusSkills;
@property (nonatomic, copy, readonly) NSString *briefingText;
@end

@interface FGAcademyDrillSelector : NSObject
- (FGAcademyDrill *)recommendedDrillForProfile:(FGAcademyProfile *)profile
                                      coaching:(FGAcademyCoachingResult *)coaching;
- (NSArray *)alternativeDrillsForProfile:(FGAcademyProfile *)profile
                                excluding:(NSString *)drillID;
@end
```

Catalog must include the approved names:
- Technique: `Steady Rhythm`, `Center Entry`, `Smooth Climb`, `Clean Descent`, `Calm Wings`
- Pressure: `Tight Corridors`, `Fast Patterns`, `Long Runs`, `Edge Pressure`
- Signature: `Late Recovery`, `Panic Taps`, `Unstable Rhythm`, `Over-Correction`

- [ ] **Step 1: Write selector tests**

Verify priority:
1. weak skill;
2. recently improving skill;
3. occasional established-strength check;
4. repetition avoidance.

When no valid recommendation exists, fallback is the standard Technique drill `Steady Rhythm`.

- [ ] **Step 2: Implement catalog as static deterministic data**

No procedural level generation. Drill selection changes objective/evaluation only; it must not expose physics settings.

- [ ] **Step 3: Verify and commit**

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
git add spritybird/Academy/FGAcademyDrill*.h \
        spritybird/Academy/FGAcademyDrill*.m \
        tests/academy/FGAcademyDrillSelectorTests.m \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add personalized Academy drill selection"
```

---

# R9E — Academy Home and Commander Gratata UI

### Task 7: Add shared Academy theme and navigation shell

**Files:**
- Create: `spritybird/Academy/UI/FGAcademyTheme.h`
- Create: `spritybird/Academy/UI/FGAcademyTheme.m`
- Create: `spritybird/Academy/UI/FGAcademyViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyViewController.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
@interface FGAcademyTheme : NSObject
+ (UIColor *)backgroundColor;
+ (UIColor *)panelColor;
+ (UIColor *)instrumentColor;
+ (UIColor *)accentColor;
+ (UIColor *)secondaryAccentColor;
@end
```

```objc
@interface FGAcademyViewController : UIViewController
- (instancetype)initWithProfileStore:(FGAcademyProfileStore *)profileStore;
@end
```

- [ ] **Step 1: Create the programmatic narrow-safe navigation shell**

No storyboard. Use existing project programmatic UI conventions. Primary destinations:
`Home`, `Training`, `Certification`, `Flight Record`, `Progress`, and an exit/back path. Hangar remains external.

- [ ] **Step 2: Apply premium visual language**

Dark navy/graphite surfaces, cyan/ice-blue instrumentation, restrained gold/white/orange accents. Avoid star-rating arcade motifs and classroom styling.

- [ ] **Step 3: Static UI/PBX verify**

```bash
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
python3 tests/academy/test_academy_source_contract.py
git diff --check
```

- [ ] **Step 4: Commit**

```bash
git add spritybird/Academy/UI/FGAcademyTheme.* \
        spritybird/Academy/UI/FGAcademyViewController.* \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Flight Academy navigation shell"
```

### Task 8: Add Academy Home and Commander Gratata presentation

**Files:**
- Create: `spritybird/Academy/UI/FGCommanderGratataView.h`
- Create: `spritybird/Academy/UI/FGCommanderGratataView.m`
- Create: `spritybird/Academy/UI/FGAcademyHomeViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyHomeViewController.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`
- Add approved Commander Gratata image resource only after its final runtime asset is separately approved.

**Interfaces:**

```objc
@interface FGAcademyHomeViewController : UIViewController
- (instancetype)initWithProfileStore:(FGAcademyProfileStore *)profileStore
                               coach:(FGAcademyCoach *)coach
                       drillSelector:(FGAcademyDrillSelector *)drillSelector;
@end
```

Home must show:
- Commander Gratata;
- current certification;
- all five visible skill bands;
- current focus;
- one coaching note;
- recommended drill;
- recent result/trace slot;
- rank progression summary;
- `Why this?` affordance.

- [ ] **Step 1: Build the screen with safe placeholder presentation if the final instructor asset is not yet bundled**

The placeholder must be a simple local UIView/SF-symbol-like shape available in the existing deployment target, not an internet-loaded image and not a player bird texture.

- [ ] **Step 2: Verify Academy does not expose bird-selection controls**

Static contract must reject `setSelectedBirdID:` usage anywhere under `spritybird/Academy/UI`.

- [ ] **Step 3: Commit**

```bash
git add spritybird/Academy/UI/FGCommanderGratataView.* \
        spritybird/Academy/UI/FGAcademyHomeViewController.* \
        tests/academy/test_academy_source_contract.py \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Flight Academy home dashboard"
```

---

# R9F — Training Flow

### Task 9: Add Academy session state machine

**Files:**
- Create: `spritybird/Academy/FGAcademySession.h`
- Create: `spritybird/Academy/FGAcademySession.m`
- Create: `spritybird/Academy/UI/FGAcademyTrainingViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyTrainingViewController.m`
- Create: `spritybird/Academy/UI/FGAcademyDebriefViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyDebriefViewController.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
typedef NS_ENUM(NSInteger, FGAcademySessionState) {
    FGAcademySessionStateBriefing = 0,
    FGAcademySessionStateFlying,
    FGAcademySessionStateDebrief,
    FGAcademySessionStateEchoEligible,
    FGAcademySessionStateFinished
};
```

```objc
@interface FGAcademySession : NSObject
@property (nonatomic, readonly) FGAcademyDrill *drill;
@property (nonatomic, assign, readonly) FGAcademySessionState state;
- (void)beginFlight;
- (void)completeWithSummary:(FGRunSummary *)summary;
- (void)finish;
@end
```

- [ ] **Step 1: Implement state transitions independent of SpriteKit**

Invalid transitions are ignored/fail closed; session never owns bird physics or obstacle generation.

- [ ] **Step 2: Build Briefing and Debrief screens**

Briefing:
- drill title;
- family;
- focus skills;
- concise objective.

Debrief:
- one positive observation;
- one improvement cue;
- targeted band/trend;
- trace slot;
- Echo Lesson if eligible;
- finish/retry.

- [ ] **Step 3: Do not install Classic instrumentation hook yet**

Before any attempt to connect the session to live Scene events, run a separate read-only instrumentation audit. If connection requires modifying a protected gameplay file, stop and create a bounded, separately reviewed hook task with behavioral-equivalence evidence and a new hash baseline only after approval.

- [ ] **Step 4: Verify and commit**

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
git add spritybird/Academy/FGAcademySession.* \
        spritybird/Academy/UI/FGAcademyTrainingViewController.* \
        spritybird/Academy/UI/FGAcademyDebriefViewController.* \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Flight Academy training flow"
```

---

# R9G — Certification Engine

### Task 10: Add certification readiness, segments, and promotion

**Files:**
- Create: `spritybird/Academy/FGAcademyCertificationEngine.h`
- Create: `spritybird/Academy/FGAcademyCertificationEngine.m`
- Create: `spritybird/Academy/UI/FGAcademyCertificationViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyCertificationViewController.m`
- Create: `tests/academy/FGAcademyCertificationEngineTests.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
@interface FGAcademyCertificationResult : NSObject
@property (nonatomic, assign, readonly) BOOL passed;
@property (nonatomic, assign, readonly) NSInteger passedSegments;
@property (nonatomic, assign, readonly) NSInteger requiredSegments;
@property (nonatomic, assign, readonly) FGAcademyRank awardedRank;
@property (nonatomic, copy, readonly) NSString *resultExplanation;
@end

@interface FGAcademyCertificationEngine : NSObject
- (BOOL)isReadyForNextCertification:(FGAcademyProfile *)profile;
- (FGAcademyCertificationResult *)evaluateSegmentResults:(NSArray *)segmentResults
                                                 profile:(FGAcademyProfile *)profile;
@end
```

Baseline exam structure: three evaluated segments, pass two of three.

- [ ] **Step 1: Write tests**

Verify:
- insufficient evidence => not ready;
- Cadet fundamentals do not require advanced evidence;
- higher ranks progressively require broader skill coverage;
- 2/3 passes => pass;
- 1/3 => not yet certified;
- promotion never changes gameplay constants;
- Flight Master cannot promote beyond Flight Master.

- [ ] **Step 2: Implement fixed structure with adaptive emphasis**

Adaptive emphasis chooses evaluation focus only. It may not change gap, speed, impulse, mass, obstacle interval, collision geometry, or scoring.

- [ ] **Step 3: Add certification UI**

Show:
- current/next rank;
- readiness;
- segment progress;
- result;
- explanation;
- promotion presentation.

- [ ] **Step 4: Verify and commit**

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
git add spritybird/Academy/FGAcademyCertificationEngine.* \
        spritybird/Academy/UI/FGAcademyCertificationViewController.* \
        tests/academy/FGAcademyCertificationEngineTests.m \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Flight Academy certification engine"
```

---

# R9H — Flight Record, Trace, and Explainability

### Task 11: Add instructional flight traces

**Files:**
- Create: `spritybird/Academy/FGFlightTrace.h`
- Create: `spritybird/Academy/FGFlightTrace.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

**Interfaces:**

```objc
@interface FGFlightTracePoint : NSObject
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;
@property (nonatomic, assign, readonly) CGFloat normalizedY;
@property (nonatomic, assign, readonly) BOOL correctionPoint;
@property (nonatomic, assign, readonly) BOOL recoveryPoint;
@end

@interface FGFlightTrace : NSObject
@property (nonatomic, copy, readonly) NSArray *points;
+ (instancetype)traceFromSignals:(NSArray *)signals maximumPoints:(NSUInteger)maximumPoints;
@end
```

- [ ] **Step 1: Implement bounded trace sampling**

Keep short traces only. Normalize Y for presentation; retain no raw long-term telemetry stream.

- [ ] **Step 2: Ensure missing/invalid trace returns nil-safe empty state**

Echo Lesson falls back to normal retry.

- [ ] **Step 3: Commit**

```bash
git add spritybird/Academy/FGFlightTrace.* \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add instructional Academy flight traces"
```

### Task 12: Add Flight Record and Progress screens

**Files:**
- Create: `spritybird/Academy/UI/FGAcademyFlightRecordViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyFlightRecordViewController.m`
- Create: `spritybird/Academy/UI/FGAcademyProgressViewController.h`
- Create: `spritybird/Academy/UI/FGAcademyProgressViewController.m`
- Modify: `Flappy Gratata.xcodeproj/project.pbxproj`

Flight Record shows:
- five band history summaries;
- current calibration state;
- recent coaching;
- recent traces;
- certification history;
- temporary Flight Signature;
- `Why this?` evidence explanation.

Progress shows:
- Cadet → Aviator → Wing Leader → Ace → Flight Master;
- earned insignia;
- non-power Academy milestones.

- [ ] **Step 1: Build read-only presentation from `FGAcademyProfile`**

UI cannot mutate evaluator scores directly.

- [ ] **Step 2: Add `Why this?` modal/sheet**

The text comes exclusively from `FGAcademyCoachingResult.whyText`; if `evidenceSufficient == NO`, display the neutral analysis message.

- [ ] **Step 3: Verify and commit**

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
git add spritybird/Academy/UI/FGAcademyFlightRecordViewController.* \
        spritybird/Academy/UI/FGAcademyProgressViewController.* \
        "Flappy Gratata.xcodeproj/project.pbxproj"
git commit -m "Add Academy flight record and progress"
```

---

# R9I — Resilience and Recalibration

### Task 13: Harden old/corrupt data and neutral fallbacks

**Files:**
- Modify: `spritybird/Academy/FGAcademyProfileStore.m`
- Modify: `spritybird/Academy/FGFlightSkillEvaluator.m`
- Modify: `spritybird/Academy/FGAcademyCoach.m`
- Modify: `spritybird/Academy/FGAcademyDrillSelector.m`
- Modify: `spritybird/Academy/FGAcademySession.m`
- Modify: relevant Academy XCTest files

- [ ] **Step 1: Add failing resilience tests**

Cover:
- corrupted profile dictionary;
- missing skill entry;
- NaN/infinite score input where representable;
- unknown drill ID;
- missing coaching history;
- missing trace;
- incompatible evaluator evidence;
- future schema version;
- partial certification dictionary.

- [ ] **Step 2: Implement exact safe fallbacks**

- invalid profile → safe defaults;
- durable valid certification rank retained where safe;
- incompatible evaluator evidence → recalibrate confidence;
- missing recommendation → `Steady Rhythm`;
- missing trace → normal retry;
- malformed coaching → `Complete another flight for analysis`;
- insufficient evidence → `Calibrating`.

- [ ] **Step 3: Verify all static guards**

```bash
python3 tests/academy/test_academy_source_contract.py
git diff --check
```

- [ ] **Step 4: Commit**

```bash
git add spritybird/Academy \
        tests/academy
git commit -m "Harden Flight Academy resilience"
```

---

# R9J — Full Static Closure and Full-Xcode Handoff

### Task 14: Run R9 static closure audit

**Files:**
- Modify/Create: `tests/academy/test_academy_source_contract.py`
- Create: `docs/superpowers/evidence/2026-08-26-r9-static-closure.md`

- [ ] **Step 1: Extend the static audit to cover all R9 contracts**

The audit must verify:
- all expected Academy `.h/.m` files exist;
- PBX references and compile-source membership are unique;
- no Academy source calls protected gameplay mutation APIs;
- no bird-selection persistence mutation in Academy UI;
- no R10 DNA persistence fields;
- all five skill names and six visible states including Calibrating;
- all five certification ranks;
- all three drill families and approved drill names;
- `Why this?` explainability surface exists;
- profile schema version exists;
- protected gameplay hashes match expected baseline unless a separately authorized hook milestone explicitly re-baselined them;
- Git worktree is clean after closure commit.

- [ ] **Step 2: Run static closure**

```bash
python3 tests/academy/test_academy_source_contract.py
plutil -lint "Flappy Gratata.xcodeproj/project.pbxproj"
git diff --check
```

Expected: all available static checks PASS.

- [ ] **Step 3: Record build limitation accurately**

Evidence document must state:

```text
STATIC_R9_CONTRACT=PASS
IOS_BUILD_VALIDATION=NOT_PERFORMED_ON_THIS_MAC
XCTEST_VALIDATION=NOT_PERFORMED_ON_THIS_MAC
```

Do not represent R9 as runtime-validated until a full Xcode/iOS SDK environment runs the build and XCTest suite.

- [ ] **Step 4: Full-Xcode validation when available**

On a Mac with full Xcode and a compatible simulator:

```bash
xcodebuild -project "Flappy Gratata.xcodeproj" \
  -scheme "Flappy Gratata" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  clean build

xcodebuild test -project "Flappy Gratata.xcodeproj" \
  -scheme "Flappy Gratata" \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Expected:
- build exits `0`;
- all Academy XCTest cases pass;
- manual smoke confirms Academy Home → Training / Certification / Flight Record navigation;
- Classic play remains behaviorally unchanged;
- no bird selection is changed from Academy;
- corrupt/missing Academy data falls back safely.

- [ ] **Step 5: Commit closure evidence**

```bash
git add tests/academy/test_academy_source_contract.py \
        docs/superpowers/evidence/2026-08-26-r9-static-closure.md
git commit -m "Document R9 Flight Academy static closure"
```

---

# Separate Required Gate — Live Classic Instrumentation Hook

The R9 domain, persistence, coaching, drills, certification, and UI can be developed without silently modifying protected Classic sources. However, a complete live Academy ultimately needs actual flight signals from Classic runs.

Before touching any protected file, create a separate bounded change with these requirements:

1. identify the minimum existing call sites that can emit approved observation events;
2. write behavioral-equivalence tests/guards first;
3. change only the minimum protected source lines necessary to emit read-only signals;
4. do not alter return values, branch conditions, physics constants, object lifetimes, collision handling, score, restart, or obstacle generation;
5. run full Xcode build/XCTest before accepting a new protected hash baseline;
6. record old and new hashes plus diff;
7. obtain explicit approval before committing the re-baseline.

Until that gate is executed and full-runtime validation is available, the plan must report:

```text
LIVE_SIGNAL_HOOK=NOT_YET_AUTHORIZED_OR_RUNTIME_VALIDATED
CLASSIC_GAMEPLAY_HASH_BASELINE=PRESERVED
```

This prevents Academy instrumentation from being disguised as ordinary feature work.

---

# Plan Self-Review

## Spec coverage

- Premium futuristic Academy identity: R9E.
- Commander Gratata and no bird-selection duplication: R9E.
- Orientation / briefing / drill / debrief / certification journey: R9F + R9G.
- Rhythm / Precision / Recovery / Control / Nerve: R9B.
- Confidence-aware bands and calibration: R9B + R9I.
- Cadet → Flight Master certification: R9G.
- Technique / Pressure / Signature drills: R9D.
- Flight Signature as coaching only: R9D + R9H.
- Flight traces and Echo Lesson fallback: R9H + R9I.
- Explainable “Why this?”: R9D + R9H.
- Versioned local persistence: R9C.
- Fail-closed Academy behavior: R9I.
- R9/R10 boundary: static contract from R9A onward and R9J closure.
- Classic gameplay safeguards: global constraints + R9A static guard + separate instrumentation gate + R9J closure.
- On-device/offline-only requirement: all milestones.
- Static/full-Xcode validation distinction: all milestone gates + R9J.

## Type consistency

The plan uses the following stable dependency order:

`FGFlightSignal` → `FGFlightSignalRecorder` → `FGRunSummary` → `FGFlightSkillEvaluator` → `FGAcademyProfile` / `FGAcademyProfileStore` → `FGAcademyCoach` → `FGAcademyDrillCatalog` / `FGAcademyDrillSelector` → `FGAcademySession` / `FGAcademyCertificationEngine` → Academy UI.

No later task is permitted to bypass these interfaces by reading gameplay internals directly.
