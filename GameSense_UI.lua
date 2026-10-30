--[[
    GameSense-style UI
    Themes · Animations · Preferences · Detailed icons · Notifications
    Press INSERT to toggle the menu
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ─────────────────────────────────────────────
-- Core utilities
-- ─────────────────────────────────────────────
local function safeCall(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        warn("[GameSense]", tostring(a))
        return false
    end
    return true, a, b, c
end

local function clamp(n, lo, hi)
    return math.max(lo, math.min(hi, n))
end

local function tween(obj, props, duration, style, dir)
    if not obj or not obj.Parent then return nil end
    local info = TweenInfo.new(
        duration or 0.15,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function tweenColor(obj, prop, color, duration)
    if not obj then return nil end
    return tween(obj, { [prop] = color }, duration or 0.12)
end

-- ─────────────────────────────────────────────
-- Theme palettes
-- ─────────────────────────────────────────────
local Themes = {
    GameSense = {
        WindowBg = Color3.fromRGB(8, 8, 8), SidebarBg = Color3.fromRGB(6, 6, 6),
        PanelBg = Color3.fromRGB(14, 14, 14), PanelBorder = Color3.fromRGB(28, 28, 28),
        Header = Color3.fromRGB(165, 165, 165), Text = Color3.fromRGB(195, 195, 195),
        TextDim = Color3.fromRGB(115, 115, 115), Accent = Color3.fromRGB(220, 35, 145),
        AccentDark = Color3.fromRGB(150, 20, 95), SliderTrack = Color3.fromRGB(32, 32, 32),
        CheckboxOff = Color3.fromRGB(38, 38, 38), CheckboxBorder = Color3.fromRGB(55, 55, 55),
        Button = Color3.fromRGB(22, 22, 22), ButtonHover = Color3.fromRGB(32, 32, 32),
        DropdownBg = Color3.fromRGB(20, 20, 20), DropdownBorder = Color3.fromRGB(42, 42, 42),
        IconOff = Color3.fromRGB(95, 95, 95), IconHover = Color3.fromRGB(170, 170, 170),
        Scroll = Color3.fromRGB(220, 35, 145), Stroke = Color3.fromRGB(38, 38, 38),
        SidebarLine = Color3.fromRGB(22, 22, 22), NotifyBg = Color3.fromRGB(18, 18, 18),
    },
    Midnight = {
        WindowBg = Color3.fromRGB(10, 12, 18), SidebarBg = Color3.fromRGB(8, 10, 15),
        PanelBg = Color3.fromRGB(16, 18, 26), PanelBorder = Color3.fromRGB(32, 36, 48),
        Header = Color3.fromRGB(160, 170, 190), Text = Color3.fromRGB(200, 210, 230),
        TextDim = Color3.fromRGB(100, 110, 130), Accent = Color3.fromRGB(80, 140, 255),
        AccentDark = Color3.fromRGB(50, 90, 180), SliderTrack = Color3.fromRGB(28, 32, 42),
        CheckboxOff = Color3.fromRGB(35, 40, 52), CheckboxBorder = Color3.fromRGB(50, 58, 72),
        Button = Color3.fromRGB(20, 24, 34), ButtonHover = Color3.fromRGB(30, 36, 50),
        DropdownBg = Color3.fromRGB(18, 22, 30), DropdownBorder = Color3.fromRGB(40, 48, 62),
        IconOff = Color3.fromRGB(90, 100, 120), IconHover = Color3.fromRGB(160, 180, 210),
        Scroll = Color3.fromRGB(80, 140, 255), Stroke = Color3.fromRGB(40, 48, 62),
        SidebarLine = Color3.fromRGB(24, 28, 38), NotifyBg = Color3.fromRGB(14, 16, 22),
    },
    Crimson = {
        WindowBg = Color3.fromRGB(12, 8, 8), SidebarBg = Color3.fromRGB(10, 6, 6),
        PanelBg = Color3.fromRGB(18, 12, 12), PanelBorder = Color3.fromRGB(40, 28, 28),
        Header = Color3.fromRGB(180, 150, 150), Text = Color3.fromRGB(210, 190, 190),
        TextDim = Color3.fromRGB(130, 100, 100), Accent = Color3.fromRGB(220, 50, 50),
        AccentDark = Color3.fromRGB(160, 30, 30), SliderTrack = Color3.fromRGB(36, 26, 26),
        CheckboxOff = Color3.fromRGB(42, 30, 30), CheckboxBorder = Color3.fromRGB(60, 42, 42),
        Button = Color3.fromRGB(26, 18, 18), ButtonHover = Color3.fromRGB(38, 26, 26),
        DropdownBg = Color3.fromRGB(22, 16, 16), DropdownBorder = Color3.fromRGB(48, 34, 34),
        IconOff = Color3.fromRGB(110, 85, 85), IconHover = Color3.fromRGB(190, 150, 150),
        Scroll = Color3.fromRGB(220, 50, 50), Stroke = Color3.fromRGB(48, 30, 30),
        SidebarLine = Color3.fromRGB(28, 18, 18), NotifyBg = Color3.fromRGB(20, 12, 12),
    },
    Emerald = {
        WindowBg = Color3.fromRGB(8, 12, 10), SidebarBg = Color3.fromRGB(6, 10, 8),
        PanelBg = Color3.fromRGB(12, 18, 15), PanelBorder = Color3.fromRGB(28, 40, 34),
        Header = Color3.fromRGB(150, 180, 165), Text = Color3.fromRGB(190, 215, 200),
        TextDim = Color3.fromRGB(100, 130, 115), Accent = Color3.fromRGB(40, 200, 120),
        AccentDark = Color3.fromRGB(25, 140, 80), SliderTrack = Color3.fromRGB(26, 36, 30),
        CheckboxOff = Color3.fromRGB(32, 42, 36), CheckboxBorder = Color3.fromRGB(48, 62, 54),
        Button = Color3.fromRGB(18, 26, 22), ButtonHover = Color3.fromRGB(28, 40, 34),
        DropdownBg = Color3.fromRGB(16, 24, 20), DropdownBorder = Color3.fromRGB(38, 52, 44),
        IconOff = Color3.fromRGB(85, 110, 95), IconHover = Color3.fromRGB(150, 190, 165),
        Scroll = Color3.fromRGB(40, 200, 120), Stroke = Color3.fromRGB(32, 48, 40),
        SidebarLine = Color3.fromRGB(20, 30, 24), NotifyBg = Color3.fromRGB(12, 18, 14),
    },
}

local currentThemeName = "GameSense"
local C = {}
for k, v in pairs(Themes.GameSense) do C[k] = v end

-- ─────────────────────────────────────────────
-- Preferences (file + memory fallback)
-- ─────────────────────────────────────────────
local Preferences = { theme = "GameSense", menuKey = "Insert", windowPos = nil }
local CONFIG_NAME = "GameSenseUI_Prefs.json"
local sharedEnv = (getgenv and getgenv()) or _G

local function savePreferences()
    Preferences.theme = currentThemeName
    local data = {
        theme = Preferences.theme,
        menuKey = Preferences.menuKey,
        windowPos = Preferences.windowPos,
    }
    sharedEnv.GameSenseUI_Prefs = data
    if writefile then
        safeCall(writefile, CONFIG_NAME, HttpService:JSONEncode(data))
    end
end

local function loadPreferences()
    local data = nil
    if readfile and isfile then
        local ok, content = safeCall(function()
            if isfile(CONFIG_NAME) then return readfile(CONFIG_NAME) end
        end)
        if ok and content then
            local decodeOk, decoded = safeCall(function()
                return HttpService:JSONDecode(content)
            end)
            if decodeOk and type(decoded) == "table" then data = decoded end
        end
    end
    if not data and type(sharedEnv.GameSenseUI_Prefs) == "table" then
        data = sharedEnv.GameSenseUI_Prefs
    end
    if not data then return end
    if data.theme and Themes[data.theme] then
        Preferences.theme = data.theme
        currentThemeName = data.theme
        for k, v in pairs(Themes[data.theme]) do C[k] = v end
    end
    if data.menuKey then Preferences.menuKey = data.menuKey end
    if data.windowPos then Preferences.windowPos = data.windowPos end
end

safeCall(loadPreferences)

-- ─────────────────────────────────────────────
-- Registry & control tracking
-- ─────────────────────────────────────────────
local registry = {}
local sidebarButtons = {}
local controlRefs = {}
local openDropdowns = {}

local function register(obj, prop, key)
    if obj then table.insert(registry, { obj = obj, prop = prop, key = key }) end
end

local function closeAllDropdowns()
    for _, api in ipairs(openDropdowns) do
        if api and api.list then api.list.Visible = false end
    end
end

-- ─────────────────────────────────────────────
-- Root GUI
-- ─────────────────────────────────────────────
local Gui = Instance.new("ScreenGui")
Gui.Name = "GameSense"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
Gui.Parent = game:GetService("CoreGui")

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 598, 0, 462)
Window.Position = UDim2.new(0.5, -299, 0.5, -231)
Window.BackgroundColor3 = C.WindowBg
Window.BorderSizePixel = 0
Window.Active = true
Window.ClipsDescendants = true
Window.Parent = Gui
register(Window, "BackgroundColor3", "WindowBg")

if Preferences.windowPos and Preferences.windowPos.X and Preferences.windowPos.Y then
    Window.Position = UDim2.new(0, Preferences.windowPos.X, 0, Preferences.windowPos.Y)
end

local WindowStroke = Instance.new("UIStroke")
WindowStroke.Color = C.Stroke
WindowStroke.Thickness = 1
WindowStroke.Parent = Window
register(WindowStroke, "Color", "Stroke")

local Rainbow = Instance.new("Frame")
Rainbow.Name = "Rainbow"
Rainbow.Size = UDim2.new(1, 0, 0, 1)
Rainbow.BorderSizePixel = 0
Rainbow.BackgroundColor3 = Color3.fromRGB(180, 80, 200)
Rainbow.Parent = Window

local RainbowGrad = Instance.new("UIGradient")
RainbowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(80, 180, 255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 255, 160)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 220, 80)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 100, 140)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(160, 80, 255)),
})
RainbowGrad.Parent = Rainbow

