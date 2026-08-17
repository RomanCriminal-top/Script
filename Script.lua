-- ЧАСТЬ 1: ОСНОВНАЯ ЛОГИКА, АИМБОТ И ВКЛАДКА MAIN
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки основных функций
local ESP_Enabled = false
local Aimbot_Enabled = false
local Crosshair_Enabled = false

-- Настройки вкладки PLAYER
local Fly_Enabled = false
local Speed_Enabled = false
local GodMode_Enabled = false
local WalkSpeed_Value = 16
local Jump_Enabled = false
local JumpPower_Value = 50
local Noclip_Enabled = false

-- Настройки тумблеров VISUAL (Плавность добавлена)
local Aimbot_Smoothness = 0.4
local Aimbot_FOV = 150 
local Crosshair_Size = 10 
local Vis_Boxes = true
local Vis_Lines = true
local Vis_FOV = true
local Vis_Names = true
local Vis_Dist = true

-- Цвета (1 = Белый, 2 = Зеленый, 3 = Фиолетовый, 4 = Радуга)
local CurrentColorIndex = 1
local ColorModes = {"DEFAULT", "GREEN", "PURPLE", "RAINBOW"}
local CurrentStaticColor = Color3.fromRGB(255, 255, 255) 

local ESP_Cache = {}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

local Crosshair_Horizontal = Drawing.new("Line")
Crosshair_Horizontal.Thickness = 2
Crosshair_Horizontal.Visible = false

local Crosshair_Vertical = Drawing.new("Line")
Crosshair_Vertical.Thickness = 2
Crosshair_Vertical.Visible = false

local function CreateESP(player)
    if player == LocalPlayer then return end
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Thickness = 1.5
    Box.Filled = false
    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Thickness = 1
    local Text = Drawing.new("Text")
    Text.Visible = false
    Text.Size = 14
    Text.Center = true
    Text.Outline = true
    Text.Color = Color3.fromRGB(255, 255, 255)
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

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if head and humanoid and humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

UserInputService.JumpRequest:Connect(function()
    if Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

RunService.Heartbeat:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local DynamicColor = CurrentStaticColor
    if ColorModes[CurrentColorIndex] == "RAINBOW" then
        DynamicColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
    _G.CurrentRainbowColor = DynamicColor

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        -- Скорость меняется только если включен Speed_Enabled
        if Speed_Enabled then
            hum.WalkSpeed = WalkSpeed_Value
        end
        
        -- Логика God Mode
        if GodMode_Enabled then
            hum.Health = hum.MaxHealth
        end

        if Jump_Enabled then
            hum.JumpPower = JumpPower_Value
            hum.UseJumpPower = true
        else
            hum.UseJumpPower = false
        end
        if Noclip_Enabled then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end

    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Color = DynamicColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if Crosshair_Enabled then
        local lSize = Crosshair_Size
        local gap = 3
        Crosshair_Horizontal.From = Vector2.new(screenCenter.X - lSize - gap, screenCenter.Y)
        Crosshair_Horizontal.To = Vector2.new(screenCenter.X + lSize + gap, screenCenter.Y)
        Crosshair_Vertical.From = Vector2.new(screenCenter.X, screenCenter.Y - lSize - gap)
        Crosshair_Vertical.To = Vector2.new(screenCenter.X, screenCenter.Y + lSize + gap)
        Crosshair_Horizontal.Color = DynamicColor
        Crosshair_Vertical.Color = DynamicColor
        Crosshair_Horizontal.Visible = true
        Crosshair_Vertical.Visible = true
    else
        Crosshair_Horizontal.Visible = false
        Crosshair_Vertical.Visible = false
    end

    for player, objs in pairs(ESP_Cache) do
        if ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distance = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                local sizeX = 2300 / distance 
                local sizeY = 3300 / distance
                objs.Box.Color = DynamicColor
                objs.Line.Color = DynamicColor

                if Vis_Boxes then
                    objs.Box.Size = Vector2.new(sizeX, sizeY)
                    objs.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    objs.Box.Visible = true
                else objs.Box.Visible = false end

                if Vis_Lines then
                    objs.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY / 2))
                    objs.Line.Visible = true
                else objs.Line.Visible = false end

                if Vis_Names or Vis_Dist then
                    local textString = ""
                    if Vis_Names then textString = textString .. player.Name end
                    if Vis_Dist then 
                        if Vis_Names then textString = textString .. " " end
                        textString = textString .. "[" .. tostring(distance) .. "m]"
                    end
                    objs.Text.Text = textString
                    objs.Text.Position = Vector2.new(pos.X, pos.Y - (sizeY / 2) - 18)
                    objs.Text.Visible = true
                else objs.Text.Visible = false end
            else objs.Box.Visible = false objs.Line.Visible = false objs.Text.Visible = false end
        else objs.Box.Visible = false objs.Line.Visible = false objs.Text.Visible = false end
    end

    if Aimbot_Enabled then
        local target = GetClosestPlayerToCenter()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetHead = target.Character.Head
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetHead.Position), Aimbot_Smoothness)
        end
    end
