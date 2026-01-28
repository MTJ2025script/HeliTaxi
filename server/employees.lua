-- Employee Management System

-- Hire Employee
RegisterNetEvent('heli-taxi:server:hireEmployee', function(targetSource)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local targetIdentifier = Framework.GetIdentifier(targetSource)
    
    if not HasPermission(identifier, 'hire', src) then
        Framework.Notify(src, 'You do not have permission to hire employees', 'error')
        return
    end
    
    if IsEmployee(targetIdentifier, targetSource) then
        Framework.Notify(src, 'This person is already an employee', 'error')
        return
    end
    
    local targetName = Framework.GetPlayerName(targetSource)
    local rank = 'junior_pilot'
    local salary = Config.Ranks[rank].salary
    
    MySQL.insert('INSERT INTO heli_taxi_employees (identifier, name, rank, salary) VALUES (?, ?, ?, ?)',
        {targetIdentifier, targetName, rank, salary}, function(insertId)
        if insertId then
            Employees[targetIdentifier] = {
                id = insertId,
                identifier = targetIdentifier,
                name = targetName,
                rank = rank,
                salary = salary,
                status = 'off_duty',
                total_flights = 0,
                total_distance = 0,
                total_earned = 0
            }
            
            Framework.Notify(src, 'You hired ' .. targetName .. ' as ' .. Config.Ranks[rank].label, 'success')
            Framework.Notify(targetSource, 'You have been hired by Heli-Taxi as ' .. Config.Ranks[rank].label, 'success')
            
            -- Log transaction
            MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                {'expense', 0, 'Hired ' .. targetName .. ' as ' .. Config.Ranks[rank].label, identifier, Framework.GetPlayerName(src)})
        end
    end)
end)

-- Fire Employee
RegisterNetEvent('heli-taxi:server:fireEmployee', function(targetIdentifier)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'fire', src) then
        Framework.Notify(src, 'You do not have permission to fire employees', 'error')
        return
    end
    
    if not IsEmployee(targetIdentifier, nil) then
        Framework.Notify(src, 'This person is not an employee', 'error')
        return
    end
    
    local targetName = Employees[targetIdentifier].name
    
    MySQL.query('DELETE FROM heli_taxi_employees WHERE identifier = ?', {targetIdentifier}, function(affectedRows)
        if affectedRows > 0 then
            Employees[targetIdentifier] = nil
            
            Framework.Notify(src, 'You fired ' .. targetName, 'success')
            
            -- Notify player if online
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework.GetIdentifier(tonumber(playerId))
                if playerIdentifier == targetIdentifier then
                    Framework.Notify(tonumber(playerId), 'You have been fired from Heli-Taxi', 'error')
                    TriggerClientEvent('heli-taxi:client:setDuty', tonumber(playerId), false)
                    break
                end
            end
            
            -- Log transaction
            MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                {'expense', 0, 'Fired ' .. targetName, identifier, Framework.GetPlayerName(src)})
        end
    end)
end)

-- Promote Employee
RegisterNetEvent('heli-taxi:server:promoteEmployee', function(targetIdentifier)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'promote', src) then
        Framework.Notify(src, 'You do not have permission to promote employees', 'error')
        return
    end
    
    if not IsEmployee(targetIdentifier, nil) then
        Framework.Notify(src, 'This person is not an employee', 'error')
        return
    end
    
    local emp = GetEmployee(targetIdentifier, nil)
    local currentRank = emp.rank
    local newRank = nil
    
    -- Determine next rank
    if currentRank == 'junior_pilot' then
        newRank = 'pilot'
    elseif currentRank == 'pilot' then
        newRank = 'assistant'
    elseif currentRank == 'assistant' then
        newRank = 'boss'
    else
        Framework.Notify(src, 'Employee is already at highest rank', 'error')
        return
    end
    
    local newSalary = Config.Ranks[newRank].salary
    
    MySQL.update('UPDATE heli_taxi_employees SET rank = ?, salary = ? WHERE identifier = ?',
        {newRank, newSalary, targetIdentifier}, function(affectedRows)
        if affectedRows > 0 then
            Employees[targetIdentifier].rank = newRank
            Employees[targetIdentifier].salary = newSalary
            
            Framework.Notify(src, 'You promoted ' .. emp.name .. ' to ' .. Config.Ranks[newRank].label, 'success')
            
            -- Notify player if online
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework.GetIdentifier(tonumber(playerId))
                if playerIdentifier == targetIdentifier then
                    Framework.Notify(tonumber(playerId), 'You have been promoted to ' .. Config.Ranks[newRank].label, 'success')
                    break
                end
            end
            
            -- Log transaction
            MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                {'expense', 0, 'Promoted ' .. emp.name .. ' to ' .. Config.Ranks[newRank].label, identifier, Framework.GetPlayerName(src)})
        end
    end)
end)

