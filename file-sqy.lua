--[[=================================================================
    VENICE x RIVALS - SELLOS DE ALAS v7 (FINAL)
    ------------------------------------------------------------------
    * Paredes + TERRENO en blanco con estampas
    * Boton de BRILLO con intensidad (para que el blanco se vea blanco)
    * Galeria + importador de IDs (se guarda en disco)
    * Preview, restore y unload completo
===================================================================]]

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local LP           = Players.LocalPlayer
local WS           = workspace

if getgenv and getgenv().VeniceWings7 then
    pcall(function() getgenv().VeniceWings7:Destroy() end)
end

local isUnloaded = false
local Conn = {}
local function track(c) table.insert(Conn, c) return c end

local TargetParent = game:GetService("CoreGui")
if gethui then pcall(function() TargetParent = gethui() end) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VeniceWings7"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = TargetParent end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end
if getgenv then getgenv().VeniceWings7 = ScreenGui end

--=================================================================
--  LISTA DE IMAGENES
--=================================================================
local SAVE_FILE = "venice_wings_ids.txt"

local DEFAULT_IDS = {
    "100381501972125", "17814474604", "14983316111", "102541166446822",
    "113627759349696", "14148300044", "98658629679207", "114580112063066",
    "105148240247620", "17662891564",
}
local IDS = {}

local function loadIDS()
    local ok, txt = pcall(function()
        if readfile and isfile and isfile(SAVE_FILE) then return readfile(SAVE_FILE) end
    end)
    IDS = {}
    if ok and txt then
        for id in tostring(txt):gmatch("%d+") do table.insert(IDS, id) end
    end
    if #IDS == 0 then
        for _, id in ipairs(DEFAULT_IDS) do table.insert(IDS, id) end
    end
end

local function saveIDS()
    pcall(function() if writefile then writefile(SAVE_FILE, table.concat(IDS, "\n")) end end)
end

local WALL_COLORS = {
    { name = "blanca",   color = Color3.fromRGB(255, 255, 255) },
    { name = "gris",     color = Color3.fromRGB(150, 150, 155) },
    { name = "negra",    color = Color3.fromRGB(32, 32, 38) },
    { name = "original", color = nil },
}

local TEX_COLORS = {
    { name = "negra",  color = Color3.fromRGB(10, 10, 10) },
    { name = "blanca", color = Color3.fromRGB(255, 255, 255) },
    { name = "roja",   color = Color3.fromRGB(210, 40, 40) },
    { name = "dorada", color = Color3.fromRGB(255, 190, 60) },
}

local CFG = {
    asset      = nil,
    tiling     = 5,
    allFaces   = true,
    minSize    = 1,
    skipChars  = true,
    autoNew    = true,
    randomOff  = true,
    terrain    = true,
    wallColor  = Color3.fromRGB(255, 255, 255),
    texColor   = Color3.fromRGB(10, 10, 10),
    bright     = false,
    brightLvl  = 3,
    volume     = 1,
    pitch      = 1,
    loop       = false,
    sound      = nil,
}

local CREATED = {}
local BACKUP  = {}
local paintedCount = 0
local Terrain = WS:FindFirstChildOfClass("Terrain")

local TERRAIN_MATS = {
    Enum.Material.Grass, Enum.Material.Sand, Enum.Material.Rock,
    Enum.Material.Snow, Enum.Material.Ground, Enum.Material.Mud,
    Enum.Material.LeafyGrass, Enum.Material.Salt, Enum.Material.Sandstone,
    Enum.Material.Basalt, Enum.Material.Asphalt, Enum.Material.CrackedLava,
    Enum.Material.Limestone, Enum.Material.Pavement, Enum.Material.Dirt,
    Enum.Material.Ice, Enum.Material.Glacier, Enum.Material.Mud,
}
local TERRAIN_COLOR_BACKUP = nil
local TERRAIN_VARIANTS = {}

