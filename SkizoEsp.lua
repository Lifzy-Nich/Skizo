-- ============================================
-- SKIZO HUB v4.1 - TOUCH OPTIMIZED
-- ESP | SPEED | NO CLIP | FLY (TOUCH) | ANTI STUN | SPECTATE | POINTS | TP PLAYER
-- OPTIMIZED FOR DELTA EXECUTOR (MOBILE)
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

-- Fly Mode Variables (Touch Optimized)
local flyEnabled = false
local flyConnection = nil
local flySpeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil

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
            print("✅ Loaded data: " .. #savedData.points .. " points")
            currentSpeed = savedData.speed or 50
            flySpeed = savedData.flySpeed or 50
            return
        end
    end
    savedData = {points = {}, speed = 50, flySpeed = 50}
    currentSpeed = 50
    flySpeed = 50
    print("📁 New data file created")
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
    if speedConnection then
        speedConnection:Disconnect()
    end
    
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
    
    if speedEnabled then
        applySpeed()
    end
end

local function toggleSpeed()
    speedEnabled = not speedEnabled
    
    if speedEnabled then
        applySpeed()
        startSpeedControl()
        print("✅ Speed: " .. currentSpeed)
    else
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = defaultSpeed
            end
        end
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        print("❌ Speed OFF")
    end
end

-- ================= PART 4: NO CLIP SYSTEM =================
local function applyNoClip()
    local character = LocalPlayer.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = not noClipEnabled
        end
    end
end

local function startNoClip()
    if noClipConnection then
        noClipConnection:Disconnect()
    end
    
    noClipConnection = RunService.RenderStepped:Connect(function()
        if noClipEnabled and LocalPlayer.Character then
            local character = LocalPlayer.Character
            for _, part in pairs(character:GetDescendants()) do
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
        print("✅ No Clip ON")
    else
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        if noClipConnection then
            noClipConnection:Disconnect()
            noClipConnection = nil
        end
        print("❌ No Clip OFF")
    end
end

-- ================= PART 5: FLY MODE (TOUCH OPTIMIZED) =================
local function createFlyObjects(character)
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Hapus objek lama jika ada
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    
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
    
    -- Matikan gravitasi dan platform stand
    humanoid.PlatformStand = true
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
end

local function destroyFlyObjects()
    if flyBodyVelocity then 
        flyBodyVelocity:Destroy() 
        flyBodyVelocity = nil 
    end
    if flyBodyGyro then 
        flyBodyGyro:Destroy() 
        flyBodyGyro = nil 
    end
end

local function updateFlyMovement()
    if not flyEnabled or not LocalPlayer.Character then return end
    
    local character = LocalPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    -- Ambil arah gerakan dari MoveDirection (analog sentuh)
    local moveDirection = humanoid.MoveDirection
    
    if moveDirection.Magnitude > 0 then
        -- Gerakan horizontal berdasarkan analog
        local velocity = moveDirection * flySpeed
        flyBodyVelocity.Velocity = velocity
    else
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
    
    -- Update orientasi agar menghadap arah gerakan
    if moveDirection.Magnitude > 0.1 then
        local lookCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + moveDirection)
        flyBodyGyro.CFrame = lookCFrame
    end
end

local function startFly()
    if flyConnection then
        flyConnection:Disconnect()
    end
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if flyEnabled and LocalPlayer.Character then
            updateFlyMovement()
        end
    end)
end

local function setFlySpeed(value)
    flySpeed = math.clamp(value, 10, 500)
    savedData.flySpeed = flySpeed
    saveData()
    print("🦅 Fly speed: " .. flySpeed)
end

local function toggleFly()
    flyEnabled = not flyEnabled
    
    if flyEnabled then
        local character = LocalPlayer.Character
        if character then
            createFlyObjects(character)
        end
        startFly()
        print("🦅 FLY MODE ON - Use analog to move")
    else
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.Velocity = Vector3.new(0, 0, 0)
            end
        end
        destroyFlyObjects()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        print("❌ FLY MODE OFF")
    end
