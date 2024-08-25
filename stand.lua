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
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp is already active.", "All")
            return
        end

        isAutoStomping = true
        autoStompTarget = game.Players:FindFirstChild(target)
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp activated for " .. target, "All")

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

            -- Notify when auto-stomp stops
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp stopped for " .. target, "All")
        end)()
    end

    -- Function to stop auto-stomp
    local function stopAutoStomp()
        if not isAutoStomping then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp is not active.", "All")
            return
        end
        isAutoStomping = false
        autoStompTarget = nil
        ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp has been stopped.", "All")
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
                            autoStompTarget = user
                            startAutoStomp(user.Name)
                        end
                    end
                end
            end
        end)

        activeAutosaveThreads[user.Name] = thread
        coroutine.resume(thread)
    end

    local function stopAutosave(user)
        if activeAutosaveThreads[user.Name] then
            table.remove(autosavedUsers, table.find(autosavedUsers, user.Name))
            activeAutosaveThreads[user.Name] = nil
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Autosave stopped for " .. user.Name, "All")
        end
    end

    -- Command handling
    local function onCommandReceived(command)
        local args = command:split(" ")

        if args[1] == ".autostomp" then
            if args[2] then
                startAutoStomp(args[2])
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Please specify a target username.", "All")
            end
        elseif args[1] == ".stopautostomp" then
            stopAutoStomp()
        elseif args[1] == ".grab" then
            if args[2] then
                grabPlayer(args[2])
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Please specify a target username.", "All")
            end
        elseif args[1] == ".autosave" then
            if args[2] then
                local target = findPlayerByName(args[2])
                if target then
                    autosave(target)
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Autosaving for " .. target.Name, "All")
                else
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Player not found.", "All")
                end
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Please specify a target username.", "All")
            end
        elseif args[1] == ".stopautosave" then
            if args[2] then
                local target = findPlayerByName(args[2])
                if target then
                    stopAutosave(target)
                else
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Player not found.", "All")
                end
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Please specify a target username.", "All")
            end
        end
    end

    -- Listening to chat for commands
    local chatService = require(ReplicatedStorage:WaitForChild("ChatServiceRunner"):WaitForChild("ChatService"))
    chatService.OnMessageReceived:Connect(onCommandReceived)
end
