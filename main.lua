-- Maqueta VISUAL para Roblox Studio (LocalScript).
-- No ejecuta funciones de juego ni automatiza acciones.
local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local MAGENTA = Color3.fromRGB(198, 0, 210)
local BG = Color3.fromRGB(9, 9, 10)
local PANEL = Color3.fromRGB(10, 10, 11)
local TEXT = Color3.fromRGB(207, 207, 210)
local EDGE = Color3.fromRGB(58, 58, 60)

local gui = Instance.new("ScreenGui")
gui.Name = "LuaInterfaceMockup"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = playerGui
local root = Instance.new("Frame")
root.Name = "Window"
root.Size = UDim2.fromOffset(657, 553)
root.Position = UDim2.new(0.5, -328, 0.5, -276)
root.BackgroundColor3 = BG
root.BorderColor3 = Color3.fromRGB(90, 90, 92)
root.Parent = gui

local function frame(parent, name, x, y, w, h, color, border)
 local f = Instance.new("Frame")
 f.Name=name; f.Position=UDim2.fromOffset(x,y); f.Size=UDim2.fromOffset(w,h)
 f.BackgroundColor3=color; f.BorderColor3=border or EDGE; f.BorderSizePixel=1; f.Parent=parent
 return f
end
local function text(parent, value, x, y, w, h, size, bold, center)
 local t=Instance.new("TextLabel")
 t.BackgroundTransparency=1; t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h)
 t.Font=bold and Enum.Font.GothamSemibold or Enum.Font.Gotham
 t.TextSize=size or 11; t.TextColor3=TEXT; t.TextXAlignment=center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
 t.TextYAlignment=Enum.TextYAlignment.Center; t.Text=value; t.Parent=parent
 return t
end
local function button(parent, value, x, y, w, h, callback)
 local b=Instance.new("TextButton")
 b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(w,h); b.BackgroundColor3=Color3.fromRGB(31,31,33)
 b.BorderColor3=Color3.fromRGB(63,63,65); b.Font=Enum.Font.Gotham; b.TextSize=11; b.TextColor3=Color3.fromRGB(235,235,237)
 b.Text=value; b.AutoButtonColor=true; b.Parent=parent
 if callback then b.Activated:Connect(callback) end
 return b
end
local function checkbox(parent, value, x, y, checked)
 local b=Instance.new("TextButton"); b.Position=UDim2.fromOffset(x,y+3); b.Size=UDim2.fromOffset(8,8)
 b.BackgroundColor3=checked and MAGENTA or Color3.fromRGB(24,24,25); b.BorderColor3=Color3.fromRGB(67,67,69); b.Text=""; b.Parent=parent
 text(parent,value,x+18,y,205,15,10,false,false)
 b.Activated:Connect(function() b.BackgroundColor3=(b.BackgroundColor3==MAGENTA) and Color3.fromRGB(24,24,25) or MAGENTA end)
 return b
end
-- Top color line and side rail
frame(root,"TopAccent",0,0,657,2,Color3.fromRGB(65,130,138),Color3.fromRGB(65,130,138))
frame(root,"Sidebar",2,5,75,545,Color3.fromRGB(12,12,13),Color3.fromRGB(48,48,50))
local nav={{"●",52},{"◉",127},{"⊕",201},{"☼",276},{"⚙",350},{"⌁",438},{"●",500}}
for i,n in ipairs(nav) do
 if i==5 or i==6 then frame(root,"NavTile",4,n[2]-34,72,70,BG,EDGE) end
 local t=text(root,n[1],15,n[2]-17,48,36,27,true,true); t.TextColor3=Color3.fromRGB(113,113,116)
end
-- Three panes
frame(root,"MiscPane",98,26,258,504,PANEL,EDGE)
frame(root,"SettingsPane",375,26,256,154,PANEL,EDGE)
frame(root,"OtherPane",375,201,256,329,PANEL,EDGE)
frame(root,"Divider",360,26,10,504,BG,Color3.fromRGB(35,35,37))
text(root,"Miscellaneous",112,17,150,18,11,true,false)
text(root,"Settings",388,20,130,18,11,true,false)
text(root,"Other",388,196,100,18,11,true,false)
-- Left pane: reference-matched rows
text(root,"Override FOV",139,43,150,16,10,false,false)
frame(root,"FOVTrack",139,64,157,5,Color3.fromRGB(67,67,69),Color3.fromRGB(67,67,69))
frame(root,"FOVValue",139,64,133,5,MAGENTA,MAGENTA); text(root,"115°",260,57,36,12,9,false,false)
local leftChecks={{"Bunny hop",81,true},{"Air strafe",99,true},{"Z-Hop",188,false},{"Pre-speed",206,false},{"Knifebot",261,true},{"Zeusbot",280,true},{"Blockbot",298,false},{"Automatic weapons",316,true},{"Jump at edge",350,false},{"Reveal competitive ranks",369,false},{"Auto-accept matchmaking",388,false},{"Log weapon purchases",407,true},{"Log damage dealt",425,true},{"Automatic grenade release",444,false},{"Fast walk",462,false}}
for _,r in ipairs(leftChecks) do checkbox(root,r[1],120,r[2],r[3]) end
text(root,"Air strafe direction",139,111,160,16,10,false,false)
button(root,"View angles",139,129,157,19,function() end)
text(root,"Air strafe smoothing",139,149,160,16,10,false,false)
text(root,"0%",139,168,40,12,9,false,false)
frame(root,"SmoothTrack",139,169,157,5,Color3.fromRGB(67,67,69),Color3.fromRGB(67,67,69))
text(root,"Air duck",139,218,120,15,10,false,false)
button(root,"Off",139,236,157,19,function() end)
text(root,"0ms",139,328,45,13,9,false,false)
frame(root,"DelayTrack",139,344,157,5,Color3.fromRGB(67,67,69),Color3.fromRGB(67,67,69))
text(root,"Free look",139,475,100,15,10,false,false)
button(root,"Steal player name",139,489,157,23,function() end)
-- Settings pane
text(root,"Menu key",415,43,120,16,10,false,false); text(root,"[INS]",592,43,30,16,9,false,false)
text(root,"Menu color",415,60,120,16,10,false,false); frame(root,"AccentSwatch",594,68,17,8,MAGENTA,MAGENTA)
local rightChecks={{"Anti-untrusted",83,true},{"Hide from OBS",102,false},{"Low FPS warning",121,false},{"Lock menu layout",140,false},{"TrashTalk",159,false}}
for _,r in ipairs(rightChecks) do checkbox(root,r[1],397,r[2],r[3]) end
-- Other pane selector and inert demo buttons
button(root,"Rage",417,221,157,19,function() end)
text(root,"⌄",558,222,12,16,10,false,false); text(root,"[-]",600,219,25,14,9,false,false)
local actions={"Load config","Save config","Reset config","Import from clipboard","Export to clipboard","Reset menu layout","Lua script manager","Unload"}
for i,name in ipairs(actions) do button(root,name,417,246+(i-1)*33,157,24,function() end) end
