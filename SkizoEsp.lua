-- ESP GamePass Script untuk Delta Executor
-- Simpan sebagai file .lua dan jalankan di Delta

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ===== KONFIGURASI =====
local GAMEPASS_ID = 12345678 -- GANTI DENGAN ID GAMEPASS KAMU
-- =======================

-- VARIABLES
local hasGamePass = false
local espEnabled = false
local espObjects = {}
local gamepassChecked = false

-- CEK GAMEPASS (Method untuk executor)
local function checkGamePass()
    -- Method 1: Cek melalui MarketplaceService (jika support)
    local success, result = pcall(function()
        local MarketplaceService = game:GetService("MarketplaceService")
        return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, GAMEPASS_ID)
    end)
    
    if success and result ~= nil then
        hasGamePass = result
        gamepassChecked = true
        return hasGamePass
    end
    
    -- Method 2: Fallback - anggap punya (untuk testing)
    -- HAPUS INI SAAT PRODUCTION!
    hasGamePass = true
    gamepassChecked = true
    return true
end

-- CREATE ESP
local function createESP(player)
    if not espEnabled then return end
    if player == LocalPlayer then return end
    
    -- Tunggu character
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
    end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Hapus ESP lama jika ada
    if espObjects[player] then
        if espObjects[player].billboard then
            espObjects[player].billboard:Destroy()
        end
        if espObjects[player].highlight then
            espObjects[player].highlight:Destroy()
        end
    end
    
    -- Billboard untuk nama dan jarak
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    
    -- Nama Player
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Parent = billboard
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    
    -- Jarak
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Parent = billboard
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "Distance: 0m"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 12
    distanceLabel.Font = Enum.Font.Gotham
    
    billboard.Parent = humanoidRootPart
    
    -- Highlight effect
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_" .. player.Name
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.3
    highlight.Parent = character
    
    espObjects[player] = {
        billboard = billboard,
        highlight = highlight,
        character = character
    }
    
    -- Update jarak setiap frame
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
            distanceLabel.Text = string.format("Distance: %.1fm", distance)
            
            -- Warna berdasarkan jarak
            if distance < 30 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
            elseif distance < 100 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                highlight.FillColor = Color3.fromRGB(255, 100, 0)
            else
                nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
            end
        end
    end)
    
    espObjects[player].connection = connection
end

-- HAPUS ESP
local function removeESP(player)
    if espObjects[player] then
        if espObjects[player].billboard then
            pcall(function() espObjects[player].billboard:Destroy() end)
        end
        if espObjects[player].highlight then
            pcall(function() espObjects[player].highlight:Destroy() end)
        end
        if espObjects[player].connection then
            pcall(function() espObjects[player].connection:Disconnect() end)
        end
        espObjects[player] = nil
    end
end

-- TOGGLE ESP
local function toggleESP()
    if not gamepassChecked then
        checkGamePass()
    end
    
    if not hasGamePass then
        print("⚠️ Kamu tidak memiliki GamePass!")
        return
    end
    
    espEnabled = not espEnabled
    
    if espEnabled then
        print("✅ ESP ENABLED")
        -- Buat ESP untuk semua player
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
    else
        print("❌ ESP DISABLED")
        -- Hapus semua ESP
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
    end
end

