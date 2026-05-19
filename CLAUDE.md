# PUSAKA: Pasar Gaib — Project Context for Claude Code

> **READ THIS FILE AT THE START OF EVERY SESSION** before doing any work.

---

## Game Overview

**PUSAKA: Pasar Gaib** = Roblox treasure-hunting live-service bertema mistis Indonesia.

- **Spawn:** Pasar Gaib (hub konsentris dengan leaderboard 3D, NPC vendor, dan kios sewa player).
- **Core loop:** spawn → pilih portal (12 map mistis) → eksplor & fight makhluk gaib ringan → koleksi Pusaka → balik ke hub → flex aura + trade di kios.
- **Item tier:** 3 tingkat — 10 Legendary (soul-bound 30 hari), Mid-tier Rare/Epic (lock 7–30 hari), Common consumables (bebas trade).
- **Currency:** Koin Gaib (in-game, dari gameplay) + Robux (premium, sewa kios & Game Pass) + barter item-vs-item.
- **Genre:** simulator + collect + co-op multiplayer.

Single source of truth game design: Notion page **PUSAKA: Pasar Gaib — Game Design Doc** (`a3365cab-d4a5-43b4-8046-1ab549fe9f4f`). Fetch via Notion MCP kalau butuh detail mekanik/balance/item.

---

## Tech Stack

| Layer | Tool | Lock di |
|---|---|---|
| Engine | Roblox Studio (Windows/Mac, no Linux) | — |
| Language | Luau (strict mode) | — |
| Sync VS Code ↔ Studio | **Rojo 7.4.4** | `aftman.toml` |
| Linter | **Selene 0.27.1** | `aftman.toml` |
| Formatter | **StyLua 0.20.0** | `aftman.toml` |
| Toolchain manager | Aftman 0.3.0 (global) | — |
| Version control | Git + GitHub (private repo) | — |

Restore toolchain di mesin baru: `aftman install` di root repo.

---

## Project Structure

```
pusaka-pasar-gaib/
├── CLAUDE.md                    # File ini — briefing primary coder
├── CHANGELOG-MANUAL.md          # WAJIB: log kerja manual Alexa (backup coder)
├── README.md                    # Public-facing
├── aftman.toml                  # Tool versions locked
├── default.project.json         # Rojo project mapping
├── .gitignore
├── pusaka-pasar-gaib-dev.rbxl   # Place file dev (DI-TRACK, bukan ignored)
├── src/
│   ├── client/                  # LocalScript: UI, input, camera, SFX, partikel
│   ├── server/                  # Script: game logic, DataStore, MarketplaceService, RemoteEvent handler
│   └── shared/                  # ModuleScript: data shared client+server (item defs, balance constants, types)
└── docs/                        # (dibuat saat butuh) architecture.md, item-database.md, balance-tuning.md, datastore-schema.md
```

Rojo mapping (lihat `default.project.json`):
- `src/shared/` → `ReplicatedStorage.Shared`
- `src/server/` → `ServerScriptService.Server`
- `src/client/` → `StarterPlayer.StarterPlayerScripts.Client`

---

## Luau Coding Conventions

### Strict typing (WAJIB)

Setiap file Luau diawali:
```lua
--!strict
```

Type-hint semua variable & function signature:
```lua
local playerHealth: number = 100

local function takeDamage(player: Player, amount: number): boolean
    -- ...
    return true
end
```

### Naming

| Element | Convention | Contoh |
|---|---|---|
| ModuleScript / file | **PascalCase** | `InventoryService.lua`, `PusakaCatalog.lua` |
| LocalScript / Script | PascalCase (sama kayak module) | `MainClient.client.lua` |
| Function | **camelCase** | `addItem()`, `getInventory()`, `equipPusaka()` |
| Variable lokal | camelCase | `currentSlot`, `pickupCount` |
| Constant | **SCREAMING_SNAKE_CASE** | `MAX_INVENTORY_SLOTS`, `LEGENDARY_DROP_RATE`, `DATASTORE_RETRY_LIMIT` |
| Type alias | PascalCase | `type PlayerInventory = {...}` |
| Private member (modul) | `_camelCase` prefix underscore | `_internalState` |

