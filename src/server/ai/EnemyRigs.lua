--!strict
--[[
	@module      EnemyRigs
	@description Shared builders untuk enemy rig — minimal Humanoid-driven
	             skeleton (HumanoidRootPart unanchored + Humanoid + visual parts
	             welded via WeldConstraint). Bukan reuse GhostSpawner (yang
	             anchored cosmetic). Tiap enemy module call helper relevant atau
	             build dari scratch dengan helper di sini.
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

return EnemyRigs
