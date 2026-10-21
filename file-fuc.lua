--[[=====================================================================
  SHAKO · RIO + CAPA COMPAT v1.2  ·  Delta / Android / executor-agnostic
  ---------------------------------------------------------------------
  BUILD LEGIT:  SOLO AIMBOT + ESP (jugadores) + ESP WORLD + SETTINGS
======================================================================]]

--=========================== AJUSTES ===========================
local CFG = {
    Buttons              = true,   -- botones MENU / AIM / STOP
    MobileDefaults       = true,
    OverrideTargetPicker = true,
    FpsCap               = 60,
    LoadRioFromUrl       = false,
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

if not mouse1press then
    mouse1press = function() pcall(function() VIM:SendMouseButtonEvent(0,0,0,true,game,0) end) end
end
if not mouse1release then
    mouse1release = function() pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end) end
end
if not mouse1click then
    mouse1click = function() mouse1press() task.wait(0.012) mouse1release() end
end

if SHC.touch and type(mousemoverel) == "function" then
    SHC._oldMouseRel = mousemoverel
    mousemoverel = function() end
end

if SHC.mobile and CFG.FpsCap and type(setfpscap) == "function" then
    pcall(setfpscap, CFG.FpsCap)
end

SHC.hasHook   = type(hookfunction) == "function"
SHC.hasHookMM = type(hookmetamethod) == "function"
if not SHC.hasHook then shcNotify("sin hookfunction: Silent OFF") end

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

--============= 2) DRAWING SHIM =============
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

    tap(btnMenu, function()
        local name = (getgenv().config and getgenv().config.MenuKey) or getgenv()._ShakoMenuKey or "RightShift"
        local ok, kc = pcall(function() return Enum.KeyCode[name] end)
        if not ok or not kc then kc = Enum.KeyCode.RightShift end
        VIM:SendKeyEvent(true, kc, false, game)
        task.wait(0.06)
        VIM:SendKeyEvent(false, kc, false, game)
    end)

    tap(btnAim, function()
        SHC.aimOn = not SHC.aimOn
        btnAim.BackgroundColor3 = SHC.aimOn and Color3.fromRGB(60, 210, 100) or Color3.fromRGB(35, 120, 65)
        local st = getgenv()._ShakoAimKB
        if type(st) ~= "table" then st = { held = false, toggled = false } getgenv()._ShakoAimKB = st end
        st.toggled = SHC.aimOn
    end)

    tap(btnStop, function() if SHC.stopAll then SHC.stopAll() end end)

    SHC.gui = gui
end

--================= 4) AIM MÓVIL POR CÁMARA =================
SHC.aimOn = false

local FOVC = {
    White = Color3.fromRGB(255,255,255), Red = Color3.fromRGB(255,70,80),
    Green = Color3.fromRGB(80,255,140), Cyan = Color3.fromRGB(80,220,255),
    Magenta = Color3.fromRGB(255,100,220), Yellow = Color3.fromRGB(255,230,80),
    Orange = Color3.fromRGB(255,160,50), Purple = Color3.fromRGB(168,85,255),
}
local function fovCol(v)
    if typeof(v) == "Color3" then return v end
    return FOVC[v or "White"] or Color3.fromRGB(255,230,80)
end

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
        if cfg.AimbotFOVColor then fs.Color = fovCol(cfg.AimbotFOVColor) end
        fovFrame.BackgroundColor3 = fovCol(cfg.AimbotFOVColor)
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
        "UECounterEnabled","AntiUnnamed","AimbotEnabled","SpeedEnabled","JumpPowerEnabled","SlideBoostEnabled",
    }) do
        if type(cfg[k]) == "boolean" then cfg[k] = false end
    end
    getgenv()._ShakoSilentActive = false
    local st = getgenv()._ShakoAimKB
    if type(st) == "table" then st.toggled = false st.held = false end
    SHC.aimOn = false
    for _, f in ipairs({
        "StopVoidSpam","StopSleepyCounter","StopKiciaCounter","StopPredDodge",
        "StopStickBehindTP","StopFakePosition","StopUECounter",
        "StopTriggerbot","StopBlink","StopDefense","StopBodyTwist","StopSilentAim","StopRagebot",
        "StopAntiAim","StopFly","StopNoclip","StopAimbot",
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
        cfg.WallXray           = false
        cfg.AimbotSmooth       = math.clamp(tonumber(cfg.AimbotSmooth) or 0.9, 0.35, 1)
        cfg.AimbotFOV          = math.min(tonumber(cfg.AimbotFOV) or 400, 300)
        cfg.AimbotKeyMode      = "Toggle"
        cfg.AimbotShowFOV      = true
    end

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
-- shako.win | LEGIT BUILD

pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
end)

if getgenv().antiSleepy_loaded then
    if getgenv()._ShakoUIReady == true then
        return
    end
    getgenv().antiSleepy_loaded = false
end
getgenv().antiSleepy_loaded = true
getgenv().config = getgenv().config

-- ==================== AXIS/HARION ANTI-CHEAT BYPASS ====================
pcall(function()
(function()
    local players = game:GetService("Players")
    local coreGui = game:GetService("CoreGui")
    if not game:IsLoaded() then game.Loaded:Wait() end
    local player = players.LocalPlayer
    while not player do
        players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        player = players.LocalPlayer
    end
    local playerGui = player:WaitForChild("PlayerGui")
    local function isActiveLoadingGui(object)
        local n = object.Name:lower():gsub("[%s_%-]", "")
        if n ~= "loadingscreen" and not n:find("loadingscreen", 1, true) then return false end
        local cur = object
        while cur and cur ~= playerGui and cur ~= coreGui do
            if cur:IsA("LayerCollector") and not cur.Enabled then return false end
            if cur:IsA("GuiObject") and not cur.Visible then return false end
            cur = cur.Parent
        end
        return object:IsDescendantOf(playerGui) or object:IsDescendantOf(coreGui)
    end
    local clearSince
    local t0 = os.clock()
    repeat
        local loading = false
        for _, root in ipairs({ playerGui, coreGui }) do
            local ok, list = pcall(function() return root:GetDescendants() end)
            if ok then
                for _, object in ipairs(list) do
                    if isActiveLoadingGui(object) then loading = true break end
                end
            end
            if loading then break end
        end
        clearSince = loading and nil or (clearSince or os.clock())
        task.wait(0.1)
    until (clearSince and os.clock() - clearSince >= 0.5) or os.clock() - t0 > 60

    local genvL = getgenv()
    if genvL.__ShakoStartupHooks then return end
    genvL.__ShakoStartupHooks = true
    local function ncc(fn) return (type(newcclosure) == "function" and newcclosure(fn)) or fn end
    local cref = (type(cloneref) == "function" and cloneref) or function(o) return o end
    if type(setthreadidentity) == "function" then pcall(setthreadidentity, 8) end

    local okEnv, renv = pcall(function() return getrenv() end)
    local smt = okEnv and type(renv) == "table" and renv.setmetatable or nil
    if type(hookfunction) == "function" and smt then
        local oldSmt = smt
        local okHook, hooked = pcall(hookfunction, smt, ncc(function(Table, Metatable)
            if Metatable and type(Metatable) == "table" and rawget(Metatable, "__mode") then
                local mode = rawget(Metatable, "__mode")
                if mode == "kv" or mode == "v" or mode == "k" then
                    local okT, trace = pcall(debug.traceback)
                    trace = okT and trace or ""
                    if trace:find("MiscellaneousController", 1, true)
                        or trace:find("CameraSecurity", 1, true)
                        or trace:find("AnalyticsPipelineController", 1, true) then
                        return oldSmt({ 1, 2, 3 }, {})
                    end
                end
            end
            return oldSmt(Table, Metatable)
        end))
        if okHook and hooked then oldSmt = hooked end
    end

    local lpl = cref(players).LocalPlayer
    if lpl and type(hookfunction) == "function" then
        pcall(function()
            local oldKick
            oldKick = hookfunction(lpl.Kick, ncc(function(self, ...)
                if self == lpl then return nil end
                return oldKick(self, ...)
            end))
        end)
        pcall(function()
            local oldGetMouse
            oldGetMouse = hookfunction(lpl.GetMouse, ncc(function(self, ...)
                if self == lpl then
                    local okT, trace = pcall(debug.traceback)
                    if okT and trace:find("MiscellaneousController", 1, true) then
                        local realMouse = oldGetMouse(self, ...)
                        return setmetatable({}, {
                            __index = function(_, key)
                                if key == "X" or key == "Y" then
                                    local loc = game:GetService("UserInputService"):GetMouseLocation()
                                    return key == "X" and loc.X or loc.Y
                                end
                                local val = realMouse[key]
                                if type(val) == "function" then return function(_, ...) return val(realMouse, ...) end end
                                return val
                            end,
                            __newindex = function(_, key, value) realMouse[key] = value end,
                        })
                    end
                end
                return oldGetMouse(self, ...)
            end))
        end)
    end

    pcall(function()
        local cs = require(lpl:WaitForChild("PlayerScripts"):WaitForChild("Modules"):WaitForChild("CameraSecurity", 10))
        local mt = getrawmetatable(cs)
        if mt then
            if type(setreadonly) == "function" then pcall(setreadonly, mt, false) end
            mt.__index = function() return nil end
            mt.__tostring = function() return "LocalPlayer = nil" end
            mt.__newindex = function(E, G, f) return rawset(E, G, f) end
        end
    end)

    pcall(function()
        for _, service in pairs({ cref(players), workspace, cref(game:GetService("ReplicatedStorage")), cref(game:GetService("ReplicatedFirst")) }) do
            service.Name = service.Name .. " "
        end
    end)

    task.spawn(function()
        local ok, ServerPing = pcall(function() return workspace:WaitForChild("ServerPing", 30) end)
        local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        local PingRemote = Remotes and Remotes:FindFirstChild("Ping")
        if not PingRemote then return end
        while task.wait(12 * math.random()) do
            local rnd = math.random(1, 9999)
            local sp = (ok and ServerPing and ServerPing.Value) or -1
            local value = rnd == 6961 and 2137 or rnd == sp and 2138 or rnd
            pcall(function() PingRemote:FireServer(value) end)
        end
    end)
    print("[shako] anti-cheat bypass activo")
end)()
end)
task.wait(2)

pcall(function()
    if getgenv()._ShakoAvatarKeepThread then
        task.cancel(getgenv()._ShakoAvatarKeepThread)
        getgenv()._ShakoAvatarKeepThread = nil
    end
end)

getgenv()._ShakoUIReady = false
getgenv()._ShakoBootAt = tick()

-- ==================== SOLO RIVALS ====================
local RIVALS_GAME_ID = 6035872082
local function notSupportedKick()
    local msg = "this game not supported"
    warn("[shako.win] " .. msg .. " | GameId=" .. tostring(game.GameId))
    pcall(function()
        local lp = game:GetService("Players").LocalPlayer
        if lp then lp:Kick(msg) end
    end)
    pcall(function()
        game:GetService("TeleportService"):Teleport(0)
    end)
    getgenv().antiSleepy_loaded = false
end

local _gid = tonumber(game.GameId)
local _okGame = (_gid == RIVALS_GAME_ID)
if not _okGame then
    warn("[shako.win] GameId=" .. tostring(_gid) .. " (esperado " .. tostring(RIVALS_GAME_ID) .. ")")
end

local function shakoFail(msg)
    warn("[shako]", msg)
    getgenv().antiSleepy_loaded = false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    for _ = 1, 100 do
        LocalPlayer = Players.LocalPlayer
        if LocalPlayer then break end
        task.wait(0.05)
    end
end
if not LocalPlayer then
    shakoFail("LocalPlayer nil — reintenta en 1s")
    return
end

pcall(function() LocalPlayer:WaitForChild("PlayerGui", 12) end)

local Camera = workspace.CurrentCamera

-- ==================== Obsidian UI ====================
local repo = "https://raw.githubusercontent.com/xyznick/UELinoriaLib/main/"
local Library, ThemeManager, SaveManager

local function httpGet(url)
    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and body and #body > 100 then return body end
    return nil
end

local function try_load(url)
    local body = httpGet(url)
    if not body then return nil end
    local ok, res = pcall(function() return loadstring(body)() end)
    if ok and res then return res end
    return nil
end

local UELINORIA_REPO = "https://raw.githubusercontent.com/xyznick/UELinoriaLib/main/"
local LINORIA_REPO = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local OBSIDIAN_REPO = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

Library = try_load(UELINORIA_REPO .. "Library.lua")
ThemeManager = try_load(UELINORIA_REPO .. "addons/ThemeManager.lua")
SaveManager = try_load(UELINORIA_REPO .. "addons/SaveManager.lua")
local _usingLinoria = Library ~= nil
local _usingUE = Library ~= nil

if not Library then
    task.wait(0.25)
    Library = try_load(LINORIA_REPO .. "Library.lua")
    ThemeManager = try_load(LINORIA_REPO .. "addons/ThemeManager.lua")
    SaveManager = try_load(LINORIA_REPO .. "addons/SaveManager.lua")
    _usingLinoria = Library ~= nil
    _usingUE = false
end
if not Library then
    task.wait(0.25)
    Library = try_load(OBSIDIAN_REPO .. "Library.lua")
    ThemeManager = try_load(OBSIDIAN_REPO .. "addons/ThemeManager.lua")
    SaveManager = try_load(OBSIDIAN_REPO .. "addons/SaveManager.lua")
    _usingLinoria = false
    _usingUE = false
end

if not Library or type(Library.CreateWindow) ~= "function" then
    shakoFail("UI Library no cargó (UELinoria/Linoria/Obsidian)")
    return
end

do
    local function wrapGroupbox(gb)
        if not gb or gb.__shakoPatched then return gb end
        gb.__shakoPatched = true
        local function hook(method, valueKey)
            local old = gb[method]
            if type(old) ~= "function" then return end
            gb[method] = function(self, idx, opts)
                opts = opts or {}
                local cb = opts.Callback
                local ret = old(self, idx, opts)
                if cb and _usingLinoria then
                    task.defer(function()
                        local Toggles = Library.Toggles or getgenv().Toggles
                        local Options = Library.Options or getgenv().Options
                        if method == "AddToggle" and Toggles and Toggles[idx] then
                            pcall(function()
                                Toggles[idx]:OnChanged(function()
                                    pcall(cb, Toggles[idx].Value)
                                end)
                            end)
                        elseif Options and Options[idx] then
                            pcall(function()
                                Options[idx]:OnChanged(function()
                                    local v = Options[idx].Value
                                    pcall(cb, v)
                                end)
                            end)
                        end
                    end)
                end
                return ret
            end
        end
        hook("AddToggle")
        hook("AddSlider")
        hook("AddDropdown")
        local oldBtn = gb.AddButton
        if type(oldBtn) == "function" then
            gb.AddButton = function(self, opts)
                if type(opts) == "table" and opts.Func and not opts.Callback then
                    if _usingLinoria then
                        return oldBtn(self, opts.Text or "Button", opts.Func)
                    end
                end
                return oldBtn(self, opts)
            end
        end
        return gb
    end

    local function wrapTab(tab)
        if not tab or tab.__shakoPatched then return tab end
        tab.__shakoPatched = true
        for _, m in ipairs({ "AddLeftGroupbox", "AddRightGroupbox", "AddGroupbox" }) do
            local old = tab[m]
            if type(old) == "function" then
                tab[m] = function(self, ...)
                    local gb = old(self, ...)
                    return wrapGroupbox(gb)
                end
            end
        end
        return tab
    end

    local oldCreate = Library.CreateWindow
    Library.CreateWindow = function(self, opts)
        opts = opts or {}
        local ok, win = pcall(oldCreate, self, {
            Title = opts.Title or "shako.win",
            Center = opts.Center ~= false,
            AutoShow = opts.AutoShow ~= false,
            TabPadding = 8,
        })
        if not ok or not win then
            return oldCreate(self, opts)
        end
        local oldAddTab = win.AddTab
        if type(oldAddTab) == "function" then
            win.AddTab = function(self, name, ...)
                local tab = oldAddTab(self, name, ...)
                return wrapTab(tab)
            end
        end
        return win
    end

    local oldNotify = Library.Notify
    if type(oldNotify) == "function" then
        Library.Notify = function(self, a, b, c)
            if type(a) == "table" then
                local title = a.Title or a.title or "shako"
                local desc = a.Description or a.description or a.Text or ""
                local t = a.Time or a.time or 3
                local msg = (desc ~= "" and (tostring(title) .. " · " .. tostring(desc))) or tostring(title)
                return oldNotify(self, msg, t)
            end
            return oldNotify(self, a, b, c)
        end
    end
end
getgenv()._ShakoUsingLinoria = _usingLinoria

task.defer(function()
    task.wait(0.3)
    pcall(function()
        local k = (getgenv().config and getgenv().config.MenuKey) or "RightShift"
        Library.ToggleKeybind = tostring(k)
        getgenv()._ShakoMenuKey = tostring(k)
    end)
end)

pcall(function() Library.ShowCustomCursor = true end)

local LucideIcons = {}
pcall(function()
    LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))() or {}
