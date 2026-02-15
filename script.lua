--[[ 
    ASYLUM ELITE V13.5
    - FIXED: NPC ESP now clears instantly on death or despawn.
    - ADDED: ESP Color Picker (Visuals Tab).
    - FIXED: Off-screen "Ghost" drawings forced to invisible.
    - LAYOUT: Reorganized Aim tab as requested.
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// Global Settings
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
    SkeletonEnabled = false,
    ChamsEnabled = false,
    GhostESP = false,
    TracerEnabled = false,
    AimPart = "Head",
    TargetMode = "All",
    ESPColor = Color3.fromRGB(0, 150, 255) -- Default Blue
}

--// FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Color = getgenv().Config.ESPColor; FOVCircle.Visible = false

--// UI Setup
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui); ScreenGui.Name = "AsylumV13_5"; ScreenGui.ResetOnSpawn = false
local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 600, 0, 420); Main.Position = UDim2.new(0.5, -300, 0.5, -210); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 160, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30); Sidebar.BorderSizePixel = 0; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)
local SidebarTitle = Instance.new("TextLabel", Sidebar); SidebarTitle.Size = UDim2.new(1, 0, 0, 60); SidebarTitle.Text = "ASYLUM ELITE"; SidebarTitle.TextColor3 = Color3.fromRGB(0, 150, 255); SidebarTitle.Font = "GothamBold"; SidebarTitle.TextSize = 22; SidebarTitle.BackgroundTransparency = 1
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -180, 1, -20); Container.Position = UDim2.new(0, 170, 0, 10); Container.BackgroundTransparency = 1

local Tabs = { Aim = {}, Visuals = {}, Misc = {} }
local function CreateTabFrame()
    local f = Instance.new("ScrollingFrame", Container); f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.Visible = false; f.ScrollBarThickness = 0; f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 10); f.UIListLayout.HorizontalAlignment = "Center"
    return f
end
Tabs.Aim.Frame = CreateTabFrame(); Tabs.Visuals.Frame = CreateTabFrame(); Tabs.Misc.Frame = CreateTabFrame()

local function ShowTab(name) for i, v in pairs(Tabs) do v.Frame.Visible = (i == name) end end
local bCount = 0
local function CreateSidebarBtn(name)
    local b = Instance.new("TextButton", Sidebar); b.Size = UDim2.new(0.9, 0, 0, 45); b.Position = UDim2.new(0.05, 0, 0, 75 + (bCount * 55)); b.BackgroundColor3 = Color3.fromRGB(30, 30, 45); b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; b.TextSize = 18; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() ShowTab(name) end); bCount = bCount + 1
end
CreateSidebarBtn("Aim"); CreateSidebarBtn("Visuals"); CreateSidebarBtn("Misc"); ShowTab("Aim")

--// UI Elements
local function AddToggle(p, t, k)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 35); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 35, 0, 18); btn.Position = UDim2.new(1, -40, 0.5, -9); btn.BackgroundColor3 = getgenv().Config[k] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60); btn.Text = ""; Instance.new("UICorner", btn)
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Text = t; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = "Gotham"; lbl.TextSize = 14; lbl.TextXAlignment = "Left"; lbl.BackgroundTransparency = 1
    btn.MouseButton1Click:Connect(function() getgenv().Config[k] = not getgenv().Config[k]; btn.BackgroundColor3 = getgenv().Config[k] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60) end)
end

