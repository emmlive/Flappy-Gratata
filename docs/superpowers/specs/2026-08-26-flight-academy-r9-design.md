# Flappy Gratata 3.0 — R9 Flight Academy Design

Date: 2026-08-26
Status: Approved design, ready for repository review
Phase: R9

## 1. Purpose

R9 introduces Flight Academy as a premium futuristic flight-school mode that observes how the player flies, coaches specific skills, recommends personalized drills, conducts certification flights, and records Academy progress without changing Classic gameplay.

The Academy's central product idea is that Flappy Gratata should not only answer "How far can you fly?" but also "How do you fly?"

R9 establishes the behavioral observation and coaching foundation that R10 Flight DNA can later consume. R9 does not create permanent Flight DNA traits, alter bird cosmetics from behavior, or change gameplay physics.

## 2. Product Principles

1. Classic gameplay remains authoritative and mechanically unchanged.
2. The Academy observes and interprets play; it does not secretly assist or handicap the player.
3. Progress is earned through demonstrated skill and consistency, not XP grinding alone.
4. Coaching must be explainable and based on observable flight behavior.
5. Player-facing skill ratings use prestige bands, while precise internal scores remain hidden.
6. R9 remains fully on-device and does not require a backend, account, cloud sync, or analytics service.
7. R9 data is versioned from its first release so future evaluator changes can recalibrate safely.
8. The Academy has its own premium aviation-school identity and does not duplicate the Hangar's bird-selection role.

## 3. Visual Identity

Flight Academy is a clean, prestigious, futuristic aviation institution rather than a classroom, sci-fi laboratory, or arcade mission list.

Visual language:
- deep navy and graphite surfaces;
- cyan and ice-blue instrumentation;
- restrained gold, silver, white, and aviation-orange accents;
- technical but readable typography;
- runway, radar, flight-path, telemetry, and certification motifs;
- subtle holographic/grid motion where appropriate;
- polished rank insignia and certification presentation.

### Commander Gratata

The Academy uses a dedicated instructor identity, Commander Gratata, as its visual host and coaching presence.

Commander Gratata is not the player's selected bird and is not a replacement for Hangar selection. The instructor should visually echo the Academy family while remaining a distinct Academy-only presentation character: navy/cobalt plumage, white structural feathers, aviation-orange highlights, restrained metallic details, and a disciplined elite-flight-instructor silhouette.

Commander Gratata appears mainly on Academy Home, briefing, coaching, and certification surfaces and should not obstruct active gameplay.

## 4. Player Journey

The primary Academy journey is:

Orientation -> Briefing -> Drill -> Debrief -> Improve Skill Bands -> Certification Flight -> Promotion -> Advanced Personalized Training

### 4.1 Orientation Flight

The first Academy visit begins with a brief Orientation Flight that introduces the five measured skills and explains that the Academy evaluates flying behavior without changing the rules of Classic play.

The orientation must remain concise and should not behave like a long tutorial.

### 4.2 Flight Briefing

Each training session starts with a briefing that presents:
- current certification rank;
- current skill-band profile;
- one recommended training focus;
- one concise coaching observation;
- recommended drill and optional alternatives;
- a "Why this?" explanation control.

### 4.3 Drill

The player enters a short focused training objective. The underlying flight mechanics remain Classic mechanics.

### 4.4 Debrief

The Academy reports more than score. A debrief includes:
- one positive observation;
- one improvement cue;
- the targeted skill band and trend;
- a simplified flight trace when evidence is available;
- optional Echo Lesson after near-success or useful comparison opportunities.

### 4.5 Certification Flight

When requirements are met, the player may take a multi-segment practical certification flight. Certification emphasizes consistency across several evaluated segments rather than one lucky run.

## 5. Progression Model

R9 combines skill ratings and formal pilot certification.

### 5.1 Five Flight Skills

The five skills are:
- Rhythm
- Precision
- Recovery
- Control
- Nerve

Internally each skill may use a precise numerical representation plus evidence confidence. Players see prestige bands rather than exact scores.

Recommended visible bands:
- Developing
- Qualified
- Advanced
- Elite
- Mastery