-- ─────────────────────────────────────────────
-- Notification toast
-- ─────────────────────────────────────────────
local NotifyHolder = Instance.new("Frame")
NotifyHolder.Name = "NotifyHolder"
NotifyHolder.Size = UDim2.new(0, 260, 1, 0)
NotifyHolder.Position = UDim2.new(1, -270, 0, 20)
NotifyHolder.BackgroundTransparency = 1
NotifyHolder.Parent = Gui

local notifyLayout = Instance.new("UIListLayout")
notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifyLayout.Padding = UDim.new(0, 6)
notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifyLayout.Parent = NotifyHolder

local function notify(text, duration)
    duration = duration or 2.5
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = C.NotifyBg or C.PanelBg
    card.BorderSizePixel = 0
    card.BackgroundTransparency = 1
    card.Parent = NotifyHolder

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Accent
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = C.Accent
    accent.BorderSizePixel = 0
    accent.BackgroundTransparency = 1
    accent.Parent = card

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(text)
    label.TextColor3 = C.Text
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTransparency = 1
    label.Parent = card

    tween(card, { BackgroundTransparency = 0 }, 0.2)
    tween(stroke, { Transparency = 0 }, 0.2)
    tween(accent, { BackgroundTransparency = 0 }, 0.2)
    tween(label, { TextTransparency = 0 }, 0.2)

    task.delay(duration, function()
        if not card.Parent then return end
        tween(card, { BackgroundTransparency = 1 }, 0.25)
        tween(stroke, { Transparency = 1 }, 0.25)
        tween(accent, { BackgroundTransparency = 1 }, 0.25)
        local t = tween(label, { TextTransparency = 1 }, 0.25)
        if t then
            t.Completed:Connect(function()
                card:Destroy()
            end)
        else
            card:Destroy()
        end
    end)
