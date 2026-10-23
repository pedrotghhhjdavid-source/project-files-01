--[[=================================================================
    VENICE x RIVALS  |  TEXTURA PERSONALIZADA EN LA ARENA + SFX
    ------------------------------------------------------------------
    * Boton -> pone TU imagen (cruz con alas) en la arena / suelo
    * Usa MaterialVariant (ligero, no laguea) con modo compatible
    * Reproductor de cualquier sonido: loop, volumen, tono
    * Abrir / cerrar panel: RightShift o el boton flotante
    * Basado en la tecnica del script fleasion (scriptblox)
===================================================================]]

local Players         = game:GetService("Players")
local UIS             = game:GetService("UserInputService")
local MaterialService = game:GetService("MaterialService")
local SoundService    = game:GetService("SoundService")
local TweenService    = game:GetService("TweenService")
local LP              = Players.LocalPlayer
local WS              = workspace

if getgenv and getgenv().VeniceRivalsTex then
    pcall(function() getgenv().VeniceRivalsTex:Destroy() end)
end

local isUnloaded = false
local Conn = {}
local function track(c) table.insert(Conn, c) return c end

local TargetParent = game:GetService("CoreGui")
if gethui then pcall(function() TargetParent = gethui() end) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VeniceRivalsTex"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = TargetParent end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end
if getgenv then getgenv().VeniceRivalsTex = ScreenGui end

--=================================================================
--  CONFIG
--=================================================================
local DEFAULT_IMG = "https://cdn.supercoloring.com/coloring/497496/cross-with-wings-coloring-page-md.png"
local FALLBACKS   = { "https://cdn.supercoloring.com/coloring/497496/cross-with-wings-coloring-page-sm.webp" }

local CFG = {
    tiling     = 10,
    onlySand   = true,
    withChars  = false,
    withTerrain= true,
    autoApply  = true,
    volume     = 1,
    pitch      = 1,
    loop       = false,
    sound      = nil,
    asset      = nil,
    variantMode= true,
}

--=================================================================
--  NOTIFICACIONES (estilo fleasion)
--=================================================================
local function notify(title, body, dur)
    if isUnloaded then return end
    dur = dur or 4
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 260, 0, 50)
    f.Position = UDim2.new(0, -290, 1, -70)
    f.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    f.BorderColor3 = Color3.fromRGB(65, 65, 70)
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
    t.TextColor3 = Color3.fromRGB(160, 140, 255)
    t.Text = title
    t.ZIndex = 201
    t.Parent = f

    local b = Instance.new("TextLabel")
    b.Size = UDim2.new(1, -16, 0, 22)
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
        Position = UDim2.new(0, 12, 1, -70) }):Play()
    task.delay(dur, function()
        if isUnloaded or not f.Parent then return end
        local o = TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0, -290, 1, -70) })
        o:Play()
        o.Completed:Connect(function() f:Destroy() end)
    end)
end

