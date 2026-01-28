-- Vehicle Management Client
local currentVehicle = nil
local currentVehicleData = nil

-- Spawn Vehicle
RegisterNetEvent('heli-taxi:client:spawnVehicle', function(vehicleData, helipadIndex)
    -- Check if player already has a vehicle spawned
    if currentVehicle then
        -- If vehicle was deleted/despawned, reset the variable
        if not DoesEntityExist(currentVehicle) then
            print('[Heli-Taxi] Previous vehicle no longer exists, resetting')
            currentVehicle = nil
            currentVehicleData = nil
        else
            -- Vehicle still exists, cannot spawn another
            Framework.Notify(_U('already_have_vehicle'), 'error')
            return
        end
    end
    
    local helipad = Config.Locations.Helipads[helipadIndex]
    if not helipad then
        Framework.Notify(_U('invalid_helipad'), 'error')
        return
    end
    
    local coords = helipad.coords
    local heading = coords.w
    
    -- Request model
    local modelHash = GetHashKey(vehicleData.model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(modelHash) then
        Framework.Notify(_U('model_load_failed'), 'error')
        return
    end
    
    -- Create vehicle (networked = true to prevent disappearing!)
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, true, false)
    
    -- CRITICAL: Freeze vehicle during initialization to prevent physics issues
    FreezeEntityPosition(vehicle, true)
    
    -- Wait for vehicle to exist (extended timeout)
    timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not DoesEntityExist(vehicle) then
        Framework.Notify(_U('spawn_failed'), 'error')
        print('[Heli-Taxi] ERROR: Vehicle entity does not exist after creation')
        return
    end
    
    -- Wait for network synchronization
    timeout = 0
    while not NetworkGetEntityIsNetworked(vehicle) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    -- CRITICAL: Wait for world collision and entity fade-in
    while IsEntityWaitingForWorldCollision(vehicle) do
        Wait(10)
    end
    
    -- Activate collision
    SetEntityCollision(vehicle, true, true)
    
    -- ENFORCE VISIBILITY (multiple attempts)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAlpha(vehicle, 255, false)
    SetEntityVisible(vehicle, true, false)
    
    -- Set entity as mission entity to prevent auto-delete
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    
    -- Get network ID and ensure it's networked
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(netId, true)
    SetNetworkIdExistsOnAllMachines(netId, true)
    
    -- Prevent deletion (double security)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleIsStolen(vehicle, false)
    
    -- Extended network sync wait
    Wait(1000)
    
    -- Re-enforce visibility
    SetEntityVisible(vehicle, true, true)
    PlaceObjectOnGroundProperly(vehicle)
    
    -- Unfreeze vehicle
    FreezeEntityPosition(vehicle, false)
    
    -- CRITICAL: Additional wait to ensure entity is fully initialized
    -- This fixes the "originalPlate: nil" issue
    Wait(500)
    
    -- CRITICAL: Get original plate BEFORE modifying vehicle properties!
    -- This prevents "No such entity" errors
    -- Try multiple times with waits if needed
    local originalPlate = GetVehicleNumberPlateText(vehicle)
    
    if not originalPlate or originalPlate == '' then
        print('[Heli-Taxi] ⚠️ First plate attempt failed, waiting and retrying...')
        Wait(1000)
        originalPlate = GetVehicleNumberPlateText(vehicle)
        
        if not originalPlate or originalPlate == '' then
            print('[Heli-Taxi] ⚠️ Second plate attempt failed, final retry...')
            Wait(1000)
            originalPlate = GetVehicleNumberPlateText(vehicle)
        end
    end
    
    -- CRITICAL: Only try to set custom plate if we have a valid original plate
    local plate
    if originalPlate and originalPlate ~= '' then
        -- Try to set custom plate
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
        Wait(100)  -- Give time for plate to update
        
        -- Verify plate was set correctly
        plate = GetVehicleNumberPlateText(vehicle)
        
        -- Fallback to original plate if custom plate failed
        if not plate or plate == '' then
            print('[Heli-Taxi] ⚠️ WARNING: Custom plate failed, using original plate')
            plate = originalPlate
        end
    else
        -- No original plate - try to get ANY plate
        print('[Heli-Taxi] ⚠️ No original plate, attempting to get current plate...')
        Wait(500)
        plate = GetVehicleNumberPlateText(vehicle)
    end
    
    -- NOW set other vehicle properties (plate is guaranteed valid!)
    SetVehicleEngineOn(vehicle, false, false, false)
    SetVehicleFuelLevel(vehicle, vehicleData.fuel + 0.0)
    SetVehicleBodyHealth(vehicle, vehicleData.condition * 10.0)
    SetVehicleEngineHealth(vehicle, vehicleData.condition * 10.0)
    
    -- Model can be released now
    SetModelAsNoLongerNeeded(modelHash)
    
    -- CRITICAL: Final plate validation before using it!
    if not plate or plate == '' then
        print('[Heli-Taxi] ❌ CRITICAL ERROR: Could not get vehicle plate after all attempts!')
        print('[Heli-Taxi] originalPlate: ' .. tostring(originalPlate))
        print('[Heli-Taxi] Vehicle will be deleted - please retry spawn')
        
        -- Delete broken vehicle
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
        
        Framework.Notify('Fahrzeug-Spawn fehlgeschlagen - bitte erneut versuchen', 'error')
        SendNUIMessage({action = 'closeMenu'})
        SetNuiFocus(false, false)
        
        return  -- EXIT - Don't set currentVehicle!
    end
    
    -- Unlock doors BEFORE giving keys (critical order!)
    SetVehicleDoorsLocked(vehicle, 1)  -- 1 = Unlocked
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
    
    -- Give QB-Core keys to spawner (needed for engine start)
    if GetResourceState('qb-core') == 'started' then
        TriggerEvent('qb-vehiclekeys:client:SetOwner', plate)
        print('[Heli-Taxi] 🔑 QB-Core Keys gegeben: ' .. plate)
    end
    
    -- Wait for keys to be processed, then unlock again (QB-Core sometimes re-locks)
    Wait(200)
    SetVehicleDoorsLocked(vehicle, 1)  -- Force unlock again
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false)
    print('[Heli-Taxi] 🔓 Türen entsperrt für alle Mitarbeiter')
    
    -- CRITICAL: Set currentVehicle ONLY AFTER everything is initialized AND plate is valid
    -- This prevents the monitoring thread from detecting it as "lost" during spawn
    currentVehicle = vehicle
    currentVehicleData = vehicleData
    
    Framework.Notify(_U('vehicle_spawned', helipad.label), 'success')
    
    -- Close menu
    SendNUIMessage({action = 'closeMenu'})
    SetNuiFocus(false, false)
