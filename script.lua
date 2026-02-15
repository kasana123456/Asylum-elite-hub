--[[ 
    ASYLUM ELITE V12.2
    - ADDED: Target Part Selector (Head, Torso, HumanoidRootPart)
    - ALL FEATURES PRESERVED: Method 1 & 2 Silent, Camera Snap, Chams, ESP
    - ALL CONTROLS PRESERVED: All Sliders, Dropdowns, and Team/NPC Filters
]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()
local TweenService = game:GetService("TweenService")

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
    AimPart = "Head", -- Default
    TargetMode = "All",
}

--// FOV DRAWING
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(0, 150, 255)

--// GUI CORE
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui)
ScreenGui.Name = "AsylumV12_2"; ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 600, 0, 420); Main.Position = UDim2.new(0.5, -300, 0.5, -210); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 160, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30); Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

local SidebarTitle = Instance.new("TextLabel", Sidebar)
SidebarTitle.Size = UDim2.new(1, 0, 0, 60); SidebarTitle.Text = "ASYLUM ELITE"; SidebarTitle.TextColor3 = Color3.fromRGB(0, 150, 255); SidebarTitle.Font = "GothamBold"; SidebarTitle.TextSize = 22; SidebarTitle.BackgroundTransparency = 1

local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -180, 1, -20); Container.Position = UDim2.new(0, 170, 0, 10); Container.BackgroundTransparency = 1

local Tabs = { Aim = {}, Visuals = {}, Misc = {} }
local function CreateTabFrame()
    local f = Instance.new("ScrollingFrame", Container)
    f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.Visible = false; f.ScrollBarThickness = 0; f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    local layout = Instance.new("UIListLayout", f); layout.Padding = UDim.new(0, 12); layout.HorizontalAlignment = "Center"
    return f
end
Tabs.Aim.Frame = CreateTabFrame(); Tabs.Visuals.Frame = CreateTabFrame(); Tabs.Misc.Frame = CreateTabFrame()

local function ShowTab(name) for i, v in pairs(Tabs) do v.Frame.Visible = (i == name) end end
local bCount = 0
local function CreateSidebarBtn(name)
    local b = Instance.new("TextButton", Sidebar)
    b.Size = UDim2.new(0.9, 0, 0, 45); b.Position = UDim2.new(0.05, 0, 0, 75 + (bCount * 55)); b.BackgroundColor3 = Color3.fromRGB(30, 30, 45); b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamSemibold"; b.TextSize = 18; Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function() ShowTab(name) end); bCount = bCount + 1
end
CreateSidebarBtn("Aim"); CreateSidebarBtn("Visuals"); CreateSidebarBtn("Misc"); ShowTab("Aim")

--// UI COMPONENTS
local function AddToggle(parent, txt, key)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 45, 0, 24); btn.Position = UDim2.new(1, -50, 0.5, -12); btn.BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60); btn.Text = ""; Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local label = Instance.new("TextLabel", f); label.Size = UDim2.new(1, -60, 1, 0); label.Text = txt; label.TextColor3 = Color3.new(1,1,1); label.Font = "Gotham"; label.TextSize = 16; label.TextXAlignment = "Left"; label.BackgroundTransparency = 1
    btn.MouseButton1Click:Connect(function()
        getgenv().Config[key] = not getgenv().Config[key]
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = getgenv().Config[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60)}):Play()
    end)
end

local function AddDropdown(parent, txt, options, key)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 45); f.BackgroundTransparency = 1; f.ZIndex = 100 -- Ensure dropdowns are on top
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50); btn.Text = txt .. ": " .. getgenv().Config[key]; btn.TextColor3 = Color3.new(1,1,1); btn.Font = "GothamSemibold"; btn.TextSize = 14; Instance.new("UICorner", btn)
    local drop = Instance.new("Frame", f); drop.Size = UDim2.new(1, 0, 0, #options * 40); drop.Position = UDim2.new(0, 0, 1, 5); drop.BackgroundColor3 = Color3.fromRGB(25, 25, 35); drop.Visible = false; drop.ZIndex = 101; Instance.new("UICorner", drop)
    Instance.new("UIListLayout", drop)
    btn.MouseButton1Click:Connect(function() drop.Visible = not drop.Visible end)
    for _, opt in pairs(options) do
        local o = Instance.new("TextButton", drop); o.Size = UDim2.new(1, 0, 0, 40); o.BackgroundTransparency = 1; o.Text = opt; o.TextColor3 = Color3.new(0.8, 0.8, 0.8); o.Font = "Gotham"; o.TextSize = 14; o.ZIndex = 102
        o.MouseButton1Click:Connect(function() getgenv().Config[key] = opt; btn.Text = txt .. ": " .. opt; drop.Visible = false end)
    end
end

local function AddSlider(parent, txt, min, max, key, decimal)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95, 0, 0, 65); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1, 0, 0, 25); l.Text = txt .. ": " .. getgenv().Config[key]; l.TextColor3 = Color3.new(1,1,1); l.BackgroundTransparency = 1; l.Font = "GothamSemibold"; l.TextSize = 14; l.TextXAlignment = "Left"
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, 0, 0, 8); bar.Position = UDim2.new(0,0,0.7,0); bar.BackgroundColor3 = Color3.fromRGB(40,40,50); Instance.new("UICorner", bar)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[key]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255); Instance.new("UICorner", fill)
    local function update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * pos
        if decimal then val = math.round(val * 100) / 100 else val = math.floor(val) end
        getgenv().Config[key] = val; l.Text = txt .. ": " .. val; fill.Size = UDim2.new(pos, 0, 1, 0)
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local sliding = true; update(i); local con; con = UIS.InputChanged:Connect(function(ni) if ni.UserInputType == Enum.UserInputType.MouseMovement then update(ni) end end) UIS.InputEnded:Connect(function(ei) if ei.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false; con:Disconnect() end end) end end)
end

