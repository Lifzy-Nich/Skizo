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

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = header
minimizeBtn.Size = UDim2.new(0, 18, 1, 0)
minimizeBtn.Position = UDim2.new(1, -40, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
minimizeBtn.TextSize = 12

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 3)
minCorner.Parent = minimizeBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = header
closeBtn.Size = UDim2.new(0, 18, 1, 0)
closeBtn.Position = UDim2.new(1, -20, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
closeBtn.TextSize = 9

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 3)
closeCorner.Parent = closeBtn

-- Tab Buttons (4 tabs for compact UI)
local tabFrame = Instance.new("Frame")
tabFrame.Parent = mainFrame
tabFrame.Size = UDim2.new(1, 0, 0, 24)
tabFrame.Position = UDim2.new(0, 0, 0, 20)
tabFrame.BackgroundTransparency = 1

local tabs = {"ESP", "FLY", "VIEW", "PTS"}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Parent = tabFrame
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
    btn.BackgroundColor3 = i == 1 and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(15, 15, 18)
    btn.BorderSizePixel = 0
    btn.Text = tabName
    btn.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
    btn.TextSize = 8
    btn.Font = Enum.Font.GothamBold
    tabButtons[tabName] = btn
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
end

-- Content Container
local container = Instance.new("Frame")
container.Parent = mainFrame
container.Size = UDim2.new(1, -8, 1, -54)
container.Position = UDim2.new(0, 4, 0, 46)
container.BackgroundTransparency = 1

-- ================= PART 13: ESP PANEL =================
local espPanel = Instance.new("Frame")
espPanel.Parent = container
espPanel.Size = UDim2.new(1, 0, 1, 0)
espPanel.BackgroundTransparency = 1

local espToggle = Instance.new("TextButton")
espToggle.Parent = espPanel
espToggle.Size = UDim2.new(1, 0, 0, 28)
espToggle.Position = UDim2.new(0, 0, 0, 0)
espToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
espToggle.BorderSizePixel = 0
espToggle.Text = "🔘 ESP"
espToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
espToggle.TextSize = 10
espToggle.Font = Enum.Font.GothamBold

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 4)
espCorner.Parent = espToggle

local espStatus = Instance.new("TextLabel")
espStatus.Parent = espPanel
espStatus.Size = UDim2.new(1, 0, 0, 20)
espStatus.Position = UDim2.new(0, 0, 0, 32)
espStatus.BackgroundTransparency = 1
espStatus.Text = "● OFF"
espStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
espStatus.TextSize = 8

-- ================= PART 14: FLY PANEL =================
local flyPanel = Instance.new("Frame")
flyPanel.Parent = container
flyPanel.Size = UDim2.new(1, 0, 1, 0)
flyPanel.BackgroundTransparency = 1
flyPanel.Visible = false

-- Speed
local speedToggle = Instance.new("TextButton")
speedToggle.Parent = flyPanel
speedToggle.Size = UDim2.new(1, 0, 0, 26)
speedToggle.Position = UDim2.new(0, 0, 0, 0)
speedToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
speedToggle.BorderSizePixel = 0
speedToggle.Text = "⚡ SPEED"
speedToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
speedToggle.TextSize = 9

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 4)
speedCorner.Parent = speedToggle

local speedVal = Instance.new("TextLabel")
speedVal.Parent = flyPanel
speedVal.Size = UDim2.new(1, 0, 0, 14)
speedVal.Position = UDim2.new(0, 0, 0, 28)
speedVal.BackgroundTransparency = 1
speedVal.Text = "Speed: " .. currentSpeed
speedVal.TextColor3 = Color3.fromRGB(200, 200, 200)
speedVal.TextSize = 7

-- Speed Slider
local speedSliderBg = Instance.new("Frame")
speedSliderBg.Parent = flyPanel
speedSliderBg.Size = UDim2.new(1, 0, 0, 2)
speedSliderBg.Position = UDim2.new(0, 0, 0, 44)
speedSliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
speedSliderBg.BorderSizePixel = 0

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = speedSliderBg

local speedSlider = Instance.new("Frame")
speedSlider.Parent = speedSliderBg
speedSlider.Size = UDim2.new(currentSpeed / 1000, 0, 1, 0)
speedSlider.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
speedSlider.BorderSizePixel = 0

