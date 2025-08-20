--[[
   🔥 Premium Loader - Speed + ESP Player (menu draggable + toggle "$")
   Fix drag/position + toggle fiable
   Dernière màj: 2025-08-20
]]

if _G.__PREMIUM_MENU_LOADED then return end
_G.__PREMIUM_MENU_LOADED = true

-- ============== Services & utils ==============
local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local RS      = game:GetService("RunService")
local TS      = game:GetService("TweenService")

local LP = Players.LocalPlayer
local function char() return LP.Character or LP.CharacterAdded:Wait() end
local function hum()  return (char()):WaitForChild("Humanoid") end

local function safeParent(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    gui.Parent = ok and core or LP:WaitForChild("PlayerGui")
end

local function tween(o,t,p)
    return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
end

-- ============== State ==============
local S = {
    uiVisible = true,
    speedEnabled = false,
    speed = 22, minSpeed = 16, maxSpeed = 100,
    espWanted = false, espLoaded = false,
    esp = { Boxes=true, Names=true, TeamColors=true, Tracers=false },
    con = {},
    humanoid=nil, normalSpeed=nil
}

-- ============== UI ==============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Premium_Menu_UI"
safeParent(ScreenGui)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(380, 270)
Main.BackgroundColor3 = Color3.fromRGB(18,18,20)
Main.BorderSizePixel = 0
Main.Active = true -- pour recevoir l’input même si transparent
Main.ClipsDescendants = false
Main.Parent = ScreenGui

-- centrer proprement au spawn
do
    local cam = workspace.CurrentCamera
    local vs = cam.ViewportSize
    Main.Position = UDim2.fromOffset(math.floor(vs.X/2 - Main.Size.X.Offset/2), math.floor(vs.Y/2 - Main.Size.Y.Offset/2))
end

local Corner = Instance.new("UICorner", Main) Corner.CornerRadius = UDim.new(0,16)
local Stroke = Instance.new("UIStroke", Main) Stroke.Thickness = 1.5 Stroke.Transparency = 0.15 Stroke.Color = Color3.fromRGB(255,255,255)

local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.ZIndex = 0
Shadow.Image = "rbxassetid://5028857084"
Shadow.ImageTransparency = 0.4
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(24,24,276,276)
Shadow.AnchorPoint = Vector2.new(0.5,0.5)
Shadow.Position = UDim2.fromScale(0.5,0.5)
Shadow.Size = UDim2.new(1, 32, 1, 32)
Shadow.BackgroundTransparency = 1
Shadow.Parent = Main

-- Header (barre de drag)
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1,0,0,44)
Header.BackgroundTransparency = 1
Header.Active = true
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(14, 6)
Title.Size = UDim2.fromOffset(250, 32)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Text = "⚡ Premium Hub — Speed & ESP"
Title.Parent = Header

local Hint = Instance.new("TextLabel")
Hint.BackgroundTransparency = 1
Hint.AnchorPoint = Vector2.new(1,0)
Hint.Position = UDim2.new(1,-12,0,10)
Hint.Size = UDim2.fromOffset(150, 24)
Hint.Font = Enum.Font.Gotham
Hint.TextSize = 14
Hint.TextXAlignment = Enum.TextXAlignment.Right
Hint.TextColor3 = Color3.fromRGB(180,180,190)
Hint.Text = 'Touche: "$" (⇧+4)  • F2 secours'
Hint.Parent = Header

local Sep = Instance.new("Frame")
Sep.BackgroundColor3 = Color3.fromRGB(45,45,52)
Sep.Size = UDim2.new(1, -24, 0, 1)
Sep.Position = UDim2.fromOffset(12, 44)
Sep.BorderSizePixel = 0
Sep.Parent = Main

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.BackgroundTransparency = 1
Content.Position = UDim2.fromOffset(12, 56)
Content.Size = UDim2.new(1, -24, 1, -68)
Content.Parent = Main

local UIList = Instance.new("UIListLayout")
UIList.Parent = Content
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,10)

