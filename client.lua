local heliTaxiActive = false
local currentHeli = nil
local currentDriver = nil
local currentDestination = nil

-- Create blip for heli taxi location
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.HeliSpawn.coords.x, Config.HeliSpawn.coords.y, Config.HeliSpawn.coords.z)
    SetBlipSprite(blip, Config.BlipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, Config.BlipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Helicopter Taxi")
    EndTextCommandSetBlipName(blip)
end)

-- Main thread for marker and interaction
Citizen.CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Only show marker at spawn location, not at illegal locations
        local distance = #(playerCoords - Config.HeliSpawn.coords)
        
        if distance < 50.0 then
            sleep = 0
            DrawMarker(1, Config.HeliSpawn.coords.x, Config.HeliSpawn.coords.y, Config.HeliSpawn.coords.z - 1.0, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                2.0, 2.0, 1.0, 
                Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a, 
                false, true, 2, false, nil, nil, false)
            
            if distance < 2.0 then
                ShowHelpText("Press ~INPUT_CONTEXT~ to call Helicopter Taxi")
                
                if IsControlJustReleased(0, 38) and not heliTaxiActive then -- E key
                    CallHeliTaxi()
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

function ShowHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function CallHeliTaxi()
    heliTaxiActive = true
    
    -- Show destination menu
    ShowDestinationMenu()
end

function ShowDestinationMenu()
    local elements = {}
    
    for i, location in ipairs(Config.TaxiLocations) do
        table.insert(elements, {
            label = location.name,
            value = i
        })
    end
    
    -- For simplicity, use native notification instead of ESX menu
    SendNUIMessage({
        type = "showDestinations",
        destinations = Config.TaxiLocations
    })
    
    -- Simplified selection - auto-select first destination for testing
    -- In production, you'd want a proper menu system
    SelectDestination(1)
end

function SelectDestination(index)
    currentDestination = Config.TaxiLocations[index]
    
    if not currentDestination then
        ShowNotification("Invalid destination selected")
        heliTaxiActive = false
        return
    end
    
    ShowNotification("Helicopter taxi called to: " .. currentDestination.name)
    SpawnHeliTaxi()
end

function SpawnHeliTaxi()
    local modelHash = GetHashKey(Config.HeliSpawn.model)
    
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(100)
    end
    
    -- Spawn helicopter
    currentHeli = CreateVehicle(modelHash, Config.HeliSpawn.coords.x, Config.HeliSpawn.coords.y, Config.HeliSpawn.coords.z, Config.HeliSpawn.heading, true, false)
    SetVehicleEngineOn(currentHeli, true, true, false)
    SetVehicleNumberPlateText(currentHeli, "TAXI")
    
    -- Spawn NPC driver
    local driverModel = GetHashKey("s_m_m_pilot_01")
    RequestModel(driverModel)
    while not HasModelLoaded(driverModel) do
        Citizen.Wait(100)
    end
    
    currentDriver = CreatePedInsideVehicle(currentHeli, 26, driverModel, -1, true, false)
    SetBlockingOfNonTemporaryEvents(currentDriver, true)
    SetPedFleeAttributes(currentDriver, 0, false)
    SetPedCombatAttributes(currentDriver, 17, true)
    
    ShowNotification("Helicopter is ready. Get in!")
    
    -- Wait for player to enter
    Citizen.CreateThread(function()
        while heliTaxiActive do
            Citizen.Wait(100)
            
            local playerPed = PlayerPedId()
            
            if IsPedInVehicle(playerPed, currentHeli, false) then
                StartTaxiRoute()
                break
            end
        end
    end)
end

function StartTaxiRoute()
    if not currentDestination or not currentDriver or not currentHeli then
        ShowNotification("Error starting taxi route")
        CleanupTaxi()
        return
    end
    
    ShowNotification("Flying to: " .. currentDestination.name)
    
    -- Make NPC driver fly to destination
    TaskHeliMission(currentDriver, currentHeli, 0, 0, 
        currentDestination.coords.x, currentDestination.coords.y, currentDestination.coords.z, 
        4, 30.0, 10.0, -1.0, 0, 10, -1.0, 0)
    
    -- Monitor arrival
    Citizen.CreateThread(function()
        while heliTaxiActive do
            Citizen.Wait(1000)
            
            if currentHeli and DoesEntityExist(currentHeli) then
                local heliCoords = GetEntityCoords(currentHeli)
                local distance = #(heliCoords - currentDestination.coords)
                
                -- Check if arrived (within 50 meters)
                if distance < 50.0 then
                    ShowNotification("Arrived at destination: " .. currentDestination.name)
                    Citizen.Wait(5000)
                    CleanupTaxi()
                    break
                end
            else
                CleanupTaxi()
                break
            end
        end
    end)
end

function CleanupTaxi()
    heliTaxiActive = false
    
    if currentDriver and DoesEntityExist(currentDriver) then
        DeleteEntity(currentDriver)
    end
    
    if currentHeli and DoesEntityExist(currentHeli) then
        DeleteEntity(currentHeli)
    end
    
    currentDriver = nil
    currentHeli = nil
    currentDestination = nil
end

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupTaxi()
    end
end)
