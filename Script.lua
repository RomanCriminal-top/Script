-- Rayfield UI Library Loader
Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services Optimization
Players = game:GetService("Players")
RunService = game:GetService("RunService")
UserInputService = game:GetService("UserInputService")
CoreGui = game:GetService("CoreGui")
Workspace = game:GetService("Workspace")

LocalPlayer = Players.LocalPlayer
Camera = Workspace.CurrentCamera
Mouse = LocalPlayer:GetMouse()

-- Notification Helper Function
NotifyToggle = function(featureName, state)
    Rayfield:Notify({
        Title = "Система",
        Content = featureName .. (state and " включен" or " выключен"),
        Duration = 2,
        Image = 4483362458,
    })
end

-- Window Creation
Window = Rayfield:CreateWindow({
   Name = "Скрипт @RomanCriminal",
   Icon = 0,
   LoadingTitle = "Скрипт @RomanCriminal",
   LoadingSubtitle = "Скрипт @RomanCriminal",
   Theme = "Ocean",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- UI Boundary Overflow Fix
task.spawn(function()
    task.wait(1)
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name:find("Rayfield") or gui:FindFirstChild("Main")) then
            for _, v in ipairs(gui:GetDescendants()) do
                if v:IsA("Frame") or v:IsA("ScrollingFrame") then
                    v.ClipsDescendants = true
                end
            end
        end
    end
end)

Original_WalkSpeed = 16
Original_JumpPower = 50

SaveOriginalStats = function(char)
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

ESP_Enabled = false
Aimbot_Enabled = false
Crosshair_Enabled = false

Vis_Boxes = true
Vis_Lines = true
Vis_FOV = true
Vis_Names = true
Vis_Dist = true

Aimbot_Smoothness = 0.4
Aimbot_FOV = 150
Crosshair_Size = 10

Speed_Enabled = false
WalkSpeed_Value = 16
Jump_Enabled = false
JumpPower_Value = 50
InfJump_Enabled = false
Noclip_Enabled = false
GodMode_Enabled = false

PlatformMode = "Под игроком"
PlatformSize_Value = 7
WaitingForTarget = false
PlatformsQueue = {}
MaxPlatforms = 10

SelectedColorName = "Серый"
ColorTable = {
    ["Серый"] = Color3.fromRGB(150, 150, 150)
}

GetCurrentColor = function()
    if SelectedColorName == "Радуга" then
        return Color3.fromHSV((tick() % 3) / 3, 1, 1)
    else
        return ColorTable[SelectedColorName] or Color3.fromRGB(150, 150, 150)
    end
end

FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

Crosshair_H = Drawing.new("Line")
Crosshair_H.Thickness = 1.8
Crosshair_H.Visible = false

Crosshair_V = Drawing.new("Line")
Crosshair_V.Thickness = 1.8
Crosshair_V.Visible = false

Crosshair_Dot = Drawing.new("Circle")
Crosshair_Dot.Radius = 2.5
Crosshair_Dot.Filled = true
Crosshair_Dot.Visible = false

ESP_Cache = {}

CreateESP = function(player)
    if player == LocalPlayer then return end
    local Box = Drawing.new("Square")
    Box.Visible = false; Box.Thickness = 1.5; Box.Filled = false
    local Line = Drawing.new("Line")
    Line.Visible = false; Line.Thickness = 1.2
    local Text = Drawing.new("Text")
    Text.Visible = false; Text.Size = 13; Text.Center = true; Text.Outline = true; Text.OutlineColor = Color3.fromRGB(0, 0, 0); Text.Color = Color3.fromRGB(255, 255, 255)
    ESP_Cache[player] = {Box = Box, Line = Line, Text = Text}
end

RemoveESP = function(player)
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

GetTargetPart = function(character)
    if not character then return nil end
    local standard = character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("Head") 
        or character:FindFirstChild("Torso") 
        or character:FindFirstChild("UpperTorso")
    if standard and standard:IsA("BasePart") then return standard end
    for _, v in ipairs(character:GetDescendants()) do
        if v:IsA("BasePart") then return v end
    end
    return nil
end

GetClosestPlayerToCenter = function(screenCenter)
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

SpawnPlatformAt = function(pos)
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(PlatformSize_Value, 1, PlatformSize_Value)
    platform.Position = pos
    platform.Anchored = true
    platform.CanCollide = true
    platform.Material = Enum.Material.Neon
    platform.Color = GetCurrentColor()
    platform.Parent = Workspace
    
    table.insert(PlatformsQueue, platform)
    while #PlatformsQueue > MaxPlatforms do
        local oldest = table.remove(PlatformsQueue, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
end

TriggerPlatform = function()
    if PlatformMode == "Под игроком" then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            SpawnPlatformAt(char.HumanoidRootPart.Position - Vector3.new(0, 3.5, 0))
        end
    elseif PlatformMode == "По клику" then
        WaitingForTarget = true
    end
end

UserInputService.JumpRequest:Connect(function()
    if InfJump_Enabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

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

if CoreGui:FindFirstChild("RomanPlatformGui") then CoreGui.RomanPlatformGui:Destroy() end
PlatformGui = Instance.new("ScreenGui")
PlatformGui.Name = "RomanPlatformGui"
PlatformGui.Enabled = false
PlatformGui.ResetOnSpawn = false
PlatformGui.Parent = CoreGui

PlatBtn = Instance.new("TextButton")
PlatBtn.Size = UDim2.new(0, 52, 0, 52)
PlatBtn.Position = UDim2.new(0, 20, 0.5, -26)
PlatBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
PlatBtn.Text = "🧱"
PlatBtn.TextSize = 22
PlatBtn.Active = true
PlatBtn.Draggable = true
PlatBtn.Parent = PlatformGui
Instance.new("UICorner", PlatBtn).CornerRadius = UDim.new(1, 0)

UIStroke = Instance.new("UIStroke")
UIStroke.Color = GetCurrentColor()
UIStroke.Thickness = 2
UIStroke.Parent = PlatBtn

PlatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        TriggerPlatform()
    end
end)

RunService.Stepped:Connect(function()
    if Noclip_Enabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local vpSize = Camera.ViewportSize
    local center = Vector2.new(vpSize.X * 0.5, vpSize.Y * 0.5)
    local activeColor = GetCurrentColor()
    UIStroke.Color = activeColor
    for _, platform in ipairs(PlatformsQueue) do
        if platform and platform.Parent then platform.Color = activeColor end
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if Speed_Enabled then hum.WalkSpeed = WalkSpeed_Value end
            if GodMode_Enabled then hum.Health = hum.MaxHealth end
            if Jump_Enabled then hum.JumpPower = JumpPower_Value hum.UseJumpPower = true end
        end
    end
    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = center
        FOVCircle.Color = activeColor
        FOVCircle.Visible = true
    else FOVCircle.Visible = false end
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
    else Crosshair_H.Visible = false; Crosshair_V.Visible = false; Crosshair_Dot.Visible = false end
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
        if targetPart then Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPart.Position), Aimbot_Smoothness) end
    end
end)
MainTab = Window:CreateTab("Главная", 4483362458)
VisualTab = Window:CreateTab("Визуализация", 4483362458)
PlayerTab = Window:CreateTab("Игрок", 4483362458)

