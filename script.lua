local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "ASYLUM ELITE V17.3",
   LoadingTitle = "Asylum Hub",
   LoadingSubtitle = "Advanced Combat Engine",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AsylumElite",
      FileName = "Unified_V17_3"
   },
   KeySystem = false
})

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

--// FULL CONFIGURATION
getgenv().Config = {
    -- Targeting System
    TargetMode = "All",
    AimPart = "Head",
    AimKey = Enum.UserInputType.MouseButton2, -- Right click to aim
    AimKeybind = false, -- Toggle for keybind requirement
    StickyTarget = false, -- Keep targeting same enemy
    ClosestToMouse = true, -- Target closest to mouse vs closest to player
    
    -- Aimbot Methods
    CameraAim = false, -- Camera-based aimbot
    Method1_Silent = false, -- Raycast hook (Universal)
    Method2_Silent = false, -- Mouse hook (Mouse.Hit/Target)
    Method3_Silent = false, -- Remote hook (FireServer/InvokeServer)
    Method4_Namecall = false, -- Namecall spy (Advanced)
    CursorLock = false, -- Cursor sticks to target
    TriggerBot = false, -- Auto shoot when hovering
    AutoShoot = false, -- Auto shoot when locked
    
    -- Aimbot Settings
    Smoothness = 0.2,
    Prediction = 0.13, -- Velocity prediction
    ShakeReduction = 0, -- Reduce camera shake (0-100)
    FOVRadius = 150,
    WallCheck = true,
    TeamCheck = true,
    VisibleCheck = true, -- Only target visible enemies
    
    -- Advanced Targeting
    IgnoreDowned = true, -- Don't target downed players
    PrioritizeLowHealth = false, -- Target low HP enemies first
    HealthThreshold = 50, -- Health % to prioritize
    
    -- Resolver (Anti-Desync)
    ResolverEnabled = false,
    ResolverMethod = "MoveDirection", -- MoveDirection, Velocity, Hybrid
    
    -- Visuals
    ShowFOV = true,
    FOVFilled = false,
    FOVFillTransparency = 0.1,
    ESPEnabled = false,
    NameESP = false,
    HealthESP = false,
    DistanceESP = false,
    TracerEnabled = false,
    BulletTracers = false,
    ChamsEnabled = false,
    GhostESP = false,
    ESPColor = Color3.fromRGB(0, 255, 255),
    TargetColor = Color3.fromRGB(255, 0, 0),
    TeamColor = Color3.fromRGB(0, 255, 0),
    TracerOrigin = "Bottom",
    ShowTeammates = false,
    
    -- Crosshair
    ShowCrosshair = false,
    CrosshairSize = 10,
    CrosshairColor = Color3.fromRGB(255, 255, 255),
    CrosshairThickness = 2,
    
    -- Misc & Movement
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    NoTilt = false,
    NoSlowdown = false,
    AutoSprint = false,
    
    -- Hitbox
    HitboxEnabled = false,
    HitboxSize = 10,
    HitboxTransparency = 0.7,
    
    -- Melee Hitbox Extender
    MeleeExtenderEnabled = false,
    MeleeRange = 5, -- Distance from player
    MeleeHitboxSize = 8, -- Size of the extended hitbox
    MeleeAutoTarget = false, -- Automatically move hitbox to nearest enemy
    MeleeVisualize = false -- Show where the melee hitbox is
}

--// ESP STORAGE
local ESPObjects = {}

--// COMBAT STATE
local StickyLockedTarget = nil
local IsAiming = false

--// AUTO SAVE SYSTEM
local ConfigFolder = "AsylumElite"
local ConfigFile = "config.json"

local function SaveConfig()
    local success, err = pcall(function()
        if not isfolder(ConfigFolder) then
            makefolder(ConfigFolder)
        end
        
        local configData = game:GetService("HttpService"):JSONEncode(getgenv().Config)
        writefile(ConfigFolder .. "/" .. ConfigFile, configData)
    end)
    
    if success then
        Rayfield:Notify({
            Title = "Config Saved",
            Content = "Settings saved successfully!",
            Duration = 3,
            Image = 4483362458
        })
    else
        warn("Failed to save config:", err)
    end
end

local function LoadConfig()
    local success, err = pcall(function()
        if isfolder(ConfigFolder) and isfile(ConfigFolder .. "/" .. ConfigFile) then
            local configData = readfile(ConfigFolder .. "/" .. ConfigFile)
            local loadedConfig = game:GetService("HttpService"):JSONDecode(configData)
            
            -- Merge loaded config with current config (preserve new settings)
            for key, value in pairs(loadedConfig) do
                if getgenv().Config[key] ~= nil then
                    getgenv().Config[key] = value
                end
            end
            
            Rayfield:Notify({
                Title = "Config Loaded",
                Content = "Settings loaded successfully!",
                Duration = 3,
                Image = 4483362458
            })
            
            return true
        end
    end)
    
    if not success then
        warn("Failed to load config:", err)
    end
    
    return false
end

-- Auto-save every 30 seconds
task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

-- Auto-load config on script start
task.spawn(function()
    task.wait(1) -- Wait for UI to load
    LoadConfig()
end)

-- Save config when player leaves (cleanup)
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LP then
        SaveConfig()
    end
end)

-- Also save when script is being destroyed
local scriptConnection
scriptConnection = game:GetService("RunService").Heartbeat:Connect(function()
    if not getgenv then
        SaveConfig()
        if scriptConnection then
            scriptConnection:Disconnect()
        end
    end
end)

--// PERFORMANCE: TARGET CACHE
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

--// COMBAT HELPER FUNCTIONS
local function GetPredictedPosition(character)
    if not getgenv().Config.Prediction or getgenv().Config.Prediction == 0 then
        return nil
    end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    
    local velocity = root.AssemblyLinearVelocity or root.Velocity
    return root.Position + (velocity * getgenv().Config.Prediction)
end

local function ResolveTarget(character)
    if not getgenv().Config.ResolverEnabled then return character end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return character end
    
    if getgenv().Config.ResolverMethod == "MoveDirection" then
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0 then
            root.CFrame = CFrame.new(root.Position + (moveDir * 2))
        end
    elseif getgenv().Config.ResolverMethod == "Velocity" then
        local velocity = root.AssemblyLinearVelocity or root.Velocity
        if velocity.Magnitude > 1 then
            root.CFrame = CFrame.new(root.Position + velocity.Unit)
        end
    elseif getgenv().Config.ResolverMethod == "Hybrid" then
        local velocity = root.AssemblyLinearVelocity or root.Velocity
        local moveDir = humanoid.MoveDirection
        if velocity.Magnitude > 1 and moveDir.Magnitude > 0 then
            local avgDir = (velocity.Unit + moveDir).Unit
            root.CFrame = CFrame.new(root.Position + avgDir * 1.5)
        end
    end
    
    return character
end

local function IsTargetValid(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Check if downed
    if getgenv().Config.IgnoreDowned then
        if humanoid.Health < humanoid.MaxHealth * 0.01 or humanoid.PlatformStand then
            return false
        end
    end
    
    -- Visible check
    if getgenv().Config.VisibleCheck then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and LP.Character then
            local ray = Ray.new(Camera.CFrame.Position, (root.Position - Camera.CFrame.Position).Unit * 1000)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LP.Character, character})
            if hit and hit.Parent ~= character then
                return false
            end
        end
    end
    
    return true
