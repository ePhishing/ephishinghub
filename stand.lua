return function(ownerUsername, alts)
    local autosavedUsers = {}
    local activeAutostompThreads = {}
    local activeAutosaveThreads = {}
    local isGrabbing = false
    local dropping = false
    local targetPlayerName = ownerUsername
    --local safezoneCFrame = CFrame.new(0, -400, 0)  -- Updated safezone position
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
    local targetCFrame = CFrame.new(-451.999084, 80.4387283, -207.518799, 0.7223894, 0, -0.69, 0, 1 ,0 , 0.691, 0, 0.72)
    
    -- Fetch services
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    
    -- Define localPlayer and localChar
    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local LocalPlayer = Players.LocalPlayer
    local activeFloatThread = nil
    local floatPart = nil

    print("safezoneCFrame:", safezoneCFrame)
    print("targetCFrame:", targetCFrame)
    print("Players:", Players)
    print("ReplicatedStorage:", ReplicatedStorage)
    print("Workspace:", Workspace)
    print("RunService:", RunService)
    print("localPlayer:", localPlayer)
    print("localChar:", localChar)

    local function moveToSafezone()
        local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        localChar:SetPrimaryPartCFrame(safezoneCFrame)
    end

    -- Detect respawn and move to the safezone
    local function monitorRespawn()
        local function onCharacterAdded(character)
            local bodyEffects = character:WaitForChild("BodyEffects")
            local deadValue = bodyEffects:WaitForChild("Dead")

            deadValue:GetPropertyChangedSignal("Value"):Connect(function()
                if not deadValue.Value then
                    moveToSafezone()
                end
            end)
        end

        localPlayer.CharacterAdded:Connect(onCharacterAdded)
        
        -- In case the player already has a character when the script runs
        if localPlayer.Character then
            onCharacterAdded(localPlayer.Character)
        end
    end

    monitorRespawn()

    localChar:SetPrimaryPartCFrame(safezoneCFrame)
    
    -- Function to create and position the invisible tool under the alts
    local function createInvisibleToolForAlts(altCharacter)
        local tool = Instance.new("Part")
        tool.Size = Vector3.new(1, 1, 1)  -- Skinny tool size
        tool.Anchored = true
        tool.Transparency = 1  -- Invisible
        tool.CanCollide = false
        tool.Parent = workspace
        
        -- Position the tool 2 CFrames (studs) up under the alt
        local altRootPart = altCharacter:FindFirstChild("HumanoidRootPart")
        if altRootPart then
            tool.CFrame = altRootPart.CFrame - Vector3.new(0, 2, 0)
        end
        
        return tool
    end

    local function stopFloating()
        if activeFloatThread then
            coroutine.close(activeFloatThread)
            activeFloatThread = nil
        end
        if floatPart then
            floatPart:Destroy()
            floatPart = nil
        end
    end
    
    local function startFloating(targetPlayerName, altUsernames)
        local targetPlayer = Players:FindFirstChild(targetPlayerName)
        if not targetPlayer then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Target player not found.", "All")
            return
        end
    
        local targetCharacter = targetPlayer.Character
        local localCharacter = LocalPlayer.Character
    
        if not targetCharacter or not localCharacter then
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Target or local character not found.", "All")
            return
        end
    
        -- Create a table to store floating parts for each alt
        local floatParts = {}
        
        -- Create floating parts for each alt and start floating them
        for i, altUsername in ipairs(altUsernames) do
            local altPlayer = Players:FindFirstChild(altUsername)
            if altPlayer then
                local altCharacter = altPlayer.Character
                if altCharacter then
                    -- Create an invisible part under the alt player to simulate floating
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(4, 4, 4)
                    part.Anchored = true
                    part.Transparency = 1  -- Make the part invisible
                    part.Parent = workspace
                    table.insert(floatParts, part)
    
                    activeFloatThread = coroutine.create(function()
                        while true do
                            local targetPosition = targetCharacter.HumanoidRootPart.Position
                            -- Calculate the distance based on the alt's position in the list
                            local distanceBehind = i * 4  -- Increase the distance by 4 studs for each alt
                            local behindPosition = targetPosition - (targetCharacter.HumanoidRootPart.CFrame.lookVector * distanceBehind)
            
                            -- Update the float part position
                            part.Position = behindPosition - Vector3.new(4, 4, 4)
            
                            -- Move the alt player to float behind the target player
                            altCharacter.HumanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(4, 4, 4))
            
                            RunService.RenderStepped:Wait()
                        end
                    end)
    
                    coroutine.resume(activeFloatThread)
                end
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Alt player " .. altUsername .. " not found.", "All")
            end
        end
    end

    local function findPlayerByName(name)
        name = name:lower()
        for _, player in pairs(Players:GetPlayers()) do
            if player.DisplayName:lower():find(name) or 
               player.Name:lower():find(name) then
                return player, player.Name  -- Return the player object and the exact username
            end
        end
        return nil, nil
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
                local targetPosition = targetChar.UpperTorso.Position + Vector3.new(0, 2, 0)
                
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
                        wait(0.75)
    
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
        local function isValidState()
            local userChar = user.Character
            if not userChar or not userChar:FindFirstChild("BodyEffects") then return false end
            
            local bodyEffects = userChar.BodyEffects
            local UpperTorso = userChar:FindFirstChild("UpperTorso")
            
            if not UpperTorso then return false end
    
            -- Check if the user is in a valid state for stomping
            return bodyEffects['K.O'].Value and 
                   not userChar:FindFirstChild("GRABBING_CONSTRAINT") and 
                   not bodyEffects['Dead'].Value
        end
    
        while true do
            -- Wait in the safe zone until the user is ready
            localChar:SetPrimaryPartCFrame(safezoneCFrame)
            
            -- Wait until the user is in a valid state
            while not isValidState() do
                wait(1)  -- Wait before rechecking
            end
            
            -- Proceed with stomping
            local userChar = user.Character
            local bodyEffects = userChar.BodyEffects
            local UpperTorso = userChar:FindFirstChild("UpperTorso")
            local UpperPosition = UpperTorso.Position + Vector3.new(0, 3, 0)
            
            while isValidState() do
                ReplicatedStorage.MainEvent:FireServer("Stomp")
                ReplicatedStorage.MainEvent:FireServer("Stomp")
                localChar.HumanoidRootPart.CFrame = CFrame.new(UpperPosition)
                ReplicatedStorage.MainEvent:FireServer("Stomp")
                wait(1)  -- Wait before the next stomp
            end
            
            -- Return to the safe zone if the user becomes invalid (e.g., dead)
            localChar:SetPrimaryPartCFrame(safezoneCFrame)
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

        if string.sub(message, 1, 5) == ".throw" then
            local stopString = "Grabbing"
            local stopBoolean = true
            ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)
            isGrabbing = false
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Threw any target.", "All")
        end

        if string.sub(message, 1, 11) == ".autostomp " then
            local username = string.sub(message, 12)
            local user = findPlayerByName(username)
            if user then
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp activated for " .. username, "All")
                
                -- Stop any previous auto-stomp thread for this player
                for _, thread in pairs(activeAutostompThreads) do
                    if thread.user == user then
                        coroutine.close(thread.co)
                    end
                end
    
                -- Start a new auto-stomp thread
                local thread = {
                    user = user,
                    co = coroutine.create(function()
                        autoStomp(user)
                    end)
                }
                table.insert(activeAutostompThreads, thread)
                coroutine.resume(thread.co)
            else
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Invalid username: " .. username, "All")
            end
        end
        
        if string.sub(message, 1, 5) == ".stop" then
            -- Stop all active auto-stomp threads
            for _, thread in pairs(activeAutostompThreads) do
                coroutine.close(thread.co)
            end
            activeAutostompThreads = {}
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-stomp stopped.", "All")
        end
        if string.sub(message, 1, 5) == ".drop" then
            game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Started Dropping!", "All")
            dropping = true
            
            -- Create invisible tools for all alts
            local tools = {}
            for _, altUsername in ipairs(alts) do
                local altPlayer = game.Players:FindFirstChild(altUsername)
                if altPlayer and altPlayer.Character then
                    table.insert(tools, createInvisibleToolForAlts(altPlayer.Character))
                end
            end
            
            repeat
                -- Fire the drop money event
                game.ReplicatedStorage.MainEvent:FireServer("DropMoney", 10000)
                wait(0.3)
            until dropping == false
            
            -- Clean up tools after dropping is done
            for _, tool in ipairs(tools) do
                if tool then
                    tool:Destroy()
                end
            end
        end
        if string.sub(message, 1, 2) == "S!" then
            stopFloating()
            startFloating(targetPlayerName, alts)
            game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Floating behind " .. targetPlayerName, "All")
        end
        if string.sub(message, 1, 5) == "Kill!" then
            stopFloating()
            dropping = false
            game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Stopped dropping!","All")
        end
        if string.sub(message, 1, 7) == "Vanish!" then
            stopFloating()
            dropping = false
            localChar:SetPrimaryPartCFrame(safezoneCFrame)
            game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Vanished!","All")
        end
    end
    

    -- Attach chat listener to all players
    for _, player in pairs(Players:GetPlayers()) do
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end

    -- Attach chat listener for new players
    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end)
end