end

-- ================= PART 6: ANTI STUN SYSTEM =================
local function startAntiStun()
    if antiStunConnection then
        antiStunConnection:Disconnect()
    end
    
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
        print("🛡️ Anti Stun ON")
    else
        if antiStunConnection then
            antiStunConnection:Disconnect()
            antiStunConnection = nil
        end
        print("❌ Anti Stun OFF")
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
    billboard.Size = UDim2.new(0, 120, 0, 32)
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
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.GothamBold
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Parent = billboard
    distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 8
    
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
        print("✅ ESP ON")
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
    else
        print("❌ ESP OFF")
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
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
    if humanoid then
        camera.CameraSubject = humanoid
    end
    
    if LocalPlayer.Character then
        local localHumanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if localHumanoid then
            localHumanoid.AutoRotate = false
            localHumanoid.PlatformStand = true
        end
    end
    
    print("👁️ Spectating: " .. player.Name)
end

local function getPlayerList()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(players, player)
        end
    end
    return players
end

-- ================= PART 9: TELEPORT TO PLAYER =================
local function teleportToPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        print("❌ Target not found")
        return false
    end
    
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
    
    print("✨ Teleported to: " .. targetPlayer.Name)
    return true
end

-- ================= PART 10: POINT SYSTEM =================
local function saveCurrentPoint(pointName)
    if not LocalPlayer.Character then return false end
    
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local position = rootPart.Position
    local pointData = {
        name = pointName,
        x = position.X,
        y = position.Y,
        z = position.Z,
        time = os.date("%H:%M:%S")
    }
    
    table.insert(savedData.points, pointData)
    saveData()
    print("📍 Saved: " .. pointName)
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
    
    print("✨ Teleported to: " .. point.name)
    return true
end

local function deletePoint(index)
    if savedData.points[index] then
        local pointName = savedData.points[index].name
        table.remove(savedData.points, index)
        saveData()
        print("🗑️ Deleted: " .. pointName)
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
        createFlyObjects(character)
        startFly()
    end
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
    end
end)

