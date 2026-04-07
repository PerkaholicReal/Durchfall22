--[[
    Matcha Player Name Display Test
    Shows player names above their heads using Drawing API
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local SHOW_DISTANCE = 150  -- Max distance to show names
local UPDATE_RATE = 0.05   -- 20hz update
local TAG_Y_OFFSET = 2.5   -- Height above character

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
    
    -- Use head if available, otherwise HRP + offset
    if head then
        return head.Position
    elseif hrp then
        return hrp.Position + Vector3.new(0, TAG_Y_OFFSET, 0)
    end
    return nil
end

-- Update a single player's tag
local function updateTag(player, tag)
    -- Check if player is valid and not local player
    if not player or player == LocalPlayer then
        tag.Visible = false
        return
    end
    
    -- Get character and position
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
    
    -- Check distance
    local localChar = LocalPlayer.Character
    local localPos = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if localPos then
        local dist = (headPos - localPos.Position).Magnitude
        if dist > SHOW_DISTANCE then
            tag.Visible = false
            return
        end
    end
    
    -- World to screen
    local ok, screenPos, onScreen = pcall(WorldToScreen, headPos)
    if not ok or not onScreen then
        tag.Visible = false
        return
    end
    
    -- Update tag
    tag.Position = Vector2.new(screenPos.X, screenPos.Y - 25)  -- Above head
    tag.Text = player.Name
    
    -- Optional: Add display name or health indicator
    if player.DisplayName and player.DisplayName ~= player.Name then
        tag.Text = player.Name .. " (" .. player.DisplayName .. ")"
    end
    
    -- Color by team if available
    local team = player.Team
    if team and team.TeamColor then
        tag.Color = team.TeamColor.Color
    else
        tag.Color = Color3.fromRGB(255, 255, 255)
    end
    
    tag.Visible = true
end

-- Clean up tags for players that left
local function cleanup()
    for name, tag in pairs(PlayerTags) do
        if not activePlayers[name] then
            pcall(function() tag:Remove() end)
            PlayerTags[name] = nil
        end
    end
end

-- Main update loop
local running = true
local function mainLoop()
    while running do
        task.wait(UPDATE_RATE)
        
        -- Update active players list
        local currentPlayers = Players:GetPlayers()
        activePlayers = {}
        for _, player in ipairs(currentPlayers) do
            activePlayers[player.Name] = player
        end
        
        -- Create missing tags
        for _, player in ipairs(currentPlayers) do
            if player ~= LocalPlayer and not PlayerTags[player.Name] then
                PlayerTags[player.Name] = createTag(player.Name)
            end
        end
        
        -- Update all tags
        for name, player in pairs(activePlayers) do
            local tag = PlayerTags[name]
            if tag then
                updateTag(player, tag)
            end
        end
        
        -- Clean up
        cleanup()
    end
end

-- Handle player leaving
local function onPlayerRemoving(player)
    local tag = PlayerTags[player.Name]
    if tag then
        pcall(function() tag:Remove() end)
        PlayerTags[player.Name] = nil
    end
end

-- Handle character death (optional: flash name red briefly)
local function onCharacterAdded(player, character)
    local tag = PlayerTags[player.Name]
    if tag then
        tag.Color = Color3.fromRGB(255, 0, 0)
        task.spawn(function()
            task.wait(0.5)
            if tag and PlayerTags[player.Name] then
                local team = player.Team
                if team and team.TeamColor then
                    tag.Color = team.TeamColor.Color
                else
                    tag.Color = Color3.fromRGB(255, 255, 255)
                end
            end
        end)
    end
end

-- Connect events
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
end

-- Start the script
local success, err = pcall(mainLoop)
if not success then
    notify("Error in name display: " .. tostring(err), "Matcha Test", 5)
end

-- Cleanup on script stop (if you need to stop it)
-- running = false
