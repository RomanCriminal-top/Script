-- Rayfield UI Library Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services Optimization
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============================================
-- Anti-Cheat Detection & Logging
-- ============================================

local AntiCheatDetected = false
local AntiCheatTimer = 0
local ConfirmEnabled = false

local function LogEvent(message)
    local logFile = "anti_cheat_log.txt"
    local content = "[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. message .. "\n"
    pcall(function()
        writefile(logFile, readfile(logFile) .. content)
    end)
end

local function CheckAntiCheat()
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("Frame") then
            local name = gui.Name:lower()
            if name:find("anti") or name:find("ban") or name:find("detect") or name:find("cheat") then
                return true
            end
        end
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then
                local name = child.Name:lower()
                if name:find("anti") or name:find("ban") or name:find("detect") or name:find("cheat") then
                    return true
                end
            end
        end
    end
    return false
end

-- ============================================
-- Remote Events Finder & Hooking
-- ============================================

local function FindMovementEvents()
    local events = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            if name:find("move") or name:find("position") or name:find("update") or 
               name:find("sync") or name:find("loc") or name:find("pos") then
                table.insert(events, obj)
            end
        end
    end
    return events
end

local RemoteHooks = {}
local LastRemoteSend = 0

local function HookRemoteEvent(remote)
    if not remote then return end

    local originalFireServer = remote.FireServer
    local originalInvokeServer = remote.InvokeServer

    remote.FireServer = function(...)
        if AntiCheatDetected then return end

        local args = {...}

        for i, arg in ipairs(args) do
            if typeof(arg) == "Vector3" then
                local noise = Vector3.new(
                    (math.random() - 0.5) * 0.5,
                    (math.random() - 0.5) * 0.3,
                    (math.random() - 0.5) * 0.5
                )
                args[i] = arg + noise
            elseif typeof(arg) == "CFrame" then
                local randomRot = CFrame.Angles(
                    (math.random() - 0.5) * 0.01,
                    (math.random() - 0.5) * 0.01,
                    (math.random() - 0.5) * 0.01
                )
                args[i] = arg * randomRot
            end
        end

        local currentTime = tick()
        if currentTime - LastRemoteSend < 0.05 then
            local delay = 0.05 + math.random() * 0.05
            task.wait(delay)
        end
        LastRemoteSend = tick()

        return originalFireServer(remote, unpack(args))
    end

    remote.InvokeServer = function(...)
        if AntiCheatDetected then return end

        local args = {...}

        for i, arg in ipairs(args) do
            if typeof(arg) == "Vector3" then
                local noise = Vector3.new(
                    (math.random() - 0.5) * 0.5,
                    (math.random() - 0.5) * 0.3,
                    (math.random() - 0.5) * 0.5
                )
                args[i] = arg + noise
            elseif typeof(arg) == "CFrame" then
                local randomRot = CFrame.Angles(
                    (math.random() - 0.5) * 0.01,
                    (math.random() - 0.5) * 0.01,
                    (math.random() - 0.5) * 0.01
                )
                args[i] = arg * randomRot
            end
        end

        local currentTime = tick()
        if currentTime - LastRemoteSend < 0.05 then
            local delay = 0.05 + math.random() * 0.05
            task.wait(delay)
        end
        LastRemoteSend = tick()

        return originalInvokeServer(remote, unpack(args))
    end

    RemoteHooks[remote.Name] = {
        remote = remote,
        originalFire = originalFireServer,
        originalInvoke = originalInvokeServer
    }
end

local MovementEvents = FindMovementEvents()
for _, event in ipairs(MovementEvents) do
    HookRemoteEvent(event)
end

-- ============================================
-- Debug Hooking
-- ============================================

local function HookDebugFunctions()
    local debugLibrary = debug
    if debugLibrary then
        local original_getinfo = debugLibrary.getinfo
        local original_getlocal = debugLibrary.getlocal
        local original_getupvalue = debugLibrary.getupvalue

        debugLibrary.getinfo = function(...)
            local args = {...}
            if type(args[1]) == "number" and args[1] >= 0 then
                return nil
            end
            return original_getinfo(...)
        end

        debugLibrary.getlocal = function(...)
            return nil
        end

        debugLibrary.getupvalue = function(...)
            return nil
        end
    end