end)

if CoreGui:FindFirstChild("DeltaESP_Gui") then CoreGui.DeltaESP_Gui:Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

_G.RomanMainFrame = Instance.new("Frame")
local MainFrame = _G.RomanMainFrame
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 230, 0, 315)
MainFrame.Position = UDim2.new(0.5, -115, 0.4, -157)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Title.Text = "@RomanCriminal script"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local MainTabButton = Instance.new("TextButton")
MainTabButton.Size = UDim2.new(0, 62, 0, 25)
MainTabButton.Position = UDim2.new(0, 10, 0, 42)
MainTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MainTabButton.Text = "MAIN"
MainTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTabButton.Font = Enum.Font.GothamBold
MainTabButton.TextSize = 10
MainTabButton.Parent = MainFrame
Instance.new("UICorner", MainTabButton).CornerRadius = UDim.new(0, 5)

local VisualTabButton = Instance.new("TextButton")
VisualTabButton.Size = UDim2.new(0, 62, 0, 25)
VisualTabButton.Position = UDim2.new(0, 77, 0, 42)
VisualTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
VisualTabButton.Text = "VISUAL"
VisualTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
VisualTabButton.Font = Enum.Font.GothamBold
VisualTabButton.TextSize = 10
VisualTabButton.Parent = MainFrame
Instance.new("UICorner", VisualTabButton).CornerRadius = UDim.new(0, 5)

local PlayerTabButton = Instance.new("TextButton")
PlayerTabButton.Size = UDim2.new(0, 70, 0, 25)
PlayerTabButton.Position = UDim2.new(0, 144, 0, 42)
PlayerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
PlayerTabButton.Text = "PLAYER"
PlayerTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
PlayerTabButton.Font = Enum.Font.GothamBold
PlayerTabButton.TextSize = 10
PlayerTabButton.Parent = MainFrame
Instance.new("UICorner", PlayerTabButton).CornerRadius = UDim.new(0, 5)

_G.MainContentFrame = Instance.new("Frame")
_G.VisualContentFrame = Instance.new("Frame")
_G.PlayerContentFrame = Instance.new("Frame")

local function initCF(f)
    f.Size = UDim2.new(1, 0, 1, -75)
    f.Position = UDim2.new(0, 0, 0, 75)
    f.BackgroundTransparency = 1
    f.Parent = MainFrame
end
initCF(_G.MainContentFrame)
initCF(_G.VisualContentFrame)
initCF(_G.PlayerContentFrame)
_G.VisualContentFrame.Visible = false
_G.PlayerContentFrame.Visible = false

local function switchTab(activeBtn, activeFrame)
    _G.MainContentFrame.Visible = false
    _G.VisualContentFrame.Visible = false
    _G.PlayerContentFrame.Visible = false
    MainTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    MainTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    VisualTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    VisualTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    PlayerTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    PlayerTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    activeFrame.Visible = true
    activeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    activeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

MainTabButton.MouseButton1Click:Connect(function() switchTab(MainTabButton, _G.MainContentFrame) end)
VisualTabButton.MouseButton1Click:Connect(function() switchTab(VisualTabButton, _G.VisualContentFrame) end)
PlayerTabButton.MouseButton1Click:Connect(function() switchTab(PlayerTabButton, _G.PlayerContentFrame) end)

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 190, 0, 38)
ToggleButton.Position = UDim2.new(0.5, -95, 0, 10)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "MASTER ESP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 13
ToggleButton.Parent = _G.MainContentFrame
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)

