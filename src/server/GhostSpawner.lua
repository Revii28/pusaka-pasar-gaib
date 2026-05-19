--!strict
--[[
	@module      GhostSpawner
	@description Spawn 1 hantu companion di belakang tiap NPC vendor (6 studs
	             behind, calculated from NPC lookDirection). Pairing kultural:
	               Mbok Inem    -> Pocong     (classic Indo, kain putih kotor)
	               Pak Tukijo   -> Genderuwo  (forest dweller, mata merah glow)
	               Nyai Sumi    -> Kuntilanak (female ghost, rambut panjang)
	               Bandar Robux -> Leak       (Balinese, kepala lepas floating)
	             Tiap hantu placeholder BasePart primitive (Block/Ball/Cylinder)
	             dengan BillboardGui nama merah di atas head. Kuntilanak hover
	             vertikal via TweenService, Leak head orbit horizontal via
	             RunService Heartbeat. Detail polish & custom mesh nyusul Phase
	             art pass.
	@author      Claude Agent (primary coder)
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GhostSpawner = {}

type GhostType = "Pocong" | "Genderuwo" | "Kuntilanak" | "Leak"

type VendorInfo = {
	name: string,
	position: Vector3,
	lookDirection: Vector3,
}

local BEHIND_DISTANCE = 6
local TAG_COLOR = Color3.fromRGB(255, 100, 100)
local TAG_SIZE = UDim2.new(0, 80, 0, 20)

local NPC_TO_GHOST: { [string]: GhostType } = {
	["Mbok Inem"] = "Pocong",
	["Pak Tukijo"] = "Genderuwo",
	["Nyai Sumi"] = "Kuntilanak",
	["Bandar Robux"] = "Leak",
}

local function attachNameTag(anchor: BasePart, ghostName: string, offsetY: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GhostNameTag"
	billboard.Size = TAG_SIZE
	billboard.StudsOffset = Vector3.new(0, offsetY, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = anchor
	billboard.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ghostName
	label.Font = Enum.Font.Cartoon
	label.TextColor3 = TAG_COLOR
	label.TextScaled = true
	label.Parent = billboard
end

local function buildPocong(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Pocong"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 7, 3)
	body.Position = base + Vector3.new(0, 3.5, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Fabric
	body.Color = Color3.fromRGB(220, 215, 200)
	body.Transparency = 0.3
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Position = base + Vector3.new(0, 8, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.Fabric
	head.Color = Color3.fromRGB(220, 215, 200)
	head.Transparency = 0.3
	head.Parent = model

	model.PrimaryPart = head
	attachNameTag(head, "Pocong", 2)
	return model
end

local function buildGenderuwo(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Genderuwo"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(4, 9, 3)
	body.Position = base + Vector3.new(0, 4.5, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Slate
	body.Color = Color3.fromRGB(60, 40, 30)
	body.Transparency = 0.2
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local eyeOffsets: { Vector3 } = {
		Vector3.new(-0.7, 3.5, 1.6),
		Vector3.new(0.7, 3.5, 1.6),
	}
	for i, off in ipairs(eyeOffsets) do
		local eye = Instance.new("Part")
		eye.Name = ("Eye%d"):format(i)
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.3, 0.3, 0.3)
		eye.Position = base + off
		eye.Anchored = true
		eye.CanCollide = false
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255, 0, 0)
		eye.Parent = model

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 0, 0)
		light.Brightness = 2
		light.Range = 5
		light.Parent = eye
	end

	model.PrimaryPart = body
	attachNameTag(body, "Genderuwo", 6)
	return model
end

local function buildKuntilanak(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Kuntilanak"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.5, 8, 2.5)
	body.Position = base + Vector3.new(0, 4, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Fabric
	body.Color = Color3.fromRGB(240, 240, 230)
	body.Transparency = 0.5
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local hair = Instance.new("Part")
	hair.Name = "Hair"
	hair.Shape = Enum.PartType.Cylinder
	hair.Size = Vector3.new(6, 0.5, 0.5)
	hair.CFrame = CFrame.new(base + Vector3.new(0, 5, -1.4)) * CFrame.Angles(0, 0, math.rad(90))
	hair.Anchored = true
	hair.CanCollide = false
	hair.Material = Enum.Material.Fabric
	hair.Color = Color3.fromRGB(15, 10, 10)
	hair.Parent = model

	local hoverInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local hoverTween = TweenService:Create(body, hoverInfo, {
		Position = body.Position + Vector3.new(0, 0.5, 0),
	})
	hoverTween:Play()

	model.PrimaryPart = body
	attachNameTag(body, "Kuntilanak", 5)
	return model
end

local function buildLeak(base: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Leak"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 4, 3)
	body.Position = base + Vector3.new(0, 2, 0)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Glass
	body.Color = Color3.fromRGB(180, 50, 50)
	body.Transparency = 0.4
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.Glass
	head.Color = Color3.fromRGB(180, 50, 50)
	head.Transparency = 0.4
	head.Parent = model

	local centerPos = base + Vector3.new(0, 8, 0)
	head.Position = centerPos

	local orbitRadius = 1.5
	local orbitSpeed = 1.0
	local t = 0
	local heartbeat: RBXScriptConnection
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		if not head.Parent then
			heartbeat:Disconnect()
			return
		end
		t += dt * orbitSpeed
		head.Position = centerPos
			+ Vector3.new(math.cos(t) * orbitRadius, 0, math.sin(t) * orbitRadius)
	end)

	model.PrimaryPart = head
	attachNameTag(head, "Leak", 2)
	return model
end

local BUILDERS: { [GhostType]: (Vector3) -> Model } = {
	Pocong = buildPocong,
	Genderuwo = buildGenderuwo,
	Kuntilanak = buildKuntilanak,
	Leak = buildLeak,
}

function GhostSpawner.spawnAll(vendorList: { VendorInfo }): { Model }
	local spawned: { Model } = {}
	for _, vendor in ipairs(vendorList) do
		local ghostType = NPC_TO_GHOST[vendor.name]
		if not ghostType then
			warn(("[GhostSpawner] no ghost mapping for vendor %s"):format(vendor.name))
			continue
		end

		local builder = BUILDERS[ghostType]
		local behindOffset = -vendor.lookDirection * BEHIND_DISTANCE
		local groundPos =
			Vector3.new(vendor.position.X + behindOffset.X, 0, vendor.position.Z + behindOffset.Z)

		local ghost = builder(groundPos)
		ghost.Parent = workspace
		table.insert(spawned, ghost)
	end
	return spawned
end

return GhostSpawner
