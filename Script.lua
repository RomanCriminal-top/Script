-- Rayfield UI Library Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services Optimization
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Window Creation
local Window = Rayfield:CreateWindow({
   Name = "@RomanCriminal script",
   Icon = 0,
   LoadingTitle = "script by @RomanCriminal",
   LoadingSubtitle = "script by @RomanCriminal",
   Theme = "Ocean",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- UI Boundary Overflow Fix (ClipsDescendants)
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

-- Original Stats Tracker
local Original_WalkSpeed = 16
local Original_JumpPower = 50

local function SaveOriginalStats(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if hum.WalkSpeed > 0 and hum.WalkSpeed ~= WalkSpeed_Value then
            Original_WalkSpeed = hum.WalkSpeed
        end
        if hum.JumpPower > 0 and hum.JumpPower ~= JumpPower_Value then
            Original_JumpPower = hum.JumpPower
        end
    end
end

if LocalPlayer.Character then SaveOriginalStats(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(SaveOriginalStats)

-- Main State Variables
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

-- Dynamic Color Accent System (Gray & Rainbow)
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

-- Fixed Center Screen FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Crosshair Elements
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

-- ESP Cache
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

-- Ultra-Universal Part Finder
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

-- Fast Center Aimbot Search
local function GetClosestPlayerToCenter(screenCenter)
    local closest, shortest = nil, Aimbot_FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local part = GetTargetPart(player.Character)
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if part and (not hum or hum.Health > 0) then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < shortest then closest = part; shortest = dist end
                end
            end
        end
    end
    return closest
end

-- Platform Manager
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

-- Infinite Jump Listener
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

-- Input Handling for Platforms
UserInputService.InputBegan:Connect(function(input, gpe)
    if WaitingForTarget and not gpe then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Mouse and Mouse.Hit then
                SpawnPlatformAt(Mouse.Hit.Position + Vector3.new(0, 0.5, 0))
            end
            WaitingForTarget = false
        end
    end
end)

-- Floating Platform Button
if CoreGui:FindFirstChild("RomanPlatformGui") then CoreGui.RomanPlatformGui:Destroy() end
local PlatformGui = Instance.new("ScreenGui")
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

-- Dedicated Noclip Physics Loop
RunService.Stepped:Connect(function()
    if Noclip_Enabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Optimized Render Loop
RunService.RenderStepped:Connect(function()
    local vpSize = Camera.ViewportSize
    local center = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
    local activeColor = GetCurrentColor()
    
    UIStroke.Color = activeColor

    -- Dynamic Platform Color Update
    for _, platform in ipairs(PlatformsQueue) do
        if platform and platform.Parent then
            platform.Color = activeColor
        end
    end

    -- Local Player Modifications
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Speed_Enabled then hum.WalkSpeed = WalkSpeed_Value end
            if GodMode_Enabled then hum.Health = hum.MaxHealth end
            if Jump_Enabled then hum.JumpPower = JumpPower_Value hum.UseJumpPower = true end
        end
    end

    -- FOV Rendering
    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = center
        FOVCircle.Color = activeColor
        FOVCircle.Visible = true
    else 
        FOVCircle.Visible = false 
    end

    -- Crosshair Rendering
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

    -- ESP Loop Rendering
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

    -- Universal Center Aimbot
    if Aimbot_Enabled then
        local targetPart = GetClosestPlayerToCenter(center)
        if targetPart then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPart.Position), Aimbot_Smoothness)
        end
    end
end)

-- RAYFIELD UI STRUCTURE
local MainTab = Window:CreateTab("Main", 4483362458)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- MAIN TAB
MainTab:CreateSection("Combat Tools")
MainTab:CreateToggle({
    Name = "Universal ESP",
    CurrentValue = false,
    Callback = function(V) ESP_Enabled = V end
})
MainTab:CreateToggle({
    Name = "Universal Aimbot",
    CurrentValue = false,
    Callback = function(V) Aimbot_Enabled = V end
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
PlayerTab:CreateSection("Platform System")
PlayerTab:CreateToggle({
   Name = "Floating Platform Button",
   CurrentValue = false,
   Callback = function(Value) PlatformGui.Enabled = Value end,
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
            if hum then hum.WalkSpeed = Original_WalkSpeed end
        end
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
            end
        end
    end 
})
PlayerTab:CreateSlider({ Name = "Jump Height", Range = {50, 350}, Increment = 1, CurrentValue = 50, Callback = function(V) JumpPower_Value = V end })
