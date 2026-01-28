-- Flight Management System
local ActiveFlights = {}

-- Start Flight
RegisterNetEvent('heli-taxi:server:startFlight', function(vehiclePlate, vehicleModel)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not IsEmployee(identifier) then
        Framework.Notify(src, 'You are not an employee', 'error')
        return
    end
    
    local emp = GetEmployee(identifier)
    if emp.status ~= 'on_duty' then
        Framework.Notify(src, 'You must be on duty to start a flight', 'error')
        return
    end
    
    -- Initialize flight data
    ActiveFlights[identifier] = {
        pilot = identifier,
        pilotName = emp.name,
        vehiclePlate = vehiclePlate,
        vehicleModel = vehicleModel,
        startTime = os.time(),
        startLocation = nil, -- Will be set by client
        distance = 0.0,
        cost = Config.Pricing.flatFee, -- Start with flat fee
        fuelConsumed = 0.0
    }
    
    Framework.Notify(src, 'Flight started - Flat fee: $' .. Config.Pricing.flatFee, 'primary')
    TriggerClientEvent('heli-taxi:client:flightStarted', src, ActiveFlights[identifier])
end)

-- Update Flight Data
RegisterNetEvent('heli-taxi:server:updateFlight', function(distance, fuelConsumed)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not ActiveFlights[identifier] then return end
    
    local flight = ActiveFlights[identifier]
    flight.distance = distance
    flight.fuelConsumed = fuelConsumed
    
    -- Calculate cost: flat fee + (distance in km * price per km)
    local distanceInKm = distance / 1000
    flight.cost = Config.Pricing.flatFee + math.floor(distanceInKm * Config.Pricing.perKilometer)
    
    -- Send update to client
    TriggerClientEvent('heli-taxi:client:flightUpdate', src, {
        distance = distanceInKm,
        cost = flight.cost,
        duration = os.time() - flight.startTime,
        fuelConsumed = fuelConsumed
    })
end)

-- End Flight
RegisterNetEvent('heli-taxi:server:endFlight', function(endLocation, passengerRating, tipAmount)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not ActiveFlights[identifier] then
        Framework.Notify(src, 'No active flight found', 'error')
        return
    end
    
    local flight = ActiveFlights[identifier]
    local duration = os.time() - flight.startTime
    local distanceInKm = flight.distance / 1000
    
    -- Ensure minimum charge
    if flight.cost < Config.Pricing.minimumCharge then
        flight.cost = Config.Pricing.minimumCharge
    end
    
    -- Add tip to cost
    local totalEarned = flight.cost + (tipAmount or 0)
    
    -- Save flight to database
    MySQL.insert([[
        INSERT INTO heli_taxi_flights 
        (pilot_identifier, pilot_name, vehicle_model, vehicle_plate, distance, duration, cost, fuel_consumed, passenger_rating, tip_amount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        flight.pilot,
        flight.pilotName,
        flight.vehicleModel,
        flight.vehiclePlate,
        distanceInKm,
        duration,
        flight.cost,
        flight.fuelConsumed,
        passengerRating or 0,
        tipAmount or 0
    })
    
    -- Update company income
    MySQL.update('UPDATE heli_taxi_company SET balance = balance + ?, total_income = total_income + ?',
        {totalEarned, totalEarned})
    
    -- Update employee stats
    MySQL.update([[
        UPDATE heli_taxi_employees 
        SET total_flights = total_flights + 1, 
            total_distance = total_distance + ?, 
            total_earned = total_earned + ?
        WHERE identifier = ?
    ]], {distanceInKm, totalEarned, identifier})
    
    -- Update vehicle stats
    MySQL.update([[
        UPDATE heli_taxi_vehicles 
        SET total_flights = total_flights + 1,
            total_distance = total_distance + ?,
            last_used = NOW()
        WHERE plate = ?
    ]], {distanceInKm, flight.vehiclePlate})
    
    -- Log transaction
    MySQL.insert([[
        INSERT INTO heli_taxi_transactions 
        (transaction_type, amount, description, performer_identifier, performer_name)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        'income',
        totalEarned,
        string.format('Flight income - %.2f km - %s', distanceInKm, flight.vehicleModel),
        identifier,
        flight.pilotName
    })
    
    -- Update employee cache
    if Employees[identifier] then
        Employees[identifier].total_flights = (Employees[identifier].total_flights or 0) + 1
        Employees[identifier].total_distance = (Employees[identifier].total_distance or 0) + distanceInKm
        Employees[identifier].total_earned = (Employees[identifier].total_earned or 0) + totalEarned
    end
    
    -- Clear active flight
    ActiveFlights[identifier] = nil
    
    -- Notify player
    Framework.Notify(src, string.format('Flight completed! Distance: %.2f km, Earned: $%d', distanceInKm, totalEarned), 'success')
    TriggerClientEvent('heli-taxi:client:flightEnded', src, {
        distance = distanceInKm,
        duration = duration,
        cost = flight.cost,
        tip = tipAmount or 0,
        total = totalEarned,
        rating = passengerRating or 0
    })
end)

-- Cancel Flight
RegisterNetEvent('heli-taxi:server:cancelFlight', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if ActiveFlights[identifier] then
        ActiveFlights[identifier] = nil
        Framework.Notify(src, 'Flight cancelled', 'primary')
        TriggerClientEvent('heli-taxi:client:flightCancelled', src)
    end
end)

-- Get Flight History
RegisterNetEvent('heli-taxi:server:getFlightHistory', function(limit)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    local queryLimit = limit or 50
    
    MySQL.query([[
        SELECT * FROM heli_taxi_flights 
        WHERE pilot_identifier = ? 
        ORDER BY flight_date DESC 
        LIMIT ?
    ]], {identifier, queryLimit}, function(flights)
        TriggerClientEvent('heli-taxi:client:receiveFlightHistory', src, flights or {})
    end)
end)

-- Get Company Flight History (Boss only)
RegisterNetEvent('heli-taxi:server:getCompanyFlightHistory', function(limit)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'view_stats') then
        Framework.Notify(src, 'You do not have permission', 'error')
        return
    end
    
    local queryLimit = limit or 100
    
    MySQL.query([[
        SELECT * FROM heli_taxi_flights 
        ORDER BY flight_date DESC 
        LIMIT ?
    ]], {queryLimit}, function(flights)
        TriggerClientEvent('heli-taxi:client:receiveFlightHistory', src, flights or {})
    end)
end)
