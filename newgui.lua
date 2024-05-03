

--!nocheck
--[=[
    MAKE SILENT-AIM:
        * Only useable when tool activated;
]=]
--// Cleanup
if _G.Draw then
    for _, v in next, _G.Draw.drawed do
        v:Destroy()
    end
    table.clear(_G.Draw)
    _G.Draw = nil
end
if _G.env then
    for _, signal in next, _G.env.signals do
        signal:Disconnect()
    end
    table.clear(_G.env)
    _G.env = nil
end



--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")



--// Player vars
local Player = Players.LocalPlayer
local Backpack = Player:FindFirstChild("Backpack") or Player:WaitForChild("Backpack")
local Mouse = Player:GetMouse()
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")

local Camera = workspace.CurrentCamera



--// Folders
local Lobby = workspace:FindFirstChild("Lobby")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")



--// Remotes
local Shoot: RemoteEvent? = Remotes and Remotes:FindFirstChild("Shoot")



-- Globals --
_G.env = {
    states = {
        Aimbot = false,
        SpeedHack = false,
        InfJump = false,
        SilentAim = false,
        KillAll = false,
        Hitbox = false,
        RgbHitbox = false,
        EnemyEsp = false,
        FriendlyEsp = false,
        WallCheck = false
    },
    values = {
        Bones = {
            "HumanoidRootPartHead",
            "LeftHand",
            "RightHand",
            "LeftLowerArm",
            "RightLowerArm",
            "LeftUpperArm",
            "RightUpperArm",
            "LeftFoot",
            "LeftLowerLeg",
            "UpperTorso",
            "LeftUpperLeg",
            "RightFoot",
            "RightLowerLeg",
            "LowerTorso",
            "RightUpperLeg",
            "HeadTorso",
            "Left Arm",
            "Right Arm",
            "Left Leg",
            "Right Leg",
            "HumanoidRootPart"
        },
        Esp = {
            Enemy = {
                Name = false,
                Distance = false,
                Box = false
            },
            Friendly = {
                Name = false,
                Distance = false,
                Box = false
            }
        },
        Aimbot = {
            Target = ""
        },
        Teleport = {
            Target = "",
            Auto = false
        },
        Stand = {
            Dual = 1,
            Type = "Classic",
            Auto = false
        },
        Hitbox = {
            Size = 2,
            Color = Color3.fromRGB(163, 162, 165),
            Transparency = 1
        },
        Speedhack = 16
    },
    signals = {}
}



--// Functions
local function GetStandByType(Type)
    local a = Lobby and Lobby:FindFirstChild("ClassicStands")
    local b = Lobby and Lobby:FindFirstChild("DualityStands")
    local stand = nil

    if not (a and b) then
        return stand
    end
    
    if (Type):lower() == "classic" then
        for _, v in next, a:GetChildren() do
            for _, c in next, v:GetChildren() do
                if c.Name == "Stand" then

                    local data = c:GetAttributes()
                    local Size = _G.env.values.Stand.Dual
    
                    if (Size == 1 and (not data.MaxCharacters and data.CharacterCount == 0)) then
                        return c
                    end
                    if (Size > 1 and (data.MaxCharacters and data.CharacterCount) and data.CharacterCount < data.MaxCharacters) then
                        return c
                    end
                end
            end
        end
    end

    if (Type):lower() == "duality" then
        for _, v in next, b:GetChildren() do
            for _, c in next, v:GetChildren() do
                if c.Name == "Stand" then

                    local data = c:GetAttributes()
                    local Size = _G.env.values.Stand.Dual
    
                    if (Size == 1 and (not data.MaxCharacters and data.CharacterCount == 0)) then
                        return c
                    end
                    if (Size > 1 and (data.MaxCharacters and data.CharacterCount) and data.CharacterCount < data.MaxCharacters) then
                        return c
                    end
                end
            end
        end
    end

    return stand
end



-- Initialize --
loadstring(request {
    Url = "https://pastebin.com/raw/hHtrB2cD",
    Method = "GET"
}.Body)()



-- Libraries --
local UILib = loadstring(request {
    Url = "https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/Venus%20Lib/Venus%20Lib%20Source.lua",
    Method = "GET"
}.Body)()



-- UI Library --
local Window = UILib:Load {
    Name = "Murderer vs Sheriff Duels"..if game.PlaceVersion == 1923 then
        ` | Status: UNDETECTED`
    else
        ` | Status: RISKY`,  --| Name
    SizeX = 500,            --| Width
    SizeY = 350,            --| Height
    Theme = "Midnight",     --| Theme
    Extension = "json",     --| File format
    Folder = "Settings"     --| Settings folder
}
local Watermark = UILib:Watermark("Я лучший, я всегда побеждаю | v1.0 | LeftAlt")
--| Watermark:Set(text)         | Name
--| Watermark:Hide()            | Toggle
--| UILib.Extension = "json"    | File format
--| library.Folder = "Settings" | Settings folder



