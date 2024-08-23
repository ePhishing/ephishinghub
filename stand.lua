local ownerUsername = "notephishing" -- The owner's username
local autosavedUsers = {}
local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
local targetCFrame = CFrame.new(583.931641, 51.061409, -476.954193, -0.999745369, 1.49123665e-08, -0.0225663595, 1.44838328e-08, 1, 1.91533687e-08, 0.0225663595, 1.88216429e-08, -0.999745369)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Flag to track grabbing status
local isGrabbing = false

-- Initialize BlockAura flag
local BlockAura = true
local BlockAuraReal = false

-- Function to handle auto block
local function autoBlock()
    if BlockAura then
        BlockAuraReal = true
        
        while BlockAuraReal do
            wait()
            
            local MainEvent = ReplicatedStorage:WaitForChild('MainEvent')
            local Distance = 15
            
            local forbidden = {'[Popcorn]','[HotDog]','[GrenadeLauncher]','[RPG]','[SMG]','[TacticalShotgun]','[AK47]','[AUG]','[Glock]', '[Shotgun]','[Flamethrower]','[Silencer]','[AR]','[Revolver]','[SilencerAR]','[LMG]','[P90]','[DrumGun]','[Double-Barrel SG]','[Hamburger]','[Chicken]','[Pizza]','[Cranberry]','[Donut]','[Taco]','[Starblox Latte]','[BrownBag]','[Weights]','[HeavyWeights]'}
            local Found = false
            for _, v in pairs(Workspace.Players:GetChildren()) do
                local upperTorso = v:FindFirstChild('UpperTorso')
                if upperTorso and (upperTorso.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= Distance then
                    local tool = v:FindFirstChildWhichIsA('Tool')
                    if v.BodyEffects.Attacking.Value and (not tool or not table.find(forbidden, tool.Name)) and v.Name ~= Players.LocalPlayer.Name then
                        Found = true
                        MainEvent:FireServer('Block', Players.LocalPlayer.Name)
                    end
                end
            end
            
            if not Found then
                local blockEffect = Players.LocalPlayer.Character.BodyEffects:FindFirstChild('Block')
                if blockEffect then
                    blockEffect:Destroy()
                end
            end
        end
    else
        BlockAuraReal = false
    end
end

-- Call autoBlock function to start it
autoBlock()

-- Function to find a player by a partial match of username or display name
local function findPlayerByName(name)
    local lowerName = name:lower()
    for _, player in pairs(Players:GetPlayers()) do
        local displayName = player.DisplayName:lower()
        local username = player.Name:lower()

        -- Check if the search term is a prefix of either display name or username
        if displayName:find(lowerName, 1, true) == 1 or username:find(lowerName, 1, true) == 1 then
            return player
        end
    end
    return nil
end


-- Function to handle grabbing simulation
local function grabPlayer(target)
    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    
    if isGrabbing then
        return
    end
    
    isGrabbing = true

    while isGrabbing do
        wait()

        local targetPlayer = Players:FindFirstChild(target)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character.BodyEffects['K.O'].Value and 
           not Workspace.Players:FindFirstChild(target):FindFirstChild("GRABBING_CONSTRAINT") and 
           not targetPlayer.Character.BodyEffects['Dead'].Value then

            -- Move to target and perform grabbing
            local targetChar = targetPlayer.Character
            local targetPosition = targetChar:FindFirstChild('UpperTorso').Position + Vector3.new(0, 3, 0)

            localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)

            -- Start grabbing
            ReplicatedStorage.MainEvent:FireServer("Grabbing", false)
            
            -- Check if grabbing constraint is applied
            if Workspace.Players:FindFirstChild(target):FindFirstChild("GRABBING_CONSTRAINT") then

                localChar:SetPrimaryPartCFrame(targetCFrame)

                while (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude > 2 do
                    wait()
                end
                
                -- Check if the local player is at the targetCFrame
                if (localChar.PrimaryPart.CFrame.Position - targetCFrame.Position).magnitude < 0.1 then
                    ReplicatedStorage.MainEvent:FireServer("Grabbing", true)
                    wait(1)
                
                    localChar:SetPrimaryPartCFrame(safezoneCFrame)
                    
                    isGrabbing = false
                    break
                end
            end
        end
    end
end

-- Function to handle autosave logic
local function autosave(user)
    if not table.find(autosavedUsers, user.Name) then
        table.insert(autosavedUsers, user.Name)
        print("User " .. user.Name .. " added to autosave list.")
    end

    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()

    user.Character:WaitForChild("Humanoid").HealthChanged:Connect(function(health)
        if health <= 1 then
            local userChar = user.Character or user.CharacterAdded:Wait()
            grabPlayer(user.Name)
        end
    end)
end

-- Function to remove all autosaved users
local function removeAutosaves()
    autosavedUsers = {}
end

-- Function to handle chat messages
local function onChatted(player, message)
    if player.Name ~= ownerUsername then return end

    if string.sub(message, 1, 6) == ".chat " then
        local msgToSay = string.sub(message, 7)
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msgToSay, "All")
    end

    if string.sub(message, 1, 7) == ".rejoin" then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
    end

    if string.sub(message, 1, 10) == ".autosave " then
        local username = string.sub(message, 11)
        local user = findPlayerByName(username)
        if user then
            autosave(user)
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Autosave masters activated.", "All")
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Invalid username", "All")
        end
    end

    if string.sub(message, 1, 7) == ".remove" then
        removeAutosaves()
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("All autosaves removed.", "All")
    end
end

-- Connect the function to the player's chat event
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onChatted(player, message)
    end)
end)

-- Ensure that the script also works for players already in the game
for _, player in pairs(Players:GetPlayers()) do
    player.Chatted:Connect(function(message)
        onChatted(player, message)
    end)
end
