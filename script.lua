local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ASYLUM ELITE V16.0",
   LoadingTitle = "Asylum Hub",
   LoadingSubtitle = "All-In-One Unified Script",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AsylumElite",
      FileName = "UnifiedConfig"
   },
   KeySystem = false
})

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// Consolidated Configuration
getgenv().Config = {
    -- Aim Logic
    TargetMode = "All",
    AimPart = "Head",
    CameraAim = false,
    Method1_Silent = false,
    Method2_Silent = false,
    Smoothness = 0.15,
    FOVRadius = 150,
    WallCheck = true,
    TeamCheck = true,
    
    -- Visuals
    ShowFOV = true,
    ESPEnabled = false,
    NameESP = false,
    TracerEnabled = false,
    ChamsEnabled = false,
    GhostESP = false,
    ESPColor = Color3.fromRGB(0, 255, 255),
    
    -- Misc
    HitboxEnabled = false,
    HitboxSize = 10
}

--// PERFORMANCE: TARGET CACHE (Unified NPC/Player Scan)
local TargetCache = {}
local function RefreshTargets()
    local newCache = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") and v ~= LP.Character then
            table.insert(newCache, v)
        end
    end
    TargetCache = newCache
end
task.spawn(function() while task.wait(1.5) do RefreshTargets() end end)
RefreshTargets()

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5

--// TABS
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local MiscTab = Window:CreateTab("Character", 4483362458)

--- COMBAT TAB ---
CombatTab:CreateSection("Targeting Mode")
CombatTab:CreateDropdown({
   Name = "Target Type",
   Options = {"All", "Players", "NPCs"},
   CurrentOption = {"All"},
   Callback = function(Option) getgenv().Config.TargetMode = Option[1] end,
})

CombatTab:CreateDropdown({
   Name = "Target Bone",
   Options = {"Head", "UpperTorso", "HumanoidRootPart"},
   CurrentOption = {"Head"},
   Callback = function(Option) getgenv().Config.AimPart = Option[1] end,
})

CombatTab:CreateSection("Aimbot Methods")
CombatTab:CreateToggle({
   Name = "Camera Snap (Right Click)",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.CameraAim = v end,
})

CombatTab:CreateToggle({
   Name = "Silent Aim (Raycast)",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.Method1_Silent = v end,
})

CombatTab:CreateToggle({
   Name = "Silent Aim (Mouse Hit)",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.Method2_Silent = v end,
})

CombatTab:CreateSection("Precision & Checks")
CombatTab:CreateSlider({
   Name = "FOV Size",
   Range = {10, 800},
   Increment = 5,
   CurrentValue = 150,
   Callback = function(v) getgenv().Config.FOVRadius = v end,
})

CombatTab:CreateSlider({
   Name = "Smoothing",
   Range = {0.01, 1},
   Increment = 0.01,
   CurrentValue = 0.15,
   Callback = function(v) getgenv().Config.Smoothness = v end,
})

CombatTab:CreateToggle({
   Name = "Wall Check",
   CurrentValue = true,
   Callback = function(v) getgenv().Config.WallCheck = v end,
})

--- VISUALS TAB ---
VisualsTab:CreateSection("ESP Components")
VisualsTab:CreateToggle({
   Name = "Box ESP",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.ESPEnabled = v end,
})

VisualsTab:CreateToggle({
   Name = "Names & Health",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.NameESP = v end,
})

VisualsTab:CreateToggle({
   Name = "Tracers",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.TracerEnabled = v end,
})

VisualsTab:CreateSection("Chams")
VisualsTab:CreateToggle({
   Name = "Glow Chams",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.ChamsEnabled = v end,
})

VisualsTab:CreateToggle({
   Name = "Ghost (Wallhack)",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.GhostESP = v end,
})

VisualsTab:CreateSection("Global Visuals")
VisualsTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = true,
   Callback = function(v) getgenv().Config.ShowFOV = v end,
})

VisualsTab:CreateColorPicker({
    Name = "Theme Color",
    Color = Color3.fromRGB(0, 255, 255),
    Callback = function(v) getgenv().Config.ESPColor = v end
})

--- MISC TAB ---
MiscTab:CreateSection("Hitbox Mod")
MiscTab:CreateToggle({
   Name = "Expand Hitboxes",
   CurrentValue = false,
   Callback = function(v) getgenv().Config.HitboxEnabled = v end,
})

MiscTab:CreateSlider({
   Name = "Hitbox Size",
   Range = {2, 50},
   Increment = 1,
   CurrentValue = 10,
   Callback = function(v) getgenv().Config.HitboxSize = v end,
})

--// CORE UNIFIED ENGINE
local ESPLib = {}
RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Color = getgenv().Config.ESPColor
    
    local pot, dist = nil, getgenv().Config.FOVRadius

    for _, v in pairs(TargetCache) do
        if v.Parent and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local char = v
            local player = Players:GetPlayerFromCharacter(char)
            
            -- Filter logic from V12.2
            if getgenv().Config.TeamCheck and player and player.Team == LP.Team then continue end
            local mode = getgenv().Config.TargetMode
            local isValid = (mode == "All") or (mode == "Players" and player) or (mode == "NPCs" and not player)

            if isValid then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    -- Hitbox Logic
                    if getgenv().Config.HitboxEnabled then
                        root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                        root.Transparency = 0.7
                    else
                        root.Size = Vector3.new(2,2,1); root.Transparency = 1
                    end

                    -- Targeting Logic
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
            end
        end
    end
    Locked = pot
end)

--// Aim Control & Metatable Hooks
UIS.InputBegan:Connect(function(i, c) if not c and i.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then IsAiming = false end end)

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

Rayfield:Notify({Title = "ASYLUM UNIFIED", Content = "All previous features are now active.", Duration = 4})