end

-- ─────────────────────────────────────────────
-- Sidebar
-- ─────────────────────────────────────────────
local SIDEBAR_W = 46

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -1)
Sidebar.Position = UDim2.new(0, 0, 0, 1)
Sidebar.BackgroundColor3 = C.SidebarBg
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Window
register(Sidebar, "BackgroundColor3", "SidebarBg")

local SidebarLine = Instance.new("Frame")
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, -1, 0, 0)
SidebarLine.BackgroundColor3 = C.SidebarLine
SidebarLine.BorderSizePixel = 0
SidebarLine.Parent = Sidebar
register(SidebarLine, "BackgroundColor3", "SidebarLine")

-- ─────────────────────────────────────────────
-- Icon system
-- ─────────────────────────────────────────────
local function setIconColor(container, col)
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("Frame") then
            if obj.Name ~= "Bar" and obj.Name ~= "Hole" then
                obj.BackgroundColor3 = col
            end
        elseif obj:IsA("UIStroke") then
            obj.Color = col
        end
    end
end

local function addFrame(parent, size, pos, color, corner)
    local f = Instance.new("Frame")
    f.Size = size
    f.Position = pos
    f.BackgroundColor3 = color or C.IconOff
    f.BorderSizePixel = 0
    f.Parent = parent
    if corner then Instance.new("UICorner", f).CornerRadius = corner end
    return f
end

local function addStrokeRing(parent, size, pos, thickness)
    local ring = Instance.new("Frame")
    ring.Size = size
    ring.Position = pos
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Parent = parent
    local s = Instance.new("UIStroke")
    s.Color = C.IconOff
    s.Thickness = thickness or 1.3
    s.Parent = ring
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    return ring, s
end

local function iconPlayer(parent)
    addFrame(parent, UDim2.new(0, 9, 0, 9), UDim2.new(0.5, -4.5, 0.5, -8), C.IconOff, UDim.new(1, 0))
    addFrame(parent, UDim2.new(0, 15, 0, 2), UDim2.new(0.5, -7.5, 0.5, -9.2), C.IconOff, UDim.new(0, 1))
    addFrame(parent, UDim2.new(0, 4, 0, 6), UDim2.new(0.5, -9, 0.5, -7), C.IconOff, UDim.new(0, 2))
    addFrame(parent, UDim2.new(0, 4, 0, 6), UDim2.new(0.5, 5, 0.5, -7), C.IconOff, UDim.new(0, 2))
    addFrame(parent, UDim2.new(0, 13, 0, 7), UDim2.new(0.5, -6.5, 0.5, 3), C.IconOff, UDim.new(0, 3))
end

local function iconAim(parent)
    addStrokeRing(parent, UDim2.new(0, 15, 0, 15), UDim2.new(0.5, -7.5, 0.5, -7.5), 1.4)
    addFrame(parent, UDim2.new(0, 5, 0, 1.5), UDim2.new(0.5, -8, 0.5, -0.75), C.IconOff)
    addFrame(parent, UDim2.new(0, 5, 0, 1.5), UDim2.new(0.5, 3, 0.5, -0.75), C.IconOff)
    addFrame(parent, UDim2.new(0, 1.5, 0, 5), UDim2.new(0.5, -0.75, 0.5, -8), C.IconOff)
    addFrame(parent, UDim2.new(0, 1.5, 0, 5), UDim2.new(0.5, -0.75, 0.5, 3), C.IconOff)
    addFrame(parent, UDim2.new(0, 2.5, 0, 2.5), UDim2.new(0.5, -1.25, 0.5, -1.25), C.IconOff, UDim.new(1, 0))