--=================================================================
--  NOTIFICACIONES
--=================================================================
local function notify(title, body, dur)
    if isUnloaded then return end
    dur = dur or 4
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 270, 0, 52)
    f.Position = UDim2.new(0, -300, 1, -72)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    f.BorderColor3 = Color3.fromRGB(65, 65, 72)
    f.ZIndex = 200
    f.Parent = ScreenGui

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(140, 110, 255)
    bar.BorderSizePixel = 0
    bar.ZIndex = 201
    bar.Parent = f

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -16, 0, 20)
    t.Position = UDim2.new(0, 12, 0, 5)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.Code
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = Color3.fromRGB(165, 145, 255)
    t.Text = title
    t.ZIndex = 201
    t.Parent = f

    local b = Instance.new("TextLabel")
    b.Size = UDim2.new(1, -16, 0, 24)
    b.Position = UDim2.new(0, 12, 0, 24)
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.Code
    b.TextSize = 11
    b.TextWrapped = true
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.TextColor3 = Color3.fromRGB(200, 200, 205)
    b.Text = body
    b.ZIndex = 201
    b.Parent = f

    TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
        Position = UDim2.new(0, 12, 1, -72) }):Play()
    task.delay(dur, function()
        if isUnloaded or not f.Parent then return end
        local o = TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0, -300, 1, -72) })
        o:Play()
        o.Completed:Connect(function() f:Destroy() end)
    end)
end

--=================================================================
--  BRILLO
--=================================================================
local LIGHT_BACKUP = nil
local ATMO = nil

local function applyBright()
    if not CFG.bright then return end
    if not LIGHT_BACKUP then
        LIGHT_BACKUP = {
            Brightness = Lighting.Brightness,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Ambient = Lighting.Ambient,
            ClockTime = Lighting.ClockTime,
            ExposureCompensation = Lighting.ExposureCompensation,
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            ColorShift_Top = Lighting.ColorShift_Top,
            ColorShift_Bottom = Lighting.ColorShift_Bottom,
        }
        ATMO = Lighting:FindFirstChildOfClass("Atmosphere")
        if ATMO then LIGHT_BACKUP.AtmoDensity = ATMO.Density end
    end

    local lv = CFG.brightLvl
    pcall(function() Lighting.Brightness = 1 + lv * 0.9 end)
    pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160) end)
    pcall(function() Lighting.Ambient = Color3.fromRGB(130, 130, 140) end)
    pcall(function() Lighting.ClockTime = 14 end)
    pcall(function() Lighting.ExposureCompensation = 0.08 * lv end)
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.FogEnd = 100000 end)
    pcall(function() Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255) end)
    if ATMO then pcall(function() ATMO.Density = 0.05 end) end
end

local function restoreBright()
    if not LIGHT_BACKUP then return end
    for k, v in pairs(LIGHT_BACKUP) do
        if k ~= "AtmoDensity" then pcall(function() Lighting[k] = v end) end
    end
    if ATMO and LIGHT_BACKUP.AtmoDensity then
        pcall(function() ATMO.Density = LIGHT_BACKUP.AtmoDensity end)
    end
    LIGHT_BACKUP = nil
end

--=================================================================
--  TERRENO
--=================================================================
local function clearTerrainVariants()
    if Terrain then
        for _, m in ipairs(TERRAIN_MATS) do
            pcall(function() Terrain:SetMaterialVariant(m, nil) end)
        end
    end
    for _, mv in pairs(TERRAIN_VARIANTS) do pcall(function() mv:Destroy() end) end
    TERRAIN_VARIANTS = {}
end

local function paintTerrain()
    if not Terrain or not CFG.terrain or not CFG.asset then return end

    if not TERRAIN_COLOR_BACKUP then
        TERRAIN_COLOR_BACKUP = {}
        for _, m in ipairs(TERRAIN_MATS) do
            local ok, c = pcall(function() return Terrain:GetMaterialColor(m) end)
            if ok and c then TERRAIN_COLOR_BACKUP[m] = c end
        end
    end

    clearTerrainVariants()

    for _, m in ipairs(TERRAIN_MATS) do
        pcall(function() Terrain:SetMaterialColor(m, CFG.wallColor or Color3.new(1, 1, 1)) end)

        local name = "VN_T_" .. m.Name
        local old = MaterialService:FindFirstChild(name)
        if old then old:Destroy() end

        local mv = Instance.new("MaterialVariant")
        mv.Name = name
        pcall(function() mv.BasePartMaterial = m end)
        local okA = pcall(function() mv.AlbedoMap = CFG.asset end)
        if not okA then pcall(function() mv.TextureMap = CFG.asset end) end
        pcall(function()
            mv.StudsPerTileU = CFG.tiling
            mv.StudsPerTileV = CFG.tiling
        end)
        pcall(function() mv.Parent = MaterialService end)

        if mv.Parent then
            TERRAIN_VARIANTS[m.Name] = mv
            pcall(function() Terrain:SetMaterialVariant(m, mv) end)
        end
    end
