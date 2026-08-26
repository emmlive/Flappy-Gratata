# Flappy Gratata 3.0 — Monetization Architecture Design

Date: 2026-08-26
Status: Approved design, ready for repository review
Scope: Post-R9 monetization track, targeted for R10/R11 planning

## 1. Purpose

Flappy Gratata 3.0 monetization must create sustainable revenue without weakening the core game, turning progression into pay-to-win, or making the free experience feel incomplete.

The launch model is:

- free Classic gameplay;
- free core Flight Academy;
- one-time Elite Lifetime upgrade;
- optional cosmetic in-app purchases;
- no subscription at launch;
- no consumable currency at launch;
- no rewarded ads at launch.

The monetization system must remain mechanically separate from Classic gameplay physics, collision, scoring, obstacle generation, and difficulty.

## 2. Product Principles

1. Free players receive the complete core game loop.
2. Elite sells depth, personalization, prestige, and cosmetics rather than gameplay power.
3. Existing earnable progression must not be converted into pay-only progression.
4. Premium birds must use the same Classic physics, hitbox, scoring, and gameplay rules as every other bird.
5. Purchase prompts must be discoverable but low-pressure.
6. Store ownership must be determined from verified entitlement state, not UI state or local button actions.
7. Restore Purchases must always be available.
8. Free Classic and free Academy content must remain usable when StoreKit is unavailable.
9. Monetization launch scope should remain intentionally small.
10. Future ads, subscriptions, consumable currency, or custom backend purchase systems require a separate design and approval.

## 3. Launch Business Model

### 3.1 Free Tier

Free players receive:

- Classic gameplay;
- full five-skill Academy evaluation;
- core Academy coaching;
- basic Technique / Pressure / Signature training;
- standard certification progression;
- standard Flight Record;
- normal bird progression and earnable birds;
- standard Commander Gratata presentation;
- standard Academy presentation.

The free tier must not behave like a demo or trial.

### 3.2 Elite Lifetime

Elite is a one-time permanent purchase.

Launch direction:

- Product: Elite Lifetime
- Price direction: USD $7.99
- Type: non-consumable entitlement
- No recurring billing

Elite includes:

- Elite Vanguard exclusive bird;
- premium Academy visual theme;
- Elite insignia set;
- enhanced Commander Gratata presentation;
- deeper Flight Record history;
- advanced trace comparison;
- additional advanced Academy drills;
- deeper Academy analysis / premium presentation features;
- selected premium cosmetic value bundled with Elite.

Elite must not unlock:

- stronger physics;
- larger/smaller hitbox;
- altered obstacle spacing;
- score multipliers;
- easier certification logic;
- hidden difficulty advantages;
- gameplay power.

## 4. Elite Vanguard

Elite Vanguard is the permanent ownership symbol for Elite Lifetime.

Visual direction:

- deep obsidian / navy body;
- platinum-white structural feathers;
- restrained gold and cyan accents;
- precision-machined visor details;
- premium aviation / Vanguard identity;
- visually distinct from Cyber, Academy, Legendary, and Commander Gratata.

Elite Vanguard is:

- unique to Elite Lifetime;
- not separately purchasable;
- not included in cosmetic bundles;
- not earnable through ads;
- not a shortcut unlock for another existing bird;
- mechanically identical to all other birds.

The Hangar should label the bird clearly as:

`ELITE EXCLUSIVE`

## 5. Cosmetic Products

Cosmetic packs remain optional and independent from Elite.

Launch pricing direction:

- Standard cosmetic pack: USD $2.99
- Larger premium bundle: USD $4.99

Launch catalog:

### 5.1 Cyber Pack — $2.99

Provides Cyber-themed cosmetic value and presentation extras.

The pack must not remove normal earnable progression already associated with existing Cyber content. Paid content should be distinct cosmetic value, variants, presentation enhancements, or clearly separated premium additions.

### 5.2 Legendary Pack — $2.99

