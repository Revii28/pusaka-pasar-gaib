# CHANGELOG-MANUAL.md

Log perubahan manual yang dibuat via **Alexa** (Notion AI) saat Claude Agent kena 5-jam limit Claude Pro. Setiap session baru, Claude Agent baca file ini DULU sebelum kerja — supaya gak duplicate effort & langsung paham state terakhir.

**Format aturan:**
- Entry baru di **paling atas** (tanggal descending — newest first).
- Tanggal ISO `YYYY-MM-DD`. Kalau lebih dari satu sesi di hari yang sama, tambah jam: `2026-05-19 14:30`.
- Tiga sub-section wajib per entry: **Selesai**, **Known Issues / TODO Claude Agent**, **Context untuk session berikutnya**.
- Commit yang menyertai entry pakai prefix `manual:` (BEDA dari `feat:`/`fix:`/`refactor:`/`docs:`/`chore:` yang dipakai Claude Agent).
- Entry bootstrap pertama di bawah ditulis Claude Agent sebagai anchor format — entry berikutnya semua dari Alexa.

---

## 2026-05-19 (Bootstrap — Claude Agent / chore)

### Selesai

- `aftman.toml` → NEW. Lock toolchain: `rojo-rbx/rojo@7.4.4`, `Kampfkarren/selene@0.27.1`, `JohnnyMorganz/StyLua@0.20.0`.
- `aftman install` → 3 tools installed under `.aftman/` (gitignored).
- `.gitignore` → NEW. Ignore `.aftman/`, `.vscode/`, `*.rbxl.lock`, `aftman.exe`, `.gdd-tmp.md`, OS clutter. **Track `*.rbxl`** (place file dev).
- `rojo init` → generated `default.project.json` + `src/{client,server,shared}/` + default `README.md`.
- `default.project.json` → standard Rojo place mapping (Workspace.Baseplate + Lighting + SoundService defaults).
- `CLAUDE.md` → NEW. Briefing lengkap untuk Claude Code session: tech stack (Aftman/Rojo/Selene/StyLua), Luau strict typing convention, naming (PascalCase modules / camelCase functions / SCREAMING_SNAKE constants), workflow handoff Claude Agent ↔ Alexa, anti-pattern list, build order MVP Phase 3, reference ke GDD Notion (ID `a3365cab-d4a5-43b4-8046-1ab549fe9f4f`).
- `CHANGELOG-MANUAL.md` → NEW (file ini). Template + entry pertama (= bootstrap setup).
- Place file dev `pusaka-pasar-gaib-dev.rbxl` di-track di Git.

### Known Issues / TODO Claude Agent

- **Phase 2 belum jalan** — Hello World sync test (VS Code → Rojo → Studio) belum diverifikasi end-to-end. Next session: `rojo serve` + Studio connect plugin, paste sample `print()` di `src/server/init.server.lua`, F5 di Studio, cek Output.
- **`selene.toml` & `stylua.toml` belum dibuat.** Selene & StyLua udah ke-install via Aftman tapi belum di-config. Default config probably OK untuk start, tapi config explicit perlu dibuat sebelum tulis Luau script pertama (supaya `--!strict` + Roblox std lib detected dengan benar).
- **`docs/` folder belum ada.** Mulai populate saat Phase 3: `architecture.md`, `item-database.md`, `balance-tuning.md`, `datastore-schema.md`.
- **Verifikasi 2FA Roblox** — TODO user-side (bukan code), tapi WAJIB sebelum publish ke cloud Phase 4.
- **Reserve social handle `@pusakapasargaib`** (TikTok + Instagram + X) — TODO user-side.

### Context untuk session berikutnya

- Repo state: skeleton Rojo siap, toolchain ter-pin via Aftman, dokumentasi workflow handoff di place.
- Belum nulis baris Luau satu pun. Phase 1 (setup) = SELESAI. Next = Phase 2 (Hello World sync test) → Phase 3 (MVP vertical slice: Pasar Gaib hub + 1 portal + 1 map + inventory + 3 item).
- GDD Notion masih single source of truth untuk semua keputusan game design. Fetch via MCP kalau butuh detail (item spec, drop rate, balance numbers).
- Branch `main`, commit pertama: `chore: initial project skeleton + Rojo + Aftman setup`.

---
