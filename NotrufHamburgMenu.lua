-- NotrufHamburgMenu.lua
-- Place this script into StarterPlayerScripts as a LocalScript

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local state = {
    carFly = false,
    godMode = false,
    rainbowCar = false,
}

local flyConnection = nil
local rainbowConnection = nil
local godModeConnection = nil
local currentMoveVector = Vector3.zero
local menuGui = nil
local menuOpen = true

local function makeButton(parent, text, size, pos, bgColor)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = pos
    button.BackgroundColor3 = bgColor
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 20
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = button

    return button
end

local function setMenuVisible(visible)
    menuOpen = visible
    if menuGui then
        menuGui.Enabled = visible
    end
end

local function toggleMenu()
    setMenuVisible(not menuOpen)
end

local function findVehicleForPlayer()
    local character = player.Character
    if not character then
        return nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("VehicleSeat") then
            if descendant.Occupant == humanoid then
                return descendant.Parent
            end
        end
    end

    return nil
end

local function getCharacterModel()
    if player.Character then
        return player.Character
    end
    return nil
end

local function stopCarFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    local vehicle = findVehicleForPlayer()
    if vehicle then
        local primaryPart = vehicle.PrimaryPart or vehicle:FindFirstChildOfClass("BasePart")
        if primaryPart then
            local flyVelocity = primaryPart:FindFirstChild("NotrufCarFlyVelocity")
            local flyGyro = primaryPart:FindFirstChild("NotrufCarFlyGyro")
            if flyVelocity then
                flyVelocity:Destroy()
            end
            if flyGyro then
                flyGyro:Destroy()
            end
        end
    end
end

local function startCarFly()
    if state.carFly then
        return
    end

    local vehicle = findVehicleForPlayer()
    if not vehicle then
        print("❌ Keine Auto gefunden - bitte einsteigen!")
        return
    end

    local primaryPart = vehicle.PrimaryPart or vehicle:FindFirstChildOfClass("BasePart")
    if not primaryPart then
        return
    end

    local flyVelocity = primaryPart:FindFirstChild("NotrufCarFlyVelocity")
    if not flyVelocity then
        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Name = "NotrufCarFlyVelocity"
        flyVelocity.MaxForce = Vector3.new(40000, 40000, 40000)
        flyVelocity.Velocity = Vector3.zero
        flyVelocity.Parent = primaryPart
    end

    local flyGyro = primaryPart:FindFirstChild("NotrufCarFlyGyro")
    if not flyGyro then
        flyGyro = Instance.new("BodyGyro")
        flyGyro.Name = "NotrufCarFlyGyro"
        flyGyro.MaxTorque = Vector3.new(50000, 50000, 50000)
        flyGyro.CFrame = primaryPart.CFrame
        flyGyro.Parent = primaryPart
    end

    state.carFly = true

    flyConnection = RunService.RenderStepped:Connect(function()
        if not state.carFly then
            return
        end

        local vehicleNow = findVehicleForPlayer()
        if not vehicleNow then
            stopCarFly()
            return
        end

        local vehiclePrimary = vehicleNow.PrimaryPart or vehicleNow:FindFirstChildOfClass("BasePart")
        if not vehiclePrimary then
            return
        end

        local finalMove = currentMoveVector
        local look = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local moveVector = (look * finalMove.Z + right * finalMove.X)

        if moveVector.Magnitude > 0 then
            moveVector = moveVector.Unit
        else
            moveVector = Vector3.zero
        end

        local upForce = 0
        if finalMove.Y > 0 then
            upForce = 16
        elseif finalMove.Y < 0 then
            upForce = -16
        end

        local speed = 45
        local targetVelocity = Vector3.new(moveVector.X * speed, upForce + 2, moveVector.Z * speed)

        flyVelocity.Velocity = targetVelocity
        flyGyro.CFrame = CFrame.new(vehiclePrimary.Position, vehiclePrimary.Position + (look * 2 + Vector3.new(0, 0.2, 0)))
    end)
end

local function toggleCarFly()
    if state.carFly then
        state.carFly = false
        stopCarFly()
    else
        startCarFly()
    end
end

