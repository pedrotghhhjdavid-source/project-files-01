-- ============================================================
--  DARK MENU  –  Interfaz idéntica a la imagen (Roblox Executor)
--  Solo visual / sin cheats funcionales
-- ============================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local player       = Players.LocalPlayer

local parent = (gethui and gethui()) or player:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("DarkMenuClone")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name            = "DarkMenuClone"
gui.ResetOnSpawn    = false
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.Parent          = parent

-- ── Paleta ──────────────────────────────────────────────────
local C = {
    bg        = Color3.fromRGB( 12, 12, 12),
    panel     = Color3.fromRGB( 20, 20, 20),
    panelHdr  = Color3.fromRGB( 16, 16, 16),
    border    = Color3.fromRGB( 48, 48, 48),
    accent    = Color3.fromRGB(200,  0, 200),
    accentDim = Color3.fromRGB(120,  0, 120),
    txt       = Color3.fromRGB(200, 200, 200),
    txtDim    = Color3.fromRGB(110, 110, 110),
    txtBright = Color3.fromRGB(230, 230, 230),
    chkOff    = Color3.fromRGB( 60,  60,  60),
    btnBg     = Color3.fromRGB( 38,  38,  38),
    btnBdr    = Color3.fromRGB( 65,  65,  65),
    sliderTrk = Color3.fromRGB( 60,  60,  60),
    sideBg    = Color3.fromRGB( 10, 10, 10),
    sideAct   = Color3.fromRGB( 28, 28, 28),
    iconOff   = Color3.fromRGB( 80,  80,  80),
    iconOn    = Color3.fromRGB(180, 180, 180),
    ddBg      = Color3.fromRGB( 42,  42,  42),
    ddBdr     = Color3.fromRGB( 70,  70,  70),
}

-- ── Helpers ────────────────────────────────────────────────
local function n(class, props, par)
    local o = Instance.new(class)
    for k,v in pairs(props) do o[k]=v end
    o.Parent = par
    return o
end

local function stroke(obj, col, thick)
    return n("UIStroke",{Color=col or C.border,Thickness=thick or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},obj)
end

local function corner(obj, r)
    return n("UICorner",{CornerRadius=UDim.new(0,r or 4)},obj)
end

local order = 0
local function ord() order = order + 1; return order end

-- ── Ventana principal ───────────────────────────────────────
local win = n("Frame",{
    Name="Win",
    Size=UDim2.fromOffset(660,560),
    Position=UDim2.new(0.5,-330,0.5,-280),
    BackgroundColor3=C.bg,
    BorderSizePixel=0,
    Active=true,
},gui)
stroke(win, C.border, 1)

-- Línea superior (gradient magenta)
local topLine = n("Frame",{
    Size=UDim2.new(1,0,0,2),
    Position=UDim2.fromOffset(0,0),
    BackgroundColor3=C.accent,
    BorderSizePixel=0,
},win)
n("UIGradient",{
    Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.accent),
        ColorSequenceKeypoint.new(0.5, C.accentDim),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(40,0,40)),
    }),
},topLine)

-- Barra de título
local titleBar = n("TextLabel",{
    Size=UDim2.new(1,0,0,22),
    Position=UDim2.fromOffset(0,2),
    BackgroundColor3=C.panelHdr,
    BorderSizePixel=0,
    Text="  DARK MENU",
    TextColor3=Color3.fromRGB(140,140,140),
    TextSize=11,
    Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
    Active=true,
},win)

local btnClose = n("TextButton",{
    Size=UDim2.fromOffset(28,22),
    Position=UDim2.new(1,-28,0,0),
    BackgroundTransparency=1,
    Text="×",
    TextColor3=C.txt,
    TextSize=18,
    Font=Enum.Font.Code,
},titleBar)
btnClose.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Drag
local drag, dStart, sPos = false, nil, nil
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or  inp.UserInputType==Enum.UserInputType.Touch then
        drag=true; dStart=inp.Position; sPos=win.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement
    or  inp.UserInputType==Enum.UserInputType.Touch) then
        local d = inp.Position - dStart
        win.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset+d.X,
                                 sPos.Y.Scale, sPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or  inp.UserInputType==Enum.UserInputType.Touch then drag=false end
end)

-- ── SIDEBAR ─────────────────────────────────────────────────
local side = n("Frame",{
    Position=UDim2.fromOffset(3,28),
    Size=UDim2.new(0,72,1,-34),
    BackgroundColor3=C.sideBg,
    BorderSizePixel=0,
},win)
stroke(side, C.border, 1)

