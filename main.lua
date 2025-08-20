--[[
   🔥 Premium Loader - Speed + ESP Player (menu draggable + toggle "$")
   Auteur: toi :)
   Dernière màj: 2025-08-20

   ✅ Touche pour afficher/masquer le menu: "$" (Shift + 4)
   ✅ Menu draggable, transitions fluides
   ✅ Toggles: Speed / ESP
   ✅ Slider de vitesse (16 → 100)
   ✅ ESP patché (Boxes / Names / Team Colors / Tracers)

   📦 Utilisation en loader:
   loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main.lua"))()

   ⚠️ Remarques:
   - L’ESP utilise le Drawing API (exploits compatibles).
   - Le script évite les resets de vitesse et gère les respawns.
--]]

if _G.__PREMIUM_MENU_LOADED then
    warn("Menu déjà chargé.")
    return
end
_G.__PREMIUM_MENU_LOADED = true

-- ========= Services & Utils =========
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local RunService         = game:GetService("RunService")

local LocalPlayer        = Players.LocalPlayer
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function getHumanoid(char)
    char = char or getCharacter()
    return char:WaitForChild("Humanoid")
end

-- Parent sûr pour ScreenGui
local function safeParent(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(gui) end
    end)
    local parentOk, core = pcall(function() return game:GetService("CoreGui") end)
    if parentOk and core then
        gui.Parent = core
    else
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Tweens
local function tween(o, t, p)
    local ti = TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    return TweenService:Create(o, ti, p)
end

-- ========= State global =========
local STATE = {
    uiVisible = true,
    speedEnabled = false,
    espWanted   = false,
    espLoaded   = false,
    espOptions = {
        Boxes = true,
        Names = true,
        TeamColors = true,
        Tracers = false,
    },
    speed = 22,         -- valeur par défaut
    minSpeed = 16,
    maxSpeed = 100,

    connections = {
        speedHeartbeat = nil,
        speedCharAdded = nil,
        antiReset = nil,
    },

    humanoid = nil,
    normalSpeed = nil,
}

-- ========= UI =========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Premium_Menu_UI"
safeParent(ScreenGui)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(380, 270)
Main.Position = UDim2.fromScale(0.1, 0.25)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 16)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.15
Stroke.Color = Color3.fromRGB(255,255,255)
Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

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
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(14, 6)
Title.Size = UDim2.fromOffset(320, 32)
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
Hint.Text = 'Touche: "$" (⇧+4)'
Hint.Parent = Header

local Sep = Instance.new("Frame")
Sep.BackgroundColor3 = Color3.fromRGB(45,45,52)
Sep.Size = UDim2.new(1, -24, 0, 1)
Sep.Position = UDim2.fromOffset(12, 44)
Sep.BorderSizePixel = 0
Sep.Parent = Main

-- Contenu
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.BackgroundTransparency = 1
Content.Position = UDim2.fromOffset(12, 56)
Content.Size = UDim2.new(1, -24, 1, -68)
Content.Parent = Main

-- Layout
local UIList = Instance.new("UIListLayout")
UIList.Parent = Content
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,10)

-- Helpers UI (toggle + card)
local function makeCard(titleText, subtitleText)
    local Card = Instance.new("Frame")
    Card.Size = UDim2.new(1,0,0,92)
    Card.BackgroundColor3 = Color3.fromRGB(24,24,28)
    Card.BorderSizePixel = 0
    local c = Instance.new("UICorner", Card) c.CornerRadius = UDim.new(0,12)
    local s = Instance.new("UIStroke", Card) s.Thickness = 1 s.Transparency = 0.25 s.Color = Color3.fromRGB(255,255,255)

    local T = Instance.new("TextLabel")
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.GothamSemibold
    T.TextSize = 16
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.TextColor3 = Color3.fromRGB(235,235,240)
    T.Text = titleText
    T.Position = UDim2.fromOffset(12,10)
    T.Size = UDim2.fromOffset(260,22)
    T.Parent = Card

    local ST = Instance.new("TextLabel")
    ST.BackgroundTransparency = 1
    ST.Font = Enum.Font.Gotham
    ST.TextSize = 13
    ST.TextXAlignment = Enum.TextXAlignment.Left
    ST.TextColor3 = Color3.fromRGB(170,170,182)
    ST.Text = subtitleText or ""
    ST.Position = UDim2.fromOffset(12,32)
    ST.Size = UDim2.fromOffset(270,20)
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