-- BUAT GUI SEDERHANA (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_GUI"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 260, 0, 180)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Parent = mainFrame
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

-- Title Text
local titleText = Instance.new("TextLabel")
titleText.Parent = titleBar
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "ESP PLAYER"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = titleBar
minimizeBtn.Size = UDim2.new(0, 30, 1, 0)
minimizeBtn.Position = UDim2.new(1, -65, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 20

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = titleBar
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -32, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

-- Content Frame
local contentFrame = Instance.new("Frame")
contentFrame.Parent = mainFrame
contentFrame.Size = UDim2.new(1, 0, 1, -35)
contentFrame.Position = UDim2.new(0, 0, 0, 35)
contentFrame.BackgroundTransparency = 1

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = contentFrame
statusLabel.Size = UDim2.new(1, -20, 0, 35)
statusLabel.Position = UDim2.new(0, 10, 0, 10)
statusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
statusLabel.BackgroundTransparency = 0.3
statusLabel.BorderSizePixel = 0
statusLabel.Text = "Status: Checking GamePass..."
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 13

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = contentFrame
toggleBtn.Size = UDim2.new(0, 120, 0, 40)
toggleBtn.Position = UDim2.new(0.5, -60, 0, 55)
toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "ENABLE ESP"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

-- Info Label
local infoLabel = Instance.new("TextLabel")
infoLabel.Parent = contentFrame
infoLabel.Size = UDim2.new(1, -20, 0, 25)
infoLabel.Position = UDim2.new(0, 10, 0, 105)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "ESP: OFF"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.TextSize = 11

-- Fungsi untuk update UI
local function updateUI()
    if hasGamePass then
        statusLabel.Text = "✓ GamePass Owned!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        toggleBtn.Visible = true
    else
        statusLabel.Text = "✗ GamePass NOT Owned"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        toggleBtn.Visible = false
        infoLabel.Text = "Buy GamePass to use ESP"
    end
    
    if espEnabled then
        toggleBtn.Text = "DISABLE ESP"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        infoLabel.Text = "ESP: ON"
        infoLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        toggleBtn.Text = "ENABLE ESP"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        infoLabel.Text = "ESP: OFF"
        infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- Button Functions
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 260, 0, 35)
        contentFrame.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 260, 0, 180)
        contentFrame.Visible = true
        minimizeBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if espEnabled then
        toggleESP()
    end
    screenGui:Destroy()
    print("🔴 GUI Closed")
end)

toggleBtn.MouseButton1Click:Connect(function()
    toggleESP()
    updateUI()
end)

-- Draggable
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Event Handlers untuk player join/leave
Players.PlayerAdded:Connect(function(player)
    if espEnabled and hasGamePass and player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(1)
            createESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Inisialisasi
checkGamePass()
wait(1)
updateUI()

print("✅ ESP Script Loaded!")
print("🎮 GamePass ID: " .. GAMEPASS_ID)
print("💡 Status: " .. (hasGamePass and "Owned" or "Not Owned"))

-- Loop untuk update status
while wait(2) do
    if not gamepassChecked then
        checkGamePass()
        updateUI()
    end
end
local canvasHeight = 0
    
    for i, point in ipairs(savedPoints) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Parent = pointsList
        itemFrame.Size = UDim2.new(1, -10, 0, 70)
        itemFrame.Position = UDim2.new(0, 5, 0, canvasHeight)
        itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        itemFrame.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = itemFrame
        
        local pointName = Instance.new("TextLabel")
        pointName.Parent = itemFrame
        pointName.Size = UDim2.new(1, -80, 0, 25)
        pointName.Position = UDim2.new(0, 10, 0, 5)
        pointName.BackgroundTransparency = 1
        pointName.Text = point.name
        pointName.TextColor3 = Color3.fromRGB(255, 200, 100)
        pointName.TextSize = 14
        pointName.TextXAlignment = Enum.TextXAlignment.Left
        pointName.Font = Enum.Font.GothamBold
        
        local pointPos = Instance.new("TextLabel")
        pointPos.Parent = itemFrame
        pointPos.Size = UDim2.new(1, -80, 0, 20)
        pointPos.Position = UDim2.new(0, 10, 0, 32)
        pointPos.BackgroundTransparency = 1
        pointPos.Text = string.format("📍 (%.0f, %.0f, %.0f)", point.position.x, point.position.y, point.position.z)
        pointPos.TextColor3 = Color3.fromRGB(150, 150, 170)
        pointPos.TextSize = 10
        pointPos.TextXAlignment = Enum.TextXAlignment.Left
        pointPos.Font = Enum.Font.Gotham
        
        local pointTime = Instance.new("TextLabel")
        pointTime.Parent = itemFrame
        pointTime.Size = UDim2.new(1, -80, 0, 15)
        pointTime.Position = UDim2.new(0, 10, 0, 52)
        pointTime.BackgroundTransparency = 1
        pointTime.Text = point.timestamp
        pointTime.TextColor3 = Color3.fromRGB(120, 120, 140)
        pointTime.TextSize = 9
        pointTime.TextXAlignment = Enum.TextXAlignment.Left
        pointTime.Font = Enum.Font.Gotham
        
        local teleportBtn = Instance.new("TextButton")
        teleportBtn.Parent = itemFrame
        teleportBtn.Size = UDim2.new(0, 55, 0, 30)
        teleportBtn.Position = UDim2.new(1, -65, 0, 8)
        teleportBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        teleportBtn.BorderSizePixel = 0
        teleportBtn.Text = "✨ TP"
        teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        teleportBtn.TextSize = 12
        teleportBtn.Font = Enum.Font.GothamBold
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 6)
        tpCorner.Parent = teleportBtn
        
        teleportBtn.MouseButton1Click:Connect(function()
            teleportToPoint(i)
        end)
        
        local deleteBtn = Instance.new("TextButton")
        deleteBtn.Parent = itemFrame
        deleteBtn.Size = UDim2.new(0, 55, 0, 30)
        deleteBtn.Position = UDim2.new(1, -65, 0, 42)
        deleteBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        deleteBtn.BorderSizePixel = 0
        deleteBtn.Text = "🗑️"
        deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteBtn.TextSize = 14
        
        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(0, 6)
        delCorner.Parent = deleteBtn
        
        deleteBtn.MouseButton1Click:Connect(function()
            deletePoint(i)
            refreshPointsList()
        end)
        
        canvasHeight = canvasHeight + 80
    end
    
    pointsList.CanvasSize = UDim2.new(0, 0, 0, canvasHeight + 10)