-- ================= PART 12: UI CREATION (SMALL SIZE: 180x420) =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkizoHub"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (180x420)
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 180, 0, 420)
mainFrame.Position = UDim2.new(0, 5, 0, 30)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- Header (180x22)
local header = Instance.new("Frame")
header.Parent = mainFrame
header.Size = UDim2.new(1, 0, 0, 22)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
header.BorderSizePixel = 0

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡SKIZO"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 11
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = header
minimizeBtn.Size = UDim2.new(0, 20, 1, 0)
minimizeBtn.Position = UDim2.new(1, -45, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
minimizeBtn.TextSize = 14

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Parent = header
closeBtn.Size = UDim2.new(0, 20, 1, 0)
closeBtn.Position = UDim2.new(1, -23, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
closeBtn.TextSize = 10

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Tab Buttons (5 tabs)
local tabFrame = Instance.new("Frame")
tabFrame.Parent = mainFrame
tabFrame.Size = UDim2.new(1, 0, 0, 28)
tabFrame.Position = UDim2.new(0, 0, 0, 22)
tabFrame.BackgroundTransparency = 1

local tabs = {"ESP", "MOVE", "VIEW", "TP", "PTS"}
local tabButtons = {}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Parent = tabFrame
    btn.Size = UDim2.new(0.2, 0, 1, 0)
    btn.Position = UDim2.new((i-1) * 0.2, 0, 0, 0)
    btn.BackgroundColor3 = i == 1 and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(15, 15, 18)
    btn.BorderSizePixel = 0
    btn.Text = tabName
    btn.TextColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    tabButtons[tabName] = btn
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn
end

-- Content Container
local container = Instance.new("Frame")
container.Parent = mainFrame
container.Size = UDim2.new(1, -10, 1, -60)
container.Position = UDim2.new(0, 5, 0, 52)
container.BackgroundTransparency = 1

-- ================= PART 13: ESP PANEL =================
local espPanel = Instance.new("Frame")
espPanel.Parent = container
espPanel.Size = UDim2.new(1, 0, 1, 0)
espPanel.BackgroundTransparency = 1

local espToggle = Instance.new("TextButton")
espToggle.Parent = espPanel
espToggle.Size = UDim2.new(1, 0, 0, 32)
espToggle.Position = UDim2.new(0, 0, 0, 0)
espToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
espToggle.BorderSizePixel = 0
espToggle.Text = "🔘 ESP"
espToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
espToggle.TextSize = 11
espToggle.Font = Enum.Font.GothamBold

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 6)
espCorner.Parent = espToggle

local espStatus = Instance.new("TextLabel")
espStatus.Parent = espPanel
espStatus.Size = UDim2.new(1, 0, 0, 22)
espStatus.Position = UDim2.new(0, 0, 0, 36)
espStatus.BackgroundTransparency = 1
espStatus.Text = "● OFF"
espStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
espStatus.TextSize = 9

-- ================= PART 14: MOVEMENT PANEL =================
local movementPanel = Instance.new("Frame")
movementPanel.Parent = container
movementPanel.Size = UDim2.new(1, 0, 1, 0)
movementPanel.BackgroundTransparency = 1
movementPanel.Visible = false

-- Speed
local speedToggle = Instance.new("TextButton")
speedToggle.Parent = movementPanel
speedToggle.Size = UDim2.new(1, 0, 0, 30)
speedToggle.Position = UDim2.new(0, 0, 0, 0)
speedToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
speedToggle.BorderSizePixel = 0
speedToggle.Text = "⚡ SPEED"
speedToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
speedToggle.TextSize = 10

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 5)
speedCorner.Parent = speedToggle

local speedVal = Instance.new("TextLabel")
speedVal.Parent = movementPanel
speedVal.Size = UDim2.new(1, 0, 0, 18)
speedVal.Position = UDim2.new(0, 0, 0, 34)
speedVal.BackgroundTransparency = 1
speedVal.Text = "Speed: " .. currentSpeed
speedVal.TextColor3 = Color3.fromRGB(200, 200, 200)
speedVal.TextSize = 8

-- Speed Slider
local speedSliderBg = Instance.new("Frame")
speedSliderBg.Parent = movementPanel
speedSliderBg.Size = UDim2.new(1, 0, 0, 3)
speedSliderBg.Position = UDim2.new(0, 0, 0, 56)
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

-- No Clip
local noClipToggle = Instance.new("TextButton")
noClipToggle.Parent = movementPanel
noClipToggle.Size = UDim2.new(1, 0, 0, 30)
noClipToggle.Position = UDim2.new(0, 0, 0, 68)
noClipToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
noClipToggle.BorderSizePixel = 0
noClipToggle.Text = "🧱 NO CLIP"
noClipToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
noClipToggle.TextSize = 10

local noClipCorner = Instance.new("UICorner")
noClipCorner.CornerRadius = UDim.new(0, 5)
noClipCorner.Parent = noClipToggle

local noClipStatus = Instance.new("TextLabel")
noClipStatus.Parent = movementPanel
noClipStatus.Size = UDim2.new(1, 0, 0, 18)
noClipStatus.Position = UDim2.new(0, 0, 0, 102)
noClipStatus.BackgroundTransparency = 1
noClipStatus.Text = "● OFF"
noClipStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
noClipStatus.TextSize = 8

-- Fly Mode
local flyToggle = Instance.new("TextButton")
flyToggle.Parent = movementPanel
flyToggle.Size = UDim2.new(1, 0, 0, 30)
flyToggle.Position = UDim2.new(0, 0, 0, 126)
flyToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
flyToggle.BorderSizePixel = 0
flyToggle.Text = "🦅 FLY"
flyToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
flyToggle.TextSize = 10

