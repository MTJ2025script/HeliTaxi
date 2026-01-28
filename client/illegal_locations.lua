--[[
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    🚨 ILLEGAL LOCATIONS - CLIENT
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    Verwaltet versteckte Gang-Anlaufstellen:
    - Illegal Duty Toggle NPC
    - Illegal Vehicle Management NPC
    - Nur für Gang Pilots & Special Ops sichtbar
    - Keine Blips - komplett diskret
]]

local IllegalNPCs = {}
local hasAccess = false
local playerGrade = nil  -- Verwende normalen Rang statt Secret Role
local illegalMenuOpen = false  -- Track wenn illegal UI offen ist
local lastShopTrigger = 0  -- Cooldown timer for shop access
local currentHelipadIndex = 1  -- Current helipad for spawning vehicles

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HILFSFUNKTIONEN
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Prüfe ob Spieler Zugriff hat (Illegal rank OR Boss)
-- Boss hat AUTOMATISCH illegal access, ohne "illegal" rank zu brauchen
local function HasIllegalAccess()
    print('[DEBUG-ILLEGAL] ▶ HasIllegalAccess() called')
    print('[DEBUG-ILLEGAL]   └─ Config.IllegalLocations: ' .. tostring(Config.IllegalLocations ~= nil))
    print('[DEBUG-ILLEGAL]   └─ Config.IllegalLocations.enabled: ' .. tostring(Config.IllegalLocations and Config.IllegalLocations.enabled))
    print('[DEBUG-ILLEGAL]   └─ playerGrade: ' .. tostring(playerGrade))
    
    if not Config.IllegalLocations or not Config.IllegalLocations.enabled then
        print('[DEBUG-ILLEGAL]   └─ Result: FALSE (config disabled)')
        return false
    end
    
    if not playerGrade then
        print('[DEBUG-ILLEGAL]   └─ Result: FALSE (no playerGrade)')
        return false
    end
    
    -- Boss can see EVERYTHING (both normal AND illegal)
    -- Boss bleibt Boss, hat aber trotzdem illegal access
    if playerGrade == 'boss' then
        print('[DEBUG-ILLEGAL]   └─ Result: TRUE (boss rank)')
        return true
    end
    
    -- Illegal rank hat access (aber ist NICHT boss)
    if playerGrade == 'illegal' then
        print('[DEBUG-ILLEGAL]   └─ Result: TRUE (illegal rank)')
        return true
    end
    
    -- Check allowed roles from config
    if Config.IllegalLocations.accessControl and Config.IllegalLocations.accessControl.allowedRoles then
        local allowedRoles = Config.IllegalLocations.accessControl.allowedRoles
        for _, role in ipairs(allowedRoles) do
            if playerGrade == role then
                print('[DEBUG-ILLEGAL]   └─ Result: TRUE (allowed role: ' .. role .. ')')
                return true
            end
        end
    end
    
    print('[DEBUG-ILLEGAL]   └─ Result: FALSE (rank not authorized)')
    return false
end

-- Handle Illegal Vehicle Management (called when E is pressed at illegal garage NPC)
local function HandleIllegalVehicleManagement(helipadIndex)
    print('[DEBUG-ILLEGAL] ▶ HandleIllegalVehicleManagement called | Helipad: ' .. tostring(helipadIndex))
    
    -- Send background config
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
    print('[DEBUG-ILLEGAL] ▶ Triggering server getVehicles event...')
    -- Request vehicles from server with helipadIndex (= illegal garage)
    TriggerServerEvent('heli-taxi:server:getVehicles', helipadIndex)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NPC SPAWNING
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function SpawnIllegalNPC(npcData, npcKey)
    if not npcData or not npcData.enabled then
        return
    end
    
    local coords = npcData.coords
    
    if coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0 then
        return
    end
    
    RequestModel(npcData.NPC.model)
    while not HasModelLoaded(npcData.NPC.model) do
        Wait(100)
    end
    
    -- FIX: Get ground Z coordinate to prevent flying NPCs
    local groundZ = coords.z
    local found, zCoord = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 5.0, false)
    if found then
        groundZ = zCoord + 1.0  -- +1.0 offset so NPC stands ON ground
    end
    
    local npc = CreatePed(4, npcData.NPC.model, coords.x, coords.y, groundZ, coords.w, false, true)
    SetEntityCoordsNoOffset(npc, coords.x, coords.y, groundZ, false, false, false)  -- Force exact position
    
    SetEntityHeading(npc, coords.w)
    FreezeEntityPosition(npc, npcData.NPC.frozen)
    SetEntityInvincible(npc, npcData.NPC.invincible)
    SetBlockingOfNonTemporaryEvents(npc, npcData.NPC.blockEvents)
    SetPedCanRagdoll(npc, false)  -- FIX: Prevent NPC from floating/ragdolling
    
    if npcData.NPC.scenario and npcData.NPC.scenario ~= '' then
        TaskStartScenarioInPlace(npc, npcData.NPC.scenario, 0, true)
    end
    
    IllegalNPCs[npcKey] = npc
    
    if Config.Debug then
    end
