-- Garante que o jogo tá carregado
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Variáveis Globais de Controle do Cheat
local CheatConfig = {
    ESP_Enabled = false,
    ESP_Boxes = false,
    ESP_BoxType = "2D", -- "2D" ou "3D"
    ESP_Names = false,
    ESP_Health = false,
    ESP_Distance = false,
    ESP_Snaplines = false,
    ESP_SnaplineOrigin = "Bottom", -- "Top", "Center", "Bottom"
    ESP_Glow = false,
    
    -- Cores Individuais
    Color_Box = Color3.fromRGB(255, 0, 0),
    Color_Text = Color3.fromRGB(255, 255, 255),
    Color_Snapline = Color3.fromRGB(255, 0, 0),
    Color_Glow = Color3.fromRGB(255, 0, 0),
    -- Aimbot
    Aimbot_Enabled = false,
    Aimbot_FOV = 100,
    Aimbot_Smoothness = 1,
    Aimbot_TargetPart = "Head",
    
    WalkSpeed = 16
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ==========================================
-- 0. FOV CIRCLE (DRAWING API)
-- ==========================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = CheatConfig.Aimbot_FOV
FOVCircle.Filled = false

-- ==========================================
-- 1. SISTEMA DE ESP (DRAWING API & HIGHLIGHTS)
-- ==========================================
local ESP_Instances = {}

-- Função pra calcular as 8 pontas da hitbox 3D
local function GetBox3DPositions(hrp, size)
    local cframe = hrp.CFrame
    local sx, sy, sz = size.X/2, size.Y/2, size.Z/2
    return {
        cframe * CFrame.new(sx, sy, sz),
        cframe * CFrame.new(-sx, sy, sz),
        cframe * CFrame.new(-sx, -sy, sz),
        cframe * CFrame.new(sx, -sy, sz),
        cframe * CFrame.new(sx, sy, -sz),
        cframe * CFrame.new(-sx, sy, -sz),
        cframe * CFrame.new(-sx, -sy, -sz),
        cframe * CFrame.new(sx, -sy, -sz)
    }
end

local function CreateESP(player)
    if player == Players.LocalPlayer then return end

    -- Box 2D
    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false

    -- Texto (Nome, Vida, Distância)
    local Text = Drawing.new("Text")
    Text.Visible = false
    Text.Center = true
    Text.Outline = true
    Text.Font = 2
    Text.Size = 13

    -- Snapline
    local Snapline = Drawing.new("Line")
    Snapline.Visible = false
    Snapline.Thickness = 1
    Snapline.Transparency = 1

    -- Glow (Chams via Highlight)
    local Glow = Instance.new("Highlight")
    Glow.Name = "ArenaCheatGlow"
    Glow.OutlineColor = Color3.fromRGB(255, 255, 255)
    Glow.FillTransparency = 0.5
    Glow.OutlineTransparency = 0
    Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    -- Não parentamos ainda pra não quebrar. Fica salvo na memória.

    -- Box 3D (12 linhas compondo um cubo)
    local Box3D = {}
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        line.Transparency = 1
        Box3D[i] = line
    end

    ESP_Instances[player] = {Box = Box, Box3D = Box3D, Text = Text, Snapline = Snapline, Glow = Glow}
end

-- Hookando quem já tá na partida
for _, player in ipairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)

Players.PlayerRemoving:Connect(function(player)
    if ESP_Instances[player] then
        ESP_Instances[player].Box:Remove()
        for i = 1, 12 do ESP_Instances[player].Box3D[i]:Remove() end
        ESP_Instances[player].Text:Remove()
        ESP_Instances[player].Snapline:Remove()
        if ESP_Instances[player].Glow then ESP_Instances[player].Glow:Destroy() end
        ESP_Instances[player] = nil
    end
end)