--=================================================================
--  DESCARGA DEL ASSET (tecnica del fleasion)
--=================================================================
local function hashStr(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 99999989 end
    return tostring(h)
end

local function resolve(input, silent)
    local raw = tostring(input or ""):gsub("%s", "")
    if raw == "" then raw = DEFAULT_IMG end

    local num = raw:match("^%d+$") or raw:match("rbxassetid://(%d+)")
    if num then return "rbxassetid://" .. num end

    local ext = raw:match("%.png") and ".png"
        or raw:match("%.webp") and ".webp"
        or raw:match("%.jpe?g") and ".jpg" or ".png"

    if not (writefile and isfile and getcustomasset) then
        if not silent then notify("Aviso", "Tu executor no tiene writefile/getcustomasset, uso la URL directa.") end
        return raw
    end

    local fileName = "venice_tex_" .. hashStr(raw) .. ext
    local ok, res = pcall(function()
        if not isfile(fileName) then
            writefile(fileName, game:HttpGet(raw))
        end
        return getcustomasset(fileName)
    end)
    if ok and res then return res end
    if not silent then notify("Error", "No pude descargar la imagen, prueba con una ID de Roblox.") end
    return raw
end

local function loadAsset(input, silent)
    local a = resolve(input, silent)
    CFG.asset = a
    return a
end

--=================================================================
--  SISTEMA DE TEXTURA POR MATERIAL (MaterialVariant)
--=================================================================
local VARIANTS = {}          -- [nombreMaterial] = MaterialVariant
local BACKUP   = {}          -- [part] = MaterialVariant original
local Terrain  = WS:FindFirstChildOfClass("Terrain")

local function batch(list, fn, size)
    size = size or 250
    task.spawn(function()
        for i = 1, #list do
            if isUnloaded then break end
            pcall(fn, list[i])
            if i % size == 0 then task.wait() end
        end
    end)
end

local function getVariant(material)
    local name = "VNTex_" .. material.Name
    local v = VARIANTS[material.Name]
    if v and v.Parent then return v end

    local old = MaterialService:FindFirstChild(name)
    if old then old:Destroy() end

    local mv = Instance.new("MaterialVariant")
    mv.Name = name
    pcall(function() mv.BasePartMaterial = material end)
    local okA = pcall(function() mv.AlbedoMap = CFG.asset end)
    if not okA then pcall(function() mv.TextureMap = CFG.asset end) end
    pcall(function()
        mv.StudsPerTileU = CFG.tiling
        mv.StudsPerTileV = CFG.tiling
    end)
    pcall(function() mv.Parent = MaterialService end)
    if not mv.Parent then mv.Parent = MaterialService end
    VARIANTS[material.Name] = mv
    return mv
end

local function isCharPart(part)
    if CFG.withChars then return false end
    if LP.Character and part:IsDescendantOf(LP.Character) then return true end
    local m = part:FindFirstAncestorWhichIsA("Model")
    if m and m:FindFirstChildOfClass("Humanoid") then return true end
    return false
end

local function paintPart(part)
    if isUnloaded or CFG.asset == nil then return end
    if not part:IsA("BasePart") or part:IsA("Terrain") then return end
    if part.Parent and part.Parent.Name == "Camera" then return end
    if isCharPart(part) then return end
    if CFG.onlySand and part.Material ~= Enum.Material.Sand then return end

    if BACKUP[part] == nil then BACKUP[part] = part.MaterialVariant end
    local mv = getVariant(part.Material)
    pcall(function() part.MaterialVariant = mv.Name end)
end

local function paintTerrain()
    if not Terrain or not CFG.withTerrain then return end
    local mv = getVariant(Enum.Material.Sand)
    pcall(function() Terrain:SetMaterialVariant(Enum.Material.Sand, mv) end)
end

local function paintAll()
    if CFG.asset == nil then return end
    local list = WS:GetDescendants()
    batch(list, paintPart, 300)
    paintTerrain()
    task.wait(0.3)
    notify("Textura aplicada", CFG.onlySand and "Arena / Sand del mapa lista." or "Mapa completo texturizado.", 3)
end

local function unpaint()
    for part, orig in pairs(BACKUP) do
        if part and part.Parent then
            pcall(function() part.MaterialVariant = orig end)
        end
    end
    BACKUP = {}
    if Terrain then
        for _, m in ipairs({ Enum.Material.Sand }) do
            pcall(function() Terrain:SetMaterialVariant(m, nil) end)
        end
    end
    for _, mv in pairs(VARIANTS) do pcall(function() mv:Destroy() end) end
    VARIANTS = {}
    notify("Textura quitada", "El mapa volvio a lo normal.", 3)
end

local function refreshTiling()
    for _, mv in pairs(VARIANTS) do
        pcall(function()
            mv.StudsPerTileU = CFG.tiling
            mv.StudsPerTileV = CFG.tiling
        end)
    end
end

--=================================================================
--  SONIDO
--=================================================================
local function stopSound()
    if CFG.sound then pcall(function() CFG.sound:Destroy() end) CFG.sound = nil end
end

local function playSound(idOrUrl)
    local a = resolve(idOrUrl, true)
    stopSound()
    local s = Instance.new("Sound")
    s.Name = "VeniceSFX"
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
local BG, PANEL, TEXT, MUTED =
    Color3.fromRGB(18, 18, 20), Color3.fromRGB(28, 28, 33),
    Color3.fromRGB(225, 225, 230), Color3.fromRGB(150, 150, 158)

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then i[k] = v end end
    if parent then i.Parent = parent end
    return i
end

local Main = new("Frame", {
    Size = UDim2.new(0, 320, 0, 430), Position = UDim2.new(0, 16, 0, 60),
    BackgroundColor3 = BG, BorderColor3 = Color3.fromRGB(60, 60, 68),
}, ScreenGui)

local Title = new("TextLabel", {
    Size = UDim2.new(1, -12, 0, 24), Position = UDim2.new(0, 8, 0, 3),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    Text = "venice x rivals | textura de arena + sfx", TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Main)

local ToggleBtn = new("TextButton", {
    Size = UDim2.new(0, 130, 0, 28), Position = UDim2.new(0, 12, 0, 30),
    BackgroundColor3 = Color3.fromRGB(22, 22, 26), BorderColor3 = Color3.fromRGB(75, 75, 82),
    Font = Enum.Font.Code, TextSize = 12, Text = "cerrar ui [X]", TextColor3 = TEXT,
}, ScreenGui)
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local function syncBtn() ToggleBtn.Text = Main.Visible and "cerrar ui [X]" or "abrir ui [X]" end

track(ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    syncBtn()
end))

track(UIS.InputBegan:Connect(function(i, gpe)
    if not gpe and i.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
        syncBtn()
    end
end))

local Scroll = new("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -66), Position = UDim2.new(0, 5, 0, 62),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, Main)
new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, Scroll)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Scroll)

