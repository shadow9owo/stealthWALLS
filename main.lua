print("loaded")

local UserInputService = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

local isSpeedBoosted   = false
local isGodModeEnabled = false
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
        if isWallhackActive then
            addPlayerHighlight(newPlayer)
        end
    end)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        local hum = getLocalHumanoid()
        if hum then
            isSpeedBoosted = not isSpeedBoosted
        end
    elseif input.KeyCode == Enum.KeyCode.CapsLock then
        isGodModeEnabled = not isGodModeEnabled
    elseif input.KeyCode == Enum.KeyCode.X then
        isWallhackActive = not isWallhackActive
    end
end)

RunService.RenderStepped:Connect(function()
    local humanoid = getLocalHumanoid()
    if not humanoid or humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return
    end

    local rootPart = getLocalRootPart()
    if not rootPart then return end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer then
            local otherChar = otherPlayer.Character
            local otherHum  = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
            local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
            local isOtherAlive = otherHum and otherHum.Health > 0 and otherHum:GetState() ~= Enum.HumanoidStateType.Dead

            if otherRoot and isWallhackActive and isOtherAlive then
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
end)
