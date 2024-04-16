local Library = loadstring(game:HttpGet("https://pastebin.com/raw/vff1bQ9F"))()
local UserInputService = game:GetService("UserInputService")

local Window = Library.CreateLib("Murderer Vs Sheriff Duels", Synapse)

-- Tabs and sections
local Tab1 = Window:NewTab("Hitbox Tab")
local Tab1Section = Tab1:NewSection("Hitbox Misc")

local Tab2 = Window:NewTab("ESP Tab")
local Tab2Section = Tab2:NewSection("ESP Misc")

local Tab3 = Window:NewTab("Fun Tab")
local Tab3Section = Tab3:NewSection("Fun Misc")

local Tab4 = Window:NewTab("Hardcore Tab")
local Tab4Section = Tab4:NewSection("Hardcore Misc")

local Tab5 = Window:NewTab("Credits")
local Tab5Section = Tab5:NewSection("Discord/Made By: FedPal")
Tab5:NewSection("Roblox Byfron Bypass")


-- Hitbox Size Slider
Tab1Section:NewSlider("Hitbox Size", "Adjust the hitbox size from 1 to 20", 20, 1, function(size)
    _G.HeadSize = math.floor(size + 1)  -- Round the size to the nearest integer
    applyHitboxSettings()  -- Apply the Hitbox settings
end)

-- Default hitbox transparency
_G.Transparency = 1.0  -- Set default hitbox transparency to 1.0 (or 100%)

-- Hitbox Transparency Slider
Tab1Section:NewSlider("Transparency", "Adjust the hitbox transparency from 0.01 to 1", 100, 1, function(value)
    local transparencyValue = math.floor(value + 1) / 100  -- Round the value to the nearest integer
    _G.Transparency = transparencyValue == 1.0 and 1.0 or transparencyValue  -- Set transparency value
    applyHitboxSettings()  -- Apply the Hitbox settings
end)

-- Hitbox Color Picker
Tab1Section:NewColorPicker("Hitbox Color", "Change the hitbox color", Color3.fromRGB(255, 255, 255), function(color)
    _G.HitboxColor = color
    applyHitboxColor()  -- Apply the new color in real-time
    applyHitboxSettings()  -- Apply the Hitbox settings
end)

-- Function to apply the Hitbox Color in real-time
function applyHitboxColor()
    if not _G.Disabled then
        for _, player in ipairs(game:GetService('Players'):GetPlayers()) do
            if player.Name ~= game:GetService('Players').LocalPlayer.Name then
                pcall(function()
                    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        humanoidRootPart.BrickColor = BrickColor.new(_G.HitboxColor)
                    end
                end)
            end
        end
    end
end

-- Function to apply Hitbox settings in real-time
function applyHitboxSettings()
    if not _G.Disabled then
        for _, player in ipairs(game:GetService('Players'):GetPlayers()) do
            if player.Name ~= game:GetService('Players').LocalPlayer.Name then
                pcall(function()
                    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart and humanoidRootPart:IsDescendantOf(game.Workspace) then
                        humanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                        humanoidRootPart.Transparency = _G.Transparency
                        humanoidRootPart.Material = Enum.Material.Neon
                        humanoidRootPart.CanCollide = false
                    end
                end)
            end
        end
    end
end

-- Define the default color for ESP highlights
local DefaultColor = Color3.fromRGB(0, 255, 0) -- Green for all players

-- ESP Highlight Toggle Button
local espConnections = {}  -- Table to store connections for each player

