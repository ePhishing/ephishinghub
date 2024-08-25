return function(ownerUsername)
    -- Initialization and variable declarations
    local autosavedUsers = {}
    local activeAutosaveThreads = {}
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
    local targetCFrame = CFrame.new(-451.999084, 80.4387283, -207.518799, 0.7223894, 0, -0.69, 0, 1, 0, 0.691, 0, 0.72)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local isGrabbing = false
    local isAutoStomping = false
    local autoStompTarget = nil

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

        local function equipCombat()
            local LocalPlayer = Players.LocalPlayer
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        
            -- Check if "Combat" tool exists in either Backpack or Character
            local Combat = LocalPlayer.Backpack:FindFirstChild("Combat") or Character:FindFirstChild("Combat")
        
            if Combat then
                LocalPlayer.Character.Humanoid:EquipTool(Combat) -- Equip the tool
                Combat:Activate()
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Combat tool not found.", "All")
            end
        end

                -- Function to start auto-stomp
        local function startAutoStomp(target)
            if isAutoStomping then
                return
            end

            isAutoStomping = true
            autoStompTarget = game.Players:FindFirstChild(target)

            coroutine.wrap(function()
                while isAutoStomping and autoStompTarget do
                    local localPlayer = Players.LocalPlayer
                    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
                    local targetChar = autoStompTarget.Character

                    if targetChar and targetChar:FindFirstChild("BodyEffects") then
                        local bodyEffects = targetChar.BodyEffects
                        local targetPosition = targetChar.UpperTorso.Position + Vector3.new(0, 3, 0)
                        local localHealth = localChar.Humanoid.Health

                        -- Go to target and stomp if they are K.O. but not dead
                        if bodyEffects['K.O'] and bodyEffects['K.O'].Value and 
                        not targetChar:FindFirstChild("GRABBING_CONSTRAINT") and 
                        bodyEffects['Dead'] and not bodyEffects['Dead'].Value then

                            localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                            wait(0.1)

                            -- Perform the stomp action
                            ReplicatedStorage.MainEvent:FireServer("Stomp")
                            wait(0.5)  -- Adjust delay as needed

                            -- Return to safezone if health drops below 100
                            if localChar.Humanoid.Health < 100 then
                                localChar:SetPrimaryPartCFrame(safezoneCFrame)
                                wait(1)
                                localChar:SetPrimaryPartCFrame(targetCFrame)
                                wait(1)
                                ReplicatedStorage.MainEvent:FireServer("Stomp")
                                wait(0.5)
                            end

                            -- Return to safezone after stomping
                            localChar:SetPrimaryPartCFrame(safezoneCFrame)
                        end
                    end

                    wait(1)  -- Adjust delay as needed
                end
            end)()
        end

        -- Function to stop auto-stomp
        local function stopAutoStomp()
            isAutoStomping = false
            autoStompTarget = nil
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
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Stopped grabbing.", "All")
            end
            if string.sub(message, 1, 7) == ".combat" then
                equipCombat()
            end
            if string.sub(message, 1, 12) == ".autostomp " then
                local targetName = string.sub(message, 13)
                startAutoStomp(targetName)
            end
    
            if message == ".stop" then
                stopAutoStomp()
            end

        end
    
        Players.PlayerAdded:Connect(function(player)
            player.Chatted:Connect(function(message)
                onChatted(player, message)
            end)
        end)
    
        for _, player in pairs(Players:GetPlayers()) do
            player.Chatted:Connect(function(message)
                onChatted(player, message)
            end)
        end
    end
