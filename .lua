-- Połączony kod z usuwaniem i ustawianiem kolorów

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Usuwanie ekranu ładowania
local loadingScreen = playerGui:FindFirstChild("LoadingScreen")
if loadingScreen then
    loadingScreen:Destroy()
end

-- Referencje do GameGui
local gameGui = playerGui:FindFirstChild("GameGui")
if not gameGui then
    print("-error-")
    return
end

-- Funkcja do usuwania ekranów
local function deleteScreen(screen)
    if screen then
        screen:Destroy()
    end
end

-- Usuwanie Transition i KeyHints
deleteScreen(gameGui:FindFirstChild("Transition"))
deleteScreen(gameGui:FindFirstChild("KeyHints"))

-- Referencje do MatchHUD i EnergyBars
local matchHUD = gameGui:FindFirstChild("MatchHUD")
local energyBars = matchHUD and matchHUD:FindFirstChild("EngergyBars")

if not (matchHUD and energyBars) then
    print("-")
    return
end

-- Funkcja do ustawiania gradientu
local function setGradient(frame, startColor, endColor)
    if frame then
        local progressBar = frame:FindFirstChild("ProgressBar")
        if progressBar then
            local existingGradient = progressBar:FindFirstChild("UIGradient")
            if existingGradient then
                existingGradient:Destroy()
            end
            local newGradient = Instance.new("UIGradient")
            newGradient.Color = ColorSequence.new(startColor, endColor)
            newGradient.Rotation = 90
            newGradient.Parent = progressBar
        else
            print("-")
        end
    end
end

-- Ustawienie gradientu dla Power i Stamina
setGradient(energyBars:FindFirstChild("Power"), Color3.new(0, 0, 0), Color3.new(255, 0, 0)) -- Black to Red
setGradient(energyBars:FindFirstChild("Stamina"), Color3.new(0, 0, 0), Color3.new(255, 255, 255)) -- Black to White

-- Usuwanie PartyLeader
local party = gameGui:FindFirstChild("Party")
if party then
    local topbarLayout = party:FindFirstChild("TopbarLayout")
    local partyLayout = topbarLayout and topbarLayout:FindFirstChild("PartyLayout")
    local members = partyLayout and partyLayout:FindFirstChild("Members")

    if members then
        -- Szukamy odpowiedniego CircleButton
        local buttons = members:GetChildren()
        for _, button in ipairs(buttons) do
            if button.Name == "CircleButton" and button:FindFirstChild("Background") then
                local background = button.Background
                local partyLeader = background:FindFirstChild("PartyLeader")
                if partyLeader then
                    partyLeader:Destroy()
                    break -- Usuwamy tylko pierwszego lidera
                end
            end
        end
    else
        print("-")
    end
else
    print("-")
end






--tp ball - gol - speed
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local defaultSpeed = humanoid.WalkSpeed
local boostSpeed = 270
local boostDuration = 0.3
local debounceTime = 0.35
local unblockDelay = 0.5
local canActivateBoost = true
local isTeleporting = false

-- Function to update character and humanoid on respawn
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    defaultSpeed = humanoid.WalkSpeed
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Function to activate boost
local function activateBoost()
    if canActivateBoost then
        canActivateBoost = false
        humanoid.WalkSpeed = boostSpeed
        task.wait(boostDuration)
        humanoid.WalkSpeed = defaultSpeed
        task.wait(debounceTime)
        canActivateBoost = true
        task.wait(unblockDelay)
    end
end

-- Function to find all balls in the "Junk" folder
local function findBalls()
    local junkFolder = Workspace:FindFirstChild("Junk")
    if not junkFolder then
        warn("Junk folder not found!")
        return {}
    end

    local balls = {}
    for _, obj in ipairs(junkFolder:GetChildren()) do
        if obj:IsA("Part") and obj.Name == "Football" then
            table.insert(balls, obj)
        end
    end
    return balls
end