Tab2Section:NewToggle("Esp Highlight", "Toggle ESP highlight On/Off", function(state)
    espEnabled = state  -- Update the state of the toggle
    
    if not espEnabled then
        -- Disable ESP highlight by disconnecting all connections and destroying the folder containing highlights
        for _, connection in ipairs(espConnections) do
            connection:Disconnect()
        end
        espConnections = {}  -- Clear the connections table
        local highlightStorage = game:GetService("CoreGui"):FindFirstChild("Highlight_Storage")
        if highlightStorage then
            highlightStorage:Destroy()
        end
    else
        -- Enable ESP highlight
        local DepthMode = "AlwaysOnTop"
        local FillTransparency = 0.5
        local OutlineColor = Color3.fromRGB(255, 255, 255)
        local OutlineTransparency = 0

        local CoreGui = game:FindService("CoreGui")
        local Players = game:FindService("Players")
        local lp = Players.LocalPlayer

        local Storage = Instance.new("Folder")
        Storage.Parent = CoreGui
        Storage.Name = "Highlight_Storage"

        local function Highlight(plr)
            local Highlight = Instance.new("Highlight")
            Highlight.Name = plr.Name
            Highlight.FillColor = DefaultColor  -- Set color to green for all players
            Highlight.DepthMode = DepthMode
            Highlight.FillTransparency = FillTransparency
            Highlight.OutlineColor = OutlineColor
            Highlight.OutlineTransparency = 0
            Highlight.Parent = Storage

            local plrchar = plr.Character
            if plrchar then
                Highlight.Adornee = plrchar
            end

            -- Store the connection in espConnections table
            espConnections[plr] = plr.CharacterAdded:Connect(function(char)
                Highlight.Adornee = char
            end)
        end

        -- Connect player added event to create ESP
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then
                Highlight(player)
            end
        end

        -- Create ESP for new players only when ESP highlight toggle is on
        Players.PlayerAdded:Connect(function(player)
            if espEnabled then  -- Check if the ESP highlight toggle is on
                if player ~= lp then
                    Highlight(player)
                end
            end
        end)

        -- Connect player removing event to remove ESP and disconnect connection
        Players.PlayerRemoving:Connect(function(plr)
            local plrname = plr.Name
            if Storage[plrname] then
                Storage[plrname]:Destroy()
            end
            if espConnections[plr] then
                espConnections[plr]:Disconnect()
                espConnections[plr] = nil
            end
        end)
    end
end)

-- Variable to store the state of ESP name toggle
local espNameEnabled = false

-- Function to apply ESP name settings
function applyESPNameSettings()
    if not _G.Disabled then
        for _, player in ipairs(game:GetService('Players'):GetPlayers()) do
            if player.Name ~= game:GetService('Players').LocalPlayer.Name then
                pcall(function()
                    local nameLabel = game:GetService("CoreGui"):FindFirstChild("NameLabel_Storage"):FindFirstChild(player.Name .. "_NameLabel")
                    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if nameLabel and humanoidRootPart and humanoidRootPart:IsDescendantOf(game.Workspace) then
                        nameLabel.Enabled = true
                    end
                end)
            end
        end
    end
end

-- Function to disable ESP names for players outside the workspace
function disableESPName()
    local nameLabelStorage = game:GetService("CoreGui"):FindFirstChild("NameLabel_Storage")
    if nameLabelStorage then
        for _, nameLabel in ipairs(nameLabelStorage:GetChildren()) do
            if nameLabel:IsA("BillboardGui") then
                nameLabel.Enabled = false
            end
        end
    end
end