### 5.2 Pilot Certifications

Certification progression:
- Cadet
- Aviator
- Wing Leader
- Ace
- Flight Master

Certification rank is distinct from skill bands. Two players with the same rank may have materially different skill profiles.

Promotion must not provide gameplay power or physics advantages.

## 6. Five-Skill Measurement Model

### 6.1 Rhythm

Rhythm measures flap timing consistency and steadiness.

Possible observed inputs:
- intervals between flap events;
- timing variance;
- rapid repeated taps;
- burst behavior;
- rhythm stability during longer sequences.

The Academy should distinguish intentional cadence changes from repeated unstable corrections where possible.

### 6.2 Precision

Precision measures how cleanly the bird crosses obstacle gaps.

Possible observed inputs:
- bird vertical position at obstacle crossing;
- gap-center offset;
- approach stability;
- late correction magnitude near the scoring plane.

Precision must not require one mathematically perfect flight line. Different successful flying styles remain valid.

### 6.3 Recovery

Recovery measures successful stabilization after a risky or unstable situation.

Possible observed inputs:
- proximity to risky upper/lower corridors;
- unusually large corrections;
- unstable approach followed by successful clearance;
- stabilization over the next several inputs or obstacle crossings.

### 6.4 Control

Control measures correction efficiency and movement stability.

Possible observed inputs:
- unnecessary rapid taps;
- repeated direction reversals;
- vertical oscillation;
- correction frequency and magnitude relative to the obstacle sequence.

Control does not mean "fewest taps wins." It measures purposeful rather than panicked input.

### 6.5 Nerve

Nerve measures behavioral composure under pressure rather than emotion itself.

Possible observed inputs:
- maintenance of established rhythm in later or higher-risk run segments;
- stability after a near mistake;
- performance during pressure-oriented certification/drill segments;
- avoidance of abrupt deterioration under harder sequences.

### 6.6 Confidence and Evidence

Visible skill bands must be confidence-aware.

Rules:
- insufficient evidence shows a calibration state rather than a misleading rating;
- one excellent run cannot instantly create an Elite/Mastery result;
- one poor run cannot immediately destroy an established rating;
- band movement requires minimum evidence and rolling consistency;
- certification rank is more durable than evaluator confidence and should not be casually reduced by recalibration.

## 7. Flight Signature in R9

R9 may present a temporary Academy Flight Signature such as:
- Recovery-Strong Pilot;
- Precision-led Flyer;
- Strong Recovery / Developing Rhythm.

This is a coaching summary only, not permanent Flight DNA.

R9 must not persist R10 DNA identities such as Daredevil, Rhythm, Survivor, Comeback, Explorer, or Legend as permanent evolutionary traits.

## 8. Drill System

The Academy uses a deterministic, handcrafted rule system for selecting drills. It does not procedurally invent arbitrary levels or opaque objectives.

### 8.1 Technique Drills

Technique Drills isolate one skill.

Examples:
- Steady Rhythm;
- Center Entry;
- Smooth Climb;
- Clean Descent;
- Calm Wings.

### 8.2 Pressure Drills

Pressure Drills combine two or more skills under tougher evaluated sequences.

Examples:
- Tight Corridors;
- Fast Patterns;
- Long Runs;
- Edge Pressure.

### 8.3 Signature Drills

Signature Drills target recent player-specific weak patterns.

Examples:
- Late Recovery;
- Panic Taps;
- Unstable Rhythm;
- Over-Correction.

### 8.4 Recommendation Priority

Recommended-drill selection should generally:
1. address a weak skill;
2. reinforce a recently improving skill;
3. occasionally test an established strength;
4. avoid repeating the same recommendation too often.

The UI provides one primary recommendation and a small number of alternatives.

## 9. Certification Engine

Certification Flights use fixed structural rules with adaptive emphasis.

### 9.1 Rank Focus

Cadet:
- fundamentals;
- basic Rhythm and Control.

Aviator:
- adds Precision and basic Recovery.

Wing Leader:
- combines at least three skills;
- introduces sustained pressure.

Ace:
- emphasizes consistency, pressure, and adaptation.

Flight Master:
- evaluates the full five-skill profile at advanced expectations.