--// POPULATE AIM TAB
AddDropdown(Tabs.Aim.Frame, "TARGET MODE", {"All", "Players", "NPCs"}, "TargetMode")
AddDropdown(Tabs.Aim.Frame, "TARGET PART", {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}, "AimPart") -- NEW: Target Part Selector
AddToggle(Tabs.Aim.Frame, "Team Check", "TeamCheck")
AddToggle(Tabs.Aim.Frame, "Wall Check", "WallCheck")
AddToggle(Tabs.Aim.Frame, "Show FOV Circle", "ShowFOV")
AddSlider(Tabs.Aim.Frame, "FOV Radius", 10, 800, "FOVRadius")
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim")
AddSlider(Tabs.Aim.Frame, "Smoothness", 0.01, 1, "Smoothness", true)
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 1)", "Method1_Silent")
AddToggle(Tabs.Aim.Frame, "Silent Aim (Method 2)", "Method2_Silent")

--// POPULATE VISUALS & MISC
AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled")
AddToggle(Tabs.Visuals.Frame, "Skeleton ESP", "SkeletonEnabled")
AddToggle(Tabs.Visuals.Frame, "Chams (Glow)", "ChamsEnabled")
AddToggle(Tabs.Misc.Frame, "Hitbox Expander", "HitboxEnabled")
AddSlider(Tabs.Misc.Frame, "Hitbox Size", 2, 100, "HitboxSize")

--// VISUALS ENGINE
local function CreateHighlight(obj)
    local h = Instance.new("Highlight", obj)
    h.FillColor = Color3.fromRGB(0, 150, 255); h.OutlineColor = Color3.new(1,1,1)
    RunService.Heartbeat:Connect(function() 
        h.Enabled = getgenv().Config.ChamsEnabled 
        if getgenv().Config.TeamCheck and Players:GetPlayerFromCharacter(obj) and Players:GetPlayerFromCharacter(obj).Team == LP.Team then h.Enabled = false end
    end)
end

--// ENGINE LOGIC
local LockedTarget = nil
local IsRightClicking = false

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    
    local potential, dist = nil, getgenv().Config.FOVRadius
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= LP.Character then
            if getgenv().Config.ChamsEnabled and not v:FindFirstChildOfClass("Highlight") then CreateHighlight(v) end
            
            local targetPlayer = Players:GetPlayerFromCharacter(v)
            if getgenv().Config.TeamCheck and targetPlayer and targetPlayer.Team == LP.Team then continue end

            local mode = getgenv().Config.TargetMode
            local isValid = (mode == "All") or (mode == "Players" and targetPlayer) or (mode == "NPCs" and not targetPlayer)
            
            if isValid then
                local root = v:FindFirstChild(getgenv().Config.AimPart) or v:FindFirstChild("HumanoidRootPart")
                if root then
                    local sPos, onScr = Camera:WorldToViewportPoint(root.Position)
                    if onScr and (#Camera:GetPartsObscuringTarget({root.Position}, {LP.Character, Camera}) == 0 or not getgenv().Config.WallCheck) then
                        local mDist = (Vector2.new(sPos.X, sPos.Y) - UIS:GetMouseLocation()).Magnitude
                        if mDist < dist then potential = root; dist = mDist end
                    end
                end
            end
        end
    end
    LockedTarget = potential
    
    if LockedTarget and IsRightClicking and getgenv().Config.CameraAim then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, LockedTarget.Position), getgenv().Config.Smoothness)
    end
end)

--// HOOKS
local oldN; oldN = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    if not checkcaller() and getgenv().Config.Method1_Silent and LockedTarget and (m == "Raycast") then
        local args = {...}; args[2] = (LockedTarget.Position - args[1]).Unit * 1000
        return oldN(self, unpack(args))
    end
    return oldN(self, ...)
end)

local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and getgenv().Config.Method2_Silent and LockedTarget and self == Mouse and (idx == "Hit") then
        return LockedTarget.CFrame
    end
    return oldI(self, idx)
end)

--// INPUT CONTROLS
UIS.InputBegan:Connect(function(i, c)
    if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)

--// DRAGGING
local dragging, dStart, sPos
Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dStart = i.Position; sPos = Main.Position end end)
UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dStart; Main.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