local function AddDropdown(p, t, opts, k)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 40); f.BackgroundTransparency = 1; f.ZIndex = 30
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); btn.Text = t .. ": " .. tostring(getgenv().Config[k]); btn.TextColor3 = Color3.new(1,1,1); btn.Font = "Gotham"; btn.TextSize = 13; Instance.new("UICorner", btn)
    local d = Instance.new("Frame", f); d.Visible = false; d.Size = UDim2.new(1, 0, 0, #opts * 30); d.Position = UDim2.new(0,0,1,5); d.BackgroundColor3 = Color3.fromRGB(20,20,30); d.ZIndex = 31; Instance.new("UICorner", d); Instance.new("UIListLayout", d)
    btn.MouseButton1Click:Connect(function() d.Visible = not d.Visible end)
    for _, o in pairs(opts) do
        local b = Instance.new("TextButton", d); b.Size = UDim2.new(1, 0, 0, 30); b.BackgroundTransparency = 1; b.Text = o; b.TextColor3 = Color3.new(1,1,1); b.Font = "Gotham"; b.TextSize = 12
        b.MouseButton1Click:Connect(function() getgenv().Config[k] = o; btn.Text = t .. ": " .. o; d.Visible = false end)
    end
end

--// POPULATE AIM (REORGANIZED)
AddDropdown(Tabs.Aim.Frame, "TARGET PART", {"Head", "UpperTorso", "HumanoidRootPart"}, "AimPart")
AddToggle(Tabs.Aim.Frame, "Silent Method 1", "Method1_Silent")
AddToggle(Tabs.Aim.Frame, "Silent Method 2", "Method2_Silent")
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim")
AddToggle(Tabs.Aim.Frame, "Wall Check", "WallCheck")
AddToggle(Tabs.Aim.Frame, "Team Check", "TeamCheck")
AddDropdown(Tabs.Aim.Frame, "TARGET MODE", {"All", "Players", "NPCs"}, "TargetMode")

--// POPULATE VISUALS (With Color Picker)
AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled")
AddToggle(Tabs.Visuals.Frame, "Skeleton ESP", "SkeletonEnabled")
AddToggle(Tabs.Visuals.Frame, "Tracer ESP", "TracerEnabled")
AddToggle(Tabs.Visuals.Frame, "Chams (Glow)", "ChamsEnabled")
AddToggle(Tabs.Visuals.Frame, "Ghost ESP (X-Ray)", "GhostESP")

local ColorBtn = Instance.new("TextButton", Tabs.Visuals.Frame); ColorBtn.Size = UDim2.new(0.95, 0, 0, 40); ColorBtn.BackgroundColor3 = getgenv().Config.ESPColor; ColorBtn.Text = "CHANGE ESP COLOR"; ColorBtn.TextColor3 = Color3.new(1,1,1); ColorBtn.Font = "GothamBold"; Instance.new("UICorner", ColorBtn)
ColorBtn.MouseButton1Click:Connect(function()
    local colors = {Color3.new(1,0,0), Color3.new(0,1,0), Color3.new(0,0,1), Color3.new(1,1,0), Color3.new(1,0,1), Color3.fromRGB(0, 255, 255)}
    local nextC = colors[math.random(#colors)]
    getgenv().Config.ESPColor = nextC; ColorBtn.BackgroundColor3 = nextC; FOVCircle.Color = nextC
end)

--// ESP Logic & Cleanup
local Cache = {}
local function ForceKillESP(char)
    if Cache[char] then
        Cache[char].Box.Visible = false
        Cache[char].Tracer.Visible = false
        if Cache[char].Highlight then Cache[char].Highlight.Enabled = false end
        Cache[char] = nil
    end
end

--// Main Render Loop
local LockedTarget = nil; local IsRightClicking = false
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV; FOVCircle.Radius = getgenv().Config.FOVRadius; FOVCircle.Position = UIS:GetMouseLocation()
    local pot, dist = nil, getgenv().Config.FOVRadius

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= LP.Character then
            local char = v; local hum = char.Humanoid
            
            -- AGGRESSIVE CLEANUP: If NPC/Player is dead or gone, wipe immediately
            if hum.Health <= 0 or not char.Parent then ForceKillESP(char) continue end
            
            local player = Players:GetPlayerFromCharacter(char)
            if getgenv().Config.TeamCheck and player and player.Team == LP.Team then ForceKillESP(char) continue end

            if not Cache[char] then
                Cache[char] = {
                    Box = Drawing.new("Square"), Tracer = Drawing.new("Line"),
                    Highlight = Instance.new("Highlight", char)
                }
            end
            local esp = Cache[char]
            
            -- Set Colors
            esp.Box.Color = getgenv().Config.ESPColor; esp.Tracer.Color = getgenv().Config.ESPColor
            esp.Highlight.Enabled = (getgenv().Config.ChamsEnabled or getgenv().Config.GhostESP)
            esp.Highlight.DepthMode = getgenv().Config.GhostESP and 0 or 1
            esp.Highlight.FillColor = getgenv().Config.ESPColor

            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, on = Camera:WorldToViewportPoint(root.Position)
                
                -- Display logic (Off-screen fix)
                if on then
                    if getgenv().Config.ESPEnabled then
                        local sX, sY = 2000/pos.Z, 3000/pos.Z
                        esp.Box.Visible = true; esp.Box.Size = Vector2.new(sX, sY); esp.Box.Position = Vector2.new(pos.X-sX/2, pos.Y-sY/2)
                    else esp.Box.Visible = false end

                    if getgenv().Config.TracerEnabled then
                        esp.Tracer.Visible = true; esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                    else esp.Tracer.Visible = false end
                else
                    esp.Box.Visible = false; esp.Tracer.Visible = false
                end

                -- Target Logic
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
            else ForceKillESP(char) end
        end
    end
    LockedTarget = pot
    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// Silent Aim Hooks
local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod(); local a = {...}
    if not checkcaller() and getgenv().Config.Method1_Silent and LockedTarget then
        if m == "Raycast" then a[2] = (LockedTarget.Position - a[1]).Unit * 1000; return old(self, unpack(a)) end
    end
    return old(self, ...)
end)

local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and getgenv().Config.Method2_Silent and LockedTarget and self == Mouse then
        if idx == "Hit" then return LockedTarget.CFrame elseif idx == "Target" then return LockedTarget end
    end
    return oldI(self, idx)
end)

--// Inputs (F5 to Hide/Show)
UIS.InputBegan:Connect(function(i, c)
    if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)

--// Dragging logic
local d, dP, mP; Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true; dP = Main.Position; mP = i.Position end end)
UIS.InputChanged:Connect(function(i) if d and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - mP; Main.Position = UDim2.new(dP.X.Scale, dP.X.Offset + delta.X, dPos.Y.Scale, dP.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end end)