end)
local function Icon(n)
    local f = LucideIcons[string.lower(tostring(n or ""))]
    if type(f) == "string" then
        local id = f:match("rbxassetid://(%d+)") or f:match("(%d+)")
        if id then return id end
    end
    return nil
end

if ThemeManager and ThemeManager.SetLibrary then
    pcall(function()
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetFolder("shako_win")
    end)
end
if SaveManager and SaveManager.SetLibrary then
    pcall(function()
        SaveManager:SetLibrary(Library)
        SaveManager:SetFolder("shako_win/configs")
        if ThemeManager and SaveManager.IgnoreThemeSettings then
            pcall(function() SaveManager:IgnoreThemeSettings() end)
        end
        pcall(function() SaveManager:SetIgnoreIndexes({"MenuKeybind"}) end)
    end)
end

local Window
do
    local ok, win = pcall(function()
        pcall(function()
            Library.Font = Enum.Font.Gotham
            if Library.SetFontSize then
                Library:SetFontSize(13)
            else
                Library.FontSize = 13
            end
        end)
        return Library:CreateWindow({
            Title = "RioRage.win",
            Footer = "LEGIT",
            Center = true,
            AutoShow = true,
            Resizable = true,
            NotifySide = "Right",
            ShowCustomCursor = true,
        })
    end)
    if not ok or not win then
        shakoFail("CreateWindow falló — vuelve a ejecutar")
        return
    end
    Window = win

    pcall(function()
        Library.ShowCustomCursor = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

pcall(function()
    if Library.SetWatermark then
        Library:SetWatermark("shako.win · LEGIT")
    end
    if Library.Watermark then
        pcall(function() Library.Watermark.Text = "shako.win · LEGIT" end)
    end
end)

pcall(function()
    if Library and Library.Notify then
        getgenv()._ShakoLibraryNotify = Library.Notify
        Library.Notify = function(self, data)
            return
        end
    end
end)

function Notify(title, text)
    if tostring(title) ~= "Config" then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Config",
            Text = tostring(text or ""),
            Duration = 3,
        })
    end)
    pcall(function()
        local fn = getgenv()._ShakoLibraryNotify
        if type(fn) == "function" then
            fn(Library, { Title = "Config", Description = tostring(text or ""), Time = 3 })
        end
    end)
end
getgenv()._ShakoBootAt = tick()

-- ==================== CONFIG (settings intactas) ====================
getgenv().config = {
    Enabled = false,

    AimbotEnabled = false,
    AimbotKeyMode = "Hold",
    AimbotFOV = 400,
    AimbotSmooth = 0.9,
    AimbotPart = "Head",
    AimbotTeamCheck = true,
    AimbotKeyHold = false,
    MenuKey = "RightShift",
    AimbotWallCheck = false,
    AimbotVisibleCheck = false,
    AimbotShowFOV = true,
    AimbotFOVFill = true,
    AimbotFOVFillTransparency = 0.92,
    AimbotFOVAnimated = false,
    AimbotFOVColor = "White",
    AimbotFOVOutlineColor3 = Color3.fromRGB(255, 230, 80),
    AimbotFOVFillC1 = Color3.fromRGB(255, 210, 80),
    AimbotFOVFillC2 = Color3.fromRGB(255, 140, 60),
    AimbotFOVFillC3 = Color3.fromRGB(255, 80, 120),
    AimbotSmooth = 0.15,

    SilentAimEnabled = false,
    SilentHitPart = "Head",
    SilentPredict = false,
    SilentPredictAmount = 0.08,
    SilentHeadOffsetY = 0,
    SilentFOV = 800,
    SilentShowFOV = true,
    SilentTeamCheck = true,
    SilentForceAiming = true,
    SilentActivationChance = 100,
    SilentReactionTime = 0,
    SilentSwitchDelay = 0,
    SilentManipulate = true,
    SilentManipulateMode = "OnBestTarget",
    SilentWallCheck = false,
    SilentVisibleCheck = false,
    SilentUseHitboxHead = true,
    SilentFOVFill = true,
    SilentFOVFillTransparency = 0.92,
    SilentFOVAnimated = true,
    SilentFOVSpin = true,
    SilentFOVSpinSpeed = 1.2,
    SilentFOVThickness = 1.5,
    SilentFOVColor = "White",
    SilentFOVOutlineColor3 = Color3.fromRGB(255, 255, 255),
    SilentFOVFillC1 = Color3.fromRGB(255, 105, 180),
    SilentFOVFillC2 = Color3.fromRGB(180, 100, 255),
    SilentFOVFillC3 = Color3.fromRGB(80, 180, 255),

    TeamCheck = true,
    MaxRange = 1e9,
    SpawnDelay = 0.5,

    ExtendMeleeRange = false,
    ExtendMeleeRangeDist = 10,

    -- ESP (jugadores)
    ESPEnabled = false,
    ESPPerfMode = true,
    ESPMaxPlayers = 6,
    ESPUpdateInterval = 0.05,
    ESPTeamCheck = false,
    ESPTeamColor = Color3.fromRGB(80, 180, 255),
    ESPEnemyColor = Color3.fromRGB(255, 255, 255),
    ESPFilledBox = false,
    ESPHeldWeapon = false,
    ESPHealthNumber = false,
    ESPTracer = false,
    ESPTracerColor = Color3.fromRGB(255, 255, 255),
    ESPHeadMarker = false,
    ESPUseDisplayName = false,
    ESP = false,
    ESPBox = true,
    ESPBoxStyle = "Full Box",
    ESPBoxThickness = 1,
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPHealthBar = true,
    ESPSkeleton = false,
    ESPTracers = false,
    ESPMaxDistance = 100000,
    ESPDistanceScaling = true,
    ESPDistanceScalingRef = 50,
    ESPMaxDist = 1e9,
    ESPInfiniteRange = true,
    ESPShowName = true,
    ESPShowDist = true,
    ESPShowHP = true,
    ESPShowBox = true,
    ESPColor = "Red",
    ESPHealthBarColor = "Green",
    ESPUseTeamColor = false,

    -- ESP WORLD
    Fullbright = false,
    Brightness = 2,
    Exposure = 0,
    ClockTime = 14,
    NoFog = true,
    Saturation = 0,
    Contrast = 0,
    BloomEnabled = false,
    BloomIntensity = 0.4,
    BlurEnabled = false,
    BlurSize = 8,
    AmbientColor = false,
    LightingOverride = false,
    AmbientR = 120, AmbientG = 120, AmbientB = 140,
    OutdoorR = 140, OutdoorG = 140, OutdoorB = 160,
    ColorShiftEnabled = false,
    ColorShiftR = 0, ColorShiftG = 0, ColorShiftB = 0,
    TintEnabled = false,
    TintR = 255, TintG = 255, TintB = 255,
    ShadowsEnabled = true,
    GlobalShadows = true,
    EnvironmentDiffuse = 1,
    EnvironmentSpecular = 1,
    WallXray = false,
    WallTransparency = 0.55,
    WallLocalOnly = true,
    MapColorEnabled = false,
    MapColorR = 80, MapColorG = 80, MapColorB = 100,
    RemoveTextures = false,
    XRayEnabled = false,
    XRayTransparency = 0.5,
}
local config = getgenv().config

-- ==================== RIVALS MODULES ====================
local RS = game:GetService("ReplicatedStorage")
local util, enum, FighterController, SpectateController
local modulesOK = false

function loadRivalsModules()
    local ok1, u = pcall(function() return require(RS.Modules.Utility) end)
    local ok2, e = pcall(function() return require(RS.Modules.EnumLibrary) end)
    local ok3, fc = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers.FighterController)
    end)
    local ok4, sc = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers:WaitForChild("SpectateController"))
    end)
    if ok1 and ok2 and ok3 then
        util, enum, FighterController = u, e, fc
        if ok4 then SpectateController = sc end
        modulesOK = true
        return true
    end
    modulesOK = false
    return false
end

task.spawn(function()
    for _ = 1, 40 do
        if loadRivalsModules() then
            pcall(function() Notify("Rivals", "FighterController OK") end)
            break
        end
        task.wait(0.4)
    end
end)

-- ==================== CONNECTIONS + HELPERS ====================
local Connections = {
    Main = nil, StickRender = nil, Fly = nil, AntiUnnamed = nil,
    Noclip = nil, AntiAim = nil, Ragebot = nil, AutoClick = nil,
    NoRecoil = nil, AUWatch = nil, ESP = nil, VisualLoop = nil,
    Aimbot = nil, AimbotInput = nil, AimbotInputEnd = nil, RapidFireChar = nil, VoidSpam = nil,
    PredDodge = nil, Triggerbot = nil, SilentFOV = nil, FOVDraw = nil, Weather = nil, Defense = nil,
    SleepyCounter = nil, KiciaCounter = nil, StickBehind = nil, RageInd = nil, FakePosition = nil,
    ForceField = nil, ForceFieldLoop = nil, Riot = nil, RiotAbuse = nil, Blink = nil,
    MatchAutos = nil, AutoCollect = nil, AntiAimChar = nil, Manipulation = nil,
}

function SafeDisconnect(name)
    local c = Connections[name]
    if not c then return end
    if type(c) == "thread" then
        pcall(task.cancel, c)
    elseif type(c) == "table" then
        pcall(function() if c.Disconnect then c:Disconnect() end end)
    else
        pcall(function() if c.Disconnect then c:Disconnect() end end)
    end
    Connections[name] = nil
end

function getHRP()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end
function getHum()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
function getPlayerTeamId(plr)
    if not plr then return nil end
    local tid = nil
    pcall(function() tid = plr:GetAttribute("TeamID") end)
    if tid == nil then
        pcall(function() tid = plr:GetAttribute("Team") end)
    end
    if tid == nil and plr.Character then
        pcall(function() tid = plr.Character:GetAttribute("TeamID") end)
        if tid == nil then
            pcall(function() tid = plr.Character:GetAttribute("Team") end)
        end
    end
    if tid == nil and FighterController and FighterController.Objects then
        pcall(function()
            for _, obj in pairs(FighterController.Objects) do
                if obj.Player == plr then
                    tid = obj:Get("TeamID") or (obj.Get and obj:Get("Team"))
                    break
                end
            end
        end)
    end
    if tid == nil and SpectateController then
        pcall(function()
            local duel = SpectateController.CurrentDuelSubject
            if not duel or not duel.GetDueler then return end
            local dueler = duel:GetDueler(plr)
            if dueler then tid = dueler:Get("TeamID") end
        end)
    end
    if tid == nil and plr.Team then tid = plr.Team.Name end
    if tid == nil and plr.TeamColor then tid = tostring(plr.TeamColor) end
    if tid == nil then return nil end
    return tostring(tid)
end

function IsRivalsBot(plr)
    if not plr then return true end
    local ok, a = pcall(function()
        return plr:GetAttribute("IsBot") or plr:GetAttribute("Bot") or plr:GetAttribute("IsNPC") or plr:GetAttribute("NPC")
    end)
    if ok and a then return true end
    local name = string.lower(tostring(plr.Name or ""))
    local disp = string.lower(tostring(plr.DisplayName or ""))
    if name:find("bot", 1, true) or disp:find("bot", 1, true) then return true end
    if name:find("npc", 1, true) or disp:find("npc", 1, true) then return true end
    if typeof(plr.UserId) == "number" and plr.UserId <= 0 then return true end
    return false
end

local _ShakoTeamCache, _ShakoTeamCacheT = {}, {}
pcall(function()
    Players.PlayerRemoving:Connect(function(plr)
        _ShakoTeamCache[plr.UserId] = nil
        _ShakoTeamCacheT[plr.UserId] = nil
    end)
end)
function _StrongIsTeammateRaw(plr)
    if not plr or plr == LocalPlayer then return true end
    local okT, sameT = pcall(function()
        local a, b = LocalPlayer.Team, plr.Team
        if a ~= nil and b ~= nil then
            return a == b or (a.Name and b.Name and a.Name == b.Name)
        end
        return nil
    end)
    if okT and sameT == true then return true end
    if okT and sameT == false then return false end
    local okC, sameC = pcall(function()
        local ac, bc = LocalPlayer.TeamColor, plr.TeamColor
        if ac and bc then
            if ac == bc then return true end
            return false
        end
        return nil
    end)
    if okC and sameC == true then
        local ac, bc = LocalPlayer.TeamColor, plr.TeamColor
        local an, bn = tostring(ac), tostring(bc)
        if an ~= "White" and bn ~= "White" and an ~= "Medium stone grey" then return true end
    end
    local function readTid(p)
        if not p then return nil end
        local tid = nil
        pcall(function() tid = p:GetAttribute("TeamID") end)
        if tid == nil then pcall(function() tid = p:GetAttribute("Team") end) end
        if tid == nil then pcall(function() tid = p:GetAttribute("TeamId") end) end
        if tid == nil and p.Character then
            local c = p.Character
            pcall(function() tid = c:GetAttribute("TeamID") end)
            if tid == nil then pcall(function() tid = c:GetAttribute("Team") end) end
        end
        return tid
    end
    local function norm(t)
        if t == nil then return nil end
        local x = tostring(t)
        if x == "" or x == "nil" or x == "0" or x == "FFA" or x == "None" or x == "null" then return nil end
        return x
    end
    local lt, pt = norm(readTid(LocalPlayer)), norm(readTid(plr))
    if lt and pt then return lt == pt end
    if type(getPlayerTeamId) == "function" then
        local a = norm(getPlayerTeamId(LocalPlayer))
        local b = norm(getPlayerTeamId(plr))
        if a and b then return a == b end
    end
    local isMate = false
    pcall(function()
        if plr.Character and plr.Character:FindFirstChild("TeammateLabel") then isMate = true end
    end)
    if isMate then return true end
    return false
end
function StrongIsTeammate(plr)
    if not plr or plr == LocalPlayer then return true end
    local uid = plr.UserId
    local now = os.clock()
    local t = _ShakoTeamCacheT[uid]
    if t and (now - t) < 0.45 and _ShakoTeamCache[uid] ~= nil then
        return _ShakoTeamCache[uid]
    end
    local r = _StrongIsTeammateRaw(plr)
    _ShakoTeamCache[uid] = r
    _ShakoTeamCacheT[uid] = now
    return r
end
function IsSameTeam(plr) return StrongIsTeammate(plr) end

function IsEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if not plr.Character then return false end
    if config.TeamCheck == false and config.AimbotTeamCheck ~= true then return true end
    if StrongIsTeammate and StrongIsTeammate(plr) then return false end
    return true
end

function CanDoDangerousMove()
    if CanMove then return true end
    local delay = tonumber(config.SpawnDelay) or 0
    if delay <= 0 then return true end
    return (tick() - (SpawnTime or 0)) >= delay
end
function IsAntiUnnamedActive() return false end
function LookAtPos(pos) end
function ResetCameraNormal() end
function EnsureCameraFree() end

-- ==================== WORLD VISUALS ====================
local CC = Lighting:FindFirstChild("SleepyCC") or Instance.new("ColorCorrectionEffect")
CC.Name = "SleepyCC"
CC.Parent = Lighting
local BloomFX = Lighting:FindFirstChild("SleepyBloom") or Instance.new("BloomEffect")
BloomFX.Name = "SleepyBloom"
BloomFX.Enabled = false
BloomFX.Parent = Lighting
local BlurFX = Lighting:FindFirstChild("SleepyBlur") or Instance.new("BlurEffect")
BlurFX.Name = "SleepyBlur"
BlurFX.Enabled = false
BlurFX.Parent = Lighting

local oldLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd
}

local _wallCache = _wallCache or {}
local _mapColorCache = _mapColorCache or {}
local _xrayCache = _xrayCache or {}