-- Slider
local function makeSlider(parent, title, minV, maxV, defaultV, onChanged)
    local Wrap = Instance.new("Frame")
    Wrap.BackgroundTransparency = 1
    Wrap.Size = UDim2.new(1,0,0,58)
    Wrap.Parent = parent

    local T = Instance.new("TextLabel")
    T.BackgroundTransparency = 1
    T.Font = Enum.Font.Gotham
    T.TextSize = 14
    T.TextXAlignment = Enum.TextXAlignment.Left
    T.TextColor3 = Color3.fromRGB(200,200,210)
    T.Text = string.format("%s: %d", title, defaultV)
    T.Position = UDim2.fromOffset(12,0)
    T.Size = UDim2.fromOffset(240,20)
    T.Parent = Wrap

    local Bar = Instance.new("Frame")
    Bar.BackgroundColor3 = Color3.fromRGB(45,45,55)
    Bar.BorderSizePixel = 0
    Bar.Position = UDim2.fromOffset(12,24)
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
    Knob.Position = UDim2.fromOffset(0,-3)
    Knob.BackgroundColor3 = Color3.fromRGB(240,240,245)
    Knob.Parent = Fill
    local kc = Instance.new("UICorner", Knob) kc.CornerRadius = UDim.new(1,0)

    local Dragging = false
    local function setValueFromX(x)
        local abs = Bar.AbsoluteSize.X
        local rel = math.clamp(x / abs, 0, 1)
        local val = math.floor(minV + (maxV - minV) * rel + 0.5)
        local px = math.floor(abs * rel + 0.5)
        Fill.Size = UDim2.fromOffset(px, 8)
        Knob.Position = UDim2.fromOffset(px - 7, -3)
        T.Text = string.format("%s: %d", title, val)
        if onChanged then onChanged(val) end
    end

    -- init
    task.defer(function()
        local rel = (defaultV - minV) / (maxV - minV)
        setValueFromX(Bar.AbsoluteSize.X * rel)
    end)

    Bar.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            setValueFromX((io.Position.X - Bar.AbsolutePosition.X))
        end
    end)
    UserInputService.InputChanged:Connect(function(io)
        if Dragging and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
            setValueFromX((io.Position.X - Bar.AbsolutePosition.X))
        end
    end)
    UserInputService.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)

    return {
        setValue = function(v)
            v = math.clamp(v, minV, maxV)
            local rel = (v - minV) / (maxV - minV)
            setValueFromX(Bar.AbsoluteSize.X * rel)
        end
    }
end

-- ========= Cartes: SPEED =========
local SpeedCard = makeCard("Speed", "Sprint constant (anti-reset + respawn)"); SpeedCard.Parent = Content
local SpeedToggle, setSpeedToggle = makeToggle(SpeedCard, false)

local SpeedSlider = makeSlider(SpeedCard, "Vitesse", STATE.minSpeed, STATE.maxSpeed, STATE.speed, function(v)
    STATE.speed = v
end)

-- ========= Cartes: ESP =========
local ESPCard = makeCard("ESP Player", "Boxes, Names, Team Colors, Tracers"); ESPCard.Parent = Content
local ESPToggle, setESPToggle = makeToggle(ESPCard, false)

-- Ligne d’options ESP
local ESPOpts = Instance.new("Frame")
ESPOpts.BackgroundTransparency = 1
ESPOpts.Position = UDim2.fromOffset(12, 52)
ESPOpts.Size = UDim2.new(1, -24, 0, 28)
ESPOpts.Parent = ESPCard

local OptLayout = Instance.new("UIListLayout")
OptLayout.FillDirection = Enum.FillDirection.Horizontal
OptLayout.Padding = UDim.new(0,8)
OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
OptLayout.Parent = ESPOpts

