# Rojo Workflow — Code Sync TANPA Nuke Workspace

> **Insiden 22 Mei 2026 ~14:07:** connect Rojo di `pusaka-pasar-gaib-dev.rbxl`
> nge-**OVERWRITE seluruh Workspace** jadi kosong (Pasar Malam: Nyi Sumiyem,
> Mbah Karto, Mbok Inem, terrain, lighting, decoration HILANG dari session).
> Root cause: `default.project.json` dulu define `Workspace` di `tree` → Rojo
> anggap authoritative → ganti isi Workspace sesuai project (cuma Baseplate).
> **Fix:** `Workspace` udah DIHAPUS dari `default.project.json` (commit ini).
> Rojo sekarang **gak nyentuh Workspace sama sekali**.

---

## A. Apa yang Rojo manage

| Rojo manage (dari repo) | Rojo TIDAK manage |
|---|---|
| `src/server` → `ServerScriptService.Server` | **Workspace** (terrain, NPC, decoration, spawn) |
| `src/shared` → `ReplicatedStorage.Shared` | Cloud DataStore data (`PlayerData_v2`) |
| `src/client` → `StarterPlayer.StarterPlayerScripts.Client` | Asset/mesh upload (Studio Save to Roblox) |
| `Lighting` / `SoundService` (cuma set properties, `$ignoreUnknownInstances`) | Workspace 3D content apa pun |

**Code = source of truth di repo (GitHub). World 3D = source of truth di `.rbxl` / cloud experience.**

## B. Workflow aman (tiap session)

1. Terminal di folder repo: `rojo serve` (default port 34872).
2. Buka Studio → buka `.rbxl` ATAU cloud experience yang **punya Workspace content**.
3. Plugins → Rojo → **Connect**.
4. Rojo sync `ServerScriptService.Server` / `ReplicatedStorage.Shared` /
   `StarterPlayer...Client` dari repo. **Workspace utuh** (di-protect config).
5. F5 test. Kalau OK → **File → Publish to Roblox** (upload code + Workspace ke cloud).

## C. Workspace boundary — kenapa Pasar Malam gak di repo

- World building (NPC, terrain, decoration, lighting manual) dibuat **di Studio**, bukan kode.
- `.rbxl` / cloud experience = sumber kebenaran Workspace.
- Lua di repo = sumber kebenaran logic.
- Dua sumber, di-bridge via `rojo serve`. Config sengaja **gak** map Workspace → gak ada konflik.

## D. Recovery kalau Workspace ke-nuke (worst case)

1. **JANGAN Ctrl+S.**
2. Klik **Disconnect** di panel Rojo (tombol merah).
3. **File → Close → Don't Save.**
4. Reopen file → Workspace balik dari disk.
5. Kalau disk udah ke-overwrite Save: cek `C:\Users\<username>\Documents\Roblox\AutoSaves\`
   untuk autosave, atau buka snapshot cloud experience versi lain.

## E. Publish workflow (deploy ke production)

| Langkah | Aksi |
|---|---|
| Code change | commit + push ke GitHub (sumber kebenaran code) |
| Test lokal | `rojo serve` + Studio F5 |
| Publish | File → Publish to Roblox → universe `10199602349`, place `78701232149386` |
| Hasil cloud | code (via Rojo dari repo) **+** Workspace (manual building) merged |

## F. Common pitfall

- ❌ Connect Rojo di file ber-Workspace-content **tanpa config protect** = nuke (22 Mei 14:07).
- ❌ Save `.rbxl` **setelah** nuke = permanent loss.
- ✅ Sebelum connect, pastiin `default.project.json` **gak punya** node `Workspace`
  (atau punya `$ignoreUnknownInstances: true` kalau memang perlu map sub-folder Workspace).
- ℹ️ `Lighting`/`SoundService` masih di-manage (cuma properties) + `$ignoreUnknownInstances`
  biar children manual gak ke-hapus. Lighting juga di-re-apply runtime oleh `AtmosphereSetup`.

---

*Config saat ini (`default.project.json`): tree = ReplicatedStorage.Shared,
ServerScriptService.Server, StarterPlayer...Client, Lighting, SoundService.
TANPA Workspace. Aman buat connect.*