-- Fly Mode
local flyToggleBtn = Instance.new("TextButton")
flyToggleBtn.Parent = flyPanel
flyToggleBtn.Size = UDim2.new(1, 0, 0, 26)
flyToggleBtn.Position = UDim2.new(0, 0, 0, 52)
flyToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
flyToggleBtn.BorderSizePixel = 0
flyToggleBtn.Text = "🦅 FLY"
flyToggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
flyToggleBtn.TextSize = 9

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 4)
flyCorner.Parent = flyToggleBtn

local flySpeedText = Instance.new("TextLabel")
flySpeedText.Parent = flyPanel
flySpeedText.Size = UDim2.new(1, 0, 0, 14)
flySpeedText.Position = UDim2.new(0, 0, 0, 80)
flySpeedText.BackgroundTransparency = 1
flySpeedText.Text = "Fly: " .. flySpeed
flySpeedText.TextColor3 = Color3.fromRGB(200, 200, 200)
flySpeedText.TextSize = 7

-- Fly Speed Slider
local flySliderBg = Instance.new("Frame")
flySliderBg.Parent = flyPanel
flySliderBg.Size = UDim2.new(1, 0, 0, 2)
flySliderBg.Position = UDim2.new(0, 0, 0, 96)
flySliderBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
flySliderBg.BorderSizePixel = 0

local flySliderCorner = Instance.new("UICorner")
flySliderCorner.CornerRadius = UDim.new(1, 0)
flySliderCorner.Parent = flySliderBg

local flySlider = Instance.new("Frame")
flySlider.Parent = flySliderBg
flySlider.Size = UDim2.new(flySpeed / 500, 0, 1, 0)
flySlider.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
flySlider.BorderSizePixel = 0

-- No Clip
local noClipToggle = Instance.new("TextButton")
noClipToggle.Parent = flyPanel
noClipToggle.Size = UDim2.new(1, 0, 0, 26)
noClipToggle.Position = UDim2.new(0, 0, 0, 104)
noClipToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
noClipToggle.BorderSizePixel = 0
noClipToggle.Text = "🧱 NO CLIP"
noClipToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
noClipToggle.TextSize = 9

local noClipCorner = Instance.new("UICorner")
noClipCorner.CornerRadius = UDim.new(0, 4)
noClipCorner.Parent = noClipToggle

-- Anti Stun
local antiStunToggle = Instance.new("TextButton")
antiStunToggle.Parent = flyPanel
antiStunToggle.Size = UDim2.new(1, 0, 0, 26)
antiStunToggle.Position = UDim2.new(0, 0, 0, 134)
antiStunToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
antiStunToggle.BorderSizePixel = 0
antiStunToggle.Text = "🛡️ ANTI STUN"
antiStunToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
antiStunToggle.TextSize = 9

local antiStunCorner = Instance.new("UICorner")
antiStunCorner.CornerRadius = UDim.new(0, 4)
antiStunCorner.Parent = antiStunToggle

-- ================= PART 15: VIEW PANEL =================
local viewPanel = Instance.new("Frame")
viewPanel.Parent = container
viewPanel.Size = UDim2.new(1, 0, 1, 0)
viewPanel.BackgroundTransparency = 1
viewPanel.Visible = false

local specStatus = Instance.new("Frame")
specStatus.Parent = viewPanel
specStatus.Size = UDim2.new(1, 0, 0, 24)
specStatus.Position = UDim2.new(0, 0, 0, 0)
specStatus.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
specStatus.BorderSizePixel = 0

local specStatusCorner = Instance.new("UICorner")
specStatusCorner.CornerRadius = UDim.new(0, 4)
specStatusCorner.Parent = specStatus

local specStatusText = Instance.new("TextLabel")
specStatusText.Parent = specStatus
specStatusText.Size = UDim2.new(1, 0, 1, 0)
specStatusText.BackgroundTransparency = 1
specStatusText.Text = "⚪ Idle"
specStatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
specStatusText.TextSize = 7

local unspectatorBtn = Instance.new("TextButton")
unspectatorBtn.Parent = viewPanel
unspectatorBtn.Size = UDim2.new(1, 0, 0, 24)
unspectatorBtn.Position = UDim2.new(0, 0, 0, 28)
unspectatorBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
unspectatorBtn.BorderSizePixel = 0
unspectatorBtn.Text = "⏹️ STOP"
unspectatorBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
unspectatorBtn.TextSize = 8

local unspectatorCorner = Instance.new("UICorner")
unspectatorCorner.CornerRadius = UDim.new(0, 4)
unspectatorCorner.Parent = unspectatorBtn

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Parent = viewPanel
playerScroll.Size = UDim2.new(1, 0, 1, -60)
playerScroll.Position = UDim2.new(0, 0, 0, 56)
playerScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
playerScroll.BackgroundTransparency = 0.5
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 2

