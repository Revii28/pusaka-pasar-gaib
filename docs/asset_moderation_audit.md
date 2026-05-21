# Asset Moderation Re-Audit — 12 Setan

**Date:** 2026-05-22
**Trigger:** Roblox account (MR_RedLabel / 9270421581) hit account-level
moderation lock during Open Cloud PATCH batch. Root cause confirmed: **Leak
(Krasue) texture** — floating skull + exposed intestines/entrails (graphic
gore). Cross-validated: both Roblox content moderation AND an independent image
filter rejected the Leak detail screenshot.

**Method:** vision analysis of `assets/enemies/<Name>_preview.png` (rendered
normalized model). Classified vs Roblox Community Standards. Per project policy,
**ambiguity → lean SAFE** (classify higher risk, prefer SKIP over PROCEED, and
do NOT auto-modify FBX via risky texture surgery).

> **Important nuance:** the account lock is *account-level*, not per-asset. Only
> Leak is *confirmed* flagged. The other "flag" classifications below are
> *precautionary* (pre-upload risk) so the user avoids re-triggering moderation
> when manually Saving-to-Roblox in Studio.

---

## Classification table

| Setan | Visual analysis | Risk | Action |
|-------|-----------------|------|--------|
| **Leak** | Floating skull + dangling intestines (Krasue). Graphic gore. | 🔴 CONFIRMED | **DELETE** (done: FBX+preview removed, EnemyMeshIds entry removed) |
| **Tuyul** | Small bald **child-figure**, sunken dark eyes, emaciated, crawling, minimal tattered clothing. | 🔴 HIGH | **SKIP** — child-figure + distressing/scary + minimal clothing risks Roblox child-safety (CSAM) filters. Age-up requires manual sculpt → defer, do not auto-modify. |
| **SundelBolong** | Woman, long black hair, **red dress with dark mottled staining** that can read as blood. Folklore hollow-back not visible front-on. | 🟠 MED-HIGH | **SKIP / review** — bloodied-dress appearance. Mitigation: recolor dress to clean red (see below) OR pick alternative. |
| **WeweGombel** | Hunched dark hag figure; lighter chest region. Folklore depicts a topless old woman. | 🟠 MED | **SKIP / review** — potential exposed-breast nudity. Needs texture inspection; lean SKIP. |
| **BuddhaWraith** | Ornate weathered religious statue (Buddha / Shakyamuni). | 🟡 MED | **Review** — sacred religious figure as a hostile enemy is culturally/religiously sensitive (per CLAUDE.md: doctrinal/sacred representation = flag to user). Recommend a non-sacred "stone wraith" alternative. |
| **Pocong** | Shrouded corpse in white burial cloth (kain kafan), grimy, face visible. | 🟡 MED | PROCEED (caution) — folklore shroud figure, no gore/nudity. |
| **Kuntilanak** | White dress, long black hair over face, arms out. | 🟡 MED | PROCEED (caution) — standard horror ghost, fully clothed. |
| **Genderuwo** | Black hairy ape-man (fantasy), no explicit anatomy. | 🟢 LOW | PROCEED — fantasy ape monster. |
| **Banaspati** | Abstract yellow/orange fire burst (procedural orange-emission fallback). | 🟢 SAFE | PROCEED — solid color, no figure. |
| **ButoIjo** | Green muscular ogre/giant with fangs (fantasy), no explicit anatomy. | 🟢 LOW | PROCEED — fantasy ogre. |
| **SetanPasar** | Dark hooded/cloaked wraith (black death-knight). | 🟢 LOW | PROCEED — robed figure, no gore/nudity. |
| **NagaKomodo** | Gray dragon/komodo creature (fantasy). | 🟢 LOW | PROCEED — fantasy dragon. |

---

## Summary

**✅ PROCEED — safe for Studio "Save to Roblox" (7):**
Pocong, Kuntilanak, Genderuwo, Banaspati, ButoIjo, SetanPasar, NagaKomodo

**⛔ SKIP / review before any upload (5):**
- **Leak** — deleted (confirmed gore).
- **Tuyul** — child-safety filter risk (HIGH). Do not upload as-is.
- **SundelBolong** — bloodied-dress appearance (MED-HIGH).
- **WeweGombel** — potential nudity (MED).
- **BuddhaWraith** — religious-figure sensitivity (MED).

For the 4 SKIP setan, `EnemyMeshIds.lua` keeps their **existing primitive**
asset IDs (geometric shapes from the first upload batch — NOT moderation risk),
so the game still spawns them via the primitive `buildRig` path. No gameplay
breakage.

---

## Mitigation procedures (NOT auto-executed — lean SAFE, user decides)

These are documented for the user; per hard-rule they were **not** force-applied
(texture surgery is high-risk autonomous and can corrupt assets).

- **SundelBolong** — recolor dress: in Blender, load `SundelBolong.fbx`, on the
  body material's Base Color image run a hue/desaturate or paint pass to remove
  the dark red "blood" mottling (flat clean red), re-pack, re-export.
- **WeweGombel** — verify texture: open
  `sketchfab-downloads/WeweGombel/*.jpeg` base color; if bare breasts present,
  paint a cloth/garment over the chest region or pick an alternative model.
- **Tuyul** — age-up is a manual sculpt (proportions + face). Recommend sourcing
  a non-child "imp/goblin" alternative instead. Do not attempt auto-mitigation.
- **BuddhaWraith** — swap concept to a generic ornate "stone temple guardian"
  wraith (non-sacred). Search an alternative CC-BY asset.

## Leak removal (executed)
- `assets/enemies/Leak.fbx` + `Leak_preview.png` — removed from repo.
- `src/shared/EnemyMeshIds.lua` — `Leak` entry removed.
- **Retained** (deliberately, to avoid build breakage): `enemies/Leak.lua`
  (now always primitive rig — geometric, no gore), and `Leak` spawn references
  in `Constants.ENEMY_SPAWN_MAP` (PuraBali) + `GauntletConfig` (2 rooms),
  `GhostSpawner` (hub cosmetic vendor), `Items.topeng_leak` (mask item).
  > **User decision needed:** full Leak removal would require dropping/replacing
  > those spawns (PuraBali + 2 gauntlet rooms) with another Rare-tier enemy.
  > Left intact for now (lean SAFE — no gameplay invention).
