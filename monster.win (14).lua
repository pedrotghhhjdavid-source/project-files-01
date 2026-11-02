--!nonstrict
-- NEON MENU · v3.0.0 · réplica 1:1 de la referencia (656x552)
--[[═══════════════════════════════════════════════════════════════════════════════
    N E O N   M E N U   ·   Luau (Roblox)   ·   v3.0.0 “GameSense”
   ───────────────────────────────────────────────────────────────────────────
   Réplica medida píxel a píxel de la captura de referencia (656 x 552):
   ventana 656x552, sidebar 73+1, paneles de 256 con hueco de 21, filas de 18,
   títulos de sección montados sobre el borde, checkbox de 6 px, pista de 8 px,
   dropdown de 20, botones de 23 y ancho 156, barra arcoíris de 4 px.

   Sólo interfaz: ningún control ejecuta lógica de juego. Todos los controles
   guardan su estado en Flags[] y llaman a tu callback opcional (UI:Bind).

   USO RÁPIDO
     · Pega el archivo completo en tu ejecutor y ejecútalo.
     · INSERT abre/cierra la ventana (configurable en Settings → Menu key).
     · Arrastra desde la barra superior o el fondo de la sidebar.
     · Unload (panel Other) destruye la GUI y desconecta todas las señales.

   API
     local UI = getgenv().NeonMenu
     UI.AddToggle(padre, { text = "X", flag = "x", default = true })
     UI.AddSlider(padre, { text = "X", flag = "y", min = 0, max = 100 })
     UI.AddDropdown(padre, { text = "X", flag = "z", items = {...} })
     UI.AddKeybind(padre, { text = "X", flag = "k", default = Enum.KeyCode.F })
     UI.AddButton(padre, { text = "X", callback = function() end })
     UI:Bind("x", function(v) print(v) end)
     UI.Notify("texto"), UI.SaveConfig(), UI.LoadConfig(), UI.Destroy()

   ESTRUCTURA DEL ARCHIVO
     1. Config      · paleta, medidas, acentos
     2. Util        · helpers de instancia, tween, texto
     3. Icons       · 7 iconos de silueta dibujados con primitivas
     4. State       · Flags, Callbacks, setFlag
     5. Components  · Panel, Toggle, Slider, Dropdown, Keybind, Button, filas
     6. Window      · ventana, arrastre, tabs, escalado
     7. Notify      · avisos discretos
     8. Persistence · guardar/cargar JSON
     9. Content     · contenido réplica de la vista previa
    10. Bootstrap   · tecla del menú, unload, exportación de la API
═══════════════════════════════════════════════════════════════════════════════]]

--==============================================================================
-- 1. CONFIG · paleta y medidas (equivalentes al CSS final)
--==============================================================================
local Config = {}

Config.Version = "3.0.0"   -- réplica medida de la referencia (GameSense)

-- Geometría medida píxel a píxel sobre la captura de referencia (656 x 552)
--   ventana 656x552 · sidebar 73 + 1 de separador · panel 256 · hueco 21
--   márgenes del contenido: 24 izquierda, 25 derecha, 22 arriba, 23 abajo
Config.WindowSize   = Vector2.new(656, 552)
Config.SidebarWidth = 74
Config.RainbowHeight = 4
Config.ContentPad   = { top = 22, left = 24, right = 25, bottom = 23 }
Config.PanelWidth   = 256
Config.PanelGap     = 21
Config.PanelPad     = { top = 18, left = 0, right = 0, bottom = 10 }
Config.RowPitch     = 18      -- ritmo vertical de las filas
Config.RowGap       = 0
Config.CheckInset   = 22      -- checkbox respecto al borde del panel
Config.FieldInset   = 42      -- sliders, dropdowns y botones
Config.RightInset   = 58      -- margen derecho de los campos (ancho útil 156)
Config.CheckSize    = 6       -- checkbox cuadrado diminuto
Config.TrackHeight  = 8       -- pista del slider
Config.FieldHeight  = 20      -- dropdown
Config.ButtonHeight = 23      -- botón
Config.ButtonGap    = 10
Config.CornerRadius = 0
Config.TitleOverlap = 6       -- el título se monta sobre el borde superior

-- Paleta medida en la referencia
Config.Color = {
	window        = Color3.fromRGB(11, 11, 11),
	windowStroke  = Color3.fromRGB(44, 44, 44),
	sidebar       = Color3.fromRGB(11, 11, 11),
	sidebarStroke = Color3.fromRGB(34, 34, 34),
	tabActive     = Color3.fromRGB(20, 20, 20),
	tabStroke     = Color3.fromRGB(40, 40, 40),
	tabHover      = Color3.fromRGB(20, 20, 20),
	panel         = Color3.fromRGB(23, 23, 23),
	panelStroke   = Color3.fromRGB(48, 48, 48),
	fieldTop      = Color3.fromRGB(38, 38, 38),
	fieldBottom   = Color3.fromRGB(26, 26, 26),
	fieldMid      = Color3.fromRGB(32, 32, 32),
	fieldStroke   = Color3.fromRGB(52, 52, 52),
	fieldHoverTop = Color3.fromRGB(46, 46, 46),
	fieldHoverBot = Color3.fromRGB(32, 32, 32),
	menuBg        = Color3.fromRGB(24, 24, 24),
	menuStroke    = Color3.fromRGB(52, 52, 52),
	menuItemHover = Color3.fromRGB(38, 38, 38),
	rowHover      = Color3.fromRGB(31, 31, 31),
	track         = Color3.fromRGB(62, 62, 62),
	checkOff      = Color3.fromRGB(62, 62, 62),
	checkStroke   = Color3.fromRGB(56, 56, 56),
	scrollThumb   = Color3.fromRGB(58, 58, 58),
	scrollTrack   = Color3.fromRGB(20, 20, 20),
	text          = Color3.fromRGB(236, 236, 236),
	textTitle     = Color3.fromRGB(242, 242, 242),
	textDim       = Color3.fromRGB(184, 184, 188),
	textFaint     = Color3.fromRGB(150, 150, 154),
	textButton    = Color3.fromRGB(238, 238, 240),
	textValue     = Color3.fromRGB(244, 244, 244),
	iconIdle      = Color3.fromRGB(126, 126, 130),
	iconHover     = Color3.fromRGB(168, 168, 172),
	iconActive    = Color3.fromRGB(214, 214, 218),
	white         = Color3.fromRGB(255, 255, 255),
}

-- Barra arcoíris (mismos stops que el degradado del preview)
Config.Rainbow = {
	{ 0.00, Color3.fromRGB(142, 43, 196) },
	{ 0.20, Color3.fromRGB(192, 47, 138) },
	{ 0.40, Color3.fromRGB(184, 128, 42) },
	{ 0.60, Color3.fromRGB(63, 157, 99) },
	{ 0.80, Color3.fromRGB(47, 127, 184) },
	{ 1.00, Color3.fromRGB(122, 47, 196) },
}

-- SourceSans: fuente nativa de Roblox, mejor rasterizada que Gotham a 11 px.
-- No usar TextScaled ni escalas fraccionarias innecesarias: vuelven borroso el texto.
Config.Font = {
	regular = Enum.Font.SourceSans,
	medium  = Enum.Font.SourceSansSemibold,
	bold    = Enum.Font.SourceSansBold,
}

Config.TextSize = {
	body   = 12,
	title  = 12,
	value  = 12,
	hint   = 11,
	button = 12,
}

-- Acentos seleccionables (swatch "Menu color")
Config.Accents = {
	{ name = "Púrpura", color = Color3.fromRGB(178, 58, 232) },
	{ name = "Rosa",    color = Color3.fromRGB(232, 58, 130) },
	{ name = "Cian",    color = Color3.fromRGB(58, 196, 232) },
	{ name = "Verde",   color = Color3.fromRGB(92, 220, 120) },
	{ name = "Ámbar",   color = Color3.fromRGB(232, 190, 58) },
	{ name = "Rojo",    color = Color3.fromRGB(232, 70, 70) },
}

Config.Accent = Config.Accents[1].color
Config.ConfigFile = "neon_menu_config.json"

--==============================================================================
-- 2. UTIL · helpers de instancia, estilo y texto
--==============================================================================
local Util = {}

local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local Workspace    = game:GetService("Workspace")
local LocalPlayer  = Players.LocalPlayer

Util.LocalPlayer = LocalPlayer

-- Funciones opcionales del ejecutor (se detectan sin romper nada)
local function optional(name)
	local ok, fn = pcall(function() return _G[name] end)
	if ok and type(fn) == "function" then
		return fn
	end
	return nil
end
Util.writefile   = optional("writefile")
Util.readfile    = optional("readfile")
Util.isfile      = optional("isfile")
Util.setclipboard = optional("setclipboard")
Util.getclipboard = optional("getclipboard")
Util.gethui      = optional("gethui")

--- Alias histórico de Util.set (se mantiene por compatibilidad).
function Util.setProperty(obj, key, value)
	return Util.set(obj, key, value)
end

-- Propiedades ausentes en algunas versiones de Roblox/ejecutores
-- (p. ej. CursorIcon o TextTruncate) se ignoran en lugar de abortar el script.
local warnedProps = {}

-- Propiedades puramente cosméticas: si el entorno no las soporta se omiten en
-- silencio (no afectan al diseño ni al funcionamiento).
local SILENT_PROPS = {
	CursorIcon = true, TextTruncate = true, TextWrapped = true,
	ElasticBehavior = true, ScrollingDirection = true,
	AutomaticCanvasSize = true, Selectable = true, RichText = true,
}

--- Asigna una propiedad a un Instance sin riesgo de abortar.
-- Devuelve true si se aplicó.
function Util.set(obj, prop, value)
	if obj == nil then
		return false
	end
	local ok, err = pcall(function()
		obj[prop] = value
	end)
	if not ok and not SILENT_PROPS[prop] then
		local key = tostring(obj.ClassName) .. "." .. tostring(prop)
		if not warnedProps[key] then
			warnedProps[key] = true
			warn("[NeonMenu] propiedad no soportada aquí (" .. key .. "): se ignora")
		end
	end
	return ok
end

--- Aplica una tabla de propiedades.
function Util.setAll(obj, props)
	for key, value in pairs(props or {}) do
		Util.set(obj, key, value)
	end
	return obj
end