local flyCorner = Instance.new("UICorner")
flyCorner.CornerRadius = UDim.new(0, 5)
flyCorner.Parent = flyToggle

local flySpeedText = Instance.new("TextLabel")
flySpeedText.Parent = movementPanel
flySpeedText.Size = UDim2.new(1, 0, 0, 18)
flySpeedText.Position = UDim2.new(0, 0, 0, 160)
flySpeedText.BackgroundTransparency = 1
flySpeedText.Text = "Fly: " .. flySpeed
flySpeedText.TextColor3 = Color3.fromRGB(200, 200, 200)
flySpeedText.TextSize = 8

-- Fly Speed Slider
local flySliderBg = Instance.new("Frame")
flySliderBg.Parent = movementPanel
flySliderBg.Size = UDim2.new(1, 0, 0, 3)
flySliderBg.Position = UDim2.new(0, 0, 0, 182)
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

-- Anti Stun
local antiStunToggle = Instance.new("TextButton")
antiStunToggle.Parent = movementPanel
antiStunToggle.Size = UDim2.new(1, 0, 0, 30)
antiStunToggle.Position = UDim2.new(0, 0, 0, 194)
antiStunToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
antiStunToggle.BorderSizePixel = 0
antiStunToggle.Text = "🛡️ ANTI STUN"
antiStunToggle.TextColor3 = Color3.fromRGB(255, 215, 0)
antiStunToggle.TextSize = 10

local antiStunCorner = Instance.new("UICorner")
antiStunCorner.CornerRadius = UDim.new(0, 5)
antiStunCorner.Parent = antiStunToggle

local antiStunStatus = Instance.new("TextLabel")
antiStunStatus.Parent = movementPanel
antiStunStatus.Size = UDim2.new(1, 0, 0, 18)
antiStunStatus.Position = UDim2.new(0, 0, 0, 228)
antiStunStatus.BackgroundTransparency = 1
antiStunStatus.Text = "● OFF"
antiStunStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
antiStunStatus.TextSize = 8

-- ================= PART 15: VIEW PANEL (SPECTATOR) =================
local spectatorPanel = Instance.new("Frame")
spectatorPanel.Parent = container
spectatorPanel.Size = UDim2.new(1, 0, 1, 0)
spectatorPanel.BackgroundTransparency = 1
spectatorPanel.Visible = false

local specStatus = Instance.new("Frame")
specStatus.Parent = spectatorPanel
specStatus.Size = UDim2.new(1, 0, 0, 28)
specStatus.Position = UDim2.new(0, 0, 0, 0)
specStatus.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
specStatus.BorderSizePixel = 0

local specStatusCorner = Instance.new("UICorner")
specStatusCorner.CornerRadius = UDim.new(0, 5)
specStatusCorner.Parent = specStatus

local specStatusText = Instance.new("TextLabel")
specStatusText.Parent = specStatus
specStatusText.Size = UDim2.new(1, 0, 1, 0)
specStatusText.BackgroundTransparency = 1
specStatusText.Text = "⚪ Idle"
specStatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
specStatusText.TextSize = 8

local unspectatorBtn = Instance.new("TextButton")
unspectatorBtn.Parent = spectatorPanel
unspectatorBtn.Size = UDim2.new(1, 0, 0, 28)
unspectatorBtn.Position = UDim2.new(0, 0, 0, 32)
unspectatorBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
unspectatorBtn.BorderSizePixel = 0
unspectatorBtn.Text = "⏹️ STOP"
unspectatorBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
unspectatorBtn.TextSize = 9

local unspectatorCorner = Instance.new("UICorner")
unspectatorCorner.CornerRadius = UDim.new(0, 5)
unspectatorCorner.Parent = unspectatorBtn

