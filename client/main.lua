-- Main Client File
local isEmployee = false
local onDuty = false
local employeeData = nil

-- NPC Storage
local spawnedNPCs = {}

-- Load Maze Bank Tower Interior (for office locations)
CreateThread(function()
    -- Request the Maze Bank Tower IPL
    RequestIpl("ex_dt1_02_office_02b")  -- Executive Office
    
    -- Get the interior ID
    local interiorId = GetInteriorAtCoords(-75.8466, -826.9893, 243.3859)
    
    if interiorId ~= 0 then
        -- Enable all interior props
        EnableInteriorProp(interiorId, "office_chairs")
        RefreshInterior(interiorId)
        print("[Heli-Taxi] Maze Bank Tower interior loaded")
    end
end)

-- Create Blips
CreateThread(function()
    if not Config.ShowBlips then return end
    
    -- HQ Blip
    local blip = AddBlipForCoord(Config.Locations.HQ.x, Config.Locations.HQ.y, Config.Locations.HQ.z)
    SetBlipSprite(blip, Config.CompanyBlip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.CompanyBlip.scale)
    SetBlipColour(blip, Config.CompanyBlip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.CompanyBlip.label)
    EndTextCommandSetBlipName(blip)
end)

-- Spawn NPCs
CreateThread(function()
    Wait(1000)
    
    -- Spawn Duty Toggle NPC (if it's a vector4, it's an NPC location)
    if Config.Locations.DutyToggle and type(Config.Locations.DutyToggle) == 'vector4' then
        local npcConfig = Config.Locations.DutyNPC or {}
        local model = GetHashKey(npcConfig.model or 'a_f_y_business_02')
        
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(1)
        end
        
        -- Use exact Z coordinate from config (works for both interior and exterior)
        local npc = CreatePed(4, model, Config.Locations.DutyToggle.x, Config.Locations.DutyToggle.y, Config.Locations.DutyToggle.z, Config.Locations.DutyToggle.w, false, true)
        SetEntityCoordsNoOffset(npc, Config.Locations.DutyToggle.x, Config.Locations.DutyToggle.y, Config.Locations.DutyToggle.z, false, false, false)
        SetEntityHeading(npc, Config.Locations.DutyToggle.w)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedCanRagdoll(npc, false)
        TaskStartScenarioInPlace(npc, npcConfig.scenario or 'WORLD_HUMAN_CLIPBOARD', 0, true)
        
        spawnedNPCs['dutyToggle'] = npc
    end
    
    -- Spawn Vehicle Management NPC (if it's a vector4, it's an NPC location)
    if Config.Locations.VehicleManagement and type(Config.Locations.VehicleManagement) == 'vector4' then
        local npcConfig = Config.Locations.VehicleManagementNPC or {}
        local model = GetHashKey(npcConfig.model or 's_m_m_pilot_02')
        
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(1)
        end
        
        -- Use exact Z coordinate from config (works for both interior and exterior)
        local npc = CreatePed(4, model, Config.Locations.VehicleManagement.x, Config.Locations.VehicleManagement.y, Config.Locations.VehicleManagement.z, Config.Locations.VehicleManagement.w, false, true)
        SetEntityCoordsNoOffset(npc, Config.Locations.VehicleManagement.x, Config.Locations.VehicleManagement.y, Config.Locations.VehicleManagement.z, false, false, false)
        SetEntityHeading(npc, Config.Locations.VehicleManagement.w)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetPedCanRagdoll(npc, false)
        TaskStartScenarioInPlace(npc, npcConfig.scenario or 'WORLD_HUMAN_CLIPBOARD', 0, true)
        
        spawnedNPCs['vehicleManagement'] = npc
    end
end)

-- Cleanup NPCs on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, npc in pairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
end)

-- Check Employee Status
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('heli-taxi:server:getEmployeeInfo')
end)

-- Receive Employee Info
RegisterNetEvent('heli-taxi:client:updateEmployeeInfo', function(data)
    if data then
        isEmployee = true
        employeeData = data
        onDuty = data.status == 'on_duty'
        
        -- CRITICAL: Trigger updateGrade event for illegal_locations.lua
        -- This enables Boss to see illegal markers automatically
        if data.rank then
            TriggerEvent('heli-taxi:client:updateGrade', data.rank)
        end
    else
        isEmployee = false
        employeeData = nil
        onDuty = false
        TriggerEvent('heli-taxi:client:updateGrade', nil)
    end
end)

-- Helper function: Check if player is Boss
-- WICHTIG: Boss bleibt Boss (rank='boss'), hat aber BEIDE permissions (normal UND illegal)
function IsBoss()
    return employeeData and employeeData.rank == 'boss'
end