--- Crea una instancia aplicando propiedades y orden automático en listas.
function Util.create(class, props, parent)
	local obj = Instance.new(class)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			Util.setProperty(obj, key, value)
		end
	end
	if parent then
		obj.Parent = parent
		if obj:IsA("GuiObject") and parent:FindFirstChildOfClass("UIListLayout") then
			Util.set(obj, "LayoutOrder", #parent:GetChildren())
		end
	end
	return obj
end

--- UICorner con radio fijo (0 = esquinas cuadradas).
-- Si la versión de Roblox no tiene UICorner, se ignora sin romper nada.
function Util.corner(obj, radius)
	local ok, result = pcall(function()
		return Util.create("UICorner", {
			CornerRadius = UDim.new(0, radius or Config.CornerRadius),
		}, obj)
	end)
	return ok and result or nil
end

-- Las instancias de Roblox no aceptan campos personalizados, así que las
-- referencias auxiliares (stroke, zona clicable) se guardan en tablas Lua.
local strokeRegistry = setmetatable({}, { __mode = "k" })
local hitRegistry = setmetatable({}, { __mode = "k" })

--- Devuelve el UIStroke asociado a un objeto (o nil).
function Util.getStroke(obj)
	return strokeRegistry[obj]
end

--- Asocia un UIStroke a un objeto para poder recolorearlo luego.
function Util.setStroke(obj, stroke)
	strokeRegistry[obj] = stroke
	return stroke
end

--- Devuelve el TextButton que cubre la fila (zona clicable), o nil.
function Util.getHit(obj)
	return hitRegistry[obj]
end

--- Asocia la zona clicable a la fila.
function Util.setHit(obj, hit)
	hitRegistry[obj] = hit
	return hit
end

--- Borde fino.
-- Si UIStroke no existe en esta versión, devuelve un objeto "virtual" (tabla Lua)
-- de modo que cambiar su color más tarde siga funcionando sin errores.
function Util.stroke(obj, color, thickness, transparency)
	local ok, result = pcall(function()
		return Util.create("UIStroke", {
			Color = color or Config.Color.panelStroke,
			Thickness = thickness or 1,
			Transparency = transparency or 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, obj)
	end)
	if ok and result then
		return Util.setStroke(obj, result)
	end
	return Util.setStroke(obj, {
		virtual = true,
		Color = color or Config.Color.panelStroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	})
end

--- Padding por lados.
function Util.pad(obj, p)
	p = p or Config.PanelPad
	return Util.create("UIPadding", {
		PaddingTop = UDim.new(0, p.top or 0),
		PaddingBottom = UDim.new(0, p.bottom or 0),
		PaddingLeft = UDim.new(0, p.left or 0),
		PaddingRight = UDim.new(0, p.right or 0),
	}, obj)
end

--- UIListLayout vertical u horizontal.
function Util.list(obj, gap, horizontal, align)
	return Util.create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or Config.RowGap),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, obj)
end

--- TextLabel con valores por defecto del tema.
function Util.label(parent, props)
	local base = {
		BackgroundTransparency = 1,
		Font = Config.Font.regular,
		TextSize = 13,
		TextColor3 = Config.Color.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		RichText = false,
	}
	for key, value in pairs(props or {}) do
		base[key] = value
	end
	-- La etiqueta no agranda ni reduce la fuente según el tamaño del contenedor:
	-- TextScaled en Roblox puede difuminar glifos y hacer que unos textos difieran.
	base.TextScaled = false
	base.TextSize = math.floor((tonumber(base.TextSize) or 13) + 0.5)
	if base.TextWrapped ~= true then
		base.TextWrapped = false
	end
	return Util.create("TextLabel", base, parent)
end

--- Degradado vertical reutilizable (paneles, campos y botones).
function Util.gradient(obj, top, bottom, mid)
	Util.set(obj, "BackgroundColor3", mid or top)
	local stops = {
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.52, mid or top),
		ColorSequenceKeypoint.new(1, bottom),
	}
	local ok, result = pcall(function()
		return Util.create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(stops),
		}, obj)
	end)
	if ok and result then
		return result
	end
	-- sin UIGradient: queda el color plano intermedio
	return { virtual = true, Color = ColorSequence.new(stops) }
end