-- ===== helpers UI =====
local function makeCard(titleText, subtitleText)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1,0,0,104)
    Card.BackgroundColor3 = Color3.fromRGB(24,24,28)
    Card.BorderSizePixel = 0
    Card.Active = true
    local c = Instance.new("UICorner", Card) c.CornerRadius = UDim.new(0,12)
    local s = Instance.new("UIStroke", Card) s.Thickness = 1 s.Transparency = 0.25 s.Color = Color3.fromRGB(255,255,255)

    local T = Instance.new("TextLabel")
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.GothamSemibold
    T.TextSize = 16
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.TextColor3 = Color3.fromRGB(235,235,240)
    T.Text = titleText
    T.Position = UDim2.fromOffset(12,8)
    T.Size = UDim2.fromOffset(260,20)
    T.Parent = Card

    local ST = Instance.new("TextLabel")
    ST.BackgroundTransparency = 1
    ST.Font = Enum.Font.Gotham
    ST.TextSize = 13
    ST.TextXAlignment = Enum.TextXAlignment.Left
    ST.TextColor3 = Color3.fromRGB(170,170,182)
    ST.Text = subtitleText or ""
    ST.Position = UDim2.fromOffset(12,28)
    ST.Size = UDim2.fromOffset(300,18)
    ST.Parent = Card

    return Card, T, ST
end

local function makeToggle(parent, defaultOn)
    local Btn = Instance.new("TextButton")
    Btn.AutoButtonColor = false
    Btn.AnchorPoint = Vector2.new(1,0)
    Btn.Position = UDim2.new(1,-10,0,10)
    Btn.Size = UDim2.fromOffset(64,28)
    Btn.BackgroundColor3 = defaultOn and Color3.fromRGB(60,200,110) or Color3.fromRGB(60,60,68)
    Btn.Text = ""
    Btn.Parent = parent

    local c = Instance.new("UICorner", Btn) c.CornerRadius = UDim.new(1,0)
    local s = Instance.new("UIStroke", Btn) s.Thickness = 1 s.Transparency = .2 s.Color = Color3.fromRGB(255,255,255)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(26,26)
    Knob.Position = defaultOn and UDim2.fromOffset(64-28,1) or UDim2.fromOffset(1,1)
    Knob.BackgroundColor3 = Color3.fromRGB(240,240,245)
    Knob.Parent = Btn
    local kc = Instance.new("UICorner", Knob) kc.CornerRadius = UDim.new(1,0)

    local function setOn(on)
        tween(Btn, .15, {BackgroundColor3 = on and Color3.fromRGB(60,200,110) or Color3.fromRGB(60,60,68)}):Play()
        tween(Knob, .15, {Position = on and UDim2.fromOffset(64-28,1) or UDim2.fromOffset(1,1)}):Play()
    end

    return Btn, setOn
end

local function makeSlider(parent, title, minV, maxV, defaultV, onChanged)
    local Wrap = Instance.new("Frame")
    Wrap.BackgroundTransparency = 1
    Wrap.Size = UDim2.new(1,0,0,64)
    Wrap.Position = UDim2.fromOffset(0,36)
    Wrap.Parent = parent

    local T = Instance.new("TextLabel")
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.Gotham
    T.TextSize = 14
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.TextColor3 = Color3.fromRGB(200,200,210)
    T.Text = string.format("%s: %d", title, defaultV)
    T.Position = UDim2.fromOffset(12,0)
    T.Size = UDim2.fromOffset(260,20)
    T.Parent = Wrap

    local Bar = Instance.new("Frame")
    Bar.BackgroundColor3 = Color3.fromRGB(45,45,55)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.fromOffset(12,26)
    Bar.Size = UDim2.new(1,-24,0,8)
    Bar.Parent = Wrap
    local bc = Instance.new("UICorner", Bar) bc.CornerRadius = UDim.new(0,6)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Color3.fromRGB(110,170,255)
    Fill.BorderSizePixel = 0
    Fill.Size = UDim2.fromOffset(0,8)
    Fill.Parent = Bar
    local fc = Instance.new("UICorner", Fill) fc.CornerRadius = UDim.new(0,6)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(14,14)
    Knob.Position = UDim2.fromOffset(-7,-3)
    Knob.BackgroundColor3 = Color3.fromRGB(240,240,245)
    Knob.Parent = Fill
    local kc = Instance.new("UICorner", Knob) kc.CornerRadius = UDim.new(1,0)

    local dragging = false
    local function setFromX(px)
        local abs = Bar.AbsoluteSize.X
        local rel = math.clamp(px/abs, 0, 1)
        local val = math.floor(minV + (maxV-minV)*rel + 0.5)
        local w = math.floor(abs*rel + 0.5)
        Fill.Size = UDim2.fromOffset(w, 8)
        Knob.Position = UDim2.fromOffset(w-7, -3)
        T.Text = string.format("%s: %d", title, val)
        if onChanged then onChanged(val) end
    end

    -- init fiable (attend un frame pour avoir AbsoluteSize)
    RS.Heartbeat:Wait()
    local rel = (defaultV - minV) / (maxV - minV)
    setFromX(Bar.AbsoluteSize.X * rel)

    Bar.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX((io.Position.X - Bar.AbsolutePosition.X))
        end
    end)
    UIS.InputChanged:Connect(function(io)
        if dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
            setFromX((io.Position.X - Bar.AbsolutePosition.X))
        end
    end)
    UIS.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return { setValue = function(v)
        v = math.clamp(v, minV, maxV)
        local rel2 = (v - minV) / (maxV - minV)
        setFromX(Bar.AbsoluteSize.X * rel2)
    end }
