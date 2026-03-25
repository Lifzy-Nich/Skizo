-- ESP+Teleport Script for Delta Executor (Mobile Version)
-- Optimized for mobile/Android executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ===== VARIABLES =====
local espEnabled = false
local espObjects = {}
local savedPoints = {}
local fileName = "Skizo.json"

-- ===== FUNGSI LOAD/SAVE POINTS (Mobile Compatible) =====
local function loadPoints()
    local success, data = pcall(function()
        if isfile and isfile(fileName) then
            return readfile(fileName)
        end
        return nil
    end)
    
    if success and data then
        local decoded = game:GetService("HttpService"):JSONDecode(data)
        if decoded then
            savedPoints = decoded
            print("✅ Loaded " .. #savedPoints .. " points")
            return
        end
    end
    savedPoints = {}
    print("📁 New save file created")
end

local function savePoints()
    local encoded = game:GetService("HttpService"):JSONEncode(savedPoints)
    pcall(function()
        if writefile then
            writefile(fileName, encoded)
            print("💾 Points saved")
        end
    end)
end

-- ===== FUNGSI ESP (Simplified for Mobile) =====
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
    
    -- Billboard sederhana untuk mobile
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(0, 180, 0, 45)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Parent = billboard
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.6
    bg.BorderSizePixel = 0
    
    -- Nama Player
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = billboard
    nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    
    -- Jarak Label
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Parent = billboard
    distanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0 studs"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 11
    distanceLabel.Font = Enum.Font.Gotham
    
    billboard.Parent = humanoidRootPart
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_" .. player.Name
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.4
    highlight.Parent = character
    
    espObjects[player] = {
        billboard = billboard,
        highlight = highlight,
        distanceLabel = distanceLabel,
        nameLabel = nameLabel
    }
    
    -- Update jarak
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
            distanceLabel.Text = string.format("📏 %.0f studs", distance)
            
            if distance < 50 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
            elseif distance < 150 then
                nameLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                highlight.FillColor = Color3.fromRGB(255, 100, 0)
            else
                nameLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                highlight.FillColor = Color3.fromRGB(0, 255, 0)
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
        print("✅ ESP ENABLED")
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createESP(player)
            end
        end
    else
        print("❌ ESP DISABLED")
        for _, player in pairs(Players:GetPlayers()) do
            removeESP(player)
        end
    end
end

-- ===== FUNGSI POINT =====
local function saveCurrentPoint(pointName)
    if not LocalPlayer.Character then 
        print("❌ Character not found")
        return false 
    end
    
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        print("❌ Root part not found")
        return false 
    end
    
    local position = rootPart.Position
    local pointData = {
        name = pointName,
        x = position.X,
        y = position.Y,
        z = position.Z,
        time = os.date("%H:%M:%S")
    }
    
    table.insert(savedPoints, pointData)
    savePoints()
    
    print(string.format("📍 Saved '%s' at (%.0f, %.0f, %.0f)", pointName, position.X, position.Y, position.Z))
    return true
end

local function teleportToPoint(index)
    if not savedPoints[index] then return false end
    
    local point = savedPoints[index]
    local targetPos = Vector3.new(point.x, point.y, point.z)
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return false end
    
    -- Teleport
    rootPart.CFrame = CFrame.new(targetPos)
    humanoid:MoveTo(targetPos)
    
    print(string.format("✨ Teleported to '%s'", point.name))
    return true
end

local function deletePoint(index)
    if savedPoints[index] then
        local pointName = savedPoints[index].name
        table.remove(savedPoints, index)
        savePoints()
        print(string.format("🗑️ Deleted '%s'", pointName))
        return true
    end
    return false
end

-- ===== GUI SEDERHANA UNTUK MOBILE =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkizoHub"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Parent = mainFrame
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
header.BorderSizePixel = 0

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "✨ SKIZO HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = header
minimizeBtn.Size = UDim2.new(0, 30, 1, 0)
minimizeBtn.Position = UDim2.new(1, -70, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 20

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = header
closeBtn.Size = UDim2.new(0, 30, 1, 0)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

-- Tab Buttons
local tabFrame = Instance.new("Frame")
tabFrame.Parent = mainFrame
tabFrame.Size = UDim2.new(1, 0, 0, 40)
tabFrame.Position = UDim2.new(0, 0, 0, 45)
tabFrame.BackgroundTransparency = 1

local espTab = Instance.new("TextButton")
espTab.Parent = tabFrame
espTab.Size = UDim2.new(0.5, 0, 1, 0)
espTab.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
espTab.BorderSizePixel = 0
espTab.Text = "🔍 ESP"
espTab.TextColor3 = Color3.fromRGB(255, 255, 255)
espTab.TextSize = 14

local pointsTab = Instance.new("TextButton")
pointsTab.Parent = tabFrame
pointsTab.Size = UDim2.new(0.5, 0, 1, 0)
pointsTab.Position = UDim2.new(0.5, 0, 0, 0)
pointsTab.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
pointsTab.BorderSizePixel = 0
pointsTab.Text = "📍 POINTS"
pointsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
pointsTab.TextSize = 14

-- Content Container
local container = Instance.new("Frame")
container.Parent = mainFrame
container.Size = UDim2.new(1, -20, 1, -105)
container.Position = UDim2.new(0, 10, 0, 90)
container.BackgroundTransparency = 1

-- ESP Panel
local espPanel = Instance.new("Frame")
espPanel.Parent = container
espPanel.Size = UDim2.new(1, 0, 1, 0)
espPanel.BackgroundTransparency = 1

local espToggle = Instance.new("TextButton")
espToggle.Parent = espPanel
espToggle.Size = UDim2.new(1, 0, 0, 50)
espToggle.Position = UDim2.new(0, 0, 0, 0)
espToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
espToggle.BorderSizePixel = 0
espToggle.Text = "🔘 ENABLE ESP"
espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espToggle.TextSize = 15
espToggle.Font = Enum.Font.GothamBold

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = espToggle

local espStatus = Instance.new("TextLabel")
espStatus.Parent = espPanel
espStatus.Size = UDim2.new(1, 0, 0, 30)
espStatus.Position = UDim2.new(0, 0, 0, 60)
espStatus.BackgroundTransparency = 1
espStatus.Text = "Status: ● DISABLED"
espStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
espStatus.TextSize = 12

local infoBox = Instance.new("Frame")
infoBox.Parent = espPanel
infoBox.Size = UDim2.new(1, 0, 0, 100)
infoBox.Position = UDim2.new(0, 0, 0, 100)
infoBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
infoBox.BackgroundTransparency = 0.5
infoBox.BorderSizePixel = 0

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 8)
infoCorner.Parent = infoBox

local infoText = Instance.new("TextLabel")
infoText.Parent = infoBox
infoText.Size = UDim2.new(1, -10, 1, -10)
infoText.Position = UDim2.new(0, 5, 0, 5)
infoText.BackgroundTransparency = 1
infoText.Text = "📊 ESP INFO\n• Nama & jarak player\n• Warna berdasarkan jarak\n• Highlight otomatis"
infoText.TextColor3 = Color3.fromRGB(170, 170, 190)
infoText.TextSize = 11
infoText.TextWrapped = true

-- Points Panel
local pointsPanel = Instance.new("Frame")
pointsPanel.Parent = container
pointsPanel.Size = UDim2.new(1, 0, 1, 0)
pointsPanel.BackgroundTransparency = 1
pointsPanel.Visible = false

local pointInput = Instance.new("TextBox")
pointInput.Parent = pointsPanel
pointInput.Size = UDim2.new(1, 0, 0, 40)
pointInput.Position = UDim2.new(0, 0, 0, 0)
pointInput.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
pointInput.BorderSizePixel = 0
pointInput.PlaceholderText = "Point name..."
pointInput.TextColor3 = Color3.fromRGB(255, 255, 255)
pointInput.TextSize = 14

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = pointInput

local setPointBtn = Instance.new("TextButton")
setPointBtn.Parent = pointsPanel
setPointBtn.Size = UDim2.new(1, 0, 0, 45)
setPointBtn.Position = UDim2.new(0, 0, 0, 50)
setPointBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
setPointBtn.BorderSizePixel = 0
setPointBtn.Text = "📍 SET CURRENT POSITION"
setPointBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
setPointBtn.TextSize = 13

local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0, 8)
setCorner.Parent = setPointBtn