--- Tween corto y sobrio (sin animaciones llamativas).
function Util.tween(obj, time, props)
	local info = TweenInfo.new(time or 0.1, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(obj, info, props)
	tween:Play()
	return tween
end

--- Nombre legible de una tecla.
local KEY_NAMES = {
	LeftShift = "L-SHIFT",
	RightShift = "R-SHIFT",
	LeftControl = "L-CTRL",
	RightControl = "R-CTRL",
	LeftAlt = "L-ALT",
	RightAlt = "R-ALT",
	MouseButton1 = "M1",
	MouseButton2 = "M2",
	Space = "SPACE",
	Insert = "INS",
	Delete = "DEL",
	Return = "ENTER",
	Backspace = "BACK",
	CapsLock = "CAPS",
	Tab = "TAB",
}

function Util.keyName(key)
	if key == nil then
		return "?"
	end
	local raw = tostring(key.Name or "?")
	local name = KEY_NAMES[raw] or string.upper(raw)
	if #name > 9 then
		name = string.sub(name, 1, 9)
	end
	return name
end

--- Conexiones guardadas para poder desconectar todo en Destroy().
local connections = {}
function Util.connect(signal, fn)
	local conn = signal:Connect(fn)
	connections[#connections + 1] = conn
	return conn
end

function Util.disconnectAll()
	for i = #connections, 1, -1 do
		pcall(function()
			connections[i]:Disconnect()
		end)
		connections[i] = nil
	end
end

--==============================================================================
-- 3. ICONS · iconos de silueta (máscara, globo, mira, sol, engranajes, hoz, persona)
--==============================================================================
-- Se dibujan con primitivas de GUI (Frame + UICorner + UIStroke), sin assets ni
-- imágenes externas. Cada icono devuelve:
--   { frame, setColor(fn), setKnock(color), solid = {...}, knock = {...} }
-- "knock" son los huecos interiores, que se pintan con el color del fondo de la
-- sidebar para simular siluetas recortadas como en la referencia.

local Icons = {}

local function piece(parent, size, position, rotation, radius, color)
	local f = Util.create("Frame", {
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromOffset(position.X, position.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color or Config.Color.iconIdle,
		BorderSizePixel = 0,
		Rotation = rotation or 0,
	}, parent)
	Util.corner(f, radius or 0)
	return f
end

--- Círculo sólido (radio = diámetro / 2).
local function dot(parent, diameter, position, color)
	return piece(parent, Vector2.new(diameter, diameter), position, 0,
		math.floor(diameter / 2), color)
end

--- Contorno circular o elíptico.
local function outline(parent, width, height, thickness, position)
	local f = Util.create("Frame", {
		Size = UDim2.fromOffset(width, height),
		Position = UDim2.fromOffset(position.X, position.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)
	Util.corner(f, math.floor(math.min(width, height) / 2))
	local stroke = Util.stroke(f, Config.Color.iconIdle, thickness or 1.6)
	return f, stroke
end

--- Arco hecho de círculos: unión continua, grosor variable.
local function arcOfDots(parent, center, radius, fromDeg, toDeg, steps, thicknessAt)
	local dots = {}
	for i = 0, steps do
		local t = i / steps
		local angle = math.rad(fromDeg + (toDeg - fromDeg) * t)
		local thickness = thicknessAt(t)
		dots[#dots + 1] = dot(parent, thickness,
			Vector2.new(center.X + math.cos(angle) * radius,
				center.Y + math.sin(angle) * radius))
	end
	return dots
end

-- ── Icono 1 · máscara con pistola (Misc) ────────────────────────────────────
local function iconMask(holder, S)
	local solid, knock = {}, {}

	-- careta: tres piezas encadenadas (frente, rostro, mentón)
	solid[#solid + 1] = dot(holder, S * 0.30, Vector2.new(S * 0.40, S * 0.34))
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.30, S * 0.30),
		Vector2.new(S * 0.41, S * 0.54), -10, S * 0.13)
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.17, S * 0.19),
		Vector2.new(S * 0.36, S * 0.72), -10, S * 0.08)

	-- huecos de la careta
	knock[#knock + 1] = dot(holder, S * 0.075, Vector2.new(S * 0.35, S * 0.31))
	knock[#knock + 1] = dot(holder, S * 0.065, Vector2.new(S * 0.47, S * 0.29))
	knock[#knock + 1] = dot(holder, S * 0.060, Vector2.new(S * 0.37, S * 0.47))

	-- pistola apuntando arriba-derecha
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.30, S * 0.075),
		Vector2.new(S * 0.68, S * 0.30), -16, math.floor(S * 0.03))
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.085, S * 0.17),
		Vector2.new(S * 0.60, S * 0.40), -16, math.floor(S * 0.03))
	solid[#solid + 1] = dot(holder, S * 0.055, Vector2.new(S * 0.83, S * 0.26))

	-- destello de 3 puntos
	solid[#solid + 1] = dot(holder, S * 0.055, Vector2.new(S * 0.90, S * 0.17))
	solid[#solid + 1] = dot(holder, S * 0.045, Vector2.new(S * 0.95, S * 0.27))
	solid[#solid + 1] = dot(holder, S * 0.040, Vector2.new(S * 0.88, S * 0.11))

	return { solid = solid, knock = knock }
end

-- ── Icono 2 · globo terráqueo tachado (Player) ──────────────────────────────
local function iconGlobeNoWeapon(holder, S)
	local c = Vector2.new(S * 0.48, S * 0.50)
	local solid, knock = {}, {}

	local ringFrame, ringStroke = outline(holder, S * 0.66, S * 0.66, S * 0.055, c)
	solid[#solid + 1] = ringStroke

	-- meridiano (elipse vertical)
	local meridF, meridStroke = outline(holder, S * 0.34, S * 0.66, S * 0.045, c)
	solid[#solid + 1] = meridStroke

	-- ecuador
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.66, S * 0.045), c, 0, 0)

	-- pistola dentro del globo (silueta)
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.26, S * 0.065),
		Vector2.new(c.X + S * 0.02, c.Y - S * 0.06), -28, math.floor(S * 0.025))
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.075, S * 0.14),
		Vector2.new(c.X - S * 0.02, c.Y + S * 0.05), -28, math.floor(S * 0.025))

	-- barra diagonal (prohibido) con su hueco de separación
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.80, S * 0.075), c, -45, 0)
	knock[#knock + 1] = piece(holder, Vector2.new(S * 0.14, S * 0.075), c, -45, 0)

	return { solid = solid, knock = knock }
end

-- ── Icono 3 · mira clásica (Combat) ────────────────────────────────────────
local function iconCrosshair(holder, S)
	local c = Vector2.new(S * 0.5, S * 0.5)
	local solid = {}

	local ringFrame, ringStroke = outline(holder, S * 0.62, S * 0.62, S * 0.055, c)
	solid[#solid + 1] = ringStroke

	-- marcas cardinales
	local tickLen, tickThick = S * 0.12, S * 0.05
	solid[#solid + 1] = piece(holder, Vector2.new(tickThick, tickLen),
		Vector2.new(c.X, c.Y - S * 0.36), 0, 0)
	solid[#solid + 1] = piece(holder, Vector2.new(tickThick, tickLen),
		Vector2.new(c.X, c.Y + S * 0.36), 0, 0)
	solid[#solid + 1] = piece(holder, Vector2.new(tickLen, tickThick),
		Vector2.new(c.X - S * 0.36, c.Y), 0, 0)
	solid[#solid + 1] = piece(holder, Vector2.new(tickLen, tickThick),
		Vector2.new(c.X + S * 0.36, c.Y), 0, 0)

	-- cruz central y punto
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.045, S * 0.20), c, 0, 0)
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.20, S * 0.045), c, 0, 0)
	solid[#solid + 1] = dot(holder, S * 0.055, c)

	return { solid = solid, knock = {} }
end

-- ── Icono 4 · sol con mitad rellena (Visuals) ──────────────────────────────
local function iconSun(holder, S)
	local c = Vector2.new(S * 0.5, S * 0.5)
	local solid = {}

	-- rayos
	for i = 0, 7 do
		local angle = math.rad(i * 45)
		local radius = S * 0.40
		solid[#solid + 1] = piece(holder, Vector2.new(S * 0.055, S * 0.17),
			Vector2.new(c.X + math.cos(angle) * radius, c.Y + math.sin(angle) * radius),
			i * 45, math.floor(S * 0.03))
	end

	-- disco: contorno + mitad derecha rellena
	local ringF, ringStroke = outline(holder, S * 0.44, S * 0.44, S * 0.055, c)
	solid[#solid + 1] = ringStroke

	local clip = Util.create("Frame", {
		Size = UDim2.fromOffset(S * 0.42, S * 0.42),
		Position = UDim2.fromOffset(c.X, c.Y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		BorderSizePixel = 0,
	}, holder)
	Util.corner(clip, math.floor(S * 0.21))

	solid[#solid + 1] = Util.create("Frame", {
		Size = UDim2.fromScale(0.52, 1),
		Position = UDim2.fromScale(0.48, 0),
		BackgroundColor3 = Config.Color.iconIdle,
		BorderSizePixel = 0,
	}, clip)

	return { solid = solid, knock = {} }
end

-- ── Icono 5 · engranajes (Config) ──────────────────────────────────────────
-- Cuerpo circular sólido con dientes solapados (se funden en una sola silueta)
-- y buje central recortado.
local function gearSolid(holder, center, radius, teeth, solid)
	for i = 0, teeth - 1 do
		local angle = math.rad(i * (360 / teeth) - 90)
		solid[#solid + 1] = piece(holder,
			Vector2.new(radius * 0.46, radius * 0.62),
			Vector2.new(center.X + math.cos(angle) * radius * 0.92,
				center.Y + math.sin(angle) * radius * 0.92),
			i * (360 / teeth), math.floor(radius * 0.06))
	end
	solid[#solid + 1] = dot(holder, radius * 1.42, center)
end

local function iconGears(holder, S)
	local solid, knock = {}, {}
	local bigCenter   = Vector2.new(S * 0.36, S * 0.60)
	local midCenter   = Vector2.new(S * 0.71, S * 0.26)
	local smallCenter = Vector2.new(S * 0.73, S * 0.68)

	gearSolid(holder, bigCenter, S * 0.19, 8, solid)
	gearSolid(holder, midCenter, S * 0.120, 7, solid)
	gearSolid(holder, smallCenter, S * 0.105, 6, solid)

	knock[#knock + 1] = dot(holder, S * 0.140, bigCenter)
	knock[#knock + 1] = dot(holder, S * 0.080, midCenter)
	knock[#knock + 1] = dot(holder, S * 0.070, smallCenter)

	return { solid = solid, knock = knock }
end

-- ── Icono 6 · hoz (Extra) ──────────────────────────────────────────────────
-- Hoja curva que barre de arriba-izquierda a abajo-derecha, con punta afilada
-- y remate esférico en la empuñadura (como la referencia).
local function iconScythe(holder, S)
	local center = Vector2.new(S * 0.54, S * 0.60)
	local radius = S * 0.34
	local solid = {}

	local dots = arcOfDots(holder, center, radius, 196, 352, 18, function(t)
		local taper = math.sin(math.pi * t)
		return S * (0.050 + 0.135 * taper)
	end)
	for _, d in ipairs(dots) do
		solid[#solid + 1] = d
	end

	-- punta afilada (extremo inicial del arco)
	local tipAngle = math.rad(196)
	solid[#solid + 1] = piece(holder, Vector2.new(S * 0.055, S * 0.19),
		Vector2.new(center.X + math.cos(tipAngle) * radius,
			center.Y + math.sin(tipAngle) * radius),
		196 + 90, math.floor(S * 0.027))

	-- remate esférico (extremo final del arco)
	local endAngle = math.rad(352)
	solid[#solid + 1] = dot(holder, S * 0.165,
		Vector2.new(center.X + math.cos(endAngle) * radius,
			center.Y + math.sin(endAngle) * radius))

	return { solid = solid, knock = {} }
end

-- ── Icono 7 · persona (Account) ────────────────────────────────────────────
local function iconPerson(holder, S)
	local solid = {
		dot(holder, S * 0.33, Vector2.new(S * 0.5, S * 0.30)),
		piece(holder, Vector2.new(S * 0.68, S * 0.33),
			Vector2.new(S * 0.5, S * 0.76), 0, S * 0.17),
	}
	return { solid = solid, knock = {} }
end

local ICON_BUILDERS = {
	spray = iconMask,
	mask = iconMask,
	globe = iconGlobeNoWeapon,
	crosshair = iconCrosshair,
	sun = iconSun,
	gear = iconGears,
	scythe = iconScythe,
	person = iconPerson,
}

--- Construye un icono centrado dentro del padre.
-- Devuelve { frame, solid, knock, setColor(fn), setKnock(color) }.
function Icons.build(parent, kind, size)
	size = size or 46
	local holder = Util.create("Frame", {
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
	}, parent)

	local builder = ICON_BUILDERS[kind] or ICON_BUILDERS.gear
	-- el dibujo cabe exactamente en su celda: nada sobresale del tab
	local drawing = builder(holder, size)

	local icon = {
		frame = holder,
		solid = drawing.solid,
		knock = drawing.knock,
		knockColor = Config.Color.sidebar,
	}

	function icon.setColor(valueFn)
		for _, obj in ipairs(icon.solid) do
			if obj.ClassName == "UIStroke" then
				obj.Color = valueFn()
			else
				Util.set(obj, "BackgroundColor3", valueFn())
			end
		end
	end

	function icon.setKnock(color)
		icon.knockColor = color
		for _, obj in ipairs(icon.knock) do
			Util.set(obj, "BackgroundColor3", color)
		end
	end

	icon.setKnock(icon.knockColor)
	return icon
end

--==============================================================================
-- 4. STATE · Flags, callbacks y acento
--==============================================================================
local State = {
	Flags = {},
	Callbacks = {},
	Accent = Config.Accent,
	CapturingKey = false,   -- true mientras un keybind espera una tecla
}

local accentBindings = {}
local accentListeners = {}

--- Registra un objeto para que siga el color de acento.
function State.bindAccent(obj, kind, alpha)
	accentBindings[#accentBindings + 1] = { obj = obj, kind = kind or "bg", alpha = alpha or 1 }
	return obj
end

--- Registra una función que se llama cada vez que cambia el acento.
function State.onAccentChange(fn)
	accentListeners[#accentListeners + 1] = fn
	return fn
end

function State.applyAccent(color)
	State.Accent = color
	for _, binding in ipairs(accentBindings) do
		local obj = binding.obj
		if obj and obj.Parent then
			local c = color
			if binding.alpha < 1 then
				c = Color3.new(color.R * binding.alpha, color.G * binding.alpha, color.B * binding.alpha)
			end
			if binding.kind == "bg" then
				Util.set(obj, "BackgroundColor3", c)
			elseif binding.kind == "text" then
				Util.set(obj, "TextColor3", c)
			elseif binding.kind == "stroke" then
				local strokeObj = Util.getStroke(obj)
				if strokeObj then
					Util.set(strokeObj, "Color", c)
				end
			end
		end
	end
	for _, listener in ipairs(accentListeners) do
		pcall(listener, color)
	end
end

-- Tecla del menú (se puede cambiar en Settings → Menu key)
State.MenuKey = Enum.KeyCode.Insert

--- Fija un flag y dispara su callback (protegido con pcall).
function State.setFlag(flag, value, silent)
	if flag then
		State.Flags[flag] = value
	end
	if flag and not silent then
		local callback = State.Callbacks[flag]
		if callback then
			local ok, err = pcall(callback, value)
			if not ok then
				warn("[NeonMenu] callback '" .. tostring(flag) .. "': " .. tostring(err))
			end
		end
	end
end

--==============================================================================
-- 5. COMPONENTS · piezas visuales (geometría medida sobre la referencia)
--==============================================================================
local Components = {}

-- Medidas derivadas de Config
local ROW_PITCH   = Config.RowPitch
local CHECK_INSET = Config.CheckInset
local FIELD_INSET = Config.FieldInset
local RIGHT_INSET = Config.RightInset
local LABEL_INSET = CHECK_INSET + 19   -- 41 px, igual que en la captura

--- Ancho de un campo (dropdown, slider, botón).
local function fieldWidth()
	return Config.PanelWidth - FIELD_INSET - RIGHT_INSET
end

-- ── 5.1 Panel con título montado sobre el borde superior ─────────────────────
--- Devuelve (body, panel): dentro de body se apilan los controles.
function Components.Panel(parent, title, options)
	options = options or {}
	local panel = Util.create("Frame", {
		Name = "Panel",
		Size = options.size or UDim2.new(0, Config.PanelWidth, 0, 0),
		AutomaticSize = (options.autoSize == false) and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundColor3 = Config.Color.panel,
		BorderSizePixel = 0,
		LayoutOrder = options.order or 0,
		ZIndex = 2,
	}, parent)
	Util.corner(panel, Config.CornerRadius)
	Util.stroke(panel, Config.Color.panelStroke, 1)

	-- cuerpo desplazado 16 px: deja sitio al título que rompe el borde
	local body = Util.create("Frame", {
		Name = "Body",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = (options.autoSize == false) and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		ZIndex = 2,
	}, panel)
	Util.create("UIPadding", {
		PaddingTop = UDim.new(0, Config.PanelPad.top),
		PaddingBottom = UDim.new(0, Config.PanelPad.bottom),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 0),
	}, body)
	Util.list(body, options.gap or 0, false, Enum.HorizontalAlignment.Left)

	if title then
		-- fondo del color de la ventana: "corta" el borde superior del panel
		local titleLabel = Util.label(panel, {
			Text = title,
			Font = Config.Font.bold,
			TextSize = Config.TextSize.title,
			TextColor3 = Config.Color.textTitle,
			BackgroundColor3 = Config.Color.window,
			BackgroundTransparency = 0,
			Size = UDim2.new(0, 0, 0, 12),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0, 14, 0, -Config.TitleOverlap),
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
		})
		Util.pad(titleLabel, { top = 0, bottom = 0, left = 3, right = 3 })
	end

	return body, panel
end

-- ── 5.2 Fila base (ritmo de 18 px) ──────────────────────────────────────────
local function createRow(parent, height, interactive, inset)
	local row = Util.create("Frame", {
		Size = UDim2.new(1, 0, 0, height or ROW_PITCH),
		BackgroundColor3 = Config.Color.rowHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, parent)

	if interactive then
		local hit = Util.create("TextButton", {
			Size = UDim2.new(1, -(inset or CHECK_INSET), 1, 0),
			Position = UDim2.new(0, inset or CHECK_INSET, 0, 0),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		}, row)
		Util.connect(hit.MouseEnter, function()
			Util.set(row, "BackgroundTransparency", 0)
		end)
		Util.connect(hit.MouseLeave, function()
			Util.set(row, "BackgroundTransparency", 1)
		end)
		Util.setHit(row, hit)
	end
	return row
end

-- ── 5.2b Captura de tecla (etiqueta "[ ] · [F]" a la derecha) ───────────────
local function makeKeyCapture(row, options)
	options = options or {}
	local flag = options.flag
	local current = options.default or nil
	local capturing = false
	local keyWidth = options.width or 46

	-- el corchete se ancla al borde derecho de la fila (6 px de margen)
	local rightInset = options.rightInset or 6

	local keyLabel = Util.label(row, {
		Text = "[+]",
		Font = Config.Font.regular,
		TextSize = Config.TextSize.hint,
		TextColor3 = Config.Color.textFaint,
		Size = UDim2.new(0, keyWidth, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -rightInset, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 5,
	})

	local hit = Util.create("TextButton", {
		Size = UDim2.new(0, keyWidth + 8, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -rightInset, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 6,
	}, row)

	local function render()
		if capturing then
			keyLabel.Text = "[...]"
			keyLabel.TextColor3 = State.Accent
		elseif current then
			keyLabel.Text = "[" .. Util.keyName(current) .. "]"
			keyLabel.TextColor3 = Config.Color.text
		else
			keyLabel.Text = "[+]"
			keyLabel.TextColor3 = Config.Color.textFaint
		end
	end

	local function startCapture()
		capturing = true
		State.CapturingKey = true
		current = nil
		render()
	end

	local function stopCapture()
		capturing = false
		State.CapturingKey = false
		render()
	end

	Util.connect(UserInput.InputBegan, function(input, processed)
		if capturing then
			State.CapturingKey = true
			if processed then
				return
			end
			local isKeyboard = input.UserInputType == Enum.UserInputType.Keyboard
			local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
			if isKeyboard or isMouse then
				if input.KeyCode == Enum.KeyCode.Escape then
					current = nil
				elseif input.KeyCode ~= Enum.KeyCode.Unknown then
					current = input.KeyCode
				end
				capturing = false
				State.CapturingKey = false
				render()
				State.setFlag(flag, current)
				if options.callback then
					pcall(options.callback, current)
				end
			end
			return
		end
		if options.onKey and current and input.KeyCode == current then
			pcall(options.onKey)
		end
	end)

	Util.connect(hit.MouseButton1Click, function()
		if capturing then
			stopCapture()
		else
			startCapture()
		end
	end)
	Util.connect(hit.MouseLeave, function()
		if capturing then
			stopCapture()
		end
	end)

	render()
	if flag and current then
		State.Flags[flag] = current
	end

	return {
		Set = function(key)
			current = key
			render()
			State.setFlag(flag, key)
		end,
		Get = function() return current end,
		render = render,
		start = startCapture,
		stop = stopCapture,
		Hit = hit,
	}
end
Components._makeKeyCapture = makeKeyCapture

-- ── 5.3 Toggle (checkbox de 6 px; magenta cuando está activo) ───────────────
function Components.Toggle(parent, options)
	options = options or {}
	local flag = options.flag
	local row = createRow(parent, options.height or ROW_PITCH, true, CHECK_INSET)

	local box = Util.create("Frame", {
		Size = UDim2.fromOffset(Config.CheckSize, Config.CheckSize),
		Position = UDim2.new(0, CHECK_INSET, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Config.Color.checkOff,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, row)
	Util.corner(box, 0)

	local hasKeybind = options.keyFlag ~= nil or options.keybind == true
	local labelRight = hasKeybind and 52 or 0

	Util.label(row, {
		Text = options.text or "Toggle",
		Font = Config.Font.regular,
		TextSize = Config.TextSize.body,
		TextColor3 = Config.Color.textDim,
		Position = UDim2.new(0, LABEL_INSET, 0, 0),
		Size = UDim2.new(1, -(LABEL_INSET + labelRight + 4), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 4,
	})

	local keyCapture
	if hasKeybind then
		keyCapture = makeKeyCapture(row, {
			flag = options.keyFlag,
			width = 30,
			callback = options.onKeyCapture,
		})
	end

	local value = options.default == true

	local function render()
		Util.set(box, "BackgroundColor3", value and State.Accent or Config.Color.checkOff)
	end

	local function set(v, silent)
		value = v == true
		render()
		State.setFlag(flag, value, silent)
		if options.callback then
			pcall(options.callback, value)
		end
	end

	render()
	if flag then
		State.Flags[flag] = value
	end
	State.onAccentChange(function(color)
		if value then
			Util.set(box, "BackgroundColor3", color)
		end
	end)

	Util.connect(Util.getHit(row).MouseButton1Click, function()
		set(not value)
	end)

	return {
		Set = set,
		Get = function() return value end,
		Row = row,
		Keybind = keyCapture,
	}
end

-- ── 5.4 Slider (pista de 6 px y valor en blanco sobre el extremo derecho) ───
function Components.Slider(parent, options)
	options = options or {}
	local flag = options.flag
	local min = options.min or 0
	local max = options.max or 100
	local decimals = options.decimals or 0
	local suffix = options.suffix or ""
	local value = math.clamp(options.default or min, min, max)

	local wrap = Util.create("Frame", {
		Size = UDim2.new(1, 0, 0, ROW_PITCH + Config.TrackHeight + 4),
		BackgroundTransparency = 1,
	}, parent)

	Util.label(wrap, {
		Text = options.text or "Slider",
		Font = Config.Font.regular,
		TextSize = Config.TextSize.body,
		TextColor3 = Config.Color.text,
		Position = UDim2.new(0, LABEL_INSET, 0, 0),
		Size = UDim2.new(1, -(LABEL_INSET + RIGHT_INSET), 0, ROW_PITCH),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local trackY = ROW_PITCH
	local track = Util.create("Frame", {
		Size = UDim2.new(0, fieldWidth(), 0, Config.TrackHeight),
		Position = UDim2.new(0, FIELD_INSET, 0, trackY),
		BackgroundColor3 = Config.Color.track,
		BorderSizePixel = 0,
	}, wrap)
	Util.corner(track, 0)

	local fill = Util.create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = State.Accent,
		BorderSizePixel = 0,
	}, track)
	Util.corner(fill, 0)
	State.bindAccent(fill, "bg")

	-- el valor se dibuja sobre la pista, siguiendo el extremo del relleno
	local valueWidth = 46
	local valueLabel = Util.label(wrap, {
		Text = "0",
		Font = Config.Font.bold,
		TextSize = Config.TextSize.value,
		TextColor3 = Config.Color.textValue,
		Size = UDim2.new(0, valueWidth, 0, Config.TrackHeight + 2),
		Position = UDim2.new(0, FIELD_INSET, 0, trackY - 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 6,
	})

	local hit = Util.create("TextButton", {
		Size = UDim2.new(0, fieldWidth(), 0, Config.TrackHeight + 8),
		Position = UDim2.new(0, FIELD_INSET, 0, trackY - 4),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 7,
	}, wrap)

	local function format(v)
		if decimals > 0 then
			return string.format("%." .. decimals .. "f", v) .. suffix
		end
		return tostring(math.floor(v + 0.5)) .. suffix
	end

	local function renderFill()
		local alpha = (max > min) and ((value - min) / (max - min)) or 0
		Util.set(fill, "Size", UDim2.fromScale(alpha, 1))
		valueLabel.Text = format(value)
		-- el número viaja con el relleno, igual que en la referencia
		local usable = fieldWidth() - valueWidth
		local offset = math.clamp(math.floor(alpha * fieldWidth() - valueWidth / 2 + 0.5), 0, usable)
		Util.set(valueLabel, "Position", UDim2.new(0, FIELD_INSET + offset, 0, trackY - 1))
	end

	local function applyFromX(mouseX)
		local pos = track.AbsolutePosition
		local size = track.AbsoluteSize
		local alpha = math.clamp((mouseX - pos.X) / math.max(size.X, 1), 0, 1)
		value = math.clamp(min + (max - min) * alpha, min, max)
		renderFill()
		State.setFlag(flag, value, true)
		if options.onChange then
			pcall(options.onChange, value)
		end
	end

	local dragging = false
	Util.connect(hit.MouseButton1Down, function()
		dragging = true
		applyFromX(UserInput:GetMouseLocation().X)
	end)
	Util.connect(UserInput.InputChanged, function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			applyFromX(UserInput:GetMouseLocation().X)
		end
	end)
	Util.connect(UserInput.InputEnded, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			State.setFlag(flag, value)
			if options.callback then
				pcall(options.callback, value)
			end
		end
	end)

	renderFill()
	if flag then
		State.Flags[flag] = value
	end

	return {
		Set = function(v)
			value = math.clamp(v, min, max)
			renderFill()
			State.setFlag(flag, value)
		end,
		Get = function() return value end,
		Frame = wrap,
	}
end

-- ── 5.5 Dropdown (22 px, degradado sutil y flecha pequeña) ──────────────────
function Components.Dropdown(parent, options)
	options = options or {}
	local flag = options.flag
	local items = options.items or {}
	local value = options.default or items[1] or ""

	local wrap = Util.create("Frame", {
		Size = UDim2.new(1, 0, 0, options.text and (ROW_PITCH + Config.FieldHeight + 2) or Config.FieldHeight),
		BackgroundTransparency = 1,
	}, parent)

	if options.text then
		Util.label(wrap, {
			Text = options.text,
			Font = Config.Font.regular,
			TextSize = Config.TextSize.body,
			TextColor3 = Config.Color.text,
			Position = UDim2.new(0, LABEL_INSET, 0, 0),
			Size = UDim2.new(1, -(LABEL_INSET + RIGHT_INSET), 0, ROW_PITCH),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end

	local boxY = options.text and (ROW_PITCH - 2) or 0
	local header = Util.create("Frame", {
		Size = UDim2.new(0, fieldWidth(), 0, Config.FieldHeight),
		Position = UDim2.new(0, FIELD_INSET, 0, boxY),
		BackgroundTransparency = 1,
	}, wrap)

	local box = Util.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Config.Color.fieldMid,
		BorderSizePixel = 0,
	}, header)
	Util.corner(box, 0)
	local boxStroke = Util.stroke(box, Config.Color.fieldStroke, 1)
	Util.gradient(box, Config.Color.fieldTop, Config.Color.fieldBottom, Config.Color.fieldMid)

	local valueLabel = Util.label(box, {
		Text = tostring(value),
		Font = Config.Font.regular,
		TextSize = Config.TextSize.body,
		TextColor3 = Config.Color.text,
		Position = UDim2.new(0, 9, 0, 0),
		Size = UDim2.new(1, -24, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	-- flecha: cuadrado girado 45° (triángulo visual)
	local arrowHolder = Util.create("Frame", {
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(1, -15, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
	}, box)
	Util.create("Frame", {
		Size = UDim2.fromOffset(5, 5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Config.Color.textFaint,
		BorderSizePixel = 0,
		Rotation = 45,
	}, arrowHolder)

	local menu = Util.create("Frame", {
		Size = UDim2.new(0, fieldWidth(), 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Config.Color.menuBg,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
		Position = UDim2.new(0, FIELD_INSET, 0, boxY + Config.FieldHeight),
		ZIndex = 20,
	}, wrap)
	Util.corner(menu, 0)
	Util.stroke(menu, Config.Color.menuStroke, 1)
	Util.pad(menu, { top = 2, bottom = 2, left = 2, right = 2 })

	local menuButtons = {}

	local function select(item, silent)
		value = item
		valueLabel.Text = tostring(item)
		for option, button in pairs(menuButtons) do
			local chosen = (option == item)
			Util.set(button, "BackgroundColor3", chosen and Config.Color.menuItemHover or Config.Color.menuBg)
			Util.set(button, "TextColor3", chosen and Config.Color.text or Config.Color.textDim)
		end
		State.setFlag(flag, item, silent)
		if options.callback then
			pcall(options.callback, item)
		end
	end

	for index, item in ipairs(items) do
		local option = Util.create("TextButton", {
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 0, (index - 1) * 18 + 2),
			BackgroundColor3 = (item == value) and Config.Color.menuItemHover or Config.Color.menuBg,
			BorderSizePixel = 0,
			Text = "  " .. tostring(item),
			Font = Config.Font.regular,
			TextSize = Config.TextSize.body,
			TextColor3 = (item == value) and Config.Color.text or Config.Color.textDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutoButtonColor = false,
			ZIndex = 21,
		}, menu)
		Util.corner(option, 0)
		menuButtons[item] = option

		Util.connect(option.MouseEnter, function()
			if item ~= value then
				Util.set(option, "BackgroundColor3", Config.Color.menuItemHover)
				Util.set(option, "TextColor3", Config.Color.text)
			end
		end)
		Util.connect(option.MouseLeave, function()
			if item ~= value then
				Util.set(option, "BackgroundColor3", Config.Color.menuBg)
				Util.set(option, "TextColor3", Config.Color.textDim)
			end
		end)
		Util.connect(option.MouseButton1Click, function()
			select(item)
			Util.set(menu, "Visible", false)
		end)
	end
	Util.set(menu, "Size", UDim2.new(0, fieldWidth(), 0, #items * 18 + 4))

	local hit = Util.create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
	}, header)

	Util.connect(hit.MouseEnter, function()
		Util.set(box, "BackgroundColor3", Config.Color.fieldHoverTop)
		Util.set(boxStroke, "Color", Color3.fromRGB(64, 64, 64))
	end)
	Util.connect(hit.MouseLeave, function()
		Util.set(box, "BackgroundColor3", Config.Color.fieldMid)
		Util.set(boxStroke, "Color", Config.Color.fieldStroke)
	end)
	Util.connect(hit.MouseButton1Click, function()
		Util.set(menu, "Visible", not menu.Visible)
	end)

	if flag then
		State.Flags[flag] = value
	end

	return {
		Set = function(v) select(v) end,
		Get = function() return value end,
		Frame = wrap,
	}
end

-- ── 5.6 Keybind (fila independiente) ────────────────────────────────────────
function Components.Keybind(parent, options)
	options = options or {}
	local row = createRow(parent, options.height or ROW_PITCH, true, CHECK_INSET)

	if (options.text or "") ~= "" then
		Util.label(row, {
			Text = options.text,
			Font = Config.Font.regular,
			TextSize = Config.TextSize.body,
			TextColor3 = Config.Color.text,
			Position = UDim2.new(0, LABEL_INSET, 0, 0),
			Size = UDim2.new(1, -(LABEL_INSET + 52), 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
	end

	local capture = makeKeyCapture(row, {
		flag = options.flag,
		default = options.default,
		width = options.width or 46,
		callback = options.callback,
		onKey = options.onKey,
	})

	Util.connect(Util.getHit(row).MouseButton1Click, function()
		capture.start()
	end)

	return {
		Set = capture.Set,
		Get = capture.Get,
		Row = row,
	}
end

-- ── 5.7 Button (borde fino y degradado, como en la referencia) ──────────────
function Components.Button(parent, options)
	options = options or {}
	-- contenedor de ancho completo: el UIListLayout del panel coloca este marco
	local holder = Util.create("Frame", {
		Name = "ButtonRow",
		Size = UDim2.new(1, 0, 0, options.height or Config.ButtonHeight),
		BackgroundTransparency = 1,
	}, parent)

	local button = Util.create("TextButton", {
		Size = UDim2.new(0, fieldWidth(), 1, 0),
		Position = UDim2.fromOffset(FIELD_INSET, 0),
		BackgroundColor3 = Config.Color.fieldMid,
		BorderSizePixel = 0,
		Text = options.text or "Button",
		Font = Config.Font.medium,
		TextSize = Config.TextSize.button,
		TextColor3 = Config.Color.textButton,
		TextXAlignment = Enum.TextXAlignment.Center,
		AutoButtonColor = false,
	}, holder)
	Util.corner(button, 0)
	local stroke = Util.stroke(button, Config.Color.fieldStroke, 1)
	local gradient = Util.gradient(button, Config.Color.fieldTop, Config.Color.fieldBottom, Config.Color.fieldMid)

	Util.connect(button.MouseEnter, function()
		Util.set(button, "BackgroundColor3", Config.Color.fieldMid)
		Util.set(gradient, "Enabled", false)
		Util.set(stroke, "Color", Color3.fromRGB(66, 66, 66))
	end)
	Util.connect(button.MouseLeave, function()
		Util.set(gradient, "Enabled", true)
		Util.set(stroke, "Color", Config.Color.fieldStroke)
	end)
	Util.connect(button.MouseButton1Click, function()
		if options.callback then
			local ok, err = pcall(options.callback)
			if not ok then
				warn("[NeonMenu] botón '" .. tostring(options.text) .. "': " .. tostring(err))
			end
		end
	end)

	return {
		Frame = button,
		Row = holder,
		SetText = function(text)
			Util.set(button, "Text", text)
		end,
	}
end

-- ── 5.8 Fila de texto con valor a la derecha ────────────────────────────────
function Components.LabelRow(parent, options)
	options = options or {}
	local row = createRow(parent, options.height or ROW_PITCH, options.interactive == true, CHECK_INSET)
	Util.label(row, {
		Text = options.text or "",
		Font = Config.Font.regular,
		TextSize = Config.TextSize.body,
		TextColor3 = options.dim and Config.Color.textDim or Config.Color.text,
		Position = UDim2.new(0, LABEL_INSET, 0, 0),
		Size = UDim2.new(1, -(LABEL_INSET + (options.rightWidth or 0) + 8), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	if options.rightText then
		Util.label(row, {
			Text = options.rightText,
			Font = Config.Font.regular,
			TextSize = Config.TextSize.hint,
			TextColor3 = Config.Color.textFaint,
			Size = UDim2.new(0, options.rightWidth or 40, 1, 0),
			Position = UDim2.new(1, -(options.rightWidth or 40) - RIGHT_INSET + 8, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
		})
	end
	return row
end

-- ── 5.9 Fila con muestra de color ───────────────────────────────────────────
function Components.ColorRow(parent, options)
	options = options or {}
	local row = createRow(parent, options.height or ROW_PITCH, true, CHECK_INSET)
	Util.label(row, {
		Text = options.text or "Menu color",
		Font = Config.Font.regular,
		TextSize = Config.TextSize.body,
		TextColor3 = Config.Color.text,
		Position = UDim2.new(0, LABEL_INSET, 0, 0),
		Size = UDim2.new(1, -(LABEL_INSET + 34), 1, 0),
	})
	local swatch = Util.create("Frame", {
		Size = UDim2.fromOffset(22, 8),
		Position = UDim2.new(1, -22 - RIGHT_INSET + 6, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = State.Accent,
		BorderSizePixel = 0,
	}, row)
	Util.corner(swatch, 0)
	State.bindAccent(swatch, "bg")
	return { Row = row, Swatch = swatch }
end

-- ── 5.10 Subencabezado ("Omnis") ────────────────────────────────────────────
function Components.SubTitle(parent, text)
	return Util.label(parent, {
		Text = text,
		Font = Config.Font.bold,
		TextSize = Config.TextSize.title,
		TextColor3 = Config.Color.textTitle,
		Position = UDim2.new(0, CHECK_INSET, 0, 0),
		Size = UDim2.new(1, -(CHECK_INSET + RIGHT_INSET), 0, ROW_PITCH),
	})
end

--- Nota de texto para pestañas sin controles.
function Components.Note(parent, text, height)
	return Util.label(parent, {
		Text = text,
		Font = Config.Font.regular,
		TextSize = Config.TextSize.body,
		TextColor3 = Config.Color.textDim,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, LABEL_INSET, 0, 0),
		Size = UDim2.new(1, -(LABEL_INSET + RIGHT_INSET), 0, height or 34),
	})
end

-- ── 5.11 Tabla de la API ────────────────────────────────────────────────────
local API = {}

API.AddPanel    = Components.Panel
API.AddSection  = Components.Panel
API.AddToggle   = Components.Toggle
API.AddSlider   = Components.Slider
API.AddDropdown = Components.Dropdown
API.AddKeybind  = Components.Keybind
API.AddButton   = Components.Button
API.AddLabelRow = Components.LabelRow
API.AddColorRow = Components.ColorRow
API.AddSubTitle = Components.SubTitle
API.AddNote     = Components.Note
--==============================================================================
-- 6. WINDOW · ventana, arrastre, pestañas y escalado
--==============================================================================
local Window = {}

local guiParent
if Util.gethui then
	guiParent = select(2, pcall(Util.gethui)) or nil
end
if not guiParent then
	local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
	guiParent = ok and coreGui or LocalPlayer:WaitForChild("PlayerGui")
end

-- Si ya había una versión cargada (p. ej. la antigua con el bug), se cierra
-- para no dejar dos ventanas superpuestas.
pcall(function()
	local previous = getgenv and getgenv().NeonMenu
	if previous and type(previous) == "table" and type(previous.Destroy) == "function" then
		previous.Destroy()
	end
end)

local screenGui = Util.create("ScreenGui", {
	Name = "NeonMenu_" .. tostring(math.random(1000, 9999)),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 9999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

pcall(function()
	if _G.protectgui then
		_G.protectgui(screenGui)
	end
end)

Window.ScreenGui = screenGui
Window.Pages = {}
Window.Tabs = {}
Window.ActiveTab = nil
Window.IsOpen = true

-- ── 6.1 Marco principal ──────────────────────────────────────────────────────
local root = Util.create("Frame", {
	Name = "Window",
	Size = UDim2.fromOffset(Config.WindowSize.X, Config.WindowSize.Y),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Config.Color.window,
	BorderSizePixel = 0,
	ClipsDescendants = false,
}, screenGui)
Util.corner(root, 0)
Util.stroke(root, Config.Color.windowStroke, 1)
Window.Root = root

pcall(function()
	Util.create("UIScale", { Name = "Scale", Scale = 1 }, root)
end)

-- ── 6.2 Barra arcoíris superior (2 px) ───────────────────────────────────────
local rainbow = Util.create("Frame", {
	Name = "RainbowBar",
	Size = UDim2.new(1, 0, 0, Config.RainbowHeight),
	BackgroundColor3 = Config.Color.white,
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
}, root)

do
	local keypoints = {}
	for _, stop in ipairs(Config.Rainbow) do
		keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(stop[1], stop[2])
	end
	-- la barra arcoíris tolera versiones sin UIGradient (queda el color base)
	pcall(function()
		Util.create("UIGradient", { Color = ColorSequence.new(keypoints) }, rainbow)
	end)
end

-- ── 6.3 Sidebar ──────────────────────────────────────────────────────────────
local sidebar = Util.create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, Config.SidebarWidth, 1, -Config.RainbowHeight),
	Position = UDim2.fromOffset(0, Config.RainbowHeight),
	BackgroundColor3 = Config.Color.sidebar,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, root)
Util.corner(sidebar, 0)
Util.create("Frame", {
	Name = "SidebarDivider",
	Size = UDim2.new(0, 1, 1, 0),
	Position = UDim2.new(1, -1, 0, 0),
	BackgroundColor3 = Config.Color.sidebarStroke,
	BorderSizePixel = 0,
}, sidebar)
Window.Sidebar = sidebar

-- Mover la ventana arrastrando el fondo de la sidebar (área libre)
do
	local dragArea = Util.create("TextButton", {
		Name = "SidebarDragArea",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 0,
	}, sidebar)

	local dragging, dragStart, startPos = false, nil, nil
	Util.connect(dragArea.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = root.Position
		end
	end)
	Util.connect(UserInput.InputChanged, function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			Util.set(root, "Position", UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			))
		end
	end)
	Util.connect(UserInput.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

local tabHolder = Util.create("Frame", {
	Name = "Tabs",
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 2,
}, sidebar)
Util.list(tabHolder, 0)

-- ── 6.4 Área de contenido (dos columnas) ─────────────────────────────────────
local content = Util.create("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -Config.SidebarWidth, 1, -Config.RainbowHeight),
	Position = UDim2.fromOffset(Config.SidebarWidth, Config.RainbowHeight),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
}, root)
Util.create("UIPadding", {
	PaddingTop = UDim.new(0, Config.ContentPad.top),
	PaddingBottom = UDim.new(0, Config.ContentPad.bottom),
	PaddingLeft = UDim.new(0, Config.ContentPad.left),
	PaddingRight = UDim.new(0, Config.ContentPad.right),
}, content)
Window.Content = content

-- Arrastrar también desde la franja superior
do
	local topDrag = Util.create("TextButton", {
		Name = "TopDragArea",
		Size = UDim2.new(1, -Config.SidebarWidth, 0, Config.RainbowHeight + 4),
		Position = UDim2.new(0, Config.SidebarWidth, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 30,
	}, root)

	local dragging, dragStart, startPos = false, nil, nil
	Util.connect(topDrag.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = root.Position
		end
	end)
	Util.connect(UserInput.InputChanged, function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			Util.set(root, "Position", UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			))
		end
	end)
	Util.connect(UserInput.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- ── 6.5 Escalado al viewport ─────────────────────────────────────────────────
local function fitScale()
	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local scale = math.min(1, math.min(viewport.X / (Config.WindowSize.X + 90), viewport.Y / (Config.WindowSize.Y + 80)))
	local holder = root:FindFirstChild("Scale")
	if holder then
		-- A 1:1, Roblox dibuja el texto en píxeles enteros. Solo se escala
		-- para pantallas que de verdad no caben; pasos estables de 1/4.
		local fitted = (scale >= 1) and 1 or math.max(0.5, math.floor(scale * 4) / 4)
		Util.set(holder, "Scale", fitted)
	end
end
fitScale()
if Workspace.CurrentCamera then
	Util.connect(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fitScale)
end

-- ── 6.6 Pestañas ─────────────────────────────────────────────────────────────
local TAB_ORDER = {}

local function setTabVisual(tab, active)
	Util.set(tab.button, "BackgroundColor3", active and Config.Color.tabActive or Config.Color.sidebar)
	-- la pestaña activa se marca con un tile algo más claro y dos líneas finas
	Util.set(tab.indicator, "Visible", active)
	Util.set(tab.footer, "Visible", active)
	tab.icon.setColor(function()
		return active and Config.Color.iconActive or Config.Color.iconIdle
	end)
	tab.icon.setKnock(active and Config.Color.tabActive or Config.Color.sidebar)
end

local function selectTab(name)
	Window.ActiveTab = name
	for tabName, page in pairs(Window.Pages) do
		page.Visible = (tabName == name)
	end
	for tabName, tab in pairs(Window.Tabs) do
		setTabVisual(tab, tabName == name)
	end
end
Window.SelectTab = selectTab

--- Crea una pestaña en la sidebar. Devuelve el Frame de su página.
function Window.AddTab(options)
	options = options or {}
	local name = options.name or ("Tab" .. tostring(#TAB_ORDER + 1))

	local button = Util.create("TextButton", {
		Name = "Tab_" .. name,
		Size = UDim2.new(1, 0, 1 / math.max(#TAB_ORDER + 1, 7), 0),
		BackgroundColor3 = Config.Color.sidebar,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = false,
		LayoutOrder = #TAB_ORDER + 1,
	}, tabHolder)
	Util.set(button, "CursorIcon", "PointingHand")

	-- líneas del tile activo (arriba y abajo), como en la referencia
	local indicator = Util.create("Frame", {
		Name = "TabTopLine",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Config.Color.tabStroke,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
	}, button)
	local footer = Util.create("Frame", {
		Name = "TabBottomLine",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundColor3 = Config.Color.tabStroke,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 4,
	}, button)

	local icon = Icons.build(button, options.icon or "gear", options.iconSize or 42)

	Util.connect(button.MouseEnter, function()
		if Window.ActiveTab ~= name then
			Util.set(button, "BackgroundColor3", Config.Color.tabHover)
			icon.setColor(function() return Config.Color.iconHover end)
		end
	end)
	Util.connect(button.MouseLeave, function()
		if Window.ActiveTab ~= name then
			Util.set(button, "BackgroundColor3", Config.Color.sidebar)
			icon.setColor(function() return Config.Color.iconIdle end)
		end
	end)
	Util.connect(button.MouseButton1Click, function()
		selectTab(name)
	end)

	local page = Util.create("Frame", {
		Name = "Page_" .. name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	}, content)

	Window.Pages[name] = page
	Window.Tabs[name] = { button = button, icon = icon, indicator = indicator,
		footer = footer, page = page }
	TAB_ORDER[#TAB_ORDER + 1] = name

	-- repartir alturas entre las pestañas existentes
	local count = #TAB_ORDER
	for _, tabName in ipairs(TAB_ORDER) do
		Window.Tabs[tabName].button.Size = UDim2.new(1, 0, 1 / math.max(count, 7), 0)
	end

	if not Window.ActiveTab then
		selectTab(name)
	end
	return page
end

--==============================================================================
-- 7. NOTIFY · avisos discretos en la esquina inferior derecha
--==============================================================================
local notifyHolder = Util.create("Frame", {
	Name = "Notifications",
	Size = UDim2.new(0, 240, 1, -40),
	Position = UDim2.new(1, -20, 0, 20),
	BackgroundTransparency = 1,
}, screenGui)
local notifyList = Util.list(notifyHolder, 6)
notifyList.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifyList.HorizontalAlignment = Enum.HorizontalAlignment.Right

--- Muestra un aviso breve. Sin sombras ni rebotes.
function Window.Notify(text, duration)
	duration = duration or 2.2
	local card = Util.create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = Config.Color.menuBg,
		BorderSizePixel = 0,
	}, notifyHolder)
	Util.corner(card, 0)
	Util.stroke(card, Config.Color.menuStroke, 1)

	local bar = Util.create("Frame", {
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = State.Accent,
		BorderSizePixel = 0,
	}, card)
	Util.corner(bar, 0)
	State.bindAccent(bar, "bg")

	Util.label(card, {
		Text = tostring(text),
		TextSize = 13,
		TextColor3 = Config.Color.text,
		Position = UDim2.fromOffset(9, 0),
		Size = UDim2.new(1, -16, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	task.delay(duration, function()
		if card.Parent then
			card:Destroy()
		end
	end)
	return card
end

--==============================================================================
-- 8. PERSISTENCE · guardar / cargar / restablecer (JSON)
--==============================================================================
local Persistence = {}

local function serialize()
	local payload = {
		version = Config.Version,
		accent = {
			r = math.floor(State.Accent.R * 255),
			g = math.floor(State.Accent.G * 255),
			b = math.floor(State.Accent.B * 255),
		},
		flags = {},
	}
	for flag, value in pairs(State.Flags) do
		if typeof(value) == "EnumItem" then
			payload.flags[flag] = value.Name
		elseif type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
			payload.flags[flag] = value
		end
	end
	return HttpService:JSONEncode(payload)
end
Persistence.serialize = serialize

function Persistence.save(silent)
	local ok = pcall(function()
		if not Util.writefile then
			error("writefile no disponible en este ejecutor")
		end
		Util.writefile(Config.ConfigFile, serialize())
	end)
	if not silent then
		Window.Notify(ok and "Configuración guardada" or "No se pudo guardar (writefile)")
	end
	return ok
end

function Persistence.load(silent)
	local payload
	local ok = pcall(function()
		if not Util.readfile then
			error("readfile no disponible")
		end
		if Util.isfile and not Util.isfile(Config.ConfigFile) then
			error("sin archivo")
		end
		payload = HttpService:JSONDecode(Util.readfile(Config.ConfigFile))
	end)
	if not ok or type(payload) ~= "table" then
		if not silent then
			Window.Notify("No hay configuración guardada")
		end
		return false
	end
	for flag, value in pairs(payload.flags or {}) do
		State.setFlag(flag, value)
	end
	if payload.accent then
		State.applyAccent(Color3.fromRGB(payload.accent.r, payload.accent.g, payload.accent.b))
	end
	if not silent then
		Window.Notify("Configuración cargada")
	end
	return true
end

function Persistence.reset()
	for flag in pairs(State.Flags) do
		State.Flags[flag] = nil
	end
	Window.Notify("Configuración restablecida")
end

--==============================================================================
-- 9. CONTENT · réplica del contenido de la vista previa
--==============================================================================
-- Toda la construcción va protegida: si el ejecutor rechaza algo inesperado se
-- informa en consola en lugar de dejar la ventana a medio dibujar en silencio.
local contentOk, contentErr = pcall(function()

--- Crea el marco de dos columnas dentro de una página.
local function twoColumns(page)
	local left = Util.create("Frame", {
		Name = "LeftColumn",
		Size = UDim2.new(0, Config.PanelWidth, 1, 0),
		BackgroundTransparency = 1,
	}, page)

	local right = Util.create("Frame", {
		Name = "RightColumn",
		Size = UDim2.new(0, Config.PanelWidth, 1, 0),
		Position = UDim2.new(0, Config.PanelWidth + Config.PanelGap, 0, 0),
		BackgroundTransparency = 1,
	}, page)

	return left, right
end

--- Panel alto con scroll interno (columna izquierda de la referencia).
local function scrollPanel(parent, title)
	local panel = Util.create("Frame", {
		Name = "ScrollPanel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Config.Color.panel,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, parent)
	Util.corner(panel, Config.CornerRadius)
	Util.stroke(panel, Config.Color.panelStroke, 1)

	local scroll = Util.create("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Config.Color.scrollThumb,
		ScrollBarImageTransparency = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ClipsDescendants = true,
	}, panel)
	Util.set(scroll, "AutomaticCanvasSize", Enum.AutomaticSize.Y)
	Util.set(scroll, "ElasticBehavior", Enum.ElasticBehavior.Never)
	Util.set(scroll, "ScrollBarImageColor3", Config.Color.scrollThumb)
	Util.set(scroll, "VerticalScrollBarInset", Enum.ScrollBarInset.ScrollBar)
	Util.create("UIPadding", {
		PaddingTop = UDim.new(0, Config.PanelPad.top),
		PaddingBottom = UDim.new(0, Config.PanelPad.bottom),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 6),
	}, scroll)

	local body = Util.create("Frame", {
		Name = "ScrollBody",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, scroll)
	local list = Util.list(body, 0)
	Util.set(list, "HorizontalAlignment", Enum.HorizontalAlignment.Left)

	-- respaldo para ejecutores sin AutomaticCanvasSize
	local function updateCanvas()
		local height = body.AbsoluteSize.Y
		if height and height > 0 then
			Util.set(scroll, "CanvasSize", UDim2.fromOffset(0, math.ceil(height) + Config.PanelPad.bottom))
		end
	end
	Util.connect(body:GetPropertyChangedSignal("AbsoluteSize"), updateCanvas)
	task.defer(updateCanvas)

	-- título que rompe el borde superior
	local titleLabel = Util.label(panel, {
		Text = title,
		Font = Config.Font.bold,
		TextSize = Config.TextSize.title,
		TextColor3 = Config.Color.textTitle,
		BackgroundColor3 = Config.Color.window,
		BackgroundTransparency = 0,
		Size = UDim2.new(0, 0, 0, 12),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 14, 0, -Config.TitleOverlap),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	})
	Util.pad(titleLabel, { top = 0, bottom = 0, left = 3, right = 3 })

	return body, scroll
end

-- ── 9.1 Pestaña Misc (contenido principal) ───────────────────────────────────
local miscPage = Window.AddTab({ name = "Misc", icon = "spray" })

local miscLeftCol, settingsColumn = twoColumns(miscPage)
local miscBody = scrollPanel(miscLeftCol, "Miscellaneous")

-- Override FOV
API.AddSlider(miscBody, {
	text = "Override FOV",
	flag = "override_fov",
	min = 0, max = 140, default = 115, suffix = "°",
})

-- Toggles y dirección de air strafe
API.AddToggle(miscBody, { text = "Bummy hop", flag = "bummy_hop", default = true })
API.AddToggle(miscBody, { text = "Air strafe", flag = "air_strafe", default = true })

API.AddDropdown(miscBody, {
	text = "Air strafe direction",
	flag = "air_strafe_direction",
	items = { "View angles", "Movement", "Crosshair", "Both" },
	default = "View angles",
})

API.AddSlider(miscBody, {
	text = "Air strafe smoothing",
	flag = "air_strafe_smoothing",
	min = 0, max = 100, default = 0, suffix = "%",
})

API.AddKeybind(miscBody, { text = "Z-Hop", flag = "zhop_key" })
API.AddKeybind(miscBody, { text = "Pre-speed", flag = "prespeed_key" })

API.AddDropdown(miscBody, {
	text = "Air duck",
	flag = "air_duck",
	items = { "Off", "On key", "Always" },
	default = "Off",
})

API.AddToggle(miscBody, { text = "Knifebot", flag = "knifebot", default = true })
API.AddToggle(miscBody, { text = "Zaubert", flag = "zaubert", default = true })
API.AddToggle(miscBody, {
	text = "Blockbot", flag = "blockbot", default = false,
	keyFlag = "blockbot_key",
})
API.AddToggle(miscBody, {
	text = "Automatic weapons", flag = "auto_weapons", default = true,
	keyFlag = "auto_weapons_key",
})

API.AddSubTitle(miscBody, "Omnis")

API.AddToggle(miscBody, {
	text = "Jump at edge", flag = "jump_at_edge", default = false,
	keyFlag = "jump_at_edge_key",
})
API.AddToggle(miscBody, { text = "Reveal competitive ranks", flag = "reveal_ranks", default = false })
API.AddToggle(miscBody, { text = "Auto-accept matchmaking", flag = "auto_accept", default = false })
API.AddToggle(miscBody, { text = "Log weapon purchases", flag = "log_purchases", default = true })
API.AddToggle(miscBody, { text = "Log damage dealt", flag = "log_damage", default = true })
API.AddToggle(miscBody, {
	text = "Automatic grenade release", flag = "auto_nade_release", default = false,
	keyFlag = "auto_nade_key",
})
API.AddToggle(miscBody, { text = "Fast walk", flag = "fast_walk", default = false })
API.AddToggle(miscBody, {
	text = "Free look", flag = "free_look", default = false,
	keyFlag = "free_look_key",
})

-- Botón ancho (80 % del panel, como en el preview)
API.AddButton(miscBody, {
	text = "Steal player name",
	callback = function()
		Window.Notify("Acción de demostración: Steal player name")
	end,
})

-- ── 9.2 Columna derecha: Settings + Other ────────────────────────────────────
Util.list(settingsColumn, 22)

local settingsBody, settingsPanel = Components.Panel(settingsColumn, "Settings", { order = 1 })

API.AddKeybind(settingsBody, {
	text = "Menu key",
	flag = "menu_key",
	default = Enum.KeyCode.Insert,
	callback = function(key)
		if key then
			State.MenuKey = key
			Window.Notify("Tecla del menú: " .. Util.keyName(key))
		end
	end,
})

-- Menu color: cicla los acentos del tema
do
	local colorRow = Components.ColorRow(settingsBody, { text = "Menu color" })
	Util.connect(Util.getHit(colorRow.Row).MouseButton1Click, function()
		local currentIndex = 1
		for index, accent in ipairs(Config.Accents) do
			if accent.color == State.Accent then
				currentIndex = index
				break
			end
		end
		local next = Config.Accents[(currentIndex % #Config.Accents) + 1]
		State.applyAccent(next.color)
		Window.Notify("Color: " .. next.name)
	end)
end

API.AddToggle(settingsBody, { text = "Anti-untrusted", flag = "anti_untrusted", default = true })
API.AddToggle(settingsBody, { text = "Hide from OBS", flag = "hide_from_obs", default = false })
API.AddToggle(settingsBody, { text = "Low FPS warning", flag = "low_fps_warning", default = false })
API.AddToggle(settingsBody, { text = "Lock menu layout", flag = "lock_layout", default = false })
API.AddToggle(settingsBody, { text = "Trashtalk", flag = "trashtalk", default = false })

local otherBody, otherPanel = Components.Panel(settingsColumn, "Other", { order = 2, gap = Config.ButtonGap })

-- Fila del selector de config: dropdown + keybind [X]
do
	local row = Util.create("Frame", {
		Size = UDim2.new(1, 0, 0, Config.FieldHeight),
		BackgroundTransparency = 1,
	}, otherBody)

	local dropHolder = Util.create("Frame", {
		Size = UDim2.new(1, 0, 0, Config.FieldHeight),
		BackgroundTransparency = 1,
	}, row)

	API.AddDropdown(dropHolder, {
		flag = "config_slot",
		items = { "Rage", "Legit", "HvH", "Default" },
		default = "Rage",
	})

	-- la tecla del slot se dibuja justo a la derecha del desplegable
	local keyHolder = Util.create("Frame", {
		Size = UDim2.new(0, 34, 0, Config.FieldHeight),
		Position = UDim2.fromOffset(Config.FieldInset
			+ (Config.PanelWidth - Config.FieldInset - Config.RightInset) + 8, 0),
		BackgroundTransparency = 1,
	}, row)

	local capture = Components._makeKeyCapture(keyHolder, {
		flag = "config_key", default = Enum.KeyCode.X,
		width = 26, rightInset = 0,
	})
	State.Flags["config_key"] = Enum.KeyCode.X
	Util.connect(Util.create("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 7,
	}, keyHolder).MouseButton1Click, function()
		capture.start()
	end)
end

API.AddButton(otherBody, { text = "Load config", callback = function() Persistence.load() end })
API.AddButton(otherBody, { text = "Save config", callback = function() Persistence.save() end })
API.AddButton(otherBody, { text = "Reset config", callback = function() Persistence.reset() end })

API.AddButton(otherBody, {
	text = "Import from clipboard",
	callback = function()
		if not Util.getclipboard then
			Window.Notify("getclipboard no disponible")
			return
		end
		local ok, text = pcall(Util.getclipboard)
		if ok and type(text) == "string" and #text > 0 then
			Window.Notify("Importado del portapapeles (" .. #text .. " bytes)")
		else
			Window.Notify("Portapapeles vacío")
		end
	end,
})

API.AddButton(otherBody, {
	text = "Export to clipboard",
	callback = function()
		if not Util.setclipboard then
			Window.Notify("setclipboard no disponible")
			return
		end
		local ok = pcall(Util.setclipboard, serialize())
		Window.Notify(ok and "Config copiada al portapapeles" or "No se pudo copiar")
	end,
})

API.AddButton(otherBody, {
	text = "Reset menu layout",
	callback = function()
		Util.set(root, "Size", UDim2.fromOffset(Config.WindowSize.X, Config.WindowSize.Y))
		Util.set(root, "Position", UDim2.fromScale(0.5, 0.5))
		Window.Notify("Layout restablecido")
	end,
})

API.AddButton(otherBody, {
	text = "Lua script manager",
	callback = function()
		Window.Notify("Script manager: pendiente de conectar")
	end,
})

API.AddButton(otherBody, {
	text = "Unload",
	callback = function()
		Window.Notify("Descargando...")
		task.delay(0.25, function()
			API.Destroy()
		end)
	end,
})

-- El panel "Other" ocupa el resto de la columna, como en el diseño.
-- Se recalcula cuando cambian las medidas reales (layout de Roblox).
-- 1) Preferido: UIFlexItem en el panel "Other" para que llene el espacio libre.
-- 2) Respaldo: cálculo con AbsoluteSize cuando UIFlexItem no existe.
local flexApplied = pcall(function()
	local flex = Instance.new("UIFlexItem", otherPanel)
	Util.set(flex, "FlexMode", Enum.UIFlexMode.Fill)
	Util.set(otherPanel, "AutomaticSize", Enum.AutomaticSize.None)
	Util.set(otherPanel, "Size", UDim2.fromScale(1, 1))
	return true
end)

if not flexApplied then
	local otherAutoHeight = true
	local function layoutSettingsColumn()
		if not settingsColumn.Parent then
			return
		end
		local available = settingsColumn.AbsoluteSize.Y
		local used = settingsPanel.AbsoluteSize.Y
		if available <= 0 or used <= 0 then
			return
		end
		local remaining = available - used - 6
		if otherAutoHeight and remaining > 0 then
			Util.set(otherPanel, "AutomaticSize", Enum.AutomaticSize.None)
			Util.set(otherPanel, "Size", UDim2.new(1, 0, 0, math.floor(remaining)))
			otherAutoHeight = false
		end
	end
	task.defer(layoutSettingsColumn)
	task.delay(0.1, layoutSettingsColumn)
	Util.connect(settingsPanel:GetPropertyChangedSignal("AbsoluteSize"), layoutSettingsColumn)
	Util.connect(settingsColumn:GetPropertyChangedSignal("AbsoluteSize"), layoutSettingsColumn)
end

-- ── 9.3 Pestañas restantes (páginas de ejemplo) ──────────────────────────────
local function placeholderPage(name, icon, title, note)
	local page = Window.AddTab({ name = name, icon = icon })
	local leftColumn = twoColumns(page)
	local body = Components.Panel(leftColumn, title)
	Components.Note(body, note, 34)
	API.AddButton(body, {
		text = "Conectar lógica",
		callback = function()
			Window.Notify('Usa UI:Bind("flag", fn) para conectar tu código')
		end,
	})
	return page
end

placeholderPage("Player", "globe", "Player",
	"Espacio listo para tus componentes: usa UI.AddToggle, UI.AddSlider o UI.AddDropdown.")
placeholderPage("Combat", "crosshair", "Combat",
	"Cada control guarda su estado en Flags y dispara tu callback con UI:Bind.")
placeholderPage("Visuals", "sun", "Visuals",
	'Crea más paneles con UI.AddPanel(columna, "Título").')
-- Config (misma pestaña de icono engranaje del diseño)
do
	local page = Window.AddTab({ name = "Config", icon = "gear" })
	local leftColumn = twoColumns(page)
	local body = Components.Panel(leftColumn, "Configuration")
	API.AddButton(body, { text = "Save config", callback = function() Persistence.save() end })
	API.AddButton(body, { text = "Load config", callback = function() Persistence.load() end })
	API.AddButton(body, { text = "Export to clipboard", callback = function()
		if Util.setclipboard then
			pcall(Util.setclipboard, serialize())
			Window.Notify("Config copiada al portapapeles")
		else
			Window.Notify("setclipboard no disponible")
		end
	end })
	API.AddButton(body, { text = "Reset config", callback = function() Persistence.reset() end })
end

placeholderPage("Extra", "scythe", "Extra",
	"Los componentes nuevos heredan el tema y el color de acento.")

placeholderPage("Account", "person", "Account",
	"El botón Unload destruye la interfaz y desconecta todas las señales.")

end) -- fin de la construcción del contenido

if not contentOk then
	warn("[NeonMenu] error construyendo el contenido: " .. tostring(contentErr))
end

-- Resumen de lo creado (diagnóstico rápido en ejecutores restrictivos)
do
	local tabCount, controlCount = 0, 0
	for _ in pairs(Window.Tabs) do
		tabCount = tabCount + 1
	end
	for _ in pairs(State.Flags) do
		controlCount = controlCount + 1
	end
	local accent = State.Accent
	print(("[NeonMenu] %d pestañas · %d controles · acento RGB(%d,%d,%d)")
		:format(tabCount, controlCount,
			math.floor(accent.R * 255), math.floor(accent.G * 255), math.floor(accent.B * 255)))
end

--==============================================================================
-- 10. BOOTSTRAP · tecla del menú, API pública y cierre
--==============================================================================

--- Abre o cierra la ventana.
function Window.Open(open)
	Window.IsOpen = open ~= false
	Util.set(root, "Visible", Window.IsOpen)
end

function Window.Toggle()
	Window.Open(not Window.IsOpen)
end

--- Destruye la GUI y limpia conexiones.
function API.Destroy()
	Util.disconnectAll()
	pcall(function()
		screenGui:Destroy()
	end)
end

Util.connect(UserInput.InputBegan, function(input, processed)
	if processed or State.CapturingKey then
		return
	end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == State.MenuKey then
		Window.Toggle()
	end
end)

-- ── API pública ──────────────────────────────────────────────────────────────
API.Flags       = State.Flags
API.Callbacks   = State.Callbacks
API.Theme       = Config
API.Accents     = Config.Accents
API.Window      = Window
API.Version     = Config.Version

--- Conecta lógica a un flag (se ejecuta ya si el flag tiene valor).
function API:Bind(flag, callback)
	State.Callbacks[flag] = callback
	if State.Flags[flag] ~= nil then
		pcall(callback, State.Flags[flag])
	end
end

function API:GetFlag(flag)
	return State.Flags[flag]
end

function API:SetFlag(flag, value)
	State.setFlag(flag, value)
end

function API:SetAccent(color)
	State.applyAccent(color)
end

API.AddTab = Window.AddTab

API.Notify        = Window.Notify
API.Open          = Window.Open
API.Toggle        = Window.Toggle
API.SelectTab     = Window.SelectTab
API.SaveConfig    = Persistence.save
API.LoadConfig    = Persistence.load
API.ResetConfig   = Persistence.reset
API.Serialize     = Persistence.serialize

-- Exponer globalmente (compatible con ejecutores y con _G)
if getgenv then
	local ok = pcall(function()
		getgenv().NeonMenu = API
		getgenv().UI = API
	end)
	if not ok then
		_G.NeonMenu = API
		_G.UI = API
	end
else
	_G.NeonMenu = API
	_G.UI = API
end

-- Aviso de arranque (sin animaciones) + marca de versión en consola
Window.Notify("Neon Menu v" .. Config.Version .. " · " .. Util.keyName(State.MenuKey) .. " para abrir/cerrar")
print(("[NeonMenu] v%s cargado · %s abre/cierra")
	:format(Config.Version, Util.keyName(State.MenuKey)))

return API
