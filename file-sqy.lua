--[[=================================================================
    VENICE x RIVALS - TEXTURE INJECTOR v2
    ------------------------------------------------------------------
    * Pone TU imagen en todas las paredes / suelo del mapa de Rivals
    * Vista previa para comprobar que la imagen cargo bien
    * Boton DIAGNOSTICO para saber que hay en el mapa
    * Reproductor de sonidos + restore + unload
    * Abrir / cerrar: RightShift o el boton "ui"
===================================================================]]

local Players         = game:GetService("Players")
local UIS             = game:GetService("UserInputService")
local SoundService    = game:GetService("SoundService")
local TweenService    = game:GetService("TweenService")
local LP              = Players.LocalPlayer
local WS              = workspace

if getgenv and getgenv().VeniceRivalsTex2 then
    pcall(function() getgenv().VeniceRivalsTex2:Destroy() end)
end

local isUnloaded = false
local Conn = {}
local function track(c) table.insert(Conn, c) return c end

local TargetParent = game:GetService("CoreGui")
if gethui then pcall(function() TargetParent = gethui() end) end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VeniceRivalsTex2"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = TargetParent end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end
if getgenv then getgenv().VeniceRivalsTex2 = ScreenGui end

--=================================================================
--  CONFIG
--=================================================================
local DEFAULT_IMG = "https://cdn.supercoloring.com/coloring/497496/cross-with-wings-coloring-page-md.png"
local MIRRORS = {
    DEFAULT_IMG,
    "https://cdn.supercoloring.com/coloring/497496/cross-with-wings-coloring-page-sm.webp",
}

local CFG = {
    asset     = nil,
    tiling    = 8,
    allFaces  = true,
    minSize   = 1,
    skipChars = true,
    autoNew   = true,
    volume    = 1,
    pitch     = 1,
    loop      = false,
    sound     = nil,
}

