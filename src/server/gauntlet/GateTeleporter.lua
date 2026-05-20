--!strict
--[[
	@module      GateTeleporter
	@description Gate Part 8x12x0.5 ForceField material di entry tiap room
	             selanjutnya. Default RED locked + prompt disabled. Kalau
	             GauntletService notify room cleared → unlock(gate) → GREEN +
	             prompt enabled. Prompt Triggered: teleport player 8 stud past
	             gate. Anti-cheese: gate keeps state per server instance, restart
	             clears state (MVP acceptable).
	@author      Claude Agent (primary coder)
]]

local GateTeleporter = {}

local GATE_SIZE = Vector3.new(8, 12, 0.5)
local GATE_LOCKED_COLOR = Color3.fromRGB(255, 50, 50)
local GATE_UNLOCKED_COLOR = Color3.fromRGB(50, 255, 100)

local function getMapsFolder(): Instance
	return workspace:FindFirstChild("Maps") or workspace
end

function GateTeleporter.spawnGate(position: Vector3, roomId: any, initiallyUnlocked: boolean): Part
	local gate = Instance.new("Part")
	gate.Name = ("GauntletGate_%s"):format(tostring(roomId))
	gate.Size = GATE_SIZE
	gate.Position = position + Vector3.new(0, 6, 0)
	gate.Anchored = true
	gate.CanCollide = true
	gate.Material = Enum.Material.ForceField
	gate.Color = if initiallyUnlocked then GATE_UNLOCKED_COLOR else GATE_LOCKED_COLOR
	gate.Transparency = 0.3
	gate:SetAttribute("Unlocked", initiallyUnlocked)
	gate:SetAttribute("RoomId", tostring(roomId))
	gate.Parent = getMapsFolder()

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lanjut"
	prompt.ObjectText = "Pintu Gauntlet"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = initiallyUnlocked
	prompt.Parent = gate

	prompt.Triggered:Connect(function(player: Player)
		if not gate:GetAttribute("Unlocked") then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = CFrame.new(gate.Position + Vector3.new(0, 2, 8))
		end
	end)

	return gate
end

function GateTeleporter.unlock(gate: Part?)
	if not gate then
		return
	end
	gate:SetAttribute("Unlocked", true)
	gate.Color = GATE_UNLOCKED_COLOR
	local prompt = gate:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end
end

return GateTeleporter