-- Set Employee Rank Directly (NEW! For Boss Menu rank selector)
RegisterNetEvent('heli-taxi:server:setEmployeeRank', function(targetIdentifier, newRank)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- Allow changing own rank OR have permission OR be boss
    local isSelf = (identifier == targetIdentifier)
    local currentRank = GetEmployeeRank(identifier, src)
    
    -- Boss can do EVERYTHING, no permission check needed
    if currentRank ~= 'boss' and not isSelf and not HasPermission(identifier, 'promote', src) and not HasPermission(identifier, 'demote', src) then
        Framework.Notify(src, 'Du hast keine Berechtigung Ränge zu setzen', 'error')
        return
    end
    
    -- When changing own rank or boss changing anyone, pass src as source; otherwise pass nil
    local targetSource = (isSelf or currentRank == 'boss') and src or nil
    if not IsEmployee(targetIdentifier, targetSource) then
        Framework.Notify(src, 'Diese Person ist kein Mitarbeiter', 'error')
        return
    end
    
    -- Validate rank exists in Config
    if not Config.Ranks[newRank] then
        Framework.Notify(src, 'Ungültiger Rang', 'error')
        return
    end
    
    local emp = GetEmployee(targetIdentifier, targetSource)
    local oldRank = emp.rank
    local newSalary = Config.Ranks[newRank].salary
    
    MySQL.update('UPDATE heli_taxi_employees SET rank = ?, salary = ? WHERE identifier = ?',
        {newRank, newSalary, targetIdentifier}, function(affectedRows)
        if affectedRows > 0 then
            Employees[targetIdentifier].rank = newRank
            Employees[targetIdentifier].salary = newSalary
            
            Framework.Notify(src, 'Rang von ' .. emp.name .. ' zu ' .. Config.Ranks[newRank].label .. ' geändert', 'success')
            
            -- Notify player if online
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework.GetIdentifier(tonumber(playerId))
                if playerIdentifier == targetIdentifier then
                    Framework.Notify(tonumber(playerId), 'Dein Rang wurde zu ' .. Config.Ranks[newRank].label .. ' geändert', 'success')
                    
                    -- If rank changed to/from illegal, respawn NPCs
                    if newRank == 'illegal' or oldRank == 'illegal' then
                        TriggerClientEvent('heli-taxi:client:respawnIllegalNPCs', tonumber(playerId))
                    end
                    break
                end
            end
            
            -- Log transaction
            MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                {'expense', 0, 'Rang von ' .. emp.name .. ' zu ' .. Config.Ranks[newRank].label .. ' geändert (vorher: ' .. Config.Ranks[oldRank].label .. ')', identifier, Framework.GetPlayerName(src)})
        end
    end)
end)

-- Demote Employee
RegisterNetEvent('heli-taxi:server:demoteEmployee', function(targetIdentifier)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'demote', src) then
        Framework.Notify(src, 'You do not have permission to demote employees', 'error')
        return
    end
    
    if not IsEmployee(targetIdentifier, nil) then
        Framework.Notify(src, 'This person is not an employee', 'error')
        return
    end
    
    local emp = GetEmployee(targetIdentifier, nil)
    local currentRank = emp.rank
    local newRank = nil
    
    -- Determine previous rank
    if currentRank == 'boss' then
        newRank = 'assistant'
    elseif currentRank == 'assistant' then
        newRank = 'pilot'
    elseif currentRank == 'pilot' then
        newRank = 'junior_pilot'
    else
        Framework.Notify(src, 'Employee is already at lowest rank', 'error')
        return
    end
    
    local newSalary = Config.Ranks[newRank].salary
    
    MySQL.update('UPDATE heli_taxi_employees SET rank = ?, salary = ? WHERE identifier = ?',
        {newRank, newSalary, targetIdentifier}, function(affectedRows)
        if affectedRows > 0 then
            Employees[targetIdentifier].rank = newRank
            Employees[targetIdentifier].salary = newSalary
            
            Framework.Notify(src, 'You demoted ' .. emp.name .. ' to ' .. Config.Ranks[newRank].label, 'success')
            
            -- Notify player if online
            for _, playerId in ipairs(GetPlayers()) do
                local playerIdentifier = Framework.GetIdentifier(tonumber(playerId))
                if playerIdentifier == targetIdentifier then
                    Framework.Notify(tonumber(playerId), 'You have been demoted to ' .. Config.Ranks[newRank].label, 'error')
                    break
                end
            end
            
            -- Log transaction
            MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                {'expense', 0, 'Demoted ' .. emp.name .. ' to ' .. Config.Ranks[newRank].label, identifier, Framework.GetPlayerName(src)})
        end
    end)
end)

-- Get Nearby Players (for hiring)
RegisterNetEvent('heli-taxi:server:getNearbyPlayers', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'hire', src) then
        Framework.Notify(src, 'You do not have permission', 'error')
        return
    end
    
    local players = {}
    local srcCoords = GetEntityCoords(GetPlayerPed(src))
    local maxPlayers = Config.MaxNearbyPlayers or 50 -- Use config or default to 50
    local count = 0
    
    for _, playerId in ipairs(GetPlayers()) do
        if count >= maxPlayers then break end
        
        local targetId = tonumber(playerId)
        if targetId ~= src then
            local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
            local distance = #(srcCoords - targetCoords)
            
            if distance < 5.0 then
                local targetIdentifier = Framework.GetIdentifier(targetId)
                table.insert(players, {
                    source = targetId,
                    name = Framework.GetPlayerName(targetId),
                    isEmployee = IsEmployee(targetIdentifier, targetId)
                })
                count = count + 1
            end
        end
    end
    
    TriggerClientEvent('heli-taxi:client:receiveNearbyPlayers', src, players)
end)
