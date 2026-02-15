--[[ 
    ASYLUM ELITE V13.0 - FULL RELEASE
    - RESTORED: Full Box ESP & Skeleton ESP Rendering
    - RESTORED: Chams / Glow Highlighting
    - INCLUDED: All Silent Aim Methods & Camera Snap
    - INCLUDED: All Sliders & Target Part Selector
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
    AimPart = "Head",
    TargetMode = "All",
}

--// FOV DRAWING
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Color = Color3.fromRGB(0, 150, 255); FOVCircle.Visible = false

--// GUI CORE
local ScreenGui = Instance.new("ScreenGui", LP.PlayerGui); ScreenGui.Name = "AsylumV13"; ScreenGui.ResetOnSpawn = false
local Main = Instance.new("Frame", ScreenGui); Main.Size = UDim2.new(0, 600, 0, 420); Main.Position = UDim2.new(0.5, -300, 0.5, -210); Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20); Main.BorderSizePixel = 0; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local Sidebar = Instance.new("Frame", Main); Sidebar.Size = UDim2.new(0, 160, 1, 0); Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 30); Sidebar.BorderSizePixel = 0; Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)
local SidebarTitle = Instance.new("TextLabel", Sidebar); SidebarTitle.Size = UDim2.new(1, 0, 0, 60); SidebarTitle.Text = "ASYLUM ELITE"; SidebarTitle.TextColor3 = Color3.fromRGB(0, 150, 255); SidebarTitle.Font = "GothamBold"; SidebarTitle.TextSize = 22; SidebarTitle.BackgroundTransparency = 1
local Container = Instance.new("Frame", Main); Container.Size = UDim2.new(1, -180, 1, -20); Container.Position = UDim2.new(0, 170, 0, 10); Container.BackgroundTransparency = 1

local Tabs = { Aim = {}, Visuals = {}, Misc = {} }
local function CreateTabFrame()
    local f = Instance.new("ScrollingFrame", Container); f.Size = UDim2.new(1, 0, 1, 0); f.BackgroundTransparency = 1; f.Visible = false; f.ScrollBarThickness = 0; f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Instance.new("UIListLayout", f).Padding = UDim.new(0, 12); f.UIListLayout.HorizontalAlignment = "Center"
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

--// UI HELPERS
local function AddToggle(p, t, k)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 40); f.BackgroundTransparency = 1
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -45, 0.5, -10); btn.BackgroundColor3 = getgenv().Config[k] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60); btn.Text = ""; Instance.new("UICorner", btn)
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, -50, 1, 0); lbl.Text = t; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = "Gotham"; lbl.TextSize = 14; lbl.TextXAlignment = "Left"; lbl.BackgroundTransparency = 1
    btn.MouseButton1Click:Connect(function() getgenv().Config[k] = not getgenv().Config[k]; btn.BackgroundColor3 = getgenv().Config[k] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(50, 50, 60) end)
end

local function AddSlider(p, t, min, max, k, dec)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 55); f.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1, 0, 0, 20); lbl.Text = t .. ": " .. getgenv().Config[k]; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = "Gotham"; lbl.TextSize = 13; lbl.TextXAlignment = "Left"; lbl.BackgroundTransparency = 1
    local bar = Instance.new("Frame", f); bar.Size = UDim2.new(1, 0, 0, 6); bar.Position = UDim2.new(0,0,0.7,0); bar.BackgroundColor3 = Color3.fromRGB(40,40,50); Instance.new("UICorner", bar)
    local fill = Instance.new("Frame", bar); fill.Size = UDim2.new((getgenv().Config[k]-min)/(max-min), 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255); Instance.new("UICorner", fill)
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then local con; con = UIS.InputChanged:Connect(function(ni) if ni.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = math.clamp((ni.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1); local val = min + (max - min) * pos
        if dec then val = math.round(val * 100) / 100 else val = math.floor(val) end
        getgenv().Config[k] = val; lbl.Text = t .. ": " .. val; fill.Size = UDim2.new(pos, 0, 1, 0)
    end end) UIS.InputEnded:Connect(function(ei) if ei.UserInputType == Enum.UserInputType.MouseButton1 then con:Disconnect() end end) end end)
end