end

local function updateTerrainSettings()
    if not TERRAIN_COLOR_BACKUP then return end
    for _, mv in pairs(TERRAIN_VARIANTS) do
        pcall(function()
            mv.StudsPerTileU = CFG.tiling
            mv.StudsPerTileV = CFG.tiling
        end)
    end
    for _, m in ipairs(TERRAIN_MATS) do
        pcall(function() Terrain:SetMaterialColor(m, CFG.wallColor or Color3.new(1, 1, 1)) end)
    end
end

local function restoreTerrain()
    if not Terrain then return end
    clearTerrainVariants()
    if TERRAIN_COLOR_BACKUP then
        for m, c in pairs(TERRAIN_COLOR_BACKUP) do
            pcall(function() Terrain:SetMaterialColor(m, c) end)
        end
        TERRAIN_COLOR_BACKUP = nil
    end
end

--=================================================================
--  APLICAR EN PARTES
--=================================================================
local FACES_ALL = {
    Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left,
    Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom,
}
local FACES_VIS = {
    Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left,
    Enum.NormalId.Right, Enum.NormalId.Top,
}

local function isCharPart(part)
    if LP.Character and part:IsDescendantOf(LP.Character) then return true end
    local m = part:FindFirstAncestorWhichIsA("Model")
    return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end

local function setupTexture(t)
    t.Texture = CFG.asset
    t.StudsPerTileU = CFG.tiling
    t.StudsPerTileV = CFG.tiling
    t.Transparency = 0
    if CFG.texColor then pcall(function() t.Color3 = CFG.texColor end) end
    if CFG.randomOff then
        pcall(function()
            t.OffsetStudsU = math.random() * CFG.tiling
            t.OffsetStudsV = math.random() * CFG.tiling
            t.Rotation = math.random(0, 3) * 90
        end)
    else
        pcall(function() t.OffsetStudsU = 0 t.OffsetStudsV = 0 t.Rotation = 0 end)
    end
end

local function paintPart(part)
    if isUnloaded or not CFG.asset then return end
    if not part:IsA("BasePart") or part:IsA("Terrain") then return end
    if part.Transparency >= 1 then return end
    if part.Parent and part.Parent.Name == "Camera" then return end
    if CFG.skipChars and isCharPart(part) then return end
    if CFG.minSize > 0 and math.max(part.Size.X, part.Size.Y, part.Size.Z) < CFG.minSize then return end

    if CFG.wallColor then
        if not BACKUP[part] then BACKUP[part] = {} end
        if BACKUP[part].Color == nil then BACKUP[part].Color = part.Color end
        pcall(function() part.Color = CFG.wallColor end)
    end

    for _, face in ipairs(CFG.allFaces and FACES_ALL or FACES_VIS) do
        local found
        for _, c in ipairs(part:GetChildren()) do
            if c:IsA("Texture") and c.Face == face then found = c break end
        end
        if found then
            if not BACKUP[found] then
                BACKUP[found] = {
                    Texture = found.Texture, StudsPerTileU = found.StudsPerTileU,
                    StudsPerTileV = found.StudsPerTileV, Transparency = found.Transparency,
                    Color3 = found.Color3,
                }
            end
            pcall(setupTexture, found)
        else
            local t = Instance.new("Texture")
            t.Face = face
            pcall(setupTexture, t)
            t.Parent = part
            CREATED[t] = true
        end
    end
    paintedCount += 1
end

local function paintAll()
    if not CFG.asset then return end
    paintedCount = 0
    local list = WS:GetDescendants()
    task.spawn(function()
        for i = 1, #list do
            if isUnloaded then break end
            pcall(paintPart, list[i])
            if i % 250 == 0 then task.wait() end
        end
        pcall(paintTerrain)
        notify("Listo", paintedCount .. " partes + terreno estampados.", 4)
    end)
