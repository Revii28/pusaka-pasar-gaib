# Smoke Test — Gauntlet Flow

Manual F5 checklist for the gauntlet system (`GauntletService` / `GauntletConfig`
/ rooms). Run in Studio Play Solo.

## Setup
- [ ] Enter a gauntlet-enabled map via a portal (PortalHub → PortalService).
- [ ] First room builds (RoomBuilder) without Output errors.

## Per-room loop
- [ ] Room spawns the configured enemies (`GauntletConfig` room entry).
- [ ] Gate is LOCKED on entry.
- [ ] Killing all room enemies fires `EnemyAI` → `GauntletService.notifyEnemyKilled`.
- [ ] Gate UNLOCKS only after the room is fully cleared.
- [ ] Advancing applies the next room's `RoomTier` (DropMultiplier scales loot).

## Boss rooms
- [ ] Boss spawns with `attachBossHealthBar` (BillboardGui HP bar visible).
- [ ] Boss HP bar depletes with damage; boss death clears the room.

## Edge cases
- [ ] Player leaving / re-entering mid-gauntlet doesn't soft-lock the gate.
- [ ] No enemy double-counts on the gate (kill count == room enemy count).

## Note
- Leak removed from assets, but `GauntletConfig` + `Constants` still reference
  `type = "Leak"` (spawns via primitive rig). Verify Leak rooms (PuraBali +
  2 gauntlet rooms) still clear normally, OR action the full-removal decision
  in `docs/asset_moderation_audit.md`.