end

-- ===== Cartes =====
local SpeedCard = (function()
    local Card, T, ST = makeCard("Speed", "Sprint constant (anti-reset + respawn)")
    Card.Parent = Content
    local Toggle, setT = makeToggle(Card, false)
    local Slider = makeSlider(Card, "Vitesse", S.minSpeed, S.maxSpeed, S.speed, function(v) S.speed = v end)

    Toggle.MouseButton1Click:Connect(function()
        S.speedEnabled = not S.speedEnabled
        setT(S.speedEnabled)
        if S.speedEnabled then
            local h = hum(); S.humanoid = h; S.normalSpeed = h.WalkSpeed
            if S.con.hb then S.con.hb:Disconnect() end
            if S.con.anti then S.con.anti:Disconnect() end
            S.con.hb = RS.Heartbeat:Connect(function()
                if S.speedEnabled and S.humanoid and S.humanoid.Parent and S.humanoid.WalkSpeed ~= S.speed then
                    S.humanoid.WalkSpeed = S.speed
                end
            end)
            S.con.anti = h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if S.speedEnabled and h.WalkSpeed ~= S.speed then h.WalkSpeed = S.speed end
            end)
        else
            if S.con.hb then S.con.hb:Disconnect() S.con.hb=nil end
            if S.con.anti then S.con.anti:Disconnect() S.con.anti=nil end
            local h = S.humanoid or (char():FindFirstChildOfClass("Humanoid"))
            if h then h.WalkSpeed = S.normalSpeed or 16 end
        end
    end)

    LP.CharacterAdded:Connect(function()
        if S.speedEnabled then task.wait(.3); local h = hum(); S.humanoid=h; S.normalSpeed=h.WalkSpeed end
    end)

    return Card
end)()

