--!strict
--[[
	@module      EnemyRigs
	@description Shared builders untuk enemy rig — minimal Humanoid-driven
	             skeleton (HumanoidRootPart unanchored + Humanoid + visual parts
	             welded via WeldConstraint). Bukan reuse GhostSpawner (yang
	             anchored cosmetic). Tiap enemy module call helper relevant atau
	             build dari scratch dengan helper di sini.

	             Mesh pipeline: enemy visuals are Blender-generated FBX uploaded
	             to Roblox Open Cloud as Model assets (scripts/
	             upload_enemy_assets.py). Asset IDs live di
	             ReplicatedStorage.Shared.EnemyMeshIds. EnemyRigs.tryCloneMesh
	             load via InsertService:LoadAsset (server-side, cached) lalu weld
	             mesh ke Humanoid rig. Tiap enemy module fallback ke primitive
	             buildRig kalau asset gak ke-load.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local EnemyRigs = {}

-- Mesh asset templates loaded once via InsertService:LoadAsset, cloned per
-- spawn. Negative results cached so failed loads don't retry every spawn.
-- Server-side only (LoadAsset). _meshIds lazily required on first lookup.
local _meshTemplateCache: { [string]: Model } = {}
local _meshLoadFailed: { [string]: boolean } = {}
local _meshIds: { [string]: string }? = nil

function EnemyRigs.weld(part0: BasePart, part1: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = part0
	w.Part1 = part1
	w.Parent = part0
end

function EnemyRigs.makePart(props: {
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?,
	shape: Enum.PartType?,
	massless: boolean?,
	parent: Instance,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	if props.shape then
		part.Shape = props.shape
	end
	part.Size = props.size
	part.Color = props.color
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.CanCollide = if props.canCollide == nil then false else props.canCollide
	part.Massless = if props.massless == nil then true else props.massless
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.Parent = props.parent
	return part
end

function EnemyRigs.makeHumanoid(model: Model, displayName: string): Humanoid
	local hum = Instance.new("Humanoid")
	hum.DisplayName = displayName
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	hum.AutoRotate = true
	hum.Parent = model
	return hum
end

function EnemyRigs.makeRootPart(size: Vector3, parent: Instance): Part
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = size
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Massless = false
	hrp.RootPriority = 127
	hrp.TopSurface = Enum.SurfaceType.Smooth
	hrp.BottomSurface = Enum.SurfaceType.Smooth
	hrp.Anchored = false
	hrp.Parent = parent
	return hrp
end

function EnemyRigs.finalize(model: Model, hrp: Part, spawnPos: Vector3): Model
	model.PrimaryPart = hrp
	model:PivotTo(CFrame.new(spawnPos))
	return model
end

function EnemyRigs.attachBossHealthBar(model: Model, displayName: string)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BossHealthBar"
	billboard.Size = UDim2.fromOffset(220, 36)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 250
	billboard.Adornee = hrp
	billboard.Parent = hrp

	local label = Instance.new("TextLabel")
	label.Name = "BossName"
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Position = UDim2.fromOffset(0, 0)
	label.BackgroundTransparency = 1
	label.Text = displayName:upper()
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 220, 110)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Parent = billboard

	local bg = Instance.new("Frame")
	bg.Name = "BarBackground"
	bg.AnchorPoint = Vector2.new(0, 1)
	bg.Position = UDim2.fromScale(0, 1)
	bg.Size = UDim2.new(1, 0, 0, 16)
	bg.BackgroundColor3 = Color3.fromRGB(25, 15, 15)
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "BarFill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local function refresh()
		local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
	end
	refresh()
	hum.HealthChanged:Connect(refresh)
end

local function getMeshIds(): { [string]: string }
	if _meshIds == nil then
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local mod = if shared then shared:FindFirstChild("EnemyMeshIds") else nil
		print(
			`[EnemyRigs] getMeshIds first call: Shared={tostring(shared ~= nil)} EnemyMeshIds={tostring(
				mod ~= nil
			)}`
		)
		if mod and mod:IsA("ModuleScript") then
			local ok, result = pcall(require, mod)
			if not ok then
				warn(`[EnemyRigs] require EnemyMeshIds FAILED: {tostring(result)}`)
			end
			local tbl = (
				if ok and type(result) == "table" then result else {}
			) :: { [string]: string }
			local count = 0
			for _ in pairs(tbl) do
				count += 1
			end
			print(`[EnemyRigs] EnemyMeshIds module loaded: {count} entries`)
			_meshIds = tbl
		else
			warn("[EnemyRigs] Shared.EnemyMeshIds NOT FOUND — all setan will use primitive rig")
			_meshIds = {}
		end
	end
	return _meshIds :: { [string]: string }
end

-- Load (once) the Open Cloud Model asset for an enemy and cache the returned
-- container as a clone template. Server-only. Returns nil on miss/failure so
-- callers fall back to their primitive buildRig.
function EnemyRigs.loadMeshTemplate(enemyName: string): Model?
	local cached = _meshTemplateCache[enemyName]
	if cached then
		print(`[EnemyRigs] loadMeshTemplate({enemyName}): cache HIT`)
		return cached
	end
	if _meshLoadFailed[enemyName] then
		-- previously-failed (silent on repeat to avoid log spam each spawn)
		return nil
	end
	local ref = getMeshIds()[enemyName]
	if not ref then
		warn(`[EnemyRigs] {enemyName}: no entry in EnemyMeshIds -> primitive fallback`)
		_meshLoadFailed[enemyName] = true
		return nil
	end
	local digits = string.match(ref, "%d+")
	local assetId = if digits then tonumber(digits) else nil
	if not assetId then
		warn(`[EnemyRigs] {enemyName}: cannot parse assetId from '{ref}' -> primitive fallback`)
		_meshLoadFailed[enemyName] = true
		return nil
	end
	print(`[EnemyRigs] {enemyName}: InsertService:LoadAsset({assetId}) starting...`)
	local ok, loaded = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or typeof(loaded) ~= "Instance" then
		warn(
			`[EnemyRigs] LoadAsset FAILED for {enemyName} (rbxassetid://{assetId}): {tostring(
				loaded
			)}`
		)
		_meshLoadFailed[enemyName] = true
		return nil
	end
	local container = loaded :: Model
	-- Summarize structure so we can see whether MeshParts are actually inside.
	local descCount, basePartCount, meshPartCount = 0, 0, 0
	for _, d in ipairs(container:GetDescendants()) do
		descCount += 1
		if d:IsA("BasePart") then
			basePartCount += 1
		end
		if d:IsA("MeshPart") then
			meshPartCount += 1
		end
	end
	print(
		`[EnemyRigs] {enemyName}: LoadAsset OK root={(loaded :: Instance).ClassName} descendants={descCount} basePart={basePartCount} meshPart={meshPartCount}`
	)
	_meshTemplateCache[enemyName] = container
	return container
end

-- Build a Humanoid-driven rig using the uploaded mesh asset as visual. HRP
-- sized from the mesh bounding box; all mesh BaseParts welded to HRP. Returns
-- nil if the asset is unavailable (server-only) so caller -> primitive rig.
function EnemyRigs.tryCloneMesh(enemyName: string, spawnPos: Vector3): Model?
	local template = EnemyRigs.loadMeshTemplate(enemyName)
	if not template then
		print(`[EnemyRigs] tryCloneMesh({enemyName}): template nil -> primitive fallback`)
		return nil
	end
	local container = template:Clone()

	local parts: { BasePart } = {}
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end
	if #parts == 0 then
		-- Diagnostic: list descendant ClassNames so we know what came inside.
		local seen: { [string]: number } = {}
		for _, d in ipairs(container:GetDescendants()) do
			seen[d.ClassName] = (seen[d.ClassName] or 0) + 1
		end
		local summary = ""
		for k, v in pairs(seen) do
			summary ..= `{k}={v} `
		end
		warn(
			`[EnemyRigs] tryCloneMesh({enemyName}): cloned container has 0 BaseParts. Descendants: {summary}-> primitive fallback`
		)
		container:Destroy()
		return nil
	end

	local _, size = container:GetBoundingBox()
	local hrpSize = Vector3.new(math.max(size.X, 2), math.max(size.Y, 4), math.max(size.Z, 2))

	local model = Instance.new("Model")
	model.Name = enemyName .. "_Hostile"
	model:SetAttribute("EnemyType", enemyName)
	model:SetAttribute("RigVariant", "Mesh")

	local hrp = EnemyRigs.makeRootPart(hrpSize, model)
	container:PivotTo(hrp.CFrame)

	for _, part in ipairs(parts) do
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		part.Parent = model
		EnemyRigs.weld(hrp, part)
	end
	container:Destroy()

	EnemyRigs.makeHumanoid(model, enemyName)
	print(`[EnemyRigs] tryCloneMesh({enemyName}) SUCCESS: welded {#parts} parts to rig`)
	return EnemyRigs.finalize(model, hrp, spawnPos)
end

-- ============================================================================
-- Locomotion helpers — per-setan natural movement feel. SAFE & reusable: only
-- set Humanoid HipHeight/JumpPower + a "SpeedMultiplier" attribute (read by
-- EnemyAI when it sets WalkSpeed) + a "MoveStyle" string tag (for future client
-- animation/SFX hooks). Pathing stays Humanoid:MoveTo (FSM-driven) — no custom
-- physics, so the AI never breaks. Advanced behavior (BodyVelocity propulsion,
-- segment wave, screen shake, custom anims) is intentionally deferred.
-- ============================================================================

type LocomotionOpts = {
	speedMult: number?,
	hipHeight: number?,
	noJump: boolean?,
}

local function applyLocomotion(model: Model, style: string, opts: LocomotionOpts)
	model:SetAttribute("MoveStyle", style)
	model:SetAttribute("SpeedMultiplier", opts.speedMult or 1)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if opts.hipHeight ~= nil then
		hum.HipHeight = opts.hipHeight
	end
	if opts.noJump then
		hum.JumpPower = 0
		hum.JumpHeight = 0
	end
end

-- FLOAT/GLIDE — hover offset, no foot contact, no jump. (Kuntilanak, SundelBolong)
function EnemyRigs.applyFloatLocomotion(model: Model)
	applyLocomotion(model, "Float", { speedMult = 0.9, hipHeight = 4, noJump = true })
end

-- HOP — keep jump ability, normal speed; visual hop is per-enemy (e.g. Pocong). (Pocong)
function EnemyRigs.applyHopLocomotion(model: Model)
	applyLocomotion(model, "Hop", { speedMult = 1.0 })
end

-- SHUFFLE — very slow hunched gait. (WeweGombel)
function EnemyRigs.applyShuffleLocomotion(model: Model)
	applyLocomotion(model, "Shuffle", { speedMult = 0.5, noJump = true })
end

-- STRIDE — slow heavy wide steps (size from Constants rigSize). (ButoIjo)
function EnemyRigs.applyStrideLocomotion(model: Model)
	applyLocomotion(model, "Stride", { speedMult = 0.7, noJump = true })
end

-- SLITHER — ground-hugging, no jump. (NagaKomodo)
function EnemyRigs.applySlitherLocomotion(model: Model)
	applyLocomotion(model, "Slither", { speedMult = 1.0, hipHeight = 0, noJump = true })
end

-- MEDITATION — mostly stationary slow float drift. (BuddhaWraith)
function EnemyRigs.applyMeditationLocomotion(model: Model)
	applyLocomotion(model, "Meditation", { speedMult = 0.3, hipHeight = 3, noJump = true })
end

-- STOMP — slow heavy walk. (Genderuwo)
function EnemyRigs.applyStompLocomotion(model: Model)
	applyLocomotion(model, "Stomp", { speedMult = 0.6, noJump = true })
end

-- SCURRY — fast erratic small creature. (Tuyul)
function EnemyRigs.applyScurryLocomotion(model: Model)
	applyLocomotion(model, "Scurry", { speedMult = 1.6, noJump = true })
end

return EnemyRigs