end

local function iconVisuals(parent)
    addFrame(parent, UDim2.new(0, 7, 0, 7), UDim2.new(0.5, -3.5, 0.5, -3.5), C.IconOff, UDim.new(1, 0))
    local rays = {
        {-1, -10, 2, 4}, {-1, 6, 2, 4}, {-10, -1, 4, 2}, {6, -1, 4, 2},
        {-8, -8, 3.5, 2}, {4.5, -8, 3.5, 2}, {-8, 6, 3.5, 2}, {4.5, 6, 3.5, 2},
    }
    for _, r in ipairs(rays) do
        addFrame(parent, UDim2.new(0, r[3], 0, r[4]), UDim2.new(0.5, r[1], 0.5, r[2]), C.IconOff, UDim.new(0, 1))
    end
end

local function iconMisc(parent)
    addStrokeRing(parent, UDim2.new(0, 16, 0, 16), UDim2.new(0.5, -8, 0.5, -8), 1.3)
    local function makeGear(ox, oy, size, holeSize)
        addFrame(parent, UDim2.new(0, size, 0, size), UDim2.new(0.5, ox - size/2, 0.5, oy - size/2), C.IconOff, UDim.new(1, 0))
        local hole = addFrame(parent, UDim2.new(0, holeSize, 0, holeSize), UDim2.new(0.5, ox - holeSize/2, 0.5, oy - holeSize/2), C.SidebarBg, UDim.new(1, 0))
        hole.Name = "Hole"
        local half = size / 2
        local teeth = {
            {0, -half-1, 2, 2}, {0, half-1, 2, 2},
            {-half-1, 0, 2, 2}, {half-1, 0, 2, 2},
            {-half+0.5, -half+0.5, 1.8, 1.8}, {half-2.2, -half+0.5, 1.8, 1.8},
            {-half+0.5, half-2.2, 1.8, 1.8}, {half-2.2, half-2.2, 1.8, 1.8},
        }
        for _, t in ipairs(teeth) do
            addFrame(parent, UDim2.new(0, t[3], 0, t[4]), UDim2.new(0.5, ox + t[1] - t[3]/2, 0.5, oy + t[2] - t[4]/2), C.IconOff)
        end
    end
    makeGear(2.2, 2.2, 7, 2.4)
    makeGear(-2.2, -2.2, 7.5, 2.6)
end

local function iconRage(parent)
    local blade = addFrame(parent, UDim2.new(0, 13, 0, 3.5), UDim2.new(0.5, -3, 0.5, -6), C.IconOff, UDim.new(0, 1))
    blade.Rotation = 40
    local tip = addFrame(parent, UDim2.new(0, 5, 0, 3.5), UDim2.new(0.5, 5, 0.5, -9), C.IconOff, UDim.new(0, 1))
    tip.Rotation = 40
    local guard = addFrame(parent, UDim2.new(0, 7, 0, 2), UDim2.new(0.5, -6, 0.5, -1), C.IconOff)
    guard.Rotation = 40
    local handle = addFrame(parent, UDim2.new(0, 6, 0, 3), UDim2.new(0.5, -9, 0.5, 2), C.IconOff, UDim.new(0, 1))
    handle.Rotation = 40
end

local function iconPlayers(parent)
    addFrame(parent, UDim2.new(0, 8, 0, 8), UDim2.new(0.5, -4, 0.5, -8.5), C.IconOff, UDim.new(1, 0))
    addFrame(parent, UDim2.new(0, 13, 0, 8), UDim2.new(0.5, -6.5, 0.5, 1), C.IconOff, UDim.new(0, 4))
end

local IconBuilders = { iconPlayer, iconAim, iconVisuals, iconMisc, iconRage, iconPlayers }
local IconIds = { "player", "aim", "visuals", "misc", "rage", "players" }
local selected = 4

local function makeIcon(i)
    local btn = Instance.new("TextButton")
    btn.Name = IconIds[i]
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.Position = UDim2.new(0, 0, 0, (i - 1) * 48)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local icon = Instance.new("Frame")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0.5, -10, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Parent = btn
    IconBuilders[i](icon)

    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.Size = UDim2.new(0, 2, 0, 22)
    bar.Position = UDim2.new(0, 0, 0.5, -11)
    bar.BackgroundColor3 = C.Accent
    bar.BorderSizePixel = 0
    bar.Visible = (i == selected)
    bar.Parent = btn
    register(bar, "BackgroundColor3", "Accent")

    if i == selected then setIconColor(icon, C.Accent) end

    btn.MouseEnter:Connect(function()
        if i ~= selected then
            setIconColor(icon, C.IconHover)
            bar.Visible = true
            bar.BackgroundTransparency = 0.55
            tween(icon, { Size = UDim2.new(0, 21, 0, 21), Position = UDim2.new(0.5, -10.5, 0.5, -10.5) }, 0.1)
        end
    end)
    btn.MouseLeave:Connect(function()
        if i ~= selected then
            setIconColor(icon, C.IconOff)
            bar.Visible = false
            bar.BackgroundTransparency = 0
            tween(icon, { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0.5, -10, 0.5, -10) }, 0.1)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        selected = i
        closeAllDropdowns()
        for idx, child in ipairs(sidebarButtons) do
            local b = child:FindFirstChild("Bar")
            local ic = child:FindFirstChild("Icon")
            local isSel = (idx == i)
            if b then
                b.Visible = isSel
                b.BackgroundTransparency = 0
                b.BackgroundColor3 = C.Accent
            end
            if ic then
                setIconColor(ic, isSel and C.Accent or C.IconOff)
                if isSel then
                    tween(ic, { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0.5, -10, 0.5, -10) }, 0.1)
                end
            end
        end
    end)
    sidebarButtons[i] = btn