### 9.2 Exam Structure

A certification exam contains multiple evaluated segments. The baseline design is three segments with a requirement to pass two of three, unless later implementation evidence shows another fixed structure is safer or clearer.

The system may emphasize weaker skills, but it may not alter Classic physics to manufacture difficulty.

The result must explain why the player passed or was not yet certified.

Examples:
- "Passed — Precision: Elite / Rhythm: Advanced / Recovery: Qualified"
- "Not Yet Certified — Control held; Rhythm broke under pressure. Recommended drill: Calm Wings."

## 10. Echo Lesson and Flight Trace

### 10.1 Flight Trace

A flight trace visualizes the player's path through a short evaluated section.

It should help the player understand:
- where rhythm became unstable;
- where a recovery succeeded;
- where correction increased;
- how a newer attempt compares with an earlier one.

The trace is instructional and should not become a dense analytics chart.

### 10.2 Echo Lesson

Echo Lesson allows the player to compare a new attempt against a translucent trace of a previous attempt.

The purpose is not to race a ghost for speed. The player is asked to fly more smoothly, consistently, or precisely than their prior self.

If Echo evidence is unavailable or invalid, the Academy falls back to a normal retry without blocking progress.

### 10.3 One More Flap

A near-success debrief may identify a compact correction opportunity such as "Your climb began one beat too late" and offer an immediate rematch.

This must remain coaching, not an instruction overlay that guarantees exact tap timing or changes gameplay rules.

## 11. Screen and Navigation Architecture

Flight Academy is one coherent mode with shallow navigation.

### 11.1 Academy Home

Primary contents:
- Commander Gratata;
- current certification;
- five skill bands;
- current Academy focus;
- recent flight trace;
- coaching note;
- recommended drill;
- recent results;
- rank progression summary.

### 11.2 Training

Contains:
- Technique Drills;
- Pressure Drills;
- Signature Drills;
- briefing;
- drill flight;
- debrief;
- optional Echo Lesson.

### 11.3 Certification

Contains:
- rank requirements;
- readiness state;
- certification briefing;
- exam segments;
- result;
- promotion presentation.

### 11.4 Flight Record

Contains:
- skill-band history;
- recent coaching observations;
- recent traces;
- certification history;
- current Flight Signature;
- evaluator calibration state where relevant.

### 11.5 Hangar

The existing Hangar remains the bird/cosmetic destination. Academy must not duplicate bird selection.

### 11.6 Progress

Contains:
- rank progression;
- earned insignia;
- Academy milestones;
- non-power accomplishments.

### 11.7 Navigation Flows

Primary mode navigation:
Academy Home -> Training / Certification / Flight Record -> Academy Home

Training flow:
Briefing -> Flight -> Debrief -> Echo Lesson or Finish

Certification flow:
Exam Briefing -> Segment 1 -> Segment 2 -> Segment 3 -> Result

## 12. Explainability

Every adaptive coaching recommendation should expose a "Why this?" explanation.

Examples:
- "Your flap timing became less consistent during your last three longer runs."
- "Your recent flights show strong recovery after low entries, but more corrections near the next gap."

The explanation must be derived from actual available evidence and must not fabricate behavioral claims when confidence is low.

## 13. Data Architecture

R9 uses four data layers.

### 13.1 Raw Flight Signals

Short-lived observations such as:
- flap timestamps;
- bird vertical position at key events;
- gap centers;
- obstacle crossings;
- correction events;
- run outcome.

Raw signal streams should be summarized after a run rather than retained indefinitely.

### 13.2 Run Summary

Compact derived metrics such as:
- rhythm consistency;
- average gap offset;
- recovery success count;
- correction volatility;
- pressure stability;
- evidence counts.

### 13.3 Academy Profile

Persistent local state such as:
- hidden five-skill scores;
- confidence/evidence counts;
- visible prestige bands;
- current certification rank;
- completed drills;
- certification progress;
- schema version.

### 13.4 Recent Coaching History

Recent-only context such as:
- coaching observations;
- recent weak/strong signals;
- drill recommendations;
- recent drill history.

This layer exists partly to prevent repetitive coaching.

