
--==================================================
-- THE COMPLEX | Roblox Studio LocalScript
-- Place in StarterPlayer > StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cleanup previous version
local old = playerGui:FindFirstChild("THE_COMPLEX")
if old then old:Destroy() end

local state = {
    esp = false,
    fullbright = false,
    speed = false,
    fly = false,
    noclip = false,
    walkSpeed = 32,
    minimized = false,
    closed = false
}

local espObjects = {}
local savedCollision = {}

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local originalWalkSpeed = 16

local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "THE_COMPLEX"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local function make(className, props, parent)
    local obj = Instance.new(className)

    for key, value in pairs(props) do
        obj[key] = value
    end

    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, obj)
end

local PURPLE = Color3.fromRGB(130, 80, 255)
local DARK = Color3.fromRGB(18, 18, 25)
local PANEL = Color3.fromRGB(29, 29, 40)
local WHITE = Color3.fromRGB(240, 240, 250)
local GREEN = Color3.fromRGB(0, 255, 80)
local RED = Color3.fromRGB(255, 45, 45)

local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(320, 440),
    Position = UDim2.new(0.5, -160, 0.5, -220),
    BackgroundColor3 = DARK,
    BorderSizePixel = 0
}, gui)
round(main, 12)

make("UIStroke", {
    Color = PURPLE,
    Thickness = 1.5,
    Transparency = 0.15
}, main)

local top = make("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0
}, main)
round(top, 12)

make("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0
}, top)

make("TextLabel", {
    Size = UDim2.new(1, -105, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "THE COMPLEX",
    TextColor3 = WHITE,
    TextSize = 20,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, top)

local function topButton(text, x, color)
    local button = make("TextButton", {
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, x, 0, 11),
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = WHITE,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0
    }, top)

    round(button, 7)
    return button
end

local minimizeButton = topButton("-", -76, PURPLE)
local closeButton = topButton("X", -38, Color3.fromRGB(180, 55, 75))

local content = make("ScrollingFrame", {
    Name = "Content",
    Position = UDim2.fromOffset(10, 62),
    Size = UDim2.new(1, -20, 1, -72),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = PURPLE,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y
}, main)

make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, content)

local function makeButton(text, order)
    local button = make("TextButton", {
        Size = UDim2.new(1, -6, 0, 42),
        BackgroundColor3 = PANEL,
        Text = text,
        TextColor3 = WHITE,
        TextSize = 14,
        Font = Enum.Font.GothamSemibold,
        BorderSizePixel = 0,
        LayoutOrder = order,
        AutoButtonColor = true
    }, content)

    round(button, 8)
    return button
end

local function refreshButton(button, label, enabled)
    button.Text = label .. ": " .. (enabled and "ON" or "OFF")
    button.BackgroundColor3 = enabled and PURPLE or PANEL
end

--==================================================
-- ESP: GREEN PLAYERS / RED NPCs
-- Automatically scans Workspace. No folder required.
--==================================================

local function removeESP(model)
    local data = espObjects[model]
    if not data then return end

    if data.highlight then
        data.highlight:Destroy()
    end

    if data.billboard then
        data.billboard:Destroy()
    end

    espObjects[model] = nil
end

local function addESP(model)
    if not state.esp then return end
    if not model or not model:IsA("Model") then return end
    if model == player.Character then return end
    if not model:IsDescendantOf(Workspace) then return end
    if espObjects[model] then return end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- A real player has a character registered in Players.
    -- A Humanoid model without a registered player is an NPC.
    local targetPlayer = Players:GetPlayerFromCharacter(model)
    local isPlayer = targetPlayer ~= nil

    local color = isPlayer and GREEN or RED

    local highlight = make("Highlight", {
        Name = "ComplexESP",
        Adornee = model,
        FillColor = color,
        OutlineColor = color,
        FillTransparency = 0.65,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    }, gui)

    local head = model:FindFirstChild("Head")
        or model:FindFirstChild("HumanoidRootPart")

    local billboard
    local label

    if head and head:IsA("BasePart") then
        billboard = make("BillboardGui", {
            Name = "ComplexESPInfo",
            Adornee = head,
            Size = UDim2.fromOffset(220, 38),
            StudsOffset = Vector3.new(0, 2.5, 0),
            AlwaysOnTop = true
        }, gui)

        label = make("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = color,
            TextStrokeTransparency = 0.2,
            TextSize = 13,
            Font = Enum.Font.GothamBold
        }, billboard)
    end

    espObjects[model] = {
        highlight = highlight,
        billboard = billboard,
        label = label,
        head = head,
        color = color
    }
