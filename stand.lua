return function(ownerUsername)
    -- Local variables
    local autosavedUsers = {}
    local activeAutosaveThreads = {}
    local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
    local targetCFrame = CFrame.new(-422.530182, 80.4387283, -218.128326, 0.737924516, 0, -0.674883246, 0, 1, 0, 0.674883246, 0, 0.7379245)
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")

    local isGrabbing = false
    local isStopping = false

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
        local Combat = LocalPlayer.Backpack:FindFirstChild("Combat") or Character:FindFirstChild("Combat")
        if Combat then
            LocalPlayer.Character.Humanoid:EquipTool(Combat)
            Combat:Activate()
        else
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Combat tool not found.", "All")
        end
    end

    local function grabPlayer(target, bringToOwner)
        local localPlayer = Players.LocalPlayer
        local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local ownerPlayer = findPlayerByName(ownerUsername)

        if isGrabbing then
            return
        end

        isGrabbing = true

        while isGrabbing do
            if isStopping then
                isGrabbing = false
                return
            end

            wait()

            if game.Players[target] and game.Players[target].Character and
                game.Players[target].Character.BodyEffects['K.O'].Value and
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
                    if bringToOwner and ownerPlayer then
                        local ownerPosition = ownerPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
                        localChar:SetPrimaryPartCFrame(CFrame.new(ownerPosition))
                    else
                        localChar:SetPrimaryPartCFrame(targetCFrame)
                    end

                    while (localChar.PrimaryPart.Position - (bringToOwner and ownerPlayer.Character.HumanoidRootPart.Position or targetCFrame.Position)).magnitude > 2 do
                        wait()
                    end

                    if (localChar.PrimaryPart.Position - (bringToOwner and ownerPlayer.Character.HumanoidRootPart.Position or targetCFrame.Position)).magnitude <= 3 then
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

    local function bringPlayer(targetName)
        if isStopping then return end

        while true do
            if isStopping then return end

            local targetPlayer = findPlayerByName(targetName)
            if targetPlayer then
                local LocalPlayer = Players.LocalPlayer
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local localChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

                local Combat = LocalPlayer.Backpack:FindFirstChild("Combat") or Character:FindFirstChild("Combat")

                if Combat then
                    LocalPlayer.Character.Humanoid:EquipTool(Combat)
                    Combat:Activate()
                else
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Combat tool not found.", "All")
                end

                local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
                local targetLookVector = targetPlayer.Character.HumanoidRootPart.CFrame.LookVector
                local localPosition = targetPosition - (targetLookVector * 10)

                localChar:SetPrimaryPartCFrame(CFrame.new(localPosition, targetPosition))

                wait(4)

                if targetPlayer.Character.BodyEffects['K.O'].Value and not targetPlayer.Character.BodyEffects['Dead'].Value then
                    grabPlayer(targetPlayer.Name, true)
                    break
                else
                    localChar:SetPrimaryPartCFrame(safezoneCFrame)
                    wait(2)
                end
            else
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
            wait(1)
            localChar:SetPrimaryPartCFrame(safezoneCFrame)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end)
end
