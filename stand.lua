local ownerUsername = "notephishing" -- The owner's username
local autosavedUsers = {}
local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
local targetCFrame = CFrame.new(583.931641, 51.061409, -476.954193, -0.999745369, 1.49123665e-08, -0.0225663595, 1.44838328e-08, 1, 1.91533687e-08, 0.0225663595, 1.88216429e-08, -0.999745369)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Flag to track grabbing status
local isGrabbing = false

-- Function to find a player by a partial match of username or display name
local function findPlayerByName(name)
    for _, player in pairs(Players:GetPlayers()) do
        if string.sub(player.DisplayName:lower(), 1, #name) == name:lower() or 
           string.sub(player.Name:lower(), 1, #name) == name:lower() then
            return player
        end
    end
    return nil
end

-- Function to handle grabbing simulation
local function grabPlayer(target)
    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    
    -- Ensure the script only starts grabbing if it is not already in progress
    if isGrabbing then
        print("Already grabbing. Exiting function.")
        return
    end
    
    isGrabbing = true
    print("Starting to grab player " .. target .. ".")

    while isGrabbing do
        wait()

        if game.Players[target].Character.BodyEffects['K.O'].Value and 
           not game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") and 
           not game.Players[target].Character.BodyEffects['Dead'].Value then

            -- Move to target and perform grabbing
            local targetChar = game.Players[target].Character
            local targetPosition = targetChar.UpperTorso.Position + Vector3.new(0, 3, 0)

            localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
            print("Moved local player to target position: " .. tostring(targetPosition))

            -- Start grabbing
            local grabString = "Grabbing"
            local grabBoolean = false
            ReplicatedStorage.MainEvent:FireServer(grabString, grabBoolean)
            print("Grabbing action fired to server.")
            
            -- Check if grabbing constraint is applied
            if game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") then
                print("Player " .. target .. " has been successfully grabbed.")
                
                -- Move local player to target CFrame immediately after grabbing
                localChar:SetPrimaryPartCFrame(targetCFrame)
                print("Local player moved to target CFrame.")
                
                -- Wait until the local player is close to the targetCFrame
                while (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude > 2 do
                    wait()
                end
                
                -- Check if the local player is at the targetCFrame
                if (localChar.PrimaryPart.CFrame.Position - targetCFrame.Position).magnitude < 0.1 then
                    -- Wait 2 seconds before stopping the grabbing action
                    wait(1)
                    
                    -- Stop grabbing action
                    local stopString = "Grabbing"
                    local stopBoolean = true
                    ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)
                    print("Grabbing action stopped.")
                    
                    -- Wait an additional 1 second to ensure the stopping action is processed
                    wait(1)
                    
                    -- Move local player to safezone after waiting
                    localChar:SetPrimaryPartCFrame(safezoneCFrame)
                    print("Local player moved to safezone CFrame.")
                    
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

    -- Monitor the health of the target user
    user.Character:WaitForChild("Humanoid").HealthChanged:Connect(function(health)
        if health <= 1 then
            print("User " .. user.Name .. " health is low. Initiating grab process.")

            local userChar = user.Character or user.CharacterAdded:Wait()

            -- Perform grabbing simulation
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