local function _mapRoots()
    local roots = {}
    for _, name in ipairs({"Map", "World", "Level", "Arena", "Stages", "Maps", "Geometry", "MapModel"}) do
        local f = workspace:FindFirstChild(name)
        if f then roots[#roots+1] = f end
    end
    if #roots == 0 then
        for _, c in ipairs(workspace:GetChildren()) do
            if (c:IsA("Model") or c:IsA("Folder")) and c.Name ~= "Players" then
                roots[#roots+1] = c
            end
        end
    end
    return roots
end
local function _xraySkip(obj)
    if not obj or not obj:IsA("BasePart") then return true end
    local lp = LocalPlayer
    if lp.Character and obj:IsDescendantOf(lp.Character) then return true end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and obj:IsDescendantOf(plr.Character) then return true end
    end
    local cam = workspace.CurrentCamera
    if cam and obj:IsDescendantOf(cam) then return true end
    return false
end
local function applyWallXray(on)
    local trans = tonumber(config.WallTransparency) or 0.55
    if on then
        local count = 0
        for _, root in ipairs(_mapRoots()) do
            for _, obj in ipairs(root:GetDescendants()) do
                if count > 4000 then break end
                if obj:IsA("BasePart") and not _xraySkip(obj) and obj.Transparency < 0.98 then
                    if not _wallCache[obj] then _wallCache[obj] = obj.LocalTransparencyModifier or 0 end
                    pcall(function() obj.LocalTransparencyModifier = math.clamp(trans, 0, 0.98) end)
                    count += 1
                end
            end
        end
        if count < 20 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if count > 4000 then break end
                if obj:IsA("BasePart") and obj.Anchored and not _xraySkip(obj) and obj.Transparency < 0.98 then
                    if not _wallCache[obj] then _wallCache[obj] = obj.LocalTransparencyModifier or 0 end
                    pcall(function() obj.LocalTransparencyModifier = math.clamp(trans, 0, 0.98) end)
                    count += 1
                end
            end
        end
    else
        for obj, orig in pairs(_wallCache) do
            if obj and obj.Parent then
                pcall(function() obj.LocalTransparencyModifier = orig or 0 end)
            end
        end
        table.clear(_wallCache)
    end
end
local function applyXRay(on)
    local trans = tonumber(config.XRayTransparency) or 0.5
    if on then
        local count = 0
        local function touch(obj)
            if count > 5000 then return end
            if not obj:IsA("BasePart") or _xraySkip(obj) then return end
            if obj.Transparency >= 0.98 then return end
            if not _xrayCache[obj] then _xrayCache[obj] = obj.LocalTransparencyModifier or 0 end
            pcall(function() obj.LocalTransparencyModifier = math.clamp(trans, 0, 0.98) end)
            count += 1
        end
        for _, root in ipairs(_mapRoots()) do
            for _, obj in ipairs(root:GetDescendants()) do touch(obj) end
        end
        if count < 30 then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Anchored then touch(obj) end
            end
        end
    else
        for obj, orig in pairs(_xrayCache) do
            if obj and obj.Parent then
                pcall(function() obj.LocalTransparencyModifier = orig or 0 end)
            end
        end
        table.clear(_xrayCache)
    end
end
local function applyMapColor(on)
    if not on then
        for obj, col in pairs(_mapColorCache) do
            if obj and obj.Parent then pcall(function() obj.Color = col end) end
        end
        table.clear(_mapColorCache)
        return
    end
    local c = Color3.fromRGB(
        tonumber(config.MapColorR) or 80,
        tonumber(config.MapColorG) or 80,
        tonumber(config.MapColorB) or 100
    )
    local count = 0
    for _, root in ipairs(_mapRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            if count > 2000 then break end
            if obj:IsA("BasePart") then
                if not _mapColorCache[obj] then _mapColorCache[obj] = obj.Color end
                pcall(function() obj.Color = c end)
                count += 1
            end
        end
    end
end
local function applyRemoveTextures(on)
    if not on then return end
    local count = 0
    for _, root in ipairs(_mapRoots()) do
        for _, obj in ipairs(root:GetDescendants()) do
            if count > 1500 then return end
            if obj:IsA("Texture") or obj:IsA("Decal") then
                pcall(function() obj.Transparency = 1 end)
                count += 1
            end
        end
    end
end

function ApplyVisuals()
    pcall(function()
        if config.Fullbright then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.ClockTime = 12
            Lighting.ExposureCompensation = 0.6
            Lighting.GlobalShadows = false
        elseif config.LightingOverride then
            Lighting.Brightness = tonumber(config.Brightness) or 2
            Lighting.ExposureCompensation = tonumber(config.Exposure) or 0
            Lighting.ClockTime = tonumber(config.ClockTime) or 14
            Lighting.Ambient = Color3.fromRGB(
                tonumber(config.AmbientR) or 120,
                tonumber(config.AmbientG) or 120,
                tonumber(config.AmbientB) or 140
            )
            Lighting.OutdoorAmbient = Color3.fromRGB(
                tonumber(config.OutdoorR) or 140,
                tonumber(config.OutdoorG) or 140,
                tonumber(config.OutdoorB) or 160
            )
            if config.GlobalShadows ~= nil then
                Lighting.GlobalShadows = config.GlobalShadows and true or false
            end
            pcall(function()
                Lighting.EnvironmentDiffuseScale = tonumber(config.EnvironmentDiffuse) or 1
                Lighting.EnvironmentSpecularScale = tonumber(config.EnvironmentSpecular) or 1
            end)
        else
            if not config.Fullbright then
                Lighting.Brightness = tonumber(config.Brightness) or oldLighting.Brightness
                Lighting.ExposureCompensation = tonumber(config.Exposure) or oldLighting.ExposureCompensation
                Lighting.ClockTime = tonumber(config.ClockTime) or oldLighting.ClockTime
            end
            if config.AmbientColor then
                Lighting.Ambient = Color3.fromRGB(
                    tonumber(config.AmbientR) or 120,
                    tonumber(config.AmbientG) or 120,
                    tonumber(config.AmbientB) or 140
                )
                Lighting.OutdoorAmbient = Color3.fromRGB(
                    tonumber(config.OutdoorR) or 140,
                    tonumber(config.OutdoorG) or 140,
                    tonumber(config.OutdoorB) or 160
                )
            end
        end
        if config.NoFog then
            Lighting.FogStart = 1e9
            Lighting.FogEnd = 1e9
            pcall(function() Lighting.Atmosphere.Density = 0 end)
        else
            Lighting.FogStart = oldLighting.FogStart
            Lighting.FogEnd = oldLighting.FogEnd
        end
        CC.Enabled = true
        CC.Saturation = tonumber(config.Saturation) or 0
        CC.Contrast = tonumber(config.Contrast) or 0
        if config.TintEnabled then
            CC.TintColor = Color3.fromRGB(
                tonumber(config.TintR) or 255,
                tonumber(config.TintG) or 255,
                tonumber(config.TintB) or 255
            )
        else
            CC.TintColor = Color3.new(1, 1, 1)
        end
        if config.ColorShiftEnabled then
            pcall(function()
                Lighting.ColorShift_Top = Color3.fromRGB(
                    tonumber(config.ColorShiftR) or 0,
                    tonumber(config.ColorShiftG) or 0,
                    tonumber(config.ColorShiftB) or 0
                )
                Lighting.ColorShift_Bottom = Lighting.ColorShift_Top
            end)
        end
        BloomFX.Enabled = config.BloomEnabled and true or false
        BloomFX.Intensity = tonumber(config.BloomIntensity) or 0.4
        BlurFX.Enabled = config.BlurEnabled and true or false
        BlurFX.Size = tonumber(config.BlurSize) or 8
        if config.WallXray then task.defer(function() pcall(applyWallXray, true) end) end
        if config.MapColorEnabled then task.defer(function() pcall(applyMapColor, true) end) end
        if config.RemoveTextures then task.defer(function() pcall(applyRemoveTextures, true) end) end
        if config.XRayEnabled then task.defer(function() pcall(applyXRay, true) end) end
    end)
end

function ResetVisuals()
    pcall(function()
        Lighting.Brightness = oldLighting.Brightness
        Lighting.Ambient = oldLighting.Ambient
        Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
        Lighting.ExposureCompensation = oldLighting.ExposureCompensation
        Lighting.ClockTime = oldLighting.ClockTime
        Lighting.FogStart = oldLighting.FogStart
        Lighting.FogEnd = oldLighting.FogEnd
        Lighting.GlobalShadows = true
        pcall(function()
            Lighting.ColorShift_Top = Color3.new(0, 0, 0)
            Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        end)
    end)
    CC.Enabled = false
    CC.TintColor = Color3.new(1, 1, 1)
    BloomFX.Enabled = false
    BlurFX.Enabled = false
    config.WallXray = false
    config.MapColorEnabled = false
    config.XRayEnabled = false
    pcall(function() applyWallXray(false) end)
    pcall(function() applyMapColor(false) end)
    pcall(function() applyXRay(false) end)
    pcall(ResetCameraNormal)
end

-- ==================== DEFLECTION (para ESP) ====================
local deflecting = {}
Players.PlayerRemoving:Connect(function(p) deflecting[p] = nil end)
function updateDeflection()
    if not FighterController or not FighterController.Objects then return end
    for _, fighterObj in pairs(FighterController.Objects) do
        local player = fighterObj.Player
        if player then
            if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
                deflecting[player] = false
            else
                local equipped = fighterObj.EquippedItem
                local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
                local isDeflecting = false
                if isKatana then
                    isDeflecting = (equipped._attack_cooldown and equipped._attack_cooldown > tick()) or false
                end
                deflecting[player] = isDeflecting
            end
        end
    end
end
function isDeflecting(plr) return deflecting[plr] == true end

-- ==================== ITEM FIRE (helper) ====================
function targetHasShield(char)
    if not char then return true end
    if char:FindFirstChildOfClass("ForceField") then return true end
    for _, c in ipairs(char:GetChildren()) do
        local n = string.lower(c.Name)
        if n:find("forcefield") or n:find("shield") or n:find("spawnprotect") then return true end
    end
    return false
end

function fireRageUseItem(item, desyncCF, targetHead, targetRoot)
    if not util or not enum or not item then return end
    if targetHead and targetHead.Parent and targetHasShield(targetHead.Parent) then return end
    local originPos = desyncCF and desyncCF.Position or targetRoot.Position
    local targetPos = targetHead.Position
    local aimCF = CFrame.lookAt(originPos, targetPos)
    local targetCF = targetHead.CFrame
    local objSpaceHeadOffset = targetCF:ToObjectSpace(CFrame.new(targetPos))
    local cameradata = {}
    cameradata[utf8.char(1)] = {
        [utf8.char(0)] = util:EncodeCFrame(aimCF),
        [utf8.char(1)] = util:EncodeCFrame(targetCF),
        [utf8.char(2)] = targetHead,
        [utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOffset)
    }
    pcall(function()
        RS.Remotes.Replication.Fighter.UseItem:FireServer(
            item:Get("ObjectID"),
            enum:ToEnum("StartShooting"),
            cameradata,
            nil
        )
    end)
end

-- ==================== SILENT AIM + FOV ====================
local StartSilentAim, StopSilentAim, StartFOVDraw, silentTarget, silentCFD, loadSilentDeps, updateFOVCircle, fovColor, isVisibleWall
function InitCombatHooks()
local FOV_COLORS = {
    White = Color3.fromRGB(255, 255, 255),
    Red = Color3.fromRGB(255, 70, 80),
    Green = Color3.fromRGB(80, 255, 140),
    Cyan = Color3.fromRGB(80, 220, 255),
    Magenta = Color3.fromRGB(255, 100, 220),
    Yellow = Color3.fromRGB(255, 230, 80),
    Orange = Color3.fromRGB(255, 160, 50),
    Purple = Color3.fromRGB(168, 85, 255),
}
fovColor = function(name)
    if typeof(name) == "Color3" then return name end
    return FOV_COLORS[name or "White"] or Color3.fromRGB(255, 255, 255)
end

local fovScreenGui
function ensureFovGui()
    if fovScreenGui and fovScreenGui.Parent then return fovScreenGui end
    local parent
    pcall(function() parent = gethui and gethui() end)
    if not parent then pcall(function() parent = game:GetService("CoreGui") end) end
    if not parent then parent = LocalPlayer:FindFirstChild("PlayerGui") end
    local g = Instance.new("ScreenGui")
    g.Name = "ShakoFOV_Grief"
    g.DisplayOrder = 99980
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent = parent
    fovScreenGui = g
    return g
end

function buildGriefFOV(name, cfg)
    local gui = ensureFovGui()
    local container = Instance.new("Frame")
    container.Name = name
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Parent = gui

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BackgroundTransparency = cfg.fillTrans or 0.92
    fill.BorderSizePixel = 0
    fill.ZIndex = 1
    fill.Parent = container
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local fillgrad = Instance.new("UIGradient")
    fillgrad.Color = ColorSequence.new(cfg.col1 or Color3.new(1,1,1), cfg.col2 or Color3.new(1,1,1))
    fillgrad.Parent = fill

    local outline = Instance.new("Frame")
    outline.Size = UDim2.fromScale(1, 1)
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 0
    outline.ZIndex = 2
    outline.Parent = container
    Instance.new("UICorner", outline).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = cfg.thickness or 1.5
    stroke.Transparency = cfg.outlineTrans or 0.08
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = outline
    local strokegrad = Instance.new("UIGradient")
    strokegrad.Color = ColorSequence.new(cfg.col1 or Color3.new(1,1,1), cfg.col2 or Color3.fromRGB(180,180,255))
    strokegrad.Parent = stroke

    return { container = container, fill = fill, fillgrad = fillgrad, stroke = stroke, strokegrad = strokegrad }
end

local silentFOVUI = buildGriefFOV("SilentFOV", {
    fillTrans = 0.92, thickness = 1.5,
    col1 = Color3.fromRGB(255,255,255), col2 = Color3.fromRGB(180,200,255),
})
local aimbotFOVUI = buildGriefFOV("AimbotFOV", {
    fillTrans = 0.94, thickness = 1.5,
    col1 = Color3.fromRGB(255,210,80), col2 = Color3.fromRGB(255,120,50),
})

function applyFOVUI(ui, enabled, show, radius, colName, doFill, fillTrans, animated, spin, outlineCol, fillC1, fillC2, fillC3)
    if not ui or not ui.container then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vis = enabled and show
    ui.container.Visible = vis and true or false
    if not vis then return end

    local col = outlineCol
    if typeof(col) ~= "Color3" then col = fovColor(colName) end
    local c1 = (typeof(fillC1) == "Color3" and fillC1) or col
    local c2 = (typeof(fillC2) == "Color3" and fillC2) or Color3.new(
        math.clamp(col.R * 0.7 + 0.15, 0, 1), math.clamp(col.G * 0.7 + 0.15, 0, 1), math.clamp(col.B * 0.85 + 0.2, 0, 1))
    local c3 = (typeof(fillC3) == "Color3" and fillC3) or Color3.new(
        math.clamp(col.R * 0.45 + 0.1, 0, 1), math.clamp(col.G * 0.45 + 0.1, 0, 1), math.clamp(col.B * 0.7 + 0.25, 0, 1))

    local r = tonumber(radius) or 120
    if animated then r = r * (0.97 + 0.03 * math.sin(tick() * 2.2)) end
    local center = cam.ViewportSize / 2
    ui.container.Position = UDim2.fromOffset(center.X, center.Y)
    ui.container.Size = UDim2.fromOffset(r * 2, r * 2)

    if ui.fill then
        ui.fill.Visible = doFill and true or false
        ui.fill.BackgroundTransparency = tonumber(fillTrans) or 0.92
        ui.fill.BackgroundColor3 = Color3.new(1, 1, 1)
        if ui.fillgrad then
            pcall(function()
                ui.fillgrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, c1),
                    ColorSequenceKeypoint.new(0.5, c2),
                    ColorSequenceKeypoint.new(1, c3),
                })
                if spin then
                    ui.fillgrad.Rotation = (tick() * (tonumber(config.SilentFOVSpinSpeed) or 1.2) * 60) % 360
                end
            end)
        end
    end
    if ui.stroke then
        ui.stroke.Color = col
        ui.stroke.Thickness = tonumber(config.SilentFOVThickness) or 1.5
        if ui.strokegrad then
            pcall(function()
                ui.strokegrad.Color = ColorSequence.new(col, col)
                if spin then
                    ui.strokegrad.Rotation = (tick() * (tonumber(config.SilentFOVSpinSpeed) or 1.2) * 90) % 360
                end
            end)
        end
    end
end

StartFOVDraw = function()
    SafeDisconnect("FOVDraw")
    local fovFrame = 0
    Connections.FOVDraw = RunService.Heartbeat:Connect(function()
        fovFrame += 1
        if fovFrame % 5 ~= 0 then return end
        local sOn = config.SilentAimEnabled and config.SilentShowFOV ~= false
        local aOn = config.AimbotEnabled and config.AimbotShowFOV ~= false
        if not sOn and not aOn then
            if silentFOVUI and silentFOVUI.container then silentFOVUI.container.Visible = false end
            if aimbotFOVUI and aimbotFOVUI.container then aimbotFOVUI.container.Visible = false end
            return
        end
        fovFrame = fovFrame + 1
        local needFast = (sOn and (config.SilentFOVAnimated or config.SilentFOVSpin)) or (aOn and (config.AimbotFOVAnimated or config.AimbotFOVSpin))
        if not needFast and fovFrame % 2 == 0 then return end
        if sOn then
            applyFOVUI(silentFOVUI, true, true,
                config.SilentFOV or 300, config.SilentFOVColor or "White",
                config.SilentFOVFill == true, config.SilentFOVFillTransparency,
                config.SilentFOVAnimated, config.SilentFOVSpin == true,
                config.SilentFOVOutlineColor3, config.SilentFOVFillC1, config.SilentFOVFillC2, config.SilentFOVFillC3)
        else
            if silentFOVUI and silentFOVUI.container then silentFOVUI.container.Visible = false end
        end
        if aOn then
            applyFOVUI(aimbotFOVUI, true, true,
                config.AimbotFOV or 180, config.AimbotFOVColor or "Yellow",
                config.AimbotFOVFill == true, config.AimbotFOVFillTransparency,
                config.AimbotFOVAnimated, config.AimbotFOVSpin == true,
                config.AimbotFOVOutlineColor3, config.AimbotFOVFillC1, config.AimbotFOVFillC2, config.AimbotFOVFillC3)
        else
            if aimbotFOVUI and aimbotFOVUI.container then aimbotFOVUI.container.Visible = false end
        end
    end)
