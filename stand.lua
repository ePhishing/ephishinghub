return function(ownerUsername)
    -- local ownerUsername = "notephishing" -- The owner's username
        local autosavedUsers = {}
        local activeAutosaveThreads = {}
        local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
        -- bank: CFrame.new(-437.125885, 38.9783134, -285.587372, 0.0165725499, 5.298579e-08, -0.99986279, 1.16139711e-08, 1, 5.31855591e-08, 0.99986279, -1.24937944e-08, 0.0165725499)
        -- taco: CFrame.new(583.931641, 51.061409, -476.954193, -0.999745369, 1.49123665e-08, -0.0225663595, 1.44838328e-08, 1, 1.91533687e-08, 0.0225663595, 1.88216429e-08, -0.999745369)
        -- inside bank: CFrame.new(-510, 22, -283)
        local targetCFrame = CFrame.new(-437.125885, 38.9783134, -285.587372, 0.0165725499, 5.298579e-08, -0.99986279, 1.16139711e-08, 1, 5.31855591e-08, 0.99986279, -1.24937944e-08, 0.0165725499)
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Workspace = game:GetService("Workspace")
        local RunService = game:GetService("RunService")
    
    
        local isGrabbing = false

        local function findPlayerByName(name)
            for _, player in pairs(Players:GetPlayers()) do
                if string.sub(player.DisplayName:lower(), 1, #name) == name:lower() or 
                string.sub(player.Name:lower(), 1, #name) == name:lower() then
                    return player
                end
            end
            return nil
        end

        local function getKnife()
            LocalPlayer.Character.Humanoid:UnequipTools()
            
            if LocalPlayer.Backpack:FindFirstChild("[Knife]") == nil then
                local knife = Workspace.Ignored.Shop["[Knife] - $150"]
                LocalPlayer.Character.HumanoidRootPart.CFrame = knife.Head.CFrame + Vector3.new(0, 3, 0)
                if (LocalPlayer.Character.HumanoidRootPart.Position - knife.Head.Position).Magnitude <= 50 then
                    wait(0.3)
                    fireclickdetector(knife:FindFirstChild("ClickDetector"), 4)
                    wait(0.1)
                    pcall(function()
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack["[Knife]"])
                    end)
                    LocalPlayer.Character["[Knife]"].GripPos = Vector3.new(0, 5, 0)
                    LocalPlayer.Character["[Knife]"].Handle.Size = Vector3.new(50, 50, 50)
                end
            else
                return true
            end
        end
    
        local function bringPlayer(targetName)
            local targetPlayer = Players:FindFirstChild(targetName)
            if not targetPlayer then
                print("Player not found")
                return
            end
    
            local targetChar = targetPlayer.Character
            if not targetChar then
                print("Target character not found")
                return
            end
    
            while not getKnife() do
                wait()
            end
    
            local targetPosition = targetChar:WaitForChild("HumanoidRootPart").Position + Vector3.new(0, 3, 0)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
    
            while true do
                wait()
                if targetChar.BodyEffects['K.O'].Value and not targetChar:FindFirstChild("GRABBING_CONSTRAINT") and not targetChar.BodyEffects['Dead'].Value then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                    wait(0.1)
                    local grabString = "Grabbing"
                    local grabBoolean = false
                    ReplicatedStorage.MainEvent:FireServer(grabString, grabBoolean)
                    wait(0.2)
    
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 10, 0))
                    pcall(function()
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack["[Knife]"])
                    end)
                    wait(0.1)
                    LocalPlayer.Character["[Knife]"].GripPos = Vector3.new(0, 5, 0)
                    LocalPlayer.Character["[Knife]"].Handle.Size = Vector3.new(50, 50, 50)
                    LocalPlayer.Character["[Knife]"]:Activate()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 10, 0))
    
                    break
                elseif targetChar.BodyEffects['K.O'].Value == false and targetChar.BodyEffects['Dead'].Value == false or targetChar:FindFirstChild("GRABBING_CONSTRAINT") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 10, 0))
                    pcall(function()
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack["[Knife]"])
                    end)
                    wait(0.1)
                    LocalPlayer.Character["[Knife]"].GripPos = Vector3.new(0, 5, 0)
                    LocalPlayer.Character["[Knife]"].Handle.Size = Vector3.new(50, 50, 50)
                    LocalPlayer.Character["[Knife]"]:Activate()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 10, 0))
                elseif targetChar.BodyEffects['Dead'].Value then
                    Workspace.FallenPartsDestroyHeight = math.huge - math.huge
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-0.10987889766693115, -7996.8017578125, -0.1961374431848526)
                    break
                end
            end
    
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(ownerPosition)
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

            if string.sub(message, 1, 7) == ".bring " then
                local username = string.sub(message, 8)
                bringPlayer(username)
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