Provides Legendary-themed cosmetic value and premium presentation extras.

The same anti-pay-to-skip rule applies: existing earnable Legendary progression must remain meaningful.

### 5.3 Premium Flight Bundle — $4.99

A larger non-Elite cosmetic bundle that may combine:

- premium visual themes;
- presentation effects;
- selected cosmetic variants;
- non-power Hangar presentation items.

The bundle must not include:

- Elite Vanguard;
- Elite-only Academy functionality;
- gameplay advantages.

## 6. No Ads at Launch

Rewarded ads are deferred.

Launch includes:

- no rewarded ads;
- no interstitial ads;
- no banner ads;
- no ad-based unlock path.

Ads may be revisited only after real player behavior provides a product reason to add them, and any later ad system requires separate design approval.

## 7. No Subscription at Launch

Elite is a lifetime purchase.

A subscription may be reconsidered only if the product later gains enough recurring value, such as:

- seasons;
- live challenges;
- recurring content drops;
- cloud profiles;
- competitive events;
- other durable recurring services.

The initial release must not introduce a subscription simply to create recurring revenue.

## 8. No Consumable Currency at Launch

Do not add coins, gems, tokens, energy, or other paid consumable currency at launch.

The Store should use clear real-money products rather than obscuring prices behind virtual currency.

## 9. Storefront Architecture

The game uses one primary premium Store screen.

Store layout:

1. Elite Lifetime hero offer;
2. Elite Vanguard / Elite benefits preview;
3. cosmetic packs;
4. larger premium bundle;
5. Gift Elite;
6. Redeem Code;
7. Restore Purchases.

The Elite hero card should clearly communicate:

- one-time purchase;
- USD $7.99 launch direction;
- no subscription;
- what Elite adds;
- what the player already gets free.

The Store should not visually imply that free users have an incomplete game.

## 10. Purchase Entry Points

Allowed launch entry points:

### 10.1 Store

Permanent user-initiated Store destination.

### 10.2 Locked Premium Preview

If a user taps:

- Elite Vanguard;
- Elite theme;
- advanced Elite Academy feature;
- another explicitly Elite-only presentation item;

show a polished preview with a clear purchase action such as:

`Unlock Elite — $7.99`

### 10.3 Limited Milestone Invitation

After the player has experienced enough free Academy value to understand the upgrade, the app may show a restrained Elite invitation at a meaningful milestone.

This must not become a recurring interruption.

## 11. Purchase Pressure Rules

The app must not:

- show an Elite paywall after every loss;
- interrupt active gameplay;
- block certification results;
- repeatedly reopen the same paywall after dismissal;
- punish a player for closing a Store or purchase sheet;
- degrade free content because the user declined Elite.

After dismissing an unsolicited Elite invitation, suppress another automatic invitation for a meaningful period or until a genuinely new milestone is reached.

User-initiated Store access and locked-content previews remain available at any time.

## 12. StoreKit Product Structure

The launch monetization architecture uses a small set of non-consumable StoreKit products.

Conceptual products:

- `eliteLifetime`
- `cyberPack`
- `legendaryPack`
- `premiumFlightBundle`

Final App Store Connect product identifiers must be selected and recorded during implementation/release planning and must not be guessed from this design document.

At implementation time, current Apple StoreKit / App Store Connect requirements must be verified against current Apple documentation before product creation or submission.

## 13. Entitlement Service

All premium ownership checks must go through one entitlement service.

Conceptual responsibilities:

- load StoreKit product metadata;
- purchase products;
- observe verified transaction state;
- restore purchases;
- expose current entitlements;
- cache previously verified ownership safely for offline presentation;
- reject unverified or malformed purchase state;
- notify Store / Academy / Hangar UI of entitlement changes.

UI must not directly decide ownership.

Conceptual entitlements:

- `eliteLifetime`
- `cyberPack`
- `legendaryPack`
- `premiumFlightBundle`

