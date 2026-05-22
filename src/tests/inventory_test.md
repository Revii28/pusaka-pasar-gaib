# Smoke Test — Inventory + DataStore

**Pre-req:** Studio → Game Settings → Security → **Enable Studio Access to API
Services** (DataStore won't work otherwise). Run as **server** in the command
bar. Helpers:
```lua
local SS = game:GetService("ServerScriptService").Server
local Inv = require(SS.inventory.InventoryService)
local plr = game.Players:GetPlayers()[1]
```

## Test 1 — fresh player starter grant
1. F5 (Play Solo).
- [ ] Output: `[PlayerDataService] Loaded data for <Name>`, three
      `[InventoryController] inventory updated ...` lines ending `hotbar=3 bag=0`.
- [ ] `Inv.getInventory(plr).hotbar` → MinyakWangiKembang×3, JimatPenangkalSetan×1,
      AirSucu×2 (3 slots filled).

## Test 2 — pickup flow
1. Insert a Part in Workspace. Add tag `Pickup` (use a tagging plugin or
   `game:GetService("CollectionService"):AddTag(part, "Pickup")`).
2. Set attributes: `ItemId` = `"KerisPusaka"`, `Qty` = `1`.
3. Walk the character into the part.
- [ ] Output: `[PickupService] <Name> picked up KerisPusaka x1`; part destroyed;
      `getInventory` now contains KerisPusaka.

## Test 3 — stack limit
1. `Inv.addItem(plr, "AirSucu", 99)`
- [ ] An AirSucu slot caps at 99 (existing starter stack tops up first).
2. `Inv.addItem(plr, "AirSucu", 1)`
- [ ] Overflow goes to a new slot with qty 1.

## Test 4 — use callback (heal)
1. `plr.Character.Humanoid.Health = 50`
2. Find the AirSucu slot, then `Inv.useItem(plr, "hotbar", <slot>)`
- [ ] Humanoid.Health → 75 (+25); AirSucu qty decremented (slot cleared at 0).

## Test 5 — persistence
1. `Inv.addItem(plr, "KerisPusaka", 1)`; wait for an autosave (≤60s) or Stop
   (BindToClose flushes).
2. Stop, then Play again.
- [ ] `[PlayerDataService] Loaded data` and KerisPusaka is still present.
- [ ] Starter items are NOT re-granted (grantedStarters flag persisted) — hotbar
      count unchanged vs before stopping.

## Notes
- Inventory snapshot is sent whole on every change (optimize later).
- DataStore stores int slot keys as strings; `normalizeSlots` restores them on load.
