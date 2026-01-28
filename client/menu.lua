-- Menu System
local menuOpen = false

-- Open Boss Menu
function OpenBossMenu()
    -- Request fresh employee data from server before opening menu
    TriggerServerEvent('heli-taxi:server:requestEmployeeDataForMenu')
end

-- Receive employee data and open Boss Menu
RegisterNetEvent('heli-taxi:client:openBossMenuWithData', function(data)
    -- CRITICAL: Update grade for illegal_locations.lua
    -- This ensures Boss can see illegal markers even when opening Boss Menu
    if data and data.rank then
        TriggerEvent('heli-taxi:client:updateGrade', data.rank)
    end
    
    -- Send background config first
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
    SendNUIMessage({
        action = 'openBossMenu',
        employeeData = data  -- Fresh data from server!
    })
    
    -- Wait for UI to initialize before setting focus
    Citizen.Wait(100)
    
    SetNuiFocus(true, true)
    menuOpen = true
end)

-- Command to open boss menu (Tablet)
RegisterCommand('helitaxi', function()
    if IsHeliTaxiEmployee() then
        OpenBossMenu()
    else
        Framework.Notify(_U('not_employee'), 'error')
    end
end, false)

RegisterCommand('tablet', function()
    if IsHeliTaxiEmployee() then
        OpenBossMenu()
    else
        Framework.Notify(_U('not_employee'), 'error')
    end
end, false)

-- Duty command
RegisterCommand('duty', function()
    if IsHeliTaxiEmployee() then
        TriggerServerEvent('heli-taxi:server:toggleDuty')
    else
        Framework.Notify(_U('not_employee'), 'error')
    end
end, false)

-- Open Wardrobe
function OpenWardrobe()
    -- Send background config first
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
    SendNUIMessage({
        action = 'openOutfitDialog'
    })
    
    -- Wait for UI to initialize before setting focus
    Citizen.Wait(100)
    
    SetNuiFocus(true, true)
    menuOpen = true
end

-- Open Vehicle Management
function OpenVehicleManagement()
    -- Send background config first
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
    -- Request vehicles from server with nil helipadIndex (= normal garage)
    -- UI will be opened by the 'heli-taxi:client:getVehicles' event handler
    TriggerServerEvent('heli-taxi:server:getVehicles', nil)
end

-- Receive Vehicles from Server and Open Vehicle Management (NORMAL GARAGE)
RegisterNetEvent('heli-taxi:client:getVehicles', function(vehicles, helipadIndex, isIllegal)
    print('[DEBUG-VEHICLE] ✅ Received vehicles from server | Count: ' .. #vehicles .. ' | Illegal: ' .. tostring(isIllegal))
    
    -- Update vehicle list
    SendNUIMessage({
        action = 'updateVehicleList',
        vehicles = vehicles
    })
    print('[DEBUG-VEHICLE] ▶ Sent updateVehicleList to UI')
    
    -- Open Vehicle Management UI
    SendNUIMessage({
        action = 'openVehicleManagement',
        illegal = isIllegal or false,
        helipadIndex = helipadIndex
    })
    print('[DEBUG-VEHICLE] ▶ Sent openVehicleManagement to UI | Setting focus...')
    
    Citizen.Wait(100)
    SetNuiFocus(true, true)
    menuOpen = true  -- Set flag so closeUI works correctly
    print('[DEBUG-VEHICLE] ✅ Vehicle Management opened | Focus set')
end)

-- Open Vehicle Shop
function OpenVehicleShop()
    -- Send background config first
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
    -- Request available vehicles from server
    TriggerServerEvent('heli-taxi:server:getShopVehicles')
    
    SendNUIMessage({
        action = 'openVehicleShop'
    })
    
    -- Wait for UI to initialize before setting focus
    Citizen.Wait(100)
    
    SetNuiFocus(true, true)
    menuOpen = true
end

-- Open Illegal Vehicle Shop (Army Helis)
function OpenIllegalVehicleShop()
    -- Check if employee OR boss (boss can access without employee status)
    if not isEmployee and not IsBoss() then
        Framework.Notify('Kein Zugriff!', 'error')
        return
    end
    
    -- Request illegal shop access from server (validates HasIllegalAccess)
    TriggerServerEvent('heli-taxi:server:requestIllegalShopAccess')
    
    -- Send background config first
    SendNUIMessage({
        action = 'setBackground',
        enabled = Config.UIBackground and Config.UIBackground.enabled or false,
        image = Config.UIBackground and Config.UIBackground.image or 'background.png',
        opacity = Config.UIBackground and Config.UIBackground.opacity or 85,
        blur = Config.UIBackground and Config.UIBackground.blur or true,
        blurStrength = Config.UIBackground and Config.UIBackground.blurStrength or 5
    })
    
end

-- NOTE: Illegal shop handler moved to illegal_locations.lua to avoid duplicate registration
-- This prevents the freeze issue when opening illegal shop

-- Close Menu
RegisterNUICallback('closeMenu', function(data, cb)
    -- Ensure input is fully released in correct order
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    menuOpen = false
    
    -- Clear any lingering controls
    CreateThread(function()
        Wait(100)
        -- Force enable all controls after closing
        EnableAllControlActions(0)
    end)
    
    cb('ok')
end)

-- ESC key handler to prevent freeze
CreateThread(function()
    while true do
        Wait(0)
        if menuOpen then
            -- Disable ESC from game menu when NUI is open
            DisableControlAction(0, 322, true) -- ESC key
            DisableControlAction(0, 177, true) -- Backspace (Cancel)
            
            -- Manual ESC handling
            if IsDisabledControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 177) then
                SendNUIMessage({ action = 'forceClose' })
                SetNuiFocusKeepInput(false)
                SetNuiFocus(false, false)
                menuOpen = false
                Wait(100)
                EnableAllControlActions(0)
            end
        else
            Wait(500) -- Sleep when menu is closed
        end
    end
end)