end)

-- Return Vehicle
function ReturnVehicle()
    if not currentVehicle or not DoesEntityExist(currentVehicle) then
        Framework.Notify(_U('no_vehicle_to_return'), 'error')
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check if near any helipad
    local nearHelipad = false
    for _, helipad in pairs(Config.Locations.Helipads) do
        local dist = #(playerCoords - vector3(helipad.coords.x, helipad.coords.y, helipad.coords.z))
        if dist < 10.0 then
            nearHelipad = true
            break
        end
    end
    
    if not nearHelipad then
        Framework.Notify(_U('must_be_near_helipad'), 'error')
        return
    end
    
    -- Get vehicle condition and fuel
    local condition = math.floor(GetVehicleBodyHealth(currentVehicle) / 10.0)
    local fuel = GetVehicleFuelLevel(currentVehicle)
    
    -- Delete vehicle
    DeleteEntity(currentVehicle)
    
    -- Notify server
    TriggerServerEvent('heli-taxi:server:returnVehicle', currentVehicleData.plate, condition, fuel)
    
    currentVehicle = nil
    currentVehicleData = nil
    
    Framework.Notify(_U('vehicle_returned'), 'success')
end

-- CRITICAL: Keep company vehicles ALWAYS unlocked (continuous enforcement)
CreateThread(function()
    while true do
        Wait(1)  -- Optimized to 1ms for instant unlock
        
        -- Keep currentVehicle unlocked
        if currentVehicle and DoesEntityExist(currentVehicle) then
            SetVehicleDoorsLocked(currentVehicle, 1)  -- 1 = Unlocked
            SetVehicleDoorsLockedForAllPlayers(currentVehicle, false)
        end
        
        -- Also check all nearby vehicles with company plates
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicles = GetGamePool('CVehicle')
        
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local vehCoords = GetEntityCoords(vehicle)
                local dist = #(coords - vehCoords)
                
                -- Only check nearby vehicles (within 100m)
                if dist < 100.0 then
                    local plate = GetVehicleNumberPlateText(vehicle)
                    
                    -- Keep company helicopters unlocked (plate contains "HELI")
                    if plate and string.find(plate, "HELI") then
                        SetVehicleDoorsLocked(vehicle, 1)  -- Always unlocked
                        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                    end
                end
            end
        end
    end
end)