-- Tabs --
local Tabs = {
    Client = Window:Tab "Client",
    World = Window:Tab "World",
    Misc = Window:Tab "Misc",
    Credits = Window:Tab "Credits"
}



-- Sections --
local Sections = {
    Client = {
        Player = Tabs.Client:Section {
            Name = "Player", Side = "Left"
        },
        Aimbot = Tabs.Client:Section {
            Name = "Aimbot", Side = "Right"
        },
        Hitbox = Tabs.Client:Section {
            Name = "Hitbox", Side = "Left"
        }
    },
    World = {
        Esp = Tabs.World:Section {
            Name = "Esp", Side = "Left"
        }
    },
    Misc = {
        Fun = Tabs.Misc:Section {
            Name = "Fun", Side = "Left",
        },
        Perks = Tabs.Misc:Section {
            Name = "Perks", Side = "Left"
        },
        Settings = Tabs.Misc:Section {
            Name = "Settings", Side = "Right"
        }
    },
    Credits = {
        Developers = Tabs.Credits:Section {
            Name = "Developers", Side = "Left"
        },
        Information = Tabs.Credits:Section {
            Name = "Information", Side = "Right"
        }
    }
}
local SecElement = {Misc = {}}



--// Client
Sections.Client.Player:Slider {
    Text = "Speed",
    Default = 16,
    Min = 16,
    Max = 150,
    Float = 0.5,
    Flag = "",
    Callback = function(num)
        _G.env.values.SpeedHack = num
    end
}
Sections.Client.Player:Toggle {
    Name = "Speedhack",
    Default = false,
    Callback = function(state)
        _G.env.states.SpeedHack = state
    end
}

Sections.Client.Player:Toggle {
    Name = "Infinite jump",
    Default = false,
    Callback = function(state)
        _G.env.states.InfJump = state
    end
}



--// World
Sections.World.Esp:Toggle {
    Name = "Enable enemy",
    Default = false,
    Callback = function(state)
        _G.env.states.EnemyEsp = state
    end
}
Sections.World.Esp:Toggle {
    Name = "Enable friendly",
    Default = false,
    Callback = function(state)
        _G.env.states.FriendlyEsp = state
    end
}
Sections.World.Esp:Seperator("Friendly Settings")
Sections.World.Esp:Toggle {
    Name = "Name",
    Default = false,
    Callback = function(state)
        _G.env.values.Esp.Friendly.Name = state
    end
}
Sections.World.Esp:Toggle {
    Name = "Distance",
    Default = false,
    Callback = function(state)
        _G.env.values.Esp.Friendly.Distance = state
    end
}
Sections.World.Esp:Toggle {
    Name = "Box",
    Default = false,
    Callback = function(state)
        _G.env.values.Esp.Friendly.Box = state
    end
}


Sections.World.Esp:Seperator("Enemy Settings")
Sections.World.Esp:Toggle {
    Name = "Name",
    Default = false,
    Callback = function(state)
        _G.env.values.Esp.Enemy.Name = state
    end
}
Sections.World.Esp:Toggle {
    Name = "Distance",
    Default = false,
    Callback = function(state)
        _G.env.values.Esp.Enemy.Distance = state
    end
}
Sections.World.Esp:Toggle {
    Name = "Box",
    Default = false,
    Callback = function(state)
        _G.env.values.Esp.Enemy.Box = state
    end
}



--// Hitbox
Sections.Client.Hitbox:Slider {
    Text = "Scale",
    Default = 2,
    Min = 2,
    Max = 20,
    Float = 0.5,
    Flag = "",
    Callback = function(num)
        _G.env.values.Hitbox.Size = num
    end
}
Sections.Client.Hitbox:Slider {
    Text = "Transparency",
    Default = 1,
    Min = 0.100,
    Max = 1,
    Float = 0.100,
    Flag = "",
    Callback = function(num)
        _G.env.values.Hitbox.Transparency = num
    end
}
Sections.Client.Hitbox:ColorPicker {
    Name = "Color",
    Default = _G.env.values.Hitbox.Color,
    Flag = "",
    Callback = function(color)
        _G.env.values.Hitbox.Color = color
    end
}
Sections.Client.Hitbox:Toggle {
    Name = "Rainbow",
    Default = false,
    Callback = function(state)
        _G.env.states.RgbHitbox = state
    end
}
Sections.Client.Hitbox:Toggle {
    Name = "Enable",
    Default = false,
    Callback = function(state)
        _G.env.states.Hitbox = state
    end
}