-- Function to teleport all balls to the team's goal
local function teleportAllBalls()
    if isTeleporting then return end
    isTeleporting = true

    local targetPosition
    if player.Team then
        if player.Team.Name == "Home" then
            targetPosition = Vector3.new(2.010676682, 4.00001144, -186.170898)
        elseif player.Team.Name == "Away" then
            targetPosition = Vector3.new(-0.214612424, 4.00001144, 186.203613)
        end
    end

    if not targetPosition then
        warn("No valid team position")
        isTeleporting = false
        return
    end

    local balls = findBalls()
    for _, ball in ipairs(balls) do
        if ball:IsA("BasePart") then
            local success, errorMessage = pcall(function()
                ball.CFrame = CFrame.new(targetPosition)
            end)
            if not success then
                warn("Error teleporting ball: " .. errorMessage)
            end
        else
            warn("Invalid ball detected")
        end
    end

    isTeleporting = false
end

-- Function to teleport specific objects to the player's position
local function movePartsToPlayer()
    local junkFolder = Workspace:FindFirstChild("Junk")
    if not junkFolder or not junkFolder:IsA("Folder") then
        warn("Junk folder not found in Workspace")
        return
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        warn("Player's HumanoidRootPart not found")
        return
    end

    local playerPosition = rootPart.Position
    for _, obj in ipairs(junkFolder:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "kick1" or obj.Name == "kick2" or obj.Name == "kick3" or obj.Name == "Football") then
            obj.Position = playerPosition
        end
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        activateBoost()
    elseif input.KeyCode == Enum.KeyCode.G then
        teleportAllBalls()
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        movePartsToPlayer()
    end
end)

-- Handle respawn
player.CharacterAdded:Connect(function()
    task.wait(0.1)
    teleportAllBalls()
end)

-- Handle team changes
player:GetPropertyChangedSignal("Team"):Connect(teleportAllBalls)

-- Handle new objects added to Workspace
Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Part") and child.Name == "Football" then
        task.wait(0.1)
        teleportAllBalls()
    end
end)

-- Initialize the character
onCharacterAdded(character)



---one good farming xp 2 players use same
local clickInterval = 0 -- Interwał czasowy pomiędzy kliknięciami (w sekundach)
local toggleKey = Enum.KeyCode.One -- Klawisz do włączania/wyłączania auto-clickera

local autoClicking = false -- Zmienna przechowująca stan auto-clickera
local teleporting = false -- Zmienna kontrolująca stan teleportacji

local Player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Funkcja symulująca kliknięcie myszą
local function autoClick()
    local VirtualInputManager = game:GetService("VirtualInputManager")

    while autoClicking do
        wait(clickInterval)
        
        -- Sprawdź czy gracz jest obecny
        if game.Players.LocalPlayer then
            -- Symulowanie kliknięcia myszą
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) -- Użycie domyślnych współrzędnych
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) -- Użycie domyślnych współrzędnych
        end
    end
end

-- Funkcja do teleportowania obiektów do pozycji gracza
local function movePartsToPlayer()
    local junkFolder = Workspace:FindFirstChild("Junk")

    if junkFolder and junkFolder:IsA("Folder") then
        local playerChar = Player.Character
        local playerHumanoidRootPart = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
        
        if playerHumanoidRootPart then
            local playerPosition = playerHumanoidRootPart.Position

            for _, obj in ipairs(junkFolder:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name == "kick1" or obj.Name == "kick2" or obj.Name == "kick3" or obj.Name == "Football") then
                    obj.CFrame = CFrame.new(playerPosition)  -- Ustawienie obiektów w pozycji gracza
                end
            end
        end
    end
end

-- Funkcja obsługująca wciśnięcie klawisza dla auto-clickera
local function onKeyPress(input, gameProcessedEvent)
    if input.KeyCode == toggleKey and not gameProcessedEvent then
        autoClicking = not autoClicking
        if autoClicking then
            spawn(autoClick) -- Uruchomienie auto-clickera w nowym wątku
        end
    end
end

-- Funkcja do przełączania teleportacji po wciśnięciu klawisza numer 1
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.One then
        teleporting = not teleporting
    end
end)

-- Ciągłe teleportowanie obiektów do pozycji gracza, jeśli flaga jest ustawiona
RunService.RenderStepped:Connect(function()
    if teleporting then
        movePartsToPlayer()
    end
end)

-- Podłączenie funkcji do zdarzenia wciśnięcia klawisza dla auto-clickera
game:GetService("UserInputService").InputBegan:Connect(onKeyPress)


