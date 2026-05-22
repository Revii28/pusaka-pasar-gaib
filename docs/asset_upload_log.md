# Open Cloud Asset Upload Log

**Date:** 2026-05-22 · **Method:** Roblox Open Cloud `POST /v1/assets`
(`scripts/upload_enemies.py`, `model/fbx`, async operation polling).
**Account:** MR_RedLabel (userId 9270421581) — re-activated after moderation
appeal. **Wired in:** commit `7ae2b87` (`feat(enemies): wire 7 PROCEED asset IDs`).

Gate: Pocong uploaded first as a moderation test (no 403/401) before the rest.

## ✅ PROCEED — uploaded (7)

| Setan | Asset ID | FBX size | rbxassetid |
|-------|----------|----------|------------|
| Pocong | 76777567365120 | ~16.6 MB | `rbxassetid://76777567365120` |
| Kuntilanak | 109481388805656 | ~6.2 MB | `rbxassetid://109481388805656` |
| Genderuwo | 117007032460463 | ~29.5 MB | `rbxassetid://117007032460463` |
| Banaspati | 103503523067471 | ~0.9 MB | `rbxassetid://103503523067471` |
| ButoIjo | 135788034749287 | ~7.9 MB | `rbxassetid://135788034749287` |
| SetanPasar | 87806775240990 | ~1.5 MB | `rbxassetid://87806775240990` |
| NagaKomodo | 129095506826623 | ~2.5 MB | `rbxassetid://129095506826623` |

> Assets are **Model** type (FBX → Model). Consumed at runtime via
> `InsertService:LoadAsset` in `EnemyRigs.tryCloneMesh` (server-side, cached).
> If a setan still spawns primitive in-game, the Model may need a moment to
> finish server-side processing, or the rig's `RigVariant` attribute will read
> `"Primitive"` (LoadAsset miss → fallback).

## ⛔ SKIP — not uploaded (4) → primitive fallback rig

| Setan | Reason (docs/asset_moderation_audit.md) |
|-------|------------------------------------------|
| Tuyul | child-figure + scary = child-safety filter risk |
| SundelBolong | red dress reads as blood-stained |
| WeweGombel | potential exposed-breast nudity |
| BuddhaWraith | sacred religious figure as hostile enemy |

## 🔴 PERMANENT SKIP

| Setan | Reason |
|-------|--------|
| Leak | Graphic gore (floating skull + entrails) — confirmed moderation culprit. FBX removed from repo, asset deleted. |

## Re-upload instructions (if an asset gets deleted from Roblox)

1. Ensure a valid Open Cloud key (Assets read+write, 30–60d) is in `.env`
   (`ROBLOX_API_KEY=`). `.env` is gitignored — never commit it.
2. Single: `.venv\Scripts\python scripts\upload_enemies.py --only <Name>`
   All 7: `.venv\Scripts\python scripts\upload_enemies.py`
3. Copy the printed asset IDs into `src/shared/EnemyMeshIds.lua` (PROCEED block).
4. `stylua src/ && selene src/`, commit, push.
5. `403 "User is moderated"` → STOP (account flagged); `401` → key expired/invalid.
