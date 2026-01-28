-- Client Framework Integration
Framework = {}
Framework.Type = nil
Framework.Object = nil
Framework.PlayerData = {}

-- Locale helper
function _U(str, ...)
    -- Wait for Config and Locales to be loaded (increased timeout)
    local timeout = 0
    while (not Config or not Locales) and timeout < 10000 do
        Wait(10)
        timeout = timeout + 10
    end
    
    -- Debug: Log if timeout occurred
    if not Config or not Locales then
        print('[Heli-Taxi] WARNING: Locales not loaded after 10s - returning key: ' .. str)
        return str
    end
    
    -- Use configured locale or default to 'de'
    local locale = Config and Config.Locale or 'de'
    
    if Locales and Locales[locale] and Locales[locale][str] then
        return string.format(Locales[locale][str], ...)
    end
    
    -- Fallback to English
    if Locales and Locales['en'] and Locales['en'][str] then
        return string.format(Locales['en'][str], ...)
    end
    
    -- Final fallback: return the key itself
    return str
end

-- Initialize Framework
CreateThread(function()
    -- Wait for config
    while not Config do
        Wait(100)
    end
    
    if Config.Framework == 'auto' then
        -- Auto-detect framework
        if GetResourceState('es_extended') == 'started' then
            Config.Framework = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            Config.Framework = 'qb-core'
        else
            Config.Framework = 'standalone'
        end
    end
    
    Framework.Type = Config.Framework
    
    if Framework.Type == 'esx' then
        Framework.Object = exports['es_extended']:getSharedObject()
        
        RegisterNetEvent('esx:playerLoaded', function(xPlayer)
            Framework.PlayerData = xPlayer
            -- Refresh employee status when player loads
            Wait(2000)
            TriggerServerEvent('heli-taxi:server:getEmployeeInfo')
        end)
        
        RegisterNetEvent('esx:setJob', function(job)
            Framework.PlayerData.job = job
            -- Refresh employee status when job changes
            TriggerServerEvent('heli-taxi:server:getEmployeeInfo')
        end)
        
        print('[Heli-Taxi] ESX Framework detected')
    elseif Framework.Type == 'qb-core' then
        Framework.Object = exports['qb-core']:GetCoreObject()
        
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            Framework.PlayerData = Framework.Object.Functions.GetPlayerData()
            -- Refresh employee status when player loads
            Wait(2000)
            TriggerServerEvent('heli-taxi:server:getEmployeeInfo')
        end)
        
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            Framework.PlayerData.job = job
            -- Refresh employee status when job changes
            TriggerServerEvent('heli-taxi:server:getEmployeeInfo')
        end)
        
        print('[Heli-Taxi] QB-Core Framework detected')
    else
        print('[Heli-Taxi] Running in Standalone mode')
    end
end)

-- Notify
function Framework.Notify(message, type, duration)
    if Framework.Type == 'esx' then
        Framework.Object.ShowNotification(message)
    elseif Framework.Type == 'qb-core' then
        Framework.Object.Functions.Notify(message, type or 'primary', duration or 5000)
    else
        -- Standalone notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- Show Help Notification with modern styling
function Framework.ShowHelpNotification(message)
    -- Always use native GTA help text with better formatting
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Hide Help Notification
function Framework.HideHelpNotification()
    -- Clear help text immediately
    if IsHelpMessageBeingDisplayed() then
        ClearAllHelpMessages()
    end
end

-- Get Player Data
function Framework.GetPlayerData()
    if Framework.Type == 'esx' then
        return Framework.Object.GetPlayerData()
    elseif Framework.Type == 'qb-core' then
        return Framework.Object.Functions.GetPlayerData()
    else
        return Framework.PlayerData
    end
end

-- Standalone notification handler
RegisterNetEvent('heli-taxi:notify', function(message, type)
    Framework.Notify(message, type)
end)