local function setGodMode(enabled)
    local character = getCharacterModel()
    if not character then
        print("❌ Kein Character gefunden!")
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        print("❌ Humanoid nicht gefunden!")
        return
    end

    if enabled then
        print("✅ God Mode AKTIVIERT!")
        
        -- Disconnect alte Connection
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end

        -- Setze sehr hohe Health
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge

        -- Überwache Health und stelle sie wieder her
        godModeConnection = humanoid.HealthChanged:Connect(function()
            if state.godMode then
                humanoid.Health = math.huge
            end
        end)
    else
        print("❌ God Mode DEAKTIVIERT!")
        
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end

        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

local function toggleGodMode()
    state.godMode = not state.godMode
    setGodMode(state.godMode)
    print("God Mode Status: " .. tostring(state.godMode))
end

local function setRainbowCar(enabled)
    local vehicle = findVehicleForPlayer()
    if not vehicle then
        print("❌ Keine Auto gefunden!")
        return
    end

    if enabled then
        print("✅ Rainbow Car AKTIVIERT!")
        local hue = 0
        rainbowConnection = RunService.RenderStepped:Connect(function(dt)
            if not state.rainbowCar then
                return
            end

            local vehicleNow = findVehicleForPlayer()
            if not vehicleNow then
                return
            end

            hue = (hue + dt * 0.65) % 1
            local color = Color3.fromHSV(hue, 1, 1)

            for _, part in ipairs(vehicleNow:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Color = color
                end
            end
        end)
    else
        print("❌ Rainbow Car DEAKTIVIERT!")
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
    end
end

local function toggleRainbowCar()
    state.rainbowCar = not state.rainbowCar
    setRainbowCar(state.rainbowCar)
end

local function createRpgToolFE()
    local character = getCharacterModel()
    if not character then
        print("❌ Kein Character gefunden!")
        return
    end

    local existingTool = player.Backpack:FindFirstChild("RPG Tool FE")
    if existingTool then
        existingTool:Destroy()
    end

    local tool = Instance.new("Tool")
    tool.Name = "RPG Tool FE"
    tool.RequiresHandle = true

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 3, 1)
    handle.Material = Enum.Material.Metal
    handle.Color = Color3.fromRGB(255, 128, 0)
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    local rightHand = character:FindFirstChild("RightHand")
    local leftHand = character:FindFirstChild("LeftHand")
    local attachPart = rightHand or leftHand

    if attachPart then
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = attachPart
        weld.Parent = handle
    end

    tool.Parent = player.Backpack
    print("✅ RPG Tool FE erstellt!")

    tool.Activated:Connect(function()
        local char = getCharacterModel()
        if not char then
            return
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then
            return
        end

        local projectile = Instance.new("Part")
        projectile.Shape = Enum.PartType.Ball
        projectile.Size = Vector3.new(1.5, 1.5, 1.5)
        projectile.Material = Enum.Material.Neon
        projectile.Color = Color3.fromRGB(255, 140, 0)
        projectile.CanCollide = false
        projectile.CFrame = CFrame.new(root.Position + root.CFrame.LookVector * 3)
        projectile.Velocity = root.CFrame.LookVector * 120
        projectile.Parent = workspace

        local trail = Instance.new("Trail")
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 255, 255))
        trail.Lifetime = 0.2
        trail.LightEmission = 1
        trail.Parent = projectile

        Debris:AddItem(projectile, 3)

        projectile.Touched:Connect(function(hit)
            if hit:IsDescendantOf(char) then
                return
            end

            local targetHumanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
            if targetHumanoid then
                targetHumanoid:TakeDamage(35)
            end

            if projectile.Parent then
                projectile:Destroy()
            end
        end)
    end)
end