ToggleButton.MouseButton1Click:Connect(function()
    ESP_Enabled = not ESP_Enabled
    ToggleButton.Text = ESP_Enabled and "MASTER ESP: ON" or "MASTER ESP: OFF"
    ToggleButton.BackgroundColor3 = ESP_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local AimButton = Instance.new("TextButton")
AimButton.Size = UDim2.new(0, 90, 0, 35)
AimButton.Position = UDim2.new(0, 20, 0, 60)
AimButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AimButton.Text = "AIM: OFF"
AimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimButton.Font = Enum.Font.GothamBold
AimButton.TextSize = 12
AimButton.Parent = _G.MainContentFrame
Instance.new("UICorner", AimButton).CornerRadius = UDim.new(0, 8)

AimButton.MouseButton1Click:Connect(function()
    Aimbot_Enabled = not Aimbot_Enabled
    AimButton.Text = Aimbot_Enabled and "AIM: ON" or "AIM: OFF"
    AimButton.BackgroundColor3 = Aimbot_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local CrosshairButton = Instance.new("TextButton")
CrosshairButton.Size = UDim2.new(0, 90, 0, 35)
CrosshairButton.Position = UDim2.new(0, 120, 0, 60)
CrosshairButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CrosshairButton.Text = "CROSS: OFF"
CrosshairButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CrosshairButton.Font = Enum.Font.GothamBold
CrosshairButton.TextSize = 11
CrosshairButton.Parent = _G.MainContentFrame
Instance.new("UICorner", CrosshairButton).CornerRadius = UDim.new(0, 8)

CrosshairButton.MouseButton1Click:Connect(function()
    Crosshair_Enabled = not Crosshair_Enabled
    CrosshairButton.Text = Crosshair_Enabled and "CROSS: ON" or "CROSS: OFF"
    CrosshairButton.BackgroundColor3 = Crosshair_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local ColorButton = Instance.new("TextButton")
ColorButton.Size = UDim2.new(0, 190, 0, 35)
ColorButton.Position = UDim2.new(0.5, -95, 0, 110)
ColorButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ColorButton.Text = "COLOR: DEFAULT"
ColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ColorButton.Font = Enum.Font.GothamBold
ColorButton.TextSize = 12
ColorButton.Parent = _G.MainContentFrame
Instance.new("UICorner", ColorButton).CornerRadius = UDim.new(0, 8)

ColorButton.MouseButton1Click:Connect(function()
    CurrentColorIndex = CurrentColorIndex + 1
    if CurrentColorIndex > #ColorModes then CurrentColorIndex = 1 end
    local mode = ColorModes[CurrentColorIndex]
    ColorButton.Text = "COLOR: " .. mode
    if mode == "DEFAULT" then CurrentStaticColor = Color3.fromRGB(255, 255, 255) ColorButton.TextColor3 = CurrentStaticColor
    elseif mode == "GREEN" then CurrentStaticColor = Color3.fromRGB(50, 250, 50) ColorButton.TextColor3 = CurrentStaticColor
    elseif mode == "PURPLE" then CurrentStaticColor = Color3.fromRGB(180, 50, 255) ColorButton.TextColor3 = CurrentStaticColor end
end)

RunService.Heartbeat:Connect(function()
    if ColorModes[CurrentColorIndex] == "RAINBOW" and _G.CurrentRainbowColor then ColorButton.TextColor3 = _G.CurrentRainbowColor end
end)

local FindEmptyServerButton = Instance.new("TextButton")
FindEmptyServerButton.Size = UDim2.new(0, 190, 0, 35)
FindEmptyServerButton.Position = UDim2.new(0.5, -95, 0, 155)
FindEmptyServerButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
FindEmptyServerButton.Text = "🌐 НАЙТИ ПУСТОЙ СЕРВЕР"
FindEmptyServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FindEmptyServerButton.Font = Enum.Font.GothamBold
FindEmptyServerButton.TextSize = 11
FindEmptyServerButton.Parent = _G.MainContentFrame
Instance.new("UICorner", FindEmptyServerButton).CornerRadius = UDim.new(0, 8)

FindEmptyServerButton.MouseButton1Click:Connect(function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local PlaceId = game.PlaceId
    local LocalPlayer = Players.LocalPlayer

    game.StarterGui:SetCore("SendNotification", {
        Title = "🔍 Поиск сервера",
        Text = "Сканируем список серверов...",
        Duration = 5
    })

    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local response = game:HttpGet(url)
        local serverList = HttpService:JSONDecode(response)
        
        local foundServer = nil
        local minPlayers = math.huge
        
        for _, server in pairs(serverList.data) do
            if server.playing < server.maxPlayers and server.playing < minPlayers and server.id ~= game.JobId then
                minPlayers = server.playing
                foundServer = server.id
            end
        end
        
        if foundServer then
            game.StarterGui:SetCore("SendNotification", {
                Title = "✅ Сервер найден!",
                Text = "Игроков: " .. minPlayers .. ". Телепортируем...",
                Duration = 5
            })
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(PlaceId, foundServer, LocalPlayer)
        else
            game.StarterGui:SetCore("SendNotification", {
                Title = "❌ Сервер не найден",
                Text = "Попробуйте позже или создайте новый",
                Duration = 5
            })
        end
    end)
end)
-- ЧАСТЬ 2: НАСТРОЙКИ ВКЛАДОК VISUAL, PLAYER И ПОЛЗУНКИ
local UserInputService = game:GetService("UserInputService")
local MainFrame = _G.RomanMainFrame

local VisualScroll = Instance.new("ScrollingFrame")
VisualScroll.Size = UDim2.new(1, 0, 1, 0)
VisualScroll.BackgroundTransparency = 1
VisualScroll.CanvasSize = UDim2.new(0, 0, 0, 350) 
VisualScroll.ScrollBarThickness = 3
VisualScroll.Parent = _G.VisualContentFrame

local function CreateVisualToggle(textOn, textOff, yPos, startState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 190, 0, 28)
    btn.Position = UDim2.new(0.5, -95, 0, yPos)
    btn.BackgroundColor3 = startState and Color3.fromRGB(55, 60, 75) or Color3.fromRGB(45, 45, 50)
    btn.Text = startState and textOn or textOff
    btn.TextColor3 = startState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = VisualScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local state = startState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and textOn or textOff
        btn.BackgroundColor3 = state and Color3.fromRGB(55, 60, 75) or Color3.fromRGB(45, 45, 50)
        btn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
        callback(state)
    end)
end

CreateVisualToggle("BOXES: VISIBLE", "BOXES: HIDDEN", 5, true, function(v) Vis_Boxes = v end)
CreateVisualToggle("LINES: VISIBLE", "LINES: HIDDEN", 38, true, function(v) Vis_Lines = v end)
CreateVisualToggle("FOV CIRCLE: VISIBLE", "FOV CIRCLE: HIDDEN", 71, true, function(v) Vis_FOV = v end)
CreateVisualToggle("NAMES: VISIBLE", "NAMES: HIDDEN", 104, true, function(v) Vis_Names = v end)
CreateVisualToggle("DISTANCE: VISIBLE", "DISTANCE: HIDDEN", 137, true, function(v) Vis_Dist = v end)

-- Ползунок 1: FOV
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0, 190, 0, 15)
SliderLabel.Position = UDim2.new(0.5, -95, 0, 175)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "FOV Радиус: " .. tostring(Aimbot_FOV)
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextSize = 10
SliderLabel.Parent = VisualScroll

