local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HostUsername = "notephishing" -- Replace with the actual host username
local Floating = false
local BodyVelocity = nil
local TargetHRP = nil
local LastTargetPosition = nil
local StabilityThreshold = 0.1 -- Movement threshold to check if target is moving
local BobbingAmplitude = 1 -- Amplitude of the bobbing effect
local BobbingFrequency = 1 -- Frequency of the bobbing effect
local BobbingOffset = 3.5 -- Starting height for bobbing effect
local Spinning = false
local SpinSpeed = 10 -- Speed of the spinning motion
local SpinRadius = 10 -- Radius of the spinning motion
local TargetPlayer = nil


-- Leviathan Animation IDs
local LevitationAnimID = "rbxassetid://619543721"
local FallingAnimID = "rbxassetid://619541867"

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

-- Helper function to stop all default animations and apply Leviathan animations
local function applyLeviathanAnimations()
    local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

    -- Stop all animation tracks
    for _, playingTrack in animator:GetPlayingAnimationTracks() do
        playingTrack:Stop(0)
    end

    local animateScript = LocalPlayer.Character:WaitForChild("Animate")
    animateScript.run.RunAnim.AnimationId = LevitationAnimID
    animateScript.walk.WalkAnim.AnimationId = "rbxassetid://619544080"
    animateScript.jump.JumpAnim.AnimationId = "rbxassetid://619542888"
    animateScript.idle.Animation1.AnimationId = "rbxassetid://619542203"
    animateScript.idle.Animation2.AnimationId = "rbxassetid://619542203"
    animateScript.fall.FallAnim.AnimationId = FallingAnimID
    animateScript.swim.Swim.AnimationId = "rbxassetid://619543721"
    animateScript.swimidle.SwimIdle.AnimationId = "rbxassetid://619543721"
    animateScript.climb.ClimbAnim.AnimationId = "rbxassetid://619541458"
end

local function floatBehind(targetPlayer)
    local targetCharacter = targetPlayer.Character
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end

    TargetHRP = targetCharacter.HumanoidRootPart
    LastTargetPosition = TargetHRP.Position

    -- Set initial position behind and above the target
    LocalPlayer.Character.HumanoidRootPart.CFrame = TargetHRP.CFrame - TargetHRP.CFrame.LookVector * 3 + Vector3.new(0, BobbingOffset, 0)

    Floating = true

    -- Create and set up BodyVelocity
    setupBodyVelocity()

    -- Apply Leviathan animations
    applyLeviathanAnimations()

    -- Function to update floating position smoothly
    local function updateFloatingPosition()
        RunService.Stepped:Connect(function()
            if not Floating or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if BodyVelocity then BodyVelocity:Destroy() end
                Floating = false
                -- Ensure falling animation stops if floating stops
                LocalPlayer.Character.Humanoid:StopAnimation(FallingAnimID)
                return
            end

            local targetHRP = targetPlayer.Character.HumanoidRootPart
            local currentPosition = targetHRP.Position

            -- Check if the target is moving
            if (currentPosition - LastTargetPosition).magnitude > StabilityThreshold then
                -- Position the local player 3 studs above and 5 studs behind the target
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame - targetHRP.CFrame.LookVector * 3 + Vector3.new(0, BobbingOffset, 0)
                -- Update BodyVelocity to move towards the floating position
                local desiredVelocity = (LocalPlayer.Character.HumanoidRootPart.Position - targetHRP.Position) * 0.5 -- Adjusted for controlled movement
                BodyVelocity.Velocity = desiredVelocity
                -- Match target's walk speed and jump power but keep local player stationary
                LocalPlayer.Character.Humanoid.WalkSpeed = 0
                LocalPlayer.Character.Humanoid.JumpPower = 0
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
                -- Play levitation animation
                LocalPlayer.Character.Humanoid:LoadAnimation(LevitationAnimID):Play()
                
                -- Update the last target position
                LastTargetPosition = currentPosition
            else
                -- If the target is idle, apply bobbing effect
                local time = tick()
                local bobbingOffset = math.sin(time * BobbingFrequency) * BobbingAmplitude
                -- Update the position with bobbing effect
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame - targetHRP.CFrame.LookVector * 3 + Vector3.new(0, BobbingOffset + bobbingOffset, 0)
                BodyVelocity.Velocity = Vector3.new(0, 0, 0) -- Stop any unwanted movement
                
                -- Play falling animation continuously
                LocalPlayer.Character.Humanoid:LoadAnimation(FallingAnimID):Play()
            end
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
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.UseJumpPower = true
        LocalPlayer.Character.Humanoid.JumpPower = 50 -- Set to default or desired value
        LocalPlayer.Character.Humanoid.WalkSpeed = 16 -- Set to default or desired value
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    -- Ensure falling animation stops if floating stops
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:StopAnimation(FallingAnimID)
    end
end

local function rejoinGame()
    local player = LocalPlayer
    local placeId = game.PlaceId -- Get the current place ID
    local teleportService = game:GetService("TeleportService")
    teleportService:Teleport(placeId, player) -- Teleport the player to the same place
end

-- Function to start locking and spinning the camera on the target player
local function lockCameraOnTarget(targetPlayer)
    TargetPlayer = targetPlayer
    local targetHRP = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not targetHRP then
        warn("Target HumanoidRootPart not found.")
        return
    end
    
    Spinning = true

    -- Function to update the camera's CFrame to follow and spin around the target
    local function updateCamera()
        local startTime = tick()

        RunService.RenderStepped:Connect(function()
            if not Spinning or not TargetPlayer.Character or not TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                return
            end
            
            local targetPosition = TargetPlayer.Character.HumanoidRootPart.Position
            local timeElapsed = tick() - startTime
            local angle = timeElapsed * SpinSpeed
            
            -- Compute the new camera position in a circular path around the target
            local offsetX = SpinRadius * math.cos(angle)
            local offsetY = SpinRadius * math.sin(angle) * 0.5
            local offsetZ = SpinRadius * math.sin(angle)

            -- Update camera CFrame
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(offsetX, offsetY, offsetZ), targetPosition)
        end)
    end

    updateCamera()
end

-- Function to stop the camera lock and spinning
local function stopCameraLock()
    Spinning = false
end

local function onChatted(player, message)
    -- Ensure the command is coming from the host
    if player.Name ~= HostUsername then return end

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


        -- Check if the message is a lock command
    local lockPatterns = {".lock ", "!lock ", "lock "}
    for _, pattern in ipairs(lockPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            local targetUsername = string.sub(message, string.len(pattern) + 1):lower()
            for _, player in pairs(Players:GetPlayers()) do
                if string.sub(player.Name:lower(), 1, #targetUsername) == targetUsername then
                    lockCameraOnTarget(player)
                    break
                end
            end
        end
    end

    -- Check if the message is a stop command
    local stopPatterns = {".stop ", "stop ", "!stop "}
    for _, pattern in ipairs(stopPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            stopCameraLock()
            stopFloating()
        end
    end

    -- Check if the message is a rejoin command
    local rejoinPatterns = {".rejoin ", "rejoin ", "!rejoin ", "rejoin!"}
    for _, pattern in ipairs(rejoinPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            rejoinGame()
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
