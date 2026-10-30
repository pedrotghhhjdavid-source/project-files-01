-- Réplica visual de una interfaz tipo GameSense basada en la referencia.
-- Es una maqueta: no se conecta ni actúa sobre ningún juego.
local W,H=657,553
local ui={checks={},scroll=0, color={.78,.02,.80}, msg=""}
local rows={
 {"slider","Override FOV","115°"},{"check","Bunny hop",true},{"check","Air strafe",true},
 {"label","Air strafe direction"},{"select","View angles"},{"label","Air strafe smoothing"},{"meter","0%"},
 {"check","Z-Hop"},{"check","Pre-speed"},{"label","Air duck"},{"select","Off"},
 {"check","Knifebot",true},{"check","Zeusbot",true},{"check","Blockbot"},{"check","Automatic weapons",true},
 {"meter","0ms"},{"check","Jump at edge"},{"check","Reveal competitive ranks"},
 {"check","Auto-accept matchmaking"},{"check","Log weapon purchases",true},{"check","Log damage dealt",true},
 {"check","Automatic grenade release"},{"check","Fast walk"},{"label","Free look"},{"button","Steal player name"}}
local opts={{"Anti-untrusted",true},{"Hide from OBS"},{"Low FPS warning"},{"Lock menu layout"},{"TrashTalk"}}
local actions={"Load config","Save config","Reset config","Import from clipboard","Export to clipboard","Reset menu layout","Lua script manager","Unload"}
local function setc(c) love.graphics.setColor(c[1],c[2],c[3],c[4] or 1) end
local function box(x,y,w,h,fill,edge)
 setc(fill); love.graphics.rectangle("fill",x,y,w,h)
 if edge then setc(edge); love.graphics.setLineWidth(1); love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1) end
