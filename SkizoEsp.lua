-- ============================================
-- SKIZO HUB v4.2 - FLY FIXED + MINI UI
-- ESP | SPEED | NO CLIP | FLY (FIXED) | ANTI STUN | SPECTATE | POINTS | TP PLAYER
-- UI SIZE: 180x200
-- ============================================

-- ================= PART 1: VARIABLES =================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Core Variables
local espEnabled = false
local espObjects = {}
local savedData = {}
local fileName = "SkizoData.json"
local isSpectating = false
local currentSpectateTarget = nil
local camera = Workspace.CurrentCamera

-- Speed Variables
local currentSpeed = 50
local defaultSpeed = 50
local speedEnabled = false
local speedConnection = nil

-- No Clip Variables
local noClipEnabled = false
local noClipConnection = nil

-- Fly Mode Variables (FIXED)
local flyEnabled = false
local flyConnection = nil
local flySpeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil
local originalGravity = nil

-- Anti Stun Variables
local antiStunEnabled = false
local antiStunConnection = nil

-- ================= PART 2: SAVE/LOAD SYSTEM =================
local function loadData()
    local success, data = pcall(function()
        if isfile and isfile(fileName) then
            return readfile(fileName)
        end
        return nil
    end)
    
    if success and data then
        local decoded = game:GetService("HttpService"):JSONDecode(data)
        if decoded then
            savedData = decoded
            if not savedData.points then savedData.points = {} end
            if not savedData.speed then savedData.speed = 50 end
            if not savedData.flySpeed then savedData.flySpeed = 50 end
            currentSpeed = savedData.speed or 50
            flySpeed = savedData.flySpeed or 50
            return
        end
    end
    savedData = {points = {}, speed = 50, flySpeed = 50}
    currentSpeed = 50
    flySpeed = 50
end

local function saveData()
    savedData.speed = currentSpeed
    savedData.flySpeed = flySpeed
    local encoded = game:GetService("HttpService"):JSONEncode(savedData)
    pcall(function()
        if writefile then
            writefile(fileName, encoded)
        end
    end)
end

-- ================= PART 3: SPEED SYSTEM =================
local function applySpeed()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = currentSpeed
    end
end

local function startSpeedControl()
    if speedConnection then speedConnection:Disconnect() end
    speedConnection = RunService.RenderStepped:Connect(function()
        if speedEnabled and LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.WalkSpeed ~= currentSpeed then
                humanoid.WalkSpeed = currentSpeed
            end
        end
    end)
end

local function setSpeed(value)
    currentSpeed = math.clamp(value, 1, 1000)
    saveData()
    if speedEnabled then applySpeed() end
end

local function toggleSpeed()
    speedEnabled = not speedEnabled
    if speedEnabled then
        applySpeed()
        startSpeedControl()
    else
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then humanoid.WalkSpeed = defaultSpeed end
        end
        if speedConnection then speedConnection:Disconnect() speedConnection = nil end
    end
end

-- ================= PART 4: NO CLIP SYSTEM =================
local function applyNoClip()
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not noClipEnabled
        end
    end
end

