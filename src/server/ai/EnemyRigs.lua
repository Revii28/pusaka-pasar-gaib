--!strict
--[[
	@module      EnemyRigs
	@description Shared builders untuk enemy rig — minimal Humanoid-driven
	             skeleton (HumanoidRootPart unanchored + Humanoid + visual parts
	             welded via WeldConstraint). Bukan reuse GhostSpawner (yang
	             anchored cosmetic). Tiap enemy module call helper relevant atau
	             build dari scratch dengan helper di sini.

	             Per-enemy asset notes:
	             - Pocong: Blender-generated MeshPart, location
	               ReplicatedStorage.EnemyMeshes.PocongMesh (manual import via
	               Studio UI). Fallback: primitive parts (legacy buildPocongRig
	               logic preserved di enemies/Pocong.lua buildPrimitiveRig()).
	@author      Claude Agent (primary coder)
]]

local EnemyRigs = {}

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

return EnemyRigs