end
HookDebugFunctions()

-- ============================================
-- Spoof Humanoid Properties
-- ============================================

local Original_WalkSpeed = 16
local Original_JumpPower = 50

local function SpoofHumanoidProperties(humanoid)
    if not humanoid then return end

    local original_walkspeed = humanoid.WalkSpeed
    local original_jumppower = humanoid.JumpPower

    local metatable = getmetatable(humanoid) or {}
    local old_index = metatable.__index
    local old_newindex = metatable.__newindex

    metatable.__index = function(table, key)
        if key == "WalkSpeed" then
            return original_walkspeed
        elseif key == "JumpPower" then
            return original_jumppower
        end
        return old_index and old_index(table, key) or rawget(table, key)
    end

    metatable.__newindex = function(table, key, value)
        if key == "WalkSpeed" then
            original_walkspeed = value
            rawset(table, key, value)
        elseif key == "JumpPower" then
            original_jumppower = value
            rawset(table, key, value)
        else
            old_newindex and old_newindex(table, key, value) or rawset(table, key, value)
        end
    end

    setmetatable(humanoid, metatable)
end

local function SaveOriginalStats(char)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        Original_WalkSpeed = hum.WalkSpeed
        Original_JumpPower = hum.JumpPower
        SpoofHumanoidProperties(hum)
    end
end