-- Função para achar o alvo mais próximo do mouse dentro do FOV
local function GetClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart = player.Character:FindFirstChild(CheatConfig.Aimbot_TargetPart)
            if targetPart then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < CheatConfig.Aimbot_FOV and dist < shortestDistance then
                        closestPlayer = player
                        shortestDistance = dist
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Main Loop - GPU
RunService.RenderStepped:Connect(function()
    -- Atualiza e desenha o FOV Circle no mouse
    if CheatConfig.Aimbot_Enabled then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Radius = CheatConfig.Aimbot_FOV
        FOVCircle.Visible = true
        
        -- Lógica do Aimbot (Ativando no botão direito do mouse - InputType = MouseButton2)
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local target = GetClosestPlayerToMouse()
            if target and target.Character and target.Character:FindFirstChild(CheatConfig.Aimbot_TargetPart) then
                local targetPos = target.Character[CheatConfig.Aimbot_TargetPart].Position
                local currentCameraPos = Camera.CFrame.Position
                -- Suavização (Smoothness)
                local newCFrame = CFrame.new(currentCameraPos, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, CheatConfig.Aimbot_Smoothness)
            end
        end
    else
        FOVCircle.Visible = false
    end

    for player, esp in pairs(ESP_Instances) do
        -- Master Switch: Desliga tudo se o Toggle Global tiver Off
        if not CheatConfig.ESP_Enabled then
            esp.Box.Visible = false
            for i = 1, 12 do esp.Box3D[i].Visible = false end
            esp.Text.Visible = false
            esp.Snapline.Visible = false
            if esp.Glow.Parent then esp.Glow.Parent = nil end
            continue
        end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            
            local hrp = char.HumanoidRootPart
            local head = char:FindFirstChild("Head")
            if not head then continue end

            local hrpPos, OnScreen = Camera:WorldToViewportPoint(hrp.Position)
            local HeadPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local LegPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            
            -- Atualiza Cores Dinamicamente
            esp.Box.Color = CheatConfig.Color_Box
            for i = 1, 12 do esp.Box3D[i].Color = CheatConfig.Color_Box end
            
            esp.Text.Color = CheatConfig.Color_Text
            esp.Snapline.Color = CheatConfig.Color_Snapline
            esp.Glow.FillColor = CheatConfig.Color_Glow

            -- Aplicando o Glow (Wallhack interno)
            if CheatConfig.ESP_Glow then
                if esp.Glow.Parent ~= char then
                    esp.Glow.Parent = char
                end
            else
                if esp.Glow.Parent then esp.Glow.Parent = nil end
            end

            if OnScreen then
                -- Matemática Base
                local BoxHeight = math.abs(HeadPos.Y - LegPos.Y)
                local BoxWidth = BoxHeight / 2
                
                -- Controle de Boxes
                if CheatConfig.ESP_Boxes and CheatConfig.ESP_BoxType == "2D" then
                    esp.Box.Size = Vector2.new(BoxWidth, BoxHeight)
                    esp.Box.Position = Vector2.new(hrpPos.X - BoxWidth / 2, HeadPos.Y)
                    esp.Box.Visible = true
                    for i = 1, 12 do esp.Box3D[i].Visible = false end

                elseif CheatConfig.ESP_Boxes and CheatConfig.ESP_BoxType == "3D" then
                    esp.Box.Visible = false
                    local extents = char:GetExtentsSize()
                    local corners = GetBox3DPositions(hrp, extents)
                    local screenCorners = {}
                    
                    for i, c in ipairs(corners) do
                        local pos = Camera:WorldToViewportPoint(c.Position)
                        screenCorners[i] = Vector2.new(pos.X, pos.Y)
                    end
                    
                    -- Conectando os vértices do Box 3D
                    local lines = {
                        {1,2}, {2,3}, {3,4}, {4,1}, -- Frente
                        {5,6}, {6,7}, {7,8}, {8,5}, -- Trás
                        {1,5}, {2,6}, {3,7}, {4,8}  -- Laterais
                    }
                    for i = 1, 12 do
                        esp.Box3D[i].From = screenCorners[lines[i][1]]
                        esp.Box3D[i].To = screenCorners[lines[i][2]]
                        esp.Box3D[i].Visible = true
                    end
                else
                    esp.Box.Visible = false
                    for i = 1, 12 do esp.Box3D[i].Visible = false end
                end

                -- Controle de Textos (Nomes, Vida, Distância)
                local textString = ""
                if CheatConfig.ESP_Names then
                    textString = textString .. player.Name .. "\n"
                end
                if CheatConfig.ESP_Health then
                    textString = textString .. "[" .. math.floor(char.Humanoid.Health) .. " HP]\n"
                end
                if CheatConfig.ESP_Distance then
                    local distance = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                    textString = textString .. distance .. " studs"
                end

                if textString ~= "" then
                    esp.Text.Position = Vector2.new(hrpPos.X, HeadPos.Y - 15 - (CheatConfig.ESP_Names and 10 or 0))
                    esp.Text.Text = textString
                    esp.Text.Visible = true
                else
                    esp.Text.Visible = false
                end

                -- Controle de Snaplines
                if CheatConfig.ESP_Snaplines then
                    local originPos
                    if CheatConfig.ESP_SnaplineOrigin == "Bottom" then
                        originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    elseif CheatConfig.ESP_SnaplineOrigin == "Center" then
                        originPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    elseif CheatConfig.ESP_SnaplineOrigin == "Top" then
                        originPos = Vector2.new(Camera.ViewportSize.X / 2, 0)
                    end
                    
                    esp.Snapline.From = originPos
                    esp.Snapline.To = Vector2.new(hrpPos.X, hrpPos.Y)
                    esp.Snapline.Visible = true
                else
                    esp.Snapline.Visible = false
                end
                
            else
                -- Off-screen
                esp.Box.Visible = false
                for i = 1, 12 do esp.Box3D[i].Visible = false end
                esp.Text.Visible = false
                esp.Snapline.Visible = false
            end
        else
            -- Boneco morto ou não carregou
            esp.Box.Visible = false
            for i = 1, 12 do esp.Box3D[i].Visible = false end
            esp.Text.Visible = false
            esp.Snapline.Visible = false
            if esp.Glow.Parent then esp.Glow.Parent = nil end
        end
    end
end)