end

local function SpawnAllIllegalNPCs()
    if not Config.IllegalLocations or not Config.IllegalLocations.enabled then
        return
    end
    
    if not hasAccess then
        if Config.Debug then
        end
        return
    end
    
    -- Spawn TABLET-NPC (für Boss Menu / Firma-Verwaltung)
    if Config.IllegalLocations.TabletNPC and Config.IllegalLocations.TabletNPC.enabled then
        SpawnIllegalNPC(Config.IllegalLocations.TabletNPC, 'TabletNPC')
    end
    
    -- Spawn NPCs für alle 3 Helipads
    if Config.IllegalLocations.Helipads then
        for i, helipad in ipairs(Config.IllegalLocations.Helipads) do
            if helipad.NPC and helipad.NPC.enabled then
                local npcKey = 'Helipad_' .. i
                
                -- Create custom NPC data structure for helipad NPC
                local helipadNPCData = {
                    enabled = helipad.NPC.enabled,
                    coords = helipad.NPC.coords,
                    NPC = {
                        model = helipad.NPC.model,
                        scenario = helipad.NPC.scenario,
                        frozen = helipad.NPC.frozen,
                        invincible = helipad.NPC.invincible,
                        blockEvents = helipad.NPC.blockEvents,
                        interactDistance = helipad.NPC.interactDistance,
                        helpText = helipad.NPC.helpText
                    }
                }
                
                SpawnIllegalNPC(helipadNPCData, npcKey)
            end
        end
        
        -- Check Illegal Shop Marker (ONLY if menu is not open to prevent beeping!)
        if not illegalMenuOpen and Config.IllegalLocations.VehicleShop and Config.IllegalLocations.VehicleShop.enabled then
            local shopCoords = Config.IllegalLocations.VehicleShop.coords
            if shopCoords and (shopCoords.x ~= 0.0 or shopCoords.y ~= 0.0) then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords - vector3(shopCoords.x, shopCoords.y, shopCoords.z))
                
                if dist < Config.IllegalLocations.VehicleShop.interactDistance then
                    sleep = 0
                    
                    -- Draw help text
                    if Config.IllegalLocations.VehicleShop.helpText then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(Config.IllegalLocations.VehicleShop.helpText)
                        EndTextCommandDisplayHelp(0, false, true, -1)
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        illegalMenuOpen = true  -- Set flag BEFORE opening
                        -- Request illegal shop from server
                        TriggerServerEvent('heli-taxi:server:requestIllegalShopAccess')
                    end
                end
            end
        end
    end
end

