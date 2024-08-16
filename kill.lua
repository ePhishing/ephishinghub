local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local HostUsername = "notephishing" -- Replace with the actual host username
local TargetPlayer = nil
local ToolEquipped = false
local Attacking = false
local Reloading = false

-- Function to equip the first tool
local function equipFirstTool()
    if ToolEquipped then return end
    local backpack = LocalPlayer:WaitForChild("Backpack")
    local tool = backpack:FindFirstChildOfClass("Tool")
    if tool then
        tool.Parent = LocalPlayer.Character
        ToolEquipped = true
    else
        warn("No tool found in backpack.")
    end
end

-- Function to teleport behind the target and follow
local function followBehind(targetPlayer)
    local targetHRP = targetPlayer.Character:WaitForChild("HumanoidRootPart")
    local localHRP = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

    local followConnection
    followConnection = RunService.Stepped:Connect(function()
        if not Attacking then
            followConnection:Disconnect()
            return
        end

        local targetPosition = targetHRP.Position
        localHRP.CFrame = CFrame.new(targetPosition - targetHRP.CFrame.LookVector * 5)

        -- Fire the tool if equipped
        if ToolEquipped and not Reloading then
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Handle") then
                tool:Activate()
            end
        end
    end)
end

-- Function to monitor and attack the target until their health is 0
local function attackTarget(targetPlayer)
    Attacking = true

    -- Equip the first tool
    equipFirstTool()

    -- Follow behind and attack
    followBehind(targetPlayer)

    -- Monitor the target's health
    local humanoid = targetPlayer.Character:WaitForChild("Humanoid")
    while Attacking and humanoid.Health > 0 do
        wait(0.1)
    end

    Attacking = false
    ToolEquipped = false
end

-- Function to simulate reloading
local function reloadTool()
    if ToolEquipped and not Reloading then
        Reloading = true
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate() -- Click the tool
            wait(0.2) -- Slight delay to simulate clicking
            keypress(Enum.KeyCode.R) -- Simulate pressing 'R' key for reload
            wait(0.2) -- Simulate reload time (adjust as needed)
            keyrelease(Enum.KeyCode.R)
        end
        Reloading = false
    else
        warn("Tool not equipped or already reloading.")
    end
end

-- Function to handle chat commands
local function onChatted(player, message)
    -- Ensure the command is coming from the host
    if player.Name ~= HostUsername then return end

    -- Check for the kill command
    local killPatterns = {".kill ", "?kill ", "!kill "}
    for _, pattern in ipairs(killPatterns) do
        if string.sub(message, 1, string.len(pattern)) == pattern then
            local targetUsername = string.sub(message, string.len(pattern) + 1)
            local targetPlayer = Players:FindFirstChild(targetUsername)
            if targetPlayer then
                attackTarget(targetPlayer)
            else
                warn("Target player not found.")
            end
        end
    end

    -- Check for the reload command
    local reloadPatterns = {".reload", "?reload", "!reload"}
    for _, pattern in ipairs(reloadPatterns) do
        if message == pattern then
            reloadTool()
        end
    end
end

-- Connect the chat event
LocalPlayer.Chatted:Connect(function(message)
    onChatted(LocalPlayer, message)
end)

Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        onChatted(player, message)
    end)
end)