-- Points List
local pointsScroll = Instance.new("ScrollingFrame")
pointsScroll.Parent = pointsPanel
pointsScroll.Size = UDim2.new(1, 0, 0, 220)
pointsScroll.Position = UDim2.new(0, 0, 0, 105)
pointsScroll.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
pointsScroll.BackgroundTransparency = 0.5
pointsScroll.BorderSizePixel = 0
pointsScroll.ScrollBarThickness = 4

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 8)
scrollCorner.Parent = pointsScroll

-- Function refresh points
local function refreshPoints()
    for _, child in pairs(pointsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    local yPos = 5
    
    for i, point in ipairs(savedPoints) do
        local item = Instance.new("Frame")
        item.Parent = pointsScroll
        item.Size = UDim2.new(1, -10, 0, 65)
        item.Position = UDim2.new(0, 5, 0, yPos)
        item.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        item.BorderSizePixel = 0
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 6)
        itemCorner.Parent = item
        
        local nameText = Instance.new("TextLabel")
        nameText.Parent = item
        nameText.Size = UDim2.new(1, -80, 0, 25)
        nameText.Position = UDim2.new(0, 8, 0, 5)
        nameText.BackgroundTransparency = 1
        nameText.Text = point.name
        nameText.TextColor3 = Color3.fromRGB(255, 200, 100)
        nameText.TextSize = 13
        nameText.TextXAlignment = Enum.TextXAlignment.Left
        nameText.Font = Enum.Font.GothamBold
        
        local posText = Instance.new("TextLabel")
        posText.Parent = item
        posText.Size = UDim2.new(1, -80, 0, 20)
        posText.Position = UDim2.new(0, 8, 0, 30)
        posText.BackgroundTransparency = 1
        posText.Text = string.format("X:%.0f Y:%.0f Z:%.0f", point.x, point.y, point.z)
        posText.TextColor3 = Color3.fromRGB(150, 150, 170)
        posText.TextSize = 10
        posText.TextXAlignment = Enum.TextXAlignment.Left
        
        local timeText = Instance.new("TextLabel")
        timeText.Parent = item
        timeText.Size = UDim2.new(1, -80, 0, 15)
        timeText.Position = UDim2.new(0, 8, 0, 48)
        timeText.BackgroundTransparency = 1
        timeText.Text = point.time
        timeText.TextColor3 = Color3.fromRGB(120, 120, 140)
        timeText.TextSize = 9
        timeText.TextXAlignment = Enum.TextXAlignment.Left
        
        local tpBtn = Instance.new("TextButton")
        tpBtn.Parent = item
        tpBtn.Size = UDim2.new(0, 55, 0, 28)
        tpBtn.Position = UDim2.new(1, -62, 0, 8)
        tpBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.TextSize = 12
        
        local tpCorner = Instance.new("UICorner")
        tpCorner.CornerRadius = UDim.new(0, 5)
        tpCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            teleportToPoint(i)
        end)
        
        local delBtn = Instance.new("TextButton")
        delBtn.Parent = item
        delBtn.Size = UDim2.new(0, 55, 0, 28)
        delBtn.Position = UDim2.new(1, -62, 0, 40)
        delBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        delBtn.BorderSizePixel = 0
        delBtn.Text = "DEL"
        delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        delBtn.TextSize = 12
        
        local delCorner = Instance.new("UICorner")
        delCorner.CornerRadius = UDim.new(0, 5)
        delCorner.Parent = delBtn
        
        delBtn.MouseButton1Click:Connect(function()
            deletePoint(i)
            refreshPoints()
        end)
        
        yPos = yPos + 72
    end
    
    pointsScroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 5)
