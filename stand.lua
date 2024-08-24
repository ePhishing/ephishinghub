return function(ownerUsername)
    local autosavedUsers = {}
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
    local targetCFrame = CFrame.new(-437.125885, 38.9783134, -285.587372, 0.0165725499, 5.298579e-08, -0.99986279, 1.16139711e-08, 1, 5.31855591e-08, 0.99986279, -1.24937944e-08, 0.0165725499)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    
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

        -- Start grabbing process
        while true do
            wait()

            if game.Players[target].Character.BodyEffects['K.O'].Value and 
            not game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") and 
            not game.Players[target].Character.BodyEffects['Dead'].Value then

                -- Move to target and perform grabbing
                local targetChar = game.Players[target].Character
                local targetPosition = targetChar.UpperTorso.Position + Vector3.new(0, 3, 0)

                localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                wait(0.1)

                -- Start grabbing
                local grabString = "Grabbing"
                local grabBoolean = false
                ReplicatedStorage.MainEvent:FireServer(grabString, grabBoolean)
                wait(0.2)

                -- Check if grabbing constraint is applied
                if game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") then

                    -- Move local player to target CFrame immediately after grabbing
                    localChar:SetPrimaryPartCFrame(targetCFrame)

                    -- Wait until the local player is close to the targetCFrame
                    while (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude > 2 do
                        wait()
                    end

                    -- Check if the local player is at the targetCFrame
                    if (localChar.PrimaryPart.CFrame.Position - targetCFrame.Position).magnitude < 0.1 then
                        wait(1)

                        -- Stop grabbing action
                        local stopString = "Grabbing"
                        local stopBoolean = true
                        ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)

                        -- Wait an additional 1 second to ensure the stopping action is processed
                        wait(1)

                        -- Move local player to safezone after waiting
                        localChar:SetPrimaryPartCFrame(safezoneCFrame)
                    end
                end
            end
        end
    end

    -- Function to handle autosave logic
    local function autosave(user)
        if not table.find(autosavedUsers, user.Name) then
            table.insert(autosavedUsers, user.Name)
        end

        while true do
            wait(1) -- Check status every second

            local userChar = user.Character
            if userChar and userChar:FindFirstChild("BodyEffects") then
                local bodyEffects = userChar.BodyEffects
                if bodyEffects['K.O'] and bodyEffects['K.O'].Value and 
                not Workspace.Players:WaitForChild(user.Name):FindFirstChild("GRABBING_CONSTRAINT") and 
                bodyEffects['Dead'] and not bodyEffects['Dead'].Value then

                    grabPlayer(user.Name)
                end
            end
        end
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
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Autosave masters activated.", "All")
                autosave(user)
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
end
