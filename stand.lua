return function(ownerUsername)
    -- local ownerUsername = "notephishing" -- The owner's username
    local autosavedUsers = {}
    local activeAutostompThreads = {}
    local activeAutosaveThreads = {}
    local isGrabbing = false
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
    local targetCFrame = CFrame.new(-451.999084, 80.4387283, -207.518799, 0.7223894, 0, -0.69, 0, 1 ,0 , 0.691, 0, 0.72)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local StarterGui = game:GetService("StarterGui")
    local ChatService = game:GetService("Chat")


    -- Configuration
    local Config = {
        enabled = true,  -- Auto-enable chat spying
        spyOnMyself = true,
        public = true,
        publicItalics = true
    }

    localChar:SetPrimaryPartCFrame(safezoneCFrame)

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
    end

        -- Chat Spy Functionality
    local function onChatMessageReceived(player, message)
        if Config.enabled and (Config.spyOnMyself or player ~= Player) then
            local formattedMessage = message:gsub("[\n\r]", ''):gsub("\t", ' '):gsub("[ ]+", ' ')
            local hidden = true
            local conn = ChatService.OnMessageDoneFiltering:Connect(function(packet, channel)
                if packet.SpeakerUserId == player.UserId and packet.Message == formattedMessage and 
                (channel == "All" or (channel == "Team" and not Config.public and player.Team == Player.Team)) then
                    hidden = false
                end
            end)
            wait(1)
            conn:Disconnect()
            if hidden and Config.enabled then
                if Config.public then
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(
                        (Config.publicItalics and "/me " or '') .. "{SPY} [" .. player.Name .. "]: " .. formattedMessage,
                        "All"
                    )
                else
                    StarterGui:SetCore("ChatMakeSystemMessage", {
                        Text = "{SPY} [" .. player.Name .. "]: " .. formattedMessage
                    })
                end
            end
        end
    end


    local function onPlayerAdded(player)
        player.Chatted:Connect(function(message)
            onChatted(player, message)
            onChatMessageReceived(player, message)
        end)
    end

    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerAdded(player)
        onChatMessageReceived(player, message)
    end
end