end
local function label(s,x,y,c,f) setc(c or {.78,.78,.78,1}); love.graphics.setFont(f or ui.font); love.graphics.print(s,x,y) end
local function hit(x,y,w,h,fn) ui.hits[#ui.hits+1]={x=x,y=y,w=w,h=h,fn=fn} end
local function check(s,x,y,key,default)
 box(x,y+3,7,7,{.13,.13,.14,1},{.25,.25,.26,1})
 local v=ui.checks[key]; if v==nil then v=default end
 if v then box(x+1,y+4,5,5,ui.color) end
 label(s,x+17,y,{.81,.81,.81,1},ui.font)
 hit(x,y,215,17,function() ui.checks[key]=not v end)
end
function love.load()
 love.window.setMode(W,H,{resizable=true,minwidth=590,minheight=500})
 love.window.setTitle("Lua interface mockup")
 ui.font=love.graphics.newFont(11); ui.small=love.graphics.newFont(9); ui.bold=love.graphics.newFont(11,"bold")
 love.graphics.setBackgroundColor(.025,.025,.027)
end
function love.draw()
 local sw,sh=love.graphics.getDimensions(); love.graphics.push(); love.graphics.scale(sw/W,sh/H); ui.hits={}
 local bg={.035,.035,.038,1}; local panel={.035,.035,.038,1}; local edge={.23,.23,.24,1}; local white={.81,.81,.82,1}
 -- Fine colored top edge and outer frame
 box(1,1,W-2,2,{.18,.48,.52,1}); box(0,3,W,1,{.39,.13,.43,1}); box(1,4,W-2,H-5,bg,{.27,.27,.28,1})
 -- Left icon rail
 box(2,5,75,545,{.045,.045,.048,1},{.20,.20,.21,1})
 -- subtle separators and icon glyphs
 local centers={52,127,201,276,350,425,500}
 for i,y in ipairs(centers) do
  if i==5 or i==6 then box(4,y-34,72,70,{.035,.035,.038,1},{.22,.22,.23,1}) end
 end
 -- icons, drawn as simple monochrome shapes
 setc({.38,.38,.39,1}); love.graphics.setLineWidth(2)
 -- skull-like emblem
 love.graphics.circle("fill",34,51,13); love.graphics.rectangle("fill",27,60,14,6); setc(bg); love.graphics.circle("fill",30,49,2); love.graphics.circle("fill",39,49,2)
 -- crossed globe
 setc({.38,.38,.39,1}); love.graphics.circle("line",40,127,18); love.graphics.arc("line","open",40,127,12,0,math.pi*2); love.graphics.line(24,116,55,138); love.graphics.line(54,116,25,139)
 -- crosshair
 love.graphics.circle("line",39,201,18); love.graphics.line(17,201,61,201); love.graphics.line(39,179,39,223); love.graphics.circle("line",39,201,4)
 -- sun
 love.graphics.circle("line",39,276,13); love.graphics.line(39,253,39,263); love.graphics.line(39,289,39,299); love.graphics.line(16,276,27,276); love.graphics.line(51,276,62,276); love.graphics.line(23,260,29,266); love.graphics.line(49,286,56,293)
 -- gear pair
 love.graphics.print("⚙",19,326); love.graphics.print("⚙",38,341)
 -- knife / person glyphs
 love.graphics.line(20,438,54,429); love.graphics.line(20,438,50,444); love.graphics.circle("fill",39,486,10); love.graphics.arc("line","open",39,510,17,math.pi,2*math.pi)
 -- content column boxes
 box(98,26,258,504,panel,edge); box(375,26,256,154,panel,edge); box(375,201,256,329,panel,edge)
 box(360,26,10,504,{.035,.035,.038,1},{.12,.12,.13,1})
 label("Miscellaneous",112,20,white,ui.bold); label("Settings",388,23,white,ui.bold); label("Other",388,199,white,ui.bold)
 -- left list clipped to panel
 love.graphics.setScissor(101,31,251,494)
 local rowY={48,81,99,117,130,154,171,188,206,223,236,261,280,298,316,333,350,369,388,407,425,444,462,480,489}
 for i,r in ipairs(rows) do
  local y=rowY[i]-ui.scroll
  local kind,name,val=r[1],r[2],r[3]
  if kind=="slider" then
   label(name,139,y,{.82,.82,.82,1}); box(139,y+17,157,5,{.28,.28,.29,1}); box(139,y+17,132,5,ui.color); label(val,261,y+6,white,ui.small)
   hit(139,y+12,157,15,function() ui.drag=true end)
  elseif kind=="check" then check(name,120,y,"l"..i,val)
  elseif kind=="label" then label(name,139,y,{.78,.78,.78,1})
  elseif kind=="select" then box(139,y-1,157,19,{.12,.12,.12,1},{.21,.21,.22,1}); label(name,149,y+2,{.67,.67,.67,1}); label("⌄",282,y+1,{.65,.65,.65,1})
  elseif kind=="meter" then label(name,139,y,{.78,.78,.78,1}); box(139,y+13,157,4,{.27,.27,.28,1}); box(139,y+13,6,4,ui.color)
  elseif kind=="button" then box(139,y,157,23,{.12,.12,.13,1},{.24,.24,.25,1}); label(name,174,y+5,white); hit(139,y,157,23,function() ui.msg="Demostración visual" end) end
 end
 love.graphics.setScissor()
 -- Settings
 label("Menu key",415,49); label("[INS]",592,49,{.55,.55,.56,1},ui.small)
 label("Menu color",415,66); box(594,69,17,8,ui.color)
 for i,o in ipairs(opts) do check(o[1],397,83+(i-1)*19,"s"..i,o[2]) end
 -- Other menu selector and action buttons
 box(417,221,157,19,{.12,.12,.12,1},{.21,.21,.22,1}); label("Rage",429,224,{.73,.73,.73,1}); label("⌄",562,223,{.65,.65,.65,1}); label("[ ]",600,221,{.65,.65,.65,1},ui.small)
 for i,s in ipairs(actions) do local yy=246+(i-1)*33; box(417,yy,157,24,{.12,.12,.13,1},{.23,.23,.24,1}); label(s, (574-417-love.graphics.getFont():getWidth(s))/2+417, yy+6,white); hit(417,yy,157,24,function() ui.msg=s.." (maqueta)" end) end
 if ui.msg~="" then label(ui.msg,378,538,{.72,.35,.74,1},ui.small) end
 love.graphics.pop()
end
function love.mousepressed(x,y,b)
 if b~=1 then return end; local sw,sh=love.graphics.getDimensions(); x=x*W/sw; y=y*H/sh
 for _,h in ipairs(ui.hits or {}) do if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then h.fn(); return end end
end
function love.mousemoved(x,y)
 if ui.drag and love.mouse.isDown(1) then local sw=love.graphics.getWidth(); ui.fov=math.max(0,math.min(1,(x*W/sw-139)/157)) end
end
function love.mousereleased() ui.drag=false end
function love.wheelmoved(_,dy) ui.scroll=math.max(0,math.min(180,ui.scroll-dy*20)) end
