--[[
    🚁 Heli-Taxi - Betriebskosten-System (Operating Costs)
    Server-Side Logic
]]

-- Aktive Anfragen speichern
local operatingCostRequests = {}
local requestIdCounter = 0

--[[
    Betriebskosten-Anfrage erstellen
]]
RegisterNetEvent('heli_taxi:requestOperatingCosts', function(data)
    local source = source
    
    -- Validierung
    if not data or not data.type or not data.amount or not data.reason then
        Framework.ShowNotification(source, _U('invalid_request'))
        return
    end
    
    -- Betrag validieren
    local amount = tonumber(data.amount)
    if not amount or amount <= 0 or amount > Config.MaxOperatingCostRequest then
        Framework.ShowNotification(source, _U('invalid_amount'))
        return
    end
    
    -- Mitarbeiter-Check
    if not IsEmployee(source) then
        Framework.ShowNotification(source, _U('not_employee'))
        return
    end
    
    -- Request ID generieren
    requestIdCounter = requestIdCounter + 1
    local requestId = requestIdCounter
    
    -- Request speichern
    operatingCostRequests[requestId] = {
        id = requestId,
        employeeId = Framework.GetIdentifier(source),
        employeeName = Framework.GetPlayerName(source),
        type = data.type,
        amount = amount,
        reason = data.reason,
        timestamp = os.time()
    }
    
    -- Antragsteller benachrichtigen
    Framework.ShowNotification(source, _U('operating_cost_requested', amount))
    
    -- Alle Chefs benachrichtigen
    notifyBosses(requestId)
    
    print(string.format('[Heli-Taxi] Operating cost request #%d: %s requested $%d for %s', 
        requestId, operatingCostRequests[requestId].employeeName, amount, data.type))
end)

--[[
    Benachrichtige alle Chefs über neue Anfrage
]]
function notifyBosses(requestId)
    local request = operatingCostRequests[requestId]
    if not request then return end
    
    local players = Framework.GetPlayers()
    for _, playerId in ipairs(players) do
        if HasPermission(playerId, 'approve_costs') then
            -- Benachrichtigung senden
            TriggerClientEvent('heli_taxi:showCostRequest', playerId, request)
            Framework.ShowNotification(playerId, _U('new_cost_request', request.employeeName, request.amount))
        end
    end
end

--[[
    Betriebskosten genehmigen
]]
RegisterNetEvent('heli_taxi:approveOperatingCosts', function(requestId)
    local source = source
    
    -- Permission Check
    if not HasPermission(source, 'approve_costs') then
        Framework.ShowNotification(source, _U('no_permission'))
        return
    end
    
    -- Request validieren
    local request = operatingCostRequests[requestId]
    if not request then
        Framework.ShowNotification(source, _U('request_not_found'))
        return
    end
    
    -- Firmen-Balance prüfen (mit Minus-Limit)
    local companyBalance = GetCompanyBalance()
    if companyBalance - request.amount < -Config.MaxCompanyDebt then
        Framework.ShowNotification(source, _U('company_debt_limit'))
        return
    end
    
    -- Employee finden (online oder offline)
    local employeeSource = Framework.GetPlayerByIdentifier(request.employeeId)
    
    -- Geld von Firma abziehen
    UpdateCompanyBalance(-request.amount)
    
    -- Geld an Employee geben
    if employeeSource then
        Framework.AddMoney(employeeSource, request.amount)
        Framework.ShowNotification(employeeSource, _U('operating_cost_approved', request.amount))
    end
    
    -- Transaktion loggen
    MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name, transaction_date) VALUES (?, ?, ?, ?, ?, ?)', {
        'operating_costs',
        -request.amount,
        string.format('Betriebskosten: %s - %s (%s)', request.type, request.employeeName, request.reason),
        request.employeeId,
        request.employeeName,
        os.date('%Y-%m-%d %H:%M:%S')
    })
    
    -- Genehmiger benachrichtigen
    Framework.ShowNotification(source, _U('cost_request_approved', request.employeeName, request.amount))
    
    -- Request entfernen
    operatingCostRequests[requestId] = nil
    
    -- Alle Chefs über Update informieren
    updateAllBossesRequestList()
    
    print(string.format('[Heli-Taxi] Operating cost request #%d approved by %s - $%d paid to %s', 
        requestId, Framework.GetPlayerName(source), request.amount, request.employeeName))
end)

--[[
    Betriebskosten ablehnen
]]
RegisterNetEvent('heli_taxi:declineOperatingCosts', function(requestId)
    local source = source
    
    -- Permission Check
    if not HasPermission(source, 'approve_costs') then
        Framework.ShowNotification(source, _U('no_permission'))
        return
    end
    
    -- Request validieren
    local request = operatingCostRequests[requestId]
    if not request then
        Framework.ShowNotification(source, _U('request_not_found'))
        return
    end
    
    -- Employee finden und benachrichtigen
    local employeeSource = Framework.GetPlayerByIdentifier(request.employeeId)
    if employeeSource then
        Framework.ShowNotification(employeeSource, _U('operating_cost_declined'))
    end
    
    -- Ablehner benachrichtigen
    Framework.ShowNotification(source, _U('cost_request_declined', request.employeeName))
    
    -- Request entfernen
    operatingCostRequests[requestId] = nil
    
    -- Alle Chefs über Update informieren
    updateAllBossesRequestList()
    
    print(string.format('[Heli-Taxi] Operating cost request #%d declined by %s', 
        requestId, Framework.GetPlayerName(source)))
end)

--[[
    Offene Anfragen abrufen
]]
RegisterNetEvent('heli_taxi:getOperatingCostRequests', function()
    local source = source
    
    if not HasPermission(source, 'approve_costs') then
        return
    end
    
    -- Konvertiere zu Array
    local requests = {}
    for _, request in pairs(operatingCostRequests) do
        table.insert(requests, request)
    end
    
    TriggerClientEvent('heli_taxi:receiveOperatingCostRequests', source, requests)
end)

--[[
    Alle Chefs über Änderungen informieren
]]
function updateAllBossesRequestList()
    local requests = {}
    for _, request in pairs(operatingCostRequests) do
        table.insert(requests, request)
    end
    
    local players = Framework.GetPlayers()
    for _, playerId in ipairs(players) do
        if HasPermission(playerId, 'approve_costs') then
            TriggerClientEvent('heli_taxi:receiveOperatingCostRequests', playerId, requests)
        end
    end
end

print('[Heli-Taxi] Operating Costs system loaded')