end

-- Find the model containing a newly added Humanoid or body part.
local function scanCandidate(instance)
    if not state.esp then return end

    local current = instance

    while current and current ~= Workspace do
        if current:IsA("Model")
            and current:FindFirstChildOfClass("Humanoid") then
            addESP(current)
            return
        end

        current = current.Parent
    end
end

local function scanWorkspace()
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if instance:IsA("Humanoid") then
            scanCandidate(instance)
        end
    end
end

local espButton = makeButton("ESP: OFF", 1)

espButton.Activated:Connect(function()
    state.esp = not state.esp
    refreshButton(espButton, "ESP", state.esp)

    if state.esp then
        scanWorkspace()
    else
        for model in pairs(espObjects) do
            removeESP(model)
        end
    end
end)

-- Detect NPCs and player characters added after ESP is enabled.
Workspace.DescendantAdded:Connect(function(instance)
    if instance:IsA("Humanoid") then
        task.defer(function()
            scanCandidate(instance)
        end)
    end
end)

local function watchPlayer(target)
    target.CharacterAdded:Connect(function(character)
        task.wait(0.5)

        if state.esp and target ~= player then
            addESP(character)
        end
    end)
end

for _, target in ipairs(Players:GetPlayers()) do
    watchPlayer(target)

    if target ~= player and target.Character then
        addESP(target.Character)
    end
end

Players.PlayerAdded:Connect(watchPlayer)

Players.PlayerRemoving:Connect(function(target)
    if target.Character then
        removeESP(target.Character)
    end
end)

-- Update displayed distance and remove stale ESP objects.
RunService.RenderStepped:Connect(function()
    for model, data in pairs(espObjects) do
        if not model.Parent or not model:IsDescendantOf(Workspace) then
            removeESP(model)
        elseif data.label and data.head and data.head.Parent then
            local root = getRoot()

            if root then
                local distance = math.floor(
                    (root.Position - data.head.Position).Magnitude
                )

                data.label.Text = model.Name
                    .. " [" .. distance .. " studs]"
            end
        end
    end
end)

--==================================================
-- FULLBRIGHT
--==================================================

local fullbrightButton = makeButton("Fullbright: OFF", 2)

fullbrightButton.Activated:Connect(function()
    state.fullbright = not state.fullbright
    refreshButton(fullbrightButton, "Fullbright", state.fullbright)

    if state.fullbright then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        for property, value in pairs(originalLighting) do
            Lighting[property] = value
        end
    end
end)

--==================================================
-- RUN SPEED + SLIDER
--==================================================

local speedButton = makeButton("Run Speed: OFF", 3)

speedButton.Activated:Connect(function()
    state.speed = not state.speed
    refreshButton(speedButton, "Run Speed", state.speed)

    local hum = getHumanoid()

    if hum then
        if state.speed then
            hum.WalkSpeed = state.walkSpeed
        else
            hum.WalkSpeed = originalWalkSpeed
        end
    end
end)

local speedLabel = make("TextLabel", {
    Size = UDim2.new(1, -6, 0, 28),
    BackgroundTransparency = 1,
    Text = "Speed: 32",
    TextColor3 = WHITE,
    TextSize = 13,
    Font = Enum.Font.GothamSemibold,
    LayoutOrder = 4
}, content)

local slider = make("Frame", {
    Size = UDim2.new(1, -6, 0, 24),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    LayoutOrder = 5
}, content)
round(slider, 8)

local fill = make("Frame", {
    Size = UDim2.new((32 - 16) / 84, 0, 1, 0),
    BackgroundColor3 = PURPLE,
    BorderSizePixel = 0
}, slider)
round(fill, 8)

local draggingSlider = false

local function setSpeedFromX(x)
    local width = slider.AbsoluteSize.X
    if width <= 0 then return end

    local alpha = math.clamp(
        (x - slider.AbsolutePosition.X) / width, 0, 1
    )

    state.walkSpeed = math.floor(16 + alpha * 84)
    fill.Size = UDim2.new(alpha, 0, 1, 0)
    speedLabel.Text = "Speed: " .. state.walkSpeed

    if state.speed then
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = state.walkSpeed
        end
    end
end

slider.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        setSpeedFromX(input.Position.X)
    end
end)

