# Smoke Test — Enemy Mesh / Asset Verification

Manual F5 playtest checklist for enemy mesh integration after Studio "Save to
Roblox" import. Run in Studio (Play Solo). No automated tests yet.

## Pre-req
- Rojo synced (latest `src/` + `assets/` in place).
- `EnemyMeshIds.lua` wired with Studio asset IDs for PROCEED setan.

## A. Mesh load + fallback (per setan)
For each spawned enemy, in the Explorer / via command bar:
- [ ] Model spawns without error in Output.
- [ ] `model:GetAttribute("RigVariant")` == `"Mesh"` if the asset ID is valid &
      loaded; `"Primitive"` if the ID is missing/unauthorized (fallback works).
- [ ] Mesh visual matches the `assets/enemies/<Name>_preview.png` render.
- [ ] No red `[EnemyRigs] LoadAsset failed` warning for PROCEED setan.
      (Warnings EXPECTED for SKIP setan still on primitive IDs.)

## B. Locomotion feel (`MoveStyle` attribute)
Aggro each enemy and watch movement vs `docs/combat_movement_audit.md`:
- [ ] Kuntilanak / SundelBolong — **Float**: hovers (raised HipHeight), glides, no jump.
- [ ] Pocong — **Hop**: hop cosmetic; moves toward player.
- [ ] Genderuwo — **Stomp**: noticeably slow heavy walk (~0.6×).
- [ ] Tuyul — **Scurry**: fast (~1.6×), small.
- [ ] WeweGombel — **Shuffle**: very slow (~0.5×).
- [ ] ButoIjo — **Stride**: slow, large.
- [ ] NagaKomodo — **Slither**: ground-hugging (low HipHeight), no jump.
- [ ] BuddhaWraith — **Meditation**: very slow drift (~0.3×), floats.
- [ ] Banaspati — hovers (existing hover-lock). SetanPasar — normal walk.
- [ ] Enemies still path to the player (FSM `Humanoid:MoveTo` intact — no
      floating-away / stuck). SpeedMultiplier scales speed but doesn't break AI.

## C. Combat baseline
- [ ] Enemy deals melee damage on contact (cooldown per tier).
- [ ] Enemy dies → fades → drops loot (LootService) → gauntlet gate unlock if applicable.

## Known gaps (backlog, NOT expected to pass)
- Advanced combat (scream stun, projectile, AoE, grab, teleport) — deferred.
- Custom animations / SFX / screen shake — deferred.