local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(0, 190, 0, 6)
SliderFrame.Position = UDim2.new(0.5, -95, 0, 195)
SliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SliderFrame.Parent = VisualScroll

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(Aimbot_FOV / 500, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
SliderFill.Parent = SliderFrame

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 12, 0, 12)
SliderButton.Position = UDim2.new(Aimbot_FOV / 500, -6, 0.5, -6)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.Text = ""
SliderButton.Parent = SliderFrame
Instance.new("UICorner", SliderButton).CornerRadius = UDim.new(1,0)

-- Ползунок 2: Размер прицела
local CrosshairSliderLabel = Instance.new("TextLabel")
CrosshairSliderLabel.Size = UDim2.new(0, 190, 0, 15)
CrosshairSliderLabel.Position = UDim2.new(0.5, -95, 0, 215)
CrosshairSliderLabel.BackgroundTransparency = 1
CrosshairSliderLabel.Text = "Размер прицела: " .. tostring(Crosshair_Size)
CrosshairSliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CrosshairSliderLabel.Font = Enum.Font.GothamBold
CrosshairSliderLabel.TextSize = 10
CrosshairSliderLabel.Parent = VisualScroll

local CrosshairSliderFrame = Instance.new("Frame")
CrosshairSliderFrame.Size = UDim2.new(0, 190, 0, 6)
CrosshairSliderFrame.Position = UDim2.new(0.5, -95, 0, 235)
CrosshairSliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
CrosshairSliderFrame.Parent = VisualScroll