local playerListTitle = Instance.new("TextLabel")
playerListTitle.Parent = spectatorPanel
playerListTitle.Size = UDim2.new(1, 0, 0, 18)
playerListTitle.Position = UDim2.new(0, 0, 0, 66)
playerListTitle.BackgroundTransparency = 1
playerListTitle.Text = "PLAYERS"
playerListTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
playerListTitle.TextSize = 8

local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Parent = spectatorPanel
playerListScroll.Size = UDim2.new(1, 0, 1, -90)
playerListScroll.Position = UDim2.new(0, 0, 0, 85)
playerListScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
playerListScroll.BackgroundTransparency = 0.5
playerListScroll.BorderSizePixel = 0
playerListScroll.ScrollBarThickness = 2

-- ================= PART 16: TP PLAYER PANEL =================
local tpPanel = Instance.new("Frame")
tpPanel.Parent = container
tpPanel.Size = UDim2.new(1, 0, 1, 0)
tpPanel.BackgroundTransparency = 1
tpPanel.Visible = false

local tpTitle = Instance.new("TextLabel")
tpTitle.Parent = tpPanel
tpTitle.Size = UDim2.new(1, 0, 0, 20)
tpTitle.Position = UDim2.new(0, 0, 0, 0)
tpTitle.BackgroundTransparency = 1
tpTitle.Text = "🎮 TP TO PLAYER"
tpTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
tpTitle.TextSize = 9

local playerListScrollTP = Instance.new("ScrollingFrame")
playerListScrollTP.Parent = tpPanel
playerListScrollTP.Size = UDim2.new(1, 0, 1, -25)
playerListScrollTP.Position = UDim2.new(0, 0, 0, 22)
playerListScrollTP.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
playerListScrollTP.BackgroundTransparency = 0.5
playerListScrollTP.BorderSizePixel = 0
playerListScrollTP.ScrollBarThickness = 2

-- ================= PART 17: POINTS PANEL =================
local pointsPanel = Instance.new("Frame")
pointsPanel.Parent = container
pointsPanel.Size = UDim2.new(1, 0, 1, 0)
pointsPanel.BackgroundTransparency = 1
pointsPanel.Visible = false

local pointInput = Instance.new("TextBox")
pointInput.Parent = pointsPanel
pointInput.Size = UDim2.new(1, 0, 0, 28)
pointInput.Position = UDim2.new(0, 0, 0, 0)
pointInput.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
pointInput.BorderSizePixel = 0
pointInput.PlaceholderText = "Name"
pointInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
pointInput.TextColor3 = Color3.fromRGB(255, 255, 255)
pointInput.TextSize = 9

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = pointInput

local setPointBtn = Instance.new("TextButton")
setPointBtn.Parent = pointsPanel
setPointBtn.Size = UDim2.new(1, 0, 0, 28)
setPointBtn.Position = UDim2.new(0, 0, 0, 32)
setPointBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
setPointBtn.BorderSizePixel = 0
setPointBtn.Text = "📍 SAVE"
setPointBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
setPointBtn.TextSize = 9

local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0, 4)
setCorner.Parent = setPointBtn

local pointsListTitle = Instance.new("TextLabel")
pointsListTitle.Parent = pointsPanel
pointsListTitle.Size = UDim2.new(1, 0, 0, 18)
pointsListTitle.Position = UDim2.new(0, 0, 0, 66)
pointsListTitle.BackgroundTransparency = 1
pointsListTitle.Text = "SAVED"
pointsListTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
pointsListTitle.TextSize = 8