--// Aimbot
Sections.Client.Aimbot:Seperator("Legit")
Sections.Client.Aimbot:Toggle {
    Name = "Enabled",
    Flag = "",
    Default = false,
    Callback = function(state)
        _G.env.states.Aimbot = state
    end
}


Sections.Client.Aimbot:Seperator("Rage")
Sections.Client.Aimbot:Toggle {
    Name = "Silent aim",
    Flag = "",
    Default = false,
    Callback = function(state)
        _G.env.states.SilentAim = state
    end
}
Sections.Client.Aimbot:Toggle {
    Name = "Wallcheck",
    Flag = "",
    Default = false,
    Callback = function(state)
        _G.env.states.WallCheck = state
    end
}

Sections.Client.Aimbot:Toggle {
    Name = "Auto kill all",
    Flag = "",
    Default = false,
    Callback = function(state)
        _G.env.states.KillAll = state
    end
}



--// Perks
Sections.Misc.Perks:Button {
    Name = "Fling",
    Callback = function()
        --
    end
}


--// Fun
Sections.Misc.Fun:Seperator("Stand teleport")
Sections.Misc.Fun:Dropdown {
    Name = "Type",
    Default = "Classic",
    Content = {"Classic", "Duality"},
    Callback = function(option)
        _G.env.values.Stand.Type = option
    end
}

Sections.Misc.Fun:Toggle {
    Name = "Auto teleport to stand",
    Default = false,
    Flag = "",
    Callback = function(state)
        _G.env.values.Stand.Auto = state
    end
}

Sections.Misc.Fun:Button {
    Name = "Teleport to stand",
    Callback = function()
        local Stand = GetStandByType(_G.env.values.Stand.Type)
        Character:PivotTo(Stand:GetPivot() * CFrame.new(0, 5, 0))
    end
}


Sections.Misc.Fun:Seperator("Player teleport")

SecElement.Misc.PLD = Sections.Misc.Fun:Dropdown {
    Content = (function()
        local list = {}

        for _, v in next, Players:GetPlayers() do
            if v.Name  == Player.Name then
                continue
            end
            list[table.maxn(list) + 1] = v.Name
        end

        return list
    end)(),
    Scrollable = true,
    Flag = "",
    Callback = function(option)
        _G.env.values.Teleport.Target = option
        if _G.env.values.Teleport.Auto then
            local Target = Players:FindFirstChild(_G.env.values.Teleport.Target)
            local Char = (Target and Target.Character)
        

            if ((Target and Target ~= Player) and Char) then
                Character:PivotTo(Char:GetPivot())
            end
        end
    end
}
Sections.Misc.Fun:Toggle {
    Name = "Auto teleport to player",
    Flag = "",
    Default = false,
    Callback = function(state)
        _G.env.values.Teleport.Auto = state
    end
}

Sections.Misc.Fun:Button {
    Name = "Teleport to player",
    Callback = function()
        local Target = Players:FindFirstChild(_G.env.values.Teleport.Target)
        local Char = (Target and Target.Character)
        

        if ((Target and Target ~= Player) and Char) then
            Character:PivotTo(Char:GetPivot())
        end
    end
}



--// Settings misc
Sections.Misc.Settings:Keybind {
    Default = Enum.KeyCode.LeftAlt,
    Blacklist = {
        Enum.UserInputType.MouseButton1
    },
    Flag = "",
    Mode = "Toggle",
    Callback = function(...)
        UILib:Close()
    end
}
Sections.Misc.Settings:Button {
    Name = "Unload",
    Callback = function()
        UILib:Unload()
        if _G.Draw then
            for _, v in next, _G.Draw.drawed do
                v:Destroy()
            end
            table.clear(_G.Draw)
            _G.Draw = nil
        end
        if _G.env then
            for _, signal in next, _G.env.signals do
                signal:Disconnect()
            end
            table.clear(_G.env)
            _G.env = nil
        end
    end
}


--// Credits
Sections.Credits.Information:Label("Change Logs:")
Sections.Credits.Information:Label("-- Coming Soon ...")
Sections.Credits.Information:Button {
    Name = "Discord",
    Callback = function()
        setclipboard("https://discord.gg/Yy3VqbTJ")
    end
}