-- ================= PART 16: POINTS PANEL =================
local pointsPanel = Instance.new("Frame")
pointsPanel.Parent = container
pointsPanel.Size = UDim2.new(1, 0, 1, 0)
pointsPanel.BackgroundTransparency = 1
pointsPanel.Visible = false

local pointInput = Instance.new("TextBox")
pointInput.Parent = pointsPanel
pointInput.Size = UDim2.new(1, 0, 0, 24)
pointInput.Position = UDim2.new(0, 0, 0, 0)
pointInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
pointInput.BorderSizePixel = 0
pointInput.PlaceholderText = "Name"
pointInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
pointInput.TextColor3 = Color3.fromRGB(255, 255, 255)
pointInput.TextSize = 8

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 3)
inputCorner.Parent = pointInput

local setPointBtn = Instance.new("TextButton")
setPointBtn.Parent = pointsPanel
setPointBtn.Size = UDim2.new(1, 0, 0, 24)
setPointBtn.Position = UDim2.new(0, 0, 0, 28)
setPointBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
setPointBtn.BorderSizePixel = 0
setPointBtn.Text = "📍 SAVE"
setPointBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
setPointBtn.TextSize = 8

local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0, 3)
setCorner.Parent = setPointBtn

local pointsScroll = Instance.new("ScrollingFrame")
pointsScroll.Parent = pointsPanel
pointsScroll.Size = UDim2.new(1, 0, 1, -60)
pointsScroll.Position = UDim2.new(0, 0, 0, 56)
pointsScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
pointsScroll.BackgroundTransparency = 0.5
pointsScroll.BorderSizePixel = 0
pointsScroll.ScrollBarThickness = 2
-- ================= PART 17: REFRESH FUNCTIONS =================
local function refreshPlayerList()
    for _, child in pairs(playerScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local players = getPlayerList()
    local yPos = 2
    
    for i, player in ipairs(players) do
        local item = Instance.new("Frame")
        item.Parent = playerScroll
        item.Size = UDim2.new(1, -4, 0, 28)
        item.Position = UDim2.new(0, 2, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        item.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 3)
        itemCorner.Parent = item
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = item
        nameLabel.Size = UDim2.new(1, -45, 0, 18)
        nameLabel.Position = UDim2.new(0, 4, 0, 5)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        nameLabel.TextSize = 7
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local viewBtn = Instance.new("TextButton")
        viewBtn.Parent = item
        viewBtn.Size = UDim2.new(0, 35, 0, 22)
        viewBtn.Position = UDim2.new(1, -38, 0, 3)
        viewBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        viewBtn.BorderSizePixel = 0
        viewBtn.Text = "VIEW"
        viewBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        viewBtn.TextSize = 7
        
        local viewCorner = Instance.new("UICorner")
        viewCorner.CornerRadius = UDim.new(0, 3)
        viewCorner.Parent = viewBtn
        
        viewBtn.MouseButton1Click:Connect(function()
            if player.Character then
                startSpectating(player)
                if isSpectating then
                    specStatusText.Text = "👁️ " .. player.Name
                    specStatusText.TextColor3 = Color3.fromRGB(255, 215, 0)
                end
            end
        end)
        
        yPos = yPos + 34
    end
    
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

local function refreshPoints()
    for _, child in pairs(pointsScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local yPos = 2
    
    if #savedData.points == 0 then
        local emptyText = Instance.new("TextLabel")
        emptyText.Parent = pointsScroll
        emptyText.Size = UDim2.new(1, 0, 0, 25)
        emptyText.Position = UDim2.new(0, 0, 0, 5)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "Empty"
        emptyText.TextColor3 = Color3.fromRGB(100, 100, 100)
        emptyText.TextSize = 7
        pointsScroll.CanvasSize = UDim2.new(0, 0, 0, 35)
        return
    end
    
    for i, point in ipairs(savedData.points) do
        local item = Instance.new("Frame")
        item.Parent = pointsScroll
        item.Size = UDim2.new(1, -4, 0, 36)
        item.Position = UDim2.new(0, 2, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        item.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 3)
        itemCorner.Parent = item
        
        local nameText = Instance.new("TextLabel")
        nameText.Parent = item
        nameText.Size = UDim2.new(1, -45, 0, 16)
        nameText.Position = UDim2.new(0, 4, 0, 2)
        nameText.BackgroundTransparency = 1
        nameText.Text = point.name
        nameText.TextColor3 = Color3.fromRGB(255, 215, 0)
        nameText.TextSize = 7
        nameText.TextXAlignment = Enum.TextXAlignment.Left
        
        local posText = Instance.new("TextLabel")
        posText.Parent = item
        posText.Size = UDim2.new(1, -45, 0, 12)
        posText.Position = UDim2.new(0, 4, 0, 18)
        posText.BackgroundTransparency = 1
        posText.Text = string.format("%.0f,%.0f", point.x, point.z)
        posText.TextColor3 = Color3.fromRGB(150, 150, 150)
        posText.TextSize = 6
        posText.TextXAlignment = Enum.TextXAlignment.Left
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Parent = item
        tpBtn.Size = UDim2.new(0, 32, 0, 20)
        tpBtn.Position = UDim2.new(1, -35, 0, 3)
        tpBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        tpBtn.TextSize = 7
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 2)
        tpCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            teleportToPoint(i)
        end)
        
        local delBtn = Instance.new("TextButton")
        delBtn.Parent = item
        delBtn.Size = UDim2.new(0, 32, 0, 20)
        delBtn.Position = UDim2.new(1, -35, 0, 25)
        delBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        delBtn.BorderSizePixel = 0
        delBtn.Text = "DEL"
        delBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
        delBtn.TextSize = 7
        
        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(0, 2)
        delCorner.Parent = delBtn
        
        delBtn.MouseButton1Click:Connect(function()
            deletePoint(i)
            refreshPoints()
        end)
        
        yPos = yPos + 42
    end
    
    pointsScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