end

for i = 1, #IconBuilders do makeIcon(i) end

-- ─────────────────────────────────────────────
-- Content
-- ─────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -SIDEBAR_W, 1, -1)
Content.Position = UDim2.new(0, SIDEBAR_W, 0, 1)
Content.BackgroundColor3 = C.WindowBg
Content.BorderSizePixel = 0
Content.Parent = Window
register(Content, "BackgroundColor3", "WindowBg")

local Left = Instance.new("ScrollingFrame")
Left.Name = "Left"
Left.Size = UDim2.new(0.52, -10, 1, -14)
Left.Position = UDim2.new(0, 8, 0, 7)
Left.BackgroundTransparency = 1
Left.BorderSizePixel = 0
Left.ScrollBarThickness = 2
Left.ScrollBarImageColor3 = C.Accent
Left.CanvasSize = UDim2.new(0, 0, 0, 640)
Left.ScrollingDirection = Enum.ScrollingDirection.Y
Left.Parent = Content
register(Left, "ScrollBarImageColor3", "Accent")

local Right = Instance.new("ScrollingFrame")
Right.Name = "Right"
Right.Size = UDim2.new(0.48, -10, 1, -14)
Right.Position = UDim2.new(0.52, 2, 0, 7)
Right.BackgroundTransparency = 1
Right.BorderSizePixel = 0
Right.ScrollBarThickness = 2
Right.ScrollBarImageColor3 = C.Accent
Right.CanvasSize = UDim2.new(0, 0, 0, 520)
Right.ScrollingDirection = Enum.ScrollingDirection.Y
Right.Parent = Content
register(Right, "ScrollBarImageColor3", "Accent")

-- ─────────────────────────────────────────────
-- Control builders
-- ─────────────────────────────────────────────
local function panel(parent, title, h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h)
    f.BackgroundColor3 = C.PanelBg
    f.BorderSizePixel = 0
    f.Parent = parent
    register(f, "BackgroundColor3", "PanelBg")

    local s = Instance.new("UIStroke")
    s.Color = C.PanelBorder
    s.Thickness = 1
    s.Parent = f
    register(s, "Color", "PanelBorder")

    local hdr = Instance.new("TextLabel")
    hdr.Size = UDim2.new(1, -14, 0, 20)
    hdr.Position = UDim2.new(0, 8, 0, 3)
    hdr.BackgroundTransparency = 1
    hdr.Text = title
    hdr.TextColor3 = C.Header
    hdr.TextSize = 12
    hdr.Font = Enum.Font.GothamMedium
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Parent = f
    register(hdr, "TextColor3", "Header")

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Size = UDim2.new(1, -12, 1, -26)
    body.Position = UDim2.new(0, 6, 0, 24)
    body.BackgroundTransparency = 1
    body.Parent = f

    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 2)
    lay.Parent = body
    return f, body
end

local function toggle(parent, text, on, rightHint)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 18)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 12, 0, 12)
    box.Position = UDim2.new(0, 1, 0.5, -6)
    box.BackgroundColor3 = on and C.Accent or C.CheckboxOff
    box.BorderSizePixel = 0
    box.Text = ""
    box.AutoButtonColor = false
    box.Parent = row

    local boxS = Instance.new("UIStroke")
    boxS.Color = on and C.Accent or C.CheckboxBorder
    boxS.Thickness = 1
    boxS.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, rightHint and -40 or -20, 1, 0)
    lbl.Position = UDim2.new(0, 18, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    register(lbl, "TextColor3", "Text")

    if rightHint then
        local hint = Instance.new("TextLabel")
        hint.Size = UDim2.new(0, 22, 1, 0)
        hint.Position = UDim2.new(1, -22, 0, 0)
        hint.BackgroundTransparency = 1
        hint.Text = rightHint
        hint.TextColor3 = C.TextDim
        hint.TextSize = 10
        hint.Font = Enum.Font.Gotham
        hint.TextXAlignment = Enum.TextXAlignment.Right
        hint.Parent = row
        register(hint, "TextColor3", "TextDim")
    end

    local state = on
    box.MouseEnter:Connect(function()
        if not state then tweenColor(boxS, "Color", C.Accent, 0.1) end
        tween(box, { Size = UDim2.new(0, 13, 0, 13), Position = UDim2.new(0, 0.5, 0.5, -6.5) }, 0.08)
    end)
    box.MouseLeave:Connect(function()
        if not state then tweenColor(boxS, "Color", C.CheckboxBorder, 0.1) end
        tween(box, { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 1, 0.5, -6) }, 0.08)
    end)
    box.MouseButton1Click:Connect(function()
        state = not state
        tweenColor(box, "BackgroundColor3", state and C.Accent or C.CheckboxOff, 0.1)
        tweenColor(boxS, "Color", state and C.Accent or C.CheckboxBorder, 0.1)
    end)

    local api = {
        get = function() return state end,
        set = function(v)
            state = v and true or false
            box.BackgroundColor3 = state and C.Accent or C.CheckboxOff
            boxS.Color = state and C.Accent or C.CheckboxBorder
        end,
        box = box, stroke = boxS,
    }
    table.insert(controlRefs, { type = "toggle", api = api })
    return api