end

local function restore()
    for inst, props in pairs(BACKUP) do
        if inst and inst.Parent then
            for p, v in pairs(props) do pcall(function() inst[p] = v end) end
        end
    end
    BACKUP = {}
    for inst in pairs(CREATED) do pcall(function() inst:Destroy() end) end
    CREATED = {}
    paintedCount = 0
    pcall(restoreTerrain)
    notify("Restaurado", "Mapa y terreno volvieron a lo normal.", 3)
end

local function refresh()
    for inst in pairs(CREATED) do pcall(setupTexture, inst) end
    for inst in pairs(BACKUP) do pcall(setupTexture, inst) end
    pcall(updateTerrainSettings)
end

--=================================================================
--  SONIDO
--=================================================================
local function stopSound()
    if CFG.sound then pcall(function() CFG.sound:Destroy() end) CFG.sound = nil end
end

local function playSound(txt)
    local raw = tostring(txt or ""):gsub("%s", "")
    if raw == "" then return end
    local id = raw:match("^%d+$") or raw:match("rbxassetid://(%d+)")
    local a = id and ("rbxassetid://" .. id) or raw
    stopSound()
    local s = Instance.new("Sound")
    s.SoundId = a
    s.Volume = CFG.volume
    s.PlaybackSpeed = CFG.pitch
    s.Looped = CFG.loop
    s.Parent = SoundService
    s:Play()
    CFG.sound = s
end

--=================================================================
--  UI
--=================================================================
local ACCENT = Color3.fromRGB(140, 110, 255)
local BG, TEXT, MUTED =
    Color3.fromRGB(18, 18, 20), Color3.fromRGB(228, 228, 232), Color3.fromRGB(150, 150, 158)

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then i[k] = v end end
    if parent then i.Parent = parent end
    return i
end

local Main = new("Frame", {
    Size = UDim2.new(0, 330, 0, 440), Position = UDim2.new(0, 12, 0, 55),
    BackgroundColor3 = BG, BorderColor3 = Color3.fromRGB(60, 60, 68),
}, ScreenGui)

new("TextLabel", {
    Size = UDim2.new(1, -12, 0, 22), Position = UDim2.new(0, 8, 0, 3),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    Text = "venice x rivals | v7 final", TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)

local ToggleBtn = new("TextButton", {
    Size = UDim2.new(0, 120, 0, 28), Position = UDim2.new(0, 12, 0, 30),
    BackgroundColor3 = Color3.fromRGB(22, 22, 26), BorderColor3 = Color3.fromRGB(75, 75, 82),
    Font = Enum.Font.Code, TextSize = 12, Text = "cerrar ui [X]", TextColor3 = TEXT,
}, ScreenGui)
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local function syncBtn() ToggleBtn.Text = Main.Visible and "cerrar ui [X]" or "abrir ui [X]" end
track(ToggleBtn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible syncBtn() end))
track(UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.RightShift then Main.Visible = not Main.Visible syncBtn() end
end))

local Scroll = new("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -62), Position = UDim2.new(0, 5, 0, 58),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Main)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, Scroll)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Scroll)

local function section(txt, order)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.Code,
        TextSize = 11, Text = txt, TextColor3 = ACCENT,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
    }, Scroll)
end

local function button(txt, order, color, cb, parent, size)
    local b = new("TextButton", {
        Size = size or UDim2.new(1, 0, 0, 30), BackgroundColor3 = color or Color3.fromRGB(25, 25, 30),
        BorderColor3 = Color3.fromRGB(65, 65, 72), Font = Enum.Font.Code, TextSize = 10,
        Text = txt, TextColor3 = TEXT, LayoutOrder = order, TextWrapped = true,
    }, parent or Scroll)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then notify("Error", tostring(err), 6) end
    end)
    return b
end

