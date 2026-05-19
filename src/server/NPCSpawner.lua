--!strict
--[[
	@module      NPCSpawner
	@description Spawn 4 NPC vendor Pasar Gaib di 4 quadrant Middle Ring (~56
	             studs dari center, asymmetric). Tiap NPC dapat: R6 rig
	             placeholder (HRP + Head + Torso + 4 limb + Humanoid WalkSpeed=0)
	             menghadap center, ProximityPrompt "Ngobrol" key E range 8 yang
	             fire Chat:Chat() bubble. Kiosk decoration sekarang di-delegate
	             ke KioskBuilder.build() (lampion, atap layered, sesajen pile,
	             papan nama, floor). Export getVendorList() supaya GhostSpawner
	             bisa nempelin hantu di belakang tiap NPC.
	@author      Claude Agent (primary coder)
]]

local Chat = game:GetService("Chat")
local ServerScriptService = game:GetService("ServerScriptService")

local KioskBuilder =
	require(ServerScriptService:WaitForChild("Server"):WaitForChild("KioskBuilder"))

local NPCSpawner = {}

export type VendorInfo = {
	name: string,
	position: Vector3,
	lookDirection: Vector3,
}

type VendorSpec = {
	name: string,
	floorPosition: Vector3,
	torsoColor: Color3,
	dialogue: string,
}

local HUB_CENTER = Vector3.new(0, 0, 0)
local FEET_Y_OFFSET = 3
local ACTIVATION_DISTANCE = 8
local PROMPT_ACTION_TEXT = "Ngobrol"

local SKIN_COLOR = Color3.fromRGB(235, 178, 122)
local LIMB_DARK = Color3.fromRGB(40, 30, 25)
local ROOT_INVISIBLE = Color3.fromRGB(0, 0, 0)

local VENDORS: { VendorSpec } = {
	{
		name = "Mbok Inem",
		floorPosition = Vector3.new(38, 0, -42),
		torsoColor = Color3.fromRGB(102, 30, 30),
		dialogue = "Selamat datang. Cari kemenyan? Gw punya yang madu, paling wangi se-pasar.",
	},
	{
		name = "Pak Tukijo",
		floorPosition = Vector3.new(-52, 0, -22),
		torsoColor = Color3.fromRGB(30, 40, 80),
		dialogue = "Bunga 7 rupa, daun sirih, telur cemani — komplit di sini. Mau ritual apa malam ini?",
	},
	{
		name = "Nyai Sumi",
		floorPosition = Vector3.new(45, 0, 35),
		torsoColor = Color3.fromRGB(20, 15, 25),
		dialogue = "Mampir, Nak. Tasbih putih buat nolak bala, lilin merah buat ritual malam, air mawar buat sucikan diri. Mau yang mana?",
	},
	{
		name = "Bandar Robux",
		floorPosition = Vector3.new(-30, 0, 48),
		torsoColor = Color3.fromRGB(40, 130, 60),
		dialogue = "Robux numpuk, Koin Gaib menipis? Tuker di sini, rate adil. Jangan ke bandar lain, banyak yang nipu.",
	},
}

local vendorInfos: { VendorInfo } = {}

local function makePart(
	name: string,
	size: Vector3,
	color: Color3,
	parent: Instance,
	invisible: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Anchored = true
	part.CanCollide = not invisible
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if invisible then
		part.Transparency = 1
	end
	part.Parent = parent
	return part
end

local function buildRig(spec: VendorSpec): Model
	local model = Instance.new("Model")
	model.Name = spec.name

	local root = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), ROOT_INVISIBLE, model, true)
	local head = makePart("Head", Vector3.new(2, 1, 1), SKIN_COLOR, model)
	local torso = makePart("Torso", Vector3.new(2, 2, 1), spec.torsoColor, model)
	local leftArm = makePart("Left Arm", Vector3.new(1, 2, 1), SKIN_COLOR, model)
	local rightArm = makePart("Right Arm", Vector3.new(1, 2, 1), SKIN_COLOR, model)
	local leftLeg = makePart("Left Leg", Vector3.new(1, 2, 1), LIMB_DARK, model)
	local rightLeg = makePart("Right Leg", Vector3.new(1, 2, 1), LIMB_DARK, model)

	root.CFrame = CFrame.new(0, 0, 0)
	torso.CFrame = CFrame.new(0, 0, 0)
	head.CFrame = CFrame.new(0, 1.5, 0)
	leftArm.CFrame = CFrame.new(-1.5, 0, 0)
	rightArm.CFrame = CFrame.new(1.5, 0, 0)
	leftLeg.CFrame = CFrame.new(-0.5, -2, 0)
	rightLeg.CFrame = CFrame.new(0.5, -2, 0)

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.DisplayName = spec.name
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	model.PrimaryPart = root

	local placePosition = spec.floorPosition + Vector3.new(0, FEET_Y_OFFSET, 0)
	local lookTarget = HUB_CENTER + Vector3.new(0, FEET_Y_OFFSET, 0)
	model:PivotTo(CFrame.lookAt(placePosition, lookTarget))

	return model
end

local function attachPrompt(model: Model, spec: VendorSpec)
	local root = model.PrimaryPart
	if not root then
		warn(("[NPCSpawner] %s missing PrimaryPart, skip prompt"):format(spec.name))
		return
	end

	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		warn(("[NPCSpawner] %s missing Head, skip prompt"):format(spec.name))
		return
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = PROMPT_ACTION_TEXT
	prompt.ObjectText = spec.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = ACTIVATION_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = root

	prompt.Triggered:Connect(function()
		Chat:Chat(head, spec.dialogue, Enum.ChatColor.White)
	end)
end

function NPCSpawner.spawnAll(): { Model }
	local spawned: { Model } = {}
	table.clear(vendorInfos)

	for _, spec in ipairs(VENDORS) do
		print(
			("[NPCSpawner] Spawning %s at (%.0f, %.0f, %.0f)..."):format(
				spec.name,
				spec.floorPosition.X,
				spec.floorPosition.Y,
				spec.floorPosition.Z
			)
		)
		local placePosition = spec.floorPosition + Vector3.new(0, FEET_Y_OFFSET, 0)
		local lookTarget = HUB_CENTER + Vector3.new(0, FEET_Y_OFFSET, 0)
		local lookDirection = (lookTarget - placePosition).Unit

		local rigOk, rigErr = pcall(function()
			local rig = buildRig(spec)
			attachPrompt(rig, spec)
			rig.Parent = workspace
			table.insert(spawned, rig)
		end)
		if not rigOk then
			warn(("[NPCSpawner] %s rig FAILED: %s"):format(spec.name, tostring(rigErr)))
			continue
		end

		local kioskOk, kioskErr = pcall(function()
			KioskBuilder.build(placePosition, lookDirection, spec.name, workspace)
		end)
		if not kioskOk then
			warn(("[NPCSpawner] %s kiosk FAILED: %s"):format(spec.name, tostring(kioskErr)))
		end

		table.insert(vendorInfos, {
			name = spec.name,
			position = placePosition,
			lookDirection = lookDirection,
		})
		print(("[NPCSpawner] %s spawned (rig + kiosk done)."):format(spec.name))
	end

	return spawned
end

function NPCSpawner.getVendorList(): { VendorInfo }
	return vendorInfos
end

return NPCSpawner