local function section(txt, order)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.Code,
        TextSize = 11, Text = txt, TextColor3 = ACCENT,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
    }, Scroll)
end

local function button(txt, order, color, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = color or Color3.fromRGB(25, 25, 30),
        BorderColor3 = Color3.fromRGB(65, 65, 72), Font = Enum.Font.Code, TextSize = 11,
        Text = txt, TextColor3 = TEXT, LayoutOrder = order,
    }, Scroll)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then notify("Error", tostring(err)) end
    end)
    return b
end

local function box(ph, order, default)
    return new("TextBox", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
        BorderColor3 = Color3.fromRGB(60, 60, 66), Font = Enum.Font.Code, TextSize = 11,
        Text = default or "", PlaceholderText = ph, TextColor3 = TEXT,
        PlaceholderColor3 = MUTED, ClearTextOnFocus = false, LayoutOrder = order,
    }, Scroll)
end

local function toggleRow(label, order, default, cb)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = order }, Scroll)
    new("TextLabel", {
        Size = UDim2.new(0.7, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code,
        TextSize = 11, Text = label, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local st = default and true or false
    local b = new("TextButton", {
        Size = UDim2.new(0, 54, 0, 22), Position = UDim2.new(1, -54, 0.5, -11),
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
        lbl.Text = label .. ": " .. string.format("%.2f", v)
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
section("TEXTURA DE LA ARENA", 1)

local Preview = new("ImageLabel", {
    Size = UDim2.new(0, 64, 0, 64), Position = UDim2.new(1, -70, 0, 0),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(70, 70, 78),
    LayoutOrder = 1, Image = "",
}, Scroll)

local ImgBox = box("URL o ID de imagen (vacio = cruz con alas)", 2, DEFAULT_IMG)
ImgBox.Size = UDim2.new(1, -80, 0, 30)

button("APLICAR A LA ARENA (material Sand)", 3, Color3.fromRGB(45, 35, 70), function()
    local a = loadAsset(ImgBox.Text, true)
    Preview.Image = a
    CFG.onlySand = true
    paintAll()
end)

button("APLICAR A TODO EL MAPA", 4, Color3.fromRGB(35, 35, 48), function()
    local a = loadAsset(ImgBox.Text, true)
    Preview.Image = a
    CFG.onlySand = false
    paintAll()
end)

button("QUITAR TEXTURA / RESTAURAR", 5, Color3.fromRGB(30, 30, 36), function()
    unpaint()
end)

button("USAR LA CRUZ CON ALAS", 6, Color3.fromRGB(30, 30, 36), function()
    ImgBox.Text = DEFAULT_IMG
    local a = loadAsset(DEFAULT_IMG)
    Preview.Image = a
    notify("Imagen lista", "Cruz con alas cargada.", 3)
end)

toggleRow("solo material Sand (arena)", 7, true, function(v) CFG.onlySand = v end)
toggleRow("incluir terreno (Terrain)", 8, true, function(v) CFG.withTerrain = v end)
toggleRow("incluir jugadores / armas", 9, false, function(v) CFG.withChars = v end)
toggleRow("auto-aplicar a partes nuevas", 10, true, function(v) CFG.autoApply = v end)

sliderRow("Repeticion de textura", 1, 40, 10, 11, function(v)
    CFG.tiling = v
    refreshTiling()
end)

section("SONIDO", 12)
local SndBox = box("URL o ID de sonido", 13)
button("Reproducir", 14, Color3.fromRGB(45, 35, 70), function()
    local txt = SndBox.Text
    if tostring(txt):gsub("%s", "") == "" then notify("Sonido", "Pega una ID o URL de sonido.") return end
    playSound(txt)
    notify("Sonido", "Reproduciendo...", 2)
end)
button("Detener", 15, Color3.fromRGB(30, 30, 36), function() stopSound() end)
toggleRow("loop", 16, false, function(v)
    CFG.loop = v
    if CFG.sound then CFG.sound.Looped = v end
end)
sliderRow("Volumen", 0, 3, 1, 17, function(v)
    CFG.volume = v
    if CFG.sound then CFG.sound.Volume = v end
end)
sliderRow("Tono / velocidad", 0.2, 3, 1, 18, function(v)
    CFG.pitch = v
    if CFG.sound then CFG.sound.PlaybackSpeed = v end
end)

section("INFO", 19)
new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextSize = 10, TextWrapped = true, LayoutOrder = 20, TextColor3 = Color3.fromRGB(235, 180, 90),
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Ejecuta dentro de Rivals y aplica cuando el mapa ya cargo.\nSi el mapa cambia, vuelve a dar APLICAR.",
}, Scroll)

local UnloadBtn = button("UNLOAD SCRIPT", 21, Color3.fromRGB(60, 25, 25), function()
    if isUnloaded then return end
    isUnloaded = true
    for _, c in ipairs(Conn) do pcall(function() c:Disconnect() end) end
    unpaint()
    stopSound()
    pcall(function() ScreenGui:Destroy() end)
    pcall(function() collectgarbage("collect") end)
end)

--=================================================================
--  AUTO APLICAR
--=================================================================
track(WS.DescendantAdded:Connect(function(obj)
    if isUnloaded or not CFG.autoApply or CFG.asset == nil then return end
    if obj:IsA("BasePart") and not obj:IsA("Terrain") then
        task.defer(function() if obj.Parent then paintPart(obj) end end)
    end
end))

--=================================================================
--  ARRANQUE
--=================================================================
task.spawn(function()
    local a = loadAsset(DEFAULT_IMG, true)
    Preview.Image = a
    notify("Script cargado", "venice x rivals listo. Dale APLICAR.", 4)
end)