if LocalPlayer.Character then SaveOriginalStats(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(char)
    SaveOriginalStats(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then SpoofHumanoidProperties(hum) end
end)

-- ============================================
-- Window Creation (Dark Theme)
-- ============================================

local Window = Rayfield:CreateWindow({
   Name = "@RomanCriminal script",
   Icon = 0,
   LoadingTitle = "script by @RomanCriminal",
   LoadingSubtitle = "script by @RomanCriminal",
   Theme = "Dark",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

task.spawn(function()
    task.wait(0.8)
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name:find("Rayfield") or gui:FindFirstChild("Main")) then
            gui.ClipsDescendants = true
            for _, v in ipairs(gui:GetDescendants()) do
                if v:IsA("Frame") or v:IsA("ScrollingFrame") then
                    v.ClipsDescendants = true
                end
            end
        end
    end
end)

-- ============================================
-- Main State Variables
-- ============================================

local ESP_Enabled = false
local Aimbot_Enabled = false
local Crosshair_Enabled = false

local Vis_Boxes = true
local Vis_Lines = true
local Vis_FOV = true
local Vis_Names = true
local Vis_Dist = true

local Aimbot_Smoothness = 0.4
local Aimbot_FOV = 150
local Crosshair_Size = 10

local Speed_Enabled = false
local WalkSpeed_Value = 16
local Jump_Enabled = false
local JumpPower_Value = 50
local InfJump_Enabled = false
local Noclip_Enabled = false
local GodMode_Enabled = false

local PlatformMode = "Under Player"
local PlatformSize_Value = 7
local WaitingForTarget = false
local PlatformsQueue = {}
local MaxPlatforms = 10

local SelectedColorName = "Gray"
local ColorTable = {
    ["Gray"] = Color3.fromRGB(150, 150, 150)
}

local function GetCurrentColor()
    if SelectedColorName == "Rainbow" then
        return Color3.fromHSV((tick() % 3) / 3, 1, 1)
    else
        return ColorTable[SelectedColorName] or Color3.fromRGB(150, 150, 150)
    end
end

-- ============================================
-- Status Indicator
-- ============================================

local StatusLabel = nil

local function UpdateStatus()
    if not StatusLabel then return end
    local esp = ESP_Enabled and "Вкл" or "Выкл"
    local aim = Aimbot_Enabled and "Вкл" or "Выкл"
    local status = AntiCheatDetected and "🔴 Опасность! Отключено" or "🟢 Защита активна"
    StatusLabel:SetText(status .. " | ESP: " .. esp .. " | Аимбот: " .. aim)
end

-- ============================================
-- Drawing Objects
-- ============================================

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

local Crosshair_H = Drawing.new("Line")
Crosshair_H.Thickness = 1.8
Crosshair_H.Visible = false

local Crosshair_V = Drawing.new("Line")
Crosshair_V.Thickness = 1.8
Crosshair_V.Visible = false

local Crosshair_Dot = Drawing.new("Circle")
Crosshair_Dot.Radius = 2.5
Crosshair_Dot.Filled = true
Crosshair_Dot.Visible = false

-- ============================================
-- ESP Cache
-- ============================================

local ESP_Cache = {}

local function CreateESP(player)
    if player == LocalPlayer then return end
    local Box = Drawing.new("Square")
    Box.Visible = false; Box.Thickness = 1.5; Box.Filled = false
    local Line = Drawing.new("Line")
    Line.Visible = false; Line.Thickness = 1.2
    local Text = Drawing.new("Text")
    Text.Visible = false; Text.Size = 13; Text.Center = true; Text.Outline = true; Text.OutlineColor = Color3.fromRGB(0, 0, 0); Text.Color = Color3.fromRGB(255, 255, 255)
    ESP_Cache[player] = {Box = Box, Line = Line, Text = Text}
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        ESP_Cache[player].Box:Remove()
        ESP_Cache[player].Line:Remove()
        ESP_Cache[player].Text:Remove()
        ESP_Cache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- ============================================
-- Helper Functions
-- ============================================

local function GetTargetPart(character)
    if not character then return nil end

    local standard = character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("Head") 
        or character:FindFirstChild("Torso") 
        or character:FindFirstChild("UpperTorso")
    if standard and standard:IsA("BasePart") then return standard end

    for _, v in ipairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            return v
        end
    end

    return nil
end

local function GetClosestPlayerToCenter(screenCenter)
    local closest, shortest = nil, Aimbot_FOV
    local players = Players:GetPlayers()

    for i = #players, 2, -1 do
        local j = math.random(i)
        players[i], players[j] = players[j], players[i]
    end

    for _, player in ipairs(players) do
        if player ~= LocalPlayer and player.Character then
            local part = GetTargetPart(player.Character)
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if part and (not hum or hum.Health > 0) then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < shortest then 
                        closest = part 
                        shortest = dist 
                        break
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================
-- Platform Manager
-- ============================================

local function SpawnPlatformAt(pos)
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(PlatformSize_Value, 1, PlatformSize_Value)
    platform.Position = pos
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = GetCurrentColor()
    platform.Parent = Workspace

    table.insert(PlatformsQueue, platform)
    if #PlatformsQueue > MaxPlatforms then
        local oldest = table.remove(PlatformsQueue, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
end

local function TriggerPlatform()
    if PlatformMode == "Under Player" then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            SpawnPlatformAt(char.HumanoidRootPart.Position - Vector3.new(0, 3.5, 0))
        end
    elseif PlatformMode == "Target Click" then
        WaitingForTarget = true
    end
end

-- ============================================
-- Input Handlers
-- ============================================

UserInputService.JumpRequest:Connect(function()
    if InfJump_Enabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.End then
        ESP_Enabled = false
        Aimbot_Enabled = false
        Speed_Enabled = false
        Noclip_Enabled = false
        GodMode_Enabled = false
        InfJump_Enabled = false
        UpdateStatus()
        Window:Notify({
            Title = "🔒 Экстренное отключение",
            Content = "Все функции выключены",
            Duration = 2
        })
        return
    end

    if WaitingForTarget and not gpe then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Mouse and Mouse.Hit then
                SpawnPlatformAt(Mouse.Hit.Position + Vector3.new(0, 0.5, 0))
            end
            WaitingForTarget = false
        end
    end
end)

-- ============================================
-- Platform GUI (Delayed Creation)
-- ============================================

local PlatformGui = nil
local function CreatePlatformGUI()
    if PlatformGui then return end

    if CoreGui:FindFirstChild("RomanPlatformGui") then CoreGui.RomanPlatformGui:Destroy() end
    PlatformGui = Instance.new("ScreenGui")
    PlatformGui.Name = "RomanPlatformGui"
    PlatformGui.Enabled = false
    PlatformGui.ResetOnSpawn = false
    PlatformGui.Parent = CoreGui

    local PlatBtn = Instance.new("TextButton")
    PlatBtn.Size = UDim2.new(0, 52, 0, 52)
    PlatBtn.Position = UDim2.new(0, 20, 0.5, -26)
    PlatBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    PlatBtn.Text = "🧱"
    PlatBtn.TextSize = 22
    PlatBtn.Active = true
    PlatBtn.Draggable = true
    PlatBtn.Parent = PlatformGui
    Instance.new("UICorner", PlatBtn).CornerRadius = UDim.new(1, 0)

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = GetCurrentColor()
    UIStroke.Thickness = 2
    UIStroke.Parent = PlatBtn

    PlatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            TriggerPlatform()
        end
    end)
end

task.delay(2, CreatePlatformGUI)

-- ============================================
-- Noclip Physics Loop
-- ============================================

RunService.Stepped:Connect(function()
    if Noclip_Enabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ============================================
-- Main Render Loop
-- ============================================

local lastAimTime = 0
RunService.RenderStepped:Connect(function()
    if AntiCheatDetected then return end

    local vpSize = Camera.ViewportSize
    local center = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
    local activeColor = GetCurrentColor()

    if PlatformGui then
        local stroke = PlatformGui:FindFirstChildWhichIsA("UIStroke")
        if stroke then
            stroke.Color = activeColor
        end
    end

    for _, platform in ipairs(PlatformsQueue) do
        if platform and platform.Parent then
            platform.Color = activeColor
        end
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Speed_Enabled then 
                hum.WalkSpeed = WalkSpeed_Value 
                SpoofHumanoidProperties(hum)
            end
            if GodMode_Enabled then 
                hum.Health = hum.MaxHealth 
            end
            if Jump_Enabled then 
                hum.JumpPower = JumpPower_Value 
                hum.UseJumpPower = true
                SpoofHumanoidProperties(hum)
            end
        end
    end

    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = center
        FOVCircle.Color = activeColor
        FOVCircle.Visible = true
    else 
        FOVCircle.Visible = false 
    end

    if Crosshair_Enabled then
        local gap = 4
        Crosshair_H.From = Vector2.new(center.X - Crosshair_Size - gap, center.Y)
        Crosshair_H.To = Vector2.new(center.X + Crosshair_Size + gap, center.Y)
        Crosshair_V.From = Vector2.new(center.X, center.Y - Crosshair_Size - gap)
        Crosshair_V.To = Vector2.new(center.X, center.Y + Crosshair_Size + gap)
        Crosshair_Dot.Position = center

        Crosshair_H.Color = activeColor
        Crosshair_V.Color = activeColor
        Crosshair_Dot.Color = activeColor

        Crosshair_H.Visible = true
        Crosshair_V.Visible = true
        Crosshair_Dot.Visible = true
    else 
        Crosshair_H.Visible = false 
        Crosshair_V.Visible = false 
        Crosshair_Dot.Visible = false
    end

    for player, objs in pairs(ESP_Cache) do
        if ESP_Enabled and player.Character then
            local rootPart = GetTargetPart(player.Character)
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if rootPart and (not hum or hum.Health > 0) then
                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local distance = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)
                    local sizeX = math.clamp(2300 / distance, 10, 300)
                    local sizeY = math.clamp(3300 / distance, 15, 400)
                    objs.Box.Color = activeColor
                    objs.Line.Color = activeColor
                    objs.Text.Color = activeColor

                    if Vis_Boxes then
                        objs.Box.Size = Vector2.new(sizeX, sizeY)
                        objs.Box.Position = Vector2.new(pos.X - sizeX * 0.5, pos.Y - sizeY * 0.5)
                        objs.Box.Visible = true
                    else objs.Box.Visible = false end

                    if Vis_Lines then
                        objs.Line.From = Vector2.new(vpSize.X * 0.5, vpSize.Y)
                        objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY * 0.5))
                        objs.Line.Visible = true
                    else objs.Line.Visible = false end

                    if Vis_Names or Vis_Dist then
                        local str = ""
                        if Vis_Names then str = str .. player.Name end
                        if Vis_Dist then str = str .. " [" .. tostring(distance) .. "m]" end
                        objs.Text.Text = str
                        objs.Text.Position = Vector2.new(pos.X, pos.Y - (sizeY * 0.5) - 16)
                        objs.Text.Visible = true
                    else objs.Text.Visible = false end
                else objs.Box.Visible = false; objs.Line.Visible = false; objs.Text.Visible = false end
            else objs.Box.Visible = false; objs.Line.Visible = false; objs.Text.Visible = false end
        else objs.Box.Visible = false; objs.Line.Visible = false; objs.Text.Visible = false end
    end

    if Aimbot_Enabled then
        local targetPart = GetClosestPlayerToCenter(center)
        if targetPart then
            local currentTime = tick()
            local smoothFactor = Aimbot_Smoothness
            if currentTime - lastAimTime > 0.2 then
                smoothFactor = smoothFactor * (0.9 + math.random() * 0.2)
                lastAimTime = currentTime
            end
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPart.Position), smoothFactor)
        end
    end