end

local function slider(parent, text, min, max, val)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 24)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -36, 0, 12)
    lbl.Position = UDim2.new(0, 1, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.Text
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row
    register(lbl, "TextColor3", "Text")

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 34, 0, 12)
    valLbl.Position = UDim2.new(1, -34, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(val)
    valLbl.TextColor3 = C.TextDim
    valLbl.TextSize = 10
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row
    register(valLbl, "TextColor3", "TextDim")

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -2, 0, 3)
    track.Position = UDim2.new(0, 1, 0, 15)
    track.BackgroundColor3 = C.SliderTrack
    track.BorderSizePixel = 0
    track.Parent = row
    register(track, "BackgroundColor3", "SliderTrack")
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(clamp((val - min) / (max - min), 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    register(fill, "BackgroundColor3", "Accent")
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 1)

    local dragging, current = false, val
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local rel = clamp((Mouse.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            current = math.floor(min + (max - min) * rel + 0.5)
            valLbl.Text = tostring(current)
        end
    end)

    local api = {
        get = function() return current end,
        set = function(v)
            current = clamp(v, min, max)
            fill.Size = UDim2.new((current - min) / (max - min), 0, 1, 0)
            valLbl.Text = tostring(current)
        end,
        fill = fill, track = track,
    }
    table.insert(controlRefs, { type = "slider", api = api })
    return api
end

local function dropdown(parent, labelText, options, current)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, labelText ~= "" and 36 or 24)
    row.BackgroundTransparency = 1
    row.ClipsDescendants = false
    row.Parent = parent

    if labelText ~= "" then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 12)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = C.Text
        lbl.TextSize = 11
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row
        register(lbl, "TextColor3", "Text")
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -2, 0, 20)
    btn.Position = UDim2.new(0, 1, 0, labelText ~= "" and 14 or 2)
    btn.BackgroundColor3 = C.DropdownBg
    btn.BorderSizePixel = 0
    btn.Text = "  " .. current
    btn.TextColor3 = C.Text
    btn.TextSize = 11
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.Parent = row
    register(btn, "BackgroundColor3", "DropdownBg")
    register(btn, "TextColor3", "Text")

    local bs = Instance.new("UIStroke")
    bs.Color = C.DropdownBorder
    bs.Thickness = 1
    bs.Parent = btn
    register(bs, "Color", "DropdownBorder")

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 16, 1, 0)
    arrow.Position = UDim2.new(1, -16, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = C.TextDim
    arrow.TextSize = 10
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = btn
    register(arrow, "TextColor3", "TextDim")

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -2, 0, #options * 18)
    list.Position = UDim2.new(0, 1, 0, labelText ~= "" and 36 or 24)
    list.BackgroundColor3 = C.DropdownBg
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 40
    list.Parent = row
    register(list, "BackgroundColor3", "DropdownBg")

    local ls = Instance.new("UIStroke")
    ls.Color = C.DropdownBorder
    ls.Thickness = 1
    ls.Parent = list
    register(ls, "Color", "DropdownBorder")

    local selectedValue = current
    local api = { list = list, btn = btn }

    for i, opt in ipairs(options) do
        local o = Instance.new("TextButton")
        o.Size = UDim2.new(1, 0, 0, 18)
        o.Position = UDim2.new(0, 0, 0, (i - 1) * 18)
        o.BackgroundColor3 = C.DropdownBg
        o.BorderSizePixel = 0
        o.Text = "  " .. opt
        o.TextColor3 = C.Text
        o.TextSize = 11
        o.Font = Enum.Font.Gotham
        o.TextXAlignment = Enum.TextXAlignment.Left
        o.AutoButtonColor = false
        o.ZIndex = 41
        o.Parent = list
        register(o, "TextColor3", "Text")
        o.MouseEnter:Connect(function() tweenColor(o, "BackgroundColor3", C.ButtonHover, 0.08) end)
        o.MouseLeave:Connect(function() tweenColor(o, "BackgroundColor3", C.DropdownBg, 0.08) end)
        o.MouseButton1Click:Connect(function()
            selectedValue = opt
            btn.Text = "  " .. opt
            list.Visible = false
            tweenColor(bs, "Color", C.DropdownBorder, 0.1)
        end)
    end

    btn.MouseEnter:Connect(function() tweenColor(bs, "Color", C.Accent, 0.1) end)
    btn.MouseLeave:Connect(function()
        if not list.Visible then tweenColor(bs, "Color", C.DropdownBorder, 0.1) end
    end)
    btn.MouseButton1Click:Connect(function()
        local willOpen = not list.Visible
        closeAllDropdowns()
        list.Visible = willOpen
        if willOpen then tweenColor(bs, "Color", C.Accent, 0.1) end
    end)

    api.get = function() return selectedValue end
    api.set = function(v)
        selectedValue = v
        btn.Text = "  " .. tostring(v)
    end
    table.insert(openDropdowns, api)
    table.insert(controlRefs, { type = "dropdown", api = api })
    return api
end

local function button(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -2, 0, 22)
    b.BackgroundColor3 = C.Button
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = C.Text
    b.TextSize = 11
    b.Font = Enum.Font.Gotham
    b.AutoButtonColor = false
    b.Parent = parent
    register(b, "BackgroundColor3", "Button")
    register(b, "TextColor3", "Text")

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(42, 42, 42)
    s.Thickness = 1
    s.Parent = b

    b.MouseEnter:Connect(function()
        tweenColor(b, "BackgroundColor3", C.ButtonHover, 0.1)
        tweenColor(s, "Color", C.Accent, 0.1)
    end)
    b.MouseLeave:Connect(function()
        tweenColor(b, "BackgroundColor3", C.Button, 0.1)
        tweenColor(s, "Color", Color3.fromRGB(42, 42, 42), 0.1)
    end)
    if callback then b.MouseButton1Click:Connect(callback) end
    return b
end

-- ─────────────────────────────────────────────
-- Theme apply (complete)
-- ─────────────────────────────────────────────
local function applyTheme(name)
    if not Themes[name] then
        warn("[GameSense] Unknown theme:", name)
        return false
    end
    currentThemeName = name
    Preferences.theme = name
    for k, v in pairs(Themes[name]) do C[k] = v end

    for _, entry in ipairs(registry) do
        if entry.obj and entry.obj.Parent then
            safeCall(function() entry.obj[entry.prop] = C[entry.key] end)
        end
    end

    for idx, btn in ipairs(sidebarButtons) do
        local ic = btn:FindFirstChild("Icon")
        local bar = btn:FindFirstChild("Bar")
        if ic then
            setIconColor(ic, idx == selected and C.Accent or C.IconOff)
            for _, d in ipairs(ic:GetDescendants()) do
                if d.Name == "Hole" then d.BackgroundColor3 = C.SidebarBg end
            end
        end
        if bar then bar.BackgroundColor3 = C.Accent end
    end

    for _, ref in ipairs(controlRefs) do
        if ref.type == "toggle" and ref.api then
            local st = ref.api.get()
            if ref.api.box then ref.api.box.BackgroundColor3 = st and C.Accent or C.CheckboxOff end
            if ref.api.stroke then ref.api.stroke.Color = st and C.Accent or C.CheckboxBorder end
        elseif ref.type == "slider" and ref.api then
            if ref.api.fill then ref.api.fill.BackgroundColor3 = C.Accent end
            if ref.api.track then ref.api.track.BackgroundColor3 = C.SliderTrack end
        end
    end

    savePreferences()
    return true
end

-- ─────────────────────────────────────────────
-- Build panels
-- ─────────────────────────────────────────────
local miscP, miscB = panel(Left, "Miscellaneous", 620)
miscP.Position = UDim2.new(0, 0, 0, 0)

slider(miscB, "Override FOV", 60, 140, 115)
toggle(miscB, "Bunny hop", true)
toggle(miscB, "Air strafe", true)
dropdown(miscB, "Air strafe direction", {"View angles", "Movement keys", "Mouse"}, "View angles")
slider(miscB, "Air strafe smoothing", 0, 100, 0)
toggle(miscB, "Z-Hop", false, "[-]")
toggle(miscB, "Pre-speed", false, "[-]")
dropdown(miscB, "Air duck", {"Off", "On", "Always"}, "Off")
toggle(miscB, "Knifebot", true)
toggle(miscB, "Zeusbot", false)
toggle(miscB, "Blockbot", false, "[-]")
toggle(miscB, "Automatic weapons", true)
slider(miscB, "Automatic weapons", 0, 200, 0)
toggle(miscB, "Jump at edge", false, "[-]")
toggle(miscB, "Reveal competitive ranks", false)
toggle(miscB, "Auto-accept matchmaking", true)
toggle(miscB, "Log weapon purchases", true)
toggle(miscB, "Log damage dealt", true)
toggle(miscB, "Automatic grenade release", false, "[-]")
toggle(miscB, "Fast walk", false)
toggle(miscB, "Free look", false, "[-]")
button(miscB, "Steal player name")

local setP, setB = panel(Right, "Settings", 210)
setP.Position = UDim2.new(0, 0, 0, 0)

do
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, 0, 0, 16)
    r.BackgroundTransparency = 1
    r.Parent = setB
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = "Menu key"
    l.TextColor3 = C.Text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = r
    register(l, "TextColor3", "Text")
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.45, 0, 1, 0)
    v.Position = UDim2.new(0.55, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = "INS"
    v.TextColor3 = C.TextDim
    v.TextSize = 11
    v.Font = Enum.Font.Gotham
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = r
    register(v, "TextColor3", "TextDim")
end

do
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, 0, 0, 16)
    r.BackgroundTransparency = 1
    r.Parent = setB
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -22, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = "Menu color"
    l.TextColor3 = C.Text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = r
    register(l, "TextColor3", "Text")
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 14, 0, 12)
    box.Position = UDim2.new(1, -16, 0.5, -6)
    box.BackgroundColor3 = C.Accent
    box.BorderSizePixel = 0
    box.Parent = r
    register(box, "BackgroundColor3", "Accent")