local function toggleRow(label, order, default, cb)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = order }, Scroll)
    new("TextLabel", {
        Size = UDim2.new(0.72, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code,
        TextSize = 11, Text = label, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local st = default and true or false
    local b = new("TextButton", {
        Size = UDim2.new(0, 52, 0, 22), Position = UDim2.new(1, -52, 0.5, -11),
        BackgroundColor3 = st and ACCENT or Color3.fromRGB(25, 25, 30), BorderSizePixel = 0,
        Font = Enum.Font.Code, TextSize = 10, Text = st and "[ON]" or "[OFF]", TextColor3 = TEXT,
    }, row)
    b.MouseButton1Click:Connect(function()
        st = not st
        b.Text = st and "[ON]" or "[OFF]"
        b.BackgroundColor3 = st and ACCENT or Color3.fromRGB(25, 25, 30)
        cb(st)
    end)
end

local function sliderRow(label, min, max, default, order, cb)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, LayoutOrder = order }, Scroll)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Code,
        TextSize = 10, Text = label, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local bar = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 22),
        BackgroundColor3 = Color3.fromRGB(35, 35, 42), BorderSizePixel = 0, Text = "",
    }, row)
    local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ACCENT, BorderSizePixel = 0 }, bar)
    local drag = false
    local function set(a)
        a = math.clamp(a, 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        local v = min + (max - min) * a
        lbl.Text = label .. ": " .. string.format("%.1f", v)
        cb(v)
    end
    set((default - min) / (max - min))
    local function fromX(x) set((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)) end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true fromX(i.Position.X)
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            fromX(i.Position.X)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end))
end

-- ---------------- contenido ----------------
section("1. IMAGENES (toca una)", 1)

local Preview = new("ImageLabel", {
    Size = UDim2.new(0, 86, 0, 86), Position = UDim2.new(1, -92, 0, 0),
    BackgroundColor3 = Color3.fromRGB(75, 75, 85), BorderColor3 = Color3.fromRGB(95, 95, 105),
    LayoutOrder = 1, Image = "",
}, Scroll)