-- Helper function: Check if player has illegal access
-- Boss hat AUTOMATISCH illegal access, ohne "illegal" rank zu sein!
-- Illegal employees (rank='illegal') sind NICHT boss, haben aber illegal access
function HasIllegalAccess()
    if not employeeData then return false end
    -- Boss hat ALLES (bleibt aber Boss rank='boss')
    if employeeData.rank == 'boss' then
        return true
    end
    -- "illegal" rank hat illegal access (ist aber NICHT boss)
    if employeeData.rank == 'illegal' then
        return true
    end
    return false
end

-- Set Duty Status
RegisterNetEvent('heli-taxi:client:setDuty', function(status)
    onDuty = status
    if employeeData then
        employeeData.status = status and 'on_duty' or 'off_duty'
    end
end)

-- GPS Employee Tracking System
local employeeBlips = {}

CreateThread(function()
    -- Wait for Framework to be ready
    while Framework == nil do
        Wait(100)
    end
    Wait(2000) -- Additional safety wait
    
    while true do
        Wait(5000) -- Update every 5 seconds
        
        if isEmployee and Framework and Framework.Functions then
            -- Request other employee positions from server
            Framework.Functions.TriggerCallback('heli-taxi:server:getEmployeePositions', function(employees)
                -- Clean up old blips
                for playerId, blip in pairs(employeeBlips) do
                    if DoesBlipExist(blip) then
                        RemoveBlip(blip)
                    end
                end
                employeeBlips = {}
                
                -- Create new blips for each employee
                for _, employee in pairs(employees) do
                    if employee.source ~= GetPlayerServerId(PlayerId()) then
                        local blip = AddBlipForCoord(employee.coords.x, employee.coords.y, employee.coords.z)
                        SetBlipSprite(blip, employee.inVehicle and 43 or 280) -- 43 = helicopter, 280 = player
                        SetBlipColour(blip, 2) -- Green
                        SetBlipScale(blip, 0.8)
                        SetBlipAsShortRange(blip, false)
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentString('👨‍✈️ ' .. employee.name)
                        EndTextCommandSetBlipName(blip)
                        
                        employeeBlips[employee.source] = blip
                    end
                end
            end)
        else
            -- Not an employee, clean up all blips
            for playerId, blip in pairs(employeeBlips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            employeeBlips = {}
        end
    end
end)

-- Draw Markers
CreateThread(function()
    local lastHelpTextShown = nil
    
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local currentHelpText = nil
        
        -- Boss Menu Marker
        local bossMenuDist = #(playerCoords - Config.Locations.BossMenu)
        if bossMenuDist < Config.DrawDistance then
            sleep = 0
            DrawMarker(
                Config.MarkerType,
                Config.Locations.BossMenu.x, Config.Locations.BossMenu.y, Config.Locations.BossMenu.z - 1.0,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
                Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
                false, true, 2, false, nil, nil, false
            )
            
            if bossMenuDist < 2.0 then
                currentHelpText = 'boss_menu'
                if Framework and Framework.ShowHelpNotification then
                    Framework.ShowHelpNotification(_U('open_boss_menu'))
                end
                
                if IsControlJustReleased(0, 38) then -- E key
                    if isEmployee then
                        OpenBossMenu()
                    else
                        if Framework and Framework.Notify then
                            Framework.Notify(_U('not_employee'), 'error')
                        end
                    end
                end
            end
        end
        
        -- Wardrobe Marker - FIX: Allow Boss to access even without employee check
        if Config.Locations.Wardrobe and (isEmployee or IsBoss()) then
            local wardrobeDist = #(playerCoords - Config.Locations.Wardrobe)
            if wardrobeDist < Config.DrawDistance then
                sleep = 0
                DrawMarker(
                    Config.MarkerType,
                    Config.Locations.Wardrobe.x, Config.Locations.Wardrobe.y, Config.Locations.Wardrobe.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
                    Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
                    false, true, 2, false, nil, nil, false
                )
                
                if wardrobeDist < 2.0 then
                    currentHelpText = 'wardrobe'
                    if Framework and Framework.ShowHelpNotification then
                        Framework.ShowHelpNotification(_U('open_wardrobe'))
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        if isEmployee or IsBoss() then
                            OpenWardrobe()
                        else
                            if Framework and Framework.Notify then
                                Framework.Notify(_U('not_employee'), 'error')
                            end
                        end
                    end
                end
            end
        end
        
        -- DutyToggle NPC Interaction (NPC already spawned above)
        if Config.Locations.DutyToggle and type(Config.Locations.DutyToggle) == 'vector4' then
            local dutyCoords = vec3(Config.Locations.DutyToggle.x, Config.Locations.DutyToggle.y, Config.Locations.DutyToggle.z)
            local dutyDist = #(playerCoords - dutyCoords)
            if vmDist < Config.DrawDistance then
                sleep = 0
                
                if vmDist < (Config.Locations.DutyNPC and Config.Locations.DutyNPC.interactDistance or 2.5) then
                    currentHelpText = 'duty_toggle'
                    if Framework and Framework.ShowHelpNotification then
                        Framework.ShowHelpNotification(_U('toggle_duty'))
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        if isEmployee then
                            TriggerServerEvent('heli-taxi:server:toggleDuty')
                        else
                            if Framework and Framework.Notify then
                                Framework.Notify(_U('not_employee'), 'error')
                            end
                        end
                    end
                end
            end
        end
        
        -- VehicleManagement NPC Interaction (NPC already spawned above)
        if Config.Locations.VehicleManagement and type(Config.Locations.VehicleManagement) == 'vector4' then
            local vmDist = #(playerCoords - vec3(Config.Locations.VehicleManagement.x, Config.Locations.VehicleManagement.y, Config.Locations.VehicleManagement.z))
            if vmDist < Config.DrawDistance then
                sleep = 0
                
                if vmDist < (Config.Locations.VehicleManagementNPC and Config.Locations.VehicleManagementNPC.interactDistance or 2.5) then
                    currentHelpText = 'vehicle_management'
                    if Framework and Framework.ShowHelpNotification then
                        Framework.ShowHelpNotification(_U('open_vehicle_management'))
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        if isEmployee then
                            OpenVehicleManagement()
                        else
                            if Framework and Framework.Notify then
                                Framework.Notify(_U('not_employee'), 'error')
                            end
                        end
                    end
                end
            end
        end
        
        -- Vehicle Shop Marker (Normal) - FIX: Allow Boss to access even without employee check
        if Config.Locations.VehicleShop and (isEmployee or IsBoss()) then
            local shopDist = #(playerCoords - Config.Locations.VehicleShop)
            if shopDist < Config.DrawDistance then
                sleep = 0
                DrawMarker(
                    Config.MarkerType,
                    Config.Locations.VehicleShop.x, Config.Locations.VehicleShop.y, Config.Locations.VehicleShop.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
                    Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a,
                    false, true, 2, false, nil, nil, false
                )
                
                if shopDist < 2.0 then
                    currentHelpText = 'vehicle_shop'
                    if Framework and Framework.ShowHelpNotification then
                        Framework.ShowHelpNotification(_U('open_vehicle_shop'))
                    end
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        if isEmployee or IsBoss() then
                            OpenVehicleShop()
                        else
                            if Framework and Framework.Notify then
                                Framework.Notify(_U('not_employee'), 'error')
                            end
                        end
                    end
                end
            end
        end
        
        -- Illegal Vehicle Shop Marker (Army Helis) - Boss can see ALL illegal markers!
        if HasIllegalAccess() and Config.IllegalLocations and Config.IllegalLocations.VehicleShop then
            local illegalShopConfig = Config.IllegalLocations.VehicleShop
            local illegalShopCoords = illegalShopConfig.coords or illegalShopConfig  -- Support both formats
            if illegalShopCoords and illegalShopCoords.x and illegalShopCoords.y and 
               (illegalShopCoords.x ~= 0.0 or illegalShopCoords.y ~= 0.0) then
                local illegalShopDist = #(playerCoords - illegalShopCoords)
                if illegalShopDist < Config.DrawDistance then
                    sleep = 0
                    DrawMarker(
                        Config.MarkerType,
                        illegalShopCoords.x, illegalShopCoords.y, illegalShopCoords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z,
                        255, 0, 0, 150,  -- RED for illegal shop!
                        false, true, 2, false, nil, nil, false
                    )
                    
                    if illegalShopDist < 2.0 then
                        currentHelpText = 'illegal_shop'
                        Framework.ShowHelpNotification('~r~[ILLEGAL SHOP]~s~ Drücke ~INPUT_CONTEXT~ für Army Helis')
                        
                        if IsControlJustReleased(0, 38) then -- E key
                            OpenIllegalVehicleShop()
                        end
                    end
                end
            end
        end
        
        -- Clear help text when moving away from markers
        if currentHelpText ~= lastHelpTextShown then
            if lastHelpTextShown ~= nil and currentHelpText == nil then
                Framework.HideHelpNotification()
            end
            lastHelpTextShown = currentHelpText
        end
        
        Wait(sleep)
    end
end)

-- Helper function to get employee status
function IsOnDuty()
    return onDuty
end

function GetEmployeeData()
    return employeeData
end

function IsHeliTaxiEmployee()
    return isEmployee
end