-- ================= PART 18: TAB SWITCHING =================
local function switchTab(tabName)
    for name, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = name == tabName and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(15, 15, 18)
        btn.TextColor3 = name == tabName and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
    end
    
    espPanel.Visible = (tabName == "ESP")
    flyPanel.Visible = (tabName == "FLY")
    viewPanel.Visible = (tabName == "VIEW")
    pointsPanel.Visible = (tabName == "PTS")
    
    if tabName == "VIEW" then
        refreshPlayerList()
    elseif tabName == "PTS" then
        refreshPoints()
    end
end

tabButtons["ESP"].MouseButton1Click:Connect(function() switchTab("ESP") end)
tabButtons["FLY"].MouseButton1Click:Connect(function() switchTab("FLY") end)
tabButtons["VIEW"].MouseButton1Click:Connect(function() switchTab("VIEW") end)
tabButtons["PTS"].MouseButton1Click:Connect(function() switchTab("PTS") end)

-- ================= PART 19: BUTTON FUNCTIONS =================
espToggle.MouseButton1Click:Connect(function()
    toggleESP()
    if espEnabled then
        espToggle.Text = "🔴 ESP"
        espToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        espStatus.Text = "● ON"
        espStatus.TextColor3 = Color3.fromRGB(255, 215, 0)
    else
        espToggle.Text = "🔘 ESP"
        espToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        espStatus.Text = "● OFF"
        espStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

speedToggle.MouseButton1Click:Connect(function()
    toggleSpeed()
    if speedEnabled then
        speedToggle.Text = "⚡ ON"
        speedToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    else
        speedToggle.Text = "⚡ SPEED"
        speedToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

flyToggleBtn.MouseButton1Click:Connect(function()
    toggleFly()
    if flyEnabled then
        flyToggleBtn.Text = "🦅 ON"
        flyToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    else
        flyToggleBtn.Text = "🦅 FLY"
        flyToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

noClipToggle.MouseButton1Click:Connect(function()
    toggleNoClip()
    if noClipEnabled then
        noClipToggle.Text = "🧱 ON"
        noClipToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    else
        noClipToggle.Text = "🧱 NO CLIP"
        noClipToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

antiStunToggle.MouseButton1Click:Connect(function()
    toggleAntiStun()
    if antiStunEnabled then
        antiStunToggle.Text = "🛡️ ON"
        antiStunToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    else
        antiStunToggle.Text = "🛡️ ANTI STUN"
        antiStunToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

unspectatorBtn.MouseButton1Click:Connect(function()
    if isSpectating then
        stopSpectating()
        specStatusText.Text = "⚪ Idle"
        specStatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
        refreshPlayerList()
    end
end)

setPointBtn.MouseButton1Click:Connect(function()
    local name = pointInput.Text
    if name == "" then name = "P" .. (#savedData.points + 1) end
    if saveCurrentPoint(name) then
        pointInput.Text = ""
        refreshPoints()
        local oldColor = setPointBtn.BackgroundColor3
        setPointBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        wait(0.2)
        setPointBtn.BackgroundColor3 = oldColor
    end
end)
-- ================= PART 20: SLIDER FUNCTIONS =================
local speedDragging = false
speedSliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = true
        local percent = math.clamp((input.Position.X - speedSliderBg.AbsolutePosition.X) / speedSliderBg.AbsoluteSize.X, 0, 1)
        local newSpeed = math.floor(percent * 999 + 1)
        setSpeed(newSpeed)
        speedSlider.Size = UDim2.new(percent, 0, 1, 0)
        speedVal.Text = "Speed: " .. currentSpeed
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if speedDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local percent = math.clamp((input.Position.X - speedSliderBg.AbsolutePosition.X) / speedSliderBg.AbsoluteSize.X, 0, 1)
        local newSpeed = math.floor(percent * 999 + 1)
        setSpeed(newSpeed)
        speedSlider.Size = UDim2.new(percent, 0, 1, 0)
        speedVal.Text = "Speed: " .. currentSpeed
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        speedDragging = false
    end
end)

local flyDragging = false
flySliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyDragging = true
        local percent = math.clamp((input.Position.X - flySliderBg.AbsolutePosition.X) / flySliderBg.AbsoluteSize.X, 0, 1)
        local newSpeed = math.floor(percent * 490 + 10)
        setFlySpeed(newSpeed)
        flySlider.Size = UDim2.new(percent, 0, 1, 0)
        flySpeedText.Text = "Fly: " .. flySpeed
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if flyDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local percent = math.clamp((input.Position.X - flySliderBg.AbsolutePosition.X) / flySliderBg.AbsoluteSize.X, 0, 1)
        local newSpeed = math.floor(percent * 490 + 10)
        setFlySpeed(newSpeed)
        flySlider.Size = UDim2.new(percent, 0, 1, 0)
        flySpeedText.Text = "Fly: " .. flySpeed
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyDragging = false
    end
end)

-- ================= PART 21: MINIMIZE & CLOSE =================
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 180, 0, 20)
        tabFrame.Visible = false
        container.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 180, 0, 200)
        tabFrame.Visible = true
        container.Visible = true
        minimizeBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if espEnabled then toggleESP() end
    if speedEnabled then toggleSpeed() end
    if noClipEnabled then toggleNoClip() end
    if flyEnabled then toggleFly() end
    if antiStunEnabled then toggleAntiStun() end
    if isSpectating then stopSpectating() end
    screenGui:Destroy()
end)

-- ================= PART 22: DRAGABLE UI =================
local dragStartPos, dragStartMouse
local dragging = false

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = mainFrame.Position
        dragStartMouse = input.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMouse
        mainFrame.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ================= PART 23: AUTO REFRESH =================
spawn(function()
    while wait(3) do
        if viewPanel.Visible then
            refreshPlayerList()
        end
    end
end)

spawn(function()
    while wait(5) do
        if pointsPanel.Visible then
            refreshPoints()
        end
    end
end)

-- ================= PART 24: PLAYER HANDLERS =================
Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(0.5)
            createESP(player)
        end)
    end
    if viewPanel.Visible then
        wait(0.5)
        refreshPlayerList()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if currentSpectateTarget == player then
        stopSpectating()
        if viewPanel.Visible then
            specStatusText.Text = "⚪ Idle"
            refreshPlayerList()
        end
    end
    if viewPanel.Visible then refreshPlayerList() end
end)

-- ================= PART 25: INITIALIZATION =================
loadData()
currentSpeed = savedData.speed or 50
flySpeed = savedData.flySpeed or 50
speedVal.Text = "Speed: " .. currentSpeed
speedSlider.Size = UDim2.new(currentSpeed / 1000, 0, 1, 0)
flySpeedText.Text = "Fly: " .. flySpeed
flySlider.Size = UDim2.new(flySpeed / 500, 0, 1, 0)
refreshPoints()
refreshPlayerList()
switchTab("ESP")

print("=" .. string.rep("=", 35))
print("✨ SKIZO HUB v4.2 - FLY FIXED")
print("📱 UI: 180x200 | Ultra Compact")
print("")
print("🦅 FLY MODE:")
print("   • Aktifkan FLY = Karakter bisa terbang")
print("   • Geser analog = Bergerak ke segala arah")
print("   • Space = Naik | Ctrl/C = Turun")
print("   • Matikan FLY = Kembali normal")
print("")
print("🎮 FITUR:")
print("   ESP | SPEED | NO CLIP | FLY | ANTI STUN | SPECTATE | POINTS")
print("👆 Drag header to move UI")
print("=" .. string.rep("=", 35))