-- Toggle Duty
RegisterNUICallback('toggleDuty', function(data, cb)
    TriggerServerEvent('heli-taxi:server:toggleDuty')
    cb('ok')
end)

-- Get Employees
RegisterNUICallback('getEmployees', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getAllEmployees')
    cb('ok')
end)

-- Get Statistics
RegisterNUICallback('getStatistics', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getStatistics')
    cb('ok')
end)

-- Get Nearby Players
RegisterNUICallback('getNearbyPlayers', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getNearbyPlayers')
    cb('ok')
end)

-- Hire Employee
RegisterNUICallback('hireEmployee', function(data, cb)
    TriggerServerEvent('heli-taxi:server:hireEmployee', data.targetSource)
    cb('ok')
end)

-- Fire Employee
RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('heli-taxi:server:fireEmployee', data.identifier)
    cb('ok')
end)

-- Promote Employee
RegisterNUICallback('promoteEmployee', function(data, cb)
    TriggerServerEvent('heli-taxi:server:promoteEmployee', data.identifier)
    cb('ok')
end)

-- Demote Employee
RegisterNUICallback('demoteEmployee', function(data, cb)
    TriggerServerEvent('heli-taxi:server:demoteEmployee', data.identifier)
    cb('ok')
end)

-- Set Employee Rank (NEW! For rank dropdown in Boss Menu)
RegisterNUICallback('setEmployeeRank', function(data, cb)
    TriggerServerEvent('heli-taxi:server:setEmployeeRank', data.identifier, data.rank)
    cb('ok')
end)

-- Get Vehicle Shop
RegisterNUICallback('getVehicleShop', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getVehicleShop')
    cb('ok')
end)

-- Purchase Vehicle
RegisterNUICallback('purchaseVehicle', function(data, cb)
    TriggerServerEvent('heli-taxi:server:purchaseVehicle', data.model)
    
    -- Release NUI focus to prevent freeze (same as wardrobe fix)
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    menuOpen = false
    
    cb('ok')
end)

-- Spawn Vehicle
RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('heli-taxi:server:spawnVehicle', data.plate, data.helipadIndex)
    cb('ok')
end)

-- Get Transactions
RegisterNUICallback('getTransactions', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getTransactions', data.limit or 50)
    cb('ok')
end)

-- Deposit Money
RegisterNUICallback('depositMoney', function(data, cb)
    TriggerServerEvent('heli-taxi:server:depositMoney', data.amount)
    cb('ok')
end)

-- Withdraw Money
RegisterNUICallback('withdrawMoney', function(data, cb)
    TriggerServerEvent('heli-taxi:server:withdrawMoney', data.amount)
    cb('ok')
end)

-- Get Balance
RegisterNUICallback('getBalance', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getBalance')
    cb('ok')
end)

-- Get Vehicles
RegisterNUICallback('getVehicles', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getVehicles')
    cb('ok')
end)

-- Store Vehicle in Garage
RegisterNUICallback('storeVehicle', function(data, cb)
    TriggerServerEvent('heli-taxi:server:storeVehicle', data)
    cb('ok')
end)

-- Delete Stored Vehicle Entity (triggered by server)
RegisterNetEvent('heli-taxi:client:deleteStoredVehicle', function(plate)
    -- Check if this is the current vehicle
    if currentVehicle and DoesEntityExist(currentVehicle) then
        local vehiclePlate = GetVehicleNumberPlateText(currentVehicle)
        if vehiclePlate and string.find(vehiclePlate, plate) then
            -- Delete the vehicle entity
            DeleteEntity(currentVehicle)
            currentVehicle = nil
            currentVehicleData = nil
            print('[Heli-Taxi] 🏢 Vehicle ' .. plate .. ' deleted and stored in garage')
        end
    end
end)

-- Receive Shop Vehicles from Server
RegisterNetEvent('heli-taxi:client:receiveShopVehicles', function(vehicles)
    SendNUIMessage({
        action = 'updateShopVehicles',
        vehicles = vehicles
    })
end)