Elite-derived feature checks should resolve from `eliteLifetime`, rather than creating unrelated local flags for each included Elite benefit.

## 14. Purchase State Model

User-visible purchase states:

- Available
- Purchasing
- Purchased
- Pending
- Cancelled
- Unavailable

Rules:

- Purchasing disables duplicate purchase attempts for the same product.
- Purchased appears only after verified entitlement confirmation.
- Pending leaves premium content locked until verification succeeds.
- Cancelled returns cleanly to the prior UI and is not presented as a failure.
- Unavailable shows neutral retry messaging.
- Product metadata failure must not produce a fake or hard-coded App Store price.

## 15. Restore Purchases

Restore Purchases must be visible from the Store.

Restore behavior:

1. request current valid purchase history / transaction state through StoreKit;
2. rebuild entitlement state from verified ownership;
3. update Store, Hangar, and Academy from the same entitlement source;
4. never rely only on stale UI or an unverified local flag.

If restoration cannot complete because StoreKit or the network is unavailable, previously verified local entitlement state may continue to be honored while the app presents a neutral retry state.

Free content must remain available.

## 16. Gift Elite

Launch gifting is limited to Elite Lifetime.

The Store includes:

`Gift Elite`

The gifting path must use an Apple-compliant mechanism available for the final StoreKit / App Store release configuration.

The design intent is:

Gift Elite
→ eligible Apple purchase / gifting flow
→ recipient redemption
→ verified StoreKit transaction
→ `eliteLifetime` entitlement

Gift recipients receive the same Elite entitlement as direct purchasers.

At launch:

- Elite Lifetime is giftable;
- cosmetic packs are not giftable;
- Elite Vanguard remains part of the Elite entitlement;
- gifts do not create a separate gameplay entitlement class.

Cosmetic gifting may be evaluated later.

## 17. Redeem Code

The Store includes:

`Redeem Code`

Redeem Code is intended for:

- developer promotions;
- giveaways;
- creators;
- events;
- testers where appropriate;
- individually distributed free Elite access campaigns.

The redemption path must use Apple-managed code / offer mechanisms supported for the final StoreKit product configuration.

Design intent:

Redeem Code
→ Apple redemption flow
→ verified StoreKit transaction
→ normal entitlement service
→ `eliteLifetime` ownership

The app must not implement a simple private license-key database that bypasses Apple purchase / entitlement rules for paid digital functionality.

Current Apple code eligibility, offer-code limits, product support, and redemption requirements must be re-verified immediately before implementation because platform rules may change.

## 18. Failure Handling

Monetization fails closed.

If StoreKit fails:

- Classic continues;
- free Academy continues;
- existing verified entitlements remain available where safely cached;
- new premium content does not unlock without verification;
- Store shows neutral retry / unavailable state;
- no crash or dead-end navigation.

If an entitlement payload is invalid:

- reject the invalid state;
- do not unlock content;
- preserve previously verified durable ownership when safe;
- retry reconciliation with StoreKit.

If a purchase is pending:

- do not grant premium access yet;
- show pending state;
- reconcile automatically when StoreKit later verifies completion.

## 19. Purchase Integrity

The app must never unlock paid content based only on:

- tapping a purchase button;
- setting a local UI boolean;
- a Store success animation;
- an unverified transaction;
- a manually edited local preference.

Premium content is unlocked only from the centralized entitlement service after valid StoreKit ownership is established.

The Store, Academy, and Hangar must all consume the same entitlement state.

## 20. Offline Behavior

Previously verified non-consumable entitlements should remain usable offline through a safe local entitlement cache / reconciliation strategy.

Offline rules:

- previously verified Elite remains available;
- previously verified cosmetic packs remain available;
- new purchases cannot be completed offline;
- restore may show retry state;
- free content remains fully usable;
- local cache is never treated as authoritative for granting a brand-new purchase.

## 21. Testing Strategy

### 21.1 Entitlement Unit Tests

Test:

