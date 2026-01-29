-- Framework Detection and Integration
Framework = {}
Framework.Type = nil
Framework.Object = nil

-- Locale helper
function _U(str, ...)
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

-- Detect Framework
CreateThread(function()
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
        print('[Heli-Taxi] ESX Framework detected and loaded')
    elseif Framework.Type == 'qb-core' then
        Framework.Object = exports['qb-core']:GetCoreObject()
        print('[Heli-Taxi] QB-Core Framework detected and loaded')
    else
        print('[Heli-Taxi] Running in Standalone mode')
    end
end)

-- Framework-agnostic CreateCallback wrapper
function Framework.CreateCallback(name, cb)
    if Framework.Type == 'qb-core' and Framework.Object then
        Framework.Object.Functions.CreateCallback(name, cb)
    elseif Framework.Type == 'esx' and Framework.Object then
        Framework.Object.RegisterServerCallback(name, cb)
    else
        -- Standalone fallback using RegisterNetEvent
        RegisterNetEvent(name, function(...)
            local source = source
            cb(source, ...)
        end)
    end
end

-- Check if player has the job
function Framework.HasJob(source)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        return xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        return Player and Player.PlayerData.job and Player.PlayerData.job.name == Config.JobName
    else
        return false -- Standalone uses internal employee system
    end
end

-- Get player job grade
function Framework.GetJobGrade(source)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        if xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName then
            return xPlayer.job.grade
        end
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        if Player and Player.PlayerData.job and Player.PlayerData.job.name == Config.JobName then
            return Player.PlayerData.job.grade.level
        end
    end
    return nil
end

-- Get job grade name from number AND check grade name from framework
function Framework.GetRankFromGrade(grade, source)
    print('[DEBUG-SERVER] ▶ GetRankFromGrade called: grade=' .. tostring(grade) .. ', source=' .. tostring(source))
    
    -- Try to get actual grade name from framework first
    if Framework.Type == 'qb-core' and source then
        local Player = Framework.Object.Functions.GetPlayer(source)
        if Player and Player.PlayerData.job and Player.PlayerData.job.name == Config.JobName then
            local gradeLevel = Player.PlayerData.job.grade.level
            local gradeName = Player.PlayerData.job.grade.name
            print('[DEBUG-SERVER]   └─ QB-Core Job: ' .. Player.PlayerData.job.name)
            print('[DEBUG-SERVER]   └─ Grade Level: ' .. tostring(gradeLevel))
            print('[DEBUG-SERVER]   └─ Grade Name: ' .. tostring(gradeName))
            
            -- Check if this grade name exists in our config
            if Config.Ranks and Config.Ranks[gradeName] then
                print('[DEBUG-SERVER]   └─ ✅ Using QB-Core grade name: ' .. gradeName)
                return gradeName
            else
                print('[DEBUG-SERVER]   └─ ❌ Grade name "' .. tostring(gradeName) .. '" not in Config.Ranks, using fallback')
            end
        end
    elseif Framework.Type == 'esx' and source then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        if xPlayer and xPlayer.job and xPlayer.job.name == Config.JobName then
            local gradeName = xPlayer.job.grade_name
            -- Check if this grade name exists in our config
            if Config.Ranks and Config.Ranks[gradeName] then
                print('[DEBUG-SERVER]   └─ ✅ Using ESX grade name: ' .. gradeName)
                return gradeName
            end
        end
    end
    
    -- Fallback to number-based lookup
    local ranks = {'junior_pilot', 'pilot', 'assistant', 'boss', 'illegal'}
    local rank = ranks[grade + 1] or 'junior_pilot'
    print('[DEBUG-SERVER]   └─ Fallback: grade ' .. tostring(grade) .. ' → array index ' .. tostring(grade + 1) .. ' → rank: ' .. rank)
    return rank
end

-- Get Player Identifier
function Framework.GetIdentifier(source)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    else
        -- Standalone - use license (cached lookup)
        local identifiers = GetPlayerIdentifiers(source)
        for _, id in pairs(identifiers) do
            if string.find(id, 'license:', 1, true) then
                return id
            end
        end
    end
    return nil
end

-- Get Player Name
function Framework.GetPlayerName(source)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        return xPlayer and xPlayer.getName() or GetPlayerName(source)
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        return Player and Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname or GetPlayerName(source)
    else
        return GetPlayerName(source)
    end
end

-- Add Money
function Framework.AddMoney(source, amount, account)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.addMoney(amount)
            return true
        end
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        if Player then
            Player.Functions.AddMoney('cash', amount)
            return true
        end
    else
        -- Standalone - would need custom implementation
        return true
    end
    return false
end

-- Remove Money
function Framework.RemoveMoney(source, amount, account)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        if xPlayer then
            if xPlayer.getMoney() >= amount then
                xPlayer.removeMoney(amount)
                return true
            end
        end
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        if Player then
            if Player.PlayerData.money.cash >= amount then
                Player.Functions.RemoveMoney('cash', amount)
                return true
            end
        end
    else
        return true
    end
    return false
end

-- Get Money
function Framework.GetMoney(source)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        return xPlayer and xPlayer.getMoney() or 0
    elseif Framework.Type == 'qb-core' then
        local Player = Framework.Object.Functions.GetPlayer(source)
        return Player and Player.PlayerData.money.cash or 0
    else
        return 0
    end
end

-- Notify Player
function Framework.Notify(source, message, type, duration)
    if Framework.Type == 'esx' then
        local xPlayer = Framework.Object.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.showNotification(message)
        end
    elseif Framework.Type == 'qb-core' then
        TriggerClientEvent('QBCore:Notify', source, message, type or 'primary', duration or 5000)
    else
        TriggerClientEvent('heli-taxi:notify', source, message, type or 'info')
    end
end