local Grid = new("Frame", {
    Size = UDim2.new(1, -100, 0, 132), BackgroundTransparency = 1, LayoutOrder = 2,
}, Scroll)
new("UIGridLayout", {
    CellSize = UDim2.new(0.5, -3, 0, 30), CellPadding = UDim2.new(0, 6, 0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Grid)

local function pick(id)
    CFG.asset = "rbxassetid://" .. id
    Preview.Image = CFG.asset
    if TERRAIN_COLOR_BACKUP then pcall(paintTerrain) end
    notify("Elegido", "ID " .. id, 3)
end

local function rebuild()
    for _, c in ipairs(Grid:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for i, id in ipairs(IDS) do
        button("#" .. i, i, Color3.fromRGB(32, 28, 44), function() pick(id) end, Grid)
    end
    Grid.Size = UDim2.new(1, -100, 0, math.max(1, math.ceil(#IDS / 2)) * 36)
    if #IDS > 0 and not CFG.asset then
        CFG.asset = "rbxassetid://" .. IDS[1]
        Preview.Image = CFG.asset
    end
end

local ImportBox = new("TextBox", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    BorderColor3 = Color3.fromRGB(60, 60, 66), Font = Enum.Font.Code, TextSize = 10,
    Text = "", PlaceholderText = "pega IDs separadas por coma o salto de linea",
    PlaceholderColor3 = MUTED, TextColor3 = TEXT, ClearTextOnFocus = false,
    TextWrapped = true, LayoutOrder = 3,
}, Scroll)

button("IMPORTAR LISTA", 4, Color3.fromRGB(45, 36, 70), function()
    local found = {}
    for id in tostring(ImportBox.Text):gmatch("%d+") do table.insert(found, id) end
    if #found == 0 then notify("Importar", "No encontre ninguna ID.", 4) return end
    IDS = found
    saveIDS()
    rebuild()
    notify("Importado", #found .. " IDs guardadas.", 4)
end)

button("VOLVER A LA LISTA POR DEFECTO", 5, Color3.fromRGB(30, 30, 36), function()
    IDS = {}
    for _, id in ipairs(DEFAULT_IDS) do table.insert(IDS, id) end
    saveIDS()
    rebuild()
end)

section("2. COLORES", 6)

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextSize = 10, Text = "paredes y suelo", TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 7,
}, Scroll)
local wallRow = new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 8 }, Scroll)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, wallRow)
for _, w in ipairs(WALL_COLORS) do
    button(w.name, 1, w.color or Color3.fromRGB(60, 60, 70), function()
        CFG.wallColor = w.color
        notify("Color", "Paredes y suelo: " .. w.name, 2)
        paintAll()
    end, wallRow, UDim2.new(0, 72, 0, 28))
end

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextSize = 10, Text = "imagen", TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 9,
}, Scroll)
local texRow = new("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 10 }, Scroll)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }, texRow)
for _, tc in ipairs(TEX_COLORS) do
    button(tc.name, 1, tc.color, function()
        CFG.texColor = tc.color
        notify("Imagen", "Color: " .. tc.name, 2)
        refresh()
    end, texRow, UDim2.new(0, 72, 0, 28))
end

section("3. BRILLO", 11)
toggleRow("modo brillo (mapa claro)", 12, false, function(v)
    CFG.bright = v
    if v then applyBright() else restoreBright() end
end)
sliderRow("intensidad del brillo", 1, 5, 3, 13, function(v)
    CFG.brightLvl = v
    applyBright()
end)

section("4. ESTAMPAR", 14)
button("ESTAMPAR PAREDES + SUELO", 15, Color3.fromRGB(55, 42, 92), function() paintAll() end)
button("RESTAURAR MAPA", 16, Color3.fromRGB(30, 30, 36), function() restore() end)

section("5. AJUSTES", 17)
sliderRow("Tamano de cada sello (studs)", 1, 30, 5, 18, function(v)
    CFG.tiling = v
    refresh()
end)
toggleRow("posicion aleatoria", 19, true, function(v)
    CFG.randomOff = v
    refresh()
end)
toggleRow("incluir terreno / suelo", 20, true, function(v) CFG.terrain = v end)
toggleRow("todas las caras (6)", 21, true, function(v) CFG.allFaces = v end)
toggleRow("excluir jugadores / armas", 22, true, function(v) CFG.skipChars = v end)
toggleRow("auto-aplicar a partes nuevas", 23, true, function(v) CFG.autoNew = v end)
sliderRow("Tamano minimo de parte", 0, 20, 1, 24, function(v) CFG.minSize = v end)

section("SONIDO", 25)
local SndBox = new("TextBox", {
    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    BorderColor3 = Color3.fromRGB(60, 60, 66), Font = Enum.Font.Code, TextSize = 11,
    Text = "", PlaceholderText = "ID de sonido", PlaceholderColor3 = MUTED,
    TextColor3 = TEXT, ClearTextOnFocus = false, LayoutOrder = 26,
}, Scroll)
button("Reproducir", 27, Color3.fromRGB(40, 32, 62), function() playSound(SndBox.Text) end)
button("Detener", 28, Color3.fromRGB(30, 30, 36), function() stopSound() end)
toggleRow("loop", 29, false, function(v) CFG.loop = v if CFG.sound then CFG.sound.Looped = v end end)
sliderRow("Volumen", 0, 3, 1, 30, function(v) CFG.volume = v if CFG.sound then CFG.sound.Volume = v end end)

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextSize = 10, TextWrapped = true, LayoutOrder = 31, TextColor3 = Color3.fromRGB(235, 180, 90),
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Orden: toca imagen -> modo brillo ON -> ESTAMPAR.\nSi el suelo no cambia, apaga y prende 'incluir terreno'.",
}, Scroll)

button("UNLOAD SCRIPT", 32, Color3.fromRGB(60, 25, 25), function()
    if isUnloaded then return end
    isUnloaded = true
    for _, c in ipairs(Conn) do pcall(function() c:Disconnect() end) end
    restore()
    restoreBright()
    stopSound()
    pcall(function() ScreenGui:Destroy() end)
end)

--=================================================================
--  AUTO APLICAR
--=================================================================
track(WS.DescendantAdded:Connect(function(obj)
    if isUnloaded or not CFG.autoNew or not CFG.asset then return end
    if obj:IsA("BasePart") and not obj:IsA("Terrain") then
        task.defer(function() if obj.Parent then pcall(paintPart, obj) end end)
    end
end))

--=================================================================
--  ARRANQUE
--=================================================================
loadIDS()
rebuild()
notify("v7 cargado", "Imagen + modo brillo + ESTAMPAR. " .. #IDS .. " IDs en lista.", 5)
