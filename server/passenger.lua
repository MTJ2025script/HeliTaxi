--[[
    🚁 Heli-Taxi - Passagier-Taxi-System
    Server-Side Logic
    FIXED: Correct SQL column names (flight_date, transaction_type, transaction_date)
]]

-- Aktive Taxi-Fahrten
local activeTaxiRides = {}

--[[
    Check Passagier Status - Called when non-employee enters vehicle
]]
RegisterNetEvent('heli_taxi:checkPassengerStatus', function(driverServerId)
    local source = source
    
    -- Validierung
    if not driverServerId or not DoesPlayerExist(driverServerId) then
        return
    end
    
    -- Prüfe ob Passagier helitaxi Job hat
    if Framework.HasJob(source) then
        -- Ist Employee, kein Taxi nötig
        return
    end
    
    -- Prüfe ob Fahrer helitaxi Job hat
    if not Framework.HasJob(driverServerId) then
        -- Fahrer ist kein Employee, kein Taxi
        return
    end
    
    -- Dialog an Passagier senden
    TriggerClientEvent('heli_taxi:showPassengerDialog', source, {
        pilotId = driverServerId,
        pilotName = Framework.GetPlayerName(driverServerId),
        flatFee = Config.FlatFee,
        pricePerKm = Config.PricePerKm
    })
end)

--[[
    Passagier-Taxi-Anfrage senden (legacy)
]]
RegisterNetEvent('heli_taxi:notifyPassenger', function(passengerId, pilotName)
    local source = source
    
    -- Validierung
    if not passengerId or not DoesPlayerExist(passengerId) then
        return
    end
    
    -- Prüfe ob Passagier helitaxi Job hat
    if Framework.HasJob(passengerId) then
        -- Ist Employee, kein Taxi nötig
        return
    end
    
    -- Dialog an Passagier senden
    TriggerClientEvent('heli_taxi:showPassengerDialog', passengerId, {
        pilotId = source,
        pilotName = pilotName or Framework.GetPlayerName(source),
        flatFee = Config.FlatFee,
        pricePerKm = Config.PricePerKm
    })
    
    -- Pilot benachrichtigen
    Framework.Notify(source, _U('passenger_notified'))
end)

--[[
    Passagier akzeptiert Taxi
]]
RegisterNetEvent('heli_taxi:acceptTaxiRide', function(pilotId)
    local source = source
    
    -- Validierung
    if not pilotId or not DoesPlayerExist(pilotId) then
        Framework.Notify(source, _U('pilot_not_found'))
        return
    end
    
    -- Grundgebühr sofort abbuchen (auch wenn Spieler kein Geld hat!)
    local playerMoney = Framework.GetMoney(source)
    local amountToCharge = Config.FlatFee
    
    -- Buche Grundgebühr ab (Framework erlaubt Minus)
    Framework.RemoveMoney(source, amountToCharge)
    
    -- Prüfe ob Spieler jetzt im Minus ist
    local newBalance = Framework.GetMoney(source)
    local isInDebt = newBalance < 0
    
    -- Ride ID generieren
    local rideId = source .. '_' .. os.time()
    
    -- Speichere aktive Fahrt
    activeTaxiRides[rideId] = {
        id = rideId,
        passengerId = source,
        pilotId = pilotId,
        startTime = os.time(),
        flatFeePaid = true,
        totalDistance = 0,
        totalCost = Config.FlatFee
    }
    
    -- Passagier benachrichtigen
    if isInDebt then
        Framework.Notify(source, _U('taxi_accepted_debt', Config.FlatFee, newBalance))
    else
        Framework.Notify(source, _U('taxi_accepted', Config.FlatFee))
    end
    
    -- Pilot benachrichtigen
    Framework.Notify(pilotId, _U('passenger_accepted_taxi', GetPlayerName(source)))
    
    -- Beide Clients: Taxi-Flug starten
    TriggerClientEvent('heli_taxi:startTaxiRide', source, rideId, pilotId)
    TriggerClientEvent('heli_taxi:startTaxiRide', pilotId, rideId, source)
end)

--[[
    Passagier lehnt Taxi ab
]]
RegisterNetEvent('heli_taxi:declineTaxiRide', function(pilotId)
    local source = source
    
    -- Passagier benachrichtigen
    Framework.Notify(source, _U('taxi_declined'))
    
    -- Pilot benachrichtigen
    if pilotId and DoesPlayerExist(pilotId) then
        Framework.Notify(pilotId, _U('passenger_declined_taxi', GetPlayerName(source)))
    end
end)

