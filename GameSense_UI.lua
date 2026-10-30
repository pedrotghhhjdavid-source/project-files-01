-- GameSense-style UI (visual only - no real features)
-- Press INSERT to toggle the menu

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Colors (GameSense palette)
local Colors = {
    Background = Color3.fromRGB(12, 12, 12),
    Panel = Color3.fromRGB(18, 18, 18),
    PanelBorder = Color3.fromRGB(35, 35, 35),
    Sidebar = Color3.fromRGB(10, 10, 10),
    Header = Color3.fromRGB(170, 170, 170),
    Text = Color3.fromRGB(200, 200, 200),
    TextDim = Color3.fromRGB(140, 140, 140),
    Accent = Color3.fromRGB(220, 40, 140),      -- Magenta intenso
    AccentDark = Color3.fromRGB(160, 25, 100),
    SliderBg = Color3.fromRGB(30, 30, 30),
    CheckboxOff = Color3.fromRGB(40, 40, 40),
    Button = Color3.fromRGB(28, 28, 28),
    ButtonHover = Color3.fromRGB(40, 40, 40),
}

-- Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GameSenseUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 620, 0, 480)
Main.Position = UDim2.new(0.5, -310, 0.5, -240)
Main.BackgroundColor3 = Colors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 45)
MainStroke.Thickness = 1
MainStroke.Parent = Main

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 2)
MainCorner.Parent = Main

-- ========== SIDEBAR ==========
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 52, 1, 0)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Color3.fromRGB(30, 30, 30)
SidebarStroke.Thickness = 1
SidebarStroke.Parent = Sidebar

-- Sidebar icons (simple text placeholders that look clean)
local iconData = {
    {symbol = "👤", name = "Player"},
    {symbol = "🎯", name = "Aim"},
    {symbol = "☀", name = "Visuals"},
    {symbol = "⚙", name = "Misc"},
    {symbol = "🔪", name = "Rage"},
    {symbol = "👤", name = "Players"},
}

local selectedTab = 4 -- Misc selected by default (like the image)

local function createSidebarIcon(index, data)
    local btn = Instance.new("TextButton")
    btn.Name = data.name
    btn.Size = UDim2.new(1, 0, 0, 52)
    btn.Position = UDim2.new(0, 0, 0, (index - 1) * 52)
    btn.BackgroundColor3 = Colors.Sidebar
    btn.BorderSizePixel = 0
    btn.Text = data.symbol
    btn.TextSize = 22
    btn.Font = Enum.Font.Gotham
    btn.TextColor3 = Colors.TextDim
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 28)
    indicator.Position = UDim2.new(0, 0, 0.5, -14)
    indicator.BackgroundColor3 = Colors.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = (index == selectedTab)
    indicator.Parent = btn

    btn.MouseEnter:Connect(function()
        if index ~= selectedTab then
            btn.TextColor3 = Colors.Text
        end
    end)
    btn.MouseLeave:Connect(function()
        if index ~= selectedTab then
            btn.TextColor3 = Colors.TextDim
        end
    end)

    btn.MouseButton1Click:Connect(function()
        selectedTab = index
        for _, child in ipairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                local ind = child:FindFirstChild("Indicator")
                if ind then
                    ind.Visible = (child == btn)
                end
                child.TextColor3 = (child == btn) and Colors.Accent or Colors.TextDim
            end
        end
    end)

    if index == selectedTab then
        btn.TextColor3 = Colors.Accent
    end

    return btn
end

for i, data in ipairs(iconData) do
    createSidebarIcon(i, data)
end

-- ========== CONTENT AREA ==========
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -52, 1, 0)
Content.Position = UDim2.new(0, 52, 0, 0)
Content.BackgroundColor3 = Colors.Background
Content.BorderSizePixel = 0
Content.Parent = Main

-- Two columns
local LeftColumn = Instance.new("ScrollingFrame")
LeftColumn.Name = "LeftColumn"
LeftColumn.Size = UDim2.new(0.5, -8, 1, -16)
LeftColumn.Position = UDim2.new(0, 8, 0, 8)
LeftColumn.BackgroundTransparency = 1
LeftColumn.BorderSizePixel = 0
LeftColumn.ScrollBarThickness = 3
LeftColumn.ScrollBarImageColor3 = Colors.Accent
LeftColumn.CanvasSize = UDim2.new(0, 0, 0, 700)
LeftColumn.Parent = Content