- each product maps to exactly one expected entitlement;
- Elite enables all Elite-derived presentation/features;
- cosmetic products do not grant Elite;
- pending does not unlock;
- cancelled does not unlock;
- failed/unverified transaction does not unlock;
- restored verified purchase unlocks correctly;
- duplicate transaction handling is idempotent.

### 21.2 UI State Tests

Test:

- product metadata unavailable;
- purchasing state;
- pending state;
- purchased state;
- cancellation;
- restore success;
- restore unavailable;
- Elite-owned Store presentation;
- non-Elite locked preview;
- free UI remains usable with StoreKit unavailable.

### 21.3 Sandbox / TestFlight Purchase Tests

Before release validate:

- fresh Elite purchase;
- each cosmetic purchase;
- cancellation;
- interrupted transaction;
- pending transaction where testable;
- restore after reinstall;
- restore on another eligible device/account context;
- offline launch after prior verified ownership;
- entitlement propagation to Store;
- entitlement propagation to Hangar;
- entitlement propagation to Academy.

### 21.4 Gameplay Regression Tests

Verify Elite Vanguard and all paid cosmetics preserve:

- bird mass;
- impulse;
- hitbox;
- collision behavior;
- scoring;
- obstacle spacing;
- obstacle speed;
- restart behavior.

No paid product may change Classic mechanical behavior.

## 22. Release Safeguards

Before monetization release:

- one entitlement service only;
- no duplicate StoreKit observers/listeners;
- Restore Purchases visible;
- no hard-coded “owned” UI state;
- no hard-coded fake App Store price when metadata fails;
- no Store dependency for free Classic;
- no Store dependency for free Academy;
- all launch products configured and validated in App Store Connect;
- purchase metadata and screenshots/review information complete where required;
- StoreKit sandbox/TestFlight tests complete;
- current Apple review and StoreKit requirements re-verified;
- legal / privacy disclosures updated if required by the final implementation.

## 23. Launch Catalog Summary

Launch paid catalog:

- Elite Lifetime — $7.99 direction
- Cyber Pack — $2.99 direction
- Legendary Pack — $2.99 direction
- Premium Flight Bundle — $4.99 direction

Launch access mechanisms:

- direct purchase;
- Restore Purchases;
- Gift Elite;
- Redeem Code.

Not included at launch:

- subscription;
- consumable currency;
- rewarded ads;
- interstitial/banner ads;
- pay-to-win items;
- cosmetic-pack gifting;
- custom external license-key unlock system.

## 24. R9 / R10 / R11 Boundary

R9 remains focused on Flight Academy observation, coaching, drills, certification, and progress.

This monetization architecture is not to be inserted into R9 implementation work.

Recommended sequencing:

- R9: complete Flight Academy.
- R10: progression / Flight DNA / unlock architecture, including clear entitlement boundaries for cosmetic ownership.
- R11: StoreKit monetization integration, premium Store, Elite fulfillment, purchase restoration, Gift Elite / Redeem Code integration if supported by the final Apple configuration, and release validation.

If implementation sequencing later shows StoreKit foundation must land before some R10 unlock wiring, that dependency must be planned explicitly rather than silently mixed into R9.

## 25. Success Criteria

The monetization system is successful when:

1. free players receive a complete, enjoyable game and core Academy;
2. Elite feels immediately valuable at $7.99 without gameplay advantage;
3. Elite Vanguard is a recognizable premium ownership symbol;
4. cosmetic purchases remain optional and understandable;
5. the Store is premium and low-pressure;
6. purchase ownership has one verified source of truth;
7. restoration is reliable;
8. Gift Elite and Redeem Code use Apple-compliant entitlement paths;
9. StoreKit outages never block free gameplay;
10. premium ownership survives reinstall/device restoration through supported StoreKit mechanisms;
11. no launch monetization path introduces subscription fatigue, virtual-currency confusion, or ad pressure;
12. paid birds remain mechanically identical to free birds.