local function miniToggle(labelText, defaultOn, onSwitch)
    local Wrap = Instance.new("Frame")
    Wrap.BackgroundTransparency = 1
    Wrap.Size = UDim2.fromOffset(140,28)

    local L = Instance.new("TextLabel")
    L.BackgroundTransparency = 1
    L.Font = Enum.Font.Gotham
    L.TextSize = 13
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.TextColor3 = Color3.fromRGB(200,200,210)
    L.Text = labelText
    L.Position = UDim2.fromOffset(0,5)
    L.Size = UDim2.fromOffset(86,18)
    L.Parent = Wrap

    local Btn, setOn = makeToggle(Wrap, defaultOn)
    Btn.Position = UDim2.new(1,-64,0,0)
    Btn.Size = UDim2.fromOffset(56,24)
    Btn.MouseButton1Click:Connect(function()
        defaultOn = not defaultOn
        setOn(defaultOn)
        if onSwitch then onSwitch(defaultOn) end
    end)

    -- init visuel
    setOn(defaultOn)

    return Wrap, function(on)
        defaultOn = on
        setOn(on)
        if onSwitch then onSwitch(on) end
    end
end

local BoxesWrap, setBoxes = miniToggle("Boxes", STATE.espOptions.Boxes, function(on)
    STATE.espOptions.Boxes = on
    _G.WRDESPBoxes = on
end); BoxesWrap.Parent = ESPOpts

local NamesWrap, setNames = miniToggle("Names", STATE.espOptions.Names, function(on)
    STATE.espOptions.Names = on
    _G.WRDESPNames = on
end); NamesWrap.Parent = ESPOpts

local TeamsWrap, setTeams = miniToggle("Team Colors", STATE.espOptions.TeamColors, function(on)
    STATE.espOptions.TeamColors = on
    _G.WRDESPTeamColors = on
end); TeamsWrap.Parent = ESPOpts

local TracersWrap, setTracers = miniToggle("Tracers", STATE.espOptions.Tracers, function(on)
    STATE.espOptions.Tracers = on
    _G.WRDESPTracers = on
end); TracersWrap.Parent = ESPOpts

-- ========= Drag (custom) =========
do
    local dragging = false
    local dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.fromOffset(startPos.X + delta.X, startPos.Y + delta.Y)
    end

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)
end

-- ========= Toggle UI par touche "$" (Shift + 4) =========
UserInputService.InputBegan:Connect(function(io, gp)
    if gp then return end
    if io.UserInputType == Enum.UserInputType.Keyboard then
        -- "$" ≈ Shift + 4 (FR/US)
        local is4 = (io.KeyCode == Enum.KeyCode.Four)
        local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if is4 and shift then
            STATE.uiVisible = not STATE.uiVisible
            tween(Main, .18, {GroupTransparency = STATE.uiVisible and 0 or 1}):Play()
            Main.Visible = STATE.uiVisible
        end
    end
end)

-- ========= SPEED: logique =========
local function enableSpeed()
    local hum = getHumanoid()
    STATE.humanoid = hum
    STATE.normalSpeed = hum.WalkSpeed

    -- Connexion anti-reset + Heartbeat enforcement
    if STATE.connections.speedHeartbeat then STATE.connections.speedHeartbeat:Disconnect() end
    STATE.connections.speedHeartbeat = RunService.Heartbeat:Connect(function()
        if STATE.speedEnabled and STATE.humanoid and STATE.humanoid.Parent then
            if STATE.humanoid.WalkSpeed ~= STATE.speed then
                STATE.humanoid.WalkSpeed = STATE.speed
            end
        end
    end)

    if STATE.connections.antiReset then STATE.connections.antiReset:Disconnect() end
    STATE.connections.antiReset = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if STATE.speedEnabled and hum.WalkSpeed ~= STATE.speed then
            hum.WalkSpeed = STATE.speed
        end
    end)
end

local function disableSpeed()
    if STATE.connections.speedHeartbeat then STATE.connections.speedHeartbeat:Disconnect(); STATE.connections.speedHeartbeat=nil end
    if STATE.connections.antiReset then STATE.connections.antiReset:Disconnect(); STATE.connections.antiReset=nil end
    local hum = STATE.humanoid or (getCharacter():FindFirstChildOfClass("Humanoid"))
    if hum then
        hum.WalkSpeed = STATE.normalSpeed or 16
    end
end

-- Gérer respawn
if STATE.connections.speedCharAdded then STATE.connections.speedCharAdded:Disconnect() end
STATE.connections.speedCharAdded = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(.3)
    if STATE.speedEnabled then
        enableSpeed()
    end