UIS.InputChanged:Connect(function(input)
    if draggingSlider and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        setSpeedFromX(input.Position.X)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

--==================================================
-- NOCLIP (testing your own experience)
--==================================================

local noclipButton = makeButton("Noclip: OFF", 6)

noclipButton.Activated:Connect(function()
    state.noclip = not state.noclip
    refreshButton(noclipButton, "Noclip", state.noclip)

    if not state.noclip then
        for part, wasCollidable in pairs(savedCollision) do
            if part and part.Parent then
                part.CanCollide = wasCollidable
            end
        end

        table.clear(savedCollision)
    end
end)

RunService.Stepped:Connect(function()
    if not state.noclip then return end

    local character = getCharacter()
    if not character then return end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if savedCollision[part] == nil then
                savedCollision[part] = part.CanCollide
            end

            part.CanCollide = false
        end
    end
end)

--==================================================
-- FLY (keyboard: WASD, Space up, LeftCtrl down)
--==================================================

local flyButton = makeButton("Fly: OFF", 7)
local flyConnection
local bodyVelocity
local bodyGyro

local function stopFly()
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
end

local function startFly()
    local root = getRoot()
    if not root then
        state.fly = false
        refreshButton(flyButton, "Fly", false)
        return
    end

    bodyVelocity = make("BodyVelocity", {
        MaxForce = Vector3.new(1e6, 1e6, 1e6),
        Velocity = Vector3.zero
    }, root)

    bodyGyro = make("BodyGyro", {
        MaxTorque = Vector3.new(1e6, 1e6, 1e6),
        P = 9000,
        CFrame = root.CFrame
    }, root)

    flyConnection = RunService.RenderStepped:Connect(function()
        if not state.fly or not root.Parent then
            stopFly()
            return
        end

        local camera = Workspace.CurrentCamera
        if not camera then return end

        local direction = Vector3.zero

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            direction += camera.CFrame.LookVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.S) then
            direction -= camera.CFrame.LookVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.A) then
            direction -= camera.CFrame.RightVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.D) then
            direction += camera.CFrame.RightVector
        end

        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            direction += Vector3.yAxis
        end

        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= Vector3.yAxis
        end

        bodyVelocity.Velocity = direction.Magnitude > 0
            and direction.Unit * state.walkSpeed
            or Vector3.zero

        bodyGyro.CFrame = camera.CFrame
    end)
end

flyButton.Activated:Connect(function()
    state.fly = not state.fly
    refreshButton(flyButton, "Fly", state.fly)

    if state.fly then
        startFly()
    else
        stopFly()
    end
end)

--==================================================
-- FLOATING TC BUTTON
--==================================================

local floating = make("TextButton", {
    Name = "FloatingTC",
    Size = UDim2.fromOffset(52, 52),
    Position = UDim2.new(0, 18, 0.5, -26),
    BackgroundColor3 = PURPLE,
    Text = "TC",
    TextColor3 = WHITE,
    TextSize = 18,
    Font = Enum.Font.GothamBlack,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10
}, gui)
round(floating, 26)

local function setMinimized(value)
    state.minimized = value
    main.Visible = not value
    floating.Visible = value
end

minimizeButton.Activated:Connect(function()
    setMinimized(true)
end)

floating.Activated:Connect(function()
    setMinimized(false)
end)

--==================================================
-- DRAG MENU (mouse + touch)
--==================================================

local dragging = false
local dragStart
local startPosition

top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- RIGHT SHIFT TO TOGGLE MENU
--==================================================

UIS.InputBegan:Connect(function(input, processed)
    if processed or state.closed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        setMinimized(not state.minimized)
    end
end)

--==================================================
-- RESPAWN HANDLING
--==================================================

player.CharacterAdded:Connect(function(character)
    local hum = character:WaitForChild("Humanoid", 10)

    if hum then
        originalWalkSpeed = hum.WalkSpeed

        if state.speed then
            hum.WalkSpeed = state.walkSpeed
        end
    end

    if state.fly then
        state.fly = false
        stopFly()
        refreshButton(flyButton, "Fly", false)
    end

    task.wait(0.5)

    if state.esp then
        scanWorkspace()
    end
end)

--==================================================
-- CLOSE + RESTORE SETTINGS
--==================================================

closeButton.Activated:Connect(function()
    state.closed = true
    state.esp = false
    state.fly = false
    state.noclip = false

    stopFly()

    for model in pairs(espObjects) do
        removeESP(model)
    end

    for part, wasCollidable in pairs(savedCollision) do
        if part and part.Parent then
            part.CanCollide = wasCollidable
        end
    end

    if state.fullbright then
        for property, value in pairs(originalLighting) do
            Lighting[property] = value
        end
    end

    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = originalWalkSpeed
    end

    gui:Destroy()
end)

print("[THE COMPLEX] Loaded successfully")
