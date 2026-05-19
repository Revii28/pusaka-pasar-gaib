--!strict
--[[
	@module      MapHelpers
	@description Shared utilities buat 12 map module — terrain fill, common
	             decoration builders (tree/rock/torch/structure), spawn marker
	             invisible, return portal Cylinder dengan ProximityPrompt
	             "Kembali ke Pasar" yang fire teleport ke hub. MapData type
	             di-export. Density multiplier respected dari Constants.PERFORMANCE.
	@author      Claude Agent (primary coder)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local MapHelpers = {}

export type MapData = Constants.MapData

local RETURN_PAD_COLOR = Color3.fromRGB(80, 140, 230)
local RETURN_PAD_SIZE = Vector3.new(0.5, 8, 8)
local RETURN_PROMPT_ACTION = "Kembali"
local RETURN_PROMPT_OBJECT = "Kembali ke Pasar"

function MapHelpers.scaledCount(base: number): number
	local mult = Constants.PERFORMANCE.MAP_DECORATION_DENSITY_MULTIPLIER
	return math.max(1, math.floor(base * mult + 0.5))
end

function MapHelpers.particlesEnabled(): boolean
	return Constants.PERFORMANCE.ENABLE_PARTICLE_EMITTERS_MAPS
end

function MapHelpers.fillTerrain(
	offset: Vector3,
	size: Vector3,
	material: Enum.Material,
	height: number?
)
	local h = height or 10
	local terrain = workspace.Terrain
	local ok, err = pcall(function()
		terrain:FillBlock(
			CFrame.new(offset.X, offset.Y - h / 2, offset.Z),
			Vector3.new(size.X, h, size.Z),
			material
		)
	end)
	if not ok then
		warn(("[MapHelpers] FillBlock failed at %s: %s"):format(tostring(offset), tostring(err)))
	end
end

function MapHelpers.makePart(props: {
	name: string,
	size: Vector3,
	cframe: CFrame?,
	position: Vector3?,
	material: Enum.Material?,
	color: Color3?,
	transparency: number?,
	canCollide: boolean?,
	shape: Enum.PartType?,
	parent: Instance,
}): Part
	local part = Instance.new("Part")
	part.Name = props.name
	if props.shape then
		part.Shape = props.shape
	end
	part.Size = props.size
	if props.cframe then
		part.CFrame = props.cframe
	elseif props.position then
		part.Position = props.position
	end
	part.Material = props.material or Enum.Material.Plastic
	part.Color = props.color or Color3.fromRGB(180, 180, 180)
	part.Transparency = props.transparency or 0
	part.Anchored = true
	part.CanCollide = if props.canCollide == nil then true else props.canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = props.parent
	return part
end

function MapHelpers.scatterRange(
	random: Random,
	count: number,
	centerXZ: Vector2,
	radiusMin: number,
	radiusMax: number,
	builder: (Vector3) -> ()
)
	for _ = 1, count do
		local angle = random:NextNumber() * 2 * math.pi
		local radius = random:NextNumber(radiusMin, radiusMax)
		local pos = Vector3.new(
			centerXZ.X + math.cos(angle) * radius,
			0,
			centerXZ.Y + math.sin(angle) * radius
		)
		builder(pos)
	end
end

function MapHelpers.buildSimpleTorch(
	position: Vector3,
	parent: Instance,
	lightColor: Color3?
): Model
	local model = Instance.new("Model")
	model.Name = "Torch"
	local pole = MapHelpers.makePart({
		name = "Pole",
		size = Vector3.new(0.4, 3, 0.4),
		position = position + Vector3.new(0, 1.5, 0),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(60, 40, 25),
		parent = model,
	})
	local flame = MapHelpers.makePart({
		name = "Flame",
		size = Vector3.new(0.6, 0.6, 0.6),
		position = position + Vector3.new(0, 3.3, 0),
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		color = lightColor or Color3.fromRGB(255, 150, 60),
		canCollide = false,
		parent = model,
	})
	local light = Instance.new("PointLight")
	light.Color = lightColor or Color3.fromRGB(255, 150, 60)
	light.Brightness = 3
	light.Range = 12
	light.Parent = flame
	pole.Parent = model
	model.Parent = parent
	return model
end

function MapHelpers.buildSpawnMarker(mapData: MapData, parent: Instance): SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = ("Spawn_%s"):format(mapData.id)
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = mapData.spawnPos - Vector3.new(0, 0.5, 0)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Enabled = false
	spawn.Parent = parent
	return spawn
end

function MapHelpers.buildReturnPortal(
	mapData: MapData,
	parent: Instance,
	onTriggered: (Player) -> ()
): Model
	local model = Instance.new("Model")
	model.Name = "ReturnPortal"

	local pad = MapHelpers.makePart({
		name = "Pad",
		size = RETURN_PAD_SIZE,
		cframe = CFrame.new(mapData.returnPortalPos) * CFrame.Angles(0, 0, math.rad(90)),
		shape = Enum.PartType.Cylinder,
		material = Enum.Material.Neon,
		color = RETURN_PAD_COLOR,
		transparency = 0.2,
		canCollide = false,
		parent = model,
	})

	local pillar = MapHelpers.makePart({
		name = "Beacon",
		size = Vector3.new(0.5, 10, 0.5),
		position = mapData.returnPortalPos + Vector3.new(0, 5, 0),
		material = Enum.Material.Neon,
		color = RETURN_PAD_COLOR,
		transparency = 0.4,
		canCollide = false,
		parent = model,
	})

	local light = Instance.new("PointLight")
	light.Color = RETURN_PAD_COLOR
	light.Brightness = 3
	light.Range = 18
	light.Parent = pillar

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = RETURN_PROMPT_ACTION
	prompt.ObjectText = RETURN_PROMPT_OBJECT
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	prompt.Triggered:Connect(onTriggered)

	model.Parent = parent
	return model
end

function MapHelpers.getPortalService()
	local serverFolder = ServerScriptService:WaitForChild("Server")
	local servicesFolder = serverFolder:WaitForChild("services")
	return require(servicesFolder:WaitForChild("PortalService"))
end

return MapHelpers
