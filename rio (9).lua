-- ==========================================
-- NeoAim v1.0 | Educational Camera Lock GUI
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ CONFIGURACIÓN ]
local Settings = {
    Enabled = false,
    FOV = 150,          -- Radio en píxeles desde el centro de la pantalla
    Smoothness = 0.35,  -- 0.1 (lento) a 1.0 (instantáneo)
    TeamCheck = true,   -- Ignorar compañeros de equipo
    ToggleKey = Enum.KeyCode.RightShift
}

-- [ PROTECCIÓN DE ENTORNO ]
local GuiParent = game:GetService("CoreGui")
pcall(function()
    if not GuiParent then GuiParent = LocalPlayer:WaitForChild("PlayerGui") end
end)

-- Limpiar GUIs anteriores si se re-ejecuta
for _, v in ipairs(GuiParent:GetChildren()) do
    if v.Name == "NeoAim_GUI" then v:Destroy() end
end

-- ==========================================
-- [ CONSTRUCCIÓN DE LA INTERFAZ ]
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeoAim_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 140)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -70)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 200) -- Cian Neón
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.2
UIStroke.Parent = MainFrame

-- Barra Superior (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 28, 40)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar
-- Fix para esquinas inferiores de la TopBar
local TopBarFix = Instance.new("Frame")
TopBarFix.Size = UDim2.new(1, 0, 0, 10)
TopBarFix.Position = UDim2.new(0, 0, 1, -10)
TopBarFix.BackgroundColor3 = TopBar.BackgroundColor3
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NeoAim <font color=\"#00FFC8\">v1.0</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Botón de Toggle
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 200, 0, 35)
ToggleBtn.Position = UDim2.new(0.5, -100, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Rojo (Off)
ToggleBtn.Text = "AIMBOT: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- Label de Estado / Info
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 40)
InfoLabel.Position = UDim2.new(0, 10, 0, 90)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "FOV: " .. Settings.FOV .. "px\nSmooth: " .. Settings.Smoothness
InfoLabel.TextColor3 = Color3.fromRGB(150, 155, 170)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 12
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = MainFrame

-- ==========================================
-- [ LÓGICA DE ARRASTRE (DRAG) ]
-- ==========================================
local dragging, dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- [ LÓGICA DEL AIMBOT (CAMERA LOCK) ]
-- ==========================================
local function GetClosestTarget()
    local closestTarget = nil
    local closestDistance = Settings.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character:FindFirstChild("Head")
            
            -- Team Check básico
            local isEnemy = true
            if Settings.TeamCheck and player.Team == LocalPlayer.Team and LocalPlayer.Team ~= nil then
                isEnemy = false
            end

            if head and humanoid and humanoid.Health > 0 and isEnemy then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestTarget = head
                    end
                end
            end
        end
    end
    return closestTarget
end

RunService.RenderStepped:Connect(function()
    if Settings.Enabled then
        local target = GetClosestTarget()
        if target then
            -- Calcular CFrame objetivo mirando a la cabeza
            local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            -- Interpolar (Smoothness) para evitar movimientos bruscos
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Smoothness)
        end
    end
end)

-- ==========================================
-- [ EVENTOS DE INTERFAZ Y TECLADO ]
-- ==========================================
local function ToggleAimbot()
    Settings.Enabled = not Settings.Enabled
    
    -- Animación de color del botón
    local targetColor = Settings.Enabled and Color3.fromRGB(0, 200, 150) or Color3.fromRGB(200, 50, 50)
    local targetText = Settings.Enabled and "AIMBOT: ON" or "AIMBOT: OFF"
    
    TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    ToggleBtn.Text = targetText
end

ToggleBtn.MouseButton1Click:Connect(ToggleAimbot)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.ToggleKey then
        ToggleAimbot()
    end
end)

print("[NeoAim] Interfaz cargada correctamente. Presiona RightShift o usa el botón.")