-- ── Dibujo de iconos con formas ─────────────────────────────
local function drawIcon(container, type, active)
    local col = active and C.iconOn or C.iconOff
    local cx = 36  -- centro x del sidebar (72/2)
    local cy = 36  -- centro y del botón (72/2)

    if type == "headshot" then
        -- Cabeza
        local head = n("Frame",{
            Size=UDim2.fromOffset(16,16),
            Position=UDim2.fromOffset(cx-8, cy-14),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        corner(head, 8)
        -- Cuerpo
        n("Frame",{
            Size=UDim2.fromOffset(12,10),
            Position=UDim2.fromOffset(cx-6, cy+2),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        -- Destello (2 líneas cortas)
        local s1 = n("Frame",{
            Size=UDim2.fromOffset(6,2),
            Position=UDim2.fromOffset(cx+8, cy-16),
            BackgroundColor3=col, BorderSizePixel=0,
            Rotation=-30,
        },container)
        local s2 = n("Frame",{
            Size=UDim2.fromOffset(4,2),
            Position=UDim2.fromOffset(cx+12, cy-10),
            BackgroundColor3=col, BorderSizePixel=0,
            Rotation=-30,
        },container)
        local s3 = n("Frame",{
            Size=UDim2.fromOffset(5,2),
            Position=UDim2.fromOffset(cx+4, cy-20),
            BackgroundColor3=col, BorderSizePixel=0,
            Rotation=30,
        },container)

    elseif type == "antiaim" then
        -- Cabeza
        local head = n("Frame",{
            Size=UDim2.fromOffset(14,14),
            Position=UDim2.fromOffset(cx-7, cy-13),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        corner(head, 7)
        -- Cuerpo
        n("Frame",{
            Size=UDim2.fromOffset(10,12),
            Position=UDim2.fromOffset(cx-5, cy+1),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        -- Línea diagonal (arma / X)
        local diag = n("Frame",{
            Size=UDim2.fromOffset(22,2),
            Position=UDim2.fromOffset(cx-11, cy-6),
            BackgroundColor3=col, BorderSizePixel=0,
            Rotation=-45,
        },container)

    elseif type == "crosshair" then
        -- Círculo
        local circ = n("Frame",{
            Size=UDim2.fromOffset(22,22),
            Position=UDim2.fromOffset(cx-11, cy-11),
            BackgroundTransparency=1, BorderSizePixel=0,
        },container)
        corner(circ, 11)
        stroke(circ, col, 2)
        -- Cruz horizontal
        n("Frame",{
            Size=UDim2.fromOffset(22,2),
            Position=UDim2.fromOffset(cx-11, cy-1),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        -- Cruz vertical
        n("Frame",{
            Size=UDim2.fromOffset(2,22),
            Position=UDim2.fromOffset(cx-1, cy-11),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        -- Punto central
        n("Frame",{
            Size=UDim2.fromOffset(4,4),
            Position=UDim2.fromOffset(cx-2, cy-2),
            BackgroundColor3=C.bg, BorderSizePixel=0,
        },container)

    elseif type == "visuals" then
        -- Círculo
        local circ = n("Frame",{
            Size=UDim2.fromOffset(22,22),
            Position=UDim2.fromOffset(cx-11, cy-11),
            BackgroundTransparency=1, BorderSizePixel=0,
        },container)
        corner(circ, 11)
        stroke(circ, col, 2)
        -- Línea vertical que divide
        n("Frame",{
            Size=UDim2.fromOffset(2,22),
            Position=UDim2.fromOffset(cx-1, cy-11),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        -- Mitad izquierda rellena
        local half = n("Frame",{
            Size=UDim2.fromOffset(11,22),
            Position=UDim2.fromOffset(cx-11, cy-11),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        -- Recortar con corner (aproximación)
        n("UICorner",{CornerRadius=UDim.new(0,11)},half)

    elseif type == "settings" then
        -- 3 engranajes simplificados (círculos con "dientes")
        local function gear(x, y, r)
            local g = n("Frame",{
                Size=UDim2.fromOffset(r*2, r*2),
                Position=UDim2.fromOffset(x-r, y-r),
                BackgroundColor3=col, BorderSizePixel=0,
            },container)
            corner(g, r)
            -- Agujero central
            n("Frame",{
                Size=UDim2.fromOffset(math.floor(r*0.7), math.floor(r*0.7)),
                Position=UDim2.fromOffset(math.floor(r*0.15), math.floor(r*0.15)),
                BackgroundColor3=active and C.sideAct or C.sideBg,
                BorderSizePixel=0,
            },g)
            -- Dientes (4 pequeños rectángulos)
            for i=0,3 do
                local ang = i * 45
                local dx = math.floor(r * 0.85)
                local dy = 0
                if i==1 then dx=0; dy=math.floor(r*0.85)
                elseif i==2 then dx=-math.floor(r*0.85); dy=0
                elseif i==3 then dx=0; dy=-math.floor(r*0.85) end
                n("Frame",{
                    Size=UDim2.fromOffset(3,3),
                    Position=UDim2.fromOffset(math.floor(r*0.15)+dx-1, math.floor(r*0.15)+dy-1),
                    BackgroundColor3=col, BorderSizePixel=0,
                },g)
            end
        end
        gear(cx-6, cy-4, 8)
        gear(cx+8, cy+2, 7)
        gear(cx-2, cy+10, 6)

    elseif type == "trash" then
        -- Gota / símbolo curvo
        local drop = n("Frame",{
            Size=UDim2.fromOffset(16,20),
            Position=UDim2.fromOffset(cx-8, cy-12),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        n("UICorner",{CornerRadius=UDim.new(0,10)},drop)
        -- Punta de la gota
        local tip = n("Frame",{
            Size=UDim2.fromOffset(8,8),
            Position=UDim2.fromOffset(cx-4, cy-16),
            BackgroundColor3=col, BorderSizePixel=0,
            Rotation=45,
        },container)

    elseif type == "profile" then
        -- Cabeza
        local head = n("Frame",{
            Size=UDim2.fromOffset(14,14),
            Position=UDim2.fromOffset(cx-7, cy-12),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        corner(head, 7)
        -- Cuerpo (semicirculo)
        local body = n("Frame",{
            Size=UDim2.fromOffset(22,14),
            Position=UDim2.fromOffset(cx-11, cy+4),
            BackgroundColor3=col, BorderSizePixel=0,
        },container)
        n("UICorner",{CornerRadius=UDim.new(0,10)},body)
    end
end

-- Botones del sidebar
local iconTypes = {"headshot","antiaim","crosshair","visuals","settings","trash","profile"}
local activeIcon = 5  -- "settings" está activo

for i, t in ipairs(iconTypes) do
    local btn = n("TextButton",{
        Size=UDim2.new(1,0,0,72),
        Position=UDim2.fromOffset(0,(i-1)*72),
        BackgroundColor3=(i==activeIcon) and C.sideAct or C.sideBg,
        BorderSizePixel=0,
        Text="",
    },side)
    stroke(btn, C.border, 0.5)
    drawIcon(btn, t, i==activeIcon)

    btn.MouseButton1Click:Connect(function()
        for j=1,#iconTypes do
            local b = side:GetChildren()
            for _,c in ipairs(b) do
                if c:IsA("TextButton") then
                    c.BackgroundColor3 = (j==i) and C.sideAct or C.sideBg
                end
            end
        end
        activeIcon = i
    end)
end

-- ── Paneles ─────────────────────────────────────────────────
local function makePanel(name, pos, size, scroll)
    local f = n("Frame",{
        Position=pos, Size=size,
        BackgroundColor3=C.panel, BorderSizePixel=0,
    },win)
    stroke(f, C.border, 1)

    n("TextLabel",{
        Position=UDim2.fromOffset(10,-6),
        Size=UDim2.fromOffset(140,14),
        BackgroundColor3=C.panel,
        BorderSizePixel=0,
        Text=" " .. name,
        TextColor3=C.txt,
        TextSize=12,
        Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
    },f)

    local content
    if scroll then
        content = n("ScrollingFrame",{
            Position=UDim2.fromOffset(12,14),
            Size=UDim2.new(1,-24,1,-22),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            ScrollBarThickness=3,
            ScrollBarImageColor3=Color3.fromRGB(100,100,100),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            CanvasSize=UDim2.new(),
        },f)
    else
        content = n("Frame",{
            Position=UDim2.fromOffset(12,14),
            Size=UDim2.new(1,-24,1,-22),
            BackgroundTransparency=1,
            BorderSizePixel=0,
        },f)
    end

    n("UIListLayout",{
        Padding=UDim.new(0,4),
        SortOrder=Enum.SortOrder.LayoutOrder,
    },content)

    return content
end

local pMisc = makePanel("Miscellaneous",
    UDim2.fromOffset(96,28), UDim2.new(0,260,1,-34), true)

local pSet = makePanel("Settings",
    UDim2.fromOffset(378,28), UDim2.fromOffset(258,160), false)

local pOth = makePanel("Other",
    UDim2.fromOffset(378,205), UDim2.new(0,258,1,-211), false)

-- ── Widgets ─────────────────────────────────────────────────
local function addLabel(par, txt, h)
    return n("TextLabel",{
        LayoutOrder=ord(),
        Size=UDim2.new(1,-4,0,h or 16),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=C.txt,
        TextSize=12,
        Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
    },par)
end

local function addToggle(par, txt, on, hasX)
    local enabled = on or false
    local row = n("TextButton",{
        LayoutOrder=ord(),
        Size=UDim2.new(1,-4,0,17),
        BackgroundTransparency=1,
        Text="",
        AutoButtonColor=false,
    },par)

    -- Checkbox
    local box = n("Frame",{
        Position=UDim2.fromOffset(2,5),
        Size=UDim2.fromOffset(7,7),
        BackgroundColor3=enabled and C.accent or C.chkOff,
        BorderSizePixel=0,
    },row)

    n("TextLabel",{
        Position=UDim2.fromOffset(18,0),
        Size=UDim2.new(1,-(hasX and 40 or 22),1,0),
        BackgroundTransparency=1,
        Text=txt,
        TextColor3=C.txt,
        TextSize=12,
        Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
    },row)

    if hasX then
        n("TextLabel",{
            Position=UDim2.new(1,-22,0,0),
            Size=UDim2.fromOffset(20,17),
            BackgroundTransparency=1,
            Text="[x]",
            TextColor3=C.txtDim,
            TextSize=11,
            Font=Enum.Font.Code,
            TextXAlignment=Enum.TextXAlignment.Right,
        },row)
    end

    row.MouseButton1Click:Connect(function()
        enabled = not enabled
        box.BackgroundColor3 = enabled and C.accent or C.chkOff
    end)
end

local function addDropdown(par, title, opts)
    addLabel(par, title)
    local idx = 1
    local btn = n("TextButton",{
        LayoutOrder=ord(),
        Size=UDim2.new(1,-4,0,22),
        BackgroundColor3=C.ddBg,
        BorderSizePixel=0,
        Text=opts[1] .. "   ▼",
        TextColor3=C.txt,
        TextSize=11,
        Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
    },par)
    stroke(btn, C.ddBdr, 1)
    corner(btn, 3)

    btn.MouseButton1Click:Connect(function()
        idx = idx % #opts + 1
        btn.Text = opts[idx] .. "   ▼"
    end)
end

local function addSlider(par, title, mn, mx, def, suffix)
    local cur = def
    suffix = suffix or ""
    local lbl = addLabel(par, title .. "  " .. cur .. suffix)

    local track = n("TextButton",{
        LayoutOrder=ord(),
        Size=UDim2.new(1,-6,0,6),
        Position=UDim2.fromOffset(3,0),
        BackgroundColor3=C.sliderTrk,
        BorderSizePixel=0,
        Text="",
        AutoButtonColor=false,
    },par)
    corner(track, 3)

    local fill = n("Frame",{
        Size=UDim2.new((def-mn)/(mx-mn),0,1,0),
        BackgroundColor3=C.accent,
        BorderSizePixel=0,
    },track)
    corner(fill, 3)

    local holding = false
    local function upd(x)
        local r = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
        cur = math.floor(mn + (mx-mn)*r + 0.5)
        fill.Size = UDim2.new(r,0,1,0)
        lbl.Text = title .. "  " .. cur .. suffix
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or  inp.UserInputType==Enum.UserInputType.Touch then
            holding=true; upd(inp.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if holding and (inp.UserInputType==Enum.UserInputType.MouseMovement
        or  inp.UserInputType==Enum.UserInputType.Touch) then
            upd(inp.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or  inp.UserInputType==Enum.UserInputType.Touch then holding=false end
    end)
end

local function addBtn(par, txt, cb)
    local b = n("TextButton",{
        LayoutOrder=ord(),
        Size=UDim2.new(1,-4,0,26),
        BackgroundColor3=C.btnBg,
        BorderSizePixel=0,
        Text=txt,
        TextColor3=C.txt,
        TextSize=12,
        Font=Enum.Font.Code,
    },par)
    stroke(b, C.btnBdr, 1)
    corner(b, 3)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end

-- ════════════════════════════════════════════════════════════
--  CONTENIDO: Miscellaneous
-- ════════════════════════════════════════════════════════════
addSlider(pMisc, "Override FOV", 0, 180, 115, "°")
addToggle(pMisc, "Bunny hop", true)
addToggle(pMisc, "Air strafe", true)
addDropdown(pMisc, "Air strafe direction", {"View angles","Movement","Off"})
addSlider(pMisc, "Air strafe smoothing", 0, 100, 0, "%")
addToggle(pMisc, "Z-Hop", false, true)
addToggle(pMisc, "Pre-speed", false, true)
addDropdown(pMisc, "Air duck", {"Off","On"})
addToggle(pMisc, "Knifebot", true)
addToggle(pMisc, "Zeusbot", true)
addToggle(pMisc, "Blockbot", false, true)
addToggle(pMisc, "Automatic weapons", true)
addSlider(pMisc, "Oms", 0, 100, 50)
addToggle(pMisc, "Jump at edge", false, true)
addToggle(pMisc, "Reveal competitive ranks", false)
addToggle(pMisc, "Auto-accept matchmaking", false)
addToggle(pMisc, "Log weapon purchases", true)
addToggle(pMisc, "Log damage dealt", true)
addToggle(pMisc, "Automatic grenade release", false, true)
addToggle(pMisc, "Fast walk", false)
addToggle(pMisc, "Free look", false, true)
addBtn(pMisc, "Steal player name")

-- ════════════════════════════════════════════════════════════
--  CONTENIDO: Settings
-- ════════════════════════════════════════════════════════════
-- Menu key
local mkRow = n("Frame",{
    LayoutOrder=ord(),
    Size=UDim2.new(1,-4,0,17),
    BackgroundTransparency=1,
},pSet)
n("TextLabel",{
    Position=UDim2.fromOffset(2,0),
    Size=UDim2.new(1,-50,1,0),
    BackgroundTransparency=1,
    Text="Menu key",
    TextColor3=C.txt, TextSize=12, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
},mkRow)
n("TextLabel",{
    Position=UDim2.new(1,-42,0,0),
    Size=UDim2.fromOffset(40,17),
    BackgroundTransparency=1,
    Text="INS",
    TextColor3=C.txtDim, TextSize=11, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Right,
},mkRow)

-- Menu color
local mcRow = n("Frame",{
    LayoutOrder=ord(),
    Size=UDim2.new(1,-4,0,17),
    BackgroundTransparency=1,
},pSet)
n("TextLabel",{
    Position=UDim2.fromOffset(2,0),
    Size=UDim2.new(1,-50,1,0),
    BackgroundTransparency=1,
    Text="Menu color",
    TextColor3=C.txt, TextSize=12, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
},mcRow)
local colorSwatch = n("Frame",{
    Position=UDim2.new(1,-22,3),
    Size=UDim2.fromOffset(16,10),
    BackgroundColor3=C.accent,
    BorderSizePixel=0,
},mcRow)
stroke(colorSwatch, C.border, 1)

addToggle(pSet, "Anti-untrusted", true)
addToggle(pSet, "Hide from OBS", false)
addToggle(pSet, "Low FPS warning", false)
addToggle(pSet, "Lock menu layout", false)
addToggle(pSet, "Trashtalk", false)

-- ════════════════════════════════════════════════════════════
--  CONTENIDO: Other
-- ════════════════════════════════════════════════════════════
-- Rage dropdown + [x]
local rageRow = n("Frame",{
    LayoutOrder=ord(),
    Size=UDim2.new(1,-4,0,22),
    BackgroundTransparency=1,
},pOth)
local rageBtn = n("TextButton",{
    Size=UDim2.new(1,-26,1,0),
    BackgroundColor3=C.ddBg,
    BorderSizePixel=0,
    Text="Rage   ▼",
    TextColor3=C.txt, TextSize=11, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
},rageRow)
stroke(rageBtn, C.ddBdr, 1)
corner(rageBtn, 3)
n("TextLabel",{
    Position=UDim2.new(1,-22,0,0),
    Size=UDim2.fromOffset(20,22),
    BackgroundTransparency=1,
    Text="[x]",
    TextColor3=C.txtDim, TextSize=11, Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Right,
},rageRow)

local rageOpts = {"Rage","Legit","Default"}
local rageIdx = 1
rageBtn.MouseButton1Click:Connect(function()
    rageIdx = rageIdx % #rageOpts + 1
    rageBtn.Text = rageOpts[rageIdx] .. "   ▼"
end)

addBtn(pOth, "Load config")
addBtn(pOth, "Save config")
addBtn(pOth, "Reset config")
addBtn(pOth, "Import from clipboard")
addBtn(pOth, "Export to clipboard")
addBtn(pOth, "Reset menu layout", function()
    win.Position = UDim2.new(0.5,-330,0.5,-280)
end)
addBtn(pOth, "Lua script manager")
addBtn(pOth, "Unload", function() gui:Destroy() end)

-- ── Tecla Insert para mostrar/ocultar ───────────────────────
UIS.InputBegan:Connect(function(inp, processed)
    if not processed and inp.KeyCode == Enum.KeyCode.Insert then
        win.Visible = not win.Visible
    end
end)
