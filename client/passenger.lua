--[[
    🚁 Heli-Taxi - Passagier-Taxi Client
]]

local currentTaxiRide = nil
local taxiHudActive = false
local lastDistance = 0
local dialogShown = false  -- Track if dialog is already displayed

-- Configuration: Stationary time-based charging
local STATIONARY_CHARGE_PER_MINUTE = 500  -- $500 per minute when not moving (realistic helicopter costs!)
local STATIONARY_CHECK_INTERVAL = 10  -- Check every 10 seconds
local MOVEMENT_THRESHOLD = 0.05  -- Minimum km movement to not be considered stationary
local lastCheckPos = nil
local lastCheckTime = 0
local stationaryTime = 0  -- Total time spent stationary (in seconds)

--[[
    Passagier-Dialog anzeigen
]]
RegisterNetEvent('heli_taxi:showPassengerDialog', function(data)
    dialogShown = true  -- Mark dialog as shown
    SendNUIMessage({
        action = 'showPassengerDialog',
        data = data
    })
    SetNuiFocus(true, true)
end)

--[[
    Taxi akzeptieren
]]
RegisterNUICallback('acceptTaxi', function(data, cb)
    if data.pilotId then
        TriggerServerEvent('heli_taxi:acceptTaxiRide', data.pilotId)
        SetNuiFocus(false, false)
        dialogShown = false  -- Reset dialog flag
    end
    cb('ok')
end)

--[[
    Taxi ablehnen
]]
RegisterNUICallback('declineTaxi', function(data, cb)
    if data.pilotId then
        TriggerServerEvent('heli_taxi:declineTaxiRide', data.pilotId)
        SetNuiFocus(false, false)
        dialogShown = false  -- Reset dialog flag
    end
    cb('ok')
end)

--[[
    Taxi-Fahrt starten
]]
RegisterNetEvent('heli_taxi:startTaxiRide', function(rideId, otherId)
    currentTaxiRide = {
        id = rideId,
        otherId = otherId,
        startPos = GetEntityCoords(PlayerPedId()),
        startTime = GetGameTimer(),
        totalDistance = 0,
        totalCost = Config.FlatFee
    }
    
    taxiHudActive = true
    lastDistance = 0
    
    -- Initialize stationary checking variables
    lastCheckPos = GetEntityCoords(PlayerPedId())
    lastCheckTime = GetGameTimer()
    stationaryTime = 0
    
    -- HUD anzeigen
    SendNUIMessage({
        action = 'showTaxiHud',
        data = {
            flatFee = Config.FlatFee,
            pricePerKm = Config.PricePerKm
        }
    })
end)

--[[
    Ride Info Update
]]
RegisterNetEvent('heli_taxi:updateRideInfo', function(ride)
    if currentTaxiRide and currentTaxiRide.id == ride.id then
        currentTaxiRide.totalDistance = ride.totalDistance
        currentTaxiRide.totalCost = ride.totalCost
    end
end)

--[[
    Rechnung anzeigen
]]
RegisterNetEvent('heli_taxi:showInvoice', function(invoice)
    taxiHudActive = false
    
    SendNUIMessage({
        action = 'hideTaxiHud'
    })
    
    SendNUIMessage({
        action = 'showInvoice',
        invoice = invoice
    })
    SetNuiFocus(true, true)
    
    currentTaxiRide = nil
    lastCheckPos = nil
    stationaryTime = 0
    lastCheckTime = 0
    
    -- Auto-release focus after 10 seconds (shorter timeout)
    Citizen.SetTimeout(10000, function()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({
            action = 'hideInvoice'
        })
    end)
end)

--[[
    Rechnung schließen
]]
RegisterNUICallback('closeInvoice', function(data, cb)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)  -- Ensure keyboard mode is cleared
    cb('ok')
end)

