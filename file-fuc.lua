--[[=====================================================================
  SHAKO · RIO + CAPA COMPAT v1.2  ·  Delta / Android / executor-agnostic
  ---------------------------------------------------------------------
  MODO 1 ARCHIVO:  LoadRioFromUrl = false  -> pegá tu script abajo del todo
  MODO 2 ARCHIVOS: LoadRioFromUrl = true   -> subí rio.lua aparte a GitHub
  ---------------------------------------------------------------------
  Nada de tu código original fue modificado.
======================================================================]]

--=========================== AJUSTES ===========================
local CFG = {
    Buttons              = true,   -- botones MENU / AIM / STOP en pantalla
    MobileDefaults       = true,   -- perfiles de rendimiento en móvil
    OverrideTargetPicker = true,   -- apuntar al centro de pantalla (coherente con el FOV)
    FpsCap               = 60,     -- nil para no tocar el FPS

    LoadRioFromUrl       = false,  -- true = descarga tu script desde GitHub
    RioUrl               = "https://raw.githubusercontent.com/TU_USUARIO/TU_REPO/main/rio.lua",
}
--===============================================================

local SHC = {}
getgenv()._SHC = SHC

local _svc = function(n) return game:GetService(n) end
local UIS = _svc("UserInputService")
local RS  = _svc("RunService")
local PLR = _svc("Players")
local LP  = PLR.LocalPlayer
local VIM = _svc("VirtualInputManager")

SHC.touch  = UIS.TouchEnabled
SHC.mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
if not SHC.mobile and UIS.TouchEnabled and UIS.MouseEnabled == false then SHC.mobile = true end

SHC.overrideTargetPicker = CFG.OverrideTargetPicker

local function shcNotify(txt)
    pcall(function()
        _svc("StarterGui"):SetCore("SendNotification", {
            Title = "shako compat", Text = tostring(txt), Duration = 4,
        })
    end)
end

--========================= 1) POLYFILLS =========================
if not getgenv then function getgenv() return _G end end
if not getrenv then getrenv = function() return _G end end
if not newcclosure then newcclosure = function(f) return f end end
if not cloneref then cloneref = function(o) return o end end
if not setreadonly then setreadonly = function() end end
if not isreadonly then isreadonly = function() return false end end
if not getrawmetatable then getrawmetatable = function(o) return getmetatable(o) end end
if not getnamecallmethod then getnamecallmethod = function() return getgenv()._shc_method or "" end end
if not setthreadidentity and setidentity then setthreadidentity = setidentity end
if not getthreadidentity then getthreadidentity = function() return 8 end end
if not getgc then getgc = function() return {} end end
if not gethui then
    gethui = function()
        local ok, cg = pcall(function() return _svc("CoreGui") end)
        if ok and cg then return cg end
        return LP and LP:FindFirstChild("PlayerGui")
    end
end

-- file API stub: si el executor no tiene writefile, SaveManager ya no revienta
if not writefile then
    local mem = {}
    function writefile(n, c) mem[n] = tostring(c) end
    function readfile(n) return mem[n] end
    function isfile(n) return mem[n] ~= nil end
    function isfolder() return true end
    function makefolder() end
    function delfile(n) mem[n] = nil end
    function listfiles() return {} end
    function appendfile(n, c) mem[n] = (mem[n] or "") .. tostring(c) end
end

-- mouse fallbacks (triggerbot / autoclick en móvil)
if not mouse1press then
    mouse1press = function() pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0) end) end
end
if not mouse1release then
    mouse1release = function() pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end) end
end
if not mouse1click then
    mouse1click = function() mouse1press() task.wait(0.012) mouse1release() end
end

-- en táctil mousemoverel NO rota la cámara -> lo neutralizamos (apuntamos por cámara)
if SHC.touch and type(mousemoverel) == "function" then
    SHC._oldMouseRel = mousemoverel
    mousemoverel = function() end