end
StartFOVDraw()

isVisibleWall = function(fromPos, toPos, targetChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = { LocalPlayer.Character }
    if targetChar then table.insert(filter, targetChar) end
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true
    local res = workspace:Raycast(fromPos, toPos - fromPos, params)
    return res == nil
end

-- ==================== SILENT AIM (Kicia method) ====================
local GameplayUtility, GunModule
local silentHooked = false
local silentOldFire, silentOldRaycast, silentOldNamecall

loadSilentDeps = function()
    pcall(function() GameplayUtility = require(RS.Modules.GameplayUtility) end)
    pcall(function()
        local ok, gun = pcall(require, LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
        if ok and gun then GunModule = gun end
    end)
    if not util or not enum then pcall(loadRivalsModules) end
end
task.spawn(loadSilentDeps)

silentTarget = function()
    if not config.SilentAimEnabled then return nil end
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local center = cam.ViewportSize / 2
    local fov = math.max(tonumber(config.SilentFOV) or 300, 20)
    local bestHead, bestDist = nil, fov
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position or cam.CFrame.Position

    local function wallClear(fromPos, toPos, ignoreChar)
        if not config.SilentWallCheck and not config.SilentVisibleCheck then return true end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = { LocalPlayer.Character }
        if ignoreChar then table.insert(ignore, ignoreChar) end
        params.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(fromPos, toPos - fromPos, params)
        if not hit then return true end
        return hit.Instance and ignoreChar and hit.Instance:IsDescendantOf(ignoreChar)
    end

    local function getHitPart(char)
        if not char then return nil end
        local want = tostring(config.SilentHitPart or "Head")
        if (want == "Head" or want == "HitboxHead") and config.SilentUseHitboxHead ~= false then
            local hb = char:FindFirstChild("HitboxHead") or char:FindFirstChild("HitboxHeadSmall")
            if hb then return hb end
        end
        if want == "Torso" then
            return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                or char:FindFirstChild("HitboxBody") or char:FindFirstChild("HumanoidRootPart")
        end
        if want == "HitboxHead" then
            return char:FindFirstChild("HitboxHead") or char:FindFirstChild("HitboxHeadSmall") or char:FindFirstChild("Head")
        end
        return char:FindFirstChild(want) or char:FindFirstChild("Head")
            or char:FindFirstChild("HitboxBody") or char:FindFirstChild("HumanoidRootPart")
    end

    local function tryPart(char)
        if not char or char == myChar then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local part = getHitPart(char)
        if not part then return end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if sp.Z <= 0 then return end
        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(center.X, center.Y)).Magnitude
        if d > fov then return end
        if not wallClear(myPos, part.Position, char) then return end
        if d < bestDist then bestDist, bestHead = d, part end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if config.SilentTeamCheck ~= false and StrongIsTeammate and StrongIsTeammate(plr) then continue end
        tryPart(plr.Character)
    end
    pcall(function()
        for _, entity in ipairs(game:GetService("CollectionService"):GetTagged("Entity")) do
            local plr = Players:GetPlayerFromCharacter(entity)
            if plr == LocalPlayer then continue end
            if plr and config.SilentTeamCheck and IsEnemy and not IsEnemy(plr) then continue end
            tryPart(entity)
        end
    end)
    return bestHead
end

function silentPredictPos(head, origin)
    local pos = head.Position
    if config.SilentPredict == false then return pos end
    local char = head.Parent
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return pos end
    local vel = Vector3.zero
    pcall(function() vel = root.AssemblyLinearVelocity end)
    if vel.Magnitude < 4 then return pos end
    local vFlat = Vector3.new(vel.X, vel.Y * 0.35, vel.Z)
    local t = math.clamp(tonumber(config.SilentPredictAmount) or 0.08, 0, 0.35)
    if origin then
        local dist = (pos - origin).Magnitude
        t = t + math.clamp(dist / 2200, 0, 0.08)
    end
    return pos + vFlat * t
end

local function kiciaEncodeCF(cf)
    if not cf then return nil end
    if util and util.EncodeCFrame then
        local ok, enc = pcall(function() return util:EncodeCFrame(cf) end)
        if ok and enc ~= nil then return enc end
    end
    local rx, ry, rz = cf:ToOrientation()
    return {
        [utf8.char(0)] = cf.X, [utf8.char(1)] = cf.Y, [utf8.char(2)] = cf.Z,
        [utf8.char(3)] = rx, [utf8.char(4)] = ry, [utf8.char(5)] = rz,
    }
end

local function kiciaDecodeCF(t)
    if type(t) ~= "table" then return nil end
    if util and util.DecodeCFrame then
        local ok, cf = pcall(function() return util:DecodeCFrame(t) end)
        if ok and typeof(cf) == "CFrame" then return cf end
    end
    local x = t[utf8.char(0)] or t[0]
    local y = t[utf8.char(1)] or t[1]
    local z = t[utf8.char(2)] or t[2]
    local rx = t[utf8.char(3)] or t[3]
    local ry = t[utf8.char(4)] or t[4]
    local rz = t[utf8.char(5)] or t[5]
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return nil end
    rx = type(rx) == "number" and rx or 0
    ry = type(ry) == "number" and ry or 0
    rz = type(rz) == "number" and rz or 0
    return CFrame.new(x, y, z) * CFrame.fromOrientation(rx, ry, rz)
end

local function kiciaObjectSpace(origin, hitbox, aimPos)
    if not origin or not hitbox or not aimPos then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { hitbox }
    local hit = workspace:Raycast(origin, aimPos - origin, params)
    if not hit then
        local ok, closest = pcall(function() return hitbox:GetClosestPointOnSurface(origin) end)
        if ok and closest then
            local os = hitbox.CFrame:PointToObjectSpace(closest)
            if os ~= Vector3.zero then return os end
        end
        return hitbox.CFrame:PointToObjectSpace(aimPos)
    end
    local os = hitbox.CFrame:PointToObjectSpace(hit.Position)
    if os == Vector3.zero then return nil end
    return os
end

silentCFD = function(origin, head)
    if not head or not origin then return nil end
    local aimPos = head.Position
    local os = kiciaObjectSpace(origin, head, aimPos) or Vector3.new(0, 0, 0)
    return {
        [utf8.char(1)] = {
            [utf8.char(0)] = kiciaEncodeCF(CFrame.lookAt(origin, aimPos)),
            [utf8.char(1)] = kiciaEncodeCF(head.CFrame),
            [utf8.char(2)] = head,
            [utf8.char(3)] = kiciaEncodeCF(CFrame.new(os)),
        }
    }
end

function silentIsStartShooting(enumVal)
    if enumVal == nil then return false end
    if enum then
        local ok, shoot = pcall(function() return enum:ToEnum("StartShooting") end)
        if ok and shoot ~= nil and enumVal == shoot then return true end
    end
    if type(enumVal) == "string" and string.find(string.lower(enumVal), "startshoot", 1, true) then return true end
    return false
end

-- Extend melee range (parte del aim/silent)
local MELEE_NAMES = {
    knife=true, fists=true, katana=true, scythe=true, chainsaw=true,
    trowel=true, daggers=true, dagger=true, ["battle axe"]=true,
    ["glass shard"]=true, ["riot shield"]=true, fist=true, axe=true,
    sword=true, bat=true, hammer=true, melee=true,
}
local function kiciaCFEncode(cf)
    local p, y, r = cf:ToOrientation()
    return {
        [utf8.char(0)] = cf.X, [utf8.char(1)] = cf.Y, [utf8.char(2)] = cf.Z,
        [utf8.char(3)] = p, [utf8.char(4)] = y, [utf8.char(5)] = r,
    }
end
local function kiciaCFDecode(t)
    if type(t) ~= "table" then return nil end
    local x, y, z = t[utf8.char(0)], t[utf8.char(1)], t[utf8.char(2)]
    local p, yw, r = t[utf8.char(3)], t[utf8.char(4)], t[utf8.char(5)]
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return nil end
    return CFrame.new(x, y, z) * CFrame.fromOrientation(p or 0, yw or 0, r or 0)
end
function isMeleeEquipped()
    local ok, res = pcall(function()
        if not FighterController then
            pcall(function()
                FighterController = require(LocalPlayer.PlayerScripts.Controllers.FighterController)
            end)
        end
        local lf = FighterController and FighterController.LocalFighter
        if not lf then return false end
        local slot = nil
        pcall(function() slot = lf.EquippedSlot or lf.Slot end)
        if slot == 3 or slot == "Melee" or tostring(slot) == "3" then return true end
        local item = lf.EquippedItem
        if not item then return false end
        local name = ""
        pcall(function() name = tostring(item.Name or "") end)
        name = string.lower(name)
        if MELEE_NAMES[name] then return true end
        for k in pairs(MELEE_NAMES) do
            if string.find(name, k, 1, true) then return true end
        end
        return false
    end)
    return ok and res == true
end
function findClosestEnemyRootMelee(origin, range)
    local best, bestD = nil, range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local skip = false
            pcall(function()
                if config.TeamCheck and type(IsSameTeam) == "function" and IsSameTeam(plr) then skip = true end
            end)
            if not skip then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local d = (hrp.Position - origin).Magnitude
                    if d <= bestD then bestD, best = d, hrp end
                end
            end
        end
    end
    return best
end
function applyExtendMelee(camdata)
    if not config.ExtendMeleeRange then return camdata end
    if not isMeleeEquipped() then return camdata end
    if type(camdata) ~= "table" then return camdata end
    local range = tonumber(config.ExtendMeleeRangeDist) or 10
    if range < 5 then range = 5 end
    if range > 20 then range = 20 end
    local k1, k0 = utf8.char(1), utf8.char(0)
    local block = camdata[k1]
    if type(block) ~= "table" then
        if camdata[k0] ~= nil then block = camdata else return camdata end
    end
    local raw = block[k0]
    local origin = nil
    local useTable = type(raw) == "table" and type(raw[k0]) == "number"
    if useTable then
        local cf = kiciaCFDecode(raw)
        if cf then origin = cf.Position end
    end
    if not origin and util and util.DecodeCFrame and raw then
        local ok, cf = pcall(function() return util:DecodeCFrame(raw) end)
        if ok and typeof(cf) == "CFrame" then origin = cf.Position end
    end
    if not origin then
        local my = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not my then return camdata end
        origin = my.Position
    end
    local enemy = findClosestEnemyRootMelee(origin, range)
    if not enemy then return camdata end
    local aimCF = CFrame.new(enemy.Position) * CFrame.fromOrientation(-1.5707963267948966, 0, 0)
    local enc = kiciaCFEncode(aimCF)
    block[k0], block[k1] = enc, enc
    return camdata
end

task.spawn(function()
    for _ = 1, 40 do
        if silentOldFire then return end
        local ok, UseItem = pcall(function()
            return game:GetService("ReplicatedStorage").Remotes.Replication.Fighter.UseItem
        end)
        if ok and UseItem and hookfunction then
            pcall(function()
                silentOldFire = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra, ...)
                    if config.ExtendMeleeRange and type(applyExtendMelee) == "function" then
                        local okM, patchedM = pcall(applyExtendMelee, camdata)
                        if okM and patchedM ~= nil then camdata = patchedM end
                    end
                    if config.SilentAimEnabled and getgenv()._ShakoSilentActive then
                        local isShoot = false
                        pcall(function()
                            if type(silentIsStartShooting) == "function" then
                                isShoot = silentIsStartShooting(enumVal) == true
                            end
                        end)
                        if isShoot then
                            local patchFn = getgenv()._ShakoSilentPatch
                            if type(patchFn) == "function" then
                                local okP, patched = pcall(patchFn, camdata)
                                if okP and patched ~= nil then camdata = patched end
                            end
                        end
                    end
                    return silentOldFire(self, objID, enumVal, camdata, extra, ...)
                end))
            end)
            return
        end
        task.wait(0.25)
    end
end)

StartSilentAim = function()
    loadSilentDeps()
    if not util or not enum then
        pcall(loadRivalsModules)
        loadSilentDeps()
    end
    if not util or not enum then
        Notify("Silent", "Modules no listos — reintenta")
        return
    end

    getgenv()._ShakoSilentState = getgenv()._ShakoSilentState or { locked = nil, lockedAt = 0, lastSwitch = 0 }
    local SState = getgenv()._ShakoSilentState

    if config.SilentForceAiming then
        pcall(function()
            local ok, gun = pcall(require, LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun)
            if ok and gun and gun.IsFullyAiming then
                gun.IsFullyAiming = function() return true end
            end
        end)
    end

    local function getSilentPart()
        local t = silentTarget()
        if not t then SState.locked = nil return nil end
        local now = tick()
        local switchDelay = tonumber(config.SilentSwitchDelay) or 0
        local react = tonumber(config.SilentReactionTime) or 0
        if SState.locked and SState.locked.Parent and switchDelay > 0 then
            if (now - (SState.lastSwitch or 0)) < switchDelay then t = SState.locked end
        end
        if t ~= SState.locked then
            SState.locked = t
            SState.lockedAt = now
            SState.lastSwitch = now
        end
        if react > 0 and (now - (SState.lockedAt or 0)) < react then return nil end
        return t
    end

    local function patchCamdata(camdata)
        if config.SilentManipulate == false then return camdata end
        local chance = tonumber(config.SilentActivationChance) or 100
        if chance < 100 and math.random() > (chance / 100) then return camdata end

        local ok, result = pcall(function()
            local hitbox = getSilentPart()
            if not hitbox then return camdata end
            if type(camdata) ~= "table" then return camdata end
            local key = utf8.char(1)
            local entry = camdata[key]
            if type(entry) ~= "table" then
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not root then return camdata end
                return silentCFD(root.Position, hitbox) or camdata
            end
            local aim0 = kiciaDecodeCF(entry[utf8.char(0)])
            local aim1 = kiciaDecodeCF(entry[utf8.char(1)])
            local originPos
            if aim0 then
                originPos = aim0.Position
            else
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                originPos = root and root.Position
            end
            if not originPos then return camdata end
            local targetPos = hitbox.Position
            local up = tonumber(config.SilentHeadOffsetY) or 0
            if up ~= 0 then targetPos = targetPos + Vector3.new(0, up, 0) end
            if config.SilentPredict then
                local pred = silentPredictPos(hitbox, originPos)
                targetPos = Vector3.new(pred.X, targetPos.Y, pred.Z)
            end
            local os = kiciaObjectSpace(originPos, hitbox, targetPos)
            if not os then return camdata end
            entry[utf8.char(0)] = kiciaEncodeCF(CFrame.lookAt(originPos, targetPos))
            if aim1 then
                entry[utf8.char(1)] = kiciaEncodeCF(CFrame.lookAt(aim1.Position, targetPos))
            else
                entry[utf8.char(1)] = kiciaEncodeCF(hitbox.CFrame)
            end
            entry[utf8.char(2)] = hitbox
            entry[utf8.char(3)] = kiciaEncodeCF(CFrame.new(os))
            return camdata
        end)
        if ok and result ~= nil then return result end
        return camdata
    end

    local UseItem
    pcall(function() UseItem = RS.Remotes.Replication.Fighter.UseItem end)

    getgenv()._ShakoSilentPatch = patchCamdata
    getgenv()._ShakoSilentActive = true

    if UseItem and hookfunction and not silentOldFire then
        pcall(function()
            silentOldFire = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra, ...)
                if config.ExtendMeleeRange and type(applyExtendMelee) == "function" then
                    local okM, patchedM = pcall(applyExtendMelee, camdata)
                    if okM and patchedM ~= nil then camdata = patchedM end
                end
                if config.SilentAimEnabled and getgenv()._ShakoSilentActive then
                    local isShoot = false
                    pcall(function()
                        if type(silentIsStartShooting) == "function" then
                            isShoot = silentIsStartShooting(enumVal) == true
                        end
                    end)
                    if isShoot then
                        local patchFn = getgenv()._ShakoSilentPatch
                        if type(patchFn) == "function" then
                            local ok, patched = pcall(patchFn, camdata)
                            if ok and patched ~= nil then camdata = patched end
                        end
                    end
                end
                return silentOldFire(self, objID, enumVal, camdata, extra, ...)
            end))
        end)
    end

    silentHooked = true
    config.SilentAimEnabled = true
    Notify("Silent", "ON · Kicia method")
end

StopSilentAim = function()
    config.SilentAimEnabled = false
    getgenv()._ShakoSilentActive = false
    getgenv()._ShakoSilentPatch = nil
    Notify("Silent", "OFF")
end
end -- InitCombatHooks

InitCombatHooks()

-- ==================== AIMBOT (cámara) ====================
local aimbotHolding = false

function AimbotIsEnemy(plr)
    if not plr or plr == LocalPlayer then return false end
    if not plr.Character then return false end
    local tc = config.AimbotTeamCheck
    if tc == nil then tc = true end
    if config.TeamCheck == true then tc = true end
    if tc then
        if StrongIsTeammate and StrongIsTeammate(plr) then return false end
        local a, b = LocalPlayer.Team, plr.Team
        if a ~= nil and b ~= nil and a == b then return false end
    end
    return true
