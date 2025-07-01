print("loaded")

local UserInputService = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

local isSpeedBoosted   = false
local isWallhackActive = false

local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
localPlayer.CharacterAdded:Connect(function(char)
	localCharacter = char
	for p, tracer in pairs(tracers) do
		destroyCylinderTracer(tracer)
		tracers[p] = nil
		removePlayerHighlight(p)
	end
end)

local function getLocalHumanoid()
	return localCharacter and localCharacter:FindFirstChildOfClass("Humanoid")
end

local function getLocalRootPart()
	return localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
end

local function addPlayerHighlight(otherPlayer)
	local char = otherPlayer.Character
	if not char or char:FindFirstChild("WallhackHighlight") then return end
	local hl = Instance.new("Highlight")
	hl.Name         = "WallhackHighlight"
	hl.FillColor    = Color3.fromRGB(255, 0, 0)
	hl.OutlineColor = Color3.fromRGB(0, 0, 255)
	hl.Parent       = char
	char.AncestryChanged:Connect(function(_, parent)
		if not parent and hl.Parent then hl:Destroy() end
	end)
end

local function removePlayerHighlight(otherPlayer)
	local char = otherPlayer.Character
	if not char then return end
	local existing = char:FindFirstChild("WallhackHighlight")
	if existing then existing:Destroy() end
end

local tracers = {}

local function createCylinderTracer()
	local part = Instance.new("Part")
	part.Name         = "Tracer"
	part.Anchored     = true
	part.CanCollide   = false
	part.Size         = Vector3.new(0.1, 1, 0.1)
	part.Material     = Enum.Material.Neon
	part.Transparency = 0
	part.Color        = Color3.fromRGB(0, 255, 0)
	part.Parent       = workspace
	Instance.new("CylinderMesh", part)
	local hl = Instance.new("Highlight")
	hl.Name         = "TracerHighlight"
	hl.FillColor    = Color3.fromRGB(0, 255, 0)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.Parent       = part
	return part
end

local function destroyCylinderTracer(tracer)
	if tracer then tracer:Destroy() end
end

Players.PlayerRemoving:Connect(function(exitingPlayer)
	removePlayerHighlight(exitingPlayer)
	if tracers[exitingPlayer] then
		destroyCylinderTracer(tracers[exitingPlayer])
		tracers[exitingPlayer] = nil
	end
end)

Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer.CharacterAdded:Connect(function()
		if isWallhackActive then addPlayerHighlight(newPlayer) end
	end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		local hum = getLocalHumanoid()
		if hum then
			isSpeedBoosted = not isSpeedBoosted
		end
	elseif input.KeyCode == Enum.KeyCode.X then
		isWallhackActive = not isWallhackActive
	end
end)

local localPlayerDead = false
local humanoid = getLocalHumanoid()

if humanoid then
	humanoid.Died:Connect(function()
		localPlayerDead = true
		for p, tracer in pairs(tracers) do
			destroyCylinderTracer(tracer)
			tracers[p] = nil
			removePlayerHighlight(p)
		end
	end)
end

RunService.RenderStepped:Connect(function()
	humanoid = getLocalHumanoid()
	if not humanoid or humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		localPlayerDead = true
		for p, tracer in pairs(tracers) do
			destroyCylinderTracer(tracer)
			tracers[p] = nil
			removePlayerHighlight(p)
		end
		return
	else
		localPlayerDead = false
	end

	local rootPart = getLocalRootPart()
	if not rootPart then return end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= localPlayer then
			local otherChar = otherPlayer.Character
			local otherHum  = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
			local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
			local isOtherAlive = otherHum and otherHum.Health > 0 and otherHum:GetState() ~= Enum.HumanoidStateType.Dead

			if otherRoot and isWallhackActive and isOtherAlive and not localPlayerDead then
				addPlayerHighlight(otherPlayer)
				if not tracers[otherPlayer] then
					tracers[otherPlayer] = createCylinderTracer()
				end
				local tracer    = tracers[otherPlayer]
				local startPos  = otherRoot.Position
				local endPos    = rootPart.Position
				local midpoint  = (startPos + endPos) * 0.5
				local direction = endPos - startPos
				local length    = direction.Magnitude
				tracer.Size   = Vector3.new(0.1, length, 0.1)
				tracer.CFrame = CFrame.new(midpoint, endPos) * CFrame.Angles(math.rad(90), 0, 0)
			else
				removePlayerHighlight(otherPlayer)
				if tracers[otherPlayer] then
					destroyCylinderTracer(tracers[otherPlayer])
					tracers[otherPlayer] = nil
				end
			end
		end
	end

	if isGodModeEnabled then
		humanoid.MaxHealth = 1e9
		humanoid.Health    = 1e9
	else
		humanoid.MaxHealth = 100
		humanoid.Health    = 100
	end

	if isSpeedBoosted and rootPart then
		local moveDir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += camera.CFrame.RightVector end
		if moveDir.Magnitude > 0 then
			rootPart.CFrame += moveDir.Unit * 0.2
		end
	end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CheatStatusGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 250, 0, 120)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.Font = Enum.Font.SourceSansBold
statusLabel.TextSize = 16
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Visible = false
statusLabel.Parent = screenGui

local isHudVisible = false

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F3 then
		isHudVisible = not isHudVisible
		statusLabel.Visible = isHudVisible
	end
end)

RunService.RenderStepped:Connect(function()
	if isHudVisible then
		statusLabel.Text = "=== Cheat Status ===\n" ..
			"Wallhack (X): " .. (isWallhackActive and "ON" or "OFF") .. "\n" ..
			"Speed Boost (LeftShift): " .. (isSpeedBoosted and "ON" or "OFF") .. "\n\n" ..
			"Press F3 to toggle this HUD"
	end
end)
