-- Heli-Taxi Phone App Client
local QBCore = exports['qb-core']:GetCoreObject()
local lastCallTime = 0
local callCooldown = 60000 -- 60 seconds cooldown
local currentDestination = nil

-- Register phone app data callback
RegisterNUICallback('heli-taxi:getAppData', function(data, cb)
    QBCore.Functions.TriggerCallback('heli-taxi:server:getPhoneAppData', function(appData)
        -- Add current destination info for employees
        if appData.isEmployee and currentDestination then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - 
                             vector3(currentDestination.coords.x, currentDestination.coords.y, currentDestination.coords.z))
            
            appData.destination = {
                playerName = currentDestination.playerName,
                distance = math.floor(distance) .. 'm'
            }
        end
        
        cb(appData)
    end)
end)

-- Handle taxi call request
RegisterNUICallback('heli-taxi:callTaxi', function(data, cb)
    local currentTime = GetGameTimer()
    
    if currentTime - lastCallTime < callCooldown then
        local remainingTime = math.ceil((callCooldown - (currentTime - lastCallTime)) / 1000)
        QBCore.Functions.Notify('Bitte warten Sie noch ' .. remainingTime .. ' Sekunden', 'error')
        cb({ success = false, message = 'Cooldown aktiv' })
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local playerData = QBCore.Functions.GetPlayerData()
    
    TriggerServerEvent('heli-taxi:server:requestPickup', {
        coords = coords,
        playerName = playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    })
    
    lastCallTime = currentTime
    QBCore.Functions.Notify('Taxi-Anfrage gesendet! Ein Mitarbeiter wird Sie abholen.', 'success')
    
    cb({ success = true, message = 'Anfrage gesendet' })
end)

-- Receive pickup notification (for employees)
RegisterNetEvent('heli-taxi:client:receivePickupRequest', function(data)
    -- Store current destination
    currentDestination = data
    
    -- Notify employee
    QBCore.Functions.Notify('📱 Taxi-Anfrage: ' .. data.playerName .. ' benötigt Abholung!', 'primary', 8000)
    
    -- Set GPS waypoint to pickup location
    SetNewWaypoint(data.coords.x, data.coords.y)
    
    -- Create blip on map
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, 64) -- Helicopter blip
    SetBlipColour(blip, 5) -- Yellow
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🚁 Taxi-Abholung")
    EndTextCommandSetBlipName(blip)
    
    -- Remove blip after 5 minutes
    SetTimeout(300000, function()
        RemoveBlip(blip)
        currentDestination = nil
    end)
end)

-- Accept pickup from phone
RegisterNUICallback('heli-taxi:acceptPickup', function(data, cb)
    if currentDestination then
        QBCore.Functions.Notify('Auftrag angenommen! GPS-Ziel aktiv.', 'success')
        cb({ success = true })
    else
        cb({ success = false, message = 'Kein aktiver Auftrag' })
    end
end)

-- Cancel pickup from phone
RegisterNUICallback('heli-taxi:cancelPickup', function(data, cb)
    if currentDestination then
        currentDestination = nil
        QBCore.Functions.Notify('Auftrag abgelehnt.', 'error')
        cb({ success = true })
    else
        cb({ success = false, message = 'Kein aktiver Auftrag' })
    end
end)

print('[Heli-Taxi] Phone app client loaded')