local RightColumn = Instance.new("ScrollingFrame")
RightColumn.Name = "RightColumn"
RightColumn.Size = UDim2.new(0.5, -8, 1, -16)
RightColumn.Position = UDim2.new(0.5, 0, 0, 8)
RightColumn.BackgroundTransparency = 1
RightColumn.BorderSizePixel = 0
RightColumn.ScrollBarThickness = 3
RightColumn.ScrollBarImageColor3 = Colors.Accent
RightColumn.CanvasSize = UDim2.new(0, 0, 0, 500)
RightColumn.Parent = Content

-- Helper: create a panel
local function createPanel(parent, title, height)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 0, height)
    panel.BackgroundColor3 = Colors.Panel
    panel.BorderSizePixel = 0
    panel.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.PanelBorder
    stroke.Thickness = 1
    stroke.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 2)
    corner.Parent = panel

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -12, 0, 22)
    header.Position = UDim2.new(0, 8, 0, 4)
    header.BackgroundTransparency = 1
    header.Text = title
    header.TextColor3 = Colors.Header
    header.TextSize = 13
    header.Font = Enum.Font.GothamMedium
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = panel

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -12, 1, -28)
    content.Position = UDim2.new(0, 6, 0, 26)
    content.BackgroundTransparency = 1
    content.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 3)
    layout.Parent = content

    return panel, content
end

-- Helper: Toggle (square checkbox)
local function createToggle(parent, text, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 20)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 14, 0, 14)
    box.Position = UDim2.new(0, 2, 0.5, -7)
    box.BackgroundColor3 = default and Colors.Accent or Colors.CheckboxOff
    box.BorderSizePixel = 0
    box.Text = ""
    box.AutoButtonColor = false
    box.Parent = frame

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = default and Colors.Accent or Color3.fromRGB(60, 60, 60)
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 1, 0)
    label.Position = UDim2.new(0, 22, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local state = default
    box.MouseButton1Click:Connect(function()
        state = not state
        box.BackgroundColor3 = state and Colors.Accent or Colors.CheckboxOff
        boxStroke.Color = state and Colors.Accent or Color3.fromRGB(60, 60, 60)
    end)

    return frame
end

-- Helper: Slider
local function createSlider(parent, text, min, max, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 0, 14)
    label.Position = UDim2.new(0, 2, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 40, 0, 14)
    valueLabel.Position = UDim2.new(1, -40, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Colors.TextDim
    valueLabel.TextSize = 11
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -4, 0, 6)
    barBg.Position = UDim2.new(0, 2, 0, 18)
    barBg.BackgroundColor3 = Colors.SliderBg
    barBg.BorderSizePixel = 0
    barBg.Parent = frame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 2)
    barCorner.Parent = barBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = fill

    local dragging = false
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    barBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging then
            local rel = math.clamp((Mouse.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel + 0.5)
            valueLabel.Text = tostring(val)
        end
    end)

    return frame
end

-- Helper: Dropdown
local function createDropdown(parent, text, options, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    frame.ClipsDescendants = false

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 14)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 22)
    btn.Position = UDim2.new(0, 2, 0, 16)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.BorderSizePixel = 0
    btn.Text = "  " .. default
    btn.TextColor3 = Colors.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = frame

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(50, 50, 50)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = Colors.TextDim
    arrow.TextSize = 12
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = btn

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -4, 0, #options * 20)
    list.Position = UDim2.new(0, 2, 0, 40)
    list.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 50
    list.Parent = frame

    local listStroke = Instance.new("UIStroke")
    listStroke.Color = Color3.fromRGB(50, 50, 50)
    listStroke.Thickness = 1
    listStroke.Parent = list

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 20)
        optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 20)
        optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        optBtn.BorderSizePixel = 0
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = Colors.Text
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.AutoButtonColor = false
        optBtn.ZIndex = 51
        optBtn.Parent = list

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        end)
        optBtn.MouseButton1Click:Connect(function()
            btn.Text = "  " .. opt
            list.Visible = false
        end)
    end

    btn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
    end)

    return frame
end

-- Helper: Button
local function createButton(parent, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -4, 0, 24)
    btn.BackgroundColor3 = Colors.Button
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.AutoButtonColor = false
    btn.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Thickness = 1
    stroke.Parent = btn

    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Colors.ButtonHover
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Colors.Button
    end)

    return btn
end

-- ========== LEFT COLUMN - Miscellaneous ==========
local miscPanel, miscContent = createPanel(LeftColumn, "Miscellaneous", 620)
miscPanel.Position = UDim2.new(0, 0, 0, 0)