end

-- Tab switching
espTab.MouseButton1Click:Connect(function()
    espTab.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    pointsTab.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    espTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    pointsTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    espPanel.Visible = true
    pointsPanel.Visible = false
end)

pointsTab.MouseButton1Click:Connect(function()
    espTab.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    pointsTab.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
    espTab.TextColor3 = Color3.fromRGB(200, 200, 200)
    pointsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    espPanel.Visible = false
    pointsPanel.Visible = true
    refreshPoints()
end)

-- ESP Toggle
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

-- Set Point
setPointBtn.MouseButton1Click:Connect(function()
    local name = pointInput.Text
    if name == "" then
        name = "Point " .. (#savedPoints + 1)
    end
    
    if saveCurrentPoint(name) then
        pointInput.Text = ""
        refreshPoints()
        
        local oldColor = setPointBtn.BackgroundColor3
        setPointBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        wait(0.2)
        setPointBtn.BackgroundColor3 = oldColor
    end
end)

-- Minimize/Maximize
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 300, 0, 45)
        tabFrame.Visible = false
        container.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, 300, 0, 400)
        tabFrame.Visible = true
        container.Visible = true
        minimizeBtn.Text = "−"
    end
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    if espEnabled then
        toggleESP()
    end
    screenGui:Destroy()
    print("🔴 GUI Closed")
end)

-- DRAGABLE UI (Mobile compatible)
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

-- Player join/leave
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

-- INISIALISASI
loadPoints()
refreshPoints()

print("=" .. string.rep("=", 35))
print("✨ SKIZO HUB LOADED!")
print("📱 Mobile Version - Optimized")
print("📍 Points: " .. #savedPoints)
print("🎮 Tap 'ENABLE ESP' to start")
print("👆 Drag header to move UI")
print("=" .. string.rep("=", 35))