-- ==========================================
-- 2. MENU GRÁFICO (RAYFIELD)
-- ==========================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Skyfall 💀", -- Nome do Cheat Atualizado
   LoadingTitle = "Injetando Módulos...",
   LoadingSubtitle = "by Erick",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "SkyfallCheat",
      FileName = "Configs"
   },
   Discord = { Enabled = false },
   KeySystem = false
})

-- Aba Visuals
local TabVisuals = Window:CreateTab("Visuais", 4483362458)

TabVisuals:CreateToggle({
   Name = "Ativar Master ESP",
   CurrentValue = false,
   Flag = "ESP_Toggle",
   Callback = function(Value)
        CheatConfig.ESP_Enabled = Value
   end,
})

-- == SEÇÃO: BOXES ==
TabVisuals:CreateSection("Caixas (Boxes)")
TabVisuals:CreateToggle({
   Name = "Mostrar Box",
   CurrentValue = false,
   Flag = "ESP_Box",
   Callback = function(Value)
        CheatConfig.ESP_Boxes = Value
   end,
})

TabVisuals:CreateDropdown({
    Name = "Tipo de Box",
    Options = {"2D", "3D"},
    CurrentOption = {"2D"},
    MultipleOptions = false,
    Flag = "ESP_BoxType",
    Callback = function(Options)
        CheatConfig.ESP_BoxType = Options[1]
    end,
})

TabVisuals:CreateColorPicker({
    Name = "Cor do Box",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "Color_Box",
    Callback = function(Value)
        CheatConfig.Color_Box = Value
    end
})

