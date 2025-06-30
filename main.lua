print("loaded")

local UserInputService = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local camera      = workspace.CurrentCamera

local isSpeedBoosted   = false
local isGodModeEnabled = false
local isWallhackActive = false

local normalSpeed  = 16
local boostedSpeed = 50

local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()
localPlayer.CharacterAdded:Connect(function(char)
    localCharacter = char
end)

local function getLocalHumanoid()
    return localCharacter and localCharacter:FindFirstChildOfClass("Humanoid")
end

local function getLocalRootPart()
    return localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
end

local function addPlayerHighlight(otherPlayer)
    local char = otherPlayer.Character
    if not char or char:FindFirstChild("WallhackHighlight") then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name         = "WallhackHighlight"
    highlight.FillColor    = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
    highlight.Parent       = char

    char.AncestryChanged:Connect(function(_, parent)
        if not parent and highlight.Parent then
            highlight:Destroy()
        end
    end)
end

local function removePlayerHighlight(otherPlayer)
    local char = otherPlayer.Character
    if not char then return end
    local existing = char:FindFirstChild("WallhackHighlight")
    if existing then
        existing:Destroy()
    end
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

    local highlight = Instance.new("Highlight")
    highlight.Name         = "TracerHighlight"
    highlight.FillColor    = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent       = part

    return part
end

local function destroyCylinderTracer(tracer)
    if tracer then
        tracer:Destroy()
    end
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
            hum.WalkSpeed  = isSpeedBoosted and boostedSpeed or normalSpeed
        end
    elseif input.KeyCode == Enum.KeyCode.CapsLock then
        isGodModeEnabled = not isGodModeEnabled
    elseif input.KeyCode == Enum.KeyCode.X then
        isWallhackActive = not isWallhackActive
    end
end)

RunService.RenderStepped:Connect(function()
    local rootPart = getLocalRootPart()
    if not rootPart then return end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer then
            local otherRoot = otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart")

            if otherRoot and isWallhackActive then
                addPlayerHighlight(otherPlayer)

                if not tracers[otherPlayer] then
                    tracers[otherPlayer] = createCylinderTracer()
                end

                local tracer = tracers[otherPlayer]
                local startPos, endPos = otherRoot.Position, rootPart.Position
                local midpoint          = (startPos + endPos) * 0.5
                local direction         = endPos - startPos
                local length            = direction.Magnitude

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

    local humanoid = getLocalHumanoid()
    if humanoid then
        if isGodModeEnabled then
            humanoid.MaxHealth = 1e9
            humanoid.Health    = 1e9
        else
            humanoid.MaxHealth = 100
            humanoid.Health    = 100
        end
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