-- ESP Name Toggle Button
Tab2Section:NewToggle("Esp Name", "Toggle ESP name On/Off", function(state)
    espNameEnabled = state  -- Update the state of the toggle
    if not espNameEnabled then
        -- Disable ESP name by destroying the folder containing labels
        local nameLabelStorage = game:GetService("CoreGui"):FindFirstChild("NameLabel_Storage")
        if nameLabelStorage then
            nameLabelStorage:Destroy()
        end
    else
        -- Enable ESP name
        local CoreGui = game:FindService("CoreGui")
        local Players = game:FindService("Players")
        local lp = Players.LocalPlayer

        local NameLabelStorage = Instance.new("Folder")
        NameLabelStorage.Parent = CoreGui
        NameLabelStorage.Name = "NameLabel_Storage"

        local function CreateNameLabel(plr)
            local nameLabel = Instance.new("BillboardGui")
            nameLabel.Name = plr.Name .. "_NameLabel"
            nameLabel.AlwaysOnTop = true
            nameLabel.Size = UDim2.new(0, 100, 0, 20)
            nameLabel.StudsOffset = Vector3.new(0, 3, 0) -- Adjust the vertical offset as needed
            nameLabel.Adornee = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            nameLabel.Parent = NameLabelStorage

            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "Name"
            textLabel.Text = plr.Name
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.Font = Enum.Font.SourceSans
            textLabel.TextSize = 14
            textLabel.TextColor3 = Color3.new(1, 1, 1)
            textLabel.BackgroundTransparency = 1
            textLabel.Parent = nameLabel

            local function UpdateNameLabel()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    nameLabel.Adornee = plr.Character.HumanoidRootPart
                    nameLabel.Enabled = true
                else
                    nameLabel.Enabled = false
                end
            end

            -- Update name label position
            UpdateNameLabel()

            -- Connect character added/removed events to update label
            local characterAddedConn = plr.CharacterAdded:Connect(function()
                UpdateNameLabel()
            end)
            local characterRemovedConn = plr.CharacterRemoving:Connect(function()
                nameLabel:Destroy()
                characterAddedConn:Disconnect()
                characterRemovedConn:Disconnect()
            end)
        end

        -- Create labels for existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= lp then
                CreateNameLabel(player)
            end
        end

        -- Connect player added event to create label
        Players.PlayerAdded:Connect(function(player)
            if player ~= lp then
                CreateNameLabel(player)
            end
        end)

        -- Connect player removed event to destroy label
        Players.PlayerRemoving:Connect(function(player)
            local nameLabel = NameLabelStorage:FindFirstChild(player.Name .. "_NameLabel")
            if nameLabel then
                nameLabel:Destroy()
            end
        end)
    end
end)

local IncreaseSpeedEnabled = false

Tab3Section:NewToggle("Speed", "Increase speed", function(state)
    IncreaseSpeedEnabled = state  -- Update the state of the toggle

    function isNumber(str)
        return tonumber(str) ~= nil or str == 'inf'
    end

    local tspeed = 1
    local hb = game:GetService("RunService").Heartbeat
    local tpwalking = true
    local player = game:GetService("Players")
    local lplr = player.LocalPlayer
    local chr = lplr.Character
    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    
    -- Check if the speed increase is enabled
    while IncreaseSpeedEnabled and tpwalking and hb:Wait() and chr and hum and hum.Parent do
        if hum.MoveDirection.Magnitude > 0 then
            if tspeed and isNumber(tspeed) then
                chr:TranslateBy(hum.MoveDirection * tonumber(tspeed))
            else
                chr:TranslateBy(hum.MoveDirection)
            end
        end
    end
end)

-- Variable to store the state of Infinite Jumps toggle
local infiniteJumpEnabled = false

-- Connect the JumpRequest event
game:GetService("UserInputService").JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Infinite Jumps Toggle
Tab3Section:NewToggle("Infinite Jumps", "Toggle Infinite Jumps On/Off", function(state)
    infiniteJumpEnabled = state  -- Update the state of the toggle
end)

-- Function to teleport the local character to a specified stand
local function teleportToStand()
    local stand = workspace.Lobby.ClassicStands:GetChildren()[2].Stand
    if stand then
        local ring = stand:FindFirstChild("Ring")
        if ring then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    humanoidRootPart.CFrame = CFrame.new(ring.Position + Vector3.new(0, 3, 0)) -- Adjust the teleportation offset as needed
                else
                    print("HumanoidRootPart not found in character.")
                end
            else
                print("Character not found.")
            end
        else
            print("Ring not found in Stand.")
        end
    else
        print("Stand not found in ClassicStands.")
    end
end


-- Create a button in the GUI to teleport to the stand
Tab3Section:NewButton("Teleport to 1v1", "Teleport your character to the stand", function()
    teleportToStand()
end)

-- Function to teleport to a player
local function teleportToPlayer(player)
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            game:GetService("Players").LocalPlayer.Character:SetPrimaryPartCFrame(humanoidRootPart.CFrame)
        end
    end
end

-- Dropdown to select a player to teleport to
local playerNames = {}  -- Table to store player names
for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    table.insert(playerNames, player.Name)
end

local Dropdown = Tab3Section:NewDropdown("Select Player", "Choose a player to teleport to", playerNames, function(currentOption)
    local selectedPlayer = game:GetService("Players"):FindFirstChild(currentOption)
    if selectedPlayer then
        teleportToPlayer(selectedPlayer)
    end
end)