MainTab:CreateSection("Инструменты боя")
MainTab:CreateToggle({
    Name = "Универсальный ESP",
    CurrentValue = false,
    Callback = function(V)
        ESP_Enabled = V
        NotifyToggle("Универсальный ESP", V)
    end
})
MainTab:CreateToggle({
    Name = "Универсальный Аимбот",
    CurrentValue = false,
    Callback = function(V)
        Aimbot_Enabled = V
        NotifyToggle("Универсальный Аимбот", V)
    end
})
MainTab:CreateToggle({
    Name = "Прицел",
    CurrentValue = false,
    Callback = function(V)
        Crosshair_Enabled = V
        NotifyToggle("Прицел", V)
    end
})

MainTab:CreateSection("Операции с сервером")
MainTab:CreateButton({
   Name = "Смена сервера (мало игроков)",
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

VisualTab:CreateSection("Тема и цвет")
VisualTab:CreateDropdown({
   Name = "Акцентный цвет",
   Options = {"Серый", "Радуга"},
   CurrentOption = "Серый",
   MultipleOptions = false,
   Callback = function(Option)
       if type(Option) == "table" then SelectedColorName = Option[1] else SelectedColorName = Option end
   end,
})

VisualTab:CreateSection("Настройки ESP")
VisualTab:CreateToggle({ Name = "Коробки", CurrentValue = true, Callback = function(V) Vis_Boxes = V; NotifyToggle("ESP Коробки", V) end })
VisualTab:CreateToggle({ Name = "Линии", CurrentValue = true, Callback = function(V) Vis_Lines = V; NotifyToggle("ESP Линии", V) end })
VisualTab:CreateToggle({ Name = "Имена", CurrentValue = true, Callback = function(V) Vis_Names = V; NotifyToggle("ESP Имена", V) end })
VisualTab:CreateToggle({ Name = "Дистанция", CurrentValue = true, Callback = function(V) Vis_Dist = V; NotifyToggle("ESP Дистанция", V) end })

VisualTab:CreateSection("Аимбот и Оверлей")
VisualTab:CreateToggle({ Name = "Круг FOV", CurrentValue = true, Callback = function(V) Vis_FOV = V; NotifyToggle("Круг FOV", V) end })
VisualTab:CreateSlider({ Name = "Радиус FOV", Range = {1, 500}, Increment = 1, CurrentValue = 150, Callback = function(V) Aimbot_FOV = V end })
VisualTab:CreateSlider({ Name = "Размер прицела", Range = {1, 50}, Increment = 1, CurrentValue = 10, Callback = function(V) Crosshair_Size = V end })
VisualTab:CreateSlider({ Name = "Плавность аима", Range = {0.1, 1}, Increment = 0.05, CurrentValue = 0.4, Callback = function(V) Aimbot_Smoothness = V end })

PlayerTab:CreateSection("Система платформ")
PlayerTab:CreateToggle({
   Name = "Кнопка платформ",
   CurrentValue = false,
   Callback = function(Value)
       PlatformGui.Enabled = Value
       NotifyToggle("Кнопка платформ", Value)
   end,
})
PlayerTab:CreateDropdown({
   Name = "Режим платформ",
   Options = {"Под игроком", "По клику"},
   CurrentOption = "Под игроком",
   MultipleOptions = false,
   Callback = function(Option)
       if type(Option) == "table" then PlatformMode = Option[1] else PlatformMode = Option end
   end,
})
PlayerTab:CreateSlider({ Name = "Размер платформ", Range = {1, 30}, Increment = 1, CurrentValue = 7, Callback = function(V) PlatformSize_Value = V end })
PlayerTab:CreateSlider({
   Name = "Макс. платформ",
   Range = {1, 50},
   Increment = 1,
   CurrentValue = 10,
   Callback = function(V)
       MaxPlatforms = V
       while #PlatformsQueue > MaxPlatforms do
           local oldest = table.remove(PlatformsQueue, 1)
           if oldest and oldest.Parent then oldest:Destroy() end
       end
   end,
})

PlayerTab:CreateSection("Движение и защита")
PlayerTab:CreateToggle({ Name = "Бессмертие", CurrentValue = false, Callback = function(V) GodMode_Enabled = V; NotifyToggle("Бессмертие", V) end })
PlayerTab:CreateToggle({ Name = "Ноклип", CurrentValue = false, Callback = function(V) Noclip_Enabled = V; NotifyToggle("Ноклип", V) end })
PlayerTab:CreateToggle({ Name = "Бесконечный прыжок", CurrentValue = false, Callback = function(V) InfJump_Enabled = V; NotifyToggle("Бесконечный прыжок", V) end })

PlayerTab:CreateToggle({ 
    Name = "Спидхак", 
    CurrentValue = false, 
    Callback = function(V) 
        Speed_Enabled = V 
        if not V and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Original_WalkSpeed end
        end
        NotifyToggle("Спидхак", V)
    end 
})
PlayerTab:CreateSlider({ Name = "Скорость ходьбы", Range = {1, 250}, Increment = 1, CurrentValue = 16, Callback = function(V) WalkSpeed_Value = V end })

PlayerTab:CreateToggle({ 
    Name = "Сила прыжка", 
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
        NotifyToggle("Сила прыжка", V)
    end 
})
PlayerTab:CreateSlider({ Name = "Высота прыжка", Range = {1, 350}, Increment = 1, CurrentValue = 50, Callback = function(V) JumpPower_Value = V end })
