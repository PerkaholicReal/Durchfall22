loadstring([[
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Scan for nearby players every 5 seconds
task.spawn(function()
    while true do
        task.wait(5)
        
        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then continue end
        
        local localChar = LocalPlayer.Character
        if not localChar then continue end
        
        local localPos = localChar:FindFirstChild("HumanoidRootPart")
        if not localPos then continue end
        
        local nearby = {}
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dx = hrp.Position.X - localPos.Position.X
                        local dz = hrp.Position.Z - localPos.Position.Z
                        local dist = math.sqrt(dx*dx + dz*dz)
                        
                        -- Get health from stat folder (game-specific)
                        local health = "?"
                        local statFolder = player:FindFirstChild("stat")
                        if statFolder then
                            local healthVal = statFolder:FindFirstChild("health")
                            if healthVal then
                                health = tostring(healthVal.Value)
                            end
                        end
                        
                        if dist < 100 then
                            table.insert(nearby, player.Name .. " [HP:" .. health .. "] (" .. math.floor(dist) .. ")")
                        end
                    end
                end
            end
        end
        
        if #nearby > 0 then
            notify("Nearby: " .. table.concat(nearby, ", "), "Players", 4)
        end
    end
end)

-- Also show all players with their health on command (press H)
task.spawn(function()
    while true do
        task.wait(0.1)
        if iskeypressed(0x48) then  -- H key
            local playerList = {}
            for _, player in ipairs(Players:GetPlayers()) do
                local health = "?"
                local statFolder = player:FindFirstChild("stat")
                if statFolder then
                    local healthVal = statFolder:FindFirstChild("health")
                    if healthVal then
                        health = tostring(healthVal.Value)
                    end
                end
                table.insert(playerList, player.Name .. " [HP:" .. health .. "]")
            end
            notify(table.concat(playerList, ", "), "All Players (" .. #playerList .. ")", 5)
            task.wait(0.5)  -- debounce
        end
    end
end)

notify("Player scanner loaded! Shows nearby every 5s, press H for all players", "Matcha", 5)
]])()
