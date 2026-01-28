-- Flight Tracking and HUD
local inFlight = false
local flightData = {
    startTime = 0,
    startCoords = nil,
    distance = 0.0,
    cost = 0,
    fuelConsumed = 0.0,
    lastCoords = nil,
    startFuel = 0.0
}

-- Vehicle Entered
RegisterNetEvent('heli-taxi:client:vehicleEntered', function()
    local vehicle = GetCurrentVehicle()
    if not vehicle or not DoesEntityExist(vehicle) then return end
    
    local vehicleData = GetCurrentVehicleData()
    if not vehicleData then return end
    
    -- Initialize flight
    local playerPed = PlayerPedId()
    flightData.startTime = GetGameTimer()
    flightData.startCoords = GetEntityCoords(playerPed)
    flightData.lastCoords = flightData.startCoords
    flightData.distance = 0.0
    flightData.cost = Config.Pricing.flatFee
    flightData.startFuel = GetVehicleFuelLevel(vehicle)
    flightData.fuelConsumed = 0.0
    
    inFlight = true
    
    -- Notify server
    TriggerServerEvent('heli-taxi:server:startFlight', vehicleData.plate, vehicleData.model)
    
    -- Show HUD
    SendNUIMessage({
        action = 'showHUD',
        flatFee = Config.Pricing.flatFee
    })
end)

-- Vehicle Exited
RegisterNetEvent('heli-taxi:client:vehicleExited', function()
    if inFlight then
        -- End flight
        EndFlight()
    end
end)

-- Flight Started (from server)
RegisterNetEvent('heli-taxi:client:flightStarted', function(data)
    -- Flight confirmed by server
end)

-- Flight Update (from server)
RegisterNetEvent('heli-taxi:client:flightUpdate', function(data)
    SendNUIMessage({
        action = 'updateHUD',
        distance = data.distance,
        cost = data.cost,
        duration = data.duration,
        fuelConsumed = data.fuelConsumed
    })
end)

-- Flight Ended (from server)
RegisterNetEvent('heli-taxi:client:flightEnded', function(data)
    SendNUIMessage({
        action = 'hideHUD'
    })
    
    inFlight = false
    
    -- Show summary
    Framework.Notify(string.format('Flight Summary: %.2f km, Duration: %ds, Earned: $%d', 
        data.distance, data.duration, data.total), 'success')
end)

-- Flight Cancelled
RegisterNetEvent('heli-taxi:client:flightCancelled', function()
    SendNUIMessage({
        action = 'hideHUD'
    })
    
    inFlight = false
end)

-- End Flight
function EndFlight()
    if not inFlight then return end
    
    local playerPed = PlayerPedId()
    local currentCoords = GetEntityCoords(playerPed)
    
    local vehicle = GetCurrentVehicle()
    if vehicle and DoesEntityExist(vehicle) then
        local currentFuel = GetVehicleFuelLevel(vehicle)
        flightData.fuelConsumed = flightData.startFuel - currentFuel
    end
    
    -- End flight on server
    TriggerServerEvent('heli-taxi:server:endFlight', currentCoords, 5, 0) -- Default 5-star rating, 0 tip
    
    inFlight = false
end

-- Flight Tracking Loop
CreateThread(function()
    while true do
        Wait(1000) -- Update every second
        
        if inFlight then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle == 0 or vehicle ~= GetCurrentVehicle() then
                -- No longer in vehicle
                EndFlight()
            else
                local currentCoords = GetEntityCoords(playerPed)
                
                -- Calculate distance traveled
                if flightData.lastCoords then
                    local segmentDistance = #(currentCoords - flightData.lastCoords)
                    flightData.distance = flightData.distance + segmentDistance
                end
                
                flightData.lastCoords = currentCoords
                
                -- Get fuel
                local currentFuel = GetVehicleFuelLevel(vehicle)
                flightData.fuelConsumed = flightData.startFuel - currentFuel
                
                -- Update server
                TriggerServerEvent('heli-taxi:server:updateFlight', flightData.distance, flightData.fuelConsumed)
            end
        end
    end
end)

-- HUD Display Thread
CreateThread(function()
    while true do
        Wait(100)
        
        if inFlight then
            local duration = math.floor((GetGameTimer() - flightData.startTime) / 1000)
            local distanceKm = flightData.distance / 1000
            
            -- The HUD is handled by the HTML/JS UI
            -- Just ensure we're sending updates
        end
    end
end)

-- Cancel flight command
RegisterCommand('cancelflight', function()
    if inFlight then
        TriggerServerEvent('heli-taxi:server:cancelFlight')
    end
end, false)

-- Receive Flight History
RegisterNetEvent('heli-taxi:client:receiveFlightHistory', function(flights)
    SendNUIMessage({
        action = 'receiveFlightHistory',
        flights = flights
    })
end)
