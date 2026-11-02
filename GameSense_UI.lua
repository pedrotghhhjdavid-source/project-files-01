-- GameSense_UI.lua
-- Interfaz visual en Luau. Al ejecutar este archivo se crea la ventana.
-- No lee la global `script` y no hay que insertar un LocalScript en Studio.
--
-- Los controles solo cambian estado interno: casillas, sliders, listas,
-- color, opacidad y perfiles en memoria. No escriben la cámara, el humanoid,
-- el nombre de un jugador ni ningún servicio de la partida. El botón Run del
-- editor no ejecuta el texto.
--
-- Dependencias del cliente. Están en el proceso del juego; Studio no hace falta:
--   game, Instance, Enum, UDim2, UDim, Color3, Vector2, TweenInfo,
--   ColorSequence, ColorSequenceKeypoint, task, utf8,
--   Players, TweenService, UserInputService, RunService, GuiService
--
-- Opcionales. Si faltan, la ventana igual se crea y el aviso inicial lo dice:
--   getgenv()                                limpia la ventana de una ejecución anterior
--   gethui()                                 contenedor de GUI que expone el executor
--   CoreGui                                  se prueba si gethui no está
--   PlayerGui                                último recurso, solo si hay LocalPlayer
--   setclipboard / toclipboard / getclipboard
--   identifyexecutor / getexecutorname       solo aparecen en el aviso inicial
--
-- No forman parte de este entorno y este archivo no las llama:
--   plugin, script.Parent, ChangeHistoryService
--   writefile, readfile, appendfile, isfile, makefolder, listfiles
--   Drawing, cleardrawcache
--   hookfunction, hookmetamethod, newcclosure, checkcaller,
--   getnamecallmethod, getrawmetatable
--   protect_gui, syn.protect_gui, cloneref
--   request, http_request, HttpGet, game:HttpGet

if typeof(game) ~= "Instance" or typeof(Instance) ~= "table" or typeof(Enum) ~= "Enums" then
	warn("[GameSense_UI] Faltan game, Instance o Enum. Este archivo no corre en un intérprete Lua suelto ni como archivo abierto en Studio. Ejecútalo en un cliente Luau que ya tenga el datamodel.")
	return
end

local function capture(name, fn)
	if typeof(fn) == "function" then
		return fn
	end
	return nil
end

local Optional = {
	getgenv = capture("getgenv", getgenv),
	gethui = capture("gethui", gethui),
	setclipboard = capture("setclipboard", setclipboard),
	toclipboard = capture("toclipboard", toclipboard),
	getclipboard = capture("getclipboard", getclipboard),
	identifyexecutor = capture("identifyexecutor", identifyexecutor),
	getexecutorname = capture("getexecutorname", getexecutorname),
}

local function optionalFn(name)
	local fn = Optional[name]
	if typeof(fn) == "function" then
		return fn
	end
	local genvFn = Optional.getgenv
	if typeof(genvFn) == "function" then
		local ok, genv = pcall(genvFn)
		if ok and type(genv) == "table" then
			local inner = rawget(genv, name)
			if typeof(inner) == "function" then
				Optional[name] = inner
				return inner
			end
		end
	end
	return nil
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local clientOk, isClient = pcall(function()
	return RunService:IsClient()
end)
if clientOk and isClient == false then
	warn("[GameSense_UI] Este archivo solo crea la interfaz en el cliente.")
	return
end

local ENV = _G
local genvFn = optionalFn("getgenv")
if genvFn then
	local ok, genv = pcall(genvFn)
	if ok and type(genv) == "table" then
		ENV = genv
	end
end

if type(ENV.__GameSenseUIDestroy) == "function" then
	pcall(ENV.__GameSenseUIDestroy)
end

local function pickFont(name, fallback)
	local ok, font = pcall(function()
		return Enum.Font[name]
	end)
	if ok and font then
		return font
	end
	return fallback
end

local FontMain = pickFont("Gotham", Enum.Font.SourceSans)
local FontTitle = pickFont("GothamMedium", FontMain)

local DEG = utf8.char(176)

local Theme = {
	Window = Color3.fromRGB(18, 18, 18),
	Sidebar = Color3.fromRGB(14, 14, 14),
	Border = Color3.fromRGB(48, 48, 48),
	Button = Color3.fromRGB(34, 34, 34),
	ButtonHover = Color3.fromRGB(48, 48, 48),
	ButtonPress = Color3.fromRGB(26, 26, 26),
	Track = Color3.fromRGB(40, 40, 40),
	CheckOff = Color3.fromRGB(54, 54, 54),
	Text = Color3.fromRGB(206, 206, 206),
	TextDim = Color3.fromRGB(148, 148, 148),
	Title = Color3.fromRGB(226, 226, 226),
	Icon = Color3.fromRGB(132, 132, 132),
	IconActive = Color3.fromRGB(238, 238, 238),
	Accent = Color3.fromRGB(220, 40, 214),
}

local DEFAULT_ACCENT = Theme.Accent

local Defaults = {
	rage_enabled = false,
	rage_smooth = 0,
	rage_fov = 90,
	rage_mode = "Off",
	aa_enabled = false,
	aa_offset = 0,
	aa_dir = "Off",
	legit_enabled = false,
	legit_smooth = 0,
	legit_activation = "Off",
	menu_opacity = 100,
	animate = true,
	density = "Regular",
	override_fov = 115,
	bunny_hop = true,
	air_strafe = true,
	air_strafe_dir = "View angles",
	air_strafe_smooth = 0,
	z_hop = false,
	z_hop_adj = 0,
	pre_speed = false,
	pre_speed_adj = 0,
	air_duck = "Off",
	knifebot = true,
	zeusbot = false,
	blockbot = false,
	blockbot_adj = 0,
	automatic_weapons = true,
	auto_delay = 0,
	jump_edge = false,
	jump_edge_adj = 0,
	reveal_ranks = false,
	auto_accept = false,
	log_purchases = true,
	log_damage = true,
	auto_grenade = false,
	auto_grenade_adj = 0,
	fast_walk = false,
	free_look = false,
	free_look_adj = 0,
	anti_untrusted = true,
	hide_obs = false,
	low_fps = false,
	lock_layout = false,
	trashtalk = false,
	profile = "Rage",
	knife_model = "Default",
	knife_wear = 0,
	player_index = 1,
}

local DEFAULT_PROFILES = { "Rage", "Legit", "HvH", "Default" }

local KEY_SHORT = {
	Insert = "INS",
	Delete = "DEL",
	Home = "HOME",
	End = "END",
	PageUp = "PGUP",
	PageDown = "PGDN",
	LeftShift = "LSH",
	RightShift = "RSH",
	LeftControl = "LCTL",
	RightControl = "RCTL",
	LeftAlt = "LALT",
	RightAlt = "RALT",
	Space = "SPC",
	Backspace = "BKSP",
	CapsLock = "CAPS",
	Tab = "TAB",
	Escape = "ESC",
	Return = "ENT",
	KeypadEnter = "ENT",
	Up = "UP",
	Down = "DOWN",
	Left = "LEFT",
	Right = "RIGHT",
}

local INFO_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INFO_MED = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local WIN_W, WIN_H = 700, 512
local SIDE = 50
local MARGIN = 8
local GAP = 8
local LEFT_W = 384
local TOP = 14
local RIGHT_X = SIDE + MARGIN + LEFT_W + GAP
local RIGHT_W = WIN_W - RIGHT_X - MARGIN
local COL_H = WIN_H - TOP - MARGIN
local SETTINGS_H = 178

local State = {
	Open = true,
	MenuKey = Enum.KeyCode.Insert,
	ProfileName = "Rage",
	Clip = "",
	Values = {},
}

for key, value in pairs(Defaults) do
	State.Values[key] = value
end

local Profiles = {}
local profileNames = { "Rage", "Legit", "HvH", "Default" }
local listeners = {}
local themeListeners = {}
local connections = {}
local pageLayouts = {}
local destroyed = false
local screenGui = nil
local fpsConn = nil

