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

-- Log script start
print('^2[HeliTaxi]^7 Server script loaded successfully')
