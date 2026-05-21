# Combat + Movement Integrity Audit — 11 Setan

**Date:** 2026-05-22 · **Scope:** `src/server/ai/enemies/*.lua` vs lore-expected
behavior. Leak excluded (moderation SKIP).

## How the current system works
- **Movement** is 100% `EnemyAI` FSM (`EnemyAI.lua`): IDLE→PATROL→CHASE→ATTACK,
  driven by `Humanoid:MoveTo`. WalkSpeed is set **every tick** from
  `Constants.ENEMY_TIERS[tier].walkSpeed / chaseSpeed`.
  → A per-enemy `Humanoid.WalkSpeed = X` does NOT stick (FSM overwrites it).
  **Fix applied:** EnemyAI now multiplies by a `SpeedMultiplier` model
  attribute (default 1.0). Locomotion helpers set that attribute.
- `HipHeight` / `JumpPower` are NOT touched by the FSM → safe to set per-enemy.
- **Combat** = default melee (`Humanoid:TakeDamage` on `attackCooldown`), or a
  per-enemy `onAttack` callback. No projectile/AoE/grab/stun framework exists.

## Audit + refactor table

| Setan | Combat (cur→expected) | Movement (cur→expected) | Refactor applied |
|-------|----------------------|--------------------------|------------------|
| Pocong | melee → hop-lunge+scream | cosmetic hop tween → HOP | `applyHopLocomotion` (JumpPower + tag); scream=defer |
| Kuntilanak | melee → scream+teleport | walk → FLOAT | `applyFloatLocomotion` (HipHeight+JumpPower0+0.9×) |
| Genderuwo | melee → swing+slam AoE | walk → STOMP | `applyStompLocomotion` (0.6× heavy); AoE=defer |
| Tuyul | melee → steal+bite | walk → SCURRY | `applyScurryLocomotion` (1.6×); steal=defer |
| SundelBolong | melee → wail+lunge | walk → FLOAT (backwards) | `applyFloatLocomotion`; backwards-face=defer |
| Banaspati | melee → fireball | **hover-lock (already floats)** → FLOAT | MATCH (existing `startHoverLock`); projectile=defer |
| WeweGombel | onAttack → snatch-grab | walk → SHUFFLE | `applyShuffleLocomotion` (0.5×); grab=defer |
| ButoIjo | onAttack → club+shockwave | walk → STRIDE | `applyStrideLocomotion` (0.7×; size via rigSize 2.0) |
| SetanPasar | melee → sword combo+block | walk → KNIGHT (normal) | MATCH (normal walk = expected) |
| NagaKomodo | melee+fire-breath → bite+tail+spike | walk → SLITHER | `applySlitherLocomotion` (HipHeight low+JumpPower0) |
| BuddhaWraith | melee → curse+lotus blast | walk → FLOAT MEDITATION | `applyMeditationLocomotion` (0.3× drift+float); teleport=defer |

## Classification summary
- **Movement MISMATCH → refactored (9):** Pocong, Kuntilanak, Genderuwo, Tuyul,
  SundelBolong, WeweGombel, ButoIjo, NagaKomodo, BuddhaWraith.
- **Movement MATCH (2):** Banaspati (already hovers), SetanPasar (normal walk).
- **Combat:** all have a working **melee baseline** (MATCH for melee-type
  enemies). Advanced patterns (projectile, AoE, grab, stun, teleport, multi-hit
  combo, ground spike) are **DEFERRED** — they need new gameplay systems +
  Studio playtesting + (often) animations, which is out of safe autonomous
  scope. Documented here as the combat backlog.

## What the refactor does (SAFE, reusable — `EnemyRigs.apply*Locomotion`)
Pure Humanoid-property / attribute setters, no untested physics:
- `SpeedMultiplier` attribute (read by EnemyAI WalkSpeed) → scurry/shuffle/stomp/drift feel
- `HipHeight` raise (float/meditation) or low (slither) → hover / ground-hug look
- `JumpPower` = 0 (float/slither) or set (hop)
- `MoveStyle` attribute (string tag) → for future client animation/SFX hooks

## DEFERRED (need Studio playtest / animations / new systems — NOT auto-done)
- BodyVelocity/segment custom locomotion (true slither wave, fireball propulsion)
- Combat: projectiles, AoE shockwaves, grab-carry, scream stun, teleport, combos
- Screen shake + footstep SFX (client-side), custom AnimationIds
- Runtime model re-scaling (size currently from `Constants.ENEMIES.rigSize`)
