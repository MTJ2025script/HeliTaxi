-- Server-side script for HeliTaxi
-- Handles server events and synchronization

-- Optional ESX integration (commented out for standalone use)
--[[
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
]]--

RegisterServerEvent('helitaxi:requestTaxi')
AddEventHandler('helitaxi:requestTaxi', function(destination)
    local source = source
    
    -- Optional ESX player check (commented out for standalone)
    --[[
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end
    ]]--
    
    -- Calculate price based on distance (if needed)
    -- For now, just acknowledge the request
    TriggerClientEvent('helitaxi:taxiSpawned', source)
end)

RegisterServerEvent('helitaxi:payTaxi')
AddEventHandler('helitaxi:payTaxi', function(amount)
    local source = source
    
    -- Optional ESX payment handling (commented out for standalone)
    --[[
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end
    
    if xPlayer.getMoney() >= amount then
        xPlayer.removeMoney(amount)
        TriggerClientEvent('helitaxi:paymentSuccess', source)
    else
        TriggerClientEvent('helitaxi:paymentFailed', source)
    end
    ]]--
end)

-- Boss Menu System
RegisterServerEvent('helitaxi:requestBossMenuData')
AddEventHandler('helitaxi:requestBossMenuData', function()
    local source = source
    
    -- Check permissions (integrate with your framework)
    local hasPermission = true
    
    -- Optional ESX integration:
    --[[
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local job = xPlayer.getJob()
            hasPermission = job.name == Config.BossMenuPermission.jobName and job.grade >= Config.BossMenuPermission.minGrade
        else
            hasPermission = false
        end
    end
    ]]--
    
    -- Count actual HeliTaxi employees (if using framework)
    local employeeCount = 0
    --[[
    if ESX then
        local players = ESX.GetPlayers()
        for _, playerId in ipairs(players) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer and xPlayer.getJob().name == Config.BossMenuPermission.jobName then
                employeeCount = employeeCount + 1
            end
        end
    end
    ]]--
    
    -- For standalone, show total players or 0
    if employeeCount == 0 then
        employeeCount = 1  -- At least the person opening the menu
    end
    
    -- Gather data
    local data = {
        hasPermission = hasPermission,
        stats = {
            flights = 0,
            helicopters = 1,
            revenue = 0,
            employees = employeeCount
        },
        fleet = {
            {name = "Helicopter Alpha", status = "available", location = "Vespucci Helipad"}
        },
        employees = {},
        finances = {
            today = 0,
            week = 0,
            month = 0
        }
    }
    
    TriggerClientEvent('helitaxi:receiveBossMenuData', source, data)
end)

-- Handle legacy "illegal" boss menu requests
RegisterServerEvent('helitaxi:openIllegalBossMenu')
AddEventHandler('helitaxi:openIllegalBossMenu', function()
    local source = source
    print('^3[HeliTaxi]^7 Converting illegal boss menu request to legal management menu for player ' .. source)
    TriggerClientEvent('helitaxi:openBossMenu', source)
end)

-- Log script start
print('^2[HeliTaxi]^7 Server script loaded successfully')
print('^2[HeliTaxi]^7 Boss menu system initialized')
print('^2[HeliTaxi]^7 Use /helitaximenu command to open management interface')