end

toggle(setB, "Anti-untrusted", true)
toggle(setB, "Hide from OBS", false)
toggle(setB, "Low FPS warning", false)
toggle(setB, "Lock menu layout", false)
toggle(setB, "Trashtalk", false)

local themeDrop = dropdown(setB, "Theme", {"GameSense", "Midnight", "Crimson", "Emerald"}, currentThemeName)

button(setB, "Apply theme", function()
    local name = themeDrop.get()
    if applyTheme(name) then
        notify("Theme: " .. name, 2)
    end
end)

local othP, othB = panel(Right, "Other", 290)
othP.Position = UDim2.new(0, 0, 0, 220)

dropdown(othB, "", {"Rage", "Legit", "HvH"}, "Rage")

button(othB, "Load config", function()
    loadPreferences()
    applyTheme(Preferences.theme)
    themeDrop.set(Preferences.theme)
    notify("Config loaded", 2)
end)
button(othB, "Save config", function()
    local pos = Window.AbsolutePosition
    Preferences.windowPos = { X = pos.X, Y = pos.Y }
    savePreferences()
    notify("Config saved", 2)
end)
button(othB, "Reset config", function()
    applyTheme("GameSense")
    themeDrop.set("GameSense")
    notify("Reset to GameSense", 2)
end)
button(othB, "Import from clipboard", function() notify("Import (visual only)", 2) end)
button(othB, "Export to clipboard", function() notify("Export (visual only)", 2) end)
button(othB, "Reset menu layout", function()
    Window.Position = UDim2.new(0.5, -299, 0.5, -231)
    Preferences.windowPos = nil
    savePreferences()
    notify("Layout reset", 2)
end)
button(othB, "Lua script manager", function() notify("Script manager (visual)", 2) end)
button(othB, "Unload", function()
    notify("Unloading...", 1)
    task.delay(0.4, function() Gui:Destroy() end)
end)