local pointsScroll = Instance.new("ScrollingFrame")
pointsScroll.Parent = pointsPanel
pointsScroll.Size = UDim2.new(1, 0, 1, -90)
pointsScroll.Position = UDim2.new(0, 0, 0, 85)
pointsScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
pointsScroll.BackgroundTransparency = 0.5
pointsScroll.BorderSizePixel = 0
pointsScroll.ScrollBarThickness = 2
-- ================= PART 18: REFRESH FUNCTIONS =================
local function updateSpectatorStatus()
    if isSpectating and currentSpectateTarget then
        specStatusText.Text = "👁️ " .. currentSpectateTarget.Name
        specStatusText.TextColor3 = Color3.fromRGB(255, 215, 0)
    else
        specStatusText.Text = "⚪ Idle"
        specStatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function refreshPlayerList()
    for _, child in pairs(playerListScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local players = getPlayerList()
    local yPos = 2
    
    for i, player in ipairs(players) do
        local item = Instance.new("Frame")
        item.Parent = playerListScroll
        item.Size = UDim2.new(1, -6, 0, 32)
        item.Position = UDim2.new(0, 3, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        item.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 4)
        itemCorner.Parent = item
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = item
        nameLabel.Size = UDim2.new(1, -50, 0, 20)
        nameLabel.Position = UDim2.new(0, 6, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        nameLabel.TextSize = 8
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local viewBtn = Instance.new("TextButton")
        viewBtn.Parent = item
        viewBtn.Size = UDim2.new(0, 40, 0, 24)
        viewBtn.Position = UDim2.new(1, -44, 0, 4)
        viewBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        viewBtn.BorderSizePixel = 0
        viewBtn.Text = "VIEW"
        viewBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        viewBtn.TextSize = 8
        
        local viewCorner = Instance.new("UICorner")
        viewCorner.CornerRadius = UDim.new(0, 4)
        viewCorner.Parent = viewBtn
        
        viewBtn.MouseButton1Click:Connect(function()
            if player.Character then
                startSpectating(player)
                updateSpectatorStatus()
            end
        end)
        
        yPos = yPos + 38
    end
    
    playerListScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

local function refreshPlayerListTP()
    for _, child in pairs(playerListScrollTP:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local players = getPlayerList()
    local yPos = 2
    
    for i, player in ipairs(players) do
        local item = Instance.new("Frame")
        item.Parent = playerListScrollTP
        item.Size = UDim2.new(1, -6, 0, 32)
        item.Position = UDim2.new(0, 3, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        item.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 4)
        itemCorner.Parent = item
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = item
        nameLabel.Size = UDim2.new(1, -50, 0, 20)
        nameLabel.Position = UDim2.new(0, 6, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        nameLabel.TextSize = 8
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Parent = item
        tpBtn.Size = UDim2.new(0, 40, 0, 24)
        tpBtn.Position = UDim2.new(1, -44, 0, 4)
        tpBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        tpBtn.TextSize = 8
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 4)
        tpCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            teleportToPlayer(player)
        end)
        
        yPos = yPos + 38
    end
    
    playerListScrollTP.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

local function refreshPoints()
    for _, child in pairs(pointsScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local yPos = 2
    
    if #savedData.points == 0 then
        local emptyText = Instance.new("TextLabel")
        emptyText.Parent = pointsScroll
        emptyText.Size = UDim2.new(1, 0, 0, 30)
        emptyText.Position = UDim2.new(0, 0, 0, 5)
        emptyText.BackgroundTransparency = 1
        emptyText.Text = "Empty"
        emptyText.TextColor3 = Color3.fromRGB(100, 100, 100)
        emptyText.TextSize = 8
        pointsScroll.CanvasSize = UDim2.new(0, 0, 0, 40)
        return
    end
    
    for i, point in ipairs(savedData.points) do
        local item = Instance.new("Frame")
        item.Parent = pointsScroll
        item.Size = UDim2.new(1, -6, 0, 42)
        item.Position = UDim2.new(0, 3, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        item.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 4)
        itemCorner.Parent = item
        
        local nameText = Instance.new("TextLabel")
        nameText.Parent = item
        nameText.Size = UDim2.new(1, -50, 0, 18)
        nameText.Position = UDim2.new(0, 6, 0, 2)
        nameText.BackgroundTransparency = 1
        nameText.Text = point.name
        nameText.TextColor3 = Color3.fromRGB(255, 215, 0)
        nameText.TextSize = 8
        nameText.TextXAlignment = Enum.TextXAlignment.Left
        
        local posText = Instance.new("TextLabel")
        posText.Parent = item
        posText.Size = UDim2.new(1, -50, 0, 14)
        posText.Position = UDim2.new(0, 6, 0, 20)
        posText.BackgroundTransparency = 1
        posText.Text = string.format("%.0f,%.0f", point.x, point.z)
        posText.TextColor3 = Color3.fromRGB(150, 150, 150)
        posText.TextSize = 7
        posText.TextXAlignment = Enum.TextXAlignment.Left
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Parent = item
        tpBtn.Size = UDim2.new(0, 35, 0, 22)
        tpBtn.Position = UDim2.new(1, -39, 0, 4)
        tpBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        tpBtn.TextSize = 8
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 3)
        tpCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            teleportToPoint(i)
        end)
        
        local delBtn = Instance.new("TextButton")
        delBtn.Parent = item
        delBtn.Size = UDim2.new(0, 35, 0, 22)
        delBtn.Position = UDim2.new(1, -39, 0, 28)
        delBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        delBtn.BorderSizePixel = 0
        delBtn.Text = "DEL"
        delBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
        delBtn.TextSize = 8
        
        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(0, 3)
        delCorner.Parent = delBtn
        
        delBtn.MouseButton1Click:Connect(function()
            deletePoint(i)
            refreshPoints()
        end)
        
        yPos = yPos + 48
    end
    
    pointsScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

-- ================= PART 19: TAB SWITCHING =================
local function switchTab(tabName)
    for name, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = name == tabName and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(15, 15, 18)
        btn.TextColor3 = name == tabName and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 150, 150)
    end
    
    espPanel.Visible = (tabName == "ESP")
    movementPanel.Visible = (tabName == "MOVE")
    spectatorPanel.Visible = (tabName == "VIEW")
    tpPanel.Visible = (tabName == "TP")
    pointsPanel.Visible = (tabName == "PTS")
    
    if tabName == "VIEW" then
        refreshPlayerList()
        updateSpectatorStatus()
    elseif tabName == "TP" then
        refreshPlayerListTP()
    elseif tabName == "PTS" then
        refreshPoints()
    end