end)

-- Toggle bouton SPEED
SpeedToggle.MouseButton1Click:Connect(function()
    STATE.speedEnabled = not STATE.speedEnabled
    setSpeedToggle(STATE.speedEnabled)
    if STATE.speedEnabled then
        enableSpeed()
    else
        disableSpeed()
    end
end)

-- ========= ESP intégré (WRD/Kiriot PATCH) =========
--  Patchs:
--   - Quad color init -> ESP.Color
--   - TeamColors prop -> TeamColor (singulier)
--   - Petite robustesse + _G flags lisibles depuis UI
_G.WRDESPEnabled    = false
_G.WRDESPBoxes      = STATE.espOptions.Boxes
_G.WRDESPTeamColors = STATE.espOptions.TeamColors
_G.WRDESPTracers    = STATE.espOptions.Tracers
_G.WRDESPNames      = STATE.espOptions.Names

local WRD_ESP_CODE = [===[
-- WRD / Kiriot ESP (PATCH)
if not _G.WRDESPLoaded then
    local ESP = {
        Enabled = false,
        Boxes = true,
        BoxShift = CFrame.new(0,-1.5,0),
        BoxSize = Vector3.new(4,6,0),
        Color = Color3.fromRGB(255, 170, 0),
        FaceCamera = false,
        Names = true,
        TeamColor = true,
        Thickness = 2,
        AttachShift = 1,
        TeamMates = true,
        Players = true,
        Objects = setmetatable({}, {__mode="kv"}),
        Overrides = {}
    }

    local cam = workspace.CurrentCamera
    local plrs = game:GetService("Players")
    local plr = plrs.LocalPlayer

    local function Draw(obj, props)
        local new = Drawing.new(obj)
        props = props or {}
        for i,v in pairs(props) do new[i] = v end
        return new
    end

    function ESP:GetTeam(p)
        local ov = self.Overrides.GetTeam
        if ov then return ov(p) end
        return p and p.Team
    end

    function ESP:IsTeamMate(p)
        local ov = self.Overrides.IsTeamMate
        if ov then return ov(p) end
        return self:GetTeam(p) == self:GetTeam(plr)
    end

    function ESP:GetColor(obj)
        local ov = self.Overrides.GetColor
        if ov then return ov(obj) end
        local p = self:GetPlrFromChar(obj)
        return p and self.TeamColor and p.Team and p.Team.TeamColor.Color or self.Color
    end

    function ESP:GetPlrFromChar(char)
        local ov = self.Overrides.GetPlrFromChar
        if ov then return ov(char) end
        return plrs:GetPlayerFromCharacter(char)
    end

    function ESP:Toggle(bool)
        self.Enabled = bool
        if not bool then
            for _,v in pairs(self.Objects) do
                if v.Type == "Box" then
                    if v.Temporary then
                        v:Remove()
                    else
                        for _,comp in pairs(v.Components) do
                            comp.Visible = false
                        end
                    end
                end
            end
        end
    end

    function ESP:GetBox(obj)
        return self.Objects[obj]
    end

    local boxBase = {}
    boxBase.__index = boxBase

    function boxBase:Remove()
        ESP.Objects[self.Object] = nil
        for i,v in pairs(self.Components) do
            v.Visible = false
            v:Remove()
            self.Components[i] = nil
        end
    end

    function boxBase:Update()
        if not self.PrimaryPart then return self:Remove() end

        local color
        if ESP.Highlighted == self.Object then
            color = ESP.HighlightColor
        else
            color = self.Color or self.ColorDynamic and self:ColorDynamic() or ESP:GetColor(self.Object) or ESP.Color
        end

        local allow = true
        if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then allow = false end
        if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then allow = false end
        if self.Player and not ESP.Players then allow = false end
        if self.IsEnabled and (type(self.IsEnabled) == "string" and not ESP[self.IsEnabled] or type(self.IsEnabled) == "function" and not self:IsEnabled()) then
            allow = false
        end
        if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then
            allow = false
        end

        for _,comp in pairs(self.Components) do comp.Visible = false end
        if not allow then return end

        if ESP.Highlighted == self.Object then color = ESP.HighlightColor end

        local cf = self.PrimaryPart.CFrame
        if ESP.FaceCamera then
            cf = CFrame.new(cf.p, cam.CFrame.p)
        end
        local size = self.Size
        local locs = {
            TopLeft = cf * ESP.BoxShift * CFrame.new(size.X/2,size.Y/2,0),
            TopRight = cf * ESP.BoxShift * CFrame.new(-size.X/2,size.Y/2,0),
            BottomLeft = cf * ESP.BoxShift * CFrame.new(size.X/2,-size.Y/2,0),
            BottomRight = cf * ESP.BoxShift * CFrame.new(-size.X/2,-size.Y/2,0),
            TagPos = cf * ESP.BoxShift * CFrame.new(0,size.Y/2,0),
            Torso = cf * ESP.BoxShift
        }

        local function WTVP(v3)
            return cam:WorldToViewportPoint(v3)
        end

        if ESP.Boxes and self.Components.Quad then
            local TL,Vis1 = WTVP(locs.TopLeft.p)
            local TR,Vis2 = WTVP(locs.TopRight.p)
            local BL,Vis3 = WTVP(locs.BottomLeft.p)
            local BR,Vis4 = WTVP(locs.BottomRight.p)
            if Vis1 or Vis2 or Vis3 or Vis4 then
                self.Components.Quad.Visible = true
                self.Components.Quad.PointA = Vector2.new(TR.X, TR.Y)
                self.Components.Quad.PointB = Vector2.new(TL.X, TL.Y)
                self.Components.Quad.PointC = Vector2.new(BL.X, BL.Y)
                self.Components.Quad.PointD = Vector2.new(BR.X, BR.Y)
                self.Components.Quad.Color = color
            end
        end

        if ESP.Names then
            local Tag,Vis = WTVP(locs.TagPos.p)
            if Vis then
                self.Components.Name.Visible = true
                self.Components.Name.Position = Vector2.new(Tag.X, Tag.Y)
                self.Components.Name.Text = self.Name
                self.Components.Name.Color = color

                self.Components.Distance.Visible = true
                self.Components.Distance.Position = Vector2.new(Tag.X, Tag.Y + 14)
                self.Components.Distance.Text = math.floor((cam.CFrame.p - cf.p).Magnitude) .. "m"
                self.Components.Distance.Color = color
            end
        end

        if ESP.Tracers then
            local TorsoPos,Vis = WTVP(locs.Torso.p)
            if Vis then
                self.Components.Tracer.Visible = true
                self.Components.Tracer.From = Vector2.new(TorsoPos.X, TorsoPos.Y)
                self.Components.Tracer.To = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/ESP.AttachShift)
                self.Components.Tracer.Color = color
            end
        end
    end

    function ESP:Add(obj, options)
        if not obj.Parent and not options.RenderInNil then
            return
        end
        local box = setmetatable({
            Name = options.Name or obj.Name,
            Type = "Box",
            Color = options.Color,
            Size = options.Size or self.BoxSize,
            Object = obj,
            Player = options.Player or plrs:GetPlayerFromCharacter(obj),
            PrimaryPart = options.PrimaryPart or obj.ClassName == "Model" and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
            Components = {},
            IsEnabled = options.IsEnabled,
            Temporary = options.Temporary,
            ColorDynamic = options.ColorDynamic,
            RenderInNil = options.RenderInNil
        }, boxBase)

        if self:GetBox(obj) then
            self:GetBox(obj):Remove()
        end

        box.Components["Quad"] = Draw("Quad", {
            Thickness = self.Thickness,
            Color = ESP.Color, -- patch
            Transparency = 1,
            Filled = false,
            Visible = self.Enabled and self.Boxes
        })
        box.Components["Name"] = Draw("Text", {
            Text = box.Name,
            Color = box.Color or ESP.Color,
            Center = true,
            Outline = true,
            Size = 19,
            Visible = self.Enabled and self.Names
        })
        box.Components["Distance"] = Draw("Text", {
            Color = box.Color or ESP.Color,
            Center = true,
            Outline = true,
            Size = 19,
            Visible = self.Enabled and self.Names
        })
        box.Components["Tracer"] = Draw("Line", {
            Thickness = ESP.Thickness,
            Color = box.Color or ESP.Color,
            Transparency = 1,
            Visible = self.Enabled and self.Tracers
        })

        self.Objects[obj] = box

        obj.AncestryChanged:Connect(function(_, parent)
            if parent == nil and ESP.AutoRemove ~= false then
                box:Remove()
            end
        end)
        obj:GetPropertyChangedSignal("Parent"):Connect(function()
            if obj.Parent == nil and ESP.AutoRemove ~= false then
                box:Remove()
            end
        end)

        local hum = obj:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                if ESP.AutoRemove ~= false then
                    box:Remove()
                end
            end)
        end

        return box
    end

    local function CharAdded(char)
        local p = plrs:GetPlayerFromCharacter(char)
        if not p or p == plr then return end
        if not char:FindFirstChild("HumanoidRootPart") then
            local ev
            ev = char.ChildAdded:Connect(function(c)
                if c.Name == "HumanoidRootPart" then
                    ev:Disconnect()
                    ESP:Add(char, { Name = p.Name, Player = p, PrimaryPart = c })
                end
            end)
        else
            ESP:Add(char, { Name = p.Name, Player = p, PrimaryPart = char.HumanoidRootPart })
        end
    end

    local function PlayerAdded(p)
        p.CharacterAdded:Connect(CharAdded)
        if p.Character then CharAdded(p.Character) end
    end

    local plrsSvc = game:GetService("Players")
    for _,v in ipairs(plrsSvc:GetPlayers()) do
        if v ~= plr then PlayerAdded(v) end
    end
    plrsSvc.PlayerAdded:Connect(PlayerAdded)

    game:GetService("RunService").RenderStepped:Connect(function()
        cam = workspace.CurrentCamera
        if ESP.Enabled then
            for _,v in pairs(ESP.Objects) do
                if v.Update then
                    local ok,err = pcall(v.Update, v)
                    if not ok then warn("[ESP]", err) end
                end
            end
        end
    end)

    -- Sync avec _G
    if _G.WRDESPEnabled == nil then _G.WRDESPEnabled = true end
    if _G.WRDESPBoxes == nil then _G.WRDESPBoxes = true end
    if _G.WRDESPTeamColors == nil then _G.WRDESPTeamColors = true end
    if _G.WRDESPTracers == nil then _G.WRDESPTracers = false end
    if _G.WRDESPNames == nil then _G.WRDESPNames = true end

    task.spawn(function()
        while task.wait(0.12) do
            ESP:Toggle(_G.WRDESPEnabled or false)
            ESP.Boxes     = _G.WRDESPBoxes or false
            ESP.TeamColor = _G.WRDESPTeamColors or false -- patch: TeamColor (singulier)
            ESP.Tracers   = _G.WRDESPTracers or false
            ESP.Names     = _G.WRDESPNames or false
        end
    end)

    _G.WRDESPLoaded = true