end

local function GetTargetPriority(character)
    if not getgenv().Config.PrioritizeLowHealth then return 0 end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end
    
    local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100
    if healthPercent <= getgenv().Config.HealthThreshold then
        return 100 - healthPercent -- Lower health = higher priority
    end
    
    return 0
end

--// ITEM ASYLUM MELEE HITBOX EXTENDER
local MeleeVisualizePart = nil
local OriginalMeleeSizes = {}

-- Hook into Item Asylum's melee weapon system
local function GetCurrentMeleeWeapon()
    if not LP.Character then return nil end
    
    -- Item Asylum weapons are typically tools
    for _, tool in pairs(LP.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
            -- Check if it's a melee weapon (has melee-related scripts/attributes)
            local config = tool:FindFirstChild("Configuration") or tool:FindFirstChild("Config")
            if config and (config:FindFirstChild("Damage") or tool:FindFirstChild("Melee")) then
                return tool
            end
            -- Also check for common Item Asylum melee weapons
            if tool.Name:lower():find("knife") or tool.Name:lower():find("sword") 
                or tool.Name:lower():find("bat") or tool.Name:lower():find("katana")
                or tool.Name:lower():find("real") or tool.Name:lower():find("melee") then
                return tool
            end
        end
    end
    return nil
end

local function CreateMeleeVisualization()
    if MeleeVisualizePart then return MeleeVisualizePart end
    
    local part = Instance.new("Part")
    part.Name = "AsylumMeleeVisual"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.7
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Material = Enum.Material.Neon
    part.Size = Vector3.new(1, 1, 1)
    part.Parent = workspace
    
    MeleeVisualizePart = part
    return part
end

-- Modify the weapon's actual hitbox detection
local function ModifyWeaponHitbox(weapon)
    if not weapon or not weapon:FindFirstChild("Handle") then return end
    
    local handle = weapon.Handle
    
    -- Store original size if not already stored
    if not OriginalMeleeSizes[weapon] then
        OriginalMeleeSizes[weapon] = handle.Size
    end
    
    if getgenv().Config.MeleeExtenderEnabled then
        -- Extend the weapon's handle hitbox
        local newSize = Vector3.new(
            getgenv().Config.MeleeHitboxSize,
            OriginalMeleeSizes[weapon].Y + getgenv().Config.MeleeRange,
            getgenv().Config.MeleeHitboxSize
        )
        
        handle.Size = newSize
        handle.Transparency = 0.9
        handle.CanCollide = false
        
        -- Extend CFrame forward for reach
        if getgenv().Config.MeleeAutoTarget and Locked and Locked.Parent then
            -- Point weapon towards locked target
            local targetRoot = Locked.Parent:FindFirstChild("HumanoidRootPart")
            if targetRoot and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                local direction = (targetRoot.Position - LP.Character.HumanoidRootPart.Position).Unit
                local distance = getgenv().Config.MeleeRange
                handle.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(direction * distance)
            end
        end
    else
        -- Restore original size
        handle.Size = OriginalMeleeSizes[weapon]
        handle.Transparency = handle.Transparency
    end
end

local function UpdateMeleeHitbox()
    if not getgenv().Config.MeleeExtenderEnabled then
        if MeleeVisualizePart then
            MeleeVisualizePart.Parent = nil
        end
        
        -- Restore all weapon sizes
        for weapon, originalSize in pairs(OriginalMeleeSizes) do
            if weapon and weapon:FindFirstChild("Handle") then
                weapon.Handle.Size = originalSize
            end
        end
        return
    end
    
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local root = LP.Character.HumanoidRootPart
    local currentWeapon = GetCurrentMeleeWeapon()
    
    -- Modify current weapon
    if currentWeapon then
        ModifyWeaponHitbox(currentWeapon)
    end
    
    -- Calculate visualization position
    local targetPosition
    local lookDirection
    
    if getgenv().Config.MeleeAutoTarget and Locked and Locked.Parent then
        local targetRoot = Locked.Parent:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            lookDirection = (targetRoot.Position - root.Position).Unit
        else
            lookDirection = root.CFrame.LookVector
        end
    else
        lookDirection = Camera.CFrame.LookVector
    end
    
    targetPosition = root.Position + (lookDirection * getgenv().Config.MeleeRange)
    
    -- Update visualization
    if getgenv().Config.MeleeVisualize then
        local visual = CreateMeleeVisualization()
        visual.Size = Vector3.new(
            getgenv().Config.MeleeHitboxSize,
            getgenv().Config.MeleeHitboxSize,
            getgenv().Config.MeleeHitboxSize
        )
        visual.CFrame = CFrame.new(targetPosition)
        visual.Parent = workspace
    elseif MeleeVisualizePart then
        MeleeVisualizePart.Parent = nil
    end
    
    -- Extend enemy hitboxes for easier hitting
    for _, enemy in pairs(TargetCache) do
        if enemy.Parent then
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local enemyHum = enemy:FindFirstChildOfClass("Humanoid")
            
            if enemyRoot and enemyHum and enemyHum.Health > 0 then
                local distance = (targetPosition - enemyRoot.Position).Magnitude
                
                if distance < (getgenv().Config.MeleeHitboxSize + 3) then
                    -- Expand enemy hitbox when in range
                    enemyRoot.Size = Vector3.new(
                        getgenv().Config.MeleeHitboxSize,
                        enemyRoot.Size.Y,
                        getgenv().Config.MeleeHitboxSize
                    )
                    enemyRoot.Transparency = 0.8
                    enemyRoot.CanCollide = false
                else
                    -- Reset when out of range
                    if enemyRoot.Size.X > 3 then
                        enemyRoot.Size = Vector3.new(2, 2, 1)
                        enemyRoot.Transparency = 1
                    end
                end
            end
        end
    end
end

-- Monitor for new weapons being equipped
if LP.Character then
    LP.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and getgenv().Config.MeleeExtenderEnabled then
            task.wait(0.1)
            ModifyWeaponHitbox(child)
        end
    end)
    
    LP.Character.ChildRemoving:Connect(function(child)
        if child:IsA("Tool") and OriginalMeleeSizes[child] then
            if child:FindFirstChild("Handle") then
                child.Handle.Size = OriginalMeleeSizes[child]
            end
            OriginalMeleeSizes[child] = nil
        end
    end)
end

