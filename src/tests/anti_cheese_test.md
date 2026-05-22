# Smoke Test — ParkourGuard (anti-cheese)

Manual F5 procedure. Watch Output for `[ParkourGuard] ...` lines. Console =
Studio command bar (server context: `View > Command Bar`, run as server).
Replace `<Name>` with your player name.

Config (tune in `ParkourGuard.lua`): sample 1.0s, teleport >75 stud/sample,
speed >100 stud/s (2 samples), fly >50 stud sustained 2s, bounds Y<-500 or
|X|/|Z|>5000, escalation rubberband → spawn-TP → kick at 3.

## Test 1 — idle (no false positive)
1. F5, stand still ~10s.
- [ ] **Expect:** NO violation log.

## Test 2 — normal play (no false positive)
1. Walk, jump, sprint around the hub ~15s.
- [ ] **Expect:** NO violation log (normal jump ≈7 studs ≪ 50 fly threshold).

## Test 3 — teleport → violation 1 (rubberband)
1. Console: `workspace["<Name>"].HumanoidRootPart.CFrame = CFrame.new(0, 1000, 0)`
- [ ] **Expect:** `violation 1: teleport` (or `bounds`/`fly` if it lands oddly),
      character rubberbanded back to a recent safe position.

## Test 4 — repeat → violation 2 then 3 (kick)
1. Repeat the Test 3 console teleport twice more (wait ~1s between, for samples).
- [ ] **Expect:** `violation 2: ...` (teleport to SpawnLocation), then
      `violation 3: ..., KICKING` and the player is kicked.

## Test 5 — portal teleport (whitelisted, NO violation)
1. Use a hub portal ProximityPrompt ("Masuk") to travel to a map.
- [ ] **Expect:** NO violation — `PortalService` calls `notifyLegitTeleport`
      (2s window). Same for returning to hub.

## Test 6 — out of bounds
1. Console: `workspace["<Name>"].HumanoidRootPart.CFrame = CFrame.new(0, -800, 0)`
- [ ] **Expect:** `violation ...: bounds`, teleport toward spawn.

## Test 7 — fly
1. Console (server), run a loop nudging Y up without grounding:
   ```lua
   local hrp = workspace["<Name>"].HumanoidRootPart
   for i = 1, 40 do hrp.CFrame = hrp.CFrame + Vector3.new(0, 5, 0); task.wait(0.1) end
   ```
- [ ] **Expect:** after ~2s sustained >50 studs above ground, `violation ...: fly`.

## Notes
- Each violation escalates the SAME counter; run `ParkourGuard.resetViolations(player)`
  to reset between tests, or rejoin.
- Spawn has a 2s grace window (legitTeleportUntil set on start).
