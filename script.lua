--[[ 
    ASYLUM ELITE V14.0
    - REMOVED: All Dropdowns (Replaced with instant-cycle buttons).
    - FIXED: UI layout is now much flatter and easier to navigate.
    - RETAINED: GUI Scale, NPC Death Cleanup, and Off-screen protection.
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// Configuration
getgenv().Config = {
    CameraAim = false,
    Method1_Silent = false,
    Method2_Silent = false,
    WallCheck = true,
    TeamCheck = true,
    ShowFOV = true,
    FOVRadius = 150,
    Smoothness = 0.15,
    HitboxEnabled = false,
    HitboxSize = 10,
    ESPEnabled = false,
    NameESP = false,
    TracerEnabled = false,
    ChamsEnabled = false,
    GhostESP = false,
    AimPart = "Head",
    TargetMode = "All",
    ESPColor = Color3.fromRGB(0, 255, 255),
    GuiScale = 1
}

--// Drawings
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Color = getgenv().Config.ESPColor; FOVCircle.Visible = false

--// Main UI Setup
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui); ScreenGui.Name = "AsylumV14"; ScreenGui.ResetOnSpawn = false
local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 500, 0, 400); Main.Position = UDim2.new(0.5, -250, 0.5, -200); Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15); Main.BorderSizePixel = 0; Instance.new("UICorner", Main)

local MasterScale = Instance.new("UIScale", Main); MasterScale.Scale = getgenv().Config.GuiScale

local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 130, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(18, 18, 22); Sidebar.BorderSizePixel = 0; Instance.new("UICorner", Sidebar)
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -140, 1, -20); Container.Position = UDim2.new(0, 140, 0, 10); Container.BackgroundTransparency = 1

local Tabs = { Aim = {}, Visuals = {}, Misc = {} }

--// Tab Creation
local function CreateTab(name)
    local f = Instance.new("ScrollingFrame", Container)
    f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.Visible = false; f.ScrollBarThickness = 3; f.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 255); f.BorderSizePixel = 0
    f.CanvasSize = UDim2.new(0, 0, 0, 0); f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", f); layout.Padding = UDim.new(0, 8); layout.HorizontalAlignment = "Center"; layout.SortOrder = Enum.SortOrder.LayoutOrder
    Tabs[name].Frame = f
end
CreateTab("Aim"); CreateTab("Visuals"); CreateTab("Misc")

local function ShowTab(name) for i, v in pairs(Tabs) do v.Frame.Visible = (i == name) end end
local bIdx = 0
local function TabBtn(name)
    local b = Instance.new("TextButton", Sidebar); b.Size = UDim2.new(0.9, 0, 0, 35); b.Position = UDim2.new(0.05, 0, 0, 40 + (bIdx * 40)); b.BackgroundColor3 = Color3.fromRGB(25, 25, 30); b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; b.TextSize = 13; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() ShowTab(name) end); bIdx = bIdx + 1
end
TabBtn("Aim"); TabBtn("Visuals"); TabBtn("Misc"); ShowTab("Aim")

--// NEW COMPONENT: Cycle Button (Replaces Dropdown)
local function AddCycle(p, text, options, key)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(150, 150, 150); lbl.Font = "GothamBold"; lbl.TextSize = 10; lbl.TextXAlignment = "Left"; lbl.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1, 0, 0, 25); btn.Position = UDim2.new(0, 0, 0, 18); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); btn.Text = tostring(getgenv().Config[key]); btn.TextColor3 = Color3.new(1,1,1); btn.Font = "Gotham"; btn.TextSize = 13; Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        local currentIdx = table.find(options, getgenv().Config[key]) or 1
        local nextIdx = (currentIdx % #options) + 1
        getgenv().Config[key] = options[nextIdx]
        btn.Text = tostring(options[nextIdx])
    end)
end

local function AddToggle(p, text, key)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 35); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(0.7, 0, 1, 0); lbl.Text = text; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = "Gotham"; lbl.TextSize = 13; lbl.TextXAlignment = "Left"; lbl.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 35, 0, 18); btn.Position = UDim2.new(1, -40, 0.5, -9); btn.Text = ""; btn.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(45, 45, 50); Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(function() getgenv().Config[key] = not getgenv().Config[key]; btn.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(45, 45, 50) end)
end