--// ESP FUNCTIONS
local function CreateESP(character)
    if ESPObjects[character] then return end
    
    local espFolder = {
        Box = {},
        Tracer = nil,
        Name = nil,
        Health = nil,
        Distance = nil
    }
    
    -- Box ESP (4 lines forming a square)
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = getgenv().Config.ESPColor
        line.Thickness = 1.5
        line.Transparency = 1
        espFolder.Box[i] = line
    end
    
    -- Tracer Line
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = getgenv().Config.ESPColor
    tracer.Thickness = 1.5
    tracer.Transparency = 1
    espFolder.Tracer = tracer
    
    -- Name Text
    local nameText = Drawing.new("Text")
    nameText.Visible = false
    nameText.Color = getgenv().Config.ESPColor
    nameText.Size = 16
    nameText.Center = true
    nameText.Outline = true
    nameText.Font = 2
    espFolder.Name = nameText
    
    -- Health Text
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Color = Color3.fromRGB(0, 255, 0)
    healthText.Size = 14
    healthText.Center = true
    healthText.Outline = true
    healthText.Font = 2
    espFolder.Health = healthText
    
    -- Distance Text
    local distText = Drawing.new("Text")
    distText.Visible = false
    distText.Color = Color3.fromRGB(255, 255, 255)
    distText.Size = 14
    distText.Center = true
    distText.Outline = true
    distText.Font = 2
    espFolder.Distance = distText
    
    ESPObjects[character] = espFolder
end

local function RemoveESP(character)
    if not ESPObjects[character] then return end
    
    for _, line in pairs(ESPObjects[character].Box) do
        line:Remove()
    end
    
    if ESPObjects[character].Tracer then ESPObjects[character].Tracer:Remove() end
    if ESPObjects[character].Name then ESPObjects[character].Name:Remove() end
    if ESPObjects[character].Health then ESPObjects[character].Health:Remove() end
    if ESPObjects[character].Distance then ESPObjects[character].Distance:Remove() end
    
    ESPObjects[character] = nil
end

local function UpdateESP(character, isTarget, isTeammate)
    if not ESPObjects[character] then CreateESP(character) end
    
    local espFolder = ESPObjects[character]
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        -- Hide all ESP elements
        for _, line in pairs(espFolder.Box) do line.Visible = false end
        if espFolder.Tracer then espFolder.Tracer.Visible = false end
        if espFolder.Name then espFolder.Name.Visible = false end
        if espFolder.Health then espFolder.Health.Visible = false end
        if espFolder.Distance then espFolder.Distance.Visible = false end
        return
    end
    
    -- Determine ESP color based on state
    local espColor = getgenv().Config.ESPColor
    if isTarget then
        espColor = getgenv().Config.TargetColor -- Red for locked target
    elseif isTeammate then
        espColor = getgenv().Config.TeamColor -- Green for teammates
    end
    
    -- Get player info
    local player = Players:GetPlayerFromCharacter(character)
    local displayName = player and player.Name or character.Name
    
    -- Calculate screen position
    local rootPos, rootVis = Camera:WorldToViewportPoint(rootPart.Position)
    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or rootPos
    local legPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
    
    if rootVis then
        -- Calculate box size
        local height = math.abs(headPos.Y - legPos.Y)
        local width = height / 2
        
        -- Box ESP
        if getgenv().Config.ESPEnabled then
            local topLeft = Vector2.new(rootPos.X - width/2, headPos.Y)
            local topRight = Vector2.new(rootPos.X + width/2, headPos.Y)
            local bottomLeft = Vector2.new(rootPos.X - width/2, legPos.Y)
            local bottomRight = Vector2.new(rootPos.X + width/2, legPos.Y)
            
            -- Top line
            espFolder.Box[1].From = topLeft
            espFolder.Box[1].To = topRight
            espFolder.Box[1].Visible = true
            espFolder.Box[1].Color = espColor
            espFolder.Box[1].Thickness = isTarget and 2.5 or 1.5 -- Thicker for target
            
            -- Bottom line
            espFolder.Box[2].From = bottomLeft
            espFolder.Box[2].To = bottomRight
            espFolder.Box[2].Visible = true
            espFolder.Box[2].Color = espColor
            espFolder.Box[2].Thickness = isTarget and 2.5 or 1.5
            
            -- Left line
            espFolder.Box[3].From = topLeft
            espFolder.Box[3].To = bottomLeft
            espFolder.Box[3].Visible = true
            espFolder.Box[3].Color = espColor
            espFolder.Box[3].Thickness = isTarget and 2.5 or 1.5
            
            -- Right line
            espFolder.Box[4].From = topRight
            espFolder.Box[4].To = bottomRight
            espFolder.Box[4].Visible = true
            espFolder.Box[4].Color = espColor
            espFolder.Box[4].Thickness = isTarget and 2.5 or 1.5
        else
            for _, line in pairs(espFolder.Box) do line.Visible = false end
        end
        
        -- Tracer ESP
        if getgenv().Config.TracerEnabled and espFolder.Tracer then
            local tracerStart
            if getgenv().Config.TracerOrigin == "Bottom" then
                tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            elseif getgenv().Config.TracerOrigin == "Center" then
                tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            else -- Mouse
                tracerStart = UIS:GetMouseLocation()
            end
            
            espFolder.Tracer.From = tracerStart
            espFolder.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
            espFolder.Tracer.Visible = true
            espFolder.Tracer.Color = espColor
            espFolder.Tracer.Thickness = isTarget and 2.5 or 1.5 -- Thicker for target
        else
            if espFolder.Tracer then espFolder.Tracer.Visible = false end
        end
        
        -- Name ESP
        if getgenv().Config.NameESP and espFolder.Name then
            local namePrefix = ""
            if isTarget then namePrefix = "[TARGET] " end
            if isTeammate then namePrefix = "[TEAM] " end
            
            espFolder.Name.Text = namePrefix .. displayName
            espFolder.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
            espFolder.Name.Visible = true
            espFolder.Name.Color = espColor
            espFolder.Name.Size = isTarget and 18 or 16 -- Bigger text for target
        else
            if espFolder.Name then espFolder.Name.Visible = false end
        end
        
        -- Health ESP
        if getgenv().Config.HealthESP and espFolder.Health then
            local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
            espFolder.Health.Text = tostring(healthPercent) .. "%"
            espFolder.Health.Position = Vector2.new(rootPos.X, legPos.Y + 5)
            espFolder.Health.Visible = true
            
            -- Color based on health
            if healthPercent > 75 then
                espFolder.Health.Color = Color3.fromRGB(0, 255, 0)
            elseif healthPercent > 50 then
                espFolder.Health.Color = Color3.fromRGB(255, 255, 0)
            elseif healthPercent > 25 then
                espFolder.Health.Color = Color3.fromRGB(255, 165, 0)
            else
                espFolder.Health.Color = Color3.fromRGB(255, 0, 0)
            end
        else
            if espFolder.Health then espFolder.Health.Visible = false end
        end
        
        -- Distance ESP
        if getgenv().Config.DistanceESP and espFolder.Distance and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local distance = math.floor((LP.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude)
            espFolder.Distance.Text = tostring(distance) .. "m"
            espFolder.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 20)
            espFolder.Distance.Visible = true
            espFolder.Distance.Color = Color3.fromRGB(255, 255, 255)
        else
            if espFolder.Distance then espFolder.Distance.Visible = false end
        end
    else
        -- Not visible, hide all
        for _, line in pairs(espFolder.Box) do line.Visible = false end
        if espFolder.Tracer then espFolder.Tracer.Visible = false end
        if espFolder.Name then espFolder.Name.Visible = false end
        if espFolder.Health then espFolder.Health.Visible = false end
        if espFolder.Distance then espFolder.Distance.Visible = false end
    end
end

