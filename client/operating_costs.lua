--[[
    🚁 Heli-Taxi - Betriebskosten Client
]]

local costRequests = {}

--[[
    Betriebskosten anfordern
]]
RegisterNUICallback('requestOperatingCosts', function(data, cb)
    TriggerServerEvent('heli_taxi:requestOperatingCosts', data)
    cb('ok')
end)

--[[
    Betriebskosten genehmigen
]]
RegisterNUICallback('approveOperatingCosts', function(data, cb)
    if data.requestId then
        TriggerServerEvent('heli_taxi:approveOperatingCosts', data.requestId)
    end
    cb('ok')
end)

--[[
    Betriebskosten ablehnen
]]
RegisterNUICallback('declineOperatingCosts', function(data, cb)
    if data.requestId then
        TriggerServerEvent('heli_taxi:declineOperatingCosts', data.requestId)
    end
    cb('ok')
end)

--[[
    Offene Anfragen abrufen
]]
RegisterNUICallback('getOperatingCostRequests', function(data, cb)
    TriggerServerEvent('heli_taxi:getOperatingCostRequests')
    cb('ok')
end)

--[[
    Empfange Anfragen-Liste
]]
RegisterNetEvent('heli_taxi:receiveOperatingCostRequests', function(requests)
    costRequests = requests
    SendNUIMessage({
        action = 'updateCostRequests',
        requests = requests
    })
end)

--[[
    Neue Anfrage Benachrichtigung
]]
RegisterNetEvent('heli_taxi:showCostRequest', function(request)
    SendNUIMessage({
        action = 'showCostRequestNotification',
        request = request
    })
end)

print('[Heli-Taxi] Operating Costs client loaded')