### Patterns

- **Module return = tabel** dengan function fields. Hindari side-effect saat require.
  ```lua
  --!strict
  local InventoryService = {}

  function InventoryService.addItem(player: Player, itemId: string, quantity: number): boolean
      -- ...
  end

  return InventoryService
  ```
- **Konstanta di puncak file**, di-export kalau perlu dipakai modul lain.
- **Signals & events**: pakai `BindableEvent` (intra-script) atau `RemoteEvent`/`RemoteFunction` (client↔server). Hindari polling.
- **DataStore**:
  - Cache di memory, batch write tiap 30 detik (bukan tiap mutate). Rate limit Roblox: 60 read/menit per key per server.
  - Retry 3x dengan exponential backoff kalau request fail.
  - Backup pakai OrderedDataStore untuk versioning manual.
- **Cross-server**: pakai `MessagingService`, jangan HTTP eksternal kecuali wajib.
- **RNG**: pakai `Random.new()` (seeded) untuk pity counter & drop roll, BUKAN `math.random` (shared state).

### Anti-pattern (JANGAN)

- ❌ Hard-code path Instance (`workspace.Spawn.Pad`). Pakai `ReplicatedStorage`/`ServerStorage` + `WaitForChild`.
- ❌ Server trust client input. Validate semua RemoteEvent payload di server.
- ❌ `while true do wait() end` untuk polling — pakai event-driven.
- ❌ Loop ke `Players:GetPlayers()` tanpa handle player leave race.
- ❌ Simpan API key / Robux developer secret di kode. Pakai Studio Settings + jangan commit.

---

## Workflow: Claude Agent (Primary) ↔ Alexa (Backup)

**Aturan inti:** gw (Claude Agent via CLI) = primary coder dengan akses repo langsung. Alexa (Notion AI) = backup pas usage 5-jam limit Claude Pro habis — output via snippet chat yang user copy-paste manual.

### Setiap session baru gw WAJIB lakukan (urutan):

1. **`Read CLAUDE.md`** (file ini).
2. **`Read CHANGELOG-MANUAL.md`** — cek apa yang Alexa kerjain pas gw offline.
3. **`git log --oneline -15`** — audit commit history. Prefix `manual:` = Alexa, prefix lain (`feat:`/`fix:`/`refactor:`/`docs:`/`chore:`) = gw.
4. **Kalau ada section "Known Issues / TODO Claude Agent" di entry CHANGELOG terbaru**, mulai dari item pertama di situ.

### Commit message prefix (STRICT — buat audit)

| Prefix | Siapa | Untuk |
|---|---|---|
| `feat:` | Claude Agent | Fitur baru |
| `fix:` | Claude Agent | Bug fix |
| `refactor:` | Claude Agent | Restructure, no behavior change |
| `docs:` | Claude Agent | Update doc / changelog / CLAUDE.md |
| `chore:` | Claude Agent | Tooling, config, deps, aftman, gitignore |
| `manual:` | **Alexa only** | Snippet via Notion AI yang user paste manual |

Pesan commit harus deskriptif: `feat: implement InventoryService with 100-slot cap + DataStore batch write`, BUKAN `update` / `wip` / `fix bug`.

### Pas usage gw mendekati limit (~80%)

Commit & push semua kerja jadi DULU sebelum tutup session. Jangan tinggalin file mid-edit — Alexa gak bisa lanjut state in-memory gw.

```bash
git add .
git commit -m "feat: <ringkasan fitur yang baru selesai>"
git push
```

### Pas Alexa ambil alih (gw offline)

