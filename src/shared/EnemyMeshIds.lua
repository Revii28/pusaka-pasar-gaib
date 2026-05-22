-- Enemy mesh asset IDs (rbxassetid://). Consumed via InsertService:LoadAsset
-- in EnemyRigs.tryCloneMesh (server-side, cached). A missing/absent entry =>
-- the enemy module falls back to its primitive buildRig.
--
-- Wired manually after Open Cloud upload (Phase 8, 2026-05-22) via
-- scripts/upload_enemies.py. Account re-activated; 7 PROCEED uploaded fresh.
-- Do NOT regenerate via upload_enemy_assets.py (would clobber this curation).
--
-- 4 SKIP + Leak intentionally have NO mesh entry (moderation audit:
-- docs/asset_moderation_audit.md) → they spawn via their primitive rig.
return {
	-- PROCEED — realistic Sketchfab meshes (Open Cloud, 2026-05-22):
	Pocong = "rbxassetid://76777567365120",
	Kuntilanak = "rbxassetid://109481388805656",
	Genderuwo = "rbxassetid://117007032460463",
	Banaspati = "rbxassetid://103503523067471",
	ButoIjo = "rbxassetid://135788034749287",
	SetanPasar = "rbxassetid://87806775240990",
	NagaKomodo = "rbxassetid://129095506826623",

	-- SKIP (no mesh → primitive fallback rig):
	--   Tuyul        — child-safety filter risk
	--   SundelBolong — blood-dress appearance
	--   WeweGombel   — potential nudity
	--   BuddhaWraith — sacred religious figure
	-- Leak — PERMANENT SKIP (gore; FBX removed)
}