--// HELPER: BULLET TRACER
local function CreateBulletTracer(from, to)
    if not getgenv().Config.BulletTracers then return end
    local p = Instance.new("Part", workspace)
    p.Anchored = true; p.CanCollide = false; p.Transparency = 1
    p.Size = Vector3.new(0.1, 0.1, 0.1)
    local a0 = Instance.new("Attachment", p); a0.WorldPosition = from
    local a1 = Instance.new("Attachment", p); a1.WorldPosition = to
    local b = Instance.new("Beam", p)
    b.Attachment0 = a0; b.Attachment1 = a1; b.Color = ColorSequence.new(getgenv().Config.TargetColor)
    b.Width0 = 0.15; b.Width1 = 0.15; b.FaceCamera = true
    b.LightEmission = 1; b.LightInfluence = 0
    game:GetService("Debris"):AddItem(p, 0.5)
end

--// CROSSHAIR DRAWING
local Crosshair = {
    Horizontal = Drawing.new("Line"),
    Vertical = Drawing.new("Line")
}

local function UpdateCrosshair()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local size = getgenv().Config.CrosshairSize
    
    if getgenv().Config.ShowCrosshair then
        -- Horizontal line
        Crosshair.Horizontal.From = Vector2.new(center.X - size, center.Y)
        Crosshair.Horizontal.To = Vector2.new(center.X + size, center.Y)
        Crosshair.Horizontal.Color = getgenv().Config.CrosshairColor
        Crosshair.Horizontal.Thickness = getgenv().Config.CrosshairThickness
        Crosshair.Horizontal.Visible = true
        
        -- Vertical line
        Crosshair.Vertical.From = Vector2.new(center.X, center.Y - size)
        Crosshair.Vertical.To = Vector2.new(center.X, center.Y + size)
        Crosshair.Vertical.Color = getgenv().Config.CrosshairColor
        Crosshair.Vertical.Thickness = getgenv().Config.CrosshairThickness
        Crosshair.Vertical.Visible = true
    else
        Crosshair.Horizontal.Visible = false
        Crosshair.Vertical.Visible = false
    end
end

--// CURSOR LOCK FUNCTION
local function UpdateCursorLock()
    if not getgenv().Config.CursorLock or not Locked or not IsAiming then return end
    
    local targetPos = Locked.Position
    
    -- Apply prediction for cursor lock
    if getgenv().Config.Prediction and Locked.Parent then
        local predicted = GetPredictedPosition(Locked.Parent)
        if predicted then
            local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
            if aimPart then
                targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
            end
        end
    end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    
    if onScreen then
        local currentMouse = UIS:GetMouseLocation()
        local targetMouse = Vector2.new(screenPos.X, screenPos.Y)
        
        -- Calculate distance to target
        local distance = (targetMouse - currentMouse).Magnitude
        
        -- Only move if not already on target (prevents jittering)
        if distance > 1 then
            -- Apply smoothness
            local smoothFactor = 1 - getgenv().Config.Smoothness
            local newMouse = currentMouse:Lerp(targetMouse, smoothFactor)
            
            -- Calculate delta movement
            local delta = newMouse - currentMouse
            
            -- Move cursor using relative movement
            mousemoverel(delta.X, delta.Y)
        end
    end
end

--// METATABLE HOOKS - IMPROVED SILENT AIM
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index
local oldNewindex = mt.__newindex

setreadonly(mt, false)