-- ─────────────────────────────────────────────
-- Close dropdowns on outside click
-- ─────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = inp.Position
        local overDropdown = false
        for _, api in ipairs(openDropdowns) do
            if api.list and api.list.Visible then
                local abs = api.list.AbsolutePosition
                local size = api.list.AbsoluteSize
                if pos.X >= abs.X and pos.X <= abs.X + size.X and pos.Y >= abs.Y and pos.Y <= abs.Y + size.Y then
                    overDropdown = true
                    break
                end
                if api.btn then
                    local bAbs = api.btn.AbsolutePosition
                    local bSize = api.btn.AbsoluteSize
                    if pos.X >= bAbs.X and pos.X <= bAbs.X + bSize.X and pos.Y >= bAbs.Y and pos.Y <= bAbs.Y + bSize.Y then
                        overDropdown = true
                        break
                    end
                end
            end
        end
        if not overDropdown then closeAllDropdowns() end
    end
end)

-- ─────────────────────────────────────────────
-- Dragging
-- ─────────────────────────────────────────────
local dragging, dragStart, startPos = false, nil, nil

Window.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if (inp.Position.Y - Window.AbsolutePosition.Y) < 28 then
            dragging = true
            dragStart = inp.Position
            startPos = Window.Position
            closeAllDropdowns()
        end
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then
            local pos = Window.AbsolutePosition
            Preferences.windowPos = { X = pos.X, Y = pos.Y }
            savePreferences()
        end
        dragging = false
    end
end)

-- ─────────────────────────────────────────────
-- Toggle menu
-- ─────────────────────────────────────────────
local visible = true

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Insert then
        visible = not visible
        if visible then
            Window.Visible = true
            Window.BackgroundTransparency = 1
            tween(Window, { BackgroundTransparency = 0 }, 0.18)
        else
            closeAllDropdowns()
            local t = tween(Window, { BackgroundTransparency = 1 }, 0.12)
            if t then
                t.Completed:Connect(function()
                    if not visible then
                        Window.Visible = false
                        Window.BackgroundTransparency = 0
                    end
                end)
            end
        end
    end
end)

Window.BackgroundTransparency = 1
tween(Window, { BackgroundTransparency = 0 }, 0.25)
applyTheme(currentThemeName)

print("[GameSense] UI loaded · INSERT to toggle")
print("[GameSense] Theme:", currentThemeName)
print("[GameSense] Prefs:", (writefile and "file+memory") or "memory only")