## 14. Component Boundaries

Recommended architecture:

Classic Run
-> FlightSignalRecorder
-> RunSummary
-> FlightSkillEvaluator
-> AcademyProfile
-> AcademyCoach
-> DrillSelector / CertificationEngine
-> Flight Academy UI

### 14.1 FlightSignalRecorder

Purpose: capture approved observable events without making gameplay decisions.

Must not:
- mutate bird physics;
- modify obstacle placement;
- alter score;
- alter collision handling;
- control difficulty.

### 14.2 RunSummary

Purpose: reduce raw signals into compact deterministic metrics.

### 14.3 FlightSkillEvaluator

Purpose: convert run summaries and evidence windows into hidden skill values, visible bands, and confidence.

### 14.4 AcademyProfile

Purpose: own versioned local Academy state.

### 14.5 AcademyCoach

Purpose: create explainable observations from evaluator evidence.

### 14.6 DrillSelector

Purpose: select deterministic recommended drills from an approved catalog.

### 14.7 CertificationEngine

Purpose: determine readiness, segment evaluation, and certification result.

### 14.8 Flight Academy UI

Purpose: present Academy state and navigation. UI should consume Academy-domain outputs instead of directly reading Scene internals.

## 15. Persistence Boundaries

R9 persists only Academy coaching and certification state.

R9 explicitly does not persist:
- permanent Flight DNA traits;
- bird evolutionary identity;
- behavior-driven color mutations;
- aura changes;
- trails;
- eye/visor evolution;
- Echo Gratata transformation state;
- Moonlight or Eclipse DNA transformations.

Those remain R10 responsibilities.

## 16. Versioning and Recalibration

Academy persistence must include a schema version.

When evaluator logic changes:
- durable certification should be preserved where safe;
- skill evidence confidence may be recalibrated;
- old evidence may be ignored if incompatible;
- the player should not lose prestigious earned rank merely because an internal formula changed;
- invalid values must fall back to safe defaults.

If there is insufficient evidence after recalibration, the UI shows a calibration state instead of inventing a skill band.

## 17. Failure Handling

R9 is fail-closed around Classic gameplay.

If any Academy subsystem fails:
- Classic play continues;
- analysis for that run may be skipped;
- Academy UI falls back to a safe neutral state.

Fallback examples:
- missing Echo trace -> normal retry;
- missing drill recommendation -> standard Technique Drill;
- malformed coaching result -> "Complete another flight for analysis";
- insufficient skill evidence -> "Calibrating...";
- invalid persistence -> recover safe Academy defaults while preserving durable achievements where possible.

R9 must not crash or block normal Classic play because analysis data is unavailable.

## 18. Classic Gameplay Safeguards

Protected Classic behavior remains unchanged.

Known protected gameplay source hashes at R9 design baseline:

Scene.m
50c6f4542d0a849f1122dcee726280bd867b049fd651dbd8b5e0df4ade2bc4f9

BirdNode.m
a0c050e3d2fba192fa0584a6d035306f235f690e7924be192b9d7d1db73d63b4

SKScrollingNode.m
5594f59de2c920747012fc977d2bf62aea9d4ffb0bb64e475785a2511d5c435f

Score.m
3276c37c32479aa793b940a8b218787f6753cd9a9e74c03dbc7746bf0aad2ac4

Protected gameplay characteristics include:
- background scrolling speed 0;
- floor scrolling speed 3;
- vertical gap size 120;
- first obstacle padding 100;
- obstacle minimum height 60;
- obstacle interval space 130;
- bird physics body 26 x 18;
- bird mass 0.1;
- impulse 40;
- flap animation 0.2 seconds per frame;
- existing rotation behavior;
- existing collision and scoring behavior.

If instrumentation eventually requires an approved modification to a protected file, that must be isolated as its own explicitly reviewed milestone with behavioral equivalence tests and a new protected baseline. No R9 milestone may silently change these files.

## 19. Testing Strategy

### 19.1 Pure Evaluator Tests

Test deterministic calculation for:
- Rhythm;
- Precision;
- Recovery;
- Control;
- Nerve;
- confidence thresholds;
- visible band transitions;
- calibration states.