-- Method 1: Raycast Hook (Universal - works with most FPS games)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if not checkcaller() then
        -- Raycast silent aim
        if getgenv().Config.Method1_Silent and Locked and IsAiming then
            if method == "Raycast" and (self == workspace or tostring(self) == "Workspace") then
                local targetPos = Locked.Position
                
                -- Apply prediction
                if getgenv().Config.Prediction > 0 and Locked.Parent then
                    local predicted = GetPredictedPosition(Locked.Parent)
                    if predicted then
                        local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
                        if aimPart then
                            targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
                        else
                            targetPos = predicted
                        end
                    end
                end
                
                -- Modify raycast direction (args[2] is the direction vector)
                if args[1] and typeof(args[1]) == "Vector3" then
                    local origin = args[1]
                    local direction = (targetPos - origin).Unit * 1000
                    args[2] = direction
                    CreateBulletTracer(origin, targetPos)
                end
            end
            
            -- FindPartOnRay hook (older games)
            if (method == "FindPartOnRay" or method == "findPartOnRay") and (self == workspace or tostring(self) == "Workspace") then
                local targetPos = Locked.Position
                
                if getgenv().Config.Prediction > 0 and Locked.Parent then
                    local predicted = GetPredictedPosition(Locked.Parent)
                    if predicted then
                        local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
                        if aimPart then
                            targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
                        else
                            targetPos = predicted
                        end
                    end
                end
                
                -- Modify ray
                if args[1] and typeof(args[1]) == "Ray" then
                    local origin = args[1].Origin
                    local direction = (targetPos - origin).Unit * 1000
                    args[1] = Ray.new(origin, direction)
                    CreateBulletTracer(origin, targetPos)
                end
            end
            
            -- FindPartOnRayWithIgnoreList and FindPartOnRayWithWhitelist
            if (method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") 
                and (self == workspace or tostring(self) == "Workspace") then
                local targetPos = Locked.Position
                
                if getgenv().Config.Prediction > 0 and Locked.Parent then
                    local predicted = GetPredictedPosition(Locked.Parent)
                    if predicted then
                        targetPos = predicted
                    end
                end
                
                if args[1] and typeof(args[1]) == "Ray" then
                    local origin = args[1].Origin
                    local direction = (targetPos - origin).Unit * 1000
                    args[1] = Ray.new(origin, direction)
                    CreateBulletTracer(origin, targetPos)
                end
            end
            
            -- FireServer/InvokeServer hook for remote-based games
            if (method == "FireServer" or method == "InvokeServer") and getgenv().Config.Method3_Silent then
                -- Check if this is a shooting remote
                if self.Name:lower():find("shoot") or self.Name:lower():find("fire") 
                    or self.Name:lower():find("gun") or self.Name:lower():find("damage")
                    or self.Name:lower():find("hit") or self.Name:lower():find("bullet") then
                    
                    local targetPos = Locked.Position
                    
                    -- Apply prediction
                    if getgenv().Config.Prediction > 0 and Locked.Parent then
                        local predicted = GetPredictedPosition(Locked.Parent)
                        if predicted then
                            local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
                            if aimPart then
                                targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
                            end
                        end
                    end
                    
                    -- Try to find and replace position/direction arguments
                    for i, arg in pairs(args) do
                        if typeof(arg) == "Vector3" then
                            -- Check if it's a position (closer to camera) or direction (unit vector)
                            if arg.Magnitude < 10 then -- Likely a direction
                                args[i] = (targetPos - Camera.CFrame.Position).Unit
                            else -- Likely a position
                                args[i] = targetPos
                            end
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(Camera.CFrame.Position, targetPos)
                        elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            -- Replace part argument with target part
                            args[i] = Locked
                        end
                    end
                    
                    CreateBulletTracer(Camera.CFrame.Position, targetPos)
                end
            end
        end
        
        -- Method 4: Namecall Spy (catches all remote calls)
        if getgenv().Config.Method4_Namecall and Locked and IsAiming then
            -- Hook all remotes regardless of name
            if method == "FireServer" or method == "InvokeServer" then
                local targetPos = Locked.Position
                
                -- Apply prediction
                if getgenv().Config.Prediction > 0 and Locked.Parent then
                    local predicted = GetPredictedPosition(Locked.Parent)
                    if predicted then
                        local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
                        if aimPart then
                            targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
                        else
                            targetPos = predicted
                        end
                    end
                end
                
                -- Advanced argument modification
                local modified = false
                
                for i = 1, #args do
                    local arg = args[i]
                    local argType = typeof(arg)
                    
                    if argType == "Vector3" then
                        -- Check if it's a direction vector or position
                        local magnitude = arg.Magnitude
                        
                        if magnitude > 0.9 and magnitude < 1.1 then
                            -- Likely a unit direction vector
                            args[i] = (targetPos - Camera.CFrame.Position).Unit
                            modified = true
                        elseif magnitude > 10 then
                            -- Likely a position vector
                            args[i] = targetPos
                            modified = true
                        else
                            -- Ambiguous, try as direction first
                            args[i] = (targetPos - Camera.CFrame.Position).Unit
                            modified = true
                        end
                    elseif argType == "CFrame" then
                        -- Replace with aim CFrame
                        args[i] = CFrame.new(Camera.CFrame.Position, targetPos)
                        modified = true
                    elseif argType == "Instance" then
                        -- Check if it's a BasePart
                        if arg:IsA("BasePart") then
                            args[i] = Locked
                            modified = true
                        end
                    elseif argType == "Ray" then
                        -- Replace ray
                        local origin = Camera.CFrame.Position
                        args[i] = Ray.new(origin, (targetPos - origin).Unit * 1000)
                        modified = true
                    elseif argType == "table" then
                        -- Check if table contains position/direction data
                        for key, value in pairs(arg) do
                            if typeof(value) == "Vector3" then
                                if key:lower():find("pos") or key:lower():find("target") or key:lower():find("hit") then
                                    args[i][key] = targetPos
                                    modified = true
                                elseif key:lower():find("dir") or key:lower():find("angle") then
                                    args[i][key] = (targetPos - Camera.CFrame.Position).Unit
                                    modified = true
                                end
                            elseif typeof(value) == "CFrame" then
                                args[i][key] = CFrame.new(Camera.CFrame.Position, targetPos)
                                modified = true
                            elseif typeof(value) == "Instance" and value:IsA("BasePart") then
                                args[i][key] = Locked
                                modified = true
                            end
                        end
                    end
                end
                
                -- Create tracer if we modified anything
                if modified then
                    CreateBulletTracer(Camera.CFrame.Position, targetPos)
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

-- Method 2: Mouse Hook (works with games that use Mouse.Hit/Mouse.Target)
mt.__index = newcclosure(function(self, key)
    if not checkcaller() then
        if getgenv().Config.Method2_Silent and Locked and IsAiming then
            if self == Mouse or self:IsA("Mouse") then
                local targetPos = Locked.Position
                
                -- Apply prediction
                if getgenv().Config.Prediction > 0 and Locked.Parent then
                    local predicted = GetPredictedPosition(Locked.Parent)
                    if predicted then
                        local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
                        if aimPart then
                            targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
                        end
                    end
                end
                
                if key == "Hit" then
                    return CFrame.new(targetPos)
                elseif key == "Target" then
                    return Locked
                elseif key == "X" then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    return pos.X
                elseif key == "Y" then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPos)
                    return pos.Y
                elseif key == "UnitRay" then
                    local origin = Camera.CFrame.Position
                    return Ray.new(origin, (targetPos - origin).Unit)
                end
            end
        end
        
        -- UserInputService hook for GetMouseLocation
        if getgenv().Config.Method2_Silent and Locked and IsAiming then
            if tostring(self) == "UserInputService" then
                if key == "GetMouseLocation" then
                    return function()
                        local targetPos = Locked.Position
                        if getgenv().Config.Prediction > 0 and Locked.Parent then
                            local predicted = GetPredictedPosition(Locked.Parent)
                            if predicted then
                                targetPos = predicted
                            end
                        end
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                        if onScreen then
                            return Vector2.new(screenPos.X, screenPos.Y)
                        end
                        return oldIndex(self, key)()
                    end
                end
            end
        end
    end
    
    return oldIndex(self, key)
end)

-- Method 3: Camera CFrame Hook (works with camera-based aiming)
local oldCameraCFrame
mt.__newindex = newcclosure(function(self, key, value)
    if not checkcaller() then
        if getgenv().Config.Method1_Silent and Locked and IsAiming then
            if self == Camera and key == "CFrame" then
                -- Don't interfere with camera aim if both are enabled
                if not getgenv().Config.CameraAim then
                    oldCameraCFrame = value
                end
            end
        end
    end
    
    return oldNewindex(self, key, value)
end)

setreadonly(mt, true)

--// UI TABS
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local MiscTab = Window:CreateTab("Character", 4483362458)
local ItemTab = Window:CreateTab("Item Asylum", 4335489011)
local SettingsTab = Window:CreateTab("Settings", 4370341699)

--- COMBAT ---
CombatTab:CreateSection("Silent Aim Methods")
CombatTab:CreateToggle({Name = "Method 1: Raycast", CurrentValue = false, Callback = function(v) getgenv().Config.Method1_Silent = v end})
CombatTab:CreateLabel("└ Raycasting games (Modern FPS)")

CombatTab:CreateToggle({Name = "Method 2: Mouse Hook", CurrentValue = false, Callback = function(v) getgenv().Config.Method2_Silent = v end})
CombatTab:CreateLabel("└ Mouse.Hit/Target based games")

CombatTab:CreateToggle({Name = "Method 3: Remote", CurrentValue = false, Callback = function(v) getgenv().Config.Method3_Silent = v end})
CombatTab:CreateLabel("└ Named remotes (shoot/fire/gun)")

CombatTab:CreateToggle({Name = "Method 4: Namecall Spy", CurrentValue = false, Callback = function(v) getgenv().Config.Method4_Namecall = v end})
CombatTab:CreateLabel("└ All remotes (Universal catch-all)")

CombatTab:CreateSection("Other Aimbot Types")
CombatTab:CreateToggle({Name = "Camera Aimbot", CurrentValue = false, Callback = function(v) getgenv().Config.CameraAim = v end})
CombatTab:CreateToggle({Name = "Cursor Lock (Sticky)", CurrentValue = false, Callback = function(v) getgenv().Config.CursorLock = v end})

CombatTab:CreateSection("Auto Features")
CombatTab:CreateToggle({Name = "Trigger Bot", CurrentValue = false, Callback = function(v) getgenv().Config.TriggerBot = v end})
CombatTab:CreateToggle({Name = "Auto Shoot", CurrentValue = false, Callback = function(v) getgenv().Config.AutoShoot = v end})