User minta snippet ke Alexa di chat Notion → paste ke VS Code → **Ctrl+S** → Rojo auto-sync ke Studio → F5 test. **WAJIB tambah entry ke `CHANGELOG-MANUAL.md`** sebelum tutup session Alexa, format ada di template file itu. Commit prefix `manual:`.

---

## Game-Specific Build Order (dari GDD Phase 3)

MVP Vertical Slice (Minggu 1–3):

1. Terrain Pasar Gaib (Inner/Middle/Outer Ring layout) + 4 NPC vendor permanen (Mbok Inem, Pak Tukijo, Nyai Sumi, Bandar Robux) dengan ProximityPrompt.
2. Leaderboard 3D placeholder di tengah spawn pad.
3. 1 portal → 1 map (Kuburan Mbah Buyut) + 1 enemy (pocong simple AI patrol).
4. Inventory minimal 10 slot + 3 item starter (Garam Kasar, Kemenyan Madu, Daun Sirih).
5. Publish sebagai Private experience (Phase 4) supaya DataStore jalan — DataStore TIDAK persistent di Studio test mode.

Setelah MVP jalan: tambah crafting altar, kios sewa, trade tax 5%, pity counter, event Pasar Setan Jumat Kliwon.

---

## What NOT To Do

- ❌ Edit file langsung di Roblox Studio. **SEMUA coding di VS Code**, Studio cuma buat F5 test Play. Edit di Studio = gak ke-sync balik ke Git.
- ❌ Push ke `main` tanpa minimal sekali F5 test di Studio.
- ❌ Bikin file tanpa header `--!strict`.
- ❌ Asumsi DataStore jalan di Studio test — wajib publish ke cloud (Private experience) untuk verifikasi save.
- ❌ Install paket / plugin Studio dari Toolbox sembarangan — malware risk. Pakai Rojo / Wally / ProToolbox / Moon Animator official only.
- ❌ Refactor sistem yang user gak minta. Scope per task.
- ❌ Trivialisasi ritual nyata atau klaim teologis dalam content. Folk-fantasy OK, doctrinal claim NO. Kalau ragu soal representasi mistis Jawa/Bali, **flag ke user**, jangan asumsi.
- ❌ Hard-code Robux price di kode — taruh di `src/shared/Constants.lua` supaya tweak balance gampang.

---

## Reference: Where Things Live

- **Game design doc:** Notion page `PUSAKA: Pasar Gaib — Game Design Doc` (ID `a3365cab-d4a5-43b4-8046-1ab549fe9f4f`) — narasi, mekanik, balance, item, lore.
- **Aktivitas Alexa:** `CHANGELOG-MANUAL.md` (root repo).
- **Item database (production):** `docs/item-database.md` (belum dibuat, generated saat Phase 3).
- **Balance tuning:** `docs/balance-tuning.md` (drop rate, pity, floor price — belum dibuat).
- **DataStore schema:** `docs/datastore-schema.md` (belum dibuat, dibuat saat implement save).
- **GitHub:** `https://github.com/Revii28/pusaka-pasar-gaib` (private).

---

## User Preferences

- **Bahasa komunikasi:** Bahasa Indonesia informal (gw/lo) + technical terms English OK.
- **Verbosity:** ringkas-padat. Hindari preamble panjang. Lo udah baca CLAUDE.md = lo paham context.
- **Konfirmasi sebelum action:**
  - Edit file lokal & run tests = langsung jalan.
  - `git push`, `rojo build` final, publish ke Roblox cloud, destructive action (delete file/folder, force push) = konfirmasi dulu.
- **Testing approach:** manual playtest di Studio F5 (TestEZ unit testing baru di Phase 7+).
- **Riset budaya:** representasi mistis Jawa/Bali = ada toleransi folk-fantasy, tapi sensitif. Flag ke user kalau ragu.

---

*Maintained by: Revi Rifaldi. Auto-loaded oleh Claude Code tiap session.*