end

function aimbotWallClear(fromPos, toPos, targetChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {}
    if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
    if targetChar then table.insert(filter, targetChar) end
    local vm = workspace:FindFirstChild("ViewModels")
    if vm then table.insert(filter, vm) end
    params.FilterDescendantsInstances = filter
    params.IgnoreWater = true
    local delta = toPos - fromPos
    local dist = delta.Magnitude
    if dist < 0.5 then return true end
    local res = workspace:Raycast(fromPos, delta.Unit * dist, params)
    if not res then return true end
    if targetChar and res.Instance and res.Instance:IsDescendantOf(targetChar) then return true end
    return false
end

function GetAimbotTargetRivals()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local partName = config.AimbotPart or "Head"
    local fov = tonumber(config.AimbotFOV) or 400
    local center = UserInputService:GetMouseLocation()
    if not center or center.X == 0 then
        center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
    end
    local bestPart, bestScore = nil, math.huge
    local camPos = cam.CFrame.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not AimbotIsEnemy(plr) then continue end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild(partName) or char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not head or not hum or hum.Health <= 0 then continue end
        local sp, onScreen = cam:WorldToViewportPoint(head.Position)
        if sp.Z <= 0 then continue end
        local screenDist = (Vector2.new(sp.X, sp.Y) - Vector2.new(center.X, center.Y)).Magnitude
        if screenDist > fov then continue end
        if config.AimbotWallCheck or config.AimbotVisibleCheck then
            if not aimbotWallClear(camPos, head.Position, char) then continue end
        end
        if screenDist < bestScore then bestScore, bestPart = screenDist, head end
    end
    return bestPart
end

local StartAimbot, StopAimbot

StartAimbot = function()
    SafeDisconnect("Aimbot")
    SafeDisconnect("AimbotInput")
    SafeDisconnect("AimbotInputEnd")

    local st = getgenv()._ShakoAimKB or { held = false, toggled = false }
    getgenv()._ShakoAimKB = st
    st.held = false

    local function getKP()
        local opts = Library and Library.Options
        return opts and (opts.AimbotKey or opts["AimbotKey"]) or nil
    end
    local function normKey(v)
        if v == nil then return nil end
        if typeof(v) == "EnumItem" then return v end
        if type(v) == "string" then
            local s = v:gsub("%s+", "")
            if s == "" or s == "None" or s == "..." or s == "nil" then return nil end
            local low = s:lower()
            if low == "mb2" or low == "mousebutton2" or low == "mouse2" or low == "rightclick" then return Enum.UserInputType.MouseButton2 end
            if low == "mb1" or low == "mousebutton1" or low == "mouse1" or low == "leftclick" then return Enum.UserInputType.MouseButton1 end
            local ok, e = pcall(function() return Enum.KeyCode[s] end)
            if ok and e then return e end
            ok, e = pcall(function() return Enum.UserInputType[s] end)
            if ok and e then return e end
        end
        return nil
    end
    local function getKey()
        local kp = getKP()
        if kp then
            for _, field in ipairs({ "Value", "Key", "KeyCode", "Input", "Bind" }) do
                local k = normKey(rawget and rawget(kp, field) or kp[field])
                if k then return k end
            end
        end
        return Enum.UserInputType.MouseButton2
    end
    local function getMode()
        local cfg = tostring(config.AimbotKeyMode or ""):lower()
        if cfg:find("always") then return "always" end
        if cfg:find("toggle") then return "toggle" end
        if cfg:find("hold") then return "hold" end
        return "hold"
    end
    local function physDown(key)
        if not key then key = Enum.UserInputType.MouseButton2 end
        local ok, down = pcall(function()
            if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
                return UserInputService:IsKeyDown(key)
            end
            return UserInputService:IsMouseButtonPressed(key)
        end)
        return ok and down == true
    end
    local function matches(input, key)
        if not key or not input then return false end
        if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then return input.KeyCode == key end
        if typeof(key) == "EnumItem" and key.EnumType == Enum.UserInputType then return input.UserInputType == key end
        return false
    end
    local function isAimActive()
        if not config.AimbotEnabled then return false end
        local mode = getMode()
        local key = getKey()
        if mode == "always" then return true end
        if mode == "toggle" then return st.toggled == true end
        if st.held then return true end
        if physDown(key) then return true end
        return false
    end

    Connections.AimbotInput = UserInputService.InputBegan:Connect(function(input, gpe)
        local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
        if gpe and not isMouse then return end
        local key = getKey()
        local mode = getMode()
        local hit = matches(input, key)
            or (key == Enum.UserInputType.MouseButton2 and input.UserInputType == Enum.UserInputType.MouseButton2)
        if not hit then return end
        if mode == "hold" then
            st.held = true
        elseif mode == "toggle" then
            st.toggled = not (st.toggled == true)
            Notify("Aimbot", st.toggled and "Toggle ON" or "Toggle OFF")
        end
    end)
    Connections.AimbotInputEnd = UserInputService.InputEnded:Connect(function(input)
        if getMode() ~= "hold" then return end
        local key = getKey()
        if matches(input, key) or (key == Enum.UserInputType.MouseButton2 and input.UserInputType == Enum.UserInputType.MouseButton2) then
            st.held = false
        end
    end)

    local function aimStep()
        if not config.AimbotEnabled then return end
        if not isAimActive() then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local target = GetAimbotTargetRivals and GetAimbotTargetRivals()
        if not target or not target.Parent then return end
        local aimPos = target.Position
        local screenPos, onScreen = cam:WorldToViewportPoint(aimPos)
        if not onScreen and screenPos.Z < 0 then return end
        local movedMouse = false
        pcall(function()
            local mouse = UserInputService:GetMouseLocation()
            local dx = screenPos.X - mouse.X
            local dy = screenPos.Y - mouse.Y
            local smooth = tonumber(config.AimbotSmooth) or 0.9
            local sens = math.clamp(smooth, 0.2, 1)
            dx, dy = dx * sens, dy * sens
            if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then return end
            if mousemoverel then
                mousemoverel(dx, dy)
                movedMouse = true
            elseif Input and Input.MouseMove then
                Input.MouseMove(dx, dy)
                movedMouse = true
            end
        end)
        if not movedMouse then
            local pos = cam.CFrame.Position
            cam.CFrame = CFrame.new(pos, aimPos)
        end
    end

    local aimFrame = 0
    Connections.Aimbot = RunService.RenderStepped:Connect(function()
        aimFrame += 1
        if aimFrame % 3 ~= 0 then return end
        pcall(aimStep)
    end)
    Notify("Aimbot", "ON · Hold = mantener tecla")
end

StopAimbot = function()
    SafeDisconnect("Aimbot")
    SafeDisconnect("AimbotInput")
    SafeDisconnect("AimbotInputEnd")
    aimbotHolding = false
end
-- ============ FIN PARTE 1/3 ============
-- ======================================================================
--  PARTE 2/3  ·  BUILD LEGIT  ·  ESP (jugadores + world)
--  (sigue donde terminó la PARTE 1)
-- ======================================================================

-- stub: nombre de arma equipada (lo usa el ESP)
if type(getWeaponName) ~= "function" then
    function getWeaponName(plr)
        local ok, name = pcall(function()
            local lf = FighterController and FighterController.LocalFighter
            if plr and plr ~= LocalPlayer then
                for _, fo in pairs((FighterController and FighterController.Objects) or {}) do
                    if fo.Player == plr then lf = fo break end
                end
            end
            local item = lf and lf.EquippedItem
            if not item then return "" end
            return tostring(item.Name or (item.Get and item:Get("Name")) or "")
        end)
        return ok and name or ""
    end
end
if type(Rivals) ~= "table" then Rivals = Rivals or {} end

-- ==================== LUAHOOK ESP (integrado bien) ====================
do
    if type(State) ~= "table" then
        State = {}
    end
    State.ESPObjects = State.ESPObjects or {}
    State.PrimaryTarget = State.PrimaryTarget
    State.RainbowHue = State.RainbowHue or 0
end

function getSafePlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p and p:IsA("Player") then
            list[#list + 1] = p
        end
    end
    return list
end

-- Config unificado (ESP + world keys)
if type(Config) ~= "table" or getmetatable(Config) == nil then
    Config = setmetatable({}, {
        __index = function(_, k)
            if k == "ESP" then
                return config.ESPEnabled == true or config.ESP == true
            end
            if k == "Weather" then
                return config.WeatherEnabled == true or config.Weather == true
            end
            if k == "ThirdPersonEnabled" then
                return config.ThirdPerson == true or config.ThirdPersonEnabled == true
            end
            -- map UI names → LuaHook names
            if k == "ESPBox" then return config.ESPShowBox ~= false end
            if k == "ESPName" then return config.ESPShowName ~= false end
            if k == "ESPDistance" then return config.ESPShowDist ~= false end
            if k == "ESPHealth" or k == "ESPHealthBar" then return config.ESPShowHP ~= false end
            local v = config[k]
            if v ~= nil then return v end
            -- defaults sensatos para que se vea bien (estilo UE / LuaHook)
            local defaults = {
                ESPBoxStyle = "Corner Brackets",
                ESPBoxBrackets = true,
                ESPBoxThickness = 2,
                ESPCasingThickness = 2,
                ESPBoxColor = Color3.fromRGB(255, 255, 255),
                ESPBoxTransparency = 0,
                ESPBoxFill = false,
                ESPBoxScale = 1,
                ESPCornerLength = 0.28,
                ESPNameMode = "DisplayName",
                ESPTeamCheck = false,
                ESPMaxDistance = 100000,
                ESPDistanceScaling = true,
                ESPDistanceScalingRef = 50,
                ESPHealthColorMode = "Ramp",
                ESPHealthSmooth = true,
                ESPHealthNumberMode = "Always",
                ESPHealthGhost = true,
                ColorEnemy = Color3.fromRGB(255, 255, 255),
            }
            return defaults[k]
        end,
        __newindex = function(_, k, v)
            if k == "ESP" then
                config.ESPEnabled = v and true or false
                config.ESP = v and true or false
            elseif k == "Weather" then
                config.WeatherEnabled = v and true or false
                config.Weather = v and true or false
            else
                config[k] = v
            end
        end,
    })
end

local lp = LocalPlayer
Camera = workspace.CurrentCamera
pcall(function()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera
    end)
end)

if screenDraw == nil then
    screenDraw = nil
end

-- Helpers que el ESP de LuaHook necesita
function envIdOf(player)
    local id = nil
    pcall(function()
        if not player then return end
        id = player:GetAttribute("EnvironmentID")
        if id ~= nil then return end
        local char = player.Character
        if char then id = char:GetAttribute("EnvironmentID") end
    end)
    return id
end

function isTeammate(player)
    if player == LocalPlayer or player == lp then return true end
    local a = LocalPlayer:GetAttribute("TeamID")
    local b = player:GetAttribute("TeamID")
    if a ~= nil and b ~= nil then
        return a == b
    end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return LocalPlayer.Team == player.Team
    end
    return false
end

;(function()
function isAlive(player)
    local c = player and player.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then return h.Health > 0 end
    return c:FindFirstChild("HumanoidRootPart") ~= nil or c:FindFirstChild("Head") ~= nil
end

function getHealth(player)
    local c = player and player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, math.max(h.MaxHealth, 1)
end

function isVisible(worldPos)
    local cam = workspace.CurrentCamera
    if not cam or not worldPos then return true end
    local origin = cam.CFrame.Position
    local dir = worldPos - origin
    local dist = dir.Magnitude
    if dist < 1 then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { LocalPlayer.Character }
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(ignore, p.Character) end
        end
    end)
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(origin, dir.Unit * dist, params)
    return hit == nil
end

local ESP = {}
    local hasDrawing  = screenDraw ~= nil
    local _renderConn = nil
    local _espFrame   = 0
    local _lastRenderT = 0
    local _dcLastT    = 0
    local _bboxCache  = {}
    local _bboxFrameN = {}
    local _ctx        = {}
    local _renderArr  = {}
    local _dcArr      = {}
    local _radarO     = { drawings = {} }
    local _module     = { drawings = {} }
    local BLACK = Color3.new(0, 0, 0)
    local WHITE = Color3.new(1, 1, 1)
    local INK   = Color3.fromRGB(4, 6, 10)
    local HPBG  = Color3.fromRGB(11, 15, 22)
    local HP_W       = 5
    local HP_GAP     = 6
    local PAD        = 5
    local FLAG_GAP   = 6
    local BASE_H     = 1080
    local MIN_W      = 8
    local MIN_H      = 13
    local BOX_W_STUDS = 4   * 1000 / 1080
    local BOX_H_STUDS = 6.5 * 1000 / 1080
    local TEXT_FLOOR  = 8
    local DIST_MIN_MUL = 0.5
    local cam        = Camera
    local FACES = {}
    for _, n in ipairs({ "Code", "RobotoMono", "Gotham", "GothamBold", "Arial", "SourceSans" }) do
        local ok, f = pcall(function() return Enum.Font[n] end)
        if ok and f then FACES[n] = f end
    end
    if FACES.Code == nil then FACES.Code = Enum.Font.SourceSans end
    local _customFaces = {}
    function faceFor(name)
        local c = _customFaces[name]
        if c ~= nil then return c end
        return FACES[name] or FACES.Code
    end
    local GLYPH_TRI = string.char(0xE2, 0x96, 0xB2)
    local GLYPH_MID = string.char(0xC2, 0xB7)
    function typePx(base, scale)
        local v = math.floor(base * scale + 0.5)
        if v < TEXT_FLOOR then v = TEXT_FLOOR end
        return v
    end
    function distMul(dist)
        if not Config.ESPDistanceScaling then return 1 end
        local ref = Config.ESPDistanceScalingRef or 50
        return math.clamp(ref / math.max(dist or 1, 1), DIST_MIN_MUL, 1)
    end
    function sizeFor(base, mul)
        local v = math.floor(base * (mul or 1) + 0.5)
        if v < TEXT_FLOOR then v = TEXT_FLOOR end
        return v
    end
    function styleLabel(t, face, size, casing)
        if typeof(face) == "EnumItem" then
            if t.Font ~= face then t.Font = face end
        else
            if t.FontFace ~= face then t.FontFace = face end
        end
        if t.TextSize ~= size then t.TextSize = size end
        local st = t:FindFirstChildOfClass("UIStroke")
        if st then
            local c = casing or 2
            if st.Thickness ~= c then st.Thickness = c end
            if st.Enabled ~= (c > 0) then st.Enabled = c > 0 end
        end
    end
    local _seqCache = {}
    function gradSeq(key, a, b)
        if not a or not b then return nil end
        local s = _seqCache[key]
        if s and s.a == a and s.b == b then return s.seq end
        local seq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(0.5, b),
            ColorSequenceKeypoint.new(1, a),
        })
        _seqCache[key] = { a = a, b = b, seq = seq }
        return seq
    end
    function paint(inst, prop, key, mode, solid, ga, gb, rot, spin, now)
        if inst == nil then return end
        if mode == "Gradient" then
            local seq = gradSeq(key, ga, gb)
            if seq then
                if inst[prop] ~= WHITE then inst[prop] = WHITE end
                local ug = inst:FindFirstChildOfClass("UIGradient")
                if ug == nil then ug = Instance.new("UIGradient"); ug.Parent = inst end
                if ug.Color ~= seq then ug.Color = seq end
                local r = rot or 0
                if spin and spin > 0 then r = (r + (now or 0) * spin * 360) % 360 end
                if ug.Rotation ~= r then ug.Rotation = r end
                if not ug.Enabled then ug.Enabled = true end
                return
            end
        end
        local ug = inst:FindFirstChildOfClass("UIGradient")
        if ug and ug.Enabled then ug.Enabled = false end
        local c = solid or WHITE
        if inst[prop] ~= c then inst[prop] = c end
    end
    function healthColor(frac)
        local mode = Config.ESPHealthColorMode or "Ramp"
        if mode == "Solid" then return Config.ESPHealthColor or Color3.fromRGB(61, 224, 122) end
        if mode == "Gradient" then return WHITE end
        if hpRamp then return hpRamp(frac) end
        return Config.ESPHealthColor or Color3.fromRGB(61, 224, 122)
    end
    local _lock = { obj = nil, cand = nil, candT = 0 }
    function resolveLock(bestO, bestD, lockO, lockD, now)
        local lk = _lock
        if bestO == nil then lk.obj = nil; lk.cand = nil; return nil end
        local prev = lk.obj
        if lk.obj == nil or lockO == nil then
            lk.obj = bestO; lk.cand = nil
        elseif bestO == lk.obj then
            lk.cand = nil
        elseif bestD <= (lockD or math.huge) * 0.9 then
            if lk.cand == bestO then
                if (now - (lk.candT or now)) >= 0.5 then lk.obj = bestO; lk.cand = nil end
            else
                lk.cand = bestO; lk.candT = now
            end
        else
            lk.cand = nil
        end
        if lk.obj and lk.obj ~= prev then lk.obj._primT = now end
        return lk.obj
    end
    local SKEL_R15 = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    local SKEL_R6 = {
        {"Head","Torso"},
        {"Torso","Left Arm"},{"Torso","Right Arm"},
        {"Torso","Left Leg"},{"Torso","Right Leg"},
    }
    local FLAG_COLORS = {
        STARING     = Color3.fromRGB(255,  70,  85),
        DEFLECT     = Color3.fromRGB( 53, 215, 199),
        SHIELD      = Color3.fromRGB(255, 194,  75),
        INVINCIBLE  = Color3.fromRGB(255, 215,   0),
        LOW         = Color3.fromRGB(255,  90, 100),
    }
    local _gui, _absLayer = nil, nil
    function mkAbsLayer(g)
        local a = Instance.new("Frame")
        a.Name = "a"; a.BackgroundTransparency = 1; a.BorderSizePixel = 0
        a.Size = UDim2.fromScale(1, 1); a.Position = UDim2.new(); a.ZIndex = 1
        a.Parent = g
        return a
    end
    function espGui()
        if _gui and _gui.Parent then
            if _absLayer == nil or _absLayer.Parent ~= _gui then _absLayer = mkAbsLayer(_gui) end
            return _gui
        end
        local ok, g = pcall(function()
            local s = Instance.new("ScreenGui")
            s.Name = "\0" .. tostring(math.random(1e5, 1e6))
            s.IgnoreGuiInset  = true
            s.ResetOnSpawn    = false
            s.DisplayOrder    = 99990
            s.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
            local parent
            pcall(function() parent = gethui and gethui() end)
            if parent == nil then pcall(function() parent = game:GetService("CoreGui") end) end
            if parent == nil then parent = lp:FindFirstChildOfClass("PlayerGui") end
            s.Parent = parent
            return s
        end)
        if not ok or not g then return nil end
        _gui = g
        _absLayer = mkAbsLayer(g)
        return _gui
    end
    function mkFrame(parent, z)
        local f = Instance.new("Frame")
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.ZIndex = z or 1
        f.Parent = parent
        return f
    end
    function mkLabel(parent, z, align)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.RichText = true
        t.TextXAlignment = align or Enum.TextXAlignment.Center
        t.AutomaticSize = Enum.AutomaticSize.XY
        t.Size = UDim2.fromOffset(0, 0)
        t.ZIndex = z or 3
        t.TextColor3 = WHITE
        local st = Instance.new("UIStroke")
        st.Color = BLACK; st.Thickness = 1; st.Transparency = 0
        st.LineJoinMode = Enum.LineJoinMode.Round
        st.Parent = t
        t.Parent = parent
        return t
    end
    function mkList(parent, z, pad, horizAlign, vertAlign)
        local f = mkFrame(parent, z)
        f.AutomaticSize = Enum.AutomaticSize.XY
        f.Size = UDim2.fromOffset(0, 0)
        local l = Instance.new("UIListLayout")
        l.FillDirection        = Enum.FillDirection.Vertical
        l.SortOrder            = Enum.SortOrder.LayoutOrder
        l.Padding              = UDim.new(0, pad or 2)
        l.HorizontalAlignment  = horizAlign or Enum.HorizontalAlignment.Center
        l.VerticalAlignment    = vertAlign or Enum.VerticalAlignment.Top
        l.Parent = f
        return f
    end
    function mkRing(parent, z, colour, thick)
        local f = mkFrame(parent, z)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.Size = UDim2.fromScale(1, 1)
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.LineJoinMode    = Enum.LineJoinMode.Miter
        s.Color = colour; s.Thickness = thick; s.Transparency = 0
        s.Parent = f
        return f, s
    end
    function mkCasedRect(parent, z)
        local box = mkFrame(parent, z)
        box.Size = UDim2.fromScale(1, 1)
        local rIn,  sIn  = mkRing(box, z + 1, INK,   2)
        local rMid, sMid = mkRing(box, z + 2, WHITE, 2)
        local rOut, sOut = mkRing(box, z + 1, INK,   2)
        return box, sMid, sOut, sIn, rMid, rOut, rIn
    end
    function buildTree(o)
        local g = espGui(); if not g then return nil end
        local u = {}
        local root = mkFrame(g, 2)
        root.Name = "r"
        root.Visible = false
        root.Size = UDim2.fromOffset(MIN_W, MIN_H)
        u.root = root
        u.fill = mkFrame(root, 2)
        u.fill.Size = UDim2.fromScale(1, 1)
        u.fill.Visible = false
        u.box, u.boxStroke, u.caseOut, u.caseIn, u.ringMid, u.ringOut, u.ringIn = mkCasedRect(root, 3)
        u.box.Visible = false
        u.corners = {}
        for i = 1, 8 do
            local c = mkFrame(root, 6)
            c.BackgroundTransparency = 0
            c.BackgroundColor3 = WHITE
            c.Visible = false
            local cs = Instance.new("UIStroke")
            cs.Color = INK; cs.Thickness = 1; cs.Transparency = 0
            cs.LineJoinMode = Enum.LineJoinMode.Miter
            cs.Parent = c
            u.corners[i] = c
        end
        local hp = mkFrame(root, 4)
        hp.AnchorPoint = Vector2.new(1, 0)
        hp.Position = UDim2.new(0, -HP_GAP, 0, 0)
        hp.Size = UDim2.new(0, HP_W, 1, 0)
        hp.BackgroundTransparency = 0
        hp.BackgroundColor3 = HPBG
        local hs = Instance.new("UIStroke")
        hs.Color = INK; hs.Thickness = 1; hs.Transparency = 0
        hs.LineJoinMode = Enum.LineJoinMode.Miter
        hs.Parent = hp
        hp.Visible = false
        u.hp = hp
        u.hpGhost = mkFrame(hp, 5)
        u.hpGhost.BackgroundTransparency = 0
        u.hpGhost.BackgroundColor3 = WHITE
        u.hpGhost.AnchorPoint = Vector2.new(0, 1)
        u.hpGhost.Position = UDim2.fromScale(0, 1)
        u.hpGhost.Visible = false
        u.hpFill = mkFrame(hp, 6)
        u.hpFill.BackgroundTransparency = 0
        u.hpFill.BackgroundColor3 = WHITE
        u.hpFill.AnchorPoint = Vector2.new(0, 1)
        u.hpFill.Position = UDim2.fromScale(0, 1)
        u.hpFill.Size = UDim2.fromScale(1, 1)
        u.hpNum = mkLabel(root, 7, Enum.TextXAlignment.Right)
        u.hpNum.AnchorPoint = Vector2.new(1, 0)
        u.hpNum.Position = UDim2.new(0, -HP_GAP - HP_W - 3, 0, 0)
        u.hpNum.Visible = false
        local head = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
        head.AnchorPoint = Vector2.new(0.5, 1)
        head.Position = UDim2.new(0.5, 0, 0, -PAD)
        head.Visible = false
        u.head = head
        u.name = mkLabel(head, 8)
        u.name.LayoutOrder = 1
        u.under = mkFrame(head, 8)
        u.under.LayoutOrder = 2
        u.under.BackgroundTransparency = 0
        u.under.BackgroundColor3 = WHITE
        u.under.Size = UDim2.fromOffset(0, 2)
        u.under.Visible = false
        local foot = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
        foot.AnchorPoint = Vector2.new(0.5, 0)
        foot.Position = UDim2.new(0.5, 0, 1, PAD)
        foot.Visible = false
        u.foot = foot
        u.info = mkLabel(foot, 8)
        u.info.LayoutOrder = 1
        u.info.Visible = false
        local ammo = mkFrame(foot, 8)
        ammo.LayoutOrder = 2
        ammo.BackgroundTransparency = 0
        ammo.BackgroundColor3 = HPBG
        ammo.Size = UDim2.fromOffset(28, 3)
        local as = Instance.new("UIStroke")
        as.Color = INK; as.Thickness = 1; as.Transparency = 0
        as.LineJoinMode = Enum.LineJoinMode.Miter
        as.Parent = ammo
        ammo.Visible = false
        u.ammo = ammo
        u.ammoFill = mkFrame(ammo, 9)
        u.ammoFill.BackgroundTransparency = 0
        u.ammoFill.BackgroundColor3 = WHITE
        u.ammoFill.Size = UDim2.fromScale(1, 1)
        local flags = mkList(root, 7, 3, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
        flags.AnchorPoint = Vector2.new(0, 0)
        flags.Position = UDim2.new(1, FLAG_GAP, 0, 0)
        flags.Visible = false
        u.flags = flags
        u.chips = {}
        for i = 1, 5 do
            local c = mkLabel(flags, 8, Enum.TextXAlignment.Left)
            c.LayoutOrder = i
            c.Visible = false
            u.chips[i] = c
        end
        u.chev = mkLabel(root, 9)
        u.chev.AnchorPoint = Vector2.new(0.5, 1)
        u.chev.Text = GLYPH_TRI
        u.chev.Visible = false
        u.pulse = mkFrame(root, 1)
        u.pulse.AnchorPoint = Vector2.new(0.5, 0.5)
        u.pulse.Position = UDim2.fromScale(0.5, 0.5)
        local ps = Instance.new("UIStroke")
        ps.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        ps.LineJoinMode = Enum.LineJoinMode.Miter
        ps.Thickness = 2; ps.Color = WHITE
        ps.Parent = u.pulse
        u.pulseStroke = ps
        u.pulse.Visible = false
        local a = _absLayer
        u.skel = {}
        u.tracer  = mkFrame(a, 2); u.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        u.tracer.BackgroundTransparency = 0; u.tracer.BackgroundColor3 = WHITE; u.tracer.Visible = false
        u.look    = mkFrame(a, 2); u.look.AnchorPoint = Vector2.new(0.5, 0.5)
        u.look.BackgroundTransparency = 0; u.look.BackgroundColor3 = WHITE; u.look.Visible = false
        u.dot     = mkFrame(a, 3); u.dot.AnchorPoint = Vector2.new(0.5, 0.5)
        u.dot.BackgroundTransparency = 0; u.dot.BackgroundColor3 = WHITE; u.dot.Visible = false
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = u.dot
        local ds = Instance.new("UIStroke"); ds.Color = INK; ds.Thickness = 1; ds.Parent = u.dot
        return u
    end
    function destroyTree(o)
        local u = o.ui; if not u then return end
        pcall(function() if u.root then u.root:Destroy() end end)
        pcall(function() if u.tracer then u.tracer:Destroy() end end)
        pcall(function() if u.look then u.look:Destroy() end end)
        pcall(function() if u.dot then u.dot:Destroy() end end)
        if u.skel then
            for i = 1, #u.skel do pcall(function() u.skel[i]:Destroy() end) end
        end
        o.ui = nil
    end
    local _createBudget = 0
    local CREATE_BUDGET_PER_FRAME = 6 -- OPT lag
    function newDraw(t)
        if not hasDrawing then return nil end
        local ok, d = pcall(screenDraw, t)
        if not ok then return nil end
        d.Visible = false; return d
    end
    function nd(o, key, dtype)
        local d = o[key]
        if d == nil then
            if _createBudget <= 0 then return nil end
            _createBudget = _createBudget - 1
            d = newDraw(dtype) or false
            o[key] = d
            if d then o.drawings[#o.drawings + 1] = d end
        end
        return d or nil
    end
    function ndArr(o, key, dtype, n)
        local arr = o[key]
        if not arr then arr = {}; o[key] = arr end
        for i = #arr + 1, n do
            if _createBudget <= 0 then break end
            local d = newDraw(dtype)
            if not d then break end
            _createBudget = _createBudget - 1
            arr[i] = d
            o.drawings[#o.drawings + 1] = d
        end
        return arr
    end
    function ensureCham(o, char)
        local hl = o.cham
        if hl == nil then
            hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled   = false
            hl.Parent    = char
            o.cham = hl
        elseif hl and hl.Parent ~= char then
            pcall(function() hl.Parent = char end)
        end
        return o.cham
    end
    function cleanESP(p)
        local o = State.ESPObjects[p]; if not o then return end
        destroyTree(o)
        for _, d in ipairs(o.drawings or {}) do
            pcall(function() if d.Remove then d:Remove() end end)
        end
        if o.cham and o.cham.Parent then pcall(function() o.cham:Destroy() end) end
        _bboxCache[p]  = nil
        _bboxFrameN[p] = nil
        State.ESPObjects[p] = nil
    end
    function buildESP(player)
        if player == lp then return end
        cleanESP(player)
        local char = player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local isR6 = (hum and hum.RigType == Enum.HumanoidRigType.R6) or (char:FindFirstChild("Torso") ~= nil)
        local rig  = isR6 and SKEL_R6 or SKEL_R15
        local bones = {}
        for i, pair in ipairs(rig) do
            bones[i] = { a = char:FindFirstChild(pair[1]), b = char:FindFirstChild(pair[2]) }
        end
        local o = { drawings = {}, root = root, rig = rig, bones = bones, _fadeT = tick() }
        o.ui = buildTree(o)
        State.ESPObjects[player] = o
    end
    function bbox(char, player)
        local frame = _bboxFrameN[player] or -999
        if (_espFrame - frame) < 1 then
            local c = _bboxCache[player]
            if c then return c[1], c[2], c[3], c[4] end
            return nil
        end
        _bboxFrameN[player] = _espFrame
        _bboxCache[player] = nil
        local ok, pivot = pcall(function() return char:GetPivot().Position end)
        if not ok or pivot == nil then return nil end
        local sp = cam:WorldToViewportPoint(pivot)
        local depth = sp.Z
        if depth <= 0.5 then return nil end
        local vpY = _ctx.vp and _ctx.vp.Y or 1080
        local tanHalf = math.tan(math.rad(cam.FieldOfView) * 0.5)
        if tanHalf <= 0 then return nil end
        local scale = vpY / (2 * depth * tanHalf)
        local bs = Config.ESPBoxScale or 1
        local rawW = BOX_W_STUDS * scale * bs
        local rawH = BOX_H_STUDS * scale * bs
        if rawH > 4000 or rawW > 3000 then return nil end
        local x = math.floor(sp.X - rawW * 0.5)
        local y = math.floor(sp.Y - rawH * 0.5)
        local bw = math.floor(math.max(MIN_W, rawW))
        local bh = math.floor(math.max(MIN_H, rawH))
        _bboxCache[player] = { x, y, x + bw, y + bh }
        return x, y, x + bw, y + bh
    end
    function hideTree(o)
        local u = o.ui; if not u then return end
        if u.root then u.root.Visible = false end
        if u.tracer then u.tracer.Visible = false end
        if u.look then u.look.Visible = false end
        if u.dot then u.dot.Visible = false end
        if u.skel then for i = 1, #u.skel do u.skel[i].Visible = false end end
    end
    function hideDrawings(o)
        for _, d in ipairs(o.drawings) do d.Visible = false end
    end
    function hideAll(o, force)
        if o._allHidden and not force then return end
        o._allHidden = true
        hideTree(o)
        hideDrawings(o)
        if o.cham then o.cham.Enabled = false end
    end
    function ESP.rebuildAll()
        for p in pairs(State.ESPObjects) do cleanESP(p) end
        if not Config.ESP then return end
        for _, p in ipairs(getSafePlayers()) do
            if p ~= lp and p.Character then buildESP(p) end
        end
    end
    function ESP.registerFace(name, font)
        if type(name) == "string" and font ~= nil then _customFaces[name] = font end
    end
    function espWeapon(o, player)
        local now = tick()
        if not o._wepT or (now - o._wepT) > 0.5 then
            o._wep  = getWeaponName(player)
            o._wepT = now
        end
        return o._wep or "?"
    end
    function paintBox(u, ctx)
        local mode = Config.ESPBoxColorMode or "Solid"
        paint(u.boxStroke, "Color", "box", mode, Config.ESPBoxColor, Config.ESPBoxGradA, Config.ESPBoxGradB,
              Config.ESPGradientRotBox or 0, Config.ESPGradientSpeed, ctx.now)
        local ct = math.floor(math.clamp(Config.ESPCasingThickness or 2, 1, 4))
        local bt = math.floor(math.clamp(Config.ESPBoxThickness or 2, 1, 5))
        if ctx.primary and Config.ESPPrimaryEmphasis then bt = bt + 1 end
        if u.caseOut then
            u.caseOut.Thickness = ct
            u.caseOut.Color = Color3.fromRGB(0, 0, 0)
        end
        if u.caseIn then
            u.caseIn.Thickness = ct
            u.caseIn.Color = Color3.fromRGB(0, 0, 0)
        end
        if u.boxStroke.Thickness ~= bt then u.boxStroke.Thickness = bt end
        local sOut = UDim2.fromScale(1, 1)
        local sMid = UDim2.new(1, -2 * bt, 1, -2 * bt)
        local sIn  = UDim2.new(1, -2 * bt - 2 * ct, 1, -2 * bt - 2 * ct)
        if u.ringOut.Size ~= sOut then u.ringOut.Size = sOut end
        if u.ringMid.Size ~= sMid then u.ringMid.Size = sMid end
        if u.ringIn.Size  ~= sIn  then u.ringIn.Size  = sIn  end
        local tr = math.clamp((Config.ESPBoxTransparency or 0) + (1 - (ctx.fade or 1)), 0, 1)
        if u.boxStroke.Transparency ~= tr then u.boxStroke.Transparency = tr end
        if u.caseOut.Transparency ~= tr then u.caseOut.Transparency = tr end
        if u.caseIn.Transparency  ~= tr then u.caseIn.Transparency  = tr end
    end
    function drawCorners(u, w, h, ctx)
        local len = math.floor(math.clamp(w * (Config.ESPCornerLength or 0.28), 4, math.max(w * 0.48, 6)))
        local th  = math.max(math.floor(Config.ESPBoxThickness or 1), 1)
        local col = Config.ESPBoxColor or WHITE
        local mode = Config.ESPBoxColorMode or "Solid"
        local spec = {
            { 0, 0, len, th }, { 0, 0, th, len },
            { w - len, 0, len, th }, { w - th, 0, th, len },
            { 0, h - th, len, th }, { 0, h - len, th, len },
            { w - len, h - th, len, th }, { w - th, h - len, th, len },
        }
        for i = 1, 8 do
            local c = u.corners[i]
            local s = spec[i]
            c.Position = UDim2.fromOffset(s[1], s[2])
            c.Size     = UDim2.fromOffset(s[3], s[4])
            paint(c, "BackgroundColor3", "box", mode, col, Config.ESPBoxGradA, Config.ESPBoxGradB,
                  Config.ESPGradientRotBox or 0, Config.ESPGradientSpeed, ctx.now)
            local cs = c:FindFirstChildOfClass("UIStroke")
            if cs then
                cs.Color = Color3.fromRGB(0, 0, 0)
                cs.Thickness = math.max(math.floor(Config.ESPCasingThickness or 2), 1)
                cs.Transparency = 0
            end
            c.Visible = true
        end
    end
    function drawHealth(u, o, ctx, frac, hp)
        if not Config.ESPHealth then u.hp.Visible = false; u.hpNum.Visible = false; return end
        local fill = frac
        if Config.ESPHealthSmooth ~= false then
            local s = o._sHP
            if s == nil then s = frac else s = s + (frac - s) * math.clamp((ctx.dt or 0) * 14, 0, 1) end
            o._sHP = s; fill = s
        end
        fill = math.clamp(fill, 0, 1)
        u.hp.Visible = true
        u.hp.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
        u.hp.BackgroundTransparency = 0.15
        local hs = u.hp:FindFirstChildOfClass("UIStroke")
        if hs then
            hs.Color = Color3.fromRGB(0, 0, 0)
            hs.Thickness = 2
            hs.Transparency = 0
        end
        local pad = 1
        u.hpFill.Position = UDim2.new(0, pad, 1, -pad)
        u.hpFill.AnchorPoint = Vector2.new(0, 1)
        u.hpFill.Size = UDim2.new(1, -pad * 2, fill, -pad)
        local col
        if fill > 0.6 then
            local t = (fill - 0.6) / 0.4
            col = Color3.fromRGB(
                math.floor(80 + (255 - 80) * (1 - t)),
                255,
                math.floor(80 * (1 - t))
            )
        elseif fill > 0.3 then
            local t = (fill - 0.3) / 0.3
            col = Color3.fromRGB(255, math.floor(200 * t + 55 * (1 - t)), 40)
        else
            local t = fill / 0.3
            col = Color3.fromRGB(255, math.floor(55 * t), 40)
        end
        if Config.ESPHealthColorMode == "Solid" then
            col = Config.ESPHealthColor or Color3.fromRGB(80, 255, 120)
        end
        u.hpFill.BackgroundColor3 = col
        u.hpFill.BackgroundTransparency = Config.ESPHealthTransparency or 0
        if Config.ESPHealthGhost and o._ghostT and o._ghostFrac and o._ghostFrac > fill
                and (ctx.now - o._ghostT) < 0.4 then
            u.hpGhost.Visible = true
            u.hpGhost.Position = UDim2.new(0, pad, 1, -pad)
            u.hpGhost.AnchorPoint = Vector2.new(0, 1)
            u.hpGhost.Size = UDim2.new(1, -pad * 2, math.clamp(o._ghostFrac, 0, 1), -pad)
            u.hpGhost.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            u.hpGhost.BackgroundTransparency = 0.4 + 0.55 * math.clamp((ctx.now - o._ghostT) / 0.4, 0, 1)
        else
            u.hpGhost.Visible = false
        end
        local nm = Config.ESPHealthNumberMode or "Always"
        local show = nm == "Always" or (nm == "OnDamage" and frac < 0.999)
        if show then
            u.hpNum.Visible = true
            u.hpNum.Text = tostring(math.floor(hp or 0))
            styleLabel(u.hpNum, ctx.face, sizeFor((ctx.tsHp or 12) + 1, ctx.dmul), ctx.casing)
            u.hpNum.TextColor3 = col
            u.hpNum.TextTransparency = 1 - (ctx.fade or 1)
            u.hpNum.Position = UDim2.new(0, -HP_GAP - HP_W - 4, math.clamp(1 - fill, 0, 1), 0)
        else
            u.hpNum.Visible = false
        end
    end
    function drawText(u, o, player, ctx, dist, frac)
        local declut = Config.ESPDeclutter and o._declutter
        if Config.ESPName and not declut then
            u.head.Visible = true
            u.name.Visible = true
            styleLabel(u.name, ctx.face, sizeFor(ctx.tsName, ctx.dmul), ctx.casing)
            u.name.Text = (Config.ESPNameMode == "Username") and player.Name or player.DisplayName
            paint(u.name, "TextColor3", "name", Config.ESPNameColorMode or "Solid", Config.ESPNameColor,
                  Config.ESPNameGradA, Config.ESPNameGradB, Config.ESPGradientRotText or 90,
                  Config.ESPGradientSpeed, ctx.now)
            u.name.TextTransparency = math.clamp((Config.ESPNameTransparency or 0) + (1 - (ctx.fade or 1)), 0, 1)
            if Config.ESPNameHealthUnderline and frac then
                local tb = u.name.TextBounds
                u.under.Visible = true
                u.under.Size = UDim2.fromOffset(math.max(math.floor((tb and tb.X or 0) * frac), 1), 2)
                u.under.BackgroundColor3 = healthColor(frac)
            else
                u.under.Visible = false
            end
        else
            u.head.Visible = false
        end
        local showInfo = (Config.ESPDistance or Config.ESPWeapon) and not declut
        local showAmmo = Config.ESPAmmoBar and not declut
        u.foot.Visible = showInfo or showAmmo
        if showInfo then
            local txt
            if Config.ESPWeapon then txt = espWeapon(o, player) end
            if Config.ESPDistance then
                local d = ("%dm"):format(dist)
                txt = txt and (txt .. " " .. GLYPH_MID .. " " .. d) or d
            end
            u.info.Visible = true
            styleLabel(u.info, ctx.face, sizeFor(ctx.tsInfo, ctx.dmul), ctx.casing)
            u.info.Text = txt or ""
            paint(u.info, "TextColor3", "info", Config.ESPInfoColorMode or "Solid", Config.ESPInfoColor,
                  Config.ESPInfoGradA, Config.ESPInfoGradB, Config.ESPGradientRotText or 90,
                  Config.ESPGradientSpeed, ctx.now)
            u.info.TextTransparency = 1 - (ctx.fade or 1)
        else
            u.info.Visible = false
        end
        if showAmmo then
            local ammo, maxAmmo = 30, 30
            pcall(function()
                local item = Rivals.Fighter and Rivals.Fighter:Get(player)
                local eq = item and (item.EquippedItem or (item.GetEquippedItem and item:GetEquippedItem()))
                if eq and eq.Data then
                    ammo = eq.Data.Ammo or 30
                    maxAmmo = eq.Data.MaxAmmo or 30
                end
            end)
            local pct = math.clamp(maxAmmo > 0 and (ammo / maxAmmo) or 1, 0, 1)
            u.ammo.Visible = true
            u.ammo.Size = UDim2.fromOffset(math.max(math.floor(ctx.boxW * 0.9), 12), 3)
            u.ammoFill.Size = UDim2.new(pct, 0, 1, 0)
            paint(u.ammoFill, "BackgroundColor3", "mark", Config.ESPMarkColorMode or "Solid",
                  Config.ESPMarkColor, Config.ESPMarkGradA, Config.ESPMarkGradB, 0,
                  Config.ESPGradientSpeed, ctx.now)
        else
            u.ammo.Visible = false
        end
    end
    function drawFlags(u, o, player, ctx, char, frac)
        local n = 0
        function add(key, label)
            if n >= 5 then return end
            n = n + 1
            local c = u.chips[n]
            local mode = Config.ESPFlagColorMode or "PerFlag"
            c.Visible = true
            styleLabel(c, ctx.face, sizeFor(ctx.tsChip, ctx.dmul), ctx.casing)
            c.Text = label
            paint(c, "TextColor3", "flag", mode,
                  (mode == "PerFlag") and (FLAG_COLORS[key] or WHITE) or Config.ESPFlagColor,
                  Config.ESPFlagGradA, Config.ESPFlagGradB, Config.ESPGradientRotText or 90,
                  Config.ESPGradientSpeed, ctx.now)
            c.TextTransparency = 1 - (ctx.fade or 1)
        end
        if Config.ESPFlagStaring then
            local head = char:FindFirstChild("Head")
            local myPos = ctx.myRoot and ctx.myRoot.Position
            if head and myPos then
                local toMe = myPos - head.Position
                if toMe.Magnitude > 1 then
                    toMe = toMe.Unit
                    local look = head.CFrame.LookVector
                    if (look.X * toMe.X + look.Y * toMe.Y + look.Z * toMe.Z) > 0.965 then add("STARING", "[STARING]") end
                end
            end
        end
        if Config.ESPFlagDeflect and isDeflecting and isDeflecting(player) then add("DEFLECT", "[DEFLECT]") end
        if Config.ESPFlagShield then
            local wep = espWeapon(o, player)
            if wep and (wep:find("Shield") or wep:find("Riot")) then add("SHIELD", "[SHIELD]") end
        end
        if Config.ESPFlagInvincible and isSpawnProtected and isSpawnProtected(player) then add("INVINCIBLE", "[INVINCIBLE]") end
        if Config.ESPFlagLowHP and frac and frac <= 0.25 then add("LOW", "[LOW HP]") end
        u.flags.Visible = n > 0
        for i = n + 1, 5 do u.chips[i].Visible = false end
    end
    function segment(f, ax, ay, bx, by, thick, transp)
        local dx, dy = bx - ax, by - ay
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then f.Visible = false; return end
        f.Position = UDim2.fromOffset(math.floor((ax + bx) * 0.5), math.floor((ay + by) * 0.5))
        f.Size = UDim2.fromOffset(math.floor(len + 0.5), thick)
        f.Rotation = math.deg(math.atan2(dy, dx))
        f.BackgroundTransparency = transp or 0
        f.Visible = true
    end
    function drawSkeleton(u, o, ctx)
        if not Config.ESPSkeleton then
            if u.skel then for i = 1, #u.skel do u.skel[i].Visible = false end end
            return
        end
        local nb = #o.bones
        for i = #u.skel + 1, nb do
            local f = mkFrame(_absLayer, 2)
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.BackgroundTransparency = 0
            f.BackgroundColor3 = WHITE
            local s = Instance.new("UIStroke")
            s.Color = INK; s.Thickness = 1; s.Transparency = 0
            s.Parent = f
            f.Visible = false
            u.skel[i] = f
        end
        if (not o._skelPts) or (_espFrame - (o._skelFrame or -9)) >= 4 then
            o._skelFrame = _espFrame
            local pts = o._skelPts; if not pts then pts = {}; o._skelPts = pts end
            for i, pair in ipairs(o.bones) do
                local pa, pb = pair.a, pair.b
                local e = pts[i]; if not e then e = {}; pts[i] = e end
                if pa and pb and pa.Parent and pb.Parent then
                    local s1, v1 = cam:WorldToViewportPoint(pa.Position)
                    local s2, v2 = cam:WorldToViewportPoint(pb.Position)
                    if v1 and v2 and s1.Z > 0 and s2.Z > 0 then
                        e.ok = true; e.ax = s1.X; e.ay = s1.Y; e.bx = s2.X; e.by = s2.Y
                    else e.ok = false end
                else e.ok = false end
            end
        end
        local th = math.max(math.floor(Config.ESPSkeletonThickness or 1), 1)
        local mode = Config.ESPSkeletonColorMode or "Solid"
        local pts = o._skelPts
        for i = 1, nb do
            local f = u.skel[i]
            local e = pts and pts[i]
            if f then
                if e and e.ok then
                    segment(f, e.ax, e.ay, e.bx, e.by, th, Config.ESPSkeletonTransparency or 0)
                    paint(f, "BackgroundColor3", "skel", mode, Config.ESPSkeletonColor,
                          Config.ESPSkeletonGradA, Config.ESPSkeletonGradB, 0, Config.ESPGradientSpeed, ctx.now)
                else f.Visible = false end
            end
        end
    end
    function drawAbsExtras(u, o, ctx, char, minX, minY, maxX, maxY)
        if Config.ESPTracers then
            local vp = ctx.vp
            local ox, oy = vp.X * 0.5, vp.Y
            local m = Config.ESPTracerOrigin
            if m == "Top" then oy = 0
            elseif m == "Middle" then oy = vp.Y * 0.5
            elseif m == "Mouse" then
                local mp; pcall(function() mp = UserInputService:GetMouseLocation() end)
                if mp then ox, oy = mp.X, mp.Y end
            end
            segment(u.tracer, ox, oy, (minX + maxX) * 0.5, maxY,
                    math.max(math.floor(Config.ESPTracerThickness or 1), 1), Config.ESPTracerTransparency or 0)
            paint(u.tracer, "BackgroundColor3", "tracer", Config.ESPTracerColorMode or "Solid",
                  Config.ESPTracerColor, Config.ESPTracerGradA, Config.ESPTracerGradB, 0,
                  Config.ESPGradientSpeed, ctx.now)
        else u.tracer.Visible = false end
        if Config.ESPHeadDot then
            local head = char:FindFirstChild("Head")
            local ok = false
            if head then
                local hsp, inv = cam:WorldToViewportPoint(head.Position)
                if inv and hsp.Z > 0 then
                    local r = math.clamp(Config.ESPHeadDotSize or 4, 2, 16)
                    u.dot.Position = UDim2.fromOffset(math.floor(hsp.X), math.floor(hsp.Y))
                    u.dot.Size = UDim2.fromOffset(r * 2, r * 2)
                    paint(u.dot, "BackgroundColor3", "mark", Config.ESPMarkColorMode or "Solid",
                          Config.ESPMarkColor, Config.ESPMarkGradA, Config.ESPMarkGradB, 0,
                          Config.ESPGradientSpeed, ctx.now)
                    u.dot.Visible = true; ok = true
                end
            end
            if not ok then u.dot.Visible = false end
        else u.dot.Visible = false end
        if Config.ESPLookLine then
            local head = char:FindFirstChild("Head")
            local ok = false
            if head then
                local look = head.CFrame.LookVector
                local p1 = head.Position
                local p2 = p1 + look * math.clamp(Config.ESPLookLineLength or 8, 2, 32)
                local s1, v1 = cam:WorldToViewportPoint(p1)
                local s2, v2 = cam:WorldToViewportPoint(p2)
                if v1 and v2 and s1.Z > 0 and s2.Z > 0 then
                    segment(u.look, s1.X, s1.Y, s2.X, s2.Y, 1, 0)
                    paint(u.look, "BackgroundColor3", "mark", Config.ESPMarkColorMode or "Solid",
                          Config.ESPMarkColor, Config.ESPMarkGradA, Config.ESPMarkGradB, 0,
                          Config.ESPGradientSpeed, ctx.now)
                    ok = true
                end
            end
            if not ok then u.look.Visible = false end
        else u.look.Visible = false end
    end
    function renderPlayer(player, o)
        local ctx  = _ctx
        local char = player.Character
        if not char or not o.root or not o.root.Parent then cleanESP(player); return end
        if not o.root:IsA("BasePart") then cleanESP(player); return end
        local rootPos = o.root.Position
        if not rootPos then cleanESP(player); return end
        if not o.ui then o.ui = buildTree(o); if not o.ui then return end end
        local u = o.ui
        local vp     = ctx.vp
        local myRoot = ctx.myRoot
        local dist   = o._dist
        if not dist then
            dist = (myRoot and myRoot.Position and rootPos)
                and (myRoot.Position - rootPos).Magnitude or 0
        end
        local oor = dist > Config.ESPMaxDistance
        if (Config.ESPTeamCheck and isTeammate(player)) or (not isAlive(player)) then
            hideAll(o); return
        end
        if (Config.ESPRadar or Config.ESPChamsVisSpli
-- ===================== FIN DE LO VISIBLE (PARTE 2) =====================
-- ======================================================================
--  PARTE 3/3  ·  BUILD LEGIT  ·  cierre del ESP + loop + UI
--  (continúa dentro del IIFE del ESP abierto en la PARTE 2)
-- ======================================================================

        -- visibilidad / fade
        local vis = true
        if Config.ESPVisibleCheck or Config.ESPVisibleOnly then
            vis = isVisible(rootPos)
        end
        if Config.ESPVisibleOnly and not vis then hideAll(o); return end

        local fade = 1
        if Config.ESPFade ~= false then
            fade = math.clamp((tick() - (o._fadeT or 0)) / 0.22, 0, 1)
        end
        o._allHidden = false

        local minX, minY, maxX, maxY = bbox(char, player)
        if not minX then hideAll(o); return end
        local bw = math.max(maxX - minX, 1)
        local bh = math.max(maxY - minY, 1)

        local hp, maxHp = getHealth(player)
        local frac = (maxHp > 0) and math.clamp(hp / maxHp, 0, 1) or 0
        if o._lastFrac and frac < o._lastFrac - 0.001 then
            o._ghostT = tick(); o._ghostFrac = o._lastFrac
        end
        o._lastFrac = frac

        ctx.now    = tick()
        ctx.dt     = ctx.dt or (1 / 60)
        ctx.vp     = vp
        ctx.myRoot = myRoot
        ctx.boxW   = bw
        ctx.boxH   = bh
        ctx.fade   = fade
        ctx.primary = (State.PrimaryTarget == player)
        ctx.dmul   = distMul(dist)
        ctx.face   = faceFor("Gotham")
        ctx.casing = 1
        ctx.tsName, ctx.tsInfo, ctx.tsHp, ctx.tsChip = 13, 12, 12, 11

        u.root.Visible  = true
        u.root.Position = UDim2.fromOffset(minX, minY)
        u.root.Size     = UDim2.fromOffset(bw, bh)

        -- caja
        local boxOn = Config.ESPBox
        u.box.Visible = boxOn and true or false
        if boxOn then
            local style = Config.ESPBoxStyle or "Corner Brackets"
            if style == "Corner Brackets" then
                if u.boxStroke then u.boxStroke.Transparency = 1 end
                if u.caseOut then u.caseOut.Transparency = 1 end
                if u.caseIn  then u.caseIn.Transparency  = 1 end
                drawCorners(u, bw, bh, ctx)
            else
                for i = 1, 8 do u.corners[i].Visible = false end
                paintBox(u, ctx)
            end
        else
            for i = 1, 8 do u.corners[i].Visible = false end
        end

        -- relleno
        if Config.ESPBoxFill and boxOn then
            u.fill.Visible = true
            u.fill.BackgroundTransparency = 1 - math.clamp(Config.ESPBoxFillTransparency or 0.85, 0, 1)
            paint(u.fill, "BackgroundColor3", "box", Config.ESPBoxColorMode or "Solid",
                  Config.ESPBoxColor, Config.ESPBoxGradA, Config.ESPBoxGradB, 0,
                  Config.ESPGradientSpeed, ctx.now)
        else
            u.fill.Visible = false
        end

        drawHealth(u, o, ctx, frac, hp)
        drawText(u, o, player, ctx, dist, frac)
        drawFlags(u, o, player, ctx, char, frac)
        drawSkeleton(u, o, ctx)
        drawAbsExtras(u, o, ctx, char, minX, minY, maxX, maxY)

        -- chams
        if Config.ESPChams then
            local hl = ensureCham(o, char)
            if hl then
                hl.Enabled            = true
                hl.FillColor          = Config.ESPChamsColor or (Config.ESPBoxColor or WHITE)
                hl.OutlineColor       = Config.ESPChamsOutline or INK
                hl.FillTransparency   = Config.ESPChamsTransparency or 0.5
                hl.OutlineTransparency = 0
            end
        elseif o.cham and o.cham.Enabled then
            o.cham.Enabled = false
        end
    end -- renderPlayer

    -- ===================== LOOP DEL ESP =====================
    function espUpdate(dt)
        _espFrame += 1
        local c2 = workspace.CurrentCamera
        if c2 then Camera = c2 cam = c2 end
        if not cam then return end
        _ctx.dt = dt
        _ctx.vp = cam.ViewportSize
        local myChar = LocalPlayer.Character
        _ctx.myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        _createBudget = CREATE_BUDGET_PER_FRAME

        if not Config.ESP then
            for _, o in pairs(State.ESPObjects) do hideAll(o) end
            if _espFrame % 40 == 0 then
                for p in pairs(State.ESPObjects) do cleanESP(p) end
            end
            return
        end

        -- asegurar árboles
        for _, p in ipairs(getSafePlayers()) do
            if p ~= LocalPlayer and p.Character then
                local o = State.ESPObjects[p]
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if not o or not o.root or o.root.Parent ~= root then buildESP(p) end
            end
        end
        for p in pairs(State.ESPObjects) do
            if not p.Character then cleanESP(p) end
        end

        -- objetivo primario (más cercano) para énfasis
        State.PrimaryTarget = nil
        local bestD
        local mr = _ctx.myRoot
        if mr then
            for _, p in ipairs(getSafePlayers()) do
                local o = State.ESPObjects[p]
                if o and o.root and o.root.Parent then
                    local d = (mr.Position - o.root.Position).Magnitude
                    if not bestD or d < bestD then bestD = d State.PrimaryTarget = p end
                end
            end
        end

        for _, p in ipairs(getSafePlayers()) do
            local o = State.ESPObjects[p]
            if o then pcall(renderPlayer, p, o) end
        end
    end

    local _espAcc = 0
    _renderConn = RunService.Heartbeat:Connect(function(dt)
        local interval = tonumber(Config.ESPUpdateInterval) or 0
        if interval <= 0 or not Config.ESPPerfMode then
            espUpdate(dt)
        else
            _espAcc += dt
            if _espAcc >= interval then
                local step = _espAcc
                _espAcc = 0
                espUpdate(step)
            end
        end
    end)

    -- hooks de jugadores
    local function hookChar(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.2)
            if Config.ESP then buildESP(p) end
        end)
    end
    Players.PlayerAdded:Connect(hookChar)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then hookChar(p) end
    end
    Players.PlayerRemoving:Connect(cleanESP)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        for p in pairs(State.ESPObjects) do cleanESP(p) end
    end)

    getgenv()._ShakoESP = ESP          -- export para la UI
    ESP.rebuildAll()
end)() -- cierre IIFE ESP

-- ======================================================================
--  UI  ·  solo Aimbot / ESP / World / Settings
-- ======================================================================
local TabAimbot = Window:AddTab("Aimbot")
local TabESP    = Window:AddTab("ESP")
local TabWorld  = Window:AddTab("World")
local TabSet    = Window:AddTab("Settings")

-- ==================== AIMBOT ====================
do
    local gb = TabAimbot:AddLeftGroupbox("Aimbot")
    gb:AddToggle("AimbotEnabled", {
        Text = "Aimbot", Default = config.AimbotEnabled,
        Callback = function(v)
            config.AimbotEnabled = v
            if v then StartAimbot() else StopAimbot() end
        end,
    })
    gb:AddDropdown("AimbotKeyMode", {
        Text = "Modo", Values = { "Hold", "Toggle", "Always" },
        Default = config.AimbotKeyMode or "Hold",
        Callback = function(v) config.AimbotKeyMode = v end,
    })
    gb:AddKeybind("AimbotKey", {
        Text = "Tecla aim", Default = Enum.KeyCode.E,
        Callback = function() end,
    })
    gb:AddSlider("AimbotFOV", {
        Text = "FOV", Min = 20, Max = 800, Default = config.AimbotFOV or 400, Rounding = 0,
        Callback = function(v) config.AimbotFOV = v end,
    })
    gb:AddSlider("AimbotSmooth", {
        Text = "Smooth", Min = 0.05, Max = 1, Default = config.AimbotSmooth or 0.9, Rounding = 2,
        Callback = function(v) config.AimbotSmooth = v end,
    })
    gb:AddDropdown("AimbotPart", {
        Text = "Parte", Values = { "Head", "UpperTorso", "HumanoidRootPart" },
        Default = config.AimbotPart or "Head",
        Callback = function(v) config.AimbotPart = v end,
    })
    gb:AddToggle("AimbotTeamCheck", {
        Text = "Ignorar equipo", Default = config.AimbotTeamCheck ~= false,
        Callback = function(v) config.AimbotTeamCheck = v end,
    })
    gb:AddToggle("AimbotWallCheck", {
        Text = "Chequeo de pared", Default = config.AimbotWallCheck,
        Callback = function(v) config.AimbotWallCheck = v end,
    })
    gb:AddToggle("AimbotShowFOV", {
        Text = "Mostrar FOV", Default = config.AimbotShowFOV ~= false,
        Callback = function(v) config.AimbotShowFOV = v end,
    })

    local gb2 = TabAimbot:AddRightGroupbox("Silent Aim")
    gb2:AddToggle("SilentAimEnabled", {
        Text = "Silent Aim", Default = false,
        Callback = function(v)
            if v then StartSilentAim() else StopSilentAim() end
        end,
    })
    gb2:AddSlider("SilentFOV", {
        Text = "FOV", Min = 20, Max = 1000, Default = config.SilentFOV or 300, Rounding = 0,
        Callback = function(v) config.SilentFOV = v end,
    })
    gb2:AddDropdown("SilentHitPart", {
        Text = "Hit part", Values = { "Head", "Torso", "HitboxHead" }, Default = "Head",
        Callback = function(v) config.SilentHitPart = v end,
    })
    gb2:AddToggle("SilentPredict", {
        Text = "Predicción", Default = false,
        Callback = function(v) config.SilentPredict = v end,
    })
    gb2:AddToggle("SilentTeamCheck", {
        Text = "Ignorar equipo", Default = true,
        Callback = function(v) config.SilentTeamCheck = v end,
    })
    gb2:AddToggle("ExtendMeleeRange", {
        Text = "Extender melee", Default = false,
        Callback = function(v) config.ExtendMeleeRange = v end,
    })
    gb2:AddToggle("SilentShowFOV", {
        Text = "Mostrar FOV", Default = true,
        Callback = function(v) config.SilentShowFOV = v end,
    })
end

-- ==================== ESP ====================
do
    local gb = TabESP:AddLeftGroupbox("ESP")
    gb:AddToggle("ESPEnabled", {
        Text = "ESP", Default = config.ESPEnabled,
        Callback = function(v)
            config.ESPEnabled = v
            config.ESP = v
            local e = getgenv()._ShakoESP
            if e and e.rebuildAll then pcall(e.rebuildAll) end
        end,
    })
    gb:AddToggle("ESPBox", { Text = "Caja", Default = true, Callback = function(v) config.ESPShowBox = v end })
    gb:AddDropdown("ESPBoxStyle", {
        Text = "Estilo caja", Values = { "Corner Brackets", "Full Box" }, Default = "Corner Brackets",
        Callback = function(v) config.ESPBoxStyle = v end,
    })
    gb:AddToggle("ESPName", { Text = "Nombre", Default = true, Callback = function(v) config.ESPShowName = v end })
    gb:AddToggle("ESPDistance", { Text = "Distancia", Default = true, Callback = function(v) config.ESPShowDist = v end })
    gb:AddToggle("ESPHealthBar", { Text = "Barra de vida", Default = true, Callback = function(v) config.ESPShowHP = v end })
    gb:AddToggle("ESPHealthNumber", { Text = "Número de vida", Default = false, Callback = function(v) config.ESPHealthNumberMode = v and "Always" or "Off" end })
    gb:AddToggle("ESPSkeleton", { Text = "Esqueleto", Default = false, Callback = function(v) config.ESPSkeleton = v end })
    gb:AddToggle("ESPTracers", { Text = "Tracers", Default = false, Callback = function(v) config.ESPTracers = v end })
    gb:AddToggle("ESPHeadDot", { Text = "Punto en la cabeza", Default = false, Callback = function(v) config.ESPHeadDot = v end })
    gb:AddToggle("ESPChams", { Text = "Chams", Default = false, Callback = function(v) config.ESPChams = v end })

    local gb2 = TabESP:AddRightGroupbox("Ajustes ESP")
    gb2:AddSlider("ESPMaxDistance", {
        Text = "Distancia máx", Min = 50, Max = 5000, Default = 100000 and 1500 or 1500, Rounding = 0,
        Callback = function(v) config.ESPMaxDistance = v end,
    })
    gb2:AddToggle("ESPTeamCheck", { Text = "Ignorar equipo", Default = false, Callback = function(v) config.ESPTeamCheck = v end })
    gb2:AddToggle("ESPPerfMode", { Text = "Modo rendimiento", Default = true, Callback = function(v) config.ESPPerfMode = v end })
    gb2:AddSlider("ESPUpdateInterval", {
        Text = "Intervalo update", Min = 0.02, Max = 0.2, Default = 0.05, Rounding = 2,
        Callback = function(v) config.ESPUpdateInterval = v end,
    })
    gb2:AddSlider("ESPBoxThickness", {
        Text = "Grosor caja", Min = 1, Max = 4, Default = 2, Rounding = 0,
        Callback = function(v) config.ESPBoxThickness = v end,
    })
    gb2:AddToggle("ESPVisibleCheck", { Text = "Chequeo de visibilidad", Default = false, Callback = function(v) config.ESPVisibleCheck = v end })
end

-- ==================== WORLD ====================
do
    local gb = TabWorld:AddLeftGroupbox("Mundo")
    gb:AddToggle("Fullbright", {
        Text = "Fullbright", Default = false,
        Callback = function(v) config.Fullbright = v ApplyVisuals() end,
    })
    gb:AddToggle("NoFog", {
        Text = "Sin niebla", Default = true,
        Callback = function(v) config.NoFog = v ApplyVisuals() end,
    })
    gb:AddToggle("WallXray", {
        Text = "Ver a través de paredes", Default = false,
        Callback = function(v) config.WallXray = v ApplyVisuals() end,
    })
    gb:AddToggle("MapColorEnabled", {
        Text = "Colorear mapa", Default = false,
        Callback = function(v) config.MapColorEnabled = v ApplyVisuals() end,
    })
    gb:AddToggle("RemoveTextures", {
        Text = "Quitar texturas", Default = false,
        Callback = function(v) config.RemoveTextures = v ApplyVisuals() end,
    })
    gb:AddSlider("Brightness", {
        Text = "Brillo", Min = 0, Max = 5, Default = 2, Rounding = 1,
        Callback = function(v) config.Brightness = v config.LightingOverride = true ApplyVisuals() end,
    })
    gb:AddButton("Reset visuales", function() ResetVisuals() end)

    local gb2 = TabWorld:AddRightGroupbox("Color de mapa")
    gb2:AddSlider("MapColorR", { Text = "R", Min = 0, Max = 255, Default = 80, Rounding = 0, Callback = function(v) config.MapColorR = v ApplyVisuals() end })
    gb2:AddSlider("MapColorG", { Text = "G", Min = 0, Max = 255, Default = 80, Rounding = 0, Callback = function(v) config.MapColorG = v ApplyVisuals() end })
    gb2:AddSlider("MapColorB", { Text = "B", Min = 0, Max = 255, Default = 100, Rounding = 0, Callback = function(v) config.MapColorB = v ApplyVisuals() end })
    gb2:AddSlider("WallTransparency", {
        Text = "Transparencia pared", Min = 0, Max = 0.95, Default = 0.55, Rounding = 2,
        Callback = function(v) config.WallTransparency = v ApplyVisuals() end,
    })
end

-- ==================== SETTINGS ====================
do
    local gb = TabSet:AddLeftGroupbox("Ajustes")
    gb:AddKeybind("MenuKey", {
        Text = "Tecla del menú", Default = Enum.KeyCode.RightShift,
        Callback = function(v)
            local name = (typeof(v) == "EnumItem") and v.Name or tostring(v)
            config.MenuKey = name
            pcall(function() Library.ToggleKeybind = name end)
        end,
    })
    gb:AddButton("Guardar config", function()
        pcall(function() SaveManager:Save("legit") end)
        Notify("Config", "guardado")
    end)
    gb:AddButton("Cargar config", function()
        pcall(function() SaveManager:Load("legit") end)
        Notify("Config", "cargado")
    end)

    local gb2 = TabSet:AddRightGroupbox("Info")
    gb2:AddLabel("shako.win · LEGIT")
    gb2:AddLabel("solo aimbot + esp")
end

-- ======================================================================
--  BOOT FINAL
-- ======================================================================
pcall(ApplyVisuals)
getgenv()._ShakoUIReady = true

task.spawn(function()
    task.wait(0.5)
    if SaveManager and SaveManager.LoadAutoloadConfig then
        pcall(function() SaveManager:LoadAutoloadConfig() end)
    end
    if config.AimbotEnabled then pcall(StartAimbot) end
    if config.ESPEnabled then
        local e = getgenv()._ShakoESP
        if e and e.rebuildAll then pcall(e.rebuildAll) end
    end
    Notify("shako", "LEGIT cargado · aimbot + esp")
end)