local function setupInput()
    local keyVectorMap = {
        [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
        [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
        [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
        [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
        [Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
        [Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0),
    }

    local pressedKeys = {}

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        local vec = keyVectorMap[input.KeyCode]
        if vec then
            pressedKeys[input.KeyCode] = true

            local result = Vector3.zero
            for keyCode, v in pairs(pressedKeys) do
                if v then
                    result += keyVectorMap[keyCode]
                end
            end
            currentMoveVector = result
        end

        if input.KeyCode == Enum.KeyCode.RightShift then
            toggleMenu()
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        local vec = keyVectorMap[input.KeyCode]
        if vec then
            pressedKeys[input.KeyCode] = false

            local result = Vector3.zero
            for keyCode, v in pairs(pressedKeys) do
                if v then
                    result += keyVectorMap[keyCode]
                end
            end
            currentMoveVector = result
        end
    end)
end

local function createMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotrufHamburgMenu"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local bg = Instance.new("Frame")
    bg.Name = "Main"
    bg.Size = UDim2.new(0, 420, 0, 480)
    bg.Position = UDim2.new(0.5, -210, 0.5, -240)
    bg.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    bg.BorderSizePixel = 0
    bg.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = bg

    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.65
    shadow.BorderSizePixel = 0
    shadow.Parent = bg
    shadow.ZIndex = -1

    local cornerShadow = Instance.new("UICorner")
    cornerShadow.CornerRadius = UDim.new(0, 18)
    cornerShadow.Parent = shadow

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 32, 0, 32)
    closeButton.Position = UDim2.new(1, -40, 0, 12)
    closeButton.Text = "X"
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeButton.BorderSizePixel = 0
    closeButton.Parent = bg

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 12)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        setMenuVisible(false)
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 50)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.Text = "NOTRUF HAMBURG"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 28
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Parent = bg

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -30, 0, 24)
    subtitle.Position = UDim2.new(0, 15, 0, 50)
    subtitle.Text = "Menu / Cheat UI"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 14
    subtitle.TextColor3 = Color3.fromRGB(170, 170, 170)
    subtitle.BackgroundTransparency = 1
    subtitle.Parent = bg

    local gradient = Instance.new("Frame")
    gradient.Size = UDim2.new(1, 0, 0, 4)
    gradient.Position = UDim2.new(0, 0, 0, 84)
    gradient.BackgroundColor3 = Color3.fromRGB(255, 145, 0)
    gradient.BorderSizePixel = 0
    gradient.Parent = bg

    local buttonList = {
        {"Car Fly", UDim2.new(0, 180, 0, 42), UDim2.new(0, 20, 0, 110), Color3.fromRGB(47, 113, 201)},
        {"God Mode", UDim2.new(0, 180, 0, 42), UDim2.new(0, 220, 0, 110), Color3.fromRGB(46, 204, 113)},
        {"Rainbow Car", UDim2.new(0, 180, 0, 42), UDim2.new(0, 20, 0, 175), Color3.fromRGB(255, 104, 104)},
        {"RPG Tool FE", UDim2.new(0, 180, 0, 42), UDim2.new(0, 220, 0, 175), Color3.fromRGB(255, 172, 51)},
    }

    local buttons = {}

    for i, item in ipairs(buttonList) do
        local name, size, pos, color = item[1], item[2], item[3], item[4]
        local btn = makeButton(bg, name, size, pos, color)

        btn.MouseButton1Click:Connect(function()
            if name == "Car Fly" then
                toggleCarFly()
                btn.Text = state.carFly and "Car Fly ON ✅" or "Car Fly"
            elseif name == "God Mode" then
                toggleGodMode()
                btn.Text = state.godMode and "God Mode ON ✅" or "God Mode"
            elseif name == "Rainbow Car" then
                toggleRainbowCar()
                btn.Text = state.rainbowCar and "Rainbow Car ON ✅" or "Rainbow Car"
            elseif name == "RPG Tool FE" then
                createRpgToolFE()
                btn.Text = "✅ Spawned!"
                task.wait(2)
                btn.Text = "RPG Tool FE"
            end
        end)

        table.insert(buttons, btn)
    end

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -30, 0, 130)
    info.Position = UDim2.new(0, 15, 0, 240)
    info.Text = "🎮 Tasten: W A S D + Leertaste / Strg\n\n⚡ God Mode: Unsterblich bleiben!\n\n📞 Handy im Inventar nutzbar\n\nMenü Toggle: Rechts Shift"
    info.Font = Enum.Font.Gotham
    info.TextSize = 14
    info.TextWrap = true
    info.TextColor3 = Color3.fromRGB(205, 205, 205)
    info.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    info.BorderSizePixel = 0
    info.Parent = bg

    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 12)
    infoCorner.Parent = info

    menuGui = screenGui
    setMenuVisible(true)
    return screenGui
end

print("🚀 Notruf Hamburg Menu wird geladen...")
setupInput()
createMenu()
print("✅ Menü erfolgreich erstellt!")

player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    print("🔄 Character respawned!")
    if state.godMode then
        print("⚡ God Mode wird reaktiviert...")
        setGodMode(true)
    end
end)

player.CharacterAdded:Connect(function()
    if state.carFly then
        print("🚗 Car Fly wird reaktiviert...")
        startCarFly()
    end
end)
