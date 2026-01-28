-- Heli-Taxi Phone App Server

-- Get phone app data
Framework.CreateCallback('heli-taxi:server:getPhoneAppData', function(source, cb)
    local Player = Framework.GetPlayer(source)
    local isEmployee = IsEmployee(Framework.GetIdentifier(source))
    
    local result = MySQL.query.await('SELECT * FROM heli_taxi_vehicles WHERE status = ?', {'available'})
    local availableVehicles = result and #result or 0
    
    local employees = MySQL.query.await('SELECT COUNT(*) as count FROM heli_taxi_employees')
    local totalEmployees = employees and employees[1] and employees[1].count or 0
    
    -- Count online employees
    local onlineEmployees = 0
    local players = Framework.GetPlayers()
    for _, playerId in ipairs(players) do
        if IsEmployee(Framework.GetIdentifier(playerId)) then
            onlineEmployees = onlineEmployees + 1
        end
    end
    
    cb({
        availableVehicles = availableVehicles,
        totalEmployees = totalEmployees,
        onlineEmployees = onlineEmployees,
        companyName = 'Heli-Taxi Service',
        isEmployee = isEmployee
    })
end)

-- Get employee positions for GPS tracking
Framework.CreateCallback('heli-taxi:server:getEmployeePositions', function(source, cb)
    local employees = {}
    local players = Framework.GetPlayers()
    
    for _, playerId in ipairs(players) do
        local identifier = Framework.GetIdentifier(playerId)
        if IsEmployee(identifier) then
            local ped = GetPlayerPed(playerId)
            local coords = GetEntityCoords(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            table.insert(employees, {
                source = playerId,
                name = Framework.GetPlayerName(playerId),
                coords = { x = coords.x, y = coords.y, z = coords.z },
                inVehicle = vehicle ~= 0
            })
        end
    end
    
    cb(employees)
end)

-- Handle pickup request
RegisterNetEvent('heli-taxi:server:requestPickup', function(data)
    local src = source
    local Player = Framework.GetPlayer(src)
    
    if not Player then return end
    
    -- Send notification to all online employees
    local players = Framework.GetPlayers()
    local sentToEmployees = 0
    
    for _, playerId in ipairs(players) do
        if IsEmployee(Framework.GetIdentifier(playerId)) then
            TriggerClientEvent('heli-taxi:client:receivePickupRequest', playerId, {
                coords = data.coords,
                playerName = data.playerName,
                requesterId = src
            })
            sentToEmployees = sentToEmployees + 1
        end
    end
    
    if sentToEmployees > 0 then
        print(string.format('[Heli-Taxi] Pickup request from %s sent to %d employees', data.playerName, sentToEmployees))
    else
        Framework.Notify(src, 'Momentan sind keine Mitarbeiter online', 'error')
    end
end)

print('[Heli-Taxi] Phone app server loaded')