-- == SEÇÃO: INFORMAÇÕES ==
TabVisuals:CreateSection("Informações (Textos)")
TabVisuals:CreateToggle({
   Name = "Mostrar Nomes",
   CurrentValue = false,
   Flag = "ESP_Names",
   Callback = function(Value)
        CheatConfig.ESP_Names = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Mostrar Vida",
   CurrentValue = false,
   Flag = "ESP_Health",
   Callback = function(Value)
        CheatConfig.ESP_Health = Value
   end,
})

TabVisuals:CreateToggle({
   Name = "Mostrar Distância",
   CurrentValue = false,
   Flag = "ESP_Dist",
   Callback = function(Value)
        CheatConfig.ESP_Distance = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Cor dos Textos",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "Color_Text",
    Callback = function(Value)
        CheatConfig.Color_Text = Value
    end
})

-- == SEÇÃO: RASTREADORES ==
TabVisuals:CreateSection("Rastreadores")
TabVisuals:CreateToggle({
   Name = "Snaplines",
   CurrentValue = false,
   Flag = "ESP_Snaplines",
   Callback = function(Value)
        CheatConfig.ESP_Snaplines = Value
   end,
})

TabVisuals:CreateDropdown({
    Name = "Origem das Snaplines",
    Options = {"Bottom", "Center", "Top"},
    CurrentOption = {"Bottom"},
    MultipleOptions = false,
    Flag = "ESP_SnapOrigin",
    Callback = function(Options)
        CheatConfig.ESP_SnaplineOrigin = Options[1]
    end,
})

TabVisuals:CreateColorPicker({
    Name = "Cor da Snapline",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "Color_Snapline",
    Callback = function(Value)
        CheatConfig.Color_Snapline = Value
    end
})

-- == SEÇÃO: CHAMS ==
TabVisuals:CreateSection("Modelos (Chams)")
TabVisuals:CreateToggle({
   Name = "Glow (Parede Mágica)",
   CurrentValue = false,
   Flag = "ESP_Glow",
   Callback = function(Value)
        CheatConfig.ESP_Glow = Value
   end,
})

TabVisuals:CreateColorPicker({
    Name = "Cor do Glow",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "Color_Glow",
    Callback = function(Value)
        CheatConfig.Color_Glow = Value
    end
})

-- Aba Aimbot
local TabAimbot = Window:CreateTab("Aimbot", 4483362458)

TabAimbot:CreateToggle({
   Name = "Ativar Aimbot",
   CurrentValue = false,
   Flag = "Aimbot_Toggle",
   Callback = function(Value)
        CheatConfig.Aimbot_Enabled = Value
   end,
})

TabAimbot:CreateDropdown({
    Name = "Parte do Corpo",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "Aimbot_Part",
    Callback = function(Options)
        CheatConfig.Aimbot_TargetPart = Options[1]
    end,
})

TabAimbot:CreateSlider({
   Name = "Tamanho do FOV",
   Range = {10, 500},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 100,
   Flag = "Aimbot_FOVSlider",
   Callback = function(Value)
        CheatConfig.Aimbot_FOV = Value
   end,
})

TabAimbot:CreateSlider({
   Name = "Suavização (Smoothness)",
   Range = {0.1, 1},
   Increment = 0.1,
   Suffix = "Speed",
   CurrentValue = 1,
   Flag = "Aimbot_SmoothSlider",
   Callback = function(Value)
        CheatConfig.Aimbot_Smoothness = Value
   end,
})

-- Aba Jogador
local TabPlayer = Window:CreateTab("Jogador", 4483362458)
TabPlayer:CreateSlider({
   Name = "Velocidade de Movimento (Speedhack)",
   Range = {16, 200},
   Increment = 1,
   Suffix = "WalkSpeed",
   CurrentValue = 16,
   Flag = "SpeedSlider",
   Callback = function(Value)
        local lp = game:GetService("Players").LocalPlayer
        if lp.Character and lp.Character:FindFirstChild("Humanoid") then
            lp.Character.Humanoid.WalkSpeed = Value
        end
   end,
})

Rayfield:LoadConfiguration()