end

if SHC.mobile and CFG.FpsCap and type(setfpscap) == "function" then
    pcall(setfpscap, CFG.FpsCap)
end

SHC.hasHook   = type(hookfunction) == "function"
SHC.hasHookMM = type(hookmetamethod) == "function"
if not SHC.hasHook then shcNotify("sin hookfunction: Silent/AA/anti-cheat OFF") end

-- HttpGet con reintentos (móvil / 4G)
pcall(function()
    local raw = game.HttpGet
    if type(raw) ~= "function" then return end
    game.HttpGet = function(self, url, ...)
        local last
        for _ = 1, 3 do
            local ok, res = pcall(raw, self, url, ...)
            if ok and type(res) == "string" and #res > 0 then return res end
            last = res
            task.wait(0.4)
        end
        return last
    end
end)

--============= 2) DRAWING SHIM (si el executor no tiene Drawing) =============
if not Drawing then
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ShakoDrawingShim"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 99970
        local okp = pcall(function() gui.Parent = gethui() end)
        if not okp or not gui.Parent then
            gui.Parent = LP and LP:WaitForChild("PlayerGui", 10) or nil
        end

        local mt = {}
        local FONTMAP = { [0]=Enum.Font.Legacy, [1]=Enum.Font.Arial, [2]=Enum.Font.ArialBold, [3]=Enum.Font.SourceSans }

        local function apply(o, k, v)
            local i = o.__i
            if not i then return end
            if k == "Visible" then i.Visible = v and true or false
            elseif k == "ZIndex" then i.ZIndex = tonumber(v) or 1
            elseif k == "Color" then
                if i:IsA("TextLabel") then i.TextColor3 = v else i.BackgroundColor3 = v end
                if o.__stroke then o.__stroke.Color = v end
            elseif k == "Transparency" then
                if i:IsA("TextLabel") then i.TextTransparency = v else i.BackgroundTransparency = v end
                if o.__stroke then o.__stroke.Transparency = v end
            elseif k == "Thickness" then
                if o.__stroke then o.__stroke.Thickness = v end
                o.__th = v
                if o.__kind == "Line" then apply(o, "From", o.From) end
            elseif k == "Radius" then
                i.Size = UDim2.fromOffset(v * 2, v * 2)
            elseif k == "Filled" then
                if o.__stroke then o.__stroke.Enabled = not v end
                if not i:IsA("TextLabel") then
                    i.BackgroundTransparency = v and 0 or 1
                end
            elseif k == "From" or k == "To" then
                local a, b = o.From, o.To
                if a and b then
                    local d = b - a
                    local len = math.max(d.Magnitude, 1)
                    i.AnchorPoint = Vector2.new(0, 0.5)
                    i.Position = UDim2.fromOffset(math.floor((a.X + b.X) / 2), math.floor((a.Y + b.Y) / 2))
                    i.Size = UDim2.fromOffset(math.floor(len), math.max(math.floor(o.__th or 1), 1))
                    i.Rotation = math.deg(math.atan2(d.Y, d.X))
                end
            elseif k == "Position" then
                i.Position = UDim2.fromOffset(math.floor(v.X), math.floor(v.Y))
            elseif k == "Center" then
                if v then
                    i.AnchorPoint = Vector2.new(0.5, 0.5)
                    i.TextXAlignment = Enum.TextXAlignment.Center
                    i.TextYAlignment = Enum.TextYAlignment.Center
                else
                    i.AnchorPoint = Vector2.new(0, 0)
                    i.TextXAlignment = Enum.TextXAlignment.Left
                end
            elseif k == "Text" then i.Text = tostring(v)
            elseif k == "Size" and i:IsA("TextLabel") then i.TextSize = tonumber(v) or 12
            elseif k == "Font" and i:IsA("TextLabel") then i.Font = FONTMAP[tonumber(v) or 3] or Enum.Font.SourceSans
            elseif k == "Outline" then
                if o.__stroke then o.__stroke.Enabled = v and true or false end
            elseif k == "PointA" or k == "PointB" or k == "PointC" then
                local xs, ys = {}, {}
                for _, p in ipairs({ o.PointA, o.PointB, o.PointC }) do
                    if p then xs[#xs+1] = p.X ys[#ys+1] = p.Y end
                end
                if #xs > 0 then
                    table.sort(xs) table.sort(ys)
                    local w = math.max(xs[#xs] - xs[1], 2)
                    local h = math.max(ys[#ys] - ys[1], 2)
                    i.AnchorPoint = Vector2.new(0, 0)
                    i.Position = UDim2.fromOffset(math.floor(xs[1]), math.floor(ys[1]))
                    i.Size = UDim2.fromOffset(math.floor(w), math.floor(h))
                end
            end
        end

        mt.__newindex = function(o, k, v)
            rawset(o, k, v)
            pcall(apply, o, k, v)
        end
        mt.__index = mt
        mt.Remove = function(o) pcall(function() if o.__i then o.__i:Destroy() end end) end

        local function newObj(kind)
            local o = setmetatable({}, mt)
            o.__kind = kind
            local i
            if kind == "Line" then
                i = Instance.new("Frame"); i.BorderSizePixel = 0
            elseif kind == "Text" then
                i = Instance.new("TextLabel")
                i.BackgroundTransparency = 1; i.BorderSizePixel = 0
                i.AutomaticSize = Enum.AutomaticSize.XY
                i.Size = UDim2.fromOffset(0, 0)
                local s = Instance.new("UIStroke"); s.Thickness = 1; s.Parent = i
                o.__stroke = s
            elseif kind == "Circle" then
                i = Instance.new("Frame"); i.BorderSizePixel = 0
                i.AnchorPoint = Vector2.new(0.5, 0.5)
                local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = i
                local s = Instance.new("UIStroke"); s.Thickness = 1; s.Parent = i
                o.__stroke = s
            else
                i = Instance.new("Frame"); i.BorderSizePixel = 0
                i.AnchorPoint = Vector2.new(0.5, 0.5)
            end
            i.Visible = false
            i.ZIndex = 2
            i.Parent = gui
            o.__i = i
            return o
        end

        Drawing = { new = newObj, Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3, Code = 3 } }
        getgenv().Drawing = Drawing
    end)
end

--================= 3) OVERLAY (MENU / AIM / STOP) =================
if CFG.Buttons then
    local POS_FILE = "shako_mobtools.txt"

    -- anti doble ejecución (no duplica botones)
    if getgenv()._SHC and getgenv()._SHC.gui then
        pcall(function() getgenv()._SHC.gui:Destroy() end)
    end

    local function uiParent()
        local ok, h = pcall(gethui)
        if ok and h then return h end
        return LP:WaitForChild("PlayerGui")
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakoMobileTools"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 99999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local okp = pcall(function() gui.Parent = uiParent() end)
    if not okp or not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui", 15) end

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.AnchorPoint = Vector2.new(0, 1)
    holder.Position = UDim2.new(0, 14, 1, -120)
    holder.Size = UDim2.fromOffset(56, 176)
    holder.BackgroundTransparency = 1
    holder.Parent = gui

    pcall(function()
        if isfile and readfile and isfile(POS_FILE) then
            local x, y = tostring(readfile(POS_FILE)):match("^(%-?%d+),(%-?%d+)$")
            if x then holder.Position = UDim2.new(0, tonumber(x), 1, tonumber(y)) end
        end
    end)

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = holder

    local function mkBtn(text, col, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(50, 50)
        b.BackgroundColor3 = col
        b.BackgroundTransparency = 0.15
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.LayoutOrder = order
        b.Parent = holder
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = b
        local s = Instance.new("UIStroke"); s.Color = Color3.new(0,0,0); s.Thickness = 1.5; s.Transparency = 0.35; s.Parent = b
        return b
    end

    local btnMenu = mkBtn("MENU", Color3.fromRGB(45, 105, 200), 1)
    local btnAim  = mkBtn("AIM",  Color3.fromRGB(35, 120, 65), 2)
    local btnStop = mkBtn("STOP", Color3.fromRGB(170, 50, 55), 3)

    local drag, lastDragEnd = nil, 0
    local function bindDrag(btn)
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
               or input.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = { start = input.Position, base = holder.Position, moved = false, input = input }
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End and drag and drag.input == input then
                        if drag.moved then
                            lastDragEnd = os.clock()
                            pcall(function()
                                if writefile then
                                    writefile(POS_FILE, tostring(holder.Position.X.Offset) .. "," .. tostring(holder.Position.Y.Offset))
                                end
                            end)
                        end
                        drag = nil
                    end
                end)
            end
        end)
    end
    bindDrag(btnMenu) bindDrag(btnAim) bindDrag(btnStop)

    UIS.InputChanged:Connect(function(input)
        if not drag or input ~= drag.input then return end
        local d = input.Position - drag.start
        if d.Magnitude > 8 then drag.moved = true end
        if drag.moved then
            holder.Position = UDim2.new(
                drag.base.X.Scale, drag.base.X.Offset + d.X,
                drag.base.Y.Scale, drag.base.Y.Offset + d.Y)
        end
    end)

    local function tap(btn, fn)
        btn.Activated:Connect(function()
            if os.clock() - lastDragEnd < 0.25 then return end
            pcall(fn)
        end)
    end

    -- MENU: simula la tecla del menú (funciona con Linoria/Obsidian y forks)
    tap(btnMenu, function()
        local name = (getgenv().config and getgenv().config.MenuKey) or getgenv()._ShakoMenuKey or "RightShift"
        local ok, kc = pcall(function() return Enum.KeyCode[name] end)
        if not ok or not kc then kc = Enum.KeyCode.RightShift end
        VIM:SendKeyEvent(true, kc, false, game)
        task.wait(0.06)
        VIM:SendKeyEvent(false, kc, false, game)
    end)

    -- AIM: aim propio por cámara + sincroniza el aimbot del menú
    tap(btnAim, function()
        SHC.aimOn = not SHC.aimOn
        btnAim.BackgroundColor3 = SHC.aimOn and Color3.fromRGB(60, 210, 100) or Color3.fromRGB(35, 120, 65)
        local st = getgenv()._ShakoAimKB
        if type(st) ~= "table" then st = { held = false, toggled = false } getgenv()._ShakoAimKB = st end
        st.toggled = SHC.aimOn
    end)

    -- STOP: emergencia total
    tap(btnStop, function() if SHC.stopAll then SHC.stopAll() end end)

    SHC.gui = gui
end

--================= 4) AIM MÓVIL POR CÁMARA =================
SHC.aimOn = false

