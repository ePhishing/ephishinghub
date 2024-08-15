local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HostUsername = "notephishing" -- Replace with the actual host username
local Floating = false
local BodyVelocity = nil
local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
local TargetHRP = nil

-- Helper function to create and set up BodyVelocity
local function setupBodyVelocity()
    if BodyVelocity then
        BodyVelocity:Destroy()
    end
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000) -- Adjusted for smoother movement
    BodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
end

local function floatBehind(targetPlayer)
    local targetCharacter = targetPlayer.Character
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end

    TargetHRP = targetCharacter.HumanoidRootPart
    local targetHumanoid = targetCharacter:FindFirstChild("Humanoid")
    
    -- Store target's walk speed and jump power
    local targetWalkSpeed = targetHumanoid.WalkSpeed
    local targetJumpPower = targetHumanoid.JumpPower

    -- Set initial position behind and above the target
    LocalPlayer.Character.HumanoidRootPart.CFrame = TargetHRP.CFrame - TargetHRP.CFrame.LookVector * 5 + Vector3.new(0, 3, 0)

    Floating = true

    -- Create and set up BodyVelocity
    setupBodyVelocity()

    -- Function to update floating position smoothly
    local function updateFloatingPosition()
        RunService.Stepped:Connect(function()
            if not Floating or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if BodyVelocity then BodyVelocity:Destroy() end
                Floating = false
                return
            end

            local targetHRP = targetPlayer.Character.HumanoidRootPart
            -- Position the local player 3 studs above and 5 studs behind the target
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame - targetHRP.CFrame.LookVector * 5 + Vector3.new(0, 3, 0)
            -- Update BodyVelocity to move towards the floating position
            local desiredVelocity = (LocalPlayer.Character.HumanoidRootPart.Position - targetHRP.Position) * 10
            BodyVelocity.Velocity = desiredVelocity
            -- Match target's walk speed and jump power
            LocalPlayer.Character.Humanoid.WalkSpeed = targetWalkSpeed
            LocalPlayer.Character.Humanoid.JumpPower = targetJumpPower
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            -- Set the humanoid's animation state to idle
            LocalPlayer.Character.Humanoid:LoadAnimation(game.ServerStorage:FindFirstChild("IdleAnimation")) -- Ensure you have an IdleAnimation stored
        end)
    end

    -- Start updating position
    updateFloatingPosition()
end

local function stopFloating()
    if BodyVelocity then
        BodyVelocity:Destroy()
        BodyVelocity = nil
    end
    Floating = false
    if Humanoid then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = 50 -- Set to default or desired value
        Humanoid.WalkSpeed = 16 -- Set to default or desired value
        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function onChatted(player, message)
    -- Check if the message is a kick command
    local kickPatterns = {"!kick ", ".kick ", "kick "}
    for _, pattern in ipairs(kickPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            local targetUsername = string.sub(message, string.len(pattern) + 1)
            if targetUsername == LocalPlayer.Name then
                -- Display a kick message pop-up (simulating an anti-cheat kick)
                game.StarterGui:SetCore("ChatMakeSystemMessage", {
                    Text = "You have been kicked from the game by an administrator.";
                    Color = Color3.new(1, 0, 0); -- Red color for emphasis
                    Font = Enum.Font.SourceSansBold;
                    FontSize = Enum.FontSize.Size24;
                })

                -- Wait for the message to be seen
                wait(3)

                -- Kick the local player from the game
                LocalPlayer:Kick("You have been kicked from the game.")
            end
        end
    end

    -- Check if the message is a goto command
    local gotoPatterns = {".goto ", "goto ", "!goto "}
    for _, pattern in ipairs(gotoPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            local targetUsername = string.sub(message, string.len(pattern) + 1):lower()
            for _, player in pairs(Players:GetPlayers()) do
                if string.sub(player.Name:lower(), 1, #targetUsername) == targetUsername then
                    floatBehind(player)
                    break
                end
            end
        end
    end

    -- Check if the message is a stop command
    local stopPatterns = {".stop ", "stop ", "!stop "}
    for _, pattern in ipairs(stopPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            stopFloating()
        end
    end
end

-- Connect the onChatted function to the host player's Chatted event
Players.PlayerAdded:Connect(function(player)
    if player.Name == HostUsername then
        player.Chatted:Connect(function(message)
            onChatted(player, message)
        end)
    end
end)

-- Handle the case where the host is already in the game
local hostPlayer = Players:FindFirstChild(HostUsername)
if hostPlayer then
    hostPlayer.Chatted:Connect(function(message)
        onChatted(hostPlayer, message)
    end)
end