--[[
    Taxi-HUD Update Thread
]]
Citizen.CreateThread(function()
    while true do
        Wait(1000) -- Jede Sekunde updaten
        
        if taxiHudActive and currentTaxiRide then
            local playerPed = PlayerPedId()
            local currentPos = GetEntityCoords(playerPed)
            local distance = #(currentPos - currentTaxiRide.startPos) / 1000 -- in km
            
            -- Check for stationary status every 10 seconds
            local currentTime = GetGameTimer()
            if currentTime - lastCheckTime >= (STATIONARY_CHECK_INTERVAL * 1000) then
                -- Calculate how far the helicopter moved in the last 10 seconds
                local movementDistance = #(currentPos - lastCheckPos) / 1000 -- in km
                
                -- If movement is less than threshold, add stationary time
                if movementDistance < MOVEMENT_THRESHOLD then
                    stationaryTime = stationaryTime + STATIONARY_CHECK_INTERVAL
                end
                
                -- Update for next check
                lastCheckPos = currentPos
                lastCheckTime = currentTime
            end
            
            -- Calculate stationary cost (only charged for time spent not moving)
            local stationaryMinutes = stationaryTime / 60
            local stationaryCost = stationaryMinutes * STATIONARY_CHARGE_PER_MINUTE
            
            -- Calculate duration for display
            local duration = (GetGameTimer() - currentTaxiRide.startTime) / 1000 -- seconds
            
            -- Update costs (distance + stationary time only)
            lastDistance = distance
            currentTaxiRide.totalDistance = distance
            currentTaxiRide.totalCost = Config.FlatFee + (distance * Config.PricePerKm) + stationaryCost
            
            -- Server informieren (send totalCost including stationary charges)
            TriggerServerEvent('heli_taxi:updateTaxiRide', currentTaxiRide.id, distance, currentTaxiRide.totalCost)
            
            -- HUD updaten
            SendNUIMessage({
                action = 'updateTaxiHud',
                data = {
                    duration = duration,
                    distance = distance,
                    flatFee = Config.FlatFee,
                    distanceCost = distance * Config.PricePerKm,
                    timeCost = stationaryCost,  -- Now only charged for stationary time
                    totalCost = currentTaxiRide.totalCost
                }
            })
        end
    end
end)

--[[
    Passagier-Erkennung Thread
]]
Citizen.CreateThread(function()
    while true do
        Wait(3000) -- Alle 3 Sekunden prüfen
        
        -- NUR prüfen wenn KEINE aktive Fahrt läuft UND kein Dialog bereits angezeigt wird
        if not currentTaxiRide and not taxiHudActive and not dialogShown then
            local playerPed = PlayerPedId()
            
            if IsPedInAnyVehicle(playerPed, false) then
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                local driver = GetPedInVehicleSeat(vehicle, -1)
                
                -- Prüfe ob Passagier (nicht Fahrer)
                if driver ~= playerPed and driver ~= 0 then
                    -- Prüfe ob Fahrer helitaxi Job hat
                    local driverServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(driver))
                    
                    if driverServerId and driverServerId > 0 then
                        -- Frage Server ob Dialog zeigen soll
                        -- Server prüft ob eigener Spieler helitaxi Job hat
                        TriggerServerEvent('heli_taxi:checkPassengerStatus', driverServerId)
                    end
                end
            end
        end
    end
end)

--[[
    NUI Callback: Flug beenden Button
]]
RegisterNUICallback('endTaxiRide', function(data, cb)
    if currentTaxiRide and taxiHudActive then
        -- Fahrt beenden
        TriggerServerEvent('heli_taxi:endTaxiRide', currentTaxiRide.id)
        taxiHudActive = false
    end
    cb('ok')
end)

--[[
    Fahrt beenden bei Ausstieg (Fallback)
]]
Citizen.CreateThread(function()
    while true do
        Wait(500)
        
        if currentTaxiRide and taxiHudActive then
            local playerPed = PlayerPedId()
            
            -- Prüfe ob noch im Fahrzeug
            if not IsPedInAnyVehicle(playerPed, false) then
                -- Aus Fahrzeug ausgestiegen - Fahrt automatisch beenden
                TriggerServerEvent('heli_taxi:endTaxiRide', currentTaxiRide.id)
                taxiHudActive = false
            end
        end
    end
end)

--[[
    Passagier-Überwachung: Fahrer-Check
    Wirft Passagiere raus wenn Mitarbeiter-Fahrer aussteigt
]]
Citizen.CreateThread(function()
    while true do
        Wait(1000) -- Jede Sekunde prüfen
        
        local playerPed = PlayerPedId()
        
        -- Prüfe ob Spieler Passagier in Fahrzeug ist (nicht Fahrer)
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local driver = GetPedInVehicleSeat(vehicle, -1)
            
            -- Wenn Spieler NICHT Fahrer ist
            if driver ~= playerPed then
                -- Prüfe ob Firmen-Fahrzeug (Kennzeichen-Check)
                local plate = GetVehicleNumberPlateText(vehicle)
                
                if plate and string.find(plate, "HELI") then
                    -- Firmen-Heli: Prüfe ob Fahrer noch da ist
                    if driver == 0 then
                        -- KEIN Fahrer mehr → Passagier rauswerfen
                        TaskLeaveVehicle(playerPed, vehicle, 16) -- 16 = sofort
                        
                        -- Fahrt beenden falls aktiv
                        if currentTaxiRide and taxiHudActive then
                            TriggerServerEvent('heli_taxi:endTaxiRide', currentTaxiRide.id)
                            taxiHudActive = false
                        end
                        
                        -- Benachrichtigung
                        if Framework and Framework.Notify then
                            Framework.Notify('Der Pilot hat den Hubschrauber verlassen!', 'error', 5000)
                        end
                    end
                end
            end
        end
    end
end)

-- Passagier-System geladen