-- Change Outfit
RegisterNUICallback('changeOutfit', function(data, cb)
    -- Release NUI focus IMMEDIATELY to prevent freeze
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    menuOpen = false
    cb('ok')
    
    local playerPed = PlayerPedId()
    local outfitType = data.outfitType
    local gender = GetEntityModel(playerPed) == GetHashKey('mp_m_freemode_01') and 'male' or 'female'
    
    if outfitType == 'pilot' then
        -- Simple pilot uniform like NPCs wear
        -- Male: White shirt, black pants, pilot cap
        -- Female: White shirt, black pants, pilot cap
        
        if gender == 'male' then
            -- Male Pilot Uniform (simple like NPC pilots)
            SetPedComponentVariation(playerPed, 8, 15, 0, 0)  -- Undershirt: White
            SetPedComponentVariation(playerPed, 11, 13, 0, 0) -- Torso: Pilot shirt
            SetPedComponentVariation(playerPed, 3, 11, 0, 0)  -- Arms
            SetPedComponentVariation(playerPed, 4, 10, 0, 0)  -- Pants: Black
            SetPedComponentVariation(playerPed, 6, 25, 0, 0)  -- Shoes: Black
            -- Pilot cap/hat
            SetPedPropIndex(playerPed, 0, 61, 0, 2) -- Pilot cap
        else
            -- Female Pilot Uniform
            SetPedComponentVariation(playerPed, 8, 14, 0, 0)  -- Undershirt: White
            SetPedComponentVariation(playerPed, 11, 27, 0, 0) -- Torso: Pilot shirt
            SetPedComponentVariation(playerPed, 3, 14, 0, 0)  -- Arms
            SetPedComponentVariation(playerPed, 4, 10, 0, 0)  -- Pants: Black
            SetPedComponentVariation(playerPed, 6, 25, 0, 0)  -- Shoes: Black
            -- Pilot cap/hat
            SetPedPropIndex(playerPed, 0, 61, 0, 2) -- Pilot cap
        end
        
        Framework.Notify(_U('pilot_uniform_equipped'), 'success')
        
    elseif outfitType == 'civilian' then
        -- Reload player's saved clothing
        if GetResourceState('qb-clothing') == 'started' then
            TriggerEvent('qb-clothing:client:reloadSkin')
        elseif GetResourceState('illenium-appearance') == 'started' then
            exports['illenium-appearance']:refreshPedModel()
        else
            -- ESX/Standalone: Reload saved skin
            if Framework.Core then
                TriggerEvent('skinchanger:loadSkin')
            end
        end
        
        Framework.Notify(_U('civilian_clothes_equipped'), 'success')
    end
    
    -- Close NUI after outfit change to prevent freeze
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    menuOpen = false
    
    cb('ok')
end)

-- Calendar / Appointments NUI Callbacks
RegisterNUICallback('getAppointments', function(data, cb)
    TriggerServerEvent('heli-taxi:server:getAppointments')
    cb('ok')
end)

RegisterNUICallback('createAppointment', function(data, cb)
    TriggerServerEvent('heli-taxi:server:createAppointment', data)
    cb('ok')
end)

RegisterNUICallback('updateAppointment', function(data, cb)
    TriggerServerEvent('heli-taxi:server:updateAppointment', data)
    cb('ok')
end)

RegisterNUICallback('deleteAppointment', function(data, cb)
    TriggerServerEvent('heli-taxi:server:deleteAppointment', data.id)
    cb('ok')
end)

-- Receive Data from Server
RegisterNetEvent('heli-taxi:client:receiveEmployees', function(employees)
    SendNUIMessage({
        action = 'receiveEmployees',
        employees = employees
    })
end)

RegisterNetEvent('heli-taxi:client:receiveStatistics', function(stats)
    SendNUIMessage({
        action = 'receiveStatistics',
        stats = stats
    })
end)

RegisterNetEvent('heli-taxi:client:receiveNearbyPlayers', function(players)
    SendNUIMessage({
        action = 'receiveNearbyPlayers',
        players = players
    })
end)

RegisterNetEvent('heli-taxi:client:receiveVehicleShop', function(shopData)
    SendNUIMessage({
        action = 'receiveVehicleShop',
        shopData = shopData
    })
end)

RegisterNetEvent('heli-taxi:client:receiveTransactions', function(transactions)
    SendNUIMessage({
        action = 'receiveTransactions',
        transactions = transactions
    })
end)

RegisterNetEvent('heli-taxi:client:receiveBalance', function(balance)
    SendNUIMessage({
        action = 'receiveBalance',
        balance = balance
    })
end)

RegisterNetEvent('heli-taxi:client:receiveAppointments', function(appointments)
    print('[Heli-Taxi] CLIENT: Received', #appointments, 'appointments from server')
    SendNUIMessage({
        type = 'receiveAppointments',
        appointments = appointments
    })
end)

RegisterNetEvent('heli-taxi:client:updateCompanyBalance', function(balance)
    SendNUIMessage({
        action = 'updateBalance',
        balance = balance
    })
end)

RegisterNetEvent('heli-taxi:client:receiveAppointments', function(appointments)
    SendNUIMessage({
        type = 'receiveAppointments',
        appointments = appointments
    })
end)