local function DeleteAllIllegalNPCs()
    for key, npc in pairs(IllegalNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    IllegalNPCs = {}
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INTERACTION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local function HandleTabletNPC()
    -- Öffne Boss Menu für illegale Firma-Verwaltung (via server für validation)
    TriggerServerEvent('heli-taxi:server:requestIllegalBossMenu')
end

local function HandleIllegalVehicleManagement(helipadIndex)
    -- Send background config
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
    -- Request vehicles from server (UI wird vom Event-Handler geöffnet!)
    TriggerServerEvent('heli-taxi:server:getVehicles', helipadIndex)
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MAIN THREAD
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CreateThread(function()
    if not Config.IllegalLocations or not Config.IllegalLocations.enabled then
        return
    end
    
    while true do
        local sleep = 1000
        
        if hasAccess then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Check TABLET-NPC (Boss Menu / Firma-Verwaltung)
            if Config.IllegalLocations.TabletNPC and Config.IllegalLocations.TabletNPC.enabled then
                local tabletCoords = Config.IllegalLocations.TabletNPC.coords
                if tabletCoords.x ~= 0.0 or tabletCoords.y ~= 0.0 then
                    local dist = #(playerCoords - vector3(tabletCoords.x, tabletCoords.y, tabletCoords.z))
                    
                    if dist < Config.IllegalLocations.TabletNPC.NPC.interactDistance then
                        sleep = 0
                        
                        -- Draw help text
                        if Config.IllegalLocations.TabletNPC.NPC.helpText then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName(Config.IllegalLocations.TabletNPC.NPC.helpText)
                            EndTextCommandDisplayHelp(0, false, true, -1)
                        end
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            HandleTabletNPC()
                        end
                    end
                end
            end
            
            -- Check ILLEGAL SHOP MARKER (Army Helis)
            if Config.IllegalLocations.VehicleShop and Config.IllegalLocations.VehicleShop.enabled then
                local shopCoords = Config.IllegalLocations.VehicleShop.coords
                if shopCoords.x ~= 0.0 or shopCoords.y ~= 0.0 then
                    local dist = #(playerCoords - vector3(shopCoords.x, shopCoords.y, shopCoords.z))
                    
                    if dist < Config.IllegalLocations.VehicleShop.interactDistance then
                        sleep = 0
                        
                        -- Draw Marker
                        DrawMarker(
                            Config.IllegalLocations.VehicleShop.markerType or 1,
                            shopCoords.x, shopCoords.y, shopCoords.z - 1.0,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            1.5, 1.5, 1.0,
                            Config.IllegalLocations.VehicleShop.markerColor.r or 255,
                            Config.IllegalLocations.VehicleShop.markerColor.g or 0,
                            Config.IllegalLocations.VehicleShop.markerColor.b or 0,
                            Config.IllegalLocations.VehicleShop.markerColor.a or 100,
                            false, true, 2, false, nil, nil, false
                        )
                        
                        -- Draw help text
                        if Config.IllegalLocations.VehicleShop.helpText then
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName(Config.IllegalLocations.VehicleShop.helpText)
                            EndTextCommandDisplayHelp(0, false, true, -1)
                        end
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            local currentTime = GetGameTimer()
                            -- Check both menu flag AND cooldown (2 second cooldown to prevent spam)
                            if not illegalMenuOpen and (currentTime - lastShopTrigger) > 2000 then
                                lastShopTrigger = currentTime  -- Set cooldown timestamp
                                illegalMenuOpen = true  -- Set IMMEDIATELY to prevent continuous triggers!
                                print('[DEBUG-ILLEGAL] ▶ Shop E pressed | Cooldown active for 2s')
                                TriggerServerEvent('heli-taxi:server:requestIllegalShopAccess')
                            elseif (currentTime - lastShopTrigger) <= 2000 and not illegalMenuOpen then
                                local waitTime = math.ceil((2000 - (currentTime - lastShopTrigger)) / 1000)
                                print('[DEBUG-ILLEGAL] ⏳ Shop on cooldown, wait ' .. waitTime .. 's')
                            end
                        end
                    end
                end
            end
            
            -- Check alle 3 Helipad NPCs
            if Config.IllegalLocations.Helipads then
                for i, helipad in ipairs(Config.IllegalLocations.Helipads) do
                    if helipad.NPC and helipad.NPC.enabled then
                        local npcCoords = helipad.NPC.coords
                        if npcCoords.x ~= 0.0 or npcCoords.y ~= 0.0 then
                            local dist = #(playerCoords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))
                            
                            if dist < helipad.NPC.interactDistance then
                                sleep = 0
                                
                                -- Draw help text
                                if helipad.NPC.helpText then
                                    BeginTextCommandDisplayHelp('STRING')
                                    AddTextComponentSubstringPlayerName(helipad.NPC.helpText)
                                    EndTextCommandDisplayHelp(0, false, true, -1)
                                end
                                
                                if IsControlJustReleased(0, 38) then -- E key
                                    print('[DEBUG-ILLEGAL] ▶ Garage E pressed | Helipad ' .. i)
                                    HandleIllegalVehicleManagement(i)
                                end
                            end
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EVENTS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Update Player Grade (wenn Rang sich ändert)
RegisterNetEvent('heli-taxi:client:updateGrade', function(grade)
    print('[DEBUG-ILLEGAL] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    print('[DEBUG-ILLEGAL] ▶ updateGrade Event triggered')
    print('[DEBUG-ILLEGAL]   └─ Old Rank: ' .. tostring(playerGrade))
    print('[DEBUG-ILLEGAL]   └─ New Rank: ' .. tostring(grade))
    
    playerGrade = grade
    local oldAccess = hasAccess
    hasAccess = HasIllegalAccess()
    
    print('[DEBUG-ILLEGAL] ▶ Access Check Results:')
    print('[DEBUG-ILLEGAL]   └─ Old Access: ' .. tostring(oldAccess))
    print('[DEBUG-ILLEGAL]   └─ New Access: ' .. tostring(hasAccess))
    print('[DEBUG-ILLEGAL]   └─ playerGrade: ' .. tostring(playerGrade))
    print('[DEBUG-ILLEGAL]   └─ Config.IllegalLocations.enabled: ' .. tostring(Config.IllegalLocations and Config.IllegalLocations.enabled))
    
    -- Spawn/Delete NPCs wenn Access sich ändert
    if hasAccess and not oldAccess then
        print('[DEBUG-ILLEGAL] ✅ ACCESS GRANTED - Spawning illegal NPCs')
        DeleteAllIllegalNPCs()  -- Delete first to prevent duplicates
        Wait(100)
        SpawnAllIllegalNPCs()
        print('[DEBUG-ILLEGAL] ✅ NPCs spawned successfully')
    elseif not hasAccess and oldAccess then
        print('[DEBUG-ILLEGAL] ❌ ACCESS REVOKED - Deleting illegal NPCs')
        DeleteAllIllegalNPCs()
        print('[DEBUG-ILLEGAL] ✅ NPCs deleted successfully')
    elseif hasAccess and oldAccess then
        print('[DEBUG-ILLEGAL] ▶ Access unchanged but refreshing NPCs')
        DeleteAllIllegalNPCs()
        Wait(100)
        SpawnAllIllegalNPCs()
        print('[DEBUG-ILLEGAL] ✅ NPCs refreshed')
    else
        print('[DEBUG-ILLEGAL] ▶ No access (hasAccess: ' .. tostring(hasAccess) .. ')')
    end
    
    print('[DEBUG-ILLEGAL] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ILLEGALE UI EVENTS - KOMPLETT GETRENNT VOM NORMALEN SYSTEM!
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Open Illegal Boss Menu (Tablet NPC)
RegisterNetEvent('heli-taxi:client:openIllegalBossMenu', function(data)
    print('[DEBUG-ILLEGAL] ✅ Opening ILLEGAL Boss Menu | Data:', json.encode(data or {}))
    illegalMenuOpen = true
    
    -- Send to ILLEGAL.HTML not index.html!
    SendNUIMessage({
        action = 'openIllegalBossMenu',
        data = data
    })
    
    SetNuiFocus(true, true)
    print('[DEBUG-ILLEGAL] ✅ Illegal Boss Menu opened')
end)

-- Open Illegal Army Vehicle Shop
RegisterNetEvent('heli-taxi:client:openIllegalShop', function(vehicles)
    print('[DEBUG-ILLEGAL] ✅ Opening ILLEGAL Shop | Vehicles:', #(vehicles or {}))
    
    -- Flag is already set when E was pressed - just continue opening UI
    
    -- Send to ILLEGAL.HTML not index.html!
    SendNUIMessage({
        action = 'openIllegalShop',
        vehicles = vehicles
    })
    
    SetNuiFocus(true, true)
    print('[DEBUG-ILLEGAL] ✅ Illegal Shop opened')
end)

-- Open Illegal Garage (3 Helipads)
RegisterNetEvent('heli-taxi:client:openIllegalGarage', function(vehicles, helipadIndex)
    print('[DEBUG-ILLEGAL] ✅ Opening ILLEGAL Garage | Helipad:', helipadIndex, '| Vehicles:', #(vehicles or {}))
    illegalMenuOpen = true
    
    -- Send to ILLEGAL.HTML not index.html!
    SendNUIMessage({
        action = 'openIllegalGarage',
        vehicles = vehicles,
        helipadIndex = helipadIndex
    })
    
    SetNuiFocus(true, true)
    print('[DEBUG-ILLEGAL] ✅ Illegal Garage opened')
end)

-- Spawn Illegal Vehicle (Client-side vehicle creation)
RegisterNetEvent('heli-taxi:client:spawnIllegalVehicle', function(vehicleData)
    print('[DEBUG-ILLEGAL] ✅ Spawning illegal vehicle: ' .. vehicleData.model)
    
    local model = GetHashKey(vehicleData.model)
    
    -- Request model
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        print('[DEBUG-ILLEGAL] ❌ Failed to load model: ' .. vehicleData.model)
        return
    end
    
    -- Get spawn coordinates
    local coords = vehicleData.spawnCoords
    local x, y, z, heading = coords.x, coords.y, coords.z, coords.w or 0.0
    
    -- Create vehicle
    local vehicle = CreateVehicle(model, x, y, z + 1.0, heading, true, false)
    
    if vehicle and DoesEntityExist(vehicle) then
        -- Set plate
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
        
        -- Set fuel (if ox_fuel is available)
        if exports['ox_fuel'] then
            exports['ox_fuel']:SetFuel(vehicle, vehicleData.fuel or 100.0)
        end
        
        -- Put player in vehicle
        local ped = PlayerPedId()
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        
        -- Set vehicle as mission entity
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleEngineOn(vehicle, true, true, false)
        
        print('[DEBUG-ILLEGAL] ✅ Illegal vehicle spawned: ' .. vehicleData.plate)
    else
        print('[DEBUG-ILLEGAL] ❌ Failed to create vehicle')
    end
    
    SetModelAsNoLongerNeeded(model)
end)

-- Close Illegal Menu (from server)
RegisterNetEvent('heli-taxi:client:closeIllegalMenu', function()
    print('[DEBUG-ILLEGAL] ✅ Server requested menu close')
    illegalMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeIllegalMenu'
    })
end)

-- Close any illegal UI
RegisterNUICallback('closeIllegalMenu', function(data, cb)
    print('[DEBUG-ILLEGAL] ✅ Closing illegal menu')
    illegalMenuOpen = false
    SetNuiFocus(false, false)
    
    -- DO NOT send closeIllegalMenu back to NUI - it creates an infinite loop!
    -- The NUI already closed itself before calling this callback
    
    cb('ok')
end)

-- Set illegal flag when illegal vehicle management opens
-- This is triggered AFTER the main getVehicles event in menu.lua
AddEventHandler('heli-taxi:client:getVehicles', function(vehicles, helipadIndex, isIllegal)
    -- Set flag ONLY for illegal menus to prevent marker spam
    if isIllegal then
        illegalMenuOpen = true
    end
end)

-- Reset flag when UI closes
RegisterNUICallback('closeUI', function(data, cb)
    illegalMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Reset illegal menu flag (used when server denies access)
RegisterNetEvent('heli-taxi:client:resetIllegalMenuFlag', function()
    illegalMenuOpen = false
    print('[DEBUG-ILLEGAL] ⚠ Menu flag reset (access denied or error)')
end)

-- Resource Stop - Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DeleteAllIllegalNPCs()
end)

-- Player Loaded
RegisterNetEvent('heli-taxi:client:playerLoaded', function(employeeData)
    if employeeData and employeeData.grade then
        playerGrade = employeeData.grade
        hasAccess = HasIllegalAccess()
        if hasAccess then
            SpawnAllIllegalNPCs()
        end
    end
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NUI CALLBACKS FOR ILLEGAL SHOP & GARAGE
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Buy Illegal Vehicle (from Shop)
RegisterNUICallback('buyIllegalVehicle', function(data, cb)
    print('[DEBUG-ILLEGAL] ▶ Buying illegal vehicle: ' .. tostring(data.model) .. ' | Price: $' .. tostring(data.price))
    
    -- Send to server to purchase
    TriggerServerEvent('heli-taxi:server:purchaseIllegalVehicle', data.model, data.price)
    
    cb('ok')
end)

-- Spawn Illegal Vehicle (from Garage) - Both callbacks for compatibility
RegisterNUICallback('spawnIllegalVehicleById', function(data, cb)
    print('[DEBUG-ILLEGAL] ▶ Spawning illegal vehicle ID: ' .. tostring(data.vehicleId))
    
    -- Send to server to spawn
    TriggerServerEvent('heli-taxi:server:spawnIllegalVehicle', data.vehicleId, currentHelipadIndex)
    
    -- Close menu
    illegalMenuOpen = false
    SetNuiFocus(false, false)
    
    cb('ok')
end)

-- Alias for spawnIllegalVehicle (JS uses both names)
RegisterNUICallback('spawnIllegalVehicle', function(data, cb)
    print('[DEBUG-ILLEGAL] ▶ Spawning illegal vehicle ID (alias): ' .. tostring(data.vehicleId))
    
    -- Send to server to spawn
    TriggerServerEvent('heli-taxi:server:spawnIllegalVehicle', data.vehicleId, currentHelipadIndex)
    
    -- Close menu
    illegalMenuOpen = false
    SetNuiFocus(false, false)
    
    cb('ok')
end)

-- Request Illegal Shop (from Boss Menu button)
RegisterNUICallback('requestIllegalShop', function(data, cb)
    print('[DEBUG-ILLEGAL] ▶ Requesting illegal shop from UI')
    TriggerServerEvent('heli-taxi:server:requestIllegalShopAccess')
    cb('ok')
end)

-- Request Illegal Garage (from Boss Menu button)  
RegisterNUICallback('requestIllegalGarage', function(data, cb)
    print('[DEBUG-ILLEGAL] ▶ Requesting illegal garage from UI | Helipad: ' .. tostring(data.helipadIndex))
    currentHelipadIndex = data.helipadIndex or 1
    TriggerServerEvent('heli-taxi:server:getVehicles', currentHelipadIndex)
    cb('ok')
end)

if Config.Debug then
end