local function startNoClip()
    if noClipConnection then noClipConnection:Disconnect() end
    noClipConnection = RunService.RenderStepped:Connect(function()
        if noClipEnabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function toggleNoClip()
    noClipEnabled = not noClipEnabled
    if noClipEnabled then
        applyNoClip()
        startNoClip()
    else
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        if noClipConnection then noClipConnection:Disconnect() noClipConnection = nil end
    end
end

-- ================= PART 5: FLY MODE (FIXED - WORKING) =================
local function setupFly()
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Hapus objek lama
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    
    -- Simpan gravity asli
    if originalGravity == nil then
        originalGravity = workspace.Gravity
    end
    
    -- Matikan gravity
    workspace.Gravity = 0
    
    -- Buat BodyVelocity untuk kontrol gerakan
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 100000
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = rootPart
    
    -- Buat BodyGyro untuk menjaga orientasi
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 100000
    flyBodyGyro.CFrame = rootPart.CFrame
    flyBodyGyro.Parent = rootPart
    
    -- Set humanoid state
    humanoid.PlatformStand = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

local function cleanupFly()
    local character = LocalPlayer.Character
    
    -- Kembalikan gravity
    if originalGravity then
        workspace.Gravity = originalGravity
    end
    
    -- Hapus objek fly
    if flyBodyVelocity then 
        flyBodyVelocity:Destroy() 
        flyBodyVelocity = nil 
    end
    if flyBodyGyro then 
        flyBodyGyro:Destroy() 
        flyBodyGyro = nil 
    end
    
    -- Reset humanoid
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

local function updateFlyMovement()
    if not flyEnabled or not LocalPlayer.Character then return end
    
    local character = LocalPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart or not flyBodyVelocity then return end
    
    -- Ambil arah gerakan dari analog (MoveDirection)
    local moveDirection = humanoid.MoveDirection
    
    -- Hitung velocity berdasarkan arah dan kecepatan
    local velocity = Vector3.new(0, 0, 0)
    
    if moveDirection.Magnitude > 0 then
        -- Gerakan horizontal (depan, belakang, kanan, kiri)
        velocity = moveDirection * flySpeed
    end
    
    -- Kontrol vertikal (Space = naik, Ctrl/C = turun)
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        velocity = velocity + Vector3.new(0, flySpeed, 0)
    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
        velocity = velocity + Vector3.new(0, -flySpeed, 0)
    end
    
    -- Terapkan velocity
    flyBodyVelocity.Velocity = velocity
    
    -- Update orientasi agar menghadap arah gerakan
    if moveDirection.Magnitude > 0.1 then
        local lookCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + moveDirection)
        flyBodyGyro.CFrame = lookCFrame
    end
end

local function startFlyLoop()
    if flyConnection then flyConnection:Disconnect() end
    flyConnection = RunService.RenderStepped:Connect(function()
        updateFlyMovement()
    end)
end

local function setFlySpeed(value)
    flySpeed = math.clamp(value, 10, 500)
    savedData.flySpeed = flySpeed
    saveData()
end

local function toggleFly()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        setupFly()
        startFlyLoop()
    else
        cleanupFly()
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    end
end

-- ================= PART 6: ANTI STUN SYSTEM =================
local function startAntiStun()
    if antiStunConnection then antiStunConnection:Disconnect() end
    antiStunConnection = RunService.RenderStepped:Connect(function()
        if not antiStunEnabled then return end
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
            if speedEnabled and humanoid.WalkSpeed ~= currentSpeed then
                humanoid.WalkSpeed = currentSpeed
            end
        end
    end)
end

local function toggleAntiStun()
    antiStunEnabled = not antiStunEnabled
    if antiStunEnabled then
        startAntiStun()
    else
        if antiStunConnection then antiStunConnection:Disconnect() antiStunConnection = nil end
    end
end

-- ================= PART 7: ESP SYSTEM =================
local function createESP(player)
    if not espEnabled then return end
    if player == LocalPlayer then return end
    
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if espObjects[player] then
        pcall(function()
            if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
            if espObjects[player].highlight then espObjects[player].highlight:Destroy() end
            if espObjects[player].connection then espObjects[player].connection:Disconnect() end
        end)
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(0, 100, 0, 28)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    
    local bg = Instance.new("Frame")
    bg.Parent = billboard
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = billboard
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    nameLabel.TextSize = 9
    nameLabel.Font = Enum.Font.GothamBold
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Parent = billboard
    distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 7
    
    billboard.Parent = humanoidRootPart
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_" .. player.Name
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 215, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 215, 0)
    highlight.OutlineTransparency = 0.4
    highlight.Parent = character
    
    espObjects[player] = {
        billboard = billboard,
        highlight = highlight,
        distanceLabel = distanceLabel,
        nameLabel = nameLabel
    }
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not espEnabled or not player.Parent or not LocalPlayer.Character then
            if connection then connection:Disconnect() end
            return
        end
        
        local char = LocalPlayer.Character
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        
        if rootPart and humanoidRootPart and humanoidRootPart.Parent then
            local distance = (humanoidRootPart.Position - rootPart.Position).Magnitude
            distanceLabel.Text = string.format("%.0f", distance)
            
            if distance < 50 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            elseif distance < 150 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            else
                nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            end
        end
    end)
    
    espObjects[player].connection = connection
