-- Heli-Taxi Phone App Client
local QBCore = nil
local ESX = nil
local Framework = nil

-- Initialize framework
CreateThread(function()
    if GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        Framework = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    else
        Framework = 'standalone'
    end
end)

local lastCallTime = 0
local callCooldown = 60000 -- 60 seconds cooldown
local currentDestination = nil

-- Helper function to show notification
local function ShowNotification(message, type, duration)
    if Framework == 'qb-core' and QBCore then
        QBCore.Functions.Notify(message, type, duration)
    elseif Framework == 'esx' and ESX then
        ESX.ShowNotification(message)
    else
        -- Fallback to simple notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, true)
    end
end

-- Helper function to trigger callback
local function TriggerCallback(callbackName, cb, ...)
    if Framework == 'qb-core' and QBCore then
        QBCore.Functions.TriggerCallback(callbackName, cb, ...)
    elseif Framework == 'esx' and ESX then
        ESX.TriggerServerCallback(callbackName, cb, ...)
    else
        -- Fallback - just return empty data
        cb({})
    end
end

-- Helper function to get player data
local function GetPlayerName()
    if Framework == 'qb-core' and QBCore then
        local playerData = QBCore.Functions.GetPlayerData()
        return playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    elseif Framework == 'esx' and ESX then
        local playerData = ESX.GetPlayerData()
        return playerData.name or 'Unknown'
    else
        return 'Unknown'
    end
end

-- Register phone app data callback
RegisterNUICallback('heli-taxi:getAppData', function(data, cb)
    TriggerCallback('heli-taxi:server:getPhoneAppData', function(appData)
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
        ShowNotification('Bitte warten Sie noch ' .. remainingTime .. ' Sekunden', 'error')
        cb({ success = false, message = 'Cooldown aktiv' })
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local playerName = GetPlayerName()
    
    TriggerServerEvent('heli-taxi:server:requestPickup', {
        coords = coords,
        playerName = playerName
    })
    
    lastCallTime = currentTime
    ShowNotification('Taxi-Anfrage gesendet! Ein Mitarbeiter wird Sie abholen.', 'success', 8000)
    
    cb({ success = true, message = 'Anfrage gesendet' })
end)

-- Receive pickup notification (for employees)
RegisterNetEvent('heli-taxi:client:receivePickupRequest', function(data)
    -- Store current destination
    currentDestination = data
    
    -- Notify employee
    ShowNotification('📱 Taxi-Anfrage: ' .. data.playerName .. ' benötigt Abholung!', 'primary', 8000)
    
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
        ShowNotification('Auftrag angenommen! GPS-Ziel aktiv.', 'success')
        cb({ success = true })
    else
        cb({ success = false, message = 'Kein aktiver Auftrag' })
    end
end)

-- Cancel pickup from phone
RegisterNUICallback('heli-taxi:cancelPickup', function(data, cb)
    if currentDestination then
        currentDestination = nil
        ShowNotification('Auftrag abgelehnt.', 'error')
        cb({ success = true })
    else
        cb({ success = false, message = 'Kein aktiver Auftrag' })
    end
end)

print('[Heli-Taxi] Phone app client loaded')
