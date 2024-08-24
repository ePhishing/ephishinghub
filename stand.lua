return function(ownerUsername)
    local autosavedUsers = {}
    local activeAutosaveThreads = {}
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087)
    local targetCFrame = CFrame.new(-437.125885, 38.9783134, -285.587372)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local isGrabbing = false

    -- Define getKnife function
    local function getKnife()
        local localPlayer = Players.LocalPlayer
        local character = localPlayer.Character
        if not character or not localPlayer.Backpack then return end
        
        character.Humanoid:UnequipTools()
        local knife = Workspace.Ignored.Shop:FindFirstChild("[Knife] - $150")
        if knife and not localPlayer.Backpack:FindFirstChild("[Knife]") then
            localPlayer.Character.HumanoidRootPart.CFrame = knife.Head.CFrame + Vector3.new(0, 3, 0)
            if (localPlayer.Character.HumanoidRootPart.Position - knife.Head.Position).Magnitude <= 50 then
                wait(0.3)
                fireclickdetector(knife:FindFirstChild("ClickDetector"), 4)
                wait(0.1)
                pcall(function()
                    localPlayer.Character.Humanoid:EquipTool(localPlayer.Backpack:FindFirstChild("[Knife]"))
                end)
                localPlayer.Character["[Knife]"].GripPos = Vector3.new(0, 5, 0)
                localPlayer.Character["[Knife]"].Handle.Size = Vector3.new(50, 50, 50)
            end
        end
    end

    -- Define grabPlayer function
    local function grabPlayer(target)
        local localPlayer = Players.LocalPlayer
        local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        
        if isGrabbing then return end
        isGrabbing = true
        
        while isGrabbing do
            wait()
            
            if game.Players[target] and game.Players[target].Character.BodyEffects['K.O'].Value and
            not game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") and
            not game.Players[target].Character.BodyEffects['Dead'].Value then
                
                local targetChar = game.Players[target].Character
                local targetPosition = targetChar.UpperTorso.Position + Vector3.new(0, 3, 0)
                
                localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                wait(0.1)
                
                local grabString = "Grabbing"
                local grabBoolean = false
                ReplicatedStorage.MainEvent:FireServer(grabString, grabBoolean)
                wait(0.2)
                
                if game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") then
                    
                    localChar:SetPrimaryPartCFrame(targetCFrame)
                    
                    while (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude > 2 do
                        wait()
                    end
                    
                    if (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude <= 3 then
                        wait(1)
                        
                        local stopString = "Grabbing"
                        local stopBoolean = true
                        ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)
                        
                        wait(1)
                        
                        localChar:SetPrimaryPartCFrame(safezoneCFrame)
                        
                        isGrabbing = false
                        break
                    end
                end
            end
        end
    end

    -- Define autosave function
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
                    if distanceToTarget > 5 then
                        if bodyEffects['K.O'] and bodyEffects['K.O'].Value and
                        not userChar:FindFirstChild("GRABBING_CONSTRAINT") and
                        bodyEffects['Dead'] and not bodyEffects['Dead'].Value then

                            grabPlayer(user.Name)
                        end
                    else
                        print(user.Name .. " is already close to the target position. Skipping grab.")
                    end
                end
            end
        end)

        table.insert(activeAutosaveThreads, thread)
        coroutine.resume(thread)
    end

    -- Define removeAutosaves function
    local function removeAutosaves()
        autosavedUsers = {}
        for _, thread in pairs(activeAutosaveThreads) do
            coroutine.close(thread)
        end
        activeAutosaveThreads = {}
    end

    -- Define onChatted function
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

        if string.sub(message, 1, 7) == ".bring " then
            local username = string.sub(message, 8)
            local targetPlayer = findPlayerByName(username)
            if targetPlayer then
                getKnife()
                wait(0.5) -- Wait to ensure the knife is equipped
                -- Simulate using the knife on the target until they are knocked or grabbable
                local function useKnifeOnTarget(target)
                    local localPlayer = Players.LocalPlayer
                    local targetChar = target.Character
                    if targetChar then
                        -- Move to the target's location
                        localPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetChar.HumanoidRootPart.Position + Vector3.new(0, 10, 0))
                        pcall(function()
                            localPlayer.Character.Humanoid:EquipTool(localPlayer.Backpack:FindFirstChild("[Knife]"))
                        end)
                        wait(0.1)
                        local knife = localPlayer.Character:FindFirstChild("[Knife]")
                        if knife then
                            knife.GripPos = Vector3.new(0, 5, 0)
                            knife.Handle.Size = Vector3.new(50, 50, 50)
                            knife:Activate()
                        end
                        -- Simulate until target is knocked or grabbable
                        while not targetChar.BodyEffects['K.O'].Value and not targetChar:FindFirstChild("GRABBING_CONSTRAINT") do
                            wait(0.1)
                            knife:Activate()
                        end
                        -- Grab the target
                        grabPlayer(username)
                    end
                end
                useKnifeOnTarget(targetPlayer)
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Invalid username", "All")
            end
        end
    end

    -- Function to find player by name
    local function findPlayerByName(name)
        for _, player in pairs(Players:GetPlayers()) do
            if string.sub(player.DisplayName:lower(), 1, #name) == name:lower() or 
            string.sub(player.Name:lower(), 1, #name) == name:lower() then
                return player
            end
        end
        return nil
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