local CrosshairSliderFill = Instance.new("Frame")
CrosshairSliderFill.Size = UDim2.new((Crosshair_Size - 3) / 47, 0, 1, 0)
CrosshairSliderFill.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
CrosshairSliderFill.Parent = CrosshairSliderFrame

local CrosshairSliderButton = Instance.new("TextButton")
CrosshairSliderButton.Size = UDim2.new(0, 12, 0, 12)
CrosshairSliderButton.Position = UDim2.new((Crosshair_Size - 3) / 47, -6, 0.5, -6)
CrosshairSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CrosshairSliderButton.Text = ""
CrosshairSliderButton.Parent = CrosshairSliderFrame
Instance.new("UICorner", CrosshairSliderButton).CornerRadius = UDim.new(1,0)

-- Плавность Аима
local SmoothSliderLabel = Instance.new("TextLabel")
SmoothSliderLabel.Size = UDim2.new(0, 190, 0, 15)
SmoothSliderLabel.Position = UDim2.new(0.5, -95, 0, 255)
SmoothSliderLabel.BackgroundTransparency = 1
SmoothSliderLabel.Text = "Плавность Аима: " .. string.format("%.2f", Aimbot_Smoothness)
SmoothSliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SmoothSliderLabel.Font = Enum.Font.GothamBold
SmoothSliderLabel.TextSize = 10
SmoothSliderLabel.Parent = VisualScroll

local SmoothSliderFrame = Instance.new("Frame")
SmoothSliderFrame.Size = UDim2.new(0, 190, 0, 6)
SmoothSliderFrame.Position = UDim2.new(0.5, -95, 0, 275)
SmoothSliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SmoothSliderFrame.Parent = VisualScroll

local SmoothSliderFill = Instance.new("Frame")
SmoothSliderFill.Size = UDim2.new((Aimbot_Smoothness - 0.05) / 0.95, 0, 1, 0)
SmoothSliderFill.BackgroundColor3 = Color3.fromRGB(230, 230, 50)
SmoothSliderFill.Parent = SmoothSliderFrame

local SmoothSliderButton = Instance.new("TextButton")
SmoothSliderButton.Size = UDim2.new(0, 12, 0, 12)
SmoothSliderButton.Position = UDim2.new((Aimbot_Smoothness - 0.05) / 0.95, -6, 0.5, -6)
SmoothSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SmoothSliderButton.Text = ""
SmoothSliderButton.Parent = SmoothSliderFrame
Instance.new("UICorner", SmoothSliderButton).CornerRadius = UDim.new(1,0)

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1, 0, 1, 0)
PlayerScroll.BackgroundTransparency = 1
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 330)
PlayerScroll.ScrollBarThickness = 3
PlayerScroll.Parent = _G.PlayerContentFrame

local InfJumpBtn = Instance.new("TextButton")
InfJumpBtn.Size = UDim2.new(0, 190, 0, 30)
InfJumpBtn.Position = UDim2.new(0.5, -95, 0, 5)
InfJumpBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
InfJumpBtn.Text = "INF JUMP: OFF"
InfJumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
InfJumpBtn.Font = Enum.Font.GothamBold
InfJumpBtn.TextSize = 11
InfJumpBtn.Parent = PlayerScroll
Instance.new("UICorner", InfJumpBtn).CornerRadius = UDim.new(0,6)

InfJumpBtn.MouseButton1Click:Connect(function()
    Fly_Enabled = not Fly_Enabled
    InfJumpBtn.Text = Fly_Enabled and "INF JUMP: ON" or "INF JUMP: OFF"
    InfJumpBtn.BackgroundColor3 = Fly_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local NoclipBtn = Instance.new("TextButton")
NoclipBtn.Size = UDim2.new(0, 190, 0, 30)
NoclipBtn.Position = UDim2.new(0.5, -95, 0, 40)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
NoclipBtn.Text = "NOCLIP: OFF"
NoclipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoclipBtn.Font = Enum.Font.GothamBold
NoclipBtn.TextSize = 11
NoclipBtn.Parent = PlayerScroll
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0,6)