--[[
    Taxi-Fahrt Update (Distanz)
]]
RegisterNetEvent('heli_taxi:updateTaxiRide', function(rideId, distance, totalCost)
    local source = source
    
    -- Ride validieren
    local ride = activeTaxiRides[rideId]
    if not ride then
        return
    end
    
    -- Nur Pilot oder Passagier darf updaten
    if source ~= ride.pilotId and source ~= ride.passengerId then
        return
    end
    
    -- Distance und totalCost updaten (totalCost includes distance + stationary charges from client)
    ride.totalDistance = distance
    ride.totalCost = totalCost or (Config.FlatFee + (distance * Config.PricePerKm))
    
    -- An beide Clients senden
    TriggerClientEvent('heli_taxi:updateRideInfo', ride.passengerId, ride)
    TriggerClientEvent('heli_taxi:updateRideInfo', ride.pilotId, ride)
end)

--[[
    Taxi-Fahrt beenden
]]
RegisterNetEvent('heli_taxi:endTaxiRide', function(rideId)
    local source = source
    
    -- Ride validieren
    local ride = activeTaxiRides[rideId]
    if not ride then
        return
    end
    
    -- Nur Pilot oder Passagier darf beenden
    if source ~= ride.pilotId and source ~= ride.passengerId then
        return
    end
    
    -- Finale Abrechnung - Use CURRENT totalCost (includes distance + stationary)
    -- ride.totalCost already calculated on client and sent via updates
    local totalCost = ride.totalCost
    local distanceCost = ride.totalDistance * Config.PricePerKm
    local duration = os.time() - ride.startTime
    
    -- Restbetrag vom Passagier abbuchen (Grundgebühr wurde schon abgebucht)
    -- Total minus flat fee = remaining amount
    local remainingCost = totalCost - Config.FlatFee
    if remainingCost > 0 then
        Framework.RemoveMoney(ride.passengerId, remainingCost)
    end
    
    -- Gesamtbetrag an Firmenkasse
    MySQL.query('UPDATE heli_taxi_company SET balance = balance + ?, total_income = total_income + ? LIMIT 1', {
        totalCost,
        totalCost
    }, function(affectedRows)
        if not affectedRows then
            print('[Heli-Taxi] Warning: Failed to update company balance for ride completion')
        end
    end)
    
    -- Prüfe Passagier-Kontostand
    local passengerBalance = Framework.GetMoney(ride.passengerId)
    local isInDebt = passengerBalance < 0
    
    -- Get pilot and passenger names
    local pilotName = GetPlayerName(ride.pilotId) or 'Unknown'
    local passengerName = GetPlayerName(ride.passengerId) or 'Unknown'
    local pilotIdentifier = Framework.GetIdentifier(ride.pilotId)
    
    -- Flug in DB speichern (FIXED: use correct column names - flight_date)
    MySQL.insert('INSERT INTO heli_taxi_flights (pilot_identifier, pilot_name, passenger_id, distance, cost, duration, flight_date) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        pilotIdentifier,
        pilotName,
        ride.passengerId,
        ride.totalDistance,
        totalCost,
        duration,
        os.date('%Y-%m-%d %H:%M:%S')
    })
    
    -- Transaktion loggen (FIXED: use correct column names - transaction_type, transaction_date)
    MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name, transaction_date) VALUES (?, ?, ?, ?, ?, ?)', {
        'taxi_ride',
        totalCost,
        string.format('Taxi-Flug - Passagier: %s, Pilot: %s (%.1f km)', 
            passengerName, 
            pilotName, 
            ride.totalDistance),
        pilotIdentifier,
        pilotName,
        os.date('%Y-%m-%d %H:%M:%S')
    })
    
    -- Rechnung an beide
    local invoice = {
        passengerId = ride.passengerId,
        pilotId = ride.pilotId,
        distance = ride.totalDistance,
        duration = duration,
        flatFee = Config.FlatFee,
        distanceCost = distanceCost,
        totalCost = totalCost,
        passengerBalance = passengerBalance,
        isInDebt = isInDebt
    }
    
    TriggerClientEvent('heli_taxi:showInvoice', ride.passengerId, invoice)
    TriggerClientEvent('heli_taxi:showInvoice', ride.pilotId, invoice)
    
    -- Benachrichtigungen
    if isInDebt then
        Framework.Notify(ride.passengerId, _U('ride_ended_debt', totalCost, passengerBalance))
    else
        Framework.Notify(ride.passengerId, _U('ride_ended', totalCost))
    end
    Framework.Notify(ride.pilotId, _U('ride_payment_received', totalCost))
    
    -- Ride entfernen
    activeTaxiRides[rideId] = nil
end)

--[[
    Cleanup bei Disconnect
]]
AddEventHandler('playerDropped', function()
    local source = source
    
    -- Prüfe ob Spieler in aktiver Ride war
    for rideId, ride in pairs(activeTaxiRides) do
        if ride.passengerId == source or ride.pilotId == source then
            -- Beende Fahrt automatisch
            TriggerEvent('heli_taxi:endTaxiRide', rideId)
            break
        end
    end
end)