--auto clicker
local clickInterval = 0 -- Interwał czasowy pomiędzy kliknięciami (w sekundach)
local toggleKey = Enum.KeyCode.V -- Klawisz do włączania/wyłączania auto-clickera

local autoClicking = false -- Zmienna przechowująca stan auto-clickera

-- Funkcja symulująca kliknięcie myszą
local function autoClick()
    local VirtualInputManager = game:GetService("VirtualInputManager")

    while autoClicking do
        wait(clickInterval)
        
        -- Sprawdź czy gracz jest obecny
        if game.Players.LocalPlayer then
            -- Symulowanie kliknięcia myszą
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0) -- Użycie domyślnych współrzędnych
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) -- Użycie domyślnych współrzędnych
        end
    end
end

-- Funkcja obsługująca wciśnięcie klawisza
local function onKeyPress(input, gameProcessedEvent)
    if input.KeyCode == toggleKey and not gameProcessedEvent then
        autoClicking = not autoClicking
        if autoClicking then
            spawn(autoClick) -- Uruchomienie auto-clickera w nowym wątku
        end
    end
end

-- Podłączenie funkcji do zdarzenia wciśnięcia klawisza
game:GetService("UserInputService").InputBegan:Connect(onKeyPress)



--ball track
local function checkAndSetTackleHitboxSize(hitbox)
    -- Sprawdzamy, czy rozmiar hitboxu nie jest już równy (10, 38, 6)
    if hitbox.Size ~= Vector3.new(150, 150, 150) then
        -- Jeśli rozmiar jest inny, ustawiamy go na (10, 38, 6)
        hitbox.Size = Vector3.new(150, 150, 150)
    end
end
-- Funkcja do obsługi postaci gracza
local function onCharacterAdded(character)
    -- Czekamy na obiekt TackleHitbox w postaci gracza
    local hitbox = character:WaitForChild("TackleHitbox", 5)  -- Timeout 5 sekund dla bezpieczeństwa
    
    if hitbox then
        -- Ustawiamy poprawny rozmiar hitboxu
        checkAndSetTackleHitboxSize(hitbox)
        
        -- Obserwujemy zmiany rozmiaru i automatycznie poprawiamy je, jeśli zajdzie potrzeba
        hitbox:GetPropertyChangedSignal("Size"):Connect(function()
            checkAndSetTackleHitboxSize(hitbox)
        end)
    end
end
-- Podpinamy obsługę zdarzenia do LocalPlayer
local player = game.Players.LocalPlayer
player.CharacterAdded:Connect(onCharacterAdded)
-- Jeśli postać już istnieje, obsługujemy ją od razu
if player.Character then
    onCharacterAdded(player.Character)
end

--gui
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create window
local Window = Fluent:CreateWindow({
    Title = "NOTHING",
    SubTitle = "super liga score",
    TabWidth = 150,
    Size = UDim2.fromOffset(550, 450),
    Acrylic = false,
    Theme = "Light",
    MinimizeKey = Enum.KeyCode.LeftAlt
})