NoclipBtn.MouseButton1Click:Connect(function()
    Noclip_Enabled = not Noclip_Enabled
    NoclipBtn.Text = Noclip_Enabled and "NOCLIP: ON" or "NOCLIP: OFF"
    NoclipBtn.BackgroundColor3 = Noclip_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

-- Новая кнопка GOD MODE
local GodModeBtn = Instance.new("TextButton")
GodModeBtn.Size = UDim2.new(0, 190, 0, 30)
GodModeBtn.Position = UDim2.new(0.5, -95, 0, 75)
GodModeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
GodModeBtn.Text = "GOD MODE: OFF"
GodModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GodModeBtn.Font = Enum.Font.GothamBold
GodModeBtn.TextSize = 11
GodModeBtn.Parent = PlayerScroll
Instance.new("UICorner", GodModeBtn).CornerRadius = UDim.new(0,6)

GodModeBtn.MouseButton1Click:Connect(function()
    GodMode_Enabled = not GodMode_Enabled
    GodModeBtn.Text = GodMode_Enabled and "GOD MODE: ON" or "GOD MODE: OFF"
    GodModeBtn.BackgroundColor3 = GodMode_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local SpeedToggleBtn = Instance.new("TextButton")
SpeedToggleBtn.Size = UDim2.new(0, 190, 0, 25)
SpeedToggleBtn.Position = UDim2.new(0.5, -95, 0, 115)
SpeedToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
SpeedToggleBtn.Text = "SPEED HACK: OFF"
SpeedToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedToggleBtn.Font = Enum.Font.GothamBold
SpeedToggleBtn.TextSize = 10
SpeedToggleBtn.Parent = PlayerScroll
Instance.new("UICorner", SpeedToggleBtn).CornerRadius = UDim.new(0,5)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 190, 0, 15)
SpeedLabel.Position = UDim2.new(0.5, -95, 0, 145)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Значение Скорости: " .. tostring(WalkSpeed_Value)
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 10
SpeedLabel.Parent = PlayerScroll

local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(0, 190, 0, 6)
SpeedFrame.Position = UDim2.new(0.5, -95, 0, 165)
SpeedFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SpeedFrame.Parent = PlayerScroll

local SpeedFill = Instance.new("Frame")
SpeedFill.Size = UDim2.new((WalkSpeed_Value - 16) / 234, 0, 1, 0)
SpeedFill.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
SpeedFill.Parent = SpeedFrame

local SpeedSliderBtn = Instance.new("TextButton")
SpeedSliderBtn.Size = UDim2.new(0, 12, 0, 12)
SpeedSliderBtn.Position = UDim2.new((WalkSpeed_Value - 16) / 234, -6, 0.5, -6)
SpeedSliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SpeedSliderBtn.Text = ""
SpeedSliderBtn.Parent = SpeedFrame
Instance.new("UICorner", SpeedSliderBtn).CornerRadius = UDim.new(1,0)

SpeedToggleBtn.MouseButton1Click:Connect(function()
    Speed_Enabled = not Speed_Enabled
    SpeedToggleBtn.Text = Speed_Enabled and "SPEED HACK: ON" or "SPEED HACK: OFF"
    SpeedToggleBtn.BackgroundColor3 = Speed_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local JumpToggleBtn = Instance.new("TextButton")
JumpToggleBtn.Size = UDim2.new(0, 190, 0, 25)
JumpToggleBtn.Position = UDim2.new(0.5, -95, 0, 185)
JumpToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
JumpToggleBtn.Text = "JUMP POWER: OFF"
JumpToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpToggleBtn.Font = Enum.Font.GothamBold
JumpToggleBtn.TextSize = 10
JumpToggleBtn.Parent = PlayerScroll
Instance.new("UICorner", JumpToggleBtn).CornerRadius = UDim.new(0,5)

local JumpLabel = Instance.new("TextLabel")
JumpLabel.Size = UDim2.new(0, 190, 0, 15)
JumpLabel.Position = UDim2.new(0.5, -95, 0, 215)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Text = "Высота Прыжка: " .. tostring(JumpPower_Value)
JumpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
JumpLabel.Font = Enum.Font.GothamBold
JumpLabel.TextSize = 10
JumpLabel.Parent = PlayerScroll

local JumpFrame = Instance.new("Frame")
JumpFrame.Size = UDim2.new(0, 190, 0, 6)
JumpFrame.Position = UDim2.new(0.5, -95, 0, 235)
JumpFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
JumpFrame.Parent = PlayerScroll

local JumpFill = Instance.new("Frame")
JumpFill.Size = UDim2.new((JumpPower_Value - 50) / 300, 0, 1, 0)
JumpFill.BackgroundColor3 = Color3.fromRGB(200, 0, 255)
JumpFill.Parent = JumpFrame

local JumpSliderBtn = Instance.new("TextButton")
JumpSliderBtn.Size = UDim2.new(0, 12, 0, 12)
JumpSliderBtn.Position = UDim2.new((JumpPower_Value - 50) / 300, -6, 0.5, -6)
JumpSliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
JumpSliderBtn.Text = ""
JumpSliderBtn.Parent = JumpFrame
Instance.new("UICorner", JumpSliderBtn).CornerRadius = UDim.new(1,0)

JumpToggleBtn.MouseButton1Click:Connect(function()
    Jump_Enabled = not Jump_Enabled
    JumpToggleBtn.Text = Jump_Enabled and "JUMP POWER: ON" or "JUMP POWER: OFF"
    JumpToggleBtn.BackgroundColor3 = Jump_Enabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local draggingFOV, draggingCrosshair, draggingSpeed, draggingJump, draggingSmooth = false, false, false, false, false

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFOV = false draggingCrosshair = false draggingSpeed = false draggingJump = false draggingSmooth = false
    end
end)

SliderButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingFOV = true end end)
CrosshairSliderButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingCrosshair = true end end)
SpeedSliderBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSpeed = true end end)
JumpSliderBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingJump = true end end)
SmoothSliderButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSmooth = true end end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if draggingFOV then
            local percentage = math.clamp((input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
            Aimbot_FOV = math.floor(10 + (percentage * 490))
            SliderLabel.Text = "FOV Радиус: " .. tostring(Aimbot_FOV)
            SliderButton.Position = UDim2.new(percentage, -6, 0.5, -6) SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        elseif draggingCrosshair then
            local percentage = math.clamp((input.Position.X - CrosshairSliderFrame.AbsolutePosition.X) / CrosshairSliderFrame.AbsoluteSize.X, 0, 1)
            Crosshair_Size = math.floor(3 + (percentage * 47))
            CrosshairSliderLabel.Text = "Размер прицела: " .. tostring(Crosshair_Size)
            CrosshairSliderButton.Position = UDim2.new(percentage, -6, 0.5, -6) CrosshairSliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        elseif draggingSmooth then
            local percentage = math.clamp((input.Position.X - SmoothSliderFrame.AbsolutePosition.X) / SmoothSliderFrame.AbsoluteSize.X, 0, 1)
            Aimbot_Smoothness = 0.05 + (percentage * 0.95)
            SmoothSliderLabel.Text = "Плавность Аима: " .. string.format("%.2f", Aimbot_Smoothness)
            SmoothSliderButton.Position = UDim2.new(percentage, -6, 0.5, -6) SmoothSliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        elseif draggingSpeed then
            local percentage = math.clamp((input.Position.X - SpeedFrame.AbsolutePosition.X) / SpeedFrame.AbsoluteSize.X, 0, 1)
            WalkSpeed_Value = math.floor(16 + (percentage * 234))
            SpeedLabel.Text = "Значение Скорости: " .. tostring(WalkSpeed_Value)
            SpeedSliderBtn.Position = UDim2.new(percentage, -6, 0.5, -6) SpeedFill.Size = UDim2.new(percentage, 0, 1, 0)
        elseif draggingJump then
            local percentage = math.clamp((input.Position.X - JumpFrame.AbsolutePosition.X) / JumpFrame.AbsoluteSize.X, 0, 1)
            JumpPower_Value = math.floor(50 + (percentage * 300))
            JumpLabel.Text = "Высота Прыжка: " .. tostring(JumpPower_Value)
            JumpSliderBtn.Position = UDim2.new(percentage, -6, 0.5, -6) JumpFill.Size = UDim2.new(percentage, 0, 1, 0)
        end
    end
end)

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 2)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.Parent = MainFrame

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Position = UDim2.new(0, 10, 0.3, 0)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
OpenButton.Text = "MENU"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 12
OpenButton.Visible = false
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = MainFrame.Parent
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1,0)

CloseButton.MouseButton1Click:Connect(function() MainFrame.Visible = false OpenButton.Visible = true end)
local dragStartPos = nil
OpenButton.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStartPos = OpenButton.Position end end)
OpenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos then
            local dist = math.sqrt((OpenButton.Position.X.Offset - dragStartPos.X.Offset)^2 + (OpenButton.Position.Y.Offset - dragStartPos.Y.Offset)^2)
            if dist < 5 then MainFrame.Visible = true OpenButton.Visible = false end
        end
    end
end)