local function AddDropdown(p, t, opts, k)
    local f = Instance.new("Frame", p); f.Size = UDim2.new(0.95, 0, 0, 40); f.BackgroundTransparency = 1; f.ZIndex = 10
    local btn = Instance.new("TextButton", f); btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); btn.Text = t .. ": " .. getgenv().Config[k]; btn.TextColor3 = Color3.new(1,1,1); btn.Font = "Gotham"; btn.TextSize = 13; Instance.new("UICorner", btn)
    local d = Instance.new("Frame", f); d.Visible = false; d.Size = UDim2.new(1, 0, 0, #opts * 30); d.Position = UDim2.new(0,0,1,5); d.BackgroundColor3 = Color3.fromRGB(20,20,30); d.ZIndex = 11; Instance.new("UICorner", d); Instance.new("UIListLayout", d)
    btn.MouseButton1Click:Connect(function() d.Visible = not d.Visible end)
    for _, o in pairs(opts) do
        local b = Instance.new("TextButton", d); b.Size = UDim2.new(1, 0, 0, 30); b.BackgroundTransparency = 1; b.Text = o; b.TextColor3 = Color3.new(1,1,1); b.Font = "Gotham"; b.TextSize = 12
        b.MouseButton1Click:Connect(function() getgenv().Config[k] = o; btn.Text = t .. ": " .. o; d.Visible = false end)
    end
end

--// POPULATE
AddDropdown(Tabs.Aim.Frame, "TARGET MODE", {"All", "Players", "NPCs"}, "TargetMode")
AddDropdown(Tabs.Aim.Frame, "TARGET PART", {"Head", "UpperTorso", "HumanoidRootPart"}, "AimPart")
AddToggle(Tabs.Aim.Frame, "Team Check", "TeamCheck"); AddToggle(Tabs.Aim.Frame, "Wall Check", "WallCheck")
AddToggle(Tabs.Aim.Frame, "Show FOV Circle", "ShowFOV"); AddSlider(Tabs.Aim.Frame, "FOV Radius", 10, 800, "FOVRadius")
AddToggle(Tabs.Aim.Frame, "Camera Snap", "CameraAim"); AddSlider(Tabs.Aim.Frame, "Smoothness", 0.01, 1, "Smoothness", true)
AddToggle(Tabs.Aim.Frame, "Silent Method 1", "Method1_Silent"); AddToggle(Tabs.Aim.Frame, "Silent Method 2", "Method2_Silent")
AddToggle(Tabs.Visuals.Frame, "Box ESP", "ESPEnabled"); AddToggle(Tabs.Visuals.Frame, "Skeleton ESP", "SkeletonEnabled"); AddToggle(Tabs.Visuals.Frame, "Chams (Glow)", "ChamsEnabled")
AddToggle(Tabs.Misc.Frame, "Hitbox Expander", "HitboxEnabled"); AddSlider(Tabs.Misc.Frame, "Hitbox Size", 2, 50, "HitboxSize")

--// ESP SYSTEM
local ESP_Cache = {}
local function CreateESP(p)
    local objects = {
        Box = Drawing.new("Square"),
        Skeleton = {},
        Highlight = Instance.new("Highlight")
    }
    objects.Box.Thickness = 1; objects.Box.Filled = false; objects.Box.Color = Color3.new(1,1,1)
    ESP_Cache[p] = objects
end

local function GetBones(char)
    local bones = {}
    local function add(b1, b2) table.insert(bones, {char:FindFirstChild(b1), char:FindFirstChild(b2)}) end
    add("Head", "UpperTorso"); add("UpperTorso", "LowerTorso"); add("UpperTorso", "LeftUpperArm")
    add("LeftUpperArm", "LeftLowerArm"); add("UpperTorso", "RightUpperArm"); add("RightUpperArm", "RightLowerArm")
    add("LowerTorso", "LeftUpperLeg"); add("LeftUpperLeg", "LeftLowerLeg"); add("LowerTorso", "RightUpperLeg")
    add("RightUpperLeg", "RightLowerLeg")
    return bones
end

--// ENGINE & RENDER
local LockedTarget = nil; local IsRightClicking = false
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV; FOVCircle.Radius = getgenv().Config.FOVRadius; FOVCircle.Position = UIS:GetMouseLocation()
    local potential, dist = nil, getgenv().Config.FOVRadius
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= LP.Character then
            local char = v; local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then 
                if ESP_Cache[char] then 
                    ESP_Cache[char].Box.Visible = false
                    for _, line in pairs(ESP_Cache[char].Skeleton) do line.Visible = false end
                    if ESP_Cache[char].Highlight then ESP_Cache[char].Highlight.Enabled = false end
                end
                continue 
            end
            
            local targetPlayer = Players:GetPlayerFromCharacter(char)
            if getgenv().Config.TeamCheck and targetPlayer and targetPlayer.Team == LP.Team then continue end
            
            if not ESP_Cache[char] then CreateESP(char) end
            local data = ESP_Cache[char]
            
            -- CHAMS
            if data.Highlight then
                data.Highlight.Parent = char; data.Highlight.Enabled = getgenv().Config.ChamsEnabled
                data.Highlight.FillColor = Color3.fromRGB(0, 150, 255); data.Highlight.OutlineColor = Color3.new(1,1,1)
            end

            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScr = Camera:WorldToViewportPoint(root.Position)
                
                -- BOX ESP
                if onScr and getgenv().Config.ESPEnabled then
                    local sizeX = 2000 / pos.Z; local sizeY = 3000 / pos.Z
                    data.Box.Visible = true; data.Box.Size = Vector2.new(sizeX, sizeY)
                    data.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                else data.Box.Visible = false end

                -- SKELETON ESP
                if onScr and getgenv().Config.SkeletonEnabled then
                    local bones = GetBones(char)
                    for i, boneSet in pairs(bones) do
                        if not data.Skeleton[i] then data.Skeleton[i] = Drawing.new("Line"); data.Skeleton[i].Thickness = 1; data.Skeleton[i].Color = Color3.new(1,1,1) end
                        local b1, b2 = boneSet[1], boneSet[2]
                        if b1 and b2 then
                            local p1, o1 = Camera:WorldToViewportPoint(b1.Position)
                            local p2, o2 = Camera:WorldToViewportPoint(b2.Position)
                            if o1 and o2 then
                                data.Skeleton[i].Visible = true; data.Skeleton[i].From = Vector2.new(p1.X, p1.Y); data.Skeleton[i].To = Vector2.new(p2.X, p2.Y)
                            else data.Skeleton[i].Visible = false end
                        end
                    end
                else for _, l in pairs(data.Skeleton) do l.Visible = false end end

                -- AIMBOT LOGIC
                local mode = getgenv().Config.TargetMode
                if (mode == "All") or (mode == "Players" and targetPlayer) or (mode == "NPCs" and not targetPlayer) then
                    local aimp = char:FindFirstChild(getgenv().Config.AimPart) or root
                    local aPos, aOn = Camera:WorldToViewportPoint(aimp.Position)
                    if aOn and (#Camera:GetPartsObscuringTarget({aimp.Position}, {LP.Character, char}) == 0 or not getgenv().Config.WallCheck) then
                        local mDist = (Vector2.new(aPos.X, aPos.Y) - UIS:GetMouseLocation()).Magnitude
                        if mDist < dist then potential = aimp; dist = mDist end
                    end
                end
                
                -- HITBOX EXPANDER
                if getgenv().Config.HitboxEnabled then root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize); root.Transparency = 0.7; root.CanCollide = false else root.Size = Vector3.new(2,2,1); root.Transparency = 1 end
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
    local m = getnamecallmethod(); local args = {...}
    if not checkcaller() and getgenv().Config.Method1_Silent and LockedTarget then
        if m == "Raycast" then args[2] = (LockedTarget.Position - args[1]).Unit * 1000; return oldN(self, unpack(args))
        elseif m:find("PartOnRay") then args[1] = Ray.new(Camera.CFrame.Position, (LockedTarget.Position - Camera.CFrame.Position).Unit * 1000); return oldN(self, unpack(args)) end
    end
    return oldN(self, ...)
end)

local oldI; oldI = hookmetamethod(game, "__index", function(self, idx)
    if not checkcaller() and getgenv().Config.Method2_Silent and LockedTarget and self == Mouse then
        if idx == "Hit" then return LockedTarget.CFrame elseif idx == "Target" then return LockedTarget end
    end
    return oldI(self, idx)
end)

--// INPUTS
UIS.InputBegan:Connect(function(i, c)
    if not c and i.KeyCode == Enum.KeyCode.F5 then Main.Visible = not Main.Visible end
    if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = true end
end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsRightClicking = false end end)

--// DRAGGING
local drag, dPos, mPos; Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dPos = Main.Position; mPos = i.Position end end)
UIS.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - mPos; Main.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + delta.X, dPos.Y.Scale, dPos.Y.Offset + delta.Y) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