### 19.2 Run Summary Tests

Test conversion from known synthetic signal sequences into expected compact metrics.

### 19.3 Persistence Tests

Test:
- profile save/load;
- schema versions;
- invalid values;
- old-version migration/recalibration;
- preservation of durable certification state;
- safe fallback behavior.

### 19.4 Coach and Drill Tests

Test:
- recommendation selection from known skill/evidence states;
- repetition avoidance;
- explanation text tied to actual evidence;
- fallback drill selection.

### 19.5 Certification Tests

Test:
- readiness requirements;
- segment pass/fail;
- multi-segment consistency rule;
- promotion conditions;
- no certification from insufficient evidence.

### 19.6 Integration and Regression Guards

Test that Academy observation does not alter:
- Classic constants;
- physics;
- score calculation;
- collision geometry;
- restart behavior;
- bird-selection persistence;
- visual-family texture contract.

Known gameplay hashes must be checked at each applicable milestone unless a separately approved instrumentation milestone intentionally re-baselines them.

## 20. R9 Milestone Decomposition

### R9A — Flight Signal Contract and Read-Only Instrumentation Design

Define approved observable events and exact boundaries for emitting them from Classic runs. No gameplay mutation.

### R9B — Run Summary and Five-Skill Evaluator

Implement deterministic signal summarization, five hidden skill values, confidence, calibration, and visible prestige bands. No Academy UI dependency.

### R9C — Versioned AcademyProfile Persistence

Implement local versioned storage for skill state, visible bands, confidence, rank, drill history, certification progress, and recent coaching context.

### R9D — Academy Coach and Drill Selector

Implement evidence-based coaching explanations and deterministic Technique / Pressure / Signature recommendation rules.

### R9E — Academy Home and Commander Gratata UI

Implement the approved premium futuristic Academy dashboard and shallow navigation shell. Hangar remains the bird-selection destination.

### R9F — Training Flow

Implement Briefing -> Drill -> Debrief -> optional Echo Lesson using Classic flight mechanics.

### R9G — Certification Engine

Implement Cadet -> Aviator -> Wing Leader -> Ace -> Flight Master readiness and multi-segment certification evaluation.

### R9H — Flight Record and Flight Trace

Implement skill history, recent coaching, certification history, traces, Flight Signature, and "Why this?" explainability.

### R9I — Resilience and Recalibration

Implement corrupted/old-data behavior, confidence recalibration, missing-Echo fallback, fallback drills, and neutral coaching states.

### R9J — Full Static Closure Audit

Verify:
- Academy architecture;
- evaluator tests;
- persistence contracts;
- coaching and certification rules;
- UI/navigation wiring;
- gameplay safeguards;
- expected protected hashes;
- clean Git state;
- no unintended R10 DNA functionality.

## 21. R9 / R10 Boundary

R9 ends when Flight Academy can:
- observe approved flight signals;
- summarize runs;
- evaluate five skills;
- present confidence-aware skill bands;
- coach the player;
- recommend personalized drills;
- run Technique, Pressure, and Signature training;
- conduct certification flights;
- promote through Flight Master;
- record Academy progress;
- show flight traces and Echo Lessons;
- explain recommendations;
- recover safely from incomplete/old/corrupt Academy data.

R9 does not:
- evolve birds based on behavior;
- create permanent Flight DNA traits;
- unlock behavior-driven visual states;
- implement Echo Gratata evolution;
- implement Moonlight/Eclipse transformations;
- alter gameplay power or physics.

R10 consumes R9's durable summarized evidence to build the actual Flight DNA system.

## 22. Success Criteria

R9 is successful when:
1. players can understand how they fly, not only how far they fly;
2. coaching is personalized but explainable;
3. certification reflects consistent demonstrated skill;
4. the Academy feels like a premium futuristic aviation institution;
5. Commander Gratata provides a distinct Academy identity without replacing bird selection;
6. Classic gameplay remains mechanically unchanged;
7. R9 data is sufficient for R10 to build persistent Flight DNA without replacing the observation architecture;
8. all Academy failure modes degrade safely without blocking normal play.
