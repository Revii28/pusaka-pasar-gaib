-- Enemy mesh asset IDs (rbxassetid://). Consumed via InsertService:LoadAsset
-- in EnemyRigs.tryCloneMesh (server-side, cached). Missing entry => the enemy
-- module falls back to its primitive buildRig.
--
-- Open Cloud upload path is PAUSED (account moderation). IDs are wired
-- manually after the user does Studio "Save to Roblox" per setan.
--   * Leak REMOVED — gore content confirmed moderation culprit; Roblox will
--     delete the asset. Leak.lua now always uses its primitive rig.
--   * Tuyul / SundelBolong / WeweGombel / BuddhaWraith flagged in
--     docs/asset_moderation_audit.md (lean-SKIP). Their current IDs still
--     point to the SAFE primitive uploads from the first batch.
return {
	Pocong = "rbxassetid://107709794090664",
	Kuntilanak = "rbxassetid://111406860449904",
	Genderuwo = "rbxassetid://139769722361283",
	Tuyul = "rbxassetid://95757886711287",
	SundelBolong = "rbxassetid://125519017691944",
	Banaspati = "rbxassetid://104731812028934",
	WeweGombel = "rbxassetid://111119714324258",
	ButoIjo = "rbxassetid://125648166362876",
	SetanPasar = "rbxassetid://117928888067153",
	NagaKomodo = "rbxassetid://105785756477318",
	BuddhaWraith = "rbxassetid://111346628317618",
}