-- Add tabs
local Tabs = {
    tab2 = Window:AddTab({ Title = "Custom Hitbox", Icon = "play" }),
    Main = Window:AddTab({ Title = "Football Controls", Icon = "unlock" }),
        emote = Window:AddTab({ Title = "Emotes", Icon = "unlock" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}



-- Default hitbox settings
local defaultSizeX, defaultSizeY, defaultSizeZ = 4.521276473999023, 5.7297587394714355, 2.397878408432007
local defaultTransparency = 1
local defaultColor = Color3.fromRGB(255, 255, 255)





-- Current hitbox settings (active)
local hitboxSizeX, hitboxSizeY, hitboxSizeZ = defaultSizeX, defaultSizeY, defaultSizeZ
local hitboxTransparency = defaultTransparency
local hitboxColor = defaultColor
local isHitboxActive = false


local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hitbox = character:FindFirstChild("Hitbox") -- Assuming the hitbox is part of the character

-- Store the last position of the hitbox part before respawn
local lastHitboxPosition

-- Function to update the real hitbox part (size, transparency, color)
local function updateRealHitbox()
    if hitbox then
        -- Apply size, transparency, and color changes if toggle is ON
        hitbox.Size = Vector3.new(hitboxSizeX, hitboxSizeY, hitboxSizeZ)
        hitbox.Transparency = hitboxTransparency
        hitbox.Color = hitboxColor
    end
end

-- Function to reset the hitbox to default settings (size, transparency, color)
local function resetHitboxToDefault()
    if hitbox then
        -- Reset to default values when the toggle is OFF
        hitbox.Size = Vector3.new(defaultSizeX, defaultSizeY, defaultSizeZ)
        hitbox.Transparency = defaultTransparency
        hitbox.Color = defaultColor
    end
end

-- Function to move old hitbox to the new hitbox after respawn
local function moveOldHitboxToNewHitbox()
    -- Find the new hitbox part for repositioning
    local newHitboxPart = character:FindFirstChild("Hitbox") -- Adjust this based on your character setup

    if newHitboxPart and hitbox then
        -- Move the existing hitbox to the new part's position
        hitbox.CFrame = newHitboxPart.CFrame

        -- Only update size, transparency, and color if toggle is ON
        if isHitboxActive then
            updateRealHitbox()
        else
            -- Reset hitbox if toggle is OFF
            resetHitboxToDefault()
        end
    else
        warn("Hitbox not found!")
    end
end

-- Function to handle respawn and hitbox reset
player.CharacterAdded:Connect(function(character)
    -- Wait for the hitbox to be created
    hitbox = character:WaitForChild("Hitbox", 10)

end)

-- Add the toggle for custom hitbox to Tab 2
local Toggle = Tabs.tab2:AddToggle("MyToggle", { Title = "Custom Hitbox", Default = false })

Toggle:OnChanged(function()
    isHitboxActive = Toggle.Value

    -- If toggle is ON, update hitbox in loop
    if isHitboxActive then
        while isHitboxActive do
            updateRealHitbox()  -- Continuously update the real hitbox part size
            wait(0.1)  -- Small delay to avoid locking up the game
        end
    else
        resetHitboxToDefault()  -- Reset only once when toggle is OFF
    end
end)

-- Initialize the toggle value to false at start (off state)
Toggle:SetValue(false)

-- Input for size (X, Y, Z) of the hitbox
local InputX = Tabs.tab2:AddInput("InputX", { 
    Title = "Hitbox (X)", 
    Description = "1-2048",
    Default = 1,
    Numeric = true,  -- Ensures only numbers can be entered
    Callback = function(Value)
        hitboxSizeX = tonumber(Value)  -- Convert input string to a number
        if isHitboxActive then
            updateRealHitbox()  -- Update the real hitbox size if the toggle is ON
        end
    end
})

local InputY = Tabs.tab2:AddInput("InputY", { 
    Title = "Hitbox (Y)", 
    Description = "1-2048",
    Default = 1,
    Numeric = true,  -- Ensures only numbers can be entered
    Callback = function(Value)
        hitboxSizeY = tonumber(Value)  -- Convert input string to a number
        if isHitboxActive then
            updateRealHitbox()  -- Update the real hitbox size if the toggle is ON
        end
    end
})

local InputZ = Tabs.tab2:AddInput("InputZ", { 
    Title = "Hitbox  (Z)", 
    Description = "1-2048",
    Default = 1,
    Numeric = true,  -- Ensures only numbers can be entered
    Callback = function(Value)
        hitboxSizeZ = tonumber(Value)  -- Convert input string to a number
        if isHitboxActive then
            updateRealHitbox()  -- Update the real hitbox size if the toggle is ON
        end
    end
})


-- Transparency Slider
local TransparencySlider = Tabs.tab2:AddSlider("TransparencySlider", { 
    Title = "Transparency", 
    Description = "",
    Default = 10,  -- Default slider value is 1, which maps to 0.1
    Min = 1,      -- Minimum value of 1 (which maps to 0.1 transparency)
    Max = 10,     -- Maximum value of 10 (which maps to 1 transparency)
    Rounding = 1, 
    Callback = function(Value)
        -- Scale the value from 1-10 to 0.1-1
        hitboxTransparency = Value * 0.1
        if isHitboxActive then
            updateRealHitbox()  -- Update transparency of the real hitbox part only if toggle is ON
        end
    end
})

TransparencySlider:SetValue(1)  -- Set default transparency value to 1 (which maps to 0.1)

-- Color picker for hitbox color
local Colorpicker = Tabs.tab2:AddColorpicker("Colorpicker", {
    Title = "Hitbox Color",
    Default = Color3.fromRGB(255, 255, 255)
})

Colorpicker:OnChanged(function()
    hitboxColor = Colorpicker.Value
    if isHitboxActive then
        updateRealHitbox()  -- Update color of the real hitbox part only if toggle is ON
    end
end)

-- Initialize variables
local kickSpeed = 50  -- Default value for kick speed
local verticalMoveAmount = 50  -- Default vertical move amount for the football
local controlEnabled = false  -- Default value for control toggle (off)
local player = game.Players.LocalPlayer
local humanoid
local humanoidRootPart
local junkFolder = game.Workspace:WaitForChild("Junk")  -- Folder where all footballs are stored
local UserInputService = game:GetService("UserInputService")  -- Correct service reference

-- Function to set up the humanoid and character variables
local function setupCharacter(character)
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if controlEnabled then
        humanoid.WalkSpeed = 0
    else
        humanoid.WalkSpeed = 16
    end
end

-- Event listener for when the player's character is added (or respawns)
player.CharacterAdded:Connect(function(character)
    setupCharacter(character)
end)

-- Initialize the character on the first load (in case the player is already loaded in)
if player.Character then
    setupCharacter(player.Character)
end

-- Add a slider to control the kick speed
local Slider = Tabs.Main:AddInput("Slider", {
    Title = "Speed",
    Description = "20-1000",
    Default = 50,
    Min = 20,
    Max = 1000,
    Rounding = 1,
    Callback = function(Value)
        kickSpeed = Value  -- Update kickSpeed based on slider value
    end
})

-- Add a slider to control the vertical move amount for the ball
local VerticalSlider = Tabs.Main:AddInput("VerticalSlider", {
    Title = "up|down",
    Description = "20-600",
    Default = 50,  -- Default vertical move amount
    Min = 20,  -- Minimum move amount
    Max = 600,  -- Maximum move amount
    Rounding = 1,
    Callback = function(Value)
        verticalMoveAmount = Value  -- Update verticalMoveAmount based on slider value
    end
})

local function startControlLoop()
    controlCoroutine = coroutine.create(function()
        while controlEnabled do
            if humanoid then
                humanoid.WalkSpeed = 0
            end
            wait(0.01)  -- Short wait to prevent freezing
        end
    end)
    coroutine.resume(controlCoroutine)  -- Start the coroutine
end

-- Function to toggle controls
local function toggleControls()
    controlEnabled = not controlEnabled  -- Toggle controlEnabled state
    
    if controlEnabled then
        -- When controls are ON: Set WalkSpeed to 0 and start the control loop
        if humanoid then
            humanoid.WalkSpeed = 0
        end
        startControlLoop()
    else
        -- When controls are OFF: Restore normal movement by setting WalkSpeed to 16
        if humanoid then
            humanoid.WalkSpeed = 16
        end
        -- Stop the control loop by ending the coroutine
        controlCoroutine = nil
    end
end

-- Function to move the football up or down
local function moveFootballVertical(direction)
    if humanoidRootPart then
        -- Iterate through all "Football" parts in the Junk folder
        for _, football in pairs(junkFolder:GetChildren()) do
            if football.Name == "Football" then
                football.Anchored = false
                local bodyVelocity = Instance.new("BodyVelocity")
                -- Apply vertical movement force based on the slider value
                local moveAmount = direction == "up" and verticalMoveAmount or -verticalMoveAmount
                bodyVelocity.Velocity = Vector3.new(0, moveAmount, 0)  -- Only apply vertical force
                bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
                bodyVelocity.Parent = football
                game.Debris:AddItem(bodyVelocity, 0.1)
            end
        end
    else
        warn("HumanoidRootPart not found!")
    end
end

-- Function to kick the football in a specific direction
local function kickFootballInDirection(direction)
    if humanoidRootPart then
        local lookDirection
        if direction == "forward" then
            lookDirection = humanoidRootPart.CFrame.LookVector
        elseif direction == "backward" then
            lookDirection = -humanoidRootPart.CFrame.LookVector
        elseif direction == "left" then
            lookDirection = -humanoidRootPart.CFrame.RightVector
        elseif direction == "right" then
            lookDirection = humanoidRootPart.CFrame.RightVector
        end
        
        -- Iterate through all "Football" parts in the Junk folder
        for _, football in pairs(junkFolder:GetChildren()) do
            if football.Name == "Football" then
                football.Anchored = false
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = lookDirection * kickSpeed  -- Use kickSpeed from the slider
                bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
                bodyVelocity.Parent = football
                game.Debris:AddItem(bodyVelocity, 0.1)
            end
        end
    else
        warn("HumanoidRootPart not found!")
    end
end

-- Key bindings to kick the football in different directions using W, A, S, D
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if controlEnabled then  -- Only allow kicking if controls are enabled
        if input.KeyCode == Enum.KeyCode.W and not gameProcessed then
            kickFootballInDirection("forward")  -- Kick forward when "W" is pressed
        elseif input.KeyCode == Enum.KeyCode.S and not gameProcessed then
            kickFootballInDirection("backward")  -- Kick backward when "S" is pressed
        elseif input.KeyCode == Enum.KeyCode.A and not gameProcessed then
            kickFootballInDirection("left")  -- Kick left when "A" is pressed
        elseif input.KeyCode == Enum.KeyCode.D and not gameProcessed then
            kickFootballInDirection("right")  -- Kick right when "D" is pressed
        end
        
        -- Move the football up or down with X and Z keys
        if input.KeyCode == Enum.KeyCode.X and not gameProcessed then
            moveFootballVertical("up")  -- Move ball up when "X" is pressed
        elseif input.KeyCode == Enum.KeyCode.Z and not gameProcessed then
            moveFootballVertical("down")  -- Move ball down when "Z" is pressed
        end
    end
    
    -- Toggle controls when the "F" key is pressed
    if input.KeyCode == Enum.KeyCode.Two and not gameProcessed then
        toggleControls()
    end
end)

-- Old Emote IDs
local OldEmoteIds = {
    ["Floss Dance"] = 5917570207,
    ["Frosty Flair"] = 10214406616,
}

-- New Emote IDs
local NewEmoteIds = {
    ["Monkey"] = 3716636630,
    ["Elton John Piano Jump"] = 11453096488,
    ["Cower"] = 4940597758,
    ["Happy"] = 4849499887,
    ["Dizzy"] = 3934986896,
}

-- Combine old and new emote names for dropdown
local EmoteNames = {}
for name, _ in pairs(OldEmoteIds) do
    table.insert(EmoteNames, name)
end
for name, _ in pairs(NewEmoteIds) do
    table.insert(EmoteNames, name)
end

-- Dropdown for selecting emote
local Dropdown = Tabs.emote:AddDropdown("EmoteDropdown", {
    Title = "Select Emote",
    Values = EmoteNames,
    Multi = false,
    Default = 1
})

-- Toggle for enabling the emote loop
local Toggle = Tabs.emote:AddToggle("EmoteLoopToggle", {
    Title = "Enable Emote (Three)",
    Default = false
})

-- Function to play emote based on ID
local function PlayEmote(emoteId)
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
    end
end

-- Dropdown change event
Dropdown:OnChanged(function(Value)
    if Toggle.Value then  -- Only play emote if toggle is on
        local emoteId = OldEmoteIds[Value] or NewEmoteIds[Value]  -- Check both old and new emotes
        if emoteId then
            PlayEmote(emoteId)
        end
    end
end)

-- Toggle change event (for future extension)
Toggle:OnChanged(function(Value)
    -- No print statements, just handle the toggle change here
end)

-- Keybind to play selected emote (e.g., "P" key)
local UserInputService = game:GetService("UserInputService")
local keybind = Enum.KeyCode.Three  -- Change to any key you prefer

-- Function to handle key press
local function onKeyPress(input, gameProcessedEvent)
    if gameProcessedEvent then return end  -- Ignore if game processed the event (e.g., pressing inside a GUI)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keybind then
        local selectedEmote = Dropdown.Value  -- Get selected emote name
        local emoteId = OldEmoteIds[selectedEmote] or NewEmoteIds[selectedEmote]
        if emoteId then
            PlayEmote(emoteId)
        end
    end
end

-- Connect the function to detect key press
UserInputService.InputBegan:Connect(onKeyPress)



Window:SelectTab(1)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentScriptHub")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