local CREATED = {}   -- [Texture] = true
local BACKUP  = {}   -- [inst] = { prop = valor original }
local paintedCount = 0

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
--  DESCARGA DE LA IMAGEN
--=================================================================
local function fetchImage(url)
    local body
    local ok = pcall(function() body = game:HttpGet(url) end)
    if not (ok and body and #body > 200) then
        if request then
            local o, r = pcall(function() return request({ Url = url, Method = "GET" }) end)
            if o and r and r.Body and #r.Body > 200 then body = r.Body end
        end
    end
    if not body or #body < 200 then return nil end
    local head = body:sub(1, 12)
    if head:find("PNG") or head:find("JFIF") or head:find("RIFF") or body:sub(1, 3) == "\255\216\255" then
        return body
    end
    return nil
end

local function hashStr(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 99999989 end
    return tostring(h)
end

local function resolve(input)
    local raw = tostring(input or ""):gsub("%s", "")
    if raw == "" then raw = DEFAULT_IMG end

    local num = raw:match("^%d+$") or raw:match("rbxassetid://(%d+)")
    if num then return "rbxassetid://" .. num, "id" end

    local ext = raw:match("%.png") and ".png" or raw:match("%.webp") and ".webp"
        or raw:match("%.jpe?g") and ".jpg" or ".png"

    if not (writefile and isfile and getcustomasset) then
        return raw, "url-directa"
    end

    local file = "vnr_" .. hashStr(raw) .. ext
    if isfile(file) then
        local ok, p = pcall(getcustomasset, file)
        if ok and p then return p, "cache" end
    end

    local body = fetchImage(raw)
    if not body then return nil, "fallo-descarga" end

    local ok = pcall(function() writefile(file, body) end)
    if not ok then return nil, "fallo-escritura" end
    local ok2, path = pcall(getcustomasset, file)
    if not (ok2 and path) then return nil, "fallo-asset" end
    return path, "descargado"
end

--=================================================================
--  APLICAR TEXTURAS
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

local function paintPart(part)
    if isUnloaded or not CFG.asset then return end
    if not part:IsA("BasePart") or part:IsA("Terrain") then return end
    if part.Transparency >= 1 then return end
    if part.Parent and part.Parent.Name == "Camera" then return end
    if CFG.skipChars and isCharPart(part) then return end
    if CFG.minSize > 0 then
        local s = math.max(part.Size.X, part.Size.Y, part.Size.Z)
        if s < CFG.minSize then return end
    end

    local faces = CFG.allFaces and FACES_ALL or FACES_VIS
    for _, face in ipairs(faces) do
        local found
        for _, c in ipairs(part:GetChildren()) do
            if c:IsA("Texture") and c.Face == face then found = c break end
        end
        if found then
            if not BACKUP[found] then
                BACKUP[found] = {
                    Texture = found.Texture,
                    StudsPerTileU = found.StudsPerTileU,
                    StudsPerTileV = found.StudsPerTileV,
                    Transparency = found.Transparency,
                }
            end
            pcall(function()
                found.Texture = CFG.asset
                found.StudsPerTileU = CFG.tiling
                found.StudsPerTileV = CFG.tiling
                found.Transparency = 0
            end)
        else
            local t = Instance.new("Texture")
            t.Face = face
            t.Texture = CFG.asset
            t.StudsPerTileU = CFG.tiling
            t.StudsPerTileV = CFG.tiling
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
        notify("Listo", paintedCount .. " partes texturizadas del mapa.", 4)
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
    notify("Restaurado", "El mapa volvio a lo normal.", 3)
end

local function refreshTiling()
    for inst in pairs(CREATED) do
        pcall(function() inst.StudsPerTileU = CFG.tiling inst.StudsPerTileV = CFG.tiling end)
    end
    for inst in pairs(BACKUP) do
        pcall(function() inst.StudsPerTileU = CFG.tiling inst.StudsPerTileV = CFG.tiling end)
    end
end

--=================================================================
--  DIAGNOSTICO
--=================================================================
local function diagnose()
    local parts, meshes, sa, terrain = 0, 0, 0, WS:FindFirstChildOfClass("Terrain") ~= nil
    local mats = {}
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("BasePart") and not d:IsA("Terrain") then
            parts += 1
            if d:IsA("MeshPart") then meshes += 1 end
            if d:FindFirstChildOfClass("SurfaceAppearance") then sa += 1 end
            mats[d.Material.Name] = (mats[d.Material.Name] or 0) + 1
        end
    end
    local top = {}
    for name, n in pairs(mats) do table.insert(top, { n, name }) end
    table.sort(top, function(a, b) return a[1] > b[1] end)
    local txt = {}
    for i = 1, math.min(4, #top) do
        table.insert(txt, top[i][2] .. " x" .. top[i][1])
    end
    local msg = "partes: " .. parts .. " | mesh: " .. meshes .. " | terrain: " .. tostring(terrain)
        .. " | surfaceApp: " .. sa .. " | materiales: " .. table.concat(txt, ", ")
    notify("Diagnostico", msg, 8)
    print("[VENICE] " .. msg)
    print("[VENICE] writefile: " .. tostring(writefile ~= nil)
        .. " | getcustomasset: " .. tostring(getcustomasset ~= nil))
    return msg
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
    local a = raw:match("^%d+$") and ("rbxassetid://" .. raw) or raw
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
local BG, PANEL, TEXT, MUTED =
    Color3.fromRGB(18, 18, 20), Color3.fromRGB(26, 26, 31),
    Color3.fromRGB(228, 228, 232), Color3.fromRGB(150, 150, 158)

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do if k ~= "Parent" then i[k] = v end end
    if parent then i.Parent = parent end
    return i
end

local Main = new("Frame", {
    Size = UDim2.new(0, 320, 0, 440), Position = UDim2.new(0, 16, 0, 60),
    BackgroundColor3 = BG, BorderColor3 = Color3.fromRGB(60, 60, 68),
}, ScreenGui)

new("TextLabel", {
    Size = UDim2.new(1, -12, 0, 22), Position = UDim2.new(0, 8, 0, 3),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    Text = "venice x rivals | texture injector v2", TextColor3 = TEXT,
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

local function button(txt, order, color, cb)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = color or Color3.fromRGB(25, 25, 30),
        BorderColor3 = Color3.fromRGB(65, 65, 72), Font = Enum.Font.Code, TextSize = 11,
        Text = txt, TextColor3 = TEXT, LayoutOrder = order,
    }, Scroll)
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
section("IMAGEN", 1)

local Preview = new("ImageLabel", {
    Size = UDim2.new(0, 78, 0, 78), Position = UDim2.new(1, -84, 0, 0),
    BackgroundColor3 = Color3.fromRGB(240, 240, 245), BorderColor3 = Color3.fromRGB(80, 80, 90),
    LayoutOrder = 1, Image = "",
}, Scroll)

local ImgBox = new("TextBox", {
    Size = UDim2.new(1, -94, 0, 60), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    BorderColor3 = Color3.fromRGB(60, 60, 66), Font = Enum.Font.Code, TextSize = 10,
    Text = DEFAULT_IMG, TextWrapped = true, TextColor3 = TEXT,
    ClearTextOnFocus = false, LayoutOrder = 2, TextYAlignment = Enum.TextYAlignment.Top,
}, Scroll)

button("CARGAR / PROBAR IMAGEN", 3, Color3.fromRGB(40, 32, 62), function()
    local a, how = resolve(ImgBox.Text)
    if not a then
        notify("Fallo", "No pude descargar esa imagen. Prueba con una ID de Roblox.", 7)
        return
    end
    CFG.asset = a
    Preview.Image = a
    notify("Imagen cargada", "Origen: " .. tostring(how) .. ". Revisa la vista previa.", 5)
end)

button("APLICAR A TODO EL MAPA", 4, Color3.fromRGB(55, 42, 92), function()
    if not CFG.asset then
        local a, how = resolve(ImgBox.Text)
        if not a then notify("Fallo", "No pude cargar la imagen.", 7) return end
        CFG.asset = a
        Preview.Image = a
    end
    paintAll()
end)

button("RESTAURAR MAPA", 5, Color3.fromRGB(30, 30, 36), function() restore() end)

section("OPCIONES", 6)
toggleRow("todas las caras (6)", 7, true, function(v) CFG.allFaces = v end)
toggleRow("excluir jugadores / armas", 8, true, function(v) CFG.skipChars = v end)
toggleRow("auto-aplicar a partes nuevas", 9, true, function(v) CFG.autoNew = v end)

sliderRow("Repeticion de textura", 1, 40, 8, 10, function(v)
    CFG.tiling = v
    refreshTiling()
end)
sliderRow("Tamano minimo de parte", 0, 20, 1, 11, function(v)
    CFG.minSize = v
end)

section("SONIDO", 12)
local SndBox = new("TextBox", {
    Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(22, 22, 26),
    BorderColor3 = Color3.fromRGB(60, 60, 66), Font = Enum.Font.Code, TextSize = 11,
    Text = "", PlaceholderText = "ID o URL de sonido", PlaceholderColor3 = MUTED,
    TextColor3 = TEXT, ClearTextOnFocus = false, LayoutOrder = 13,
}, Scroll)

button("Reproducir", 14, Color3.fromRGB(40, 32, 62), function()
    playSound(SndBox.Text)
    notify("Sonido", "Reproduciendo...", 2)
end)
button("Detener", 15, Color3.fromRGB(30, 30, 36), function() stopSound() end)
toggleRow("loop", 16, false, function(v) CFG.loop = v if CFG.sound then CFG.sound.Looped = v end end)
sliderRow("Volumen", 0, 3, 1, 17, function(v) CFG.volume = v if CFG.sound then CFG.sound.Volume = v end end)
sliderRow("Tono", 0.2, 3, 1, 18, function(v) CFG.pitch = v if CFG.sound then CFG.sound.PlaybackSpeed = v end end)

section("EXTRA", 19)
button("DIAGNOSTICO DEL MAPA", 20, Color3.fromRGB(30, 30, 36), function() diagnose() end)

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, Font = Enum.Font.Code,
    TextSize = 10, TextWrapped = true, LayoutOrder = 21, TextColor3 = Color3.fromRGB(235, 180, 90),
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "1) CARGAR / PROBAR IMAGEN -> si la vista previa sale en blanco, la descarga fallo.\n"
        .. "2) APLICAR. Si el mapa no cambia, dale DIAGNOSTICO y dime que dice.",
}, Scroll)

button("UNLOAD SCRIPT", 22, Color3.fromRGB(60, 25, 25), function()
    if isUnloaded then return end
    isUnloaded = true
    for _, c in ipairs(Conn) do pcall(function() c:Disconnect() end) end
    restore()
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
task.spawn(function()
    local a, how = resolve(DEFAULT_IMG)
    if a then
        CFG.asset = a
        Preview.Image = a
        notify("Script cargado", "Imagen lista (" .. tostring(how) .. "). Dale APLICAR.", 5)
    else
        notify("Script cargado", "No pude bajar la cruz, pega una ID de Roblox.", 6)
    end
end)