local ESPCard = (function()
    local Card, T, ST = makeCard("ESP Player", "Boxes, Names, Team Colors, Tracers")
    Card.Parent = Content
    local Toggle, setT = makeToggle(Card, false)

    local Opts = Instance.new("Frame")
    Opts.BackgroundTransparency = 1
    Opts.Position = UDim2.fromOffset(12, 52)
    Opts.Size = UDim2.new(1, -24, 0, 28)
    Opts.Parent = Card
    local HL = Instance.new("UIListLayout", Opts)
    HL.FillDirection = Enum.FillDirection.Horizontal
    HL.Padding = UDim.new(0,8)

    local function mini(label, def, cb)
        local Wrap = Instance.new("Frame")
        Wrap.BackgroundTransparency = 1
        Wrap.Size = UDim2.fromOffset(150,28)
        Wrap.Parent = Opts

        local L = Instance.new("TextLabel")
        L.BackgroundTransparency = 1
        L.Font = Enum.Font.Gotham
        L.TextSize = 13
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.TextColor3 = Color3.fromRGB(200,200,210)
        L.Text = label
        L.Position = UDim2.fromOffset(0,5)
        L.Size = UDim2.fromOffset(88,18)
        L.Parent = Wrap

        local Btn, setOn = makeToggle(Wrap, def)
        Btn.Position = UDim2.new(1,-56,0,0)
        Btn.Size = UDim2.fromOffset(56,24)
        Btn.MouseButton1Click:Connect(function()
            def = not def
            setOn(def); if cb then cb(def) end
        end)
        setOn(def)
        return function(on) def=on; setOn(on); if cb then cb(on) end end
    end

    local setBoxes   = mini("Boxes",   S.esp.Boxes,   function(v) S.esp.Boxes=v; _G.WRDESPBoxes=v end)
    local setNames   = mini("Names",   S.esp.Names,   function(v) S.esp.Names=v; _G.WRDESPNames=v end)
    local setTeams   = mini("Team",    S.esp.TeamColors, function(v) S.esp.TeamColors=v; _G.WRDESPTeamColors=v end)
    local setTracers = mini("Tracers", S.esp.Tracers, function(v) S.esp.Tracers=v; _G.WRDESPTracers=v end)

    -- init
    setBoxes(S.esp.Boxes); setNames(S.esp.Names); setTeams(S.esp.TeamColors); setTracers(S.esp.Tracers)

    Toggle.MouseButton1Click:Connect(function()
        S.espWanted = not S.espWanted
        setT(S.espWanted)
        if S.espWanted then
            ensureESP()
            _G.WRDESPEnabled = true
            _G.WRDESPBoxes      = S.esp.Boxes
            _G.WRDESPNames      = S.esp.Names
            _G.WRDESPTeamColors = S.esp.TeamColors
            _G.WRDESPTracers    = S.esp.Tracers
        else
            _G.WRDESPEnabled = false
        end
    end)

    return Card
end)()

-- ===== Drag (header OU carte) + bornage écran =====
local function clampToScreen(posX,posY)
    local vs = workspace.CurrentCamera.ViewportSize
    local w,h = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
    local x = math.clamp(posX, 0, math.max(0, vs.X - w))
    local y = math.clamp(posY, 0, math.max(0, vs.Y - h))
    return x,y
end

local dragging, dragOffset
local function startDrag(input)
    dragging = true
    local mousePos = input.Position
    local absPos = Main.AbsolutePosition
    dragOffset = Vector2.new(mousePos.X - absPos.X, mousePos.Y - absPos.Y)
end
local function updateDrag(input)
    if not dragging then return end
    local x = input.Position.X - dragOffset.X
    local y = input.Position.Y - dragOffset.Y
    local cx,cy = clampToScreen(x,y)
    Main.Position = UDim2.fromOffset(cx, cy)
end
local function endDrag() dragging=false end

for _,dragArea in ipairs({Header, Main}) do
    dragArea.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(io)
            io.Changed:Connect(function()
                if io.UserInputState == Enum.UserInputState.End then endDrag() end
            end)
        end
    end)
end
UIS.InputChanged:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseMovement then updateDrag(io) end
end)

-- ===== Toggle UI (⇧+4 → "$", + F2 secours) =====
local function toggleUI()
    S.uiVisible = not S.uiVisible
    ScreenGui.Enabled = S.uiVisible
end

UIS.InputBegan:Connect(function(io, gp)
    if gp then return end
    if io.UserInputType == Enum.UserInputType.Keyboard then
        local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        if (io.KeyCode == Enum.KeyCode.Four and shift) or (Enum.KeyCode.Dollar and io.KeyCode == Enum.KeyCode.Dollar) or (io.KeyCode == Enum.KeyCode.F2) then
            toggleUI()
        end
    end
end)

-- ===== ESP (WRD/Kiriot PATCH identique) =====
_G.WRDESPEnabled    = false
_G.WRDESPBoxes      = S.esp.Boxes
_G.WRDESPTeamColors = S.esp.TeamColors
_G.WRDESPTracers    = S.esp.Tracers
_G.WRDESPNames      = S.esp.Names

