-- Vehicle Management System
local SpawnedVehicles = {}

-- On server start, return all "in_use" vehicles to garage
MySQL.ready(function()
    -- Auto-return vehicles to garage on server restart
    MySQL.update([[
        UPDATE heli_taxi_vehicles 
        SET status = 'available', last_used = NOW() 
        WHERE status = 'in_use'
    ]], {}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            print('[Heli-Taxi] ✅ ' .. affectedRows .. ' vehicle(s) returned to garage after restart')
        end
    end)
end)

-- Get Available Vehicles
RegisterNetEvent('heli-taxi:server:getVehicles', function(helipadIndex)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local rank = GetEmployeeRank(identifier, src)
    local isIllegal = (helipadIndex ~= nil)  -- If helipadIndex is provided, it's from illegal garage
    
    print('[DEBUG-SERVER] ▶ getVehicles called | HelipadIndex: ' .. tostring(helipadIndex) .. ' | Illegal: ' .. tostring(isIllegal))
    
    -- Check if illegal garage access is allowed
    if isIllegal then
        if not HasIllegalAccess(identifier, src) then
            print('[DEBUG-SERVER] ❌ ACCESS DENIED | No illegal garage access | Rank: ' .. tostring(rank))
            TriggerClientEvent('heli-taxi:client:notify', src, 'Kein Zugriff auf illegale Garage!', 'error')
            return
        end
        print('[DEBUG-SERVER] ✅ Illegal garage access granted | Rank: ' .. tostring(rank))
    end
    
    print('[DEBUG-SERVER] ▶ Querying database...')
    
    -- Use correct table based on illegal or normal
    if isIllegal then
        -- Query illegal vehicles table for the specific helipad
        MySQL.query('SELECT * FROM heli_taxi_illegal_vehicles WHERE helipad_index = ? ORDER BY purchase_date DESC', {helipadIndex}, function(vehicles)
            if not vehicles then
                print('[DEBUG-SERVER] ❌ DB QUERY FAILED - No illegal vehicles returned!')
                TriggerClientEvent('heli-taxi:client:openIllegalGarage', src, {}, helipadIndex)
                return
            end
            
            print('[DEBUG-SERVER] ✅ DB QUERY SUCCESS | Illegal vehicle count: ' .. #vehicles .. ' | Sending to client...')
            TriggerClientEvent('heli-taxi:client:openIllegalGarage', src, vehicles, helipadIndex)
        end)
    else
        -- Query normal vehicles table
        MySQL.query('SELECT * FROM heli_taxi_vehicles ORDER BY purchase_date DESC', {}, function(vehicles)
            if not vehicles then
                print('[DEBUG-SERVER] ❌ DB QUERY FAILED - No vehicles returned!')
                TriggerClientEvent('heli-taxi:client:getVehicles', src, {}, helipadIndex, false)
                return
            end
            
            print('[DEBUG-SERVER] ✅ DB QUERY SUCCESS | Vehicle count: ' .. #vehicles .. ' | Sending to client...')
            TriggerClientEvent('heli-taxi:client:getVehicles', src, vehicles, helipadIndex, false)
        end)
    end
end)

-- Purchase Vehicle
RegisterNetEvent('heli-taxi:server:purchaseVehicle', function(vehicleModel)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_fleet', src) then
        Framework.Notify(src, 'You do not have permission to purchase vehicles', 'error')
        return
    end
    
    -- Find vehicle config
    local vehicleConfig = nil
    for _, veh in pairs(Config.Vehicles) do
        if veh.model == vehicleModel then
            vehicleConfig = veh
            break
        end
    end
    
    if not vehicleConfig then
        Framework.Notify(src, 'Invalid vehicle model', 'error')
        return
    end
    
    if vehicleConfig.starter then
        Framework.Notify(src, 'This vehicle is already in your fleet', 'error')
        return
    end
    
    -- Check company balance
    MySQL.query('SELECT balance FROM heli_taxi_company LIMIT 1', {}, function(result)
        if not result or not result[1] then
            Framework.Notify(src, 'Error accessing company account', 'error')
            return
        end
        
        local balance = result[1].balance
        
        if balance < vehicleConfig.price then
            Framework.Notify(src, 'Insufficient company funds. Need: $' .. vehicleConfig.price .. ', Have: $' .. balance, 'error')
            return
        end
        
        -- Generate unique plate with retry logic
        local plate = nil
        local maxRetries = 10
        local retries = 0
        
        while retries < maxRetries do
            local candidatePlate = 'HELI' .. math.random(100, 999)
            local existing = MySQL.query.await('SELECT plate FROM heli_taxi_vehicles WHERE plate = ?', {candidatePlate})
            if not existing or #existing == 0 then
                plate = candidatePlate
                break
            end
            retries = retries + 1
        end
        
        if not plate then
            Framework.Notify(src, 'Could not generate unique plate, please try again', 'error')
            return
        end
        
        -- Insert vehicle
        MySQL.insert('INSERT INTO heli_taxi_vehicles (model, plate, condition, fuel, status) VALUES (?, ?, ?, ?, ?)',
            {vehicleModel, plate, 100.0, vehicleConfig.maxFuel, 'available'}, function(insertId)
            if insertId then
                -- Deduct from company balance
                MySQL.update('UPDATE heli_taxi_company SET balance = balance - ?, total_expenses = total_expenses + ?',
                    {vehicleConfig.price, vehicleConfig.price})
                
                -- Log transaction
                MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                    {'purchase', vehicleConfig.price, 'Purchased ' .. vehicleConfig.label, identifier, Framework.GetPlayerName(src)})
                
                Framework.Notify(src, 'Successfully purchased ' .. vehicleConfig.label .. ' for $' .. vehicleConfig.price, 'success')
                
                -- Update vehicle list for requesting client
                MySQL.query('SELECT * FROM heli_taxi_vehicles ORDER BY purchase_date DESC', {}, function(vehicles)
                    TriggerClientEvent('heli-taxi:client:getVehicles', src, vehicles or {}, nil, false)
                end)
            end
        end)
    end)
end)

-- Spawn Vehicle
RegisterNetEvent('heli-taxi:server:spawnVehicle', function(plate, helipadIndex)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not IsEmployee(identifier, src) then
        Framework.Notify(src, 'You are not an employee', 'error')
        return
    end
    
    -- Check if on duty (only for internal employee system, not framework job)
    if not Framework.HasJob(src) then
        local emp = GetEmployee(identifier, src)
        if not emp or emp.status ~= 'on_duty' then
            Framework.Notify(src, 'You must be on duty to spawn vehicles', 'error')
            return
        end
    end
    
    -- Check if vehicle exists and is available
    MySQL.query('SELECT * FROM heli_taxi_vehicles WHERE plate = ? AND status = "available"', {plate}, function(result)
        if not result or not result[1] then
            Framework.Notify(src, 'Fahrzeug nicht verfügbar', 'error')
            print('[Heli-Taxi] Vehicle not available: ' .. plate)
            return
        end
        
        local vehicle = result[1]
        
        -- Helper function to spawn vehicle after all checks/updates
        local function doSpawn()
            -- Update vehicle status to in_use
            MySQL.update('UPDATE heli_taxi_vehicles SET status = "in_use" WHERE plate = ?', 
                {plate}, function(affectedRows)
                
                if affectedRows and affectedRows > 0 then
                    print('[Heli-Taxi] Spawning vehicle ' .. vehicle.model .. ' (' .. plate .. ') for player ' .. src)
                    
                    -- Trigger client spawn event
                    TriggerClientEvent('heli-taxi:client:spawnVehicle', src, vehicle, helipadIndex)
                else
                    Framework.Notify(src, 'Fehler beim Spawnen', 'error')
                    print('[Heli-Taxi] ERROR: Failed to update vehicle status for ' .. plate)
                end
            end)
        end
        
        -- Check company balance for spawn fee
        if Config.BusinessCosts and Config.BusinessCosts.spawnFee and Config.BusinessCosts.spawnFee > 0 then
            GetCompanyBalance(function(companyBalance)
                local maxDebt = Config.DebtSystem and Config.DebtSystem.maxCompanyDebt or 50000
                
                -- Check if company would exceed debt limit
                if companyBalance - Config.BusinessCosts.spawnFee < -maxDebt then
                    Framework.Notify(src, 'Firmenkasse hat Kreditlimit erreicht!', 'error')
                    return
                end
                
                -- Get helipad name for transaction
                local helipadName = 'Unbekannt'
                if Config.Locations.Helipads and Config.Locations.Helipads[helipadIndex] then
                    helipadName = Config.Locations.Helipads[helipadIndex].label
                end
                
                -- Deduct spawn fee from company
                MySQL.update('UPDATE heli_taxi_company SET balance = balance - ?, total_expenses = total_expenses + ?', 
                    {Config.BusinessCosts.spawnFee, Config.BusinessCosts.spawnFee}, function(rows)
                    
                    -- Log transaction
                    MySQL.insert([[
                        INSERT INTO heli_taxi_transactions 
                        (transaction_type, amount, description, performer_identifier, performer_name)
                        VALUES (?, ?, ?, ?, ?)
                    ]], {
                        'expense',
                        Config.BusinessCosts.spawnFee,
                        'Helikopter-Bereitstellung - ' .. helipadName,
                        identifier,
                        Framework.GetPlayerName(src)
                    }, function(insertId)
                        -- Notify player about spawn fee
                        Framework.Notify(src, '🚁 Spawn-Gebühr $' .. Config.BusinessCosts.spawnFee .. ' abgebucht', 'primary')
                        
                        -- Now spawn the vehicle
                        doSpawn()
                    end)
                end)
            end)
        else
            -- No spawn fee configured, just spawn vehicle directly
            doSpawn()
        end
    end)
end)

-- Return Vehicle
RegisterNetEvent('heli-taxi:server:returnVehicle', function(plate, condition, fuel)
    local src = source
    
    MySQL.update('UPDATE heli_taxi_vehicles SET status = "available", condition = ?, fuel = ? WHERE plate = ?',
        {condition, fuel, plate}, function(affectedRows)
        if affectedRows > 0 then
            Framework.Notify(src, 'Vehicle returned successfully', 'success')
            
            -- Remove from spawned vehicles
            if SpawnedVehicles[plate] then
                SpawnedVehicles[plate] = nil
            end
        end
    end)
end)

-- Update Vehicle Fuel (called periodically during flight)
RegisterNetEvent('heli-taxi:server:updateVehicleFuel', function(plate, fuel)
    -- No permission check needed - this is automatic
    MySQL.update('UPDATE heli_taxi_vehicles SET fuel = ? WHERE plate = ?', {
        fuel,
        plate
    })
end)

-- Store Vehicle (remote garage storage from UI)
RegisterNetEvent('heli-taxi:server:storeVehicle', function(data)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local plate = data.plate
    
    if not IsEmployee(identifier, src) then
        Framework.Notify(src, 'No permission', 'error')
        return
    end
    
    -- Update vehicle status to available
    MySQL.update('UPDATE heli_taxi_vehicles SET status = ?, last_used = NOW() WHERE plate = ?', {
        'available',
        plate
    }, function(affectedRows)
        if affectedRows > 0 then
            print('[Heli-Taxi] 🏢 Vehicle ' .. plate .. ' stored in garage remotely')
            Framework.Notify(src, 'Fahrzeug in Garage eingelagert', 'success')
            
            -- Notify client to delete the vehicle entity
            TriggerClientEvent('heli-taxi:client:deleteStoredVehicle', src, plate)
        end
    end)
end)

-- Update Vehicle Status
RegisterNetEvent('heli-taxi:server:updateVehicleStatus', function(plate, condition, fuel, distance)
    MySQL.update('UPDATE heli_taxi_vehicles SET condition = ?, fuel = ?, total_distance = total_distance + ? WHERE plate = ?',
        {condition, fuel, distance, plate})
end)

-- Get Shop Vehicles (NEW)
RegisterNetEvent('heli-taxi:server:getShopVehicles', function()
    local src = source
    
    -- Get all available vehicle models from config
    local shopVehicles = {}
    for _, vehicle in ipairs(Config.Vehicles) do
        table.insert(shopVehicles, {
            model = vehicle.model,
            label = vehicle.label,
            price = vehicle.price,
            category = vehicle.category or 'standard'
        })
    end
    
    -- Send to client
    TriggerClientEvent('heli-taxi:client:receiveShopVehicles', src, shopVehicles)
end)

-- Check Vehicle Access (Key System) - DISABLED
RegisterNetEvent('heli-taxi:server:checkVehicleAccess', function(plate, isDriver)
    -- ✅ ACCESS CHECK DISABLED - Everyone can use company helicopters
    -- No restrictions, no employee checks, no kicks
    return
end)

-- Vehicle Lost (entity cleaned up by game)
RegisterNetEvent('heli-taxi:server:vehicleLost', function(plate)
    if not plate then return end
    
    -- Auto-return to garage when vehicle entity is lost
    MySQL.update([[
        UPDATE heli_taxi_vehicles 
        SET status = 'available', last_used = NOW() 
        WHERE plate = ? AND status = 'in_use'
    ]], {plate}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            print('[Heli-Taxi] ✅ Vehicle ' .. plate .. ' auto-returned to garage (entity lost)')
        end
    end)
end)

-- Get Vehicle Shop Data
RegisterNetEvent('heli-taxi:server:getVehicleShop', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_fleet', src) then
        Framework.Notify(src, 'You do not have permission to access vehicle shop', 'error')
        return
    end
    
    -- Get owned vehicles
    MySQL.query('SELECT model FROM heli_taxi_vehicles', {}, function(owned)
        local ownedModels = {}
        if owned then
            for _, veh in pairs(owned) do
                ownedModels[veh.model] = true
            end
        end
        
        -- Get company balance
        MySQL.query('SELECT balance FROM heli_taxi_company LIMIT 1', {}, function(company)
            local balance = company and company[1] and company[1].balance or 0
            
            -- Build shop data
            local shopData = {
                balance = balance,
                vehicles = {}
            }
            
            for _, veh in pairs(Config.Vehicles) do
                if not veh.starter then
                    table.insert(shopData.vehicles, {
                        model = veh.model,
                        label = veh.label,
                        price = veh.price,
                        category = veh.category,
                        owned = ownedModels[veh.model] or false
                    })
                end
            end
            
            TriggerClientEvent('heli-taxi:client:receiveVehicleShop', src, shopData)
        end)
    end)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ILLEGAL VEHICLE SYSTEM (Separate from normal system)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Purchase Illegal Vehicle
RegisterNetEvent('heli-taxi:server:purchaseIllegalVehicle', function(vehicleModel, price)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local rank = GetEmployeeRank(identifier, src)
    
    print('[DEBUG-ILLEGAL] ▶ Purchase illegal vehicle request | Model: ' .. tostring(vehicleModel) .. ' | Price: $' .. tostring(price))
    
    -- Check illegal access
    if not HasIllegalAccess(identifier, src) then
        print('[DEBUG-ILLEGAL] ❌ ACCESS DENIED for purchase')
        Framework.Notify(src, 'Kein Zugriff auf illegalen Shop!', 'error')
        return
    end
    
    -- Find vehicle in config
    local vehicleConfig = nil
    for _, veh in pairs(Config.Vehicles) do
        if veh.model == vehicleModel and veh.militaryOnly == true then
            vehicleConfig = veh
            break
        end
    end
    
    if not vehicleConfig then
        Framework.Notify(src, 'Ungültiges Fahrzeugmodell', 'error')
        return
    end
    
    -- Check illegal/company balance (from heli_taxi_company.illegal_balance)
    MySQL.query('SELECT illegal_balance FROM heli_taxi_company LIMIT 1', {}, function(result)
        if not result or not result[1] then
            Framework.Notify(src, 'Fehler beim Zugriff auf illegale Kasse', 'error')
            return
        end
        
        local balance = result[1].illegal_balance or 0
        
        if balance < vehicleConfig.price then
            Framework.Notify(src, 'Nicht genug Schwarzgeld. Benötigt: $' .. vehicleConfig.price .. ', Vorhanden: $' .. balance, 'error')
            return
        end
        
        -- Generate unique plate for illegal vehicle
        local plate = nil
        local maxRetries = 10
        local retries = 0
        
        while retries < maxRetries do
            local candidatePlate = 'ARMY' .. math.random(100, 999)
            local existing = MySQL.query.await('SELECT plate FROM heli_taxi_illegal_vehicles WHERE plate = ?', {candidatePlate})
            if not existing or #existing == 0 then
                plate = candidatePlate
                break
            end
            retries = retries + 1
        end
        
        if not plate then
            Framework.Notify(src, 'Konnte kein Kennzeichen generieren, bitte erneut versuchen', 'error')
            return
        end
        
        -- Insert into illegal vehicles table (helipad_index = 1 as default)
        MySQL.insert('INSERT INTO heli_taxi_illegal_vehicles (model, plate, helipad_index, `condition`, fuel, status) VALUES (?, ?, ?, ?, ?, ?)',
            {vehicleModel, plate, 1, 100.0, vehicleConfig.maxFuel or 100, 'available'}, function(insertId)
            if insertId then
                -- Deduct from illegal balance
                MySQL.update('UPDATE heli_taxi_company SET illegal_balance = illegal_balance - ?, illegal_expenses = illegal_expenses + ?',
                    {vehicleConfig.price, vehicleConfig.price})
                
                -- Log transaction in illegal transactions table
                MySQL.insert('INSERT INTO heli_taxi_illegal_transactions (transaction_type, amount, description, performer_identifier, performer_name, transaction_date) VALUES (?, ?, ?, ?, ?, ?)',
                    {'purchase', vehicleConfig.price, 'Gekauft: ' .. vehicleConfig.label, identifier, Framework.GetPlayerName(src), os.date('%Y-%m-%d %H:%M:%S')})
                
                print('[DEBUG-ILLEGAL] ✅ Purchased illegal vehicle: ' .. vehicleConfig.label .. ' | Plate: ' .. plate)
                Framework.Notify(src, 'Erfolgreich gekauft: ' .. vehicleConfig.label .. ' für $' .. vehicleConfig.price, 'success')
                
                -- Close menu and notify
                TriggerClientEvent('heli-taxi:client:closeIllegalMenu', src)
            else
                Framework.Notify(src, 'Fehler beim Speichern des Fahrzeugs', 'error')
            end
        end)
    end)
end)

-- Spawn Illegal Vehicle
RegisterNetEvent('heli-taxi:server:spawnIllegalVehicle', function(vehicleId, helipadIndex)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    print('[DEBUG-ILLEGAL] ▶ Spawn illegal vehicle request | ID: ' .. tostring(vehicleId) .. ' | Helipad: ' .. tostring(helipadIndex))
    
    -- Check illegal access
    if not HasIllegalAccess(identifier, src) then
        print('[DEBUG-ILLEGAL] ❌ ACCESS DENIED for spawn')
        Framework.Notify(src, 'Kein Zugriff auf illegale Garage!', 'error')
        return
    end
    
    -- Get vehicle from database
    MySQL.query('SELECT * FROM heli_taxi_illegal_vehicles WHERE id = ?', {vehicleId}, function(result)
        if not result or not result[1] then
            Framework.Notify(src, 'Fahrzeug nicht gefunden', 'error')
            return
        end
        
        local vehicle = result[1]
        
        if vehicle.status ~= 'available' then
            Framework.Notify(src, 'Fahrzeug ist bereits in Benutzung', 'error')
            return
        end
        
        -- Get helipad spawn location
        local helipadConfig = Config.IllegalLocations and Config.IllegalLocations.Helipads and Config.IllegalLocations.Helipads[helipadIndex or 1]
        if not helipadConfig then
            Framework.Notify(src, 'Helipad nicht gefunden', 'error')
            return
        end
        
        -- Update vehicle status
        MySQL.update('UPDATE heli_taxi_illegal_vehicles SET status = ?, last_used = NOW() WHERE id = ?', {'in_use', vehicleId})
        
        -- Spawn vehicle on client
        TriggerClientEvent('heli-taxi:client:spawnIllegalVehicle', src, {
            model = vehicle.model,
            plate = vehicle.plate,
            condition = vehicle.condition,
            fuel = vehicle.fuel,
            spawnCoords = helipadConfig.coords
        })
        
        print('[DEBUG-ILLEGAL] ✅ Spawning illegal vehicle: ' .. vehicle.model .. ' | Plate: ' .. vehicle.plate)
        Framework.Notify(src, 'Fahrzeug wird ausgeparkt: ' .. vehicle.model, 'success')
    end)
end)

-- Return Illegal Vehicle to Garage
RegisterNetEvent('heli-taxi:server:returnIllegalVehicle', function(plate, condition, fuel)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    print('[DEBUG-ILLEGAL] ▶ Return illegal vehicle | Plate: ' .. tostring(plate))
    
    -- Update vehicle status
    MySQL.update([[
        UPDATE heli_taxi_illegal_vehicles 
        SET status = 'available', `condition` = ?, fuel = ? 
        WHERE plate = ? AND status = 'in_use'
    ]], {condition or 100, fuel or 100, plate}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            print('[DEBUG-ILLEGAL] ✅ Illegal vehicle returned: ' .. plate)
            Framework.Notify(src, 'Fahrzeug eingeparkt', 'success')
        end
    end)
end)
