local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HostUsername = "notephishing" -- Replace with the actual host username
local Floating = false
local BodyVelocity = nil
local TargetHRP = nil
local LastTargetPosition = nil
local StabilityThreshold = 0.1 -- Movement threshold to check if the target is moving
local BobbingAmplitude = 1 -- Amplitude of the bobbing effect
local BobbingFrequency = 1 -- Frequency of the bobbing effect
local BobbingOffset = 3.5 -- Starting height for the bobbing effect
local Spinning = false
local SpinSpeed = 10 -- Speed of the spinning motion
local SpinRadius = 10 -- Radius of the spinning motion
local TargetPlayer = nil
local cameraConnection -- Used to disconnect camera lock
local floatingConnection -- Used to disconnect floating motion

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
    --animateScript.walk.WalkAnim.AnimationId = "rbxassetid://"
    --animateScript.jump.JumpAnim.AnimationId = "rbxassetid://"
    --animateScript.idle.Animation1.AnimationId = "rbxassetid://"
    --animateScript.idle.Animation2.AnimationId = "rbxassetid://"
    animateScript.fall.FallAnim.AnimationId = FallingAnimID
    --animateScript.swim.Swim.AnimationId = "rbxassetid://"
    --animateScript.swimidle.SwimIdle.AnimationId = "rbxassetid://"
    --animateScript.climb.ClimbAnim.AnimationId = "rbxassetid://"
end

local function floatBehind(targetPlayer)
    local targetCharacter = targetPlayer.Character
    if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then return end

    TargetHRP = targetCharacter.HumanoidRootPart
    LastTargetPosition = TargetHRP.Position

    -- Set initial position behind and above the target
    LocalPlayer.Character.HumanoidRootPart.CFrame = TargetHRP.CFrame - TargetHRP.CFrame.LookVector * 5 + Vector3.new(0, BobbingOffset, 0)

    Floating = true

    -- Create and set up BodyVelocity
    setupBodyVelocity()

    -- Apply Leviathan animations
    applyLeviathanAnimations()

    -- Function to update floating position smoothly
    local function updateFloatingPosition()
        floatingConnection = RunService.Stepped:Connect(function()
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
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame - targetHRP.CFrame.LookVector * 5 + Vector3.new(0, BobbingOffset, 0)
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
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame - targetHRP.CFrame.LookVector * 5 + Vector3.new(0, BobbingOffset + bobbingOffset, 0)
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
    if floatingConnection then
        floatingConnection:Disconnect()
        floatingConnection = nil
    end
    Floating = false
    if BodyVelocity then
        BodyVelocity:Destroy()
    end
end

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

        cameraConnection = RunService.RenderStepped:Connect(function()
            if not Spinning or not TargetPlayer.Character or not TargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                return
            end

            local targetPosition = TargetPlayer.Character.HumanoidRootPart.Position
            local timeElapsed = tick() - startTime
            local angle = timeElapsed * SpinSpeed

            -- Randomly adjust the spin axis to create unpredictable motion
            local spinAxisX = math.random(-1, 1) * SpinRadius * math.cos(angle)
            local spinAxisY = math.random(-1, 1) * SpinRadius * math.sin(angle) * 0.5
            local spinAxisZ = math.random(-1, 1) * SpinRadius * math.sin(angle)

            -- Compute the new position with randomness applied to create a varied 360-degree orbit
            local offsetX = spinAxisX + math.cos(angle)
            local offsetY = spinAxisY + math.sin(angle)
            local offsetZ = spinAxisZ + math.sin(angle)

            -- Set the new position of the LocalPlayer while ensuring the camera looks at the target
            local newCameraPosition = targetPosition + Vector3.new(offsetX, offsetY, offsetZ)
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(newCameraPosition, targetPosition)
        end)
    end

    updateCamera()
end

-- Function to stop the camera lock and spinning
local function stopCameraLock()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
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
                    TextSize = 24;
                })
                return
            end
        end
    end

    -- Float behind the target if the command is .goto
    local gotoPattern = ".goto "
    if string.sub(message, 1, string.len(gotoPattern)) == gotoPattern then
        local targetUsername = string.sub(message, string.len(gotoPattern) + 1)
        local targetPlayer = Players:FindFirstChild(targetUsername)
        if targetPlayer then
            floatBehind(targetPlayer)
        end
        return
    end

    -- Spin around the target if the command is .spin
    local spinPattern = ".spin "
    if string.sub(message, 1, string.len(spinPattern)) == spinPattern then
        local targetUsername = string.sub(message, string.len(spinPattern) + 1)
        local targetPlayer = Players:FindFirstChild(targetUsername)
        if targetPlayer then
            lockCameraOnTarget(targetPlayer)
        end
        return
    end

    -- Stop floating and spinning if the command is stop
    if message == "stop" or message == "!stop" or message == "stop!" or message == ".stop" or message == "stop." then
        stopFloating()
        stopCameraLock()
        return
    end
end

-- Connect the onChatted function to the Chatted event
Players.PlayerChatted:Connect(function(player, message)
    onChatted(player, message)
end)

-- Automatically apply the Leviathan animations when the player's character is added
LocalPlayer.CharacterAdded:Connect(applyLeviathanAnimations)
