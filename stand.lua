return function(ownerUsername)
    -- local ownerUsername = "notephishing" -- The owner's username
    local autosavedUsers = {}
    local activeAutosaveThreads = {}
    local activeAutostompThread = nil
    local isGrabbing = false
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
    local targetCFrame = CFrame.new(-451.999084, 80.4387283, -207.518799, 0.7223894, 0, -0.69, 0, 1 ,0 , 0.691, 0, 0.72)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()

    localChar:SetPrimaryPartCFrame(safezoneCFrame)

    local function findPlayerByName(name)
        for _, player in pairs(Players:GetPlayers()) do
            if string.sub(player.DisplayName:lower(), 1, #name) == name:lower() or 
            string.sub(player.Name:lower(), 1, #name) == name:lower() then
                return player
            end
        end
        return nil
    end

    local function grabPlayer(target)
        local localPlayer = Players.LocalPlayer
        local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    
        if isGrabbing then
            return
        end
    
        isGrabbing = true
    
        while isGrabbing do
            wait()
    
            if game.Players[target].Character.BodyEffects['K.O'].Value and 
            not game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") and 
            not game.Players[target].Character.BodyEffects['Dead'].Value then
    
                local targetChar = game.Players[target].Character
                local targetPosition = targetChar.UpperTorso.Position + Vector3.new(0, 3, 0)
                
                -- Check if the local player is within 10 studs of the targetCFrame
                local distanceToTarget = (targetPosition - targetCFrame.Position).magnitude
                if distanceToTarget <= 10 then
                    isGrabbing = false
                    break
                end
    
                localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                wait(0.1)
    
                local grabString = "Grabbing"
                local grabBoolean = false
                ReplicatedStorage.MainEvent:FireServer(grabString, grabBoolean)
                wait(0.2)
                
                if game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") then
                    
                    -- Move to the target CFrame
                    localChar:SetPrimaryPartCFrame(targetCFrame)
    
                    while (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude > 2 do
                        wait()
                    end
    
                    if (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude <= 3 then
                        wait(0.85)
    
                        local stopString = "Grabbing"
                        local stopBoolean = true
                        ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)
                        
                        wait(0.25)
                        
                        localChar:SetPrimaryPartCFrame(safezoneCFrame)
                        
                        isGrabbing = false
                        break
                    end
                end
            end
        end
    end

    local function autoStomp(user)
        local userChar = user.Character
        if not userChar or not userChar:FindFirstChild("BodyEffects") then return end

        local bodyEffects = userChar.BodyEffects
        local targetPosition = userChar:FindFirstChild("UpperTorso").Position + Vector3.new(0, 3, 0)
        
        while true do
            wait(1)

            -- If the target is not in the correct state, or is dead, stop the auto-stomp
            if not (bodyEffects['K.O'] and bodyEffects['K.O'].Value and 
                not userChar:FindFirstChild("GRABBING_CONSTRAINT") and 
                bodyEffects['Dead'] and not bodyEffects['Dead'].Value) then
                break
            end

            -- Check local player health
            if localChar:FindFirstChildOfClass("Humanoid") and localChar.Humanoid.Health <= 99 then
                -- Move to safezone if health is 99 or below
                localChar:SetPrimaryPartCFrame(safezoneCFrame)
                wait(2) -- Wait for a bit before going back
                localChar:SetPrimaryPartCFrame(targetCFrame)
            end

            -- Move to the target's position
            localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
            ReplicatedStorage.MainEvent:FireServer("Stomp")
            wait(1) -- Add a delay for stomp action

            -- Check if the target's health is 0 to return to safezone
            if userChar:FindFirstChildOfClass("Humanoid") and userChar.Humanoid.Health <= 0 then
                localChar:SetPrimaryPartCFrame(safezoneCFrame)
                break
            end
        end
    end

    local function autosave(user)
        if not table.find(autosavedUsers, user.Name) then
            table.insert(autosavedUsers, user.Name)
        end

        local thread = coroutine.create(function()
            while table.find(autosavedUsers, user.Name) do
                wait(1)

                local userChar = user.Character
                if userChar and userChar:FindFirstChild("BodyEffects") then
                    local bodyEffects = userChar.BodyEffects
                    local userPosition = userChar:FindFirstChild("HumanoidRootPart").Position

                    -- Check if user is within a few studs (e.g., 5 studs) of the targetCFrame
                    local distanceToTarget = (userPosition - targetCFrame.Position).magnitude

                    if distanceToTarget > 5 and distanceToTarget > 10 then
                        if bodyEffects['K.O'] and bodyEffects['K.O'].Value and 
                        not userChar:FindFirstChild("GRABBING_CONSTRAINT") and 
                        bodyEffects['Dead'] and not bodyEffects['Dead'].Value then
                            grabPlayer(user.Name)
                        end
                    elseif distanceToTarget <= 5 then
                        if bodyEffects['K.O'] and bodyEffects['K.O'].Value and 
                        not userChar:FindFirstChild("GRABBING_CONSTRAINT") and 
                        bodyEffects['Dead'] and not bodyEffects['Dead'].Value then
                            grabPlayer(user.Name)
                        end
                    end
                end
            end
        end)

        table.insert(activeAutosaveThreads, thread)
        coroutine.resume(thread)
    end

    local function removeAutosaves()
        autosavedUsers = {}
        for _, thread in pairs(activeAutosaveThreads) do
            coroutine.close(thread)
        end
        activeAutosaveThreads = {}
    end

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

        if string.sub(message, 1, 5) == ".drop" then
            local stopString = "Grabbing"
            local stopBoolean = true
            ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)
            isGrabbing = false
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Dropped any target.", "All")
        end

        if string.sub(message, 1, 8) == ".autostomp " then
            local username = string.sub(message, 10)
            local user = findPlayerByName(username)
            if user then
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp activated.", "All")
                if activeAutostompThread then
                    coroutine.close(activeAutostompThread)
                end
                activeAutostompThread = coroutine.create(function()
                    autoStomp(user)
                end)
                coroutine.resume(activeAutostompThread)
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Invalid username", "All")
            end
        end

        if string.sub(message, 1, 5) == ".stop" then
            if activeAutostompThread then
                coroutine.close(activeAutostompThread)
                activeAutostompThread = nil
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp stopped.", "All")
            end
        end
    end

    local function onPlayerAdded(player)
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
end