CombatTab:CreateSection("Method Guide")
CombatTab:CreateLabel("Try methods in order 1→2→3→4")
CombatTab:CreateLabel("Method 4 is most aggressive")
CombatTab:CreateLabel("Can combine multiple methods")
CombatTab:CreateLabel("Enable bullet tracers to test")

CombatTab:CreateSection("Targeting")
CombatTab:CreateDropdown({Name = "Target Mode", Options = {"All", "Players", "NPCs"}, CurrentOption = {"All"}, Callback = function(v) getgenv().Config.TargetMode = v[1] end})
CombatTab:CreateDropdown({Name = "Target Bone", Options = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}, CurrentOption = {"Head"}, Callback = function(v) getgenv().Config.AimPart = v[1] end})
CombatTab:CreateToggle({Name = "Sticky Target", CurrentValue = false, Callback = function(v) getgenv().Config.StickyTarget = v; if not v then StickyLockedTarget = nil end end})
CombatTab:CreateToggle({Name = "Closest to Mouse", CurrentValue = true, Callback = function(v) getgenv().Config.ClosestToMouse = v end})
CombatTab:CreateToggle({Name = "Require Aim Key (RMB)", CurrentValue = false, Callback = function(v) getgenv().Config.AimKeybind = v end})

CombatTab:CreateSection("Aim Assist")
CombatTab:CreateSlider({Name = "Smoothness", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.2, Callback = function(v) getgenv().Config.Smoothness = v end})
CombatTab:CreateSlider({Name = "Prediction", Range = {0, 0.5}, Increment = 0.01, CurrentValue = 0.13, Callback = function(v) getgenv().Config.Prediction = v end})
CombatTab:CreateSlider({Name = "Shake Reduction %", Range = {0, 100}, Increment = 5, CurrentValue = 0, Callback = function(v) getgenv().Config.ShakeReduction = v end})

CombatTab:CreateSection("FOV & Checks")
CombatTab:CreateSlider({Name = "FOV Size", Range = {10, 800}, Increment = 5, CurrentValue = 150, Callback = function(v) getgenv().Config.FOVRadius = v end})
CombatTab:CreateToggle({Name = "Wall Check", CurrentValue = true, Callback = function(v) getgenv().Config.WallCheck = v end})
CombatTab:CreateToggle({Name = "Visible Check", CurrentValue = true, Callback = function(v) getgenv().Config.VisibleCheck = v end})
CombatTab:CreateToggle({Name = "Ignore Downed", CurrentValue = true, Callback = function(v) getgenv().Config.IgnoreDowned = v end})

CombatTab:CreateSection("Advanced Targeting")
CombatTab:CreateToggle({Name = "Prioritize Low Health", CurrentValue = false, Callback = function(v) getgenv().Config.PrioritizeLowHealth = v end})
CombatTab:CreateSlider({Name = "Health Threshold %", Range = {1, 100}, Increment = 1, CurrentValue = 50, Callback = function(v) getgenv().Config.HealthThreshold = v end})

CombatTab:CreateSection("Resolver (Anti-Desync)")
CombatTab:CreateToggle({Name = "Enable Resolver", CurrentValue = false, Callback = function(v) getgenv().Config.ResolverEnabled = v end})
CombatTab:CreateDropdown({Name = "Resolver Method", Options = {"MoveDirection", "Velocity", "Hybrid"}, CurrentOption = {"MoveDirection"}, Callback = function(v) getgenv().Config.ResolverMethod = v[1] end})

--- VISUALS ---
VisualsTab:CreateSection("FOV Circle")
VisualsTab:CreateToggle({Name = "Show FOV Circle", CurrentValue = true, Callback = function(v) getgenv().Config.ShowFOV = v end})
VisualsTab:CreateToggle({Name = "FOV Filled", CurrentValue = false, Callback = function(v) getgenv().Config.FOVFilled = v end})
VisualsTab:CreateSlider({Name = "Fill Transparency", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.1, Callback = function(v) getgenv().Config.FOVFillTransparency = v end})

