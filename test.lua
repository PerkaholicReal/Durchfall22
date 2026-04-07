--[[
    Matcha Player Name Display Test - COMPLETE FIXED SCRIPT
    Uses only confirmed working Matcha features
    Note: Drawing "Text" has known bug - if names don't render, use notify version below
]]

local Players = game:GetService("Players")

-- Configuration
local SHOW_DISTANCE = 150
local UPDATE_RATE = 0.05
local TAG_Y_OFFSET = 2.5

-- Drawing pool
local PlayerTags = {}
local activePlayers = {}

-- Create a name tag for a player
local function createTag(playerName)
    local text = Drawing.new("Text")
    text.Size = 14
    text.Font = Drawing.Fonts.SystemBold
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Center = true
    text.Visible = false
    return text
end

-- Get player's head position
local function getHeadPosition(player)
    local char = player.Character
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    if head then
        return head.Position
    elseif hrp then
        return hrp.Position + Vector3.new(0, TAG_Y_OFFSET, 0)
    end
    return nil
end

-- Update a single player's tag
local function updateTag(player, tag)
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        tag.Visible = false
        return
    end
    
    if not player or player == LocalPlayer then
        tag.Visible = false
        return
    end
    
    local char = player.Character
    if not char or not char.Parent then
        tag.Visible = false
        return
    end
    
    local headPos = getHeadPosition(player)
    if not headPos then
        tag.Visible = false
        return
    end
    
    local localChar = LocalPlayer.Character
    local localPos = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if localPos then
        local dx = headPos.X - localPos.Position.X
        local dy = headPos.Y - localPos.Position.Y
        local dz = headPos.Z - localPos.Position.Z
        local distSq = dx*dx + dy*dy + dz*dz
        if distSq > (SHOW_DISTANCE * SHOW_DISTANCE) then
            tag.Visible = false
            return
        end
    end
    
    local ok, screenPos, onScreen = pcall(WorldToScreen, headPos)
    if not ok or not onScreen then
        tag.Visible = false
        return
    end
    
    tag.Position = Vector2.new(math.floor(screenPos.X + 0.5), math.floor(screenPos.Y - 25 + 0.5))
    tag.Text = player.Name
    
    local okDisplay, displayName = pcall(function() return player.DisplayName end)
    if okDisplay and displayName and displayName ~= player.Name then
        tag.Text = player.Name .. " (" .. displayName .. ")"
    end
    
    local okTeam, team = pcall(function() return player.Team end)
    if okTeam and team then
        local okColor, teamColor = pcall(function() return team.TeamColor.Color end)
        if okColor and teamColor then
            tag.Color = teamColor
        else
            tag.Color = Color3.fromRGB(255, 255, 255)
        end
    else
        tag.Color = Color3.fromRGB(255, 255, 255)
    end
    
    tag.Visible = true
end

local function cleanup()
    for name, tag in pairs(PlayerTags) do
        if not activePlayers[name] then
            pcall(function() tag:Remove() end)
            PlayerTags[name] = nil
        end
    end
end

local running = true
task.spawn(function()
    while running do
        task.wait(UPDATE_RATE)
        
        local LocalPlayer = Players.LocalPlayer
        if LocalPlayer then
            local currentPlayers = Players:GetPlayers()
            activePlayers = {}
            for _, player in ipairs(currentPlayers) do
                activePlayers[player.Name] = player
            end
            
            for _, player in ipairs(currentPlayers) do
                if player ~= LocalPlayer and not PlayerTags[player.Name] then
                    PlayerTags[player.Name] = createTag(player.Name)
                end
            end
            
            for name, player in pairs(activePlayers) do
                local tag = PlayerTags[name]
                if tag then
                    updateTag(player, tag)
                end
            end
            
            cleanup()
        end
    end
end)

local function onPlayerRemoving(player)
    local tag = PlayerTags[player.Name]
    if tag then
        pcall(function() tag:Remove() end)
        PlayerTags[player.Name] = nil
    end
end

Players.PlayerRemoving:Connect(onPlayerRemoving)

notify("Player name display loaded - Drawing Text may be buggy in some Matcha versions", "Matcha", 4)