local function AddSlider(p, text, min, max, key, decimal)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 50); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, 0, 0, 15); lbl.Text = text .. ": " .. tostring(getgenv().Config[key]); lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = "Gotham"; lbl.TextSize = 12; lbl.TextXAlignment = "Left"; lbl.BackgroundTransparency = 1
    local bg = Instance.new("Frame", f); bg.Size = UDim2.new(1, 0, 0, 4); bg.Position = UDim2.new(0, 0, 0.7, 0); bg.BackgroundColor3 = Color3.fromRGB(40, 40, 45); Instance.new("UICorner", bg)
    local fill = Instance.new("Frame", bg); fill.Size = UDim2.new((getgenv().Config[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255); Instance.new("UICorner", fill)
    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local con; con = UIS.InputChanged:Connect(function(move)
                if move.UserInputType == Enum.UserInputType.MouseMovement then
                    local per = math.clamp((move.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                    local val = min + (max - min) * per
                    if decimal then val = math.round(val * 100) / 100 else val = math.floor(val) end
                    getgenv().Config[key] = val; lbl.Text = text .. ": " .. tostring(val); fill.Size = UDim2.new(per, 0, 1, 0)
                    if key == "GuiScale" then MasterScale.Scale = val end
                end
            end)
            UIS.InputEnded:Connect(function(endInp) if endInp.UserInputType == Enum.UserInputType.MouseButton1 then con:Disconnect() end end)
        end
    end)
end

--// AIM TAB
AddCycle(Tabs.Aim.Frame, "TARGET PART", {"Head", "UpperTorso", "HumanoidRootPart"}, "AimPart")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 1)", "Method1_Silent")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 2)", "Method2_Silent")
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim")
AddSlider(Tabs.Aim.Frame, "Smoothness", 0.01, 1, "Smoothness", true)
AddSlider(Tabs.Aim.Frame, "FOV Radius", 10, 800, "FOVRadius")
AddToggle(Tabs.Aim.Frame, "Team Check", "TeamCheck")
AddToggle(Tabs.Aim.Frame, "Wall Check", "WallCheck")
AddCycle(Tabs.Aim.Frame, "TARGET MODE", {"All", "Players", "NPCs"}, "TargetMode")

--// VISUALS TAB
AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled")
AddToggle(Tabs.Visuals.Frame, "Name & Health", "NameESP")
AddToggle(Tabs.Visuals.Frame, "Tracers", "TracerEnabled")
AddToggle(Tabs.Visuals.Frame, "Chams", "ChamsEnabled")
AddToggle(Tabs.Visuals.Frame, "Ghost Mode", "GhostESP")
AddToggle(Tabs.Visuals.Frame, "Show FOV Circle", "ShowFOV")

--// MISC TAB
AddSlider(Tabs.Misc.Frame, "GUI SCALE", 0.5, 1.5, "GuiScale", true)
AddToggle(Tabs.Misc.Frame, "Hitbox Expander", "HitboxEnabled")
AddSlider(Tabs.Misc.Frame, "Hitbox Size", 2, 60, "HitboxSize")

--// CORE LOGIC (ESP / AIM)
local Cache = {}
local function RemoveESP(char)
    if Cache[char] then
        Cache[char].Box.Visible = false; Cache[char].Box:Remove()
        Cache[char].Tracer.Visible = false; Cache[char].Tracer:Remove()
        Cache[char].Text.Visible = false; Cache[char].Text:Remove()
        if Cache[char].Highlight then Cache[char].Highlight:Destroy() end
        Cache[char] = nil
    end
end

local Locked = nil; local IsAiming = false
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV; FOVCircle.Radius = getgenv().Config.FOVRadius; FOVCircle.Position = UIS:GetMouseLocation(); FOVCircle.Color = getgenv().Config.ESPColor
    local pot, dist = nil, getgenv().Config.FOVRadius

    for char, _ in pairs(Cache) do
        if not char or not char.Parent or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            RemoveESP(char)
        end
    end

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LP.Character then
            local char = v; local hum = char.Humanoid
            if hum.Health <= 0 then continue end
            local player = Players:GetPlayerFromCharacter(char)
            if getgenv().Config.TeamCheck and player and player.Team == LP.Team then continue end

            if not Cache[char] then
                Cache[char] = {Box = Drawing.new("Square"), Tracer = Drawing.new("Line"), Text = Drawing.new("Text"), Highlight = Instance.new("Highlight", char)}
                Cache[char].Text.Size = 14; Cache[char].Text.Center = true; Cache[char].Text.Outline = true
            end
            local esp = Cache[char]
            esp.Highlight.Enabled = (getgenv().Config.ChamsEnabled or getgenv().Config.GhostESP)
            esp.Highlight.DepthMode = getgenv().Config.GhostESP and 0 or 1
            esp.Highlight.FillColor = getgenv().Config.ESPColor

            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                if on then
                    if getgenv().Config.ESPEnabled then
                        local sx, sy = 2000/pos.Z, 3000/pos.Z
                        esp.Box.Visible = true; esp.Box.Size = Vector2.new(sx, sy); esp.Box.Position = Vector2.new(pos.X-sx/2, pos.Y-sy/2); esp.Box.Color = getgenv().Config.ESPColor
                    else esp.Box.Visible = false end

                    if getgenv().Config.NameESP then
                        esp.Text.Visible = true; esp.Text.Position = Vector2.new(pos.X, pos.Y - (3500/pos.Z)/2 - 15)
                        esp.Text.Text = char.Name .. " [" .. math.floor(hum.Health) .. "%]"; esp.Text.Color = getgenv().Config.ESPColor
                    else esp.Text.Visible = false end

                    if getgenv().Config.TracerEnabled then
                        esp.Tracer.Visible = true; esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y); esp.Tracer.Color = getgenv().Config.ESPColor
                    else esp.Tracer.Visible = false end
                else
                    esp.Box.Visible = false; esp.Text.Visible = false; esp.Tracer.Visible = false
                end

                local mode = getgenv().Config.TargetMode
                if (mode=="All") or (mode=="Players" and player) or (mode=="NPCs" and not player) then
                    local aim = char:FindFirstChild(getgenv().Config.AimPart) or root
                    local aPos, aOn = Camera:WorldToViewportPoint(aim.Position)
                    if aOn then
                        local mDist = (Vector2.new(aPos.X, aPos.Y) - UIS:GetMouseLocation()).Magnitude
                        if mDist < dist then
                            if not getgenv().Config.WallCheck or #Camera:GetPartsObscuringTarget({aim.Position}, {LP.Character, char}) == 0 then
                                pot = aim; dist = mDist
                            end
                        end
                    end
                end
                if getgenv().Config.HitboxEnabled then root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize); root.Transparency = 0.8; root.CanCollide = false else root.Size = Vector3.new(2,2,1); root.Transparency = 1 end
            else RemoveESP(char) end
        end
    end
    Locked = pot
    if Locked and IsAiming and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Locked.Position), getgenv().Config.Smoothness)
    end
end)

--// Aim Hooks & Inputs
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod(); local a = {...}
    if not checkcaller() and getgenv().Config.Method1_Silent and Locked then
        if m == "Raycast" then a[2] = (Locked.Position - a[1]).Unit * 1000; return old(self, unpack(a)) end
    end
    return old(self, ...)
end)
local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and getgenv().Config.Method2_Silent and Locked and self == Mouse then
        if idx == "Hit" then return Locked.CFrame elseif idx == "Target" then return Locked end
    end
    return oldI(self, idx)
end)

local d, dP, mP; Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; dP = Main.Position; mP = i.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - mP; Main.Position = UDim2.new(dP.X.Scale, dP.X.Offset + delta.X, dP.Y.Scale, dP.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
UIS.InputBegan:Connect(function(i,c) if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end 
if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false end end)