function SHC.wallClear(from, to, char)
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    local ig = {}
    if LP.Character then ig[#ig+1] = LP.Character end
    if char then ig[#ig+1] = char end
    local vm = workspace:FindFirstChild("ViewModels")
    if vm then ig[#ig+1] = vm end
    p.FilterDescendantsInstances = ig
    p.IgnoreWater = true
    return workspace:Raycast(from, to - from, p) == nil
end

function SHC.pickTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local cfg = getgenv().config or {}
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local fov = tonumber(cfg.AimbotFOV) or 260
    local partName = cfg.AimbotPart or "Head"
    local best, bestD = nil, fov
    for _, plr in ipairs(PLR:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local enemy = true
            local f = getgenv().AimbotIsEnemy or getgenv().IsEnemy
            if type(f) == "function" then
                local ok, res = pcall(f, plr)
                if ok then enemy = res ~= false end
            end
            if enemy then
                local char = plr.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local part = char:FindFirstChild(partName) or char:FindFirstChild("Head")
                if hum and hum.Health > 0 and part then
                    local aimPos = part.Position
                    if cfg.AimbotPrediction and part.AssemblyLinearVelocity then
                        aimPos = aimPos + part.AssemblyLinearVelocity * 0.05
                    end
                    local sp, on = cam:WorldToViewportPoint(aimPos)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < bestD then
                            local vis = true
                            if cfg.AimbotWallCheck or cfg.AimbotVisibleCheck then
                                vis = SHC.wallClear(cam.CFrame.Position, aimPos, char)
                            end
                            if vis then bestD = d best = part end
                        end
                    end
                end
            end
        end
    end
    return best
end

if SHC.touch then
    local fovFrame = Instance.new("Frame")
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.BackgroundTransparency = 1
    fovFrame.Visible = false
    fovFrame.ZIndex = 5
    fovFrame.Parent = SHC.gui or LP:WaitForChild("PlayerGui", 15)
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fovFrame
    local fs = Instance.new("UIStroke"); fs.Thickness = 1.5
    fs.Color = Color3.fromRGB(255, 230, 80); fs.Transparency = 0.15; fs.Parent = fovFrame

    pcall(function() RS:UnbindFromRenderStep("__shc_mobaim") end)
    RS:BindToRenderStep("__shc_mobaim", Enum.RenderPriority.Camera.Value + 1, function()
        if not SHC.aimOn then
            if fovFrame.Visible then fovFrame.Visible = false end
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local cfg = getgenv().config or {}
        local fov = tonumber(cfg.AimbotFOV) or 260
        local vp = cam.ViewportSize
        if cfg.AimbotFOVColor then fs.Color = cfg.AimbotFOVColor end
        fovFrame.BackgroundColor3 = cfg.AimbotFOVColor or Color3.fromRGB(255, 230, 80)
        fovFrame.BackgroundTransparency = cfg.AimbotFOVFill and 0.85 or 1
        fovFrame.Size = UDim2.fromOffset(fov * 2, fov * 2)
        fovFrame.Position = UDim2.fromOffset(vp.X * 0.5, vp.Y * 0.5)
        fovFrame.Visible = cfg.AimbotShowFOV ~= false

        local target = SHC.pickTarget()
        if not target then return end
        local smooth = math.clamp(tonumber(cfg.AimbotSmooth) or 0.9, 0.15, 1)
        local cur = cam.CFrame
        local goal = CFrame.lookAt(cur.Position, target.Position)
        cam.CFrame = cur:Lerp(goal, smooth)
    end)
end

--================= 5) STOP DE EMERGENCIA =================
function SHC.stopAll()
    local cfg = getgenv().config or {}
    for _, k in ipairs({
        "Enabled","RagebotEnabled","VoidSpamEnabled","AntiAimEnabled","SilentAimEnabled",
        "FlyEnabled","NoclipEnabled","SleepyCounterEnabled","KiciaCounterEnabled","PredDodgeEnabled",
        "TriggerbotEnabled","StrafeEnabled","OrbitEnabled","StickBehindTP","FakePosition","BodyTwist",
        "UECounterEnabled","AntiUnnamed","ForceFieldVisual","AutoCollectHeals","RiotEnabled",
        "RiotAbuseEnabled","BlinkEnabled","ManipulationEnabled","AimbotEnabled","SpeedEnabled",
        "JumpPowerEnabled","SlideBoostEnabled",
    }) do
        if type(cfg[k]) == "boolean" then cfg[k] = false end
    end
    getgenv()._ShakoSilentActive = false
    local st = getgenv()._ShakoAimKB
    if type(st) == "table" then st.toggled = false st.held = false end
    SHC.aimOn = false
    for _, f in ipairs({
        "StopVoidSpam","StopSleepyCounter","StopKiciaCounter","StopPredDodge","StopAutoCollect",
        "StopForceField","StopStickBehindTP","StopFakePosition","StopUECounter","StopMatchAutos",
        "StopTriggerbot","StopRiot","StopRiotAbuse","StopBlink","StopDefense","StopManipulation",
        "StopBodyTwist","StopSilentAim","StopRagebot","StopAntiAim","StopFly","StopNoclip",
    }) do
        local fn = (getgenv()[f]) or _G[f]
        if type(fn) == "function" then pcall(fn) end
    end
    pcall(function()
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local h = _G.AxisRage
        if r and h and h.home then
            r.CFrame = h.home
            r.AssemblyLinearVelocity = Vector3.zero
        end
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
    shcNotify("STOP: todo apagado")
end

--============= 6) DEFAULTS MÓVIL + PARCHE POST-LOAD =============
task.spawn(function()
    local t0 = os.clock()
    repeat task.wait(0.1) until type(getgenv().config) == "table" or (os.clock() - t0) > 90
    local cfg = getgenv().config
    if type(cfg) ~= "table" then return end

    if CFG.MobileDefaults and SHC.mobile then
        cfg.ESPPerfMode        = true
        cfg.ESPUpdateInterval  = math.max(tonumber(cfg.ESPUpdateInterval) or 0.05, 0.08)
        cfg.ESPMaxPlayers      = math.min(tonumber(cfg.ESPMaxPlayers) or 8, 6)
        cfg.ESPSkeleton        = false
        cfg.ESPTracers         = false
        cfg.ESPRadar           = false
        cfg.WallXray           = false
        cfg.VMChams            = false
        cfg.RageVoidIterations = math.min(tonumber(cfg.RageVoidIterations) or 120, 60)
        cfg.AAPacketBurst      = math.min(tonumber(cfg.AAPacketBurst) or 5, 3)
        cfg.AimbotSmooth       = math.clamp(tonumber(cfg.AimbotSmooth) or 0.9, 0.35, 1)
        cfg.AimbotFOV          = math.min(tonumber(cfg.AimbotFOV) or 400, 300)
        cfg.AimbotKeyMode      = "Toggle"
        cfg.AimbotShowFOV      = true
    end

    -- picker propio (centro = centro de pantalla)
    task.spawn(function()
        for _ = 1, 300 do
            if type(getgenv().GetAimbotTargetRivals) == "function" then break end
            task.wait(0.1)
        end
        if SHC.mobile and SHC.overrideTargetPicker
           and type(getgenv().GetAimbotTargetRivals) == "function" then
            getgenv().GetAimbotTargetRivals = function() return SHC.pickTarget() end
        end
    end)

    -- fallback de equip de slot (móvil no siempre manda teclas)
    task.spawn(function()
        for _ = 1, 300 do
            if type(getgenv().ragePressSlot) == "function" then break end
            task.wait(0.1)
        end
        local old = getgenv().ragePressSlot
        if type(old) == "function" and not SHC._slotWrapped then
            SHC._slotWrapped = true
            getgenv().ragePressSlot = function(slot)
                pcall(old, slot)
                pcall(function()
                    local fc = require(LP.PlayerScripts.Controllers.FighterController)
                    local lf = fc and fc.LocalFighter
                    if lf and lf.EquipItem then lf:EquipItem(tonumber(slot) or 1) end
                end)
            end
        end
    end)

    shcNotify(SHC.mobile and "capa móvil lista · MENU / AIM / STOP" or "capa compat lista")
end)

--============= 7) CARGA DEL SCRIPT RIO (modo 2 archivos) =============
if CFG.LoadRioFromUrl then
    local ok, err = pcall(function()
        return loadstring(game:HttpGet(CFG.RioUrl))()
    end)
    if not ok then shcNotify("rio.lua: " .. tostring(err)) end
end

-- FIN DE LA CAPA
-- ====== A PARTIR DE ACÁ VA TU SCRIPT (si LoadRioFromUrl = false) ======