local WRD_ESP_CODE = [===[
-- (code ESP identique à la version précédente, patch TeamColor + couleurs init)
if not _G.WRDESPLoaded then
    local ESP = {
        Enabled = false, Boxes = true,
        BoxShift = CFrame.new(0,-1.5,0), BoxSize = Vector3.new(4,6,0),
        Color = Color3.fromRGB(255,170,0), FaceCamera = false,
        Names = true, TeamColor = true, Thickness = 2,
        AttachShift = 1, TeamMates = true, Players = true,
        Objects = setmetatable({}, {__mode="kv"}), Overrides = {}
    }
    local cam = workspace.CurrentCamera
    local plrs = game:GetService("Players")
    local plr = plrs.LocalPlayer
    local function Draw(obj, props) local d=Drawing.new(obj); for k,v in pairs(props or {}) do d[k]=v end; return d end
    function ESP:GetTeam(p) local o=self.Overrides.GetTeam; if o then return o(p) end; return p and p.Team end
    function ESP:IsTeamMate(p) local o=self.Overrides.IsTeamMate; if o then return o(p) end; return self:GetTeam(p)==self:GetTeam(plr) end
    function ESP:GetColor(obj) local o=self.Overrides.GetColor; if o then return o(obj) end; local p=self:GetPlrFromChar(obj); return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color end
    function ESP:GetPlrFromChar(c) local o=self.Overrides.GetPlrFromChar; if o then return o(c) end; return plrs:GetPlayerFromCharacter(c) end
    function ESP:Toggle(b) self.Enabled=b; if not b then for _,v in pairs(self.Objects) do if v.Type=="Box" then for _,c in pairs(v.Components) do c.Visible=false end end end end end
    function ESP:GetBox(o) return self.Objects[o] end
    local boxBase={} boxBase.__index=boxBase
    function boxBase:Remove() ESP.Objects[self.Object]=nil; for i,v in pairs(self.Components) do v.Visible=false; v:Remove(); self.Components[i]=nil end end
    function boxBase:Update()
        if not self.PrimaryPart then return self:Remove() end
        local color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color
        local allow=true
        if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then allow=false end
        if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then allow=false end
        if self.Player and not ESP.Players then allow=false end
        if self.IsEnabled and (type(self.IsEnabled)=="string" and not ESP[self.IsEnabled] or type(self.IsEnabled)=="function" and not self:IsEnabled()) then allow=false end
        if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then allow=false end
        for _,c in pairs(self.Components) do c.Visible=false end; if not allow then return end
        local cf = self.PrimaryPart.CFrame
        if ESP.FaceCamera then cf = CFrame.new(cf.p, cam.CFrame.p) end
        local size=self.Size
        local locs={
            TopLeft= cf*ESP.BoxShift*CFrame.new(size.X/2,size.Y/2,0),
            TopRight=cf*ESP.BoxShift*CFrame.new(-size.X/2,size.Y/2,0),
            BottomLeft=cf*ESP.BoxShift*CFrame.new(size.X/2,-size.Y/2,0),
            BottomRight=cf*ESP.BoxShift*CFrame.new(-size.X/2,-size.Y/2,0),
            TagPos=cf*ESP.BoxShift*CFrame.new(0,size.Y/2,0),
            Torso=cf*ESP.BoxShift
        }
        local function WTVP(v3) return cam:WorldToViewportPoint(v3) end
        if ESP.Boxes and self.Components.Quad then
            local TL,v1=WTVP(locs.TopLeft.p) local TR,v2=WTVP(locs.TopRight.p) local BL,v3=WTVP(locs.BottomLeft.p) local BR,v4=WTVP(locs.BottomRight.p)
            if v1 or v2 or v3 or v4 then
                local q=self.Components.Quad; q.Visible=true; q.PointA=Vector2.new(TR.X,TR.Y); q.PointB=Vector2.new(TL.X,TL.Y); q.PointC=Vector2.new(BL.X,BL.Y); q.PointD=Vector2.new(BR.X,BR.Y); q.Color=color
            end
        end
        if ESP.Names then
            local Tag,vis=WTVP(locs.TagPos.p)
            if vis then
                local n=self.Components.Name; n.Visible=true; n.Position=Vector2.new(Tag.X,Tag.Y); n.Text=self.Name; n.Color=color
                local d=self.Components.Distance; d.Visible=true; d.Position=Vector2.new(Tag.X,Tag.Y+14); d.Text=math.floor((cam.CFrame.p - cf.p).Magnitude).."m"; d.Color=color
            end
        end
        if ESP.Tracers then
            local Torso,vis=WTVP(locs.Torso.p)
            if vis then local t=self.Components.Tracer; t.Visible=true; t.From=Vector2.new(Torso.X,Torso.Y); t.To=Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/ESP.AttachShift); t.Color=color end
        end
    end
    function ESP:Add(obj, options)
        if not obj.Parent and not options.RenderInNil then return end
        local box=setmetatable({
            Name=options.Name or obj.Name, Type="Box", Color=options.Color,
            Size=options.Size or self.BoxSize, Object=obj,
            Player=options.Player or plrs:GetPlayerFromCharacter(obj),
            PrimaryPart=options.PrimaryPart or obj.ClassName=="Model" and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
            Components={}, IsEnabled=options.IsEnabled, Temporary=options.Temporary, ColorDynamic=options.ColorDynamic, RenderInNil=options.RenderInNil
        }, boxBase)
        if self:GetBox(obj) then self:GetBox(obj):Remove() end
        box.Components["Quad"]=Draw("Quad",{Thickness=self.Thickness, Color=ESP.Color, Transparency=1, Filled=false, Visible=self.Enabled and self.Boxes})
        box.Components["Name"]=Draw("Text",{Text=box.Name, Color=box.Color or ESP.Color, Center=true, Outline=true, Size=19, Visible=self.Enabled and self.Names})
        box.Components["Distance"]=Draw("Text",{Color=box.Color or ESP.Color, Center=true, Outline=true, Size=19, Visible=self.Enabled and self.Names})
        box.Components["Tracer"]=Draw("Line",{Thickness=ESP.Thickness, Color=box.Color or ESP.Color, Transparency=1, Visible=self.Enabled and self.Tracers})
        self.Objects[obj]=box
        obj.AncestryChanged:Connect(function(_,p) if p==nil and ESP.AutoRemove~=false then box:Remove() end end)
        obj:GetPropertyChangedSignal("Parent"):Connect(function() if obj.Parent==nil and ESP.AutoRemove~=false then box:Remove() end end)
        local h=obj:FindFirstChildOfClass("Humanoid"); if h then h.Died:Connect(function() if ESP.AutoRemove~=false then box:Remove() end end) end
        return box
    end
    local function CharAdded(c)
        local p=plrs:GetPlayerFromCharacter(c); if not p or p==plr then return end
        local hrp=c:FindFirstChild("HumanoidRootPart")
        if hrp then ESP:Add(c,{Name=p.Name, Player=p, PrimaryPart=hrp})
        else c.ChildAdded:Connect(function(ch) if ch.Name=="HumanoidRootPart" then ESP:Add(c,{Name=p.Name, Player=p, PrimaryPart=ch}) end end) end
    end
    local function PlayerAdded(p) p.CharacterAdded:Connect(CharAdded); if p.Character then CharAdded(p.Character) end end
    for _,v in ipairs(plrs:GetPlayers()) do if v~=plr then PlayerAdded(v) end end
    plrs.PlayerAdded:Connect(PlayerAdded)
    game:GetService("RunService").RenderStepped:Connect(function()
        cam=workspace.CurrentCamera
        if ESP.Enabled then for _,v in pairs(ESP.Objects) do if v.Update then local ok,err=pcall(v.Update,v); if not ok then warn("[ESP]",err) end end end end)
    if _G.WRDESPEnabled==nil then _G.WRDESPEnabled=true end
    if _G.WRDESPBoxes==nil then _G.WRDESPBoxes=true end
    if _G.WRDESPTeamColors==nil then _G.WRDESPTeamColors=true end
    if _G.WRDESPTracers==nil then _G.WRDESPTracers=false end
    if _G.WRDESPNames==nil then _G.WRDESPNames=true end
    task.spawn(function()
        while task.wait(0.12) do
            ESP:Toggle(_G.WRDESPEnabled or false)
            ESP.Boxes     = _G.WRDESPBoxes or false
            ESP.TeamColor = _G.WRDESPTeamColors or false
            ESP.Tracers   = _G.WRDESPTracers or false
            ESP.Names     = _G.WRDESPNames or false
        end
    end)
    _G.WRDESPLoaded = true
end
]===]

function ensureESP()
    if S.espLoaded then return end
    local f,err = loadstring(WRD_ESP_CODE)
    if not f then warn("ESP load error:",err) return end
    f(); S.espLoaded = true
end

-- petite intro
print('[Premium Hub] OK. Touche "$" (⇧+4) pour cacher/montrer, F2 secours.')