-- Fuel Consumption System
CreateThread(function()
    while true do
        Wait(10000)  -- Check every 10 seconds
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        -- Check if player is in a vehicle and it's the current company vehicle
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            local plate = GetVehicleNumberPlateText(vehicle)
            
            -- Only apply fuel consumption to company helicopters (plate contains "HELI")
            if plate and string.find(plate, "HELI") and currentVehicleData then
                -- Check if engine is running
                local engineRunning = GetIsVehicleEngineRunning(vehicle)
                
                if engineRunning then
                    -- Get current fuel level
                    local currentFuel = GetVehicleFuelLevel(vehicle)
                    
                    -- Get fuel consumption rate from vehicle config
                    local fuelConsumption = currentVehicleData.fuelConsumption or 1.0
                    
                    -- Calculate fuel drain (every 10 seconds)
                    -- Divide by 6 because we check every 10s (6 times per minute)
                    local fuelDrain = fuelConsumption / 6.0
                    
                    -- Reduce fuel
                    local newFuel = math.max(0, currentFuel - fuelDrain)
                    SetVehicleFuelLevel(vehicle, newFuel)
                    
                    -- Update database with new fuel level
                    TriggerServerEvent('heli-taxi:server:updateVehicleFuel', plate, newFuel)
                    
                    -- Notify player
                    print(string.format('[Heli-Taxi] 🛢️ Fuel: %.1f%% (-%.2f%%)', newFuel, fuelDrain))
                    
                    -- Warn if fuel is low
                    if newFuel < 20 and newFuel > 19 then
                        Framework.Notify('Warnung: Treibstoff niedrig! (' .. math.floor(newFuel) .. '%)', 'warning')
                    elseif newFuel <= 0 then
                        Framework.Notify('Kein Treibstoff mehr! Motor ausgefallen!', 'error')
                        SetVehicleEngineOn(vehicle, false, true, true)
                    end
                end
            end
        end
    end
end)

-- Vehicle Access Check System - Kick non-employees from company vehicles (drivers only)
-- Passengers (non-employees) are allowed when an employee is driving
CreateThread(function()
    while true do
        Wait(1)  -- Optimized to 1ms for instant access control
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and IsPedInAnyHeli(ped) then
            local plate = GetVehicleNumberPlateText(vehicle)
            local isDriver = (GetPedInVehicleSeat(vehicle, -1) == ped)  -- -1 is driver seat
            
            -- Ask server to check if this is a company vehicle and if player has access
            -- isDriver: true if player is driving, false if passenger
            TriggerServerEvent('heli-taxi:server:checkVehicleAccess', plate, isDriver)
        end
    end
end)

-- Kick player from vehicle (no access)
RegisterNetEvent('heli-taxi:client:kickFromVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle ~= 0 then
        TaskLeaveVehicle(ped, vehicle, 16)  -- Immediate exit
        print('[Heli-Taxi] ❌ No access - kicked from vehicle')
    end
end)

-- Vehicle Existence Monitor (Auto-return to garage if entity lost)
CreateThread(function()
    while true do
        Wait(5000)  -- Check every 5 seconds
        
        -- Check if spawned vehicle still exists
        if currentVehicle ~= nil and currentVehicle ~= 0 then
            if not DoesEntityExist(currentVehicle) then
                -- Vehicle was deleted by game/cleanup scripts
                print('[Heli-Taxi] Vehicle entity lost - notifying server to return to garage')
                
                if currentPlate then
                    TriggerServerEvent('heli-taxi:server:vehicleLost', currentPlate)
                end
                
                currentVehicle = nil
                currentPlate = nil
            end
        end
    end
end)

-- Check if player is in a company vehicle
function IsInCompanyVehicle()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then return false end
    if vehicle ~= currentVehicle then return false end
    
    return true
end

function GetCurrentVehicle()
    return currentVehicle
end

function GetCurrentVehicleData()
    return currentVehicleData
end

-- Command to return vehicle
RegisterCommand('returnheli', function()
    if IsOnDuty() and currentVehicle then
        ReturnVehicle()
    end
end, false)

-- Vehicle enter/exit detection
CreateThread(function()
    local wasInVehicle = false
    
    while true do
        Wait(1)  -- Optimized to 1ms for instant detection
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local isInVehicle = vehicle ~= 0 and vehicle == currentVehicle
        
        if isInVehicle and not wasInVehicle then
            -- Entered vehicle
            wasInVehicle = true
            
            if IsOnDuty() and IsPedInAnyHeli(playerPed) then
                -- Start flight tracking
                TriggerEvent('heli-taxi:client:vehicleEntered')
            end
        elseif not isInVehicle and wasInVehicle then
            -- Exited vehicle
            wasInVehicle = false
            
            if IsOnDuty() then
                TriggerEvent('heli-taxi:client:vehicleExited')
            end
        end
    end
end)
