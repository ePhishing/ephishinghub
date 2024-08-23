local ownerUsername = "notephishing"
local autosavedUsers = {}
local safezoneCFrame = CFrame.new(-117.270287, -58.7000618, 146.536087, 0.999873519, 5.21876942e-08, -0.0159031227, -5.22713037e-08, 1, -4.84179008e-09, 0.0159031227, 5.67245495e-09, 0.999873519)
local targetCFrame = CFrame.new(583.931641, 51.061409, -476.954193, -0.999745369, 1.49123665e-08, -0.0225663595, 1.44838328e-08, 1, 1.91533687e-08, 0.0225663595, 1.88216429e-08, -0.999745369)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local isGrabbing = false

local function findPlayerByName(name)
    local lowerName = name:lower()
    for _, player in pairs(Players:GetPlayers()) do
        local displayName = player.DisplayName:lower()
        local username = player.Name:lower()

        if displayName:find(lowerName, 1, true) == 1 or username:find(lowerName, 1, true) == 1 then
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

            localChar.HumanoidRootPart.CFrame = CFrame.new(targetPosition)

            local grabString = "Grabbing"
            local grabBoolean = false
            ReplicatedStorage.MainEvent:FireServer(grabString, grabBoolean)

            if game:GetService("Workspace").Players:WaitForChild(target):FindFirstChild("GRABBING_CONSTRAINT") then

                localChar:SetPrimaryPartCFrame(targetCFrame)

                while (localChar.PrimaryPart.Position - targetCFrame.Position).magnitude > 2 do
                    wait()
                end
                
                if (localChar.PrimaryPart.CFrame.Position - targetCFrame.Position).magnitude < 0.1 then
                
                    local stopString = "Grabbing"
                    local stopBoolean = true
                    ReplicatedStorage.MainEvent:FireServer(stopString, stopBoolean)
                    
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
        print("User " .. user.Name .. " added to autosave list.")
    end

    local localPlayer = Players.LocalPlayer
    local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()

    user.Character:WaitForChild("Humanoid").HealthChanged:Connect(function(health)
        if health <= 1 then
            local userChar = user.Character or user.CharacterAdded:Wait()
            grabPlayer(user.Name)
        end
    end)
end

local function removeAutosaves()
    autosavedUsers = {}
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