Sections.Credits.Developers:Button {
    Name = "fedpal | Motivational wall",
    Callback = function()
        setclipboard("fedpal")
    end
}
Sections.Credits.Developers:Button {
    Name = "itspenguin. | Someone who helped",
    Callback = function()
        setclipboard("itspenguin.")
    end
}


--// Loops
table.insert(_G.env.signals, UserInputService.JumpRequest:Connect(function()
    if _G.env.states.InfJump then
        Character = Player.Character
        Humanoid = Character:FindFirstChild("Humanoid")
        if Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))
table.insert(_G.env.signals, Players.PlayerAdded:Connect(function(p)
    SecElement.Misc.PLD:Add(p.Name)
end))
table.insert(_G.env.signals, Players.PlayerRemoving:Connect(function(p)
    SecElement.Misc.PLD:Remove(p.Name)
end))
table.insert(_G.env.signals, RunService.Heartbeat:Connect(function()
    if _G.env.states.Aimbot then
        for _, v in next, workspace:GetChildren() do
            local plr = v:IsA("Model") and Players:GetPlayerFromCharacter(v)

            if not plr then continue end
            if plr == Player then continue end
            if plr.Team == Player then continue end
            if (not v.Humanoid or v.Humanoid.Health <= 0) then
                if plr.Name == _G.env.values.Aimbot.Target then
                    _G.env.values.Aimbot.Target = ""
                end
                continue
            end

            _G.env.values.Aimbot.Target = plr.Name
            local position, inViewport = Camera:WorldToViewportPoint(v:GetPivot().p)

            
            if (inViewport and #_G.env.values.Aimbot.Target > 0) then
                if _G.env.states.WallCheck then
                if (Mouse.Target and Mouse.Target:FindFirstAncestor(v.Name)) then
                        mousemoveabs(position.X, position.Y)
                end
        
                else
                    if not _G.env.states.WallCheck then
                        mousemoveabs(position.X, position.Y)
                    end
                end
            end
        end
    
    end

    if _G.env.states.SilentAim then
        for _, v in next, workspace:GetChildren() do
            local plr = v:IsA("Model") and Players:GetPlayerFromCharacter(v)

            if not plr then continue end
            if plr == Player then continue end
            if plr.Team == Player then continue end
            if (not v.Humanoid or v.Humanoid.Health <= 0) then
                if plr.Name == _G.env.values.Aimbot.Target then
                    _G.env.values.Aimbot.Target = ""
                end
                continue
            end

            _G.env.values.Aimbot.Target = plr.Name
            local position, inViewport = Camera:WorldToViewportPoint(v:GetPivot().p)

            
            if (inViewport and #_G.env.values.Aimbot.Target > 0) then
                if _G.env.states.WallCheck then
                if (Mouse.Target and Mouse.Target:FindFirstAncestor(v.Name)) then
                        mousemoveabs(position.X, position.Y)
                        Shoot:FireServer(
                            position,
                            position,
                            v.PrimaryPart,
                            position
                        )
                end
                else
                    if not _G.env.states.WallCheck then
                        mousemoveabs(position.X, position.Y)
                        Shoot:FireServer(
                            position,
                            position,
                            v.PrimaryPart,
                            position
                        )
                    end
                end
            end
        end
    end

    if _G.env.states.KillAll then
        for _, v in next, workspace:GetChildren() do
            local plr = v:IsA("Model") and Players:GetPlayerFromCharacter(v)

            if not plr then continue end
            if plr == Player then continue end
            if plr.Team == Player then continue end

            for _, v in next, Backpack:GetChildren() do
                local ref = v:GetAttribute("ActivatedAnimation")
                if ref == "Shoot" then
                    Humanoid:EquipTool(v)
                end
            end

            Shoot:FireServer(
                v:GetPivot().p,
                v:GetPivot().p,
                v.PrimaryPart,
                v:GetPivot().p
            )
        end
    end

    if _G.env.states.Hitbox then
        for _, v in next, workspace:GetChildren() do
            local plr = v:IsA("Model") and Players:GetPlayerFromCharacter(v)

            if not plr then continue end
            if plr == Player then continue end
            if plr.Team == Player then continue end

            v.PrimaryPart.Size = Vector3.new(
                _G.env.values.Hitbox.Size,
                _G.env.values.Hitbox.Size,
                _G.env.values.Hitbox.Size
            )
            v.PrimaryPart.Transparency = _G.env.values.Hitbox.Transparency
            v.PrimaryPart.Color = if _G.env.states.RgbHitbox then Color3.fromHSV(tick() % 5 / 5, 1, 1) else _G.env.values.Hitbox.Color
        end
    end
end))


--// Initialize default
UILib:Close()
Watermark:Hide()
