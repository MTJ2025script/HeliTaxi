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
    
    -- Simple notification showing available destinations
    ShowNotification("Helicopter Taxi called. Flying to first available destination.")
    
    -- Auto-select first destination for standalone use
    -- In production, integrate with your menu system (ESX, QB, etc.)
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
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 100 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        ShowNotification("Error: Could not load helicopter model")
        heliTaxiActive = false
        return
    end
    
    -- Spawn helicopter (client-side only for standalone)
    currentHeli = CreateVehicle(modelHash, Config.HeliSpawn.coords.x, Config.HeliSpawn.coords.y, Config.HeliSpawn.coords.z, Config.HeliSpawn.heading, false, false)
    SetVehicleEngineOn(currentHeli, true, true, false)
    SetVehicleNumberPlateText(currentHeli, "TAXI")
    
    -- Mark model as no longer needed to free memory
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Spawn NPC driver (26 = CIVMALE ped type)
    local driverModel = GetHashKey("s_m_m_pilot_01")
    RequestModel(driverModel)
    timeout = 0
    while not HasModelLoaded(driverModel) and timeout < 100 do
        Citizen.Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(driverModel) then
        ShowNotification("Error: Could not load pilot model")
        DeleteVehicle(currentHeli)
        heliTaxiActive = false
        return
    end
    
    currentDriver = CreatePedInsideVehicle(currentHeli, 26, driverModel, -1, true, false)
    SetBlockingOfNonTemporaryEvents(currentDriver, true)
    SetPedFleeAttributes(currentDriver, 0, false)
    SetPedCombatAttributes(currentDriver, 17, true)
    
    -- Mark model as no longer needed to free memory
    SetModelAsNoLongerNeeded(driverModel)
    
    ShowNotification("Helicopter is ready. Get in!")
    
    -- Wait for player to enter (with 60 second timeout)
    local startTime = GetGameTimer()
    Citizen.CreateThread(function()
        while heliTaxiActive do
            Citizen.Wait(100)
            
            -- Check timeout (60 seconds)
            if GetGameTimer() - startTime > 60000 then
                ShowNotification("Taxi call timed out")
                CleanupTaxi()
                break
            end
            
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
    -- TaskHeliMission parameters: ped, vehicle, targetVehicle, targetPed, posX, posY, posZ,
    -- mode(4=land), speed, radius, targetHeading, maxHeight, minHeight, slowDownDistance, flags
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
                
                -- Check if arrived (within 20 meters and on ground)
                if distance < 20.0 and IsVehicleOnAllWheels(currentHeli) then
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
        DeletePed(currentDriver)
    end
    
    if currentHeli and DoesEntityExist(currentHeli) then
        DeleteVehicle(currentHeli)
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

-- Boss Menu System
local bossMenuOpen = false

-- Check if player has boss permissions (can be customized for ESX/QB)
function HasBossPermission()
    -- For standalone, allow everyone to access
    -- In production, integrate with your framework's permission system
    return true
    
    -- Example ESX integration (commented out):
    --[[
    if ESX then
        local playerData = ESX.GetPlayerData()
        if playerData.job and playerData.job.name == 'helitaxi' then
            return playerData.job.grade >= 3 -- Manager rank or above
        end
    end
    return false
    ]]--
end

-- Open boss menu
function OpenBossMenu()
    if bossMenuOpen then return end
    
    local hasPermission = HasBossPermission()
    
    if not hasPermission then
        ShowNotification("Access Denied: Manager rank or above required")
    end
    
    bossMenuOpen = true
    
    -- Gather data for the menu
    local menuData = {
        hasPermission = hasPermission,
        stats = {
            flights = 0,
            helicopters = 1,
            revenue = 0,
            employees = 1
        },
        fleet = {
            {name = "Helicopter Alpha", status = "available", location = "Vespucci Helipad"}
        },
        employees = {},
        finances = {
            today = 0,
            week = 0,
            month = 0
        }
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = "openBossMenu",
        data = menuData
    })
    
    SetNuiFocus(true, true)
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseBossMenu()
    cb('ok')
end)

RegisterNUICallback('setFocus', function(data, cb)
    SetNuiFocus(data.focus, data.cursor)
    cb('ok')
end)

-- Close boss menu
function CloseBossMenu()
    bossMenuOpen = false
    SendNUIMessage({
        action = "close"
    })
    SetNuiFocus(false, false)
end

-- Boss menu marker and interaction
Citizen.CreateThread(function()
    -- Boss menu location (near spawn point)
    local bossMenuCoords = vector3(Config.HeliSpawn.coords.x + 10.0, Config.HeliSpawn.coords.y, Config.HeliSpawn.coords.z)
    
    -- Create blip for boss menu
    local blip = AddBlipForCoord(bossMenuCoords.x, bossMenuCoords.y, bossMenuCoords.z)
    SetBlipSprite(blip, 521) -- Office/briefcase icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 3) -- Blue color
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("HeliTaxi Management")
    EndTextCommandSetBlipName(blip)
    
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        local distance = #(playerCoords - bossMenuCoords)
        
        if distance < 50.0 then
            sleep = 0
            -- Draw marker for boss menu
            DrawMarker(27, bossMenuCoords.x, bossMenuCoords.y, bossMenuCoords.z - 1.0, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                1.5, 1.5, 1.5, 
                50, 150, 255, 100, 
                false, true, 2, false, nil, nil, false)
            
            if distance < 2.0 and not bossMenuOpen then
                ShowHelpText("Press ~INPUT_CONTEXT~ to open Management Menu")
                
                if IsControlJustReleased(0, 38) then -- E key
                    OpenBossMenu()
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Handle "illegal" boss menu calls from external sources
RegisterNetEvent('helitaxi:openIllegalBossMenu')
AddEventHandler('helitaxi:openIllegalBossMenu', function()
    -- Convert illegal boss menu request to legal management menu
    OpenBossMenu()
end)

RegisterNetEvent('helitaxi:openBossMenu')
AddEventHandler('helitaxi:openBossMenu', function()
    OpenBossMenu()
end)

-- Command to open boss menu
RegisterCommand('helitaximenu', function()
    OpenBossMenu()
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupTaxi()
        if bossMenuOpen then
            CloseBossMenu()
        end
    end
end)