createSlider(miscContent, "Override FOV", 60, 140, 115)
createToggle(miscContent, "Bunny hop", true)
createToggle(miscContent, "Air strafe", true)
createDropdown(miscContent, "Air strafe direction", {"View angles", "Movement keys", "Mouse"}, "View angles")
createSlider(miscContent, "Air strafe smoothing", 0, 100, 0)
createToggle(miscContent, "Z-Hop", false)
createToggle(miscContent, "Pre-speed", false)
createDropdown(miscContent, "Air duck", {"Off", "On", "Always"}, "Off")
createToggle(miscContent, "Knifebot", true)
createToggle(miscContent, "Zeusbot", false)
createToggle(miscContent, "Blockbot", false)
createToggle(miscContent, "Automatic weapons", true)
createSlider(miscContent, "Automatic weapons", 0, 200, 0)
createToggle(miscContent, "Jump at edge", false)
createToggle(miscContent, "Reveal competitive ranks", false)
createToggle(miscContent, "Auto-accept matchmaking", true)
createToggle(miscContent, "Log weapon purchases", true)
createToggle(miscContent, "Log damage dealt", true)
createToggle(miscContent, "Automatic grenade release", false)
createToggle(miscContent, "Fast walk", false)
createToggle(miscContent, "Free look", false)
createButton(miscContent, "Steal player name")

-- ========== RIGHT COLUMN ==========
-- Settings panel
local settingsPanel, settingsContent = createPanel(RightColumn, "Settings", 160)
settingsPanel.Position = UDim2.new(0, 0, 0, 0)

-- Menu key row
local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(1, 0, 0, 20)
keyFrame.BackgroundTransparency = 1
keyFrame.Parent = settingsContent

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(0.6, 0, 1, 0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "Menu key"
keyLabel.TextColor3 = Colors.Text
keyLabel.TextSize = 12
keyLabel.Font = Enum.Font.Gotham
keyLabel.TextXAlignment = Enum.TextXAlignment.Left
keyLabel.Parent = keyFrame

local keyValue = Instance.new("TextLabel")
keyValue.Size = UDim2.new(0.4, -4, 1, 0)
keyValue.Position = UDim2.new(0.6, 0, 0, 0)
keyValue.BackgroundTransparency = 1
keyValue.Text = "INS"
keyValue.TextColor3 = Colors.TextDim
keyValue.TextSize = 12
keyValue.Font = Enum.Font.Gotham
keyValue.TextXAlignment = Enum.TextXAlignment.Right
keyValue.Parent = keyFrame

-- Menu color
local colorFrame = Instance.new("Frame")
colorFrame.Size = UDim2.new(1, 0, 0, 20)
colorFrame.BackgroundTransparency = 1
colorFrame.Parent = settingsContent

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0.7, 0, 1, 0)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Menu color"
colorLabel.TextColor3 = Colors.Text
colorLabel.TextSize = 12
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = colorFrame

local colorBox = Instance.new("Frame")
colorBox.Size = UDim2.new(0, 18, 0, 14)
colorBox.Position = UDim2.new(1, -22, 0.5, -7)
colorBox.BackgroundColor3 = Colors.Accent
colorBox.BorderSizePixel = 0
colorBox.Parent = colorFrame

createToggle(settingsContent, "Anti-untrusted", true)
createToggle(settingsContent, "Hide from OBS", false)
createToggle(settingsContent, "Low FPS warning", false)
createToggle(settingsContent, "Lock menu layout", false)
createToggle(settingsContent, "Trashtalk", false)

-- Other panel
local otherPanel, otherContent = createPanel(RightColumn, "Other", 280)
otherPanel.Position = UDim2.new(0, 0, 0, 170)

createDropdown(otherContent, "", {"Rage", "Legit", "HvH"}, "Rage")

createButton(otherContent, "Load config")
createButton(otherContent, "Save config")
createButton(otherContent, "Reset config")
createButton(otherContent, "Import from clipboard")
createButton(otherContent, "Export to clipboard")
createButton(otherContent, "Reset menu layout")
createButton(otherContent, "Lua script manager")
createButton(otherContent, "Unload")

-- ========== DRAGGING ==========
local dragging = false
local dragStart = nil
local startPos = nil

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relY = input.Position.Y - Main.AbsolutePosition.Y
        if relY < 30 then -- only drag from top area
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ========== TOGGLE MENU (INSERT) ==========
local menuVisible = true
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        Main.Visible = menuVisible
    end
end)

print("[GameSense UI] Loaded - Press INSERT to toggle")
