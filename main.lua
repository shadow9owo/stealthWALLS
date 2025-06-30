print("loaded")

local UserInputService = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera

local speedBoosted = false
local godMode      = false
local wallhacks    = false

local character = player.Character or player.CharacterAdded:Wait()
player.CharacterAdded:Connect(function(char)
	character = char
end)

local function getHumanoid()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function highlightPlayer(plr)
	local char = plr.Character
	if not char then return end
	if char:FindFirstChild("WallhackHighlight") then return end

	local hl = Instance.new("Highlight")
	hl.Name         = "WallhackHighlight"
	hl.FillColor    = Color3.fromRGB(255, 0, 0)
	hl.OutlineColor = Color3.fromRGB(0, 0, 255)
	hl.Parent       = char
end

local function removeHighlight(plr)
	local char = plr.Character
	if not char then return end

	local hl = char:FindFirstChild("WallhackHighlight")
	if hl then hl:Destroy() end
end

local highlightParts = {}
local function clearHighlightParts()
	for _, part in pairs(highlightParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	highlightParts = {}
end

local function drawOneFrameBeam(startPos, endPos, color)
	color = color or Color3.fromRGB(0, 255, 0)

	local function makePart(pos)
		local p = Instance.new("Part")
		p.Name        = "BeamPart"
		p.Anchored    = true
		p.CanCollide  = false
		p.Transparency= 0
		p.Size        = Vector3.new(0.1, 0.1, 0.1)
		p.Position    = pos
		p.Parent      = workspace

		local hl = Instance.new("Highlight")
		hl.Name         = "TracerHighlight"
		hl.FillColor    = color
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.Parent       = p

		table.insert(highlightParts, p)
		return p
	end

	local part0 = makePart(startPos)
	local part1 = makePart(endPos)

	-- Attach beam
	local att0 = Instance.new("Attachment", part0)
	local att1 = Instance.new("Attachment", part1)
	local beam = Instance.new("Beam")
	beam.Attachment0  = att0
	beam.Attachment1  = att1
	beam.Width0       = 0.05
	beam.Width1       = 0.05
	beam.FaceCamera   = true
	beam.Color        = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new(0.2)
	beam.Parent       = part0

	RunService.RenderStepped:Wait()
	beam:Destroy()
	att0:Destroy()
	att1:Destroy()
end

-- Keybind toggles
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		local hum = getHumanoid()
		if hum then
			speedBoosted = not speedBoosted
			hum.WalkSpeed = speedBoosted and boostedWalkSpeed or normalWalkSpeed
		end

	elseif input.KeyCode == Enum.KeyCode.CapsLock then
		godMode = not godMode

	elseif input.KeyCode == Enum.KeyCode.X then
		wallhacks = not wallhacks
	end
end)

RunService.RenderStepped:Connect(function()
	clearHighlightParts()

	local hrp = getHRP()
	if not hrp then return end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local char     = plr.Character
			local otherHRP = char and char:FindFirstChild("HumanoidRootPart")

			if otherHRP then
				if wallhacks then
					highlightPlayer(plr)
					drawOneFrameBeam(otherHRP.Position, hrp.Position)
				else
					removeHighlight(plr)
				end
			end
		end
	end

	local hum = getHumanoid()
	if hum then
		if godMode then
			hum.MaxHealth = 1e9
			hum.Health    = 1e9
		else
			hum.MaxHealth = 100
			hum.Health    = 100
		end
	end
    
	if speedBoosted and hrp then
		local mv = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv -= camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += camera.CFrame.RightVector end

		if mv.Magnitude > 0 then
			hrp.CFrame += mv.Unit * 0.2
		end
	end
end)