end

tabButtons["ESP"].MouseButton1Click:Connect(function() switchTab("ESP") end)
tabButtons["MOVE"].MouseButton1Click:Connect(function() switchTab("MOVE") end)
tabButtons["VIEW"].MouseButton1Click:Connect(function() switchTab("VIEW") end)
tabButtons["TP"].MouseButton1Click:Connect(function() switchTab("TP") end)
tabButtons["PTS"].MouseButton1Click:Connect(function() switchTab("PTS") end)
-- ================= PART 20: BUTTON FUNCTIONS =================
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
        speedToggle.Text = "⚡ SPEED ON"
        speedToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    else
        speedToggle.Text = "⚡ SPEED"
        speedToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

noClipToggle.MouseButton1Click:Connect(function()
    toggleNoClip()
    if noClipEnabled then
        noClipToggle.Text = "🧱 CLIP ON"
        noClipToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        noClipStatus.Text = "● ON"
        noClipStatus.TextColor3 = Color3.fromRGB(255, 215, 0)
    else
        noClipToggle.Text = "🧱 NO CLIP"
        noClipToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        noClipStatus.Text = "● OFF"
        noClipStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

flyToggle.MouseButton1Click:Connect(function()
    toggleFly()
    if flyEnabled then
        flyToggle.Text = "🦅 FLY ON"
        flyToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
    else
        flyToggle.Text = "🦅 FLY"
        flyToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    end
end)

antiStunToggle.MouseButton1Click:Connect(function()
    toggleAntiStun()
    if antiStunEnabled then
        antiStunToggle.Text = "🛡️ STUN ON"
        antiStunToggle.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
        antiStunStatus.Text = "● ON"
        antiStunStatus.TextColor3 = Color3.fromRGB(255, 215, 0)
    else
        antiStunToggle.Text = "🛡️ ANTI STUN"
        antiStunToggle.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        antiStunStatus.Text = "● OFF"
        antiStunStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)

unspectatorBtn.MouseButton1Click:Connect(function()
    if isSpectating then
        stopSpectating()
        updateSpectatorStatus()
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

-- ================= PART 21: SLIDER FUNCTIONS =================
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
    if speedDragging then
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - speedSliderBg.AbsolutePosition.X) / speedSliderBg.AbsoluteSize.X, 0, 1)
            local newSpeed = math.floor(percent * 999 + 1)
            setSpeed(newSpeed)
            speedSlider.Size = UDim2.new(percent, 0, 1, 0)
            speedVal.Text = "Speed: " .. currentSpeed
        end
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
    if flyDragging then
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - flySliderBg.AbsolutePosition.X) / flySliderBg.AbsoluteSize.X, 0, 1)
            local newSpeed = math.floor(percent * 490 + 10)
            setFlySpeed(newSpeed)
            flySlider.Size = UDim2.new(percent, 0, 1, 0)
            flySpeedText.Text = "Fly: " .. flySpeed
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyDragging = false
    end