-- Function to equip the second tool found in the player's backpack and reset its cooldown
local function equipSecondTool()
    local player = game:GetService("Players").LocalPlayer
    local backpack = player.Backpack
    if backpack then
        local tools = backpack:GetChildren()
        if #tools >= 2 then
            -- Move the second tool to the player's character
            local tool = tools[2]
            tool.Parent = player.Character or player
            -- Reset the cooldown of the tool
            if tool:FindFirstChild("Cooldown") then
                tool.Cooldown.Value = 0
            end
        else
            print("There are not enough tools in the backpack.")
        end
    else
        print("Backpack not found.")
    end
end

-- Create a button in the GUI to equip the second tool in the backpack and reset its cooldown
Tab4Section:NewButton("Equip Second Tool", "Equip the second tool found in your backpack and reset its cooldown", function()
    equipSecondTool()
end)

-- Function to toggle the UI
local function toggleUI()
    Library:ToggleUI()
end

-- Listen for keypress event to toggle the UI
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightAlt then -- Change F to the desired key
        toggleUI()
    end
end)

-- Function to reset the cooldown attribute of the held tool to 0
local function resetCooldown()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool") -- Find the tool currently equipped
        if tool then
            local currentCooldown = tool:GetAttribute("Cooldown") or 0 -- Retrieve current cooldown or default to 0
            tool:SetAttribute("Cooldown", 0)  -- Set the "Cooldown" attribute to 0 (a number)
            print("Cooldown of " .. tool.Name .. " reset from " .. currentCooldown .. " to 0.")
        else
            print("No tool equipped.")
        end
    else
        print("Character not found.")
    end
end

-- Function to continuously reset the cooldown attribute of the held tool to 0
local function continuousCooldownReset()
    while cooldownResetEnabled do
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool") -- Find the tool currently equipped
            if not tool then
                resetCooldown() -- Call the function to reset the cooldown if the tool is not equipped
            end
        end
        wait(1) -- Wait for a brief interval before checking again
    end
end

-- Toggle to enable/disable continuous cooldown reset
local cooldownResetEnabled = false
local ToggleCooldownReset = Tab4Section:NewToggle("Toggle Cooldown Reset", "Toggle continuous cooldown reset On/Off", function(state)
    cooldownResetEnabled = state  -- Update the state of the toggle
    if cooldownResetEnabled then
        -- Start the continuous reset process in a coroutine
        coroutine.wrap(continuousCooldownReset)()
    end
end)

-- Call the function to reset the cooldown when the toggle is turned on
ToggleCooldownReset:SetOn(true)
resetCooldown()


-- Keep applying Hitbox and ESP settings
while true do
    if not _G.Disabled then
        applyHitboxSettings()
        applyHitboxColor()

        -- Check if ESP name toggle is enabled
        if espNameEnabled then
            -- Apply ESP name settings
            applyESPNameSettings()
        else
            -- Disable ESP name by destroying the folder containing labels
            local nameLabelStorage = game:GetService("CoreGui"):FindFirstChild("NameLabel_Storage")
            if nameLabelStorage then
                nameLabelStorage:Destroy()
            end
        end

        -- Check if ESP highlight toggle is enabled
        if espEnabled then
            -- Apply ESP highlight settings
            for _, player in ipairs(game:GetService('Players'):GetPlayers()) do
                if player.Name ~= game:GetService('Players').LocalPlayer.Name then
                    pcall(function()
                        local highlightStorage = game:GetService("CoreGui"):FindFirstChild("Highlight_Storage")
                        if not highlightStorage then
                            Highlight(player)
                        end
                    end)
                end
            end
        else
            -- Disable ESP highlight by disconnecting all connections and destroying the folder containing highlights
            for _, connection in ipairs(espConnections) do
                connection:Disconnect()
            end
            espConnections = {}  -- Clear the connections table
            local highlightStorage = game:GetService("CoreGui"):FindFirstChild("Highlight_Storage")
            if highlightStorage then
                highlightStorage:Destroy()
            end
        end
    end
    wait() -- Wait for a short duration to prevent excessive CPU usage
end