end

local function removeESP(player)
    if espObjects[player] then
        pcall(function()
            if espObjects[player].billboard then espObjects[player].billboard:Destroy() end
            if espObjects[player].highlight then espObjects[player].highlight:Destroy() end
            if espObjects[player].connection then espObjects[player].connection:Disconnect() end
        end)
        espObjects[player] = nil
    end
end

local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then createESP(player) end
        end
    else
        for _, player in pairs(Players:GetPlayers()) do removeESP(player) end
    end
end

-- ================= PART 8: SPECTATOR SYSTEM =================
local function stopSpectating()
    if not isSpectating then return end
    isSpectating = false
    currentSpectateTarget = nil
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            camera.CameraSubject = humanoid
            humanoid.AutoRotate = true
            humanoid.PlatformStand = false
        end
    end
end

local function startSpectating(player)
    if not player or not player.Character then return end
    if isSpectating then stopSpectating() end
    currentSpectateTarget = player
    isSpectating = true
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then camera.CameraSubject = humanoid end
    if LocalPlayer.Character then
        local localHumanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if localHumanoid then
            localHumanoid.AutoRotate = false
            localHumanoid.PlatformStand = true
        end
    end
end

local function getPlayerList()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(players, player) end
    end
    return players
end

-- ================= PART 9: TELEPORT TO PLAYER =================
local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end
    if isSpectating then stopSpectating() end
    local targetPos = targetRoot.Position + Vector3.new(0, 3, 0)
    rootPart.CFrame = CFrame.new(targetPos)
    humanoid:MoveTo(targetPos)
    return true
end

-- ================= PART 10: POINT SYSTEM =================
local function saveCurrentPoint(pointName)
    if not LocalPlayer.Character then return false end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local position = rootPart.Position
    table.insert(savedData.points, {
        name = pointName,
        x = position.X,
        y = position.Y,
        z = position.Z,
        time = os.date("%H:%M")
    })
    saveData()
    return true
end

local function teleportToPoint(index)
    if not savedData.points[index] then return false end
    if isSpectating then stopSpectating() end
    local point = savedData.points[index]
    local targetPos = Vector3.new(point.x, point.y, point.z)
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end
    rootPart.CFrame = CFrame.new(targetPos)
    humanoid:MoveTo(targetPos)
    return true
end

local function deletePoint(index)
    if savedData.points[index] then
        table.remove(savedData.points, index)
        saveData()
        return true
    end
    return false
end

-- ================= PART 11: CHARACTER RESPAWN HANDLER =================
LocalPlayer.CharacterAdded:Connect(function(character)
    wait(0.5)
    if speedEnabled then applySpeed() end
    if noClipEnabled then applyNoClip() end
    if flyEnabled then 
        cleanupFly()
        wait(0.1)
        setupFly()
        startFlyLoop()
    end
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then createESP(player) end
        end
    end
end)

-- ================= PART 12: UI (180x200 MINI) =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkizoHub"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 180, 0, 200)
mainFrame.Position = UDim2.new(0, 5, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 6)
mainCorner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Parent = mainFrame
header.Size = UDim2.new(1, 0, 0, 20)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
header.BorderSizePixel = 0

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 6)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(1, -45, 1, 0)
title.Position = UDim2.new(0, 6, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡SKIZO"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold

local