end)
-- ================= PART 22: MINIMIZE & CLOSE =================
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 180, 0, 22)
        tabFrame.Visible = false
        container.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 180, 0, 420)
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

-- ================= PART 23: DRAGABLE UI =================
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
    if dragging then
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartMouse
            mainFrame.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ================= PART 24: AUTO REFRESH =================
spawn(function()
    while wait(3) do
        if spectatorPanel.Visible then
            refreshPlayerList()
            updateSpectatorStatus()
        end
        if tpPanel.Visible then
            refreshPlayerListTP()
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

-- ================= PART 25: PLAYER HANDLERS =================
Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(0.5)
            createESP(player)
        end)
    end
    if spectatorPanel.Visible then
        wait(0.5)
        refreshPlayerList()
    end
    if tpPanel.Visible then
        wait(0.5)
        refreshPlayerListTP()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
    if currentSpectateTarget == player then
        stopSpectating()
        updateSpectatorStatus()
    end
    if spectatorPanel.Visible then
        refreshPlayerList()
    end
    if tpPanel.Visible then
        refreshPlayerListTP()
    end
end)

-- ================= PART 26: INITIALIZATION =================
loadData()
currentSpeed = savedData.speed or 50
flySpeed = savedData.flySpeed or 50
speedVal.Text = "Speed: " .. currentSpeed
speedSlider.Size = UDim2.new(currentSpeed / 1000, 0, 1, 0)
flySpeedText.Text = "Fly: " .. flySpeed
flySlider.Size = UDim2.new(flySpeed / 500, 0, 1, 0)
refreshPoints()
refreshPlayerList()
refreshPlayerListTP()
updateSpectatorStatus()
switchTab("ESP")

print("=" .. string.rep("=", 40))
print("✨ SKIZO HUB v4.1 - TOUCH OPTIMIZED")
print("📱 UI: 180x420 | Mobile Friendly")
print("")
print("🎮 FEATURES:")
print("   🔍 ESP - Player name & distance")
print("   ⚡ SPEED - 1-1000 (Permanent)")
print("   🧱 NO CLIP - Walk through walls")
print("   🦅 FLY - Use analog to move")
print("   🛡️ ANTI STUN - Immune to stun")
print("   👁️ SPECTATE - View players")
print("   🎮 TP PLAYER - Teleport")
print("   📍 POINTS - Save locations")
print("")
print("🦅 FLY MODE: Use analog stick to move!")
print("👆 Drag header to move UI")
print("=" .. string.rep("=", 40))