end
]===]

local function ensureESP()
    if STATE.espLoaded then return end
    local f, err = loadstring(WRD_ESP_CODE)
    if not f then
        warn("Erreur ESP:", err)
        return
    end
    f()
    STATE.espLoaded = true
end

-- Toggle bouton ESP
ESPToggle.MouseButton1Click:Connect(function()
    STATE.espWanted = not STATE.espWanted
    setESPToggle(STATE.espWanted)
    if STATE.espWanted then
        ensureESP()
        _G.WRDESPEnabled = true
        -- appliquer options actuelles
        _G.WRDESPBoxes      = STATE.espOptions.Boxes
        _G.WRDESPNames      = STATE.espOptions.Names
        _G.WRDESPTeamColors = STATE.espOptions.TeamColors
        _G.WRDESPTracers    = STATE.espOptions.Tracers
    else
        _G.WRDESPEnabled = false
    end
end)

-- Sync initial des mini toggles (au cas où tu modifies avant d’activer l’ESP)
setBoxes(STATE.espOptions.Boxes)
setNames(STATE.espOptions.Names)
setTeams(STATE.espOptions.TeamColors)
setTracers(STATE.espOptions.Tracers)

-- Petite animation d’apparition
Main.GroupTransparency = 1
Main.Visible = true
tween(Main, .18, {GroupTransparency = 0}):Play()

-- Fin
print("[Premium Hub] Chargé. Touche \"$\" pour afficher/masquer le menu.")