VisualsTab:CreateSection("Crosshair")
VisualsTab:CreateToggle({Name = "Show Crosshair", CurrentValue = false, Callback = function(v) getgenv().Config.ShowCrosshair = v end})
VisualsTab:CreateSlider({Name = "Crosshair Size", Range = {5, 30}, Increment = 1, CurrentValue = 10, Callback = function(v) getgenv().Config.CrosshairSize = v end})
VisualsTab:CreateSlider({Name = "Thickness", Range = {1, 5}, Increment = 0.5, CurrentValue = 2, Callback = function(v) getgenv().Config.CrosshairThickness = v end})
VisualsTab:CreateColorPicker({Name = "Crosshair Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(v) getgenv().Config.CrosshairColor = v end})

VisualsTab:CreateSection("ESP Components")
VisualsTab:CreateToggle({Name = "Box ESP", CurrentValue = false, Callback = function(v) getgenv().Config.ESPEnabled = v end})
VisualsTab:CreateToggle({Name = "Name ESP", CurrentValue = false, Callback = function(v) getgenv().Config.NameESP = v end})
VisualsTab:CreateToggle({Name = "Health ESP", CurrentValue = false, Callback = function(v) getgenv().Config.HealthESP = v end})
VisualsTab:CreateToggle({Name = "Distance ESP", CurrentValue = false, Callback = function(v) getgenv().Config.DistanceESP = v end})
VisualsTab:CreateToggle({Name = "Tracers", CurrentValue = false, Callback = function(v) getgenv().Config.TracerEnabled = v end})
VisualsTab:CreateDropdown({Name = "Tracer Origin", Options = {"Bottom", "Center", "Mouse"}, CurrentOption = {"Bottom"}, Callback = function(v) getgenv().Config.TracerOrigin = v[1] end})
VisualsTab:CreateToggle({Name = "Ghost (Wallhack)", CurrentValue = false, Callback = function(v) getgenv().Config.GhostESP = v end})
VisualsTab:CreateToggle({Name = "Bullet Tracers", CurrentValue = false, Callback = function(v) getgenv().Config.BulletTracers = v end})

VisualsTab:CreateSection("Color Settings")
VisualsTab:CreateColorPicker({Name = "Enemy Color", Color = Color3.fromRGB(0, 255, 255), Callback = function(v) getgenv().Config.ESPColor = v end})
VisualsTab:CreateColorPicker({Name = "Target Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) getgenv().Config.TargetColor = v end})
VisualsTab:CreateColorPicker({Name = "Team Color", Color = Color3.fromRGB(0, 255, 0), Callback = function(v) getgenv().Config.TeamColor = v end})

VisualsTab:CreateSection("Team Settings")
VisualsTab:CreateToggle({Name = "Team Check (No Target)", CurrentValue = true, Callback = function(v) getgenv().Config.TeamCheck = v end})
VisualsTab:CreateToggle({Name = "Show Teammates ESP", CurrentValue = false, Callback = function(v) getgenv().Config.ShowTeammates = v end})

--- CHARACTER & MOVEMENT ---
MiscTab:CreateSection("Movement")
MiscTab:CreateSlider({Name = "WalkSpeed", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) getgenv().Config.WalkSpeed = v end})
MiscTab:CreateSlider({Name = "Jump Power", Range = {50, 200}, Increment = 5, CurrentValue = 50, Callback = function(v) getgenv().Config.JumpPower = v end})
MiscTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Callback = function(v) getgenv().Config.InfJump = v end})
MiscTab:CreateToggle({Name = "No-Tilt (Anti-Ragdoll)", CurrentValue = false, Callback = function(v) getgenv().Config.NoTilt = v end})
MiscTab:CreateToggle({Name = "No Slowdown", CurrentValue = false, Callback = function(v) getgenv().Config.NoSlowdown = v end})
MiscTab:CreateToggle({Name = "Auto Sprint", CurrentValue = false, Callback = function(v) getgenv().Config.AutoSprint = v end})

MiscTab:CreateSection("Hitbox Mod")
MiscTab:CreateToggle({Name = "Expand Hitboxes", CurrentValue = false, Callback = function(v) getgenv().Config.HitboxEnabled = v end})
MiscTab:CreateSlider({Name = "Hitbox Size", Range = {2, 50}, Increment = 1, CurrentValue = 10, Callback = function(v) getgenv().Config.HitboxSize = v end})
MiscTab:CreateSlider({Name = "Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.7, Callback = function(v) getgenv().Config.HitboxTransparency = v end})

--- ITEM ASYLUM ---
ItemTab:CreateSection("Melee Hitbox Extender")
ItemTab:CreateToggle({Name = "Enable Melee Extender", CurrentValue = false, Callback = function(v) getgenv().Config.MeleeExtenderEnabled = v end})
ItemTab:CreateSlider({Name = "Melee Range (Distance)", Range = {1, 30}, Increment = 0.5, CurrentValue = 5, Callback = function(v) getgenv().Config.MeleeRange = v end})
ItemTab:CreateSlider({Name = "Hitbox Size (Width)", Range = {2, 20}, Increment = 0.5, CurrentValue = 8, Callback = function(v) getgenv().Config.MeleeHitboxSize = v end})
ItemTab:CreateToggle({Name = "Auto Target Nearest", CurrentValue = false, Callback = function(v) getgenv().Config.MeleeAutoTarget = v end})
ItemTab:CreateToggle({Name = "Visualize Hitbox", CurrentValue = false, Callback = function(v) getgenv().Config.MeleeVisualize = v end})

ItemTab:CreateSection("How It Works")
ItemTab:CreateLabel("Modifies your weapon's handle size")
ItemTab:CreateLabel("Range = Forward distance from player")
ItemTab:CreateLabel("Size = Width/Height of weapon hitbox")
ItemTab:CreateLabel("Auto Target = Aims at locked enemy")
ItemTab:CreateLabel("Works with: Knives, Bats, Swords, etc.")

--- SETTINGS ---
SettingsTab:CreateSection("Configuration Management")
SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        SaveConfig()
    end
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        LoadConfig()
    end
})

SettingsTab:CreateButton({
    Name = "Export Config to Clipboard",
    Callback = function()
        local success, err = pcall(function()
            local configData = game:GetService("HttpService"):JSONEncode(getgenv().Config)
            setclipboard(configData)
            Rayfield:Notify({
                Title = "Config Exported",
                Content = "Config copied to clipboard!",
                Duration = 3,
                Image = 4483362458
            })
        end)
        if not success then
            Rayfield:Notify({
                Title = "Export Failed",
                Content = "Could not export config",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

SettingsTab:CreateButton({
    Name = "Import Config from Clipboard",
    Callback = function()
        local success, err = pcall(function()
            local clipboardData = getclipboard()
            local importedConfig = game:GetService("HttpService"):JSONDecode(clipboardData)
            
            -- Merge imported config
            for key, value in pairs(importedConfig) do
                if getgenv().Config[key] ~= nil then
                    getgenv().Config[key] = value
                end
            end
            
            Rayfield:Notify({
                Title = "Config Imported",
                Content = "Settings imported successfully!",
                Duration = 3,
                Image = 4483362458
            })
        end)
        if not success then
            Rayfield:Notify({
                Title = "Import Failed",
                Content = "Invalid config in clipboard",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

SettingsTab:CreateButton({
    Name = "Reset to Default",
    Callback = function()
        -- Reset all settings to default
        getgenv().Config = {
            TargetMode = "All",
            AimPart = "Head",
            AimKey = Enum.UserInputType.MouseButton2,
            AimKeybind = false,
            StickyTarget = false,
            ClosestToMouse = true,
            CameraAim = false,
            Method1_Silent = false,
            Method2_Silent = false,
            Method3_Silent = false,
            Method4_Namecall = false,
            CursorLock = false,
            TriggerBot = false,
            AutoShoot = false,
            Smoothness = 0.2,
            Prediction = 0.13,
            ShakeReduction = 0,
            FOVRadius = 150,
            WallCheck = true,
            TeamCheck = true,
            VisibleCheck = true,
            IgnoreDowned = true,
            PrioritizeLowHealth = false,
            HealthThreshold = 50,
            ResolverEnabled = false,
            ResolverMethod = "MoveDirection",
            ShowFOV = true,
            FOVFilled = false,
            FOVFillTransparency = 0.1,
            ESPEnabled = false,
            NameESP = false,
            HealthESP = false,
            DistanceESP = false,
            TracerEnabled = false,
            BulletTracers = false,
            ChamsEnabled = false,
            GhostESP = false,
            ESPColor = Color3.fromRGB(0, 255, 255),
            TargetColor = Color3.fromRGB(255, 0, 0),
            TeamColor = Color3.fromRGB(0, 255, 0),
            TracerOrigin = "Bottom",
            ShowTeammates = false,
            ShowCrosshair = false,
            CrosshairSize = 10,
            CrosshairColor = Color3.fromRGB(255, 255, 255),
            CrosshairThickness = 2,
            WalkSpeed = 16,
            JumpPower = 50,
            InfJump = false,
            NoTilt = false,
            NoSlowdown = false,
            AutoSprint = false,
            HitboxEnabled = false,
            HitboxSize = 10,
            HitboxTransparency = 0.7,
            MeleeExtenderEnabled = false,
            MeleeRange = 5,
            MeleeHitboxSize = 8,
            MeleeAutoTarget = false,
            MeleeVisualize = false
        }
        
        Rayfield:Notify({
            Title = "Config Reset",
            Content = "All settings reset to default!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

SettingsTab:CreateSection("Auto Save")
SettingsTab:CreateLabel("Config auto-saves every 30 seconds")
SettingsTab:CreateLabel("Config loads automatically on script start")
SettingsTab:CreateLabel("Location: workspace/" .. ConfigFolder)

SettingsTab:CreateSection("Script Info")
SettingsTab:CreateLabel("Version: V17.3 Advanced")
SettingsTab:CreateLabel("Asylum Elite - Unified Engine")
SettingsTab:CreateLabel("Features: Combat, ESP, Movement, Melee")

--// CORE UNIFIED ENGINE
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5

RunService.RenderStepped:Connect(function()
    -- Character modifications
    if LP.Character and LP.Character:FindFirstChild("Humanoid") then
        local hum = LP.Character.Humanoid
        hum.WalkSpeed = getgenv().Config.WalkSpeed
        hum.JumpPower = getgenv().Config.JumpPower
        
        if getgenv().Config.NoTilt then 
            hum.PlatformStand = false 
        end
        
        if getgenv().Config.NoSlowdown then
            hum.WalkSpeed = getgenv().Config.WalkSpeed -- Override slowdowns
        end
    end

    -- Update crosshair
    UpdateCrosshair()
    
    -- Update cursor lock
    UpdateCursorLock()
    
    -- Update melee hitbox extender
    UpdateMeleeHitbox()

    -- FOV Circle
    FOVCircle.Visible = getgenv().Config.ShowFOV
    FOVCircle.Radius = getgenv().Config.FOVRadius
    FOVCircle.Position = UIS:GetMouseLocation()
    FOVCircle.Color = getgenv().Config.ESPColor
    FOVCircle.Filled = getgenv().Config.FOVFilled
    FOVCircle.Transparency = getgenv().Config.FOVFilled and (1 - getgenv().Config.FOVFillTransparency) or 1
    
    -- Check if aim key is required
    if getgenv().Config.AimKeybind then
        IsAiming = UIS:IsMouseButtonPressed(getgenv().Config.AimKey)
    else
        IsAiming = true
    end
    
    local pot, dist = nil, getgenv().Config.FOVRadius
    local highestPriority = 0

    -- Sticky target logic
    if getgenv().Config.StickyTarget and StickyLockedTarget then
        if StickyLockedTarget.Parent and IsTargetValid(StickyLockedTarget.Parent) then
            local player = Players:GetPlayerFromCharacter(StickyLockedTarget.Parent)
            local isTeammate = player and player.Team == LP.Team and player ~= LP
            
            if not (getgenv().Config.TeamCheck and isTeammate) then
                pot = StickyLockedTarget
            else
                StickyLockedTarget = nil
            end
        else
            StickyLockedTarget = nil
        end
    end

    -- Target acquisition
    if not pot or not getgenv().Config.StickyTarget then
        for _, v in pairs(TargetCache) do
            if v.Parent and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                local char = v
                local player = Players:GetPlayerFromCharacter(char)
                
                -- Check if teammate
                local isTeammate = player and player.Team == LP.Team and player ~= LP
                
                -- Handle teammate ESP logic
                if getgenv().Config.TeamCheck and isTeammate and not getgenv().Config.ShowTeammates then 
                    RemoveESP(char)
                    continue 
                end
                
                local mode = getgenv().Config.TargetMode
                local isValid = (mode == "All") or (mode == "Players" and player) or (mode == "NPCs" and not player)

                if isValid and IsTargetValid(char) then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        -- Hitbox Logic
                        if getgenv().Config.HitboxEnabled and not isTeammate then
                            root.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                            root.Transparency = getgenv().Config.HitboxTransparency
                            root.CanCollide = false
                        else
                            root.Size = Vector3.new(2,2,1)
                            root.Transparency = 1
                        end

                        -- Chams/Ghost Logic
                        if getgenv().Config.GhostESP then
                            local hl = char:FindFirstChild("AsylumHighlight") or Instance.new("Highlight", char)
                            hl.Name = "AsylumHighlight"
                            hl.Enabled = true
                            
                            -- Color based on target/teammate status
                            if Locked and Locked.Parent == char then
                                hl.FillColor = getgenv().Config.TargetColor
                            elseif isTeammate then
                                hl.FillColor = getgenv().Config.TeamColor
                            else
                                hl.FillColor = getgenv().Config.ESPColor
                            end
                            
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        elseif char:FindFirstChild("AsylumHighlight") then
                            char.AsylumHighlight.Enabled = false
                        end

                        -- Targeting logic (skip teammates if TeamCheck is on)
                        if not (getgenv().Config.TeamCheck and isTeammate) and IsAiming then
                            local aim = char:FindFirstChild(getgenv().Config.AimPart) or root
                            
                            -- Apply resolver
                            if getgenv().Config.ResolverEnabled then
                                ResolveTarget(char)
                            end
                            
                            local aPos, aOn = Camera:WorldToViewportPoint(aim.Position)
                            if aOn then
                                local mDist
                                if getgenv().Config.ClosestToMouse then
                                    mDist = (Vector2.new(aPos.X, aPos.Y) - UIS:GetMouseLocation()).Magnitude
                                else
                                    -- Closest to player
                                    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                                        mDist = (LP.Character.HumanoidRootPart.Position - aim.Position).Magnitude
                                    else
                                        mDist = math.huge
                                    end
                                end
                                
                                -- Priority system
                                local priority = GetTargetPriority(char)
                                
                                if mDist < dist then
                                    if not getgenv().Config.WallCheck or #Camera:GetPartsObscuringTarget({aim.Position}, {LP.Character, char}) == 0 then
                                        if priority >= highestPriority then
                                            pot = aim
                                            dist = mDist
                                            highestPriority = priority
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Update ESP with target and teammate status
                    local isCurrentTarget = Locked and Locked.Parent == char
                    UpdateESP(char, isCurrentTarget, isTeammate)
                else
                    RemoveESP(char)
                end
            else
                RemoveESP(v)
            end
        end
    end
    
    Locked = pot
    
    -- Update sticky target
    if getgenv().Config.StickyTarget and Locked then
        StickyLockedTarget = Locked
    end
    
    -- Camera aimbot
    if Locked and getgenv().Config.CameraAim and IsAiming then
        local targetPos = Locked.Position
        
        -- Apply prediction
        if getgenv().Config.Prediction and Locked.Parent then
            local predicted = GetPredictedPosition(Locked.Parent)
            if predicted then
                local aimPart = Locked.Parent:FindFirstChild(getgenv().Config.AimPart)
                if aimPart then
                    targetPos = predicted + (aimPart.Position - Locked.Parent.HumanoidRootPart.Position)
                end
            end
        end
        
        -- Smooth camera aim
        local camCFrame = Camera.CFrame
        local targetLook = (targetPos - camCFrame.Position).Unit
        local currentLook = camCFrame.LookVector
        
        -- Apply smoothness
        local smoothFactor = 1 - getgenv().Config.Smoothness
        local newLook = currentLook:Lerp(targetLook, smoothFactor)
        
        Camera.CFrame = CFrame.new(camCFrame.Position, camCFrame.Position + newLook)
    end
    
    -- Trigger bot
    if getgenv().Config.TriggerBot and Locked and IsAiming then
        local mousePos = UIS:GetMouseLocation()
        local aimPos, aimVis = Camera:WorldToViewportPoint(Locked.Position)
        
        if aimVis then
            local distance = (Vector2.new(aimPos.X, aimPos.Y) - mousePos).Magnitude
            if distance < 20 then -- Within 20 pixels
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end
        end
    end
end)

--// Cleanup on character death/removal
workspace.DescendantRemoving:Connect(function(v)
    if v:IsA("Model") and ESPObjects[v] then
        RemoveESP(v)
    end
end)

--// Input Handlers
UIS.JumpRequest:Connect(function() 
    if getgenv().Config.InfJump and LP.Character then 
        LP.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping") 
    end 
end)

Rayfield:Notify({Title = "ASYLUM ELITE V17.3", Content = "Auto-Save Enabled | All Features Loaded!", Duration = 6})