local function track(conn)
	connections[#connections + 1] = conn
	return conn
end

local function disconnectAll()
	if fpsConn then
		fpsConn:Disconnect()
		fpsConn = nil
	end
	for i = #connections, 1, -1 do
		local conn = connections[i]
		connections[i] = nil
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function cleanup()
	if destroyed then
		return
	end
	destroyed = true
	disconnectAll()
	ENV.__GameSenseUIDestroy = nil
	if screenGui then
		local gui = screenGui
		screenGui = nil
		gui:Destroy()
	end
end

local function tween(obj, info, props)
	local tw = TweenService:Create(obj, info, props)
	tw:Play()
	return tw
end

local function later(seconds, fn)
	if task and task.delay then
		task.delay(seconds, fn)
	else
		spawn(function()
			wait(seconds)
			fn()
		end)
	end
end

local function afterLayout(fn)
	if task and task.spawn then
		task.spawn(function()
			RunService.Heartbeat:Wait()
			if not destroyed then
				fn()
			end
		end)
	end
end

local function new(className, props, parent)
	local inst = Instance.new(className)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	for key, value in pairs(props) do
		inst[key] = value
	end
	if parent ~= nil then
		inst.Parent = parent
	end
	return inst
end

local function stroke(inst, color)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = 1
	s.Parent = inst
	pcall(function()
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end)
	return s
end

local function watch(key, fn)
	local list = listeners[key]
	if not list then
		list = {}
		listeners[key] = list
	end
	list[#list + 1] = fn
end

local function bindValue(key, fn)
	watch(key, fn)
	fn(State.Values[key])
end

local function setValue(key, value)
	State.Values[key] = value
	local list = listeners[key]
	if not list then
		return
	end
	for i = 1, #list do
		local ok, err = pcall(list[i], value)
		if not ok then
			warn("[GameSense_UI] " .. tostring(err))
		end
	end
end

local function pushAll()
	for key, list in pairs(listeners) do
		local value = State.Values[key]
		for i = 1, #list do
			local ok, err = pcall(list[i], value)
			if not ok then
				warn("[GameSense_UI] " .. tostring(err))
			end
		end
	end
end

local function onAccent(fn)
	themeListeners[#themeListeners + 1] = fn
	fn()
end

local function applyAccent(color)
	Theme.Accent = color
	for i = 1, #themeListeners do
		local ok, err = pcall(themeListeners[i])
		if not ok then
			warn("[GameSense_UI] " .. tostring(err))
		end
	end
end

local function prettyKey(code)
	local name = code.Name
	if KEY_SHORT[name] then
		return KEY_SHORT[name]
	end
	if string.sub(name, 1, 6) == "Keypad" then
		return "N" .. string.sub(name, 7)
	end
	return string.upper(name)
end

local function roundTo(n, step)
	if step <= 0 then
		return n
	end
	if n >= 0 then
		return math.floor(n / step + 0.5) * step
	end
	return math.ceil(n / step - 0.5) * step
end

local function formatValue(v, kind)
	local n = tonumber(v) or 0
	local rounded = math.floor(math.abs(n) + 0.5)
	if n < 0 then
		rounded = -rounded
	end
	if kind == "deg" then
		return tostring(rounded) .. DEG
	elseif kind == "pct" then
		return tostring(rounded) .. "%"
	elseif kind == "ms" then
		return tostring(rounded) .. "ms"
	end
	return tostring(rounded)
end

local function copyValues()
	local copy = {}
	for key, value in pairs(State.Values) do
		copy[key] = value
	end
	return copy
end

local function restoreProfileList(list)
	for i = #profileNames, 1, -1 do
		profileNames[i] = nil
	end
	for i = 1, #list do
		profileNames[i] = list[i]
	end
end

local function sortedKeys(map)
	local keys = {}
	for key in pairs(map) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	return keys
end

local function splitLines(text)
	local lines = {}
	local start = 1
	while true do
		local a, b = string.find(text, "\n", start, true)
		if not a then
			lines[#lines + 1] = string.sub(text, start)
			break
		end
		lines[#lines + 1] = string.sub(text, start, a - 1)
		start = b + 1
	end
	return lines
end

local function trim(text)
	return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

local function serialize()
	local lines = { "GSUI1" }
	local keys = sortedKeys(State.Values)
	for i = 1, #keys do
		local key = keys[i]
		local value = State.Values[key]
		local kind = typeof(value)
		if kind == "boolean" then
			lines[#lines + 1] = key .. "=b:" .. (value and "1" or "0")
		elseif kind == "number" then
			lines[#lines + 1] = key .. "=n:" .. tostring(value)
		elseif kind == "string" then
			lines[#lines + 1] = key .. "=s:" .. string.gsub(value, "[\r\n]", " ")
		end
	end
	local c = Theme.Accent
	lines[#lines + 1] = string.format(
		"accent=c:%d,%d,%d",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5)
	)
	lines[#lines + 1] = "menukey=k:" .. State.MenuKey.Name
	return table.concat(lines, "\n")
end

local function keyFromName(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local ok, code = pcall(function()
		return Enum.KeyCode[name]
	end)
	if ok and code and code ~= Enum.KeyCode.Unknown then
		return code
	end
	return nil
end

local function parseConfig(text)
	if type(text) ~= "string" or #text == 0 or #text > 20000 then
		return nil
	end
	text = string.gsub(text, "\r", "")
	local lines = splitLines(text)
	if trim(lines[1] or "") ~= "GSUI1" then
		return nil
	end
	local values = {}
	local accent = nil
	local menuKey = nil
	for i = 2, #lines do
		local line = trim(lines[i])
		if line ~= "" then
			local key, kind, data = string.match(line, "^([%w_]+)=([bnskc]):(.*)$")
			if key and kind then
				if kind == "b" then
					values[key] = data == "1"
				elseif kind == "n" then
					local n = tonumber(data)
					if n then
						values[key] = n
					end
				elseif kind == "s" then
					values[key] = data
				elseif kind == "c" and key == "accent" then
					local r, g, b = string.match(data, "^(%d+),(%d+),(%d+)$")
					if r then
						accent = Color3.fromRGB(
							math.clamp(tonumber(r), 0, 255),
							math.clamp(tonumber(g), 0, 255),
							math.clamp(tonumber(b), 0, 255)
						)
					end
				elseif kind == "k" and key == "menukey" then
					menuKey = keyFromName(data)
				end
			end
		end
	end
	return values, accent, menuKey
end

local function createIcon(kind)
	local holder = Instance.new("Frame")
	holder.Name = kind
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Size = UDim2.fromOffset(18, 18)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)

	local parts = {}
	local strokes = {}

	local function addFrame(props)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = Theme.Icon
		for key, value in pairs(props) do
			f[key] = value
		end
		f.Parent = holder
		parts[#parts + 1] = f
		return f
	end

	local function addCircle(x, y, size, filled, thickness)
		local f = addFrame({
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = filled and 0 or 1,
		})
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = f
		if not filled then
			local s = Instance.new("UIStroke")
			s.Thickness = thickness or 1
			s.Color = Theme.Icon
			s.Parent = f
			strokes[#strokes + 1] = s
		end
		return f
	end

	if kind == "head" then
		addCircle(1, 2, 9, true)
		addFrame({ Position = UDim2.fromOffset(3, 11), Size = UDim2.fromOffset(6, 4) })
		addFrame({ Position = UDim2.fromOffset(11, 3), Size = UDim2.fromOffset(6, 1) })
		addFrame({ Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(5, 1) })
		addFrame({ Position = UDim2.fromOffset(11, 9), Size = UDim2.fromOffset(4, 1) })
	elseif kind == "antiaim" then
		addCircle(1, 1, 16, false, 1)
		addCircle(6, 4, 5, true)
		addFrame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(9, 9),
			Size = UDim2.fromOffset(14, 1),
			Rotation = 45,
		})
	elseif kind == "crosshair" then
		addCircle(1, 1, 16, false, 1)
		addFrame({ Position = UDim2.fromOffset(3, 8), Size = UDim2.fromOffset(4, 1) })
		addFrame({ Position = UDim2.fromOffset(11, 8), Size = UDim2.fromOffset(4, 1) })
		addFrame({ Position = UDim2.fromOffset(8, 3), Size = UDim2.fromOffset(1, 4) })
		addFrame({ Position = UDim2.fromOffset(8, 11), Size = UDim2.fromOffset(1, 4) })
	elseif kind == "sun" then
		addCircle(6, 6, 6, true)
		for i = 0, 7 do
			local ang = math.rad(i * 45)
			addFrame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(9 + math.cos(ang) * 7, 9 + math.sin(ang) * 7),
				Size = UDim2.fromOffset(2, 2),
			})
		end
	elseif kind == "gears" then
		addCircle(1, 7, 10, false, 1)
		addCircle(8, 1, 8, false, 1)
		local teeth = { { 6, 7 }, { 1, 12 }, { 11, 12 }, { 6, 16 }, { 12, 1 }, { 16, 5 }, { 12, 9 } }
		for i = 1, #teeth do
			addFrame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(teeth[i][1], teeth[i][2]),
				Size = UDim2.fromOffset(2, 2),
			})
		end
	elseif kind == "knife" then
		addFrame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(11, 7),
			Size = UDim2.fromOffset(2, 13),
			Rotation = -42,
		})
		addFrame({ Position = UDim2.fromOffset(2, 13), Size = UDim2.fromOffset(6, 3) })
		addFrame({ Position = UDim2.fromOffset(7, 12), Size = UDim2.fromOffset(2, 5) })
	else
		addCircle(5, 1, 7, true)
		local body = addFrame({
			Position = UDim2.fromOffset(2, 9),
			Size = UDim2.fromOffset(14, 8),
		})
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = body
	end

	local function colorize(color)
		for i = 1, #parts do
			parts[i].BackgroundColor3 = color
		end
		for i = 1, #strokes do
			strokes[i].Color = color
		end
	end

	return holder, colorize
end

local function parentLabel(inst)
	local name = inst.Name
	if type(name) ~= "string" or name == "" then
		return inst.ClassName
	end
	return name
end

local function resolveParent()
	local candidates = {}
	local labels = {}
	local seen = {}

	local function add(inst)
		if typeof(inst) ~= "Instance" or seen[inst] then
			return
		end
		seen[inst] = true
		candidates[#candidates + 1] = inst
		labels[#labels + 1] = parentLabel(inst)
	end

	local huiFn = optionalFn("gethui")
	if huiFn then
		local ok, hui = pcall(huiFn)
		if ok then
			add(hui)
		end
	end

	local okCore, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if okCore then
		add(core)
	end

	local player = Players.LocalPlayer
	if not player and #candidates == 0 then
		local okWait, arrived = pcall(function()
			return Players.PlayerAdded:Wait()
		end)
		if okWait then
			player = arrived
		end
	end
	if player then
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui and #candidates == 0 then
			local ok, result = pcall(function()
				return player:WaitForChild("PlayerGui", 8)
			end)
			if ok then
				playerGui = result
			end
		end
		add(playerGui)
	end

	return candidates, labels
end

local function reportEnvironment(parentName)
	local names = {
		"getgenv",
		"gethui",
		"setclipboard",
		"toclipboard",
		"getclipboard",
		"identifyexecutor",
		"getexecutorname",
	}
	local absent = {}
	for i = 1, #names do
		if not optionalFn(names[i]) then
			absent[#absent + 1] = names[i]
		end
	end
	local execName = nil
	local idFn = optionalFn("identifyexecutor") or optionalFn("getexecutorname")
	if idFn then
		local ok, name = pcall(idFn)
		if ok and type(name) == "string" and name ~= "" then
			execName = name
		end
	end
	local line = "[GameSense_UI] Ventana creada en " .. parentName .. "."
	if execName then
		line = line .. " Executor: " .. execName .. "."
	end
	if #absent > 0 then
		line = line .. " Opcionales ausentes: " .. table.concat(absent, ", ") .. "."
	else
		line = line .. " Opcionales de entorno presentes."
	end
	line = line .. " No se usan writefile, readfile, Drawing, HttpGet ni el editor para ejecutar código."
	warn(line)
end

local function build()
	local parents, labels = resolveParent()
	if #parents == 0 then
		error("No hay contenedor de interfaz. gethui, CoreGui y PlayerGui no están disponibles.")
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "GameSense_UI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 200
	gui.IgnoreGuiInset = false
	gui.Enabled = true

	local mountedName = nil
	for i = 1, #parents do
		local parent = parents[i]
		local ok = pcall(function()
			gui.Parent = parent
		end)
		if ok and gui.Parent == parent then
			mountedName = labels[i]
			break
		end
	end
	if not mountedName then
		gui:Destroy()
		error("No se pudo mostrar la interfaz. Contenedores probados: " .. table.concat(labels, ", ") .. ".")
	end

	screenGui = gui
	for _, child in ipairs(gui.Parent:GetChildren()) do
		if child ~= gui and child.Name == "GameSense_UI" then
			child:Destroy()
		end
	end
	reportEnvironment(mountedName)

	local canGroup = false
	local Window
	local okGroup, group = pcall(function()
		return Instance.new("CanvasGroup")
	end)
	if okGroup and group then
		Window = group
		canGroup = true
	else
		Window = Instance.new("Frame")
	end
	Window.Name = "Window"
	Window.BackgroundColor3 = Theme.Window
	Window.BorderSizePixel = 0
	Window.AnchorPoint = Vector2.new(0.5, 0.5)
	Window.Position = UDim2.fromScale(0.5, 0.5)
	Window.Size = UDim2.fromOffset(WIN_W, WIN_H)
	Window.Active = true
	Window.ClipsDescendants = true
	Window.ZIndex = 2
	Window.Parent = gui

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1
	uiScale.Parent = Window

	local function applyOpacity(v)
		local alpha = math.clamp(tonumber(v) or 100, 30, 100)
		if canGroup then
			pcall(function()
				Window.GroupTransparency = (100 - alpha) / 100
			end)
		end
	end

	local toast = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.fromOffset(380, 22),
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		Visible = false,
		ZIndex = 60,
	}, Window)
	stroke(toast, Theme.Border)
	local toastLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "",
		ZIndex = 61,
	}, toast)
	pcall(function()
		toastLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end)

	local toastToken = 0
	local function toastMsg(text)
		toastToken = toastToken + 1
		local token = toastToken
		toastLabel.Text = text
		toast.Visible = true
		later(1.8, function()
			if token == toastToken and not destroyed then
				toast.Visible = false
			end
		end)
	end

	local overlay = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 30,
		Active = false,
	}, Window)
	local backdrop = new("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 30,
	}, overlay)

	local function popupFrame()
		local frame = new("Frame", {
			BackgroundColor3 = Theme.Window,
			Visible = false,
			ClipsDescendants = true,
			ZIndex = 32,
		}, overlay)
		stroke(frame, Theme.Border)
		return frame
	end

	local dropPopup = popupFrame()
	local dropList = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 33,
	}, dropPopup)
	new("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, dropList)

	local gearPopup = popupFrame()
	local gearTitle = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -48, 0, 14),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		Text = "",
		ZIndex = 33,
	}, gearPopup)
	local gearValue = new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(36, 14),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.TextDim,
		Text = "0",
		ZIndex = 33,
	}, gearPopup)
	local gearHit = new("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 30),
		Size = UDim2.new(1, -16, 0, 14),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 33,
	}, gearPopup)
	local gearTrack = new("Frame", {
		BackgroundColor3 = Theme.Track,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 33,
	}, gearHit)
	local gearFill = new("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 34,
	}, gearTrack)
	local gearKnob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(1, 8),
		BackgroundColor3 = Color3.fromRGB(220, 220, 220),
		ZIndex = 35,
	}, gearTrack)

	local colorPopup = popupFrame()
	local presetRow = new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 10),
		Size = UDim2.new(1, -16, 0, 16),
		ZIndex = 33,
	}, colorPopup)
	local hueHit = new("TextButton", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 40),
		Size = UDim2.new(1, -16, 0, 16),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 33,
	}, colorPopup)
	local hueBar = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 8),
		ZIndex = 33,
	}, hueHit)
	local hueGradient = Instance.new("UIGradient")
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 40, 40)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 180, 40)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(220, 230, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 200, 80)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(40, 190, 220)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(80, 90, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 40, 220)),
	})
	hueGradient.Parent = hueBar
	local hueKnob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.83, 0, 0.5, 0),
		Size = UDim2.fromOffset(2, 12),
		BackgroundColor3 = Color3.fromRGB(240, 240, 240),
		ZIndex = 35,
	}, hueBar)

	local PRESETS = {
		Color3.fromRGB(220, 40, 214),
		Color3.fromRGB(168, 72, 255),
		Color3.fromRGB(64, 128, 255),
		Color3.fromRGB(36, 190, 176),
		Color3.fromRGB(70, 190, 82),
		Color3.fromRGB(230, 176, 42),
		Color3.fromRGB(230, 108, 42),
		Color3.fromRGB(220, 58, 72),
	}
	for i = 1, #PRESETS do
		local sw = new("TextButton", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset((i - 1) * 22, 0),
			BackgroundColor3 = PRESETS[i],
			Text = "",
			AutoButtonColor = false,
			ZIndex = 34,
		}, presetRow)
		local preset = PRESETS[i]
		sw.Activated:Connect(function()
			local h = preset:ToHSV()
			hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
			applyAccent(preset)
		end)
	end

	local renamePopup = popupFrame()
	local renameBox = new("TextBox", {
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.new(1, -16, 0, 18),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "",
		ClearTextOnFocus = false,
		ZIndex = 34,
	}, renamePopup)
	stroke(renameBox, Theme.Border)
	local renameApply = new("TextButton", {
		BackgroundColor3 = Theme.Button,
		Position = UDim2.fromOffset(8, 34),
		Size = UDim2.new(1, -16, 0, 18),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "Apply",
		AutoButtonColor = false,
		ZIndex = 34,
	}, renamePopup)
	stroke(renameApply, Theme.Border)

	local scriptModal = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 286),
		BackgroundColor3 = Theme.Window,
		Visible = false,
		ZIndex = 36,
	}, overlay)
	stroke(scriptModal, Theme.Border)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -36, 0, 16),
		Font = FontTitle,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Title,
		Text = "Lua script manager",
		ZIndex = 37,
	}, scriptModal)
	local scriptClose = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		Size = UDim2.fromOffset(18, 16),
		BackgroundTransparency = 1,
		Font = FontMain,
		TextSize = 14,
		TextColor3 = Theme.TextDim,
		Text = "x",
		AutoButtonColor = false,
		ZIndex = 37,
	}, scriptModal)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -20, 0, 14),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.TextDim,
		Text = "Visual editor. This button does not run code.",
		ZIndex = 37,
	}, scriptModal)
	local scriptBox = new("TextBox", {
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		Position = UDim2.fromOffset(10, 48),
		Size = UDim2.new(1, -20, 0, 180),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		PlaceholderText = "visual demo",
		PlaceholderColor3 = Theme.TextDim,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		ZIndex = 37,
	}, scriptModal)
	stroke(scriptBox, Theme.Border)
	local scriptRun = new("TextButton", {
		BackgroundColor3 = Theme.Button,
		Position = UDim2.fromOffset(10, 242),
		Size = UDim2.fromOffset(200, 22),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "Run",
		AutoButtonColor = false,
		ZIndex = 37,
	}, scriptModal)
	stroke(scriptRun, Theme.Border)
	local scriptDismiss = new("TextButton", {
		BackgroundColor3 = Theme.Button,
		Position = UDim2.fromOffset(220, 242),
		Size = UDim2.fromOffset(200, 22),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "Close",
		AutoButtonColor = false,
		ZIndex = 37,
	}, scriptModal)
	stroke(scriptDismiss, Theme.Border)

	local function closePopups()
		overlay.Visible = false
		dropPopup.Visible = false
		gearPopup.Visible = false
		colorPopup.Visible = false
		renamePopup.Visible = false
		scriptModal.Visible = false
	end

	local function placePopup(popup, anchor, width, height)
		local origin = Window.AbsolutePosition
		local apos = anchor.AbsolutePosition
		local asize = anchor.AbsoluteSize
		local x = apos.X - origin.X
		local y = apos.Y - origin.Y + asize.Y + 3
		local maxX = Window.AbsoluteSize.X - width - 6
		if x > maxX then
			x = maxX
		end
		if x < 6 then
			x = 6
		end
		if y + height > Window.AbsoluteSize.Y - 8 then
			y = apos.Y - origin.Y - height - 3
		end
		if y < 8 then
			y = 8
		end
		popup.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
		popup.Size = UDim2.fromOffset(width, height)
	end

	local function reveal(popup, width, height)
		if State.Values.animate then
			popup.Size = UDim2.fromOffset(width, 0)
		end
		popup.Visible = true
		overlay.Visible = true
		if State.Values.animate then
			tween(popup, INFO_FAST, { Size = UDim2.fromOffset(width, height) })
		end
	end

	local dragOwner = nil
	local currentGearKey = nil

	local function paintGear(v)
		local n = math.clamp(tonumber(v) or 0, 0, 100)
		local alpha = n / 100
		gearFill.Size = UDim2.new(alpha, 0, 1, 0)
		gearKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
		gearValue.Text = tostring(math.floor(n + 0.5))
	end

	local function beginSliderDrag(track, minV, maxV, step, apply)
		local function update(px)
			local width = track.AbsoluteSize.X
			local alpha = 0
			if width > 0 then
				alpha = math.clamp((px - track.AbsolutePosition.X) / width, 0, 1)
			end
			local raw = minV + (maxV - minV) * alpha
			apply(math.clamp(roundTo(raw, step), minV, maxV))
		end
		return update
	end

	gearHit.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local update = beginSliderDrag(gearTrack, 0, 100, 1, function(v)
			if currentGearKey then
				State.Values[currentGearKey] = v
			end
			paintGear(v)
		end)
		update(input.Position.X)
		dragOwner = function(moveInput)
			if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				update(moveInput.Position.X)
			end
		end
	end)

	local function applyHue(alpha)
		alpha = math.clamp(alpha, 0, 1)
		hueKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
		applyAccent(Color3.fromHSV(alpha, 0.78, 1))
	end

	hueHit.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local function update(px)
			local width = hueBar.AbsoluteSize.X
			local alpha = 0
			if width > 0 then
				alpha = math.clamp((px - hueBar.AbsolutePosition.X) / width, 0, 1)
			end
			applyHue(alpha)
		end
		update(input.Position.X)
		dragOwner = function(moveInput)
			if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
				update(moveInput.Position.X)
			end
		end
	end)

	onAccent(function()
		gearFill.BackgroundColor3 = Theme.Accent
	end)

	local function openGear(anchor, key, title)
		currentGearKey = key .. "_adj"
		if typeof(State.Values[currentGearKey]) ~= "number" then
			State.Values[currentGearKey] = 0
		end
		gearTitle.Text = title
		paintGear(State.Values[currentGearKey])
		closePopups()
		placePopup(gearPopup, anchor, 188, 56)
		reveal(gearPopup, 188, 56)
	end

	local function openColor(anchor)
		local h = Theme.Accent:ToHSV()
		hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
		closePopups()
		placePopup(colorPopup, anchor, 196, 68)
		reveal(colorPopup, 196, 68)
	end

	local function openScriptModal()
		closePopups()
		overlay.Visible = true
		scriptModal.Visible = true
	end

	scriptClose.Activated:Connect(closePopups)
	backdrop.Activated:Connect(closePopups)

	local profileApi = nil

	local function commitRename()
		local newName = trim(renameBox.Text)
		if newName == "" then
			closePopups()
			return
		end
		if #newName > 18 then
			newName = string.sub(newName, 1, 18)
		end
		local old = State.ProfileName
		for i = 1, #profileNames do
			if profileNames[i] == newName and newName ~= old then
				toastMsg("That name already exists")
				return
			end
		end
		for i = 1, #profileNames do
			if profileNames[i] == old then
				profileNames[i] = newName
				break
			end
		end
		if Profiles[old] then
			Profiles[newName] = Profiles[old]
			if newName ~= old then
				Profiles[old] = nil
			end
		end
		State.ProfileName = newName
		setValue("profile", newName)
		if profileApi then
			profileApi.setOptions(profileNames)
		end
		closePopups()
	end

	renameBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and renamePopup.Visible then
			commitRename()
		end
	end)

	local function openRename(anchor)
		renameBox.Text = State.ProfileName
		closePopups()
		placePopup(renamePopup, anchor, 188, 60)
		reveal(renamePopup, 188, 60)
		afterLayout(function()
			if renamePopup.Visible then
				renameBox:CaptureFocus()
			end
		end)
	end

	local orderN = 0
	local function nextOrder()
		orderN = orderN + 1
		return orderN
	end

	local function attachButton(btn, onClick)
		btn.AutoButtonColor = false
		btn.MouseEnter:Connect(function()
			tween(btn, INFO_FAST, { BackgroundColor3 = Theme.ButtonHover })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, INFO_FAST, { BackgroundColor3 = Theme.Button })
		end)
		btn.MouseButton1Down:Connect(function()
			tween(btn, INFO_FAST, { BackgroundColor3 = Theme.ButtonPress })
		end)
		btn.MouseButton1Up:Connect(function()
			tween(btn, INFO_FAST, { BackgroundColor3 = Theme.ButtonHover })
		end)
		btn.Activated:Connect(function()
			onClick()
		end)
	end

	attachButton(scriptRun, function()
		toastMsg("Script execution is disabled. This menu is visual only.")
	end)
	attachButton(scriptDismiss, closePopups)
	attachButton(renameApply, commitRename)

	local function chevron(parent)
		local wrap = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(8, 6),
			ZIndex = parent.ZIndex + 1,
		}, parent)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(2, 3),
			Size = UDim2.fromOffset(5, 1),
			Rotation = 38,
			BackgroundColor3 = Theme.TextDim,
			ZIndex = parent.ZIndex + 1,
		}, wrap)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(6, 3),
			Size = UDim2.fromOffset(5, 1),
			Rotation = -38,
			BackgroundColor3 = Theme.TextDim,
			ZIndex = parent.ZIndex + 1,
		}, wrap)
	end

	local function openDropdown(anchor, key, options)
		for _, child in ipairs(dropList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local current = State.Values[key]
		for i = 1, #options do
			local opt = options[i]
			local row = new("TextButton", {
				BackgroundColor3 = Theme.Window,
				Size = UDim2.new(1, 0, 0, 20),
				Font = FontMain,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = opt == current and Theme.Text or Theme.TextDim,
				Text = opt,
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 34,
			}, dropList)
			new("UIPadding", {
				PaddingLeft = UDim.new(0, 6),
			}, row)
			row.MouseEnter:Connect(function()
				tween(row, INFO_FAST, { BackgroundColor3 = Theme.ButtonHover })
			end)
			row.MouseLeave:Connect(function()
				tween(row, INFO_FAST, { BackgroundColor3 = Theme.Window })
			end)
			row.Activated:Connect(function()
				setValue(key, opt)
				closePopups()
			end)
		end
		local height = #options * 20
		closePopups()
		placePopup(dropPopup, anchor, math.max(anchor.AbsoluteSize.X, 80), height)
		reveal(dropPopup, math.max(anchor.AbsoluteSize.X, 80), height)
	end

	local function createCheckbox(parent, opts)
		local row = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			LayoutOrder = nextOrder(),
		}, parent)
		local hit = new("TextButton", {
			BackgroundTransparency = 1,
			Size = opts.gear and UDim2.new(1, -24, 1, 0) or UDim2.fromScale(1, 1),
			Text = "",
			AutoButtonColor = false,
		}, row)
		local box = new("Frame", {
			BackgroundColor3 = Theme.CheckOff,
			Position = UDim2.fromOffset(0, 4),
			Size = UDim2.fromOffset(8, 8),
		}, hit)
		local label = new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -16, 1, 0),
			Font = FontMain,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Text,
			Text = opts.text,
		}, hit)
		pcall(function()
			label.TextTruncate = Enum.TextTruncate.AtEnd
		end)
		local primed = false
		local function paint(v, animated)
			local color = v and Theme.Accent or Theme.CheckOff
			if animated and State.Values.animate then
				tween(box, INFO_FAST, { BackgroundColor3 = color })
			else
				box.BackgroundColor3 = color
			end
		end
		bindValue(opts.key, function(v)
			paint(v, primed)
			primed = true
		end)
		onAccent(function()
			if State.Values[opts.key] then
				box.BackgroundColor3 = Theme.Accent
			end
		end)
		hit.Activated:Connect(function()
			setValue(opts.key, not State.Values[opts.key])
		end)
		if opts.gear then
			local gear = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(20, 14),
				BackgroundColor3 = Theme.Button,
				Font = FontMain,
				TextSize = 12,
				TextColor3 = Theme.TextDim,
				Text = "...",
				AutoButtonColor = false,
			}, row)
			stroke(gear, Theme.Border)
			attachButton(gear, function()
				openGear(gear, opts.key, opts.text)
			end)
		end
	end

	local function createSlider(parent, opts)
		local inline = opts.inline == true
		local block = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, inline and 16 or 34),
			LayoutOrder = nextOrder(),
		}, parent)
		local valueLabel
		local hit
		if inline then
			valueLabel = new("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(42, 16),
				Font = FontMain,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.TextDim,
				Text = "",
			}, block)
			hit = new("TextButton", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(44, 1),
				Size = UDim2.new(1, -44, 0, 14),
				Text = "",
				AutoButtonColor = false,
			}, block)
		else
			new("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -52, 0, 14),
				Font = FontMain,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
				Text = opts.text or "",
			}, block)
			valueLabel = new("TextLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.fromOffset(52, 14),
				Font = FontMain,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = Theme.TextDim,
				Text = "",
			}, block)
			hit = new("TextButton", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(0, 16),
				Size = UDim2.new(1, 0, 0, 14),
				Text = "",
				AutoButtonColor = false,
			}, block)
		end
		local track = new("Frame", {
			BackgroundColor3 = Theme.Track,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 0, 2),
		}, hit)
		local fill = new("Frame", {
			BackgroundColor3 = Theme.Accent,
			Size = UDim2.new(0, 0, 1, 0),
		}, track)
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(1, 8),
			BackgroundColor3 = Color3.fromRGB(220, 220, 220),
			ZIndex = 2,
		}, track)
		local minV = opts.min
		local maxV = opts.max
		local step = opts.step or 1
		local function paint(v)
			local n = math.clamp(tonumber(v) or minV, minV, maxV)
			if math.abs(n - (tonumber(v) or n)) > 0.001 then
				State.Values[opts.key] = n
			end
			local alpha = 0
			if maxV ~= minV then
				alpha = math.clamp((n - minV) / (maxV - minV), 0, 1)
			end
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
			valueLabel.Text = formatValue(n, opts.format)
			if opts.key == "menu_opacity" then
				applyOpacity(n)
			end
		end
		bindValue(opts.key, paint)
		onAccent(function()
			fill.BackgroundColor3 = Theme.Accent
		end)
		hit.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			local update = beginSliderDrag(track, minV, maxV, step, function(v)
				setValue(opts.key, v)
			end)
			update(input.Position.X)
			dragOwner = function(moveInput)
				if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
					update(moveInput.Position.X)
				end
			end
		end)
	end

	local function createDropdown(parent, opts)
		local hasText = opts.text ~= nil
		local block = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, hasText and 36 or 18),
			LayoutOrder = nextOrder(),
		}, parent)
		local boxTop = 0
		if hasText then
			new("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 14),
				Font = FontMain,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
				Text = opts.text,
			}, block)
			boxTop = 16
		end
		local box = new("TextButton", {
			Position = UDim2.fromOffset(0, boxTop),
			Size = opts.gear and UDim2.new(1, -24, 0, 18) or UDim2.new(1, 0, 0, 18),
			BackgroundColor3 = Theme.Button,
			Text = "",
			AutoButtonColor = false,
		}, block)
		stroke(box, Theme.Border)
		local caption = new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(6, 0),
			Size = UDim2.new(1, -22, 1, 0),
			Font = FontMain,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Text,
			Text = "",
		}, box)
		pcall(function()
			caption.TextTruncate = Enum.TextTruncate.AtEnd
		end)
		chevron(box)
		local options = opts.options
		bindValue(opts.key, function(v)
			caption.Text = tostring(v)
			if opts.key == "profile" then
				State.ProfileName = tostring(v)
			end
		end)
		box.MouseEnter:Connect(function()
			tween(box, INFO_FAST, { BackgroundColor3 = Theme.ButtonHover })
		end)
		box.MouseLeave:Connect(function()
			tween(box, INFO_FAST, { BackgroundColor3 = Theme.Button })
		end)
		box.Activated:Connect(function()
			openDropdown(box, opts.key, options)
		end)
		local api = {}
		function api.setOptions(list)
			options = list
		end
		if opts.gear then
			local gear = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, boxTop + 2),
				Size = UDim2.fromOffset(20, 14),
				BackgroundColor3 = Theme.Button,
				Font = FontMain,
				TextSize = 12,
				TextColor3 = Theme.TextDim,
				Text = "...",
				AutoButtonColor = false,
			}, block)
			stroke(gear, Theme.Border)
			attachButton(gear, function()
				if opts.onGear then
					opts.onGear(gear)
				else
					openGear(gear, opts.key, opts.text or "Option")
				end
			end)
		end
		return api
	end

	local function createButton(parent, text, onClick)
		local btn = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = Theme.Button,
			Font = FontMain,
			TextSize = 12,
			TextColor3 = Theme.Text,
			Text = text,
			AutoButtonColor = false,
			LayoutOrder = nextOrder(),
		}, parent)
		stroke(btn, Theme.Border)
		attachButton(btn, onClick)
		return btn
	end

	local function createCenterButton(parent, text, onClick)
		local wrap = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = nextOrder(),
		}, parent)
		local btn = new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 4),
			Size = UDim2.fromOffset(168, 20),
			BackgroundColor3 = Theme.Button,
			Font = FontMain,
			TextSize = 12,
			TextColor3 = Theme.Text,
			Text = text,
			AutoButtonColor = false,
		}, wrap)
		stroke(btn, Theme.Border)
		attachButton(btn, onClick)
	end

	local rainbow = new("Frame", {
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 8,
		Active = false,
	}, Window)
	local rainbowGradient = Instance.new("UIGradient")
	rainbowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 55, 55)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 176, 40)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 210, 90)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(40, 196, 214)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(70, 108, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 50, 220)),
	})
	rainbowGradient.Parent = rainbow

	local function addEdge(parent, pos, size)
		new("Frame", {
			BackgroundColor3 = Theme.Border,
			Position = pos,
			Size = size,
			ZIndex = 5,
			Active = false,
		}, parent)
	end
	addEdge(Window, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 1))
	addEdge(Window, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1))
	addEdge(Window, UDim2.fromOffset(0, 0), UDim2.new(0, 1, 1, 0))
	addEdge(Window, UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0))

	local dragging = false
	local dragStart = Vector2.new()
	local startPos = UDim2.fromOffset(0, 0)
	local closeTween = nil

	local function beginDrag(input, scrollFrame)
		if destroyed or State.Values.lock_layout then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if scrollFrame then
			local limit = scrollFrame.AbsolutePosition.X + scrollFrame.AbsoluteSize.X - (scrollFrame.ScrollBarThickness + 6)
			if input.Position.X >= limit then
				return
			end
		end
		closePopups()
		local abs = Window.AbsolutePosition
		Window.AnchorPoint = Vector2.new(0, 0)
		Window.Position = UDim2.fromOffset(abs.X, abs.Y)
		dragging = true
		dragStart = Vector2.new(input.Position.X, input.Position.Y)
		startPos = Window.Position
	end

	local function enableDrag(obj, scrollFrame)
		obj.Active = true
		obj.InputBegan:Connect(function(input)
			beginDrag(input, scrollFrame)
		end)
	end

	enableDrag(Window)

	local sidebar = new("Frame", {
		BackgroundColor3 = Theme.Sidebar,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(0, SIDE, 1, -2),
		ZIndex = 3,
		Active = true,
	}, Window)
	enableDrag(sidebar)
	addEdge(sidebar, UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0))
	local highlight = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(32, 32, 32),
		Position = UDim2.fromOffset(4, 8),
		Size = UDim2.fromOffset(SIDE - 8, 30),
		ZIndex = 1,
		Active = false,
	}, sidebar)
	local sideHost = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Active = false,
	}, sidebar)
	new("UIListLayout", {
		Padding = UDim.new(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, sideHost)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
	}, sideHost)

	local tooltip = new("TextLabel", {
		BackgroundColor3 = Theme.Window,
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		Font = FontMain,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Text = "",
		ZIndex = 55,
		Active = false,
	}, Window)
	stroke(tooltip, Theme.Border)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	}, tooltip)

	local function makeGroup(parent, title, x, y, w, h)
		local root = new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			ZIndex = 3,
			Active = true,
		}, parent)
		addEdge(root, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 1))
		addEdge(root, UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1))
		addEdge(root, UDim2.fromOffset(0, 0), UDim2.new(0, 1, 1, 0))
		addEdge(root, UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0))
		local titleLabel = new("TextLabel", {
			BackgroundColor3 = Theme.Window,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(10, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 14),
			Font = FontTitle,
			TextSize = 13,
			TextColor3 = Theme.Title,
			Text = title,
			ZIndex = 6,
			Active = false,
		}, root)
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}, titleLabel)
		local host = new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(8, 12),
			Size = UDim2.new(1, -16, 1, -20),
			ZIndex = 4,
			Active = false,
		}, root)
		enableDrag(root)
		return root, host, titleLabel
	end

	local leftGroup, leftHost, leftTitle = makeGroup(Window, "Miscellaneous", SIDE + MARGIN, TOP, LEFT_W, COL_H)
	local settingsGroup, settingsHost = makeGroup(Window, "Settings", RIGHT_X, TOP, RIGHT_W, SETTINGS_H)
	local otherGroup, otherHost = makeGroup(Window, "Other", RIGHT_X, TOP + SETTINGS_H + GAP, RIGHT_W, COL_H - SETTINGS_H - GAP)

	local veil = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
		Active = false,
	}, leftGroup)

	local function makePage(parent, visible)
		local scroll = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70),
			Visible = visible and true or false,
			Active = true,
			ZIndex = 4,
		}, parent)
		pcall(function()
			scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			scroll.ElasticBehavior = Enum.ElasticBehavior.Never
			scroll.ScrollingDirection = Enum.ScrollingDirection.Y
			scroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		end)
		local layout = new("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, scroll)
		pageLayouts[#pageLayouts + 1] = layout
		new("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 2),
		}, scroll)
		enableDrag(scroll, scroll)
		return scroll
	end

	local pages = {}
	local titles = {
		rage = "Rage",
		antiaim = "Anti-aim",
		legit = "Legit",
		visuals = "Visuals",
		misc = "Miscellaneous",
		knife = "Knife",
		players = "Players",
	}

	pages.rage = makePage(leftHost, false)
	createCheckbox(pages.rage, { text = "Enabled", key = "rage_enabled" })
	createSlider(pages.rage, { text = "Smoothing", key = "rage_smooth", min = 0, max = 100, format = "pct" })
	createSlider(pages.rage, { text = "Field of view", key = "rage_fov", min = 0, max = 180, format = "deg" })
	createDropdown(pages.rage, {
		text = "Mode",
		key = "rage_mode",
		options = { "Off", "Static", "Dynamic" },
	})

	pages.antiaim = makePage(leftHost, false)
	createCheckbox(pages.antiaim, { text = "Enabled", key = "aa_enabled" })
	createSlider(pages.antiaim, { text = "Offset", key = "aa_offset", min = -180, max = 180, format = "deg" })
	createDropdown(pages.antiaim, {
		text = "Direction",
		key = "aa_dir",
		options = { "Off", "Left", "Right" },
	})

	pages.legit = makePage(leftHost, false)
	createCheckbox(pages.legit, { text = "Enabled", key = "legit_enabled" })
	createSlider(pages.legit, { text = "Smoothing", key = "legit_smooth", min = 0, max = 100, format = "pct" })
	createDropdown(pages.legit, {
		text = "Activation",
		key = "legit_activation",
		options = { "Off", "Hold", "Toggle" },
	})

	pages.visuals = makePage(leftHost, false)
	createSlider(pages.visuals, { text = "Menu opacity", key = "menu_opacity", min = 30, max = 100, format = "pct" })
	createCheckbox(pages.visuals, { text = "Animate controls", key = "animate" })
	createDropdown(pages.visuals, {
		text = "Density",
		key = "density",
		options = { "Regular", "Compact" },
	})

	pages.misc = makePage(leftHost, true)
	createSlider(pages.misc, { text = "Override FOV", key = "override_fov", min = 60, max = 120, format = "deg" })
	createCheckbox(pages.misc, { text = "Bunny hop", key = "bunny_hop" })
	createCheckbox(pages.misc, { text = "Air strafe", key = "air_strafe" })
	createDropdown(pages.misc, {
		text = "Air strafe direction",
		key = "air_strafe_dir",
		options = { "View angles", "Movement keys", "Camera" },
	})
	createSlider(pages.misc, { text = "Air strafe smoothing", key = "air_strafe_smooth", min = 0, max = 100, format = "pct" })
	createCheckbox(pages.misc, { text = "Z-Hop", key = "z_hop", gear = true })
	createCheckbox(pages.misc, { text = "Pre-speed", key = "pre_speed", gear = true })
	createDropdown(pages.misc, {
		text = "Air duck",
		key = "air_duck",
		options = { "Off", "On" },
	})
	createCheckbox(pages.misc, { text = "Knifebot", key = "knifebot" })
	createCheckbox(pages.misc, { text = "Zeusbot", key = "zeusbot" })
	createCheckbox(pages.misc, { text = "Blockbot", key = "blockbot", gear = true })
	createCheckbox(pages.misc, { text = "Automatic weapons", key = "automatic_weapons" })
	createSlider(pages.misc, { key = "auto_delay", min = 0, max = 250, format = "ms", inline = true })
	createCheckbox(pages.misc, { text = "Jump at edge", key = "jump_edge", gear = true })
	createCheckbox(pages.misc, { text = "Reveal competitive ranks", key = "reveal_ranks" })
	createCheckbox(pages.misc, { text = "Auto-accept matchmaking", key = "auto_accept" })
	createCheckbox(pages.misc, { text = "Log weapon purchases", key = "log_purchases" })
	createCheckbox(pages.misc, { text = "Log damage dealt", key = "log_damage" })
	createCheckbox(pages.misc, { text = "Automatic grenade release", key = "auto_grenade", gear = true })
	createCheckbox(pages.misc, { text = "Fast walk", key = "fast_walk" })
	createCheckbox(pages.misc, { text = "Free look", key = "free_look", gear = true })
	createCenterButton(pages.misc, "Steal player name", function()
		toastMsg("Visual control. Players are not modified.")
	end)

	pages.knife = makePage(leftHost, false)
	createDropdown(pages.knife, {
		text = "Model",
		key = "knife_model",
		options = { "Default", "Karambit", "Butterfly", "M9 Bayonet", "Skeleton" },
	})
	createSlider(pages.knife, { text = "Wear", key = "knife_wear", min = 0, max = 100, format = "pct" })
	local knifePreview = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.TextDim,
		Text = "",
		LayoutOrder = nextOrder(),
	}, pages.knife)
	local function paintKnife()
		knifePreview.Text = string.format(
			"Preview    %s    %s",
			tostring(State.Values.knife_model),
			formatValue(State.Values.knife_wear, "pct")
		)
	end
	watch("knife_model", paintKnife)
	watch("knife_wear", paintKnife)
	paintKnife()

	pages.players = makePage(leftHost, false)
	local playerRows = {}
	local playerNames = { "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot" }
	local function paintPlayers()
		local selected = math.clamp(math.floor(tonumber(State.Values.player_index) or 1), 1, #playerRows)
		for i = 1, #playerRows do
			local row = playerRows[i]
			local on = i == selected
			local target = on and Color3.fromRGB(36, 36, 36) or Color3.fromRGB(22, 22, 22)
			if State.Values.animate then
				tween(row.frame, INFO_FAST, { BackgroundColor3 = target })
				tween(row.bar, INFO_FAST, { BackgroundTransparency = on and 0 or 1 })
			else
				row.frame.BackgroundColor3 = target
				row.bar.BackgroundTransparency = on and 0 or 1
			end
		end
	end
	for i = 1, #playerNames do
		local row = new("TextButton", {
			BackgroundColor3 = Color3.fromRGB(22, 22, 22),
			Size = UDim2.new(1, 0, 0, 20),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = nextOrder(),
		}, pages.players)
		local bar = new("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 2, 1, 0),
		}, row)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -14, 1, 0),
			Font = FontMain,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.Text,
			Text = playerNames[i],
		}, row)
		playerRows[i] = { frame = row, bar = bar }
		local index = i
		row.Activated:Connect(function()
			setValue("player_index", index)
		end)
		onAccent(function()
			bar.BackgroundColor3 = Theme.Accent
		end)
	end
	watch("player_index", paintPlayers)
	paintPlayers()
	createButton(pages.players, "Refresh list", function()
		toastMsg("Visual list refreshed")
	end)

	local settingsPage = makePage(settingsHost, true)
	local capturingKey = false
	local keyRow = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = nextOrder(),
	}, settingsPage)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -70, 1, 0),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		Text = "Menu key",
	}, keyRow)
	local keyButton = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 16),
		BackgroundColor3 = Theme.Button,
		Font = FontMain,
		TextSize = 11,
		TextColor3 = Theme.Text,
		Text = "[INS]",
		AutoButtonColor = false,
	}, keyRow)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
	}, keyButton)
	stroke(keyButton, Theme.Border)

	local function paintMenuKey()
		if capturingKey then
			keyButton.Text = "[...]"
		else
			keyButton.Text = "[" .. prettyKey(State.MenuKey) .. "]"
		end
	end

	attachButton(keyButton, function()
		capturingKey = true
		paintMenuKey()
	end)

	local colorRow = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = nextOrder(),
	}, settingsPage)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 1, 0),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		Text = "Menu color",
	}, colorRow)
	local swatch = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(28, 10),
		BackgroundColor3 = Theme.Accent,
		Text = "",
		AutoButtonColor = false,
	}, colorRow)
	stroke(swatch, Theme.Border)
	swatch.Activated:Connect(function()
		openColor(swatch)
	end)
	onAccent(function()
		swatch.BackgroundColor3 = Theme.Accent
	end)

	createCheckbox(settingsPage, { text = "Anti-untrusted", key = "anti_untrusted" })
	createCheckbox(settingsPage, { text = "Hide from OBS", key = "hide_obs" })
	createCheckbox(settingsPage, { text = "Low FPS warning", key = "low_fps" })
	local fpsLabel = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Font = FontMain,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.TextDim,
		Text = "FPS  --",
		Visible = false,
		LayoutOrder = nextOrder(),
	}, settingsPage)

	local function setFpsWatch(on)
		if fpsConn then
			fpsConn:Disconnect()
			fpsConn = nil
		end
		if not on or destroyed then
			fpsLabel.Visible = false
			return
		end
		fpsLabel.Visible = true
		local acc = 0
		local frames = 0
		fpsConn = RunService.RenderStepped:Connect(function(dt)
			if destroyed then
				return
			end
			acc = acc + dt
			frames = frames + 1
			if acc >= 0.45 then
				local fps = math.floor(frames / acc + 0.5)
				fpsLabel.Text = "FPS  " .. tostring(fps)
				fpsLabel.TextColor3 = fps < 30 and Theme.Accent or Theme.TextDim
				acc = 0
				frames = 0
			end
		end)
	end

	watch("low_fps", function(v)
		setFpsWatch(v == true)
	end)

	createCheckbox(settingsPage, { text = "Lock menu layout", key = "lock_layout" })
	createCheckbox(settingsPage, { text = "Trashtalk", key = "trashtalk" })

	local otherPage = makePage(otherHost, true)

	local function ensureProfile(name)
		for i = 1, #profileNames do
			if profileNames[i] == name then
				return
			end
		end
		profileNames[#profileNames + 1] = name
		if profileApi then
			profileApi.setOptions(profileNames)
		end
	end

	local function applySnapshot(snap, quiet)
		if not snap then
			if not quiet then
				toastMsg("Nothing saved for this profile")
			end
			return false
		end
		for key, defaultValue in pairs(Defaults) do
			local incoming = snap.values[key]
			if incoming ~= nil and typeof(incoming) == typeof(defaultValue) then
				State.Values[key] = incoming
			else
				State.Values[key] = defaultValue
			end
		end
		ensureProfile(tostring(State.Values.profile))
		State.ProfileName = tostring(State.Values.profile)
		if snap.menuKey then
			local code = keyFromName(snap.menuKey)
			if code then
				State.MenuKey = code
			end
		end
		applyAccent(snap.accent or DEFAULT_ACCENT)
		paintMenuKey()
		pushAll()
		if not quiet then
			toastMsg("Configuration loaded")
		end
		return true
	end

	local function currentSnapshot()
		return {
			values = copyValues(),
			accent = Theme.Accent,
			menuKey = State.MenuKey.Name,
		}
	end

	profileApi = createDropdown(otherPage, {
		key = "profile",
		options = profileNames,
		gear = true,
		onGear = function(anchor)
			openRename(anchor)
		end,
	})

	local function writeClipboard(text)
		local setFn = optionalFn("setclipboard")
		if setFn then
			local ok = pcall(setFn, text)
			if ok then
				return true
			end
		end
		local toFn = optionalFn("toclipboard")
		if toFn then
			local ok = pcall(toFn, text)
			if ok then
				return true
			end
		end
		return false
	end

	local function readClipboard()
		local getFn = optionalFn("getclipboard")
		if getFn then
			local ok, text = pcall(getFn)
			if ok and type(text) == "string" and text ~= "" then
				return text
			end
		end
		return nil
	end

	local function importText(text)
		local values, accent, menuKey = parseConfig(text)
		if not values then
			return false
		end
		applySnapshot({
			values = values,
			accent = accent,
			menuKey = menuKey and menuKey.Name or nil,
		}, true)
		return true
	end

	createButton(otherPage, "Load config", function()
		applySnapshot(Profiles[State.ProfileName], false)
	end)
	createButton(otherPage, "Save config", function()
		Profiles[State.ProfileName] = currentSnapshot()
		toastMsg("Configuration saved")
	end)
	createButton(otherPage, "Reset config", function()
		local snap = {
			values = {},
			accent = DEFAULT_ACCENT,
			menuKey = "Insert",
		}
		for key, value in pairs(Defaults) do
			snap.values[key] = value
		end
		restoreProfileList(DEFAULT_PROFILES)
		Profiles = {}
		if profileApi then
			profileApi.setOptions(profileNames)
		end
		applySnapshot(snap, true)
		toastMsg("Configuration reset")
	end)
	createButton(otherPage, "Import from clipboard", function()
		local text = readClipboard()
		if text and importText(text) then
			State.Clip = text
			toastMsg("Imported from clipboard")
			return
		end
		if State.Clip ~= "" and importText(State.Clip) then
			toastMsg("Imported from the internal buffer")
			return
		end
		toastMsg("Clipboard does not contain a menu configuration")
	end)
	createButton(otherPage, "Export to clipboard", function()
		local text = serialize()
		State.Clip = text
		if writeClipboard(text) then
			toastMsg("Exported to clipboard")
		else
			toastMsg("No clipboard API. Stored in the internal buffer.")
		end
	end)
	createButton(otherPage, "Reset menu layout", function()
		dragging = false
		Window.AnchorPoint = Vector2.new(0.5, 0.5)
		Window.Position = UDim2.fromScale(0.5, 0.5)
		uiScale.Scale = 1
		toastMsg("Layout reset")
	end)
	createButton(otherPage, "Lua script manager", openScriptModal)
	createButton(otherPage, "Unload", cleanup)

	local function applyDensity(mode)
		local pad = mode == "Compact" and 1 or 2
		for i = 1, #pageLayouts do
			pageLayouts[i].Padding = UDim.new(0, pad)
		end
	end
	watch("density", function(v)
		applyDensity(v)
	end)
	applyDensity(State.Values.density)
	applyOpacity(State.Values.menu_opacity)
	setFpsWatch(State.Values.low_fps == true)

	local tabButtons = {}
	local currentTab = nil

	local function moveHighlight(btn, instant)
		local y = btn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y
		local h = btn.AbsoluteSize.Y
		if h <= 0 then
			return
		end
		local target = UDim2.fromOffset(4, y + (h - 30) / 2)
		if instant or not State.Values.animate then
			highlight.Position = target
		else
			tween(highlight, INFO_MED, { Position = target })
		end
	end

	local function selectTab(id, instant)
		if currentTab == id then
			return
		end
		currentTab = id
		for tabId, page in pairs(pages) do
			page.Visible = tabId == id
		end
		leftTitle.Text = titles[id] or id
		for tabId, data in pairs(tabButtons) do
			local color = tabId == id and Theme.IconActive or Theme.Icon
			if instant or not State.Values.animate then
				data.colorValue.Value = color
			else
				tween(data.colorValue, INFO_FAST, { Value = color })
			end
		end
		local selected = tabButtons[id]
		if selected then
			moveHighlight(selected.button, instant)
		end
		if not instant and State.Values.animate then
			veil.BackgroundTransparency = 0.4
			tween(veil, INFO_MED, { BackgroundTransparency = 1 })
		end
		tooltip.Visible = false
		closePopups()
	end

	local function addSeparator()
		local gap = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 10),
			LayoutOrder = nextOrder(),
			Active = false,
		}, sideHost)
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 1),
			BackgroundColor3 = Color3.fromRGB(42, 42, 42),
			Active = false,
		}, gap)
	end

	local tabDefs = {
		{ id = "rage", icon = "head" },
		{ id = "antiaim", icon = "antiaim" },
		{ id = "legit", icon = "crosshair" },
		{ id = "visuals", icon = "sun" },
		{ id = "misc", icon = "gears", separator = true },
		{ id = "knife", icon = "knife", separator = true },
		{ id = "players", icon = "player", separator = true },
	}

	for i = 1, #tabDefs do
		local def = tabDefs[i]
		if def.separator then
			addSeparator()
		end
		local btn = new("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(SIDE, 32),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = nextOrder(),
		}, sideHost)
		local holder, colorize = createIcon(def.icon)
		holder.Parent = btn
		local colorValue = Instance.new("Color3Value")
		colorValue.Value = def.id == "misc" and Theme.IconActive or Theme.Icon
		colorValue.Parent = btn
		colorize(colorValue.Value)
		colorValue:GetPropertyChangedSignal("Value"):Connect(function()
			colorize(colorValue.Value)
		end)
		tabButtons[def.id] = { button = btn, colorValue = colorValue }
		local tabId = def.id
		btn.Activated:Connect(function()
			selectTab(tabId, false)
		end)
		btn.MouseEnter:Connect(function()
			if currentTab ~= tabId and State.Values.animate then
				tween(colorValue, INFO_FAST, { Value = Color3.fromRGB(186, 186, 186) })
			end
			tooltip.Text = titles[tabId]
			local y = btn.AbsolutePosition.Y - Window.AbsolutePosition.Y + 7
			tooltip.Position = UDim2.fromOffset(SIDE + 6, y)
			tooltip.Visible = true
		end)
		btn.MouseLeave:Connect(function()
			tooltip.Visible = false
			if currentTab ~= tabId then
				local color = Theme.Icon
				if State.Values.animate then
					tween(colorValue, INFO_FAST, { Value = color })
				else
					colorValue.Value = color
				end
			end
		end)
	end

	currentTab = "misc"
	leftTitle.Text = "Miscellaneous"
	afterLayout(function()
		local selected = tabButtons.misc
		if selected then
			moveHighlight(selected.button, true)
		end
	end)

	local function setOpen(open, instant)
		if destroyed then
			return
		end
		if closeTween then
			closeTween:Cancel()
			closeTween = nil
		end
		State.Open = open
		if open then
			Window.Visible = true
			if instant or not State.Values.animate then
				uiScale.Scale = 1
			else
				uiScale.Scale = 0.965
				tween(uiScale, INFO_MED, { Scale = 1 })
			end
		else
			closePopups()
			tooltip.Visible = false
			if instant or not State.Values.animate then
				Window.Visible = false
				uiScale.Scale = 1
				return
			end
			closeTween = tween(uiScale, INFO_MED, { Scale = 0.965 })
			local tw = closeTween
			local conn
			conn = tw.Completed:Connect(function()
				conn:Disconnect()
				if destroyed or State.Open then
					return
				end
				if Window then
					Window.Visible = false
					uiScale.Scale = 1
				end
			end)
		end
	end

	local floatY = 14
	local parentIsPlayerGui = gui.Parent and gui.Parent:IsA("PlayerGui")
	if not parentIsPlayerGui then
		local okInset, inset = pcall(function()
			return GuiService:GetGuiInset()
		end)
		if okInset and inset then
			floatY = inset.Y + 10
		end
	end
	local floatBtn = new("TextButton", {
		Size = UDim2.fromOffset(32, 32),
		Position = UDim2.fromOffset(14, floatY),
		BackgroundColor3 = Theme.Window,
		Font = FontTitle,
		TextSize = 12,
		TextColor3 = Theme.Accent,
		Text = "GS",
		AutoButtonColor = false,
		ZIndex = 20,
	}, gui)
	local floatStroke = stroke(floatBtn, Theme.Accent)
	onAccent(function()
		floatStroke.Color = Theme.Accent
		floatBtn.TextColor3 = Theme.Accent
	end)
	floatBtn.MouseEnter:Connect(function()
		tween(floatBtn, INFO_FAST, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) })
	end)
	floatBtn.MouseLeave:Connect(function()
		tween(floatBtn, INFO_FAST, { BackgroundColor3 = Theme.Window })
	end)
	floatBtn.Activated:Connect(function()
		setOpen(not State.Open, false)
	end)

	track(UserInputService.InputBegan:Connect(function(input)
		if destroyed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if capturingKey then
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Unknown then
				capturingKey = false
				paintMenuKey()
				return
			end
			State.MenuKey = input.KeyCode
			capturingKey = false
			paintMenuKey()
			return
		end
		if input.KeyCode == State.MenuKey then
			setOpen(not State.Open, false)
		end
	end))

	track(UserInputService.InputChanged:Connect(function(input)
		if destroyed then
			return
		end
		if dragging then
			if State.Values.lock_layout then
				dragging = false
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end
			local pos = Vector2.new(input.Position.X, input.Position.Y)
			local delta = pos - dragStart
			Window.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		elseif dragOwner and input.UserInputType == Enum.UserInputType.MouseMovement then
			dragOwner(input)
		end
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			dragOwner = nil
		end
	end))

	pcall(function()
		gui.Destroying:Connect(function()
			if destroyed then
				return
			end
			destroyed = true
			disconnectAll()
			ENV.__GameSenseUIDestroy = nil
			screenGui = nil
		end)
	end)

	if State.Values.animate then
		uiScale.Scale = 0.965
		tween(uiScale, INFO_MED, { Scale = 1 })
	end

	ENV.__GameSenseUIDestroy = cleanup
end

local ok, err = pcall(build)
if not ok then
	warn("[GameSense_UI] No se pudo crear la interfaz: " .. tostring(err))
	pcall(cleanup)
end