end)

-- ============================================
-- RAYFIELD UI STRUCTURE
-- ============================================

task.delay(1.5, function()
    local MainTab = Window:CreateTab("Main", 4483362458)
    local VisualTab = Window:CreateTab("Visuals", 4483362458)
    local PlayerTab = Window:CreateTab("Player", 4483362458)

    -- MAIN TAB
    MainTab:CreateSection("Статус")

    StatusLabel = MainTab:CreateLabel({
        Name = "🟢 Защита активна | ESP: Выкл | Аимбот: Выкл",
        CurrentValue = "active"
    })

    MainTab:CreateSection("Combat Tools")
    MainTab:CreateToggle({
        Name = "Universal ESP",
        CurrentValue = false,
        Callback = function(V)
            if ConfirmEnabled and V then
                Window:Notify({
                    Title = "❓ Подтвердите включение",
                    Content = "Нажмите 'Да' через 2 секунды",
                    Duration = 2
                })
                task.wait(2)
            end
            ESP_Enabled = V
            UpdateStatus()
        end
    })
    MainTab:CreateToggle({
        Name = "Universal Aimbot",
        CurrentValue = false,
        Callback = function(V)
            if ConfirmEnabled and V then
                Window:Notify({
                    Title = "❓ Подтвердите включение",
                    Content = "Нажмите 'Да' через 2 секунды",
                    Duration = 2
                })
                task.wait(2)
            end
            Aimbot_Enabled = V
            UpdateStatus()
        end
    })
    MainTab:CreateToggle({
        Name = "Crosshair",
        CurrentValue = false,
        Callback = function(V) Crosshair_Enabled = V end
    })

    MainTab:CreateSection("Server Operations")
    MainTab:CreateButton({
       Name = "Server Hop (Lowest Players)",
       Callback = function()
          local HttpService = game:GetService("HttpService")
          local TeleportService = game:GetService("TeleportService")
          pcall(function()
              local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
              local serverList = HttpService:JSONDecode(game:HttpGet(url))
              for _, server in ipairs(serverList.data) do
                  if server.playing < server.maxPlayers and server.id ~= game.JobId then
                      TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                      break
                  end
              end
          end)
       end,
    })

    -- VISUALS TAB
    VisualTab:CreateSection("Theme & Visual Color")
    VisualTab:CreateDropdown({
       Name = "Visual Color Accent",
       Options = {"Gray", "Rainbow"},
       CurrentOption = "Gray",
       MultipleOptions = false,
       Callback = function(Option)
           if type(Option) == "table" then SelectedColorName = Option[1] else SelectedColorName = Option end
       end,
    })

    VisualTab:CreateSection("ESP Configurations")
    VisualTab:CreateToggle({ Name = "Boxes", CurrentValue = true, Callback = function(V) Vis_Boxes = V end })
    VisualTab:CreateToggle({ Name = "Lines", CurrentValue = true, Callback = function(V) Vis_Lines = V end })
    VisualTab:CreateToggle({ Name = "Names", CurrentValue = true, Callback = function(V) Vis_Names = V end })
    VisualTab:CreateToggle({ Name = "Distance", CurrentValue = true, Callback = function(V) Vis_Dist = V end })

    VisualTab:CreateSection("Aimbot & Overlay")
    VisualTab:CreateToggle({ Name = "FOV Circle", CurrentValue = true, Callback = function(V) Vis_FOV = V end })
    VisualTab:CreateSlider({ Name = "FOV Radius", Range = {10, 500}, Increment = 1, CurrentValue = 150, Callback = function(V) Aimbot_FOV = V end })
    VisualTab:CreateSlider({ Name = "Crosshair Size", Range = {3, 50}, Increment = 1, CurrentValue = 10, Callback = function(V) Crosshair_Size = V end })
    VisualTab:CreateSlider({ Name = "Aim Smoothness", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.4, Callback = function(V) Aimbot_Smoothness = V end })

    -- PLAYER TAB
    PlayerTab:CreateSection("Protection")
    PlayerTab:CreateToggle({
        Name = "Подтверждение включения",
        CurrentValue = false,
        Callback = function(V) ConfirmEnabled = V end
    })

    PlayerTab:CreateSection("Platform System")
    PlayerTab:CreateToggle({
       Name = "Floating Platform Button",
       CurrentValue = false,
       Callback = function(Value) 
           if PlatformGui then 
               PlatformGui.Enabled = Value 
           end
       end,
    })
    PlayerTab:CreateDropdown({
       Name = "Platform Mode",
       Options = {"Under Player", "Target Click"},
       CurrentOption = "Under Player",
       MultipleOptions = false,
       Flag = "PlatMode",
       Callback = function(Option)
           if type(Option) == "table" then PlatformMode = Option[1] else PlatformMode = Option end
       end,
    })
    PlayerTab:CreateSlider({
       Name = "Platform Size",
       Range = {3, 30},
       Increment = 1,
       CurrentValue = 7,
       Callback = function(V) PlatformSize_Value = V end,
    })

    PlayerTab:CreateSection("Movement & Defense")
    PlayerTab:CreateToggle({ Name = "God Mode", CurrentValue = false, Callback = function(V) GodMode_Enabled = V end })
    PlayerTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = function(V) Noclip_Enabled = V end })
    PlayerTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(V) InfJump_Enabled = V end })

    PlayerTab:CreateToggle({ 
        Name = "Speed Hack", 
        CurrentValue = false, 
        Callback = function(V) 
            Speed_Enabled = V 
            if not V and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then 
                    hum.WalkSpeed = Original_WalkSpeed 
                    SpoofHumanoidProperties(hum)
                end
            end
            UpdateStatus()
        end 
    })
    PlayerTab:CreateSlider({ Name = "Walk Speed", Range = {16, 250}, Increment = 1, CurrentValue = 16, Callback = function(V) WalkSpeed_Value = V end })

    PlayerTab:CreateToggle({ 
        Name = "Jump Power", 
        CurrentValue = false, 
        Callback = function(V) 
            Jump_Enabled = V 
            if not V and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then 
                    hum.JumpPower = Original_JumpPower
                    hum.UseJumpPower = false
                    SpoofHumanoidProperties(hum)
                end
            end
        end 
    })
    PlayerTab:CreateSlider({ Name = "Jump Height", Range = {50, 350}, Increment = 1, CurrentValue = 50, Callback = function(V) JumpPower_Value = V end })

    UpdateStatus()

    -- ============================================
    -- ЗАПУСК ЦИКЛА АНТИЧИТА (ПОСЛЕ СОЗДАНИЯ ВСЕГО UI)
    -- ============================================
    task.spawn(function()
        while task.wait(5) do
            if AntiCheatDetected then
                AntiCheatTimer = AntiCheatTimer - 5
                if AntiCheatTimer <= 0 then
                    AntiCheatDetected = false
                    Window:Notify({
                        Title = "✅ Защита восстановлена",
                        Content = "Можно продолжать",
                        Duration = 2
                    })
                    UpdateStatus()
                end
            else
                if CheckAntiCheat() then
                    AntiCheatDetected = true
                    AntiCheatTimer = 15
                    ESP_Enabled = false
                    Aimbot_Enabled = false
                    Speed_Enabled = false
                    Noclip_Enabled = false
                    GodMode_Enabled = false
                    InfJump_Enabled = false
                    if PlatformGui then PlatformGui.Enabled = false end
                    LogEvent("AntiCheat detected! Features disabled.")
                    UpdateStatus()
                    Window:Notify({
                        Title = "⚠️ Обнаружен античит!",
                        Content = "Функции отключены на 15 секунд",
                        Duration = 3
                    })
                end
            end
        end
    end)
    -- ============================================
    -- КОНЕЦ ЦИКЛА АНТИЧИТА
    -- ============================================
end)

print("Script loaded successfully!")