end

-- Tab switching
espTab.MouseButton1Click:Connect(function()
    espTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    pointsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    espTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    pointsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    espPanel.Visible = true
    pointsPanel.Visible = false
end)

pointsTab.MouseButton1Click:Connect(function()
    espTab.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    pointsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    espTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    pointsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    espPanel.Visible = false
    pointsPanel.Visible = true
    refreshPointsList()
end)

-- ESP Toggle function
espToggle.MouseButton1Click:Connect(function()
    toggleESP()
    if espEnabled then
        espToggle.Text = "🔴 DISABLE ESP"
        espToggle.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        espStatus.Text = "Status: ● ENABLED"
        espStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        espToggle.Text = "🟢 ENABLE ESP"
        espToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        espStatus.Text = "Status: ● DISABLED"
        espStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- Set Point function
setPointBtn.MouseButton1Click:Connect(function()
    local pointName = pointNameInput.Text
    if pointName == "" then
        pointName = "Point " .. (#savedPoints + 1)
    end
    
    if saveCurrentPoint(pointName) then
        pointNameInput.Text = ""
        refreshPointsList()
        
        -- Animasi feedback
        local originalColor = setPointBtn.BackgroundColor3
        setPointBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        wait(0.2)
        setPointBtn.BackgroundColor3 = originalColor
    end
end)

-- Minimize/Maximize
local minimized = false
local originalSize = mainFrame.Size

minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 340, 0, 60)
        container.Visible = false
        tabFrame.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = originalSize
        container.Visible = true
        tabFrame.Visible = true
        minimizeBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    if espEnabled then
        toggleESP()
    end
    screenGui:Destroy()
    print("🔴 GUI Closed")
end)

-- DRAGGABLE UI
local dragging = false
local dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDrag(input)
    end
end)

-- Event Handlers untuk player join/leave
Players.PlayerAdded:Connect(function(player)
    if espEnabled and player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(0.5)
            createESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Inisialisasi
loadPoints()
refreshPointsList()

print("=" .. string.rep("=", 40))
print("✨ SKIZO HUB LOADED SUCCESSFULLY!")
print("📁 Save file: " .. fileName)
print("📍 Saved points: " .. #savedPoints)
print("🎮 ESP: Disabled (Click ENABLE to start)")
print("💡 Drag the header to move the UI")
print("=" .. string.rep("=", 40))

-- Auto-refresh points list setiap 5 detik
spawn(function()
    while wait(5) do
        if pointsPanel.Visible then
            refreshPointsList()
        end
    end
end)
