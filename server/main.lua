-- Main Server File
Employees = {}  -- Global so other server files can access it
local ActiveFlights = {}

-- Initialize Database
CreateThread(function()
    Wait(1000)
    
    -- Ensure company record exists
    MySQL.query('SELECT * FROM heli_taxi_company LIMIT 1', {}, function(result)
        if not result or #result == 0 then
            local startBalance = Config.StartingBalance or 50000
            MySQL.insert('INSERT INTO heli_taxi_company (balance, total_income, total_expenses) VALUES (?, ?, ?)', 
                {startBalance, 0, 0})
            print('[Heli-Taxi] Company account initialized with $' .. startBalance)
        else
            print('[Heli-Taxi] Company account loaded - Balance: $' .. result[1].balance)
        end
    end)
    
    -- Load all employees
    MySQL.query('SELECT * FROM heli_taxi_employees', {}, function(employees)
        if employees then
            for _, emp in pairs(employees) do
                Employees[emp.identifier] = emp
            end
            print('[Heli-Taxi] Loaded ' .. #employees .. ' employees')
        end
    end)
    
    -- Ensure starter vehicles exist
    MySQL.query('SELECT COUNT(*) as count FROM heli_taxi_vehicles', {}, function(result)
        local count = result and result[1] and result[1].count or 0
        if count == 0 then
            -- Insert starter vehicles separately for proper parameter binding
            MySQL.insert('INSERT INTO heli_taxi_vehicles (model, plate, `condition`, fuel, status) VALUES (?, ?, ?, ?, ?)',
                {'frogger', 'HELI001', 100.0, 100.0, 'available'}, 
                function(insertId1)
                    if insertId1 then
                        MySQL.insert('INSERT INTO heli_taxi_vehicles (model, plate, `condition`, fuel, status) VALUES (?, ?, ?, ?, ?)',
                            {'swift', 'HELI002', 100.0, 100.0, 'available'}, 
                            function(insertId2)
                                if insertId2 then
                                    print('[Heli-Taxi] Starter vehicles initialized (Frogger + Swift)')
                                else
                                    print('[Heli-Taxi] WARNING: Failed to initialize Swift vehicle')
                                end
                            end)
                    else
                        print('[Heli-Taxi] WARNING: Failed to initialize starter vehicles')
                    end
                end)
        else
            print('[Heli-Taxi] Loaded ' .. count .. ' vehicles')
        end
    end)
end)

-- Get Company Balance (Helper Function)
function GetCompanyBalance(callback)
    MySQL.query('SELECT balance FROM heli_taxi_company LIMIT 1', {}, function(result)
        if result and result[1] then
            callback(result[1].balance)
        else
            callback(0)
        end
    end)
end

-- Check if player is employee (via framework job OR internal database)
function IsEmployee(identifier, source)
    -- Check framework job first
    if source and Framework.HasJob(source) then
        return true
    end
    -- Fallback to internal database for standalone
    return Employees[identifier] ~= nil
end

-- Get Employee Data (from framework or internal database)
function GetEmployee(identifier, source)
    -- If using framework, create employee data from job
    if source and Framework.HasJob(source) then
        local grade = Framework.GetJobGrade(source)
        if grade ~= nil then
            local rank = Framework.GetRankFromGrade(grade, source)
            local rankConfig = Config.Ranks[rank]
            return {
                identifier = identifier,
                name = Framework.GetPlayerName(source),
                rank = rank,
                salary = rankConfig and rankConfig.salary or 1500,
                status = 'off_duty', -- Default, will be updated
                total_flights = 0,
                total_distance = 0,
                total_earned = 0
            }
        end
    end
    -- Fallback to internal database
    return Employees[identifier]
end

-- Get Employee Rank
function GetEmployeeRank(identifier, source)
    print('[DEBUG-SERVER] ▶ GetEmployeeRank called')
    print('[DEBUG-SERVER]   └─ identifier: ' .. tostring(identifier))
    print('[DEBUG-SERVER]   └─ source: ' .. tostring(source))
    
    -- Check framework job first
    if source and Framework.HasJob(source) then
        print('[DEBUG-SERVER]   └─ Framework.HasJob(source): true')
        local grade = Framework.GetJobGrade(source)
        print('[DEBUG-SERVER]   └─ Framework.GetJobGrade returned: ' .. tostring(grade))
        if grade ~= nil then
            local rank = Framework.GetRankFromGrade(grade, source)
            print('[DEBUG-SERVER]   └─ ✅ Returning rank from Framework: ' .. tostring(rank))
            return rank
        else
            print('[DEBUG-SERVER]   └─ ❌ Grade is nil!')
        end
    else
        print('[DEBUG-SERVER]   └─ Framework.HasJob(source): ' .. tostring(Framework.HasJob(source)))
    end
    
    -- Fallback to internal database
    local emp = Employees[identifier]
    if emp then
        print('[DEBUG-SERVER]   └─ ✅ Returning rank from DB: ' .. tostring(emp.rank))
        return emp.rank
    else
        print('[DEBUG-SERVER]   └─ ❌ No employee found in DB')
        return nil
    end
end

-- Check Permission
function HasPermission(identifier, permission, source)
    local rank = GetEmployeeRank(identifier, source)
    if not rank then return false end
    
    -- Boss can do EVERYTHING - bypass all permission checks
    -- Boss has BOTH normal boss permissions AND illegal permissions
    if rank == 'boss' then
        return true
    end
    
    local rankConfig = Config.Ranks[rank]
    if not rankConfig then return false end
    
    return rankConfig.permissions[permission] == true
end

-- Check if player has illegal access (Boss OR illegal rank)
function HasIllegalAccess(identifier, source)
    local rank = GetEmployeeRank(identifier, source)
    
    print('[DEBUG-SERVER] ▶ HasIllegalAccess check')
    print('[DEBUG-SERVER]   └─ Rank: ' .. tostring(rank))
    
    if not rank then
        print('[DEBUG-SERVER]   └─ Result: FALSE (no rank)')
        return false
    end
    
    -- Boss automatically has illegal access
    if rank == 'boss' then
        print('[DEBUG-SERVER]   └─ Result: TRUE (boss rank)')
        return true
    end
    
    -- Players with "illegal" rank have access
    if rank == 'illegal' then
        print('[DEBUG-SERVER]   └─ Result: TRUE (illegal rank)')
        return true
    end
    
    print('[DEBUG-SERVER]   └─ Result: FALSE (rank not authorized: ' .. rank .. ')')
    return false
end

-- Request Illegal Boss Menu (via TabletNPC) - KOMPLETT GETRENNT!
RegisterNetEvent('heli-taxi:server:requestIllegalBossMenu', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local rank = GetEmployeeRank(identifier, src)  -- FIX: Added source parameter!
    
    print('[DEBUG-SERVER] ▶ Illegal Boss Menu requested | ID: ' .. identifier .. ' | Rank: ' .. tostring(rank))
    
    if not HasIllegalAccess(identifier, src) then
        print('[DEBUG-SERVER] ❌ ACCESS DENIED | No illegal access')
        TriggerClientEvent('heli-taxi:client:notify', src, 'Kein Zugriff auf illegales Boss Menu!', 'error')
        return
    end
    
    print('[DEBUG-SERVER] ✅ ACCESS GRANTED | Loading black cash...')
    
    -- Get black cash balance (separate from normal account!)
    MySQL.query('SELECT black_cash FROM heli_taxi_accounts WHERE identifier = ? LIMIT 1', {identifier}, function(result)
        local blackCash = 0
        if result and result[1] then
            blackCash = result[1].black_cash or 0
        end
        
        print('[DEBUG-SERVER] ✅ Black cash loaded: $' .. blackCash .. ' | Opening ILLEGAL UI')
        
        -- Send to ILLEGAL.HTML not index.html!
        TriggerClientEvent('heli-taxi:client:openIllegalBossMenu', src, {
            blackCash = blackCash,
            rank = rank,
            identifier = identifier
        })
    end)
end)

-- Request Illegal Shop Access - KOMPLETT GETRENNT!
RegisterNetEvent('heli-taxi:server:requestIllegalShopAccess', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    local rank = GetEmployeeRank(identifier, src)  -- Pass source!
    
    print('[DEBUG-SERVER] ▶ Illegal Shop requested')
    print('[DEBUG-SERVER]   └─ Identifier: ' .. identifier)
    print('[DEBUG-SERVER]   └─ Rank from GetEmployeeRank: ' .. tostring(rank))
    
    -- Debug: Show framework job info
    if Framework.HasJob(src) then
        local grade = Framework.GetJobGrade(src)
        print('[DEBUG-SERVER]   └─ Framework Job Grade: ' .. tostring(grade))
        print('[DEBUG-SERVER]   └─ Expected Rank for Grade ' .. tostring(grade) .. ': ' .. tostring(Framework.GetRankFromGrade(grade, src)))  -- FIX: Added source!
    else
        print('[DEBUG-SERVER]   └─ No Framework Job found')
    end
    
    if not HasIllegalAccess(identifier, src) then
        print('[DEBUG-SERVER] ❌ ACCESS DENIED')
        TriggerClientEvent('heli-taxi:client:notify', src, 'Kein Zugriff auf illegalen Shop!', 'error')
        -- Reset flag on client so they can try again
        TriggerClientEvent('heli-taxi:client:resetIllegalMenuFlag', src)
        return
    end
    
    print('[DEBUG-SERVER] ✅ ACCESS GRANTED | Loading illegal vehicles...')
    
    -- Debug: Check if Config exists and has Vehicles
    print('[DEBUG-SERVER] Config type: ' .. type(Config))
    if Config then
        print('[DEBUG-SERVER] Config.Vehicles type: ' .. type(Config.Vehicles))
        if Config.Vehicles then
            print('[DEBUG-SERVER] Config.Vehicles count: ' .. #Config.Vehicles)
        end
    end
    
    -- Get army/military vehicles from Config.Vehicles (filtered by militaryOnly = true)
    local illegalVehicles = {}
    if Config and Config.Vehicles then
        for i, vehicle in ipairs(Config.Vehicles) do
            print('[DEBUG-SERVER] Checking vehicle ' .. i .. ': ' .. tostring(vehicle.model) .. ' | militaryOnly: ' .. tostring(vehicle.militaryOnly))
            if vehicle.militaryOnly == true then
                table.insert(illegalVehicles, {
                    model = vehicle.model,
                    name = vehicle.label,  -- UI expects 'name' not 'label'
                    label = vehicle.label,
                    price = vehicle.price,
                    category = vehicle.category or 'military',
                    passengers = vehicle.passengers or 2,
                    maxFuel = vehicle.maxFuel or 100,
                    fuelConsumption = vehicle.fuelConsumption or 1.5,
                    armed = vehicle.armed or false,
                    heavyWeapons = vehicle.heavyWeapons or false,
                    heavyLift = vehicle.heavyLift or false,
                    speed = 'HIGH',  -- UI expects speed/handling
                    handling = vehicle.armed and 'COMBAT' or 'STABLE'
                })
                print('[DEBUG-SERVER] ✅ Added military vehicle: ' .. vehicle.label)
            end
        end
    else
        print('[DEBUG-SERVER] ❌ Config or Config.Vehicles is nil!')
    end
    
    print('[DEBUG-SERVER] ✅ Loaded ' .. #illegalVehicles .. ' illegal/military vehicles | Opening ILLEGAL SHOP UI')
    
    -- Send to ILLEGAL.HTML not index.html!
    TriggerClientEvent('heli-taxi:client:openIllegalShop', src, illegalVehicles)
end)

-- Get Company Balance
RegisterNetEvent('heli-taxi:server:getCompanyBalance', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_bank', src) then
        Framework.Notify(src, 'Du hast keine Berechtigung dafür', 'error')
        return
    end
    
    MySQL.query('SELECT balance FROM heli_taxi_company LIMIT 1', {}, function(result)
        if result and result[1] then
            TriggerClientEvent('heli-taxi:client:updateCompanyBalance', src, result[1].balance)
        end
    end)
end)

-- Get Employee Info
RegisterNetEvent('heli-taxi:server:getEmployeeInfo', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if IsEmployee(identifier, src) then
        local emp = GetEmployee(identifier, src)
        TriggerClientEvent('heli-taxi:client:updateEmployeeInfo', src, emp)
    else
        TriggerClientEvent('heli-taxi:client:updateEmployeeInfo', src, nil)
    end
end)

-- Request Employee Data for Boss Menu (fresh data on menu open)
RegisterNetEvent('heli-taxi:server:requestEmployeeDataForMenu', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if IsEmployee(identifier, src) then
        local emp = GetEmployee(identifier, src)
        TriggerClientEvent('heli-taxi:client:openBossMenuWithData', src, emp)
    else
        -- Even if not found in database, check if Boss
        local rank = Framework.GetJobRank(src)
        if rank == 'boss' then
            -- Create minimal employee data for Boss
            local emp = {
                identifier = identifier,
                name = Framework.GetPlayerName(src),
                rank = 'boss',
                salary = Config.Ranks['boss'] and Config.Ranks['boss'].salary or 10000,
                status = 'off_duty',
                total_flights = 0,
                total_distance = 0,
                total_earned = 0
            }
            TriggerClientEvent('heli-taxi:client:openBossMenuWithData', src, emp)
        else
            Framework.Notify(src, 'Du bist kein Mitarbeiter', 'error')
        end
    end
end)

-- Toggle Duty
RegisterNetEvent('heli-taxi:server:toggleDuty', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not IsEmployee(identifier, src) then
        Framework.Notify(src, 'Du bist kein Mitarbeiter', 'error')
        return
    end
    
    local emp = GetEmployee(identifier, src)
    local newStatus = emp.status == 'on_duty' and 'off_duty' or 'on_duty'
    
    -- Update in database if using internal system
    if Employees[identifier] then
        MySQL.update('UPDATE heli_taxi_employees SET status = ? WHERE identifier = ?', 
            {newStatus, identifier}, function(affectedRows)
            if affectedRows > 0 then
                Employees[identifier].status = newStatus
            end
        end)
    end
    
    Framework.Notify(src, newStatus == 'on_duty' and 'Du bist jetzt im Dienst' or 'Du bist jetzt nicht mehr im Dienst', 'success')
    TriggerClientEvent('heli-taxi:client:setDuty', src, newStatus == 'on_duty')
end)

-- Get All Employees (for boss menu)
RegisterNetEvent('heli-taxi:server:getAllEmployees', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- Boss bypass: Boss can ALWAYS see employee list
    -- WICHTIG: Boss rank bleibt 'boss', hat aber automatisch beide permissions (normal UND illegal)
    local rank = GetEmployeeRank(identifier, src)
    if rank ~= 'boss' and not HasPermission(identifier, 'view_stats', src) then
        Framework.Notify(src, 'You do not have permission', 'error')
        return
    end
    
    MySQL.query('SELECT * FROM heli_taxi_employees ORDER BY hire_date DESC', {}, function(employees)
        local employeeList = employees or {}
        
        -- If using Framework job system and boss not in DB, add them to the list
        -- Boss wird als rank='boss' hinzugefügt (NICHT als 'illegal')
        if Framework.HasJob(src) and not Employees[identifier] then
            local bossRank = Framework.GetRankFromGrade(Framework.GetJobGrade(src))
            local bossData = {
                identifier = identifier,
                name = Framework.GetPlayerName(src),
                rank = bossRank or 'boss',  -- Boss bleibt 'boss', hat aber trotzdem beide permissions
                salary = Config.Ranks[bossRank or 'boss'] and Config.Ranks[bossRank or 'boss'].salary or 10000,
                status = 'on_duty',
                hire_date = os.date('%Y-%m-%d %H:%M:%S'),
                total_flights = 0,
                total_distance = 0,
                total_earned = 0
            }
            table.insert(employeeList, 1, bossData)  -- Add boss at the top
            print('[Heli-Taxi] Auto-added boss to employee list:', bossData.name, 'rank:', bossRank or 'boss')
        end
        
        TriggerClientEvent('heli-taxi:client:receiveEmployees', src, employeeList)
    end)
end)

-- Get Company Statistics
RegisterNetEvent('heli-taxi:server:getStatistics', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'view_stats', src) then
        Framework.Notify(src, 'You do not have permission', 'error')
        return
    end
    
    MySQL.query('SELECT * FROM heli_taxi_company LIMIT 1', {}, function(company)
        MySQL.query('SELECT COUNT(*) as total FROM heli_taxi_flights', {}, function(flights)
            MySQL.query('SELECT COUNT(*) as total FROM heli_taxi_vehicles', {}, function(vehicles)
                MySQL.query('SELECT COUNT(*) as total FROM heli_taxi_employees WHERE status = "on_duty"', {}, function(onDuty)
                    local stats = {
                        balance = company and company[1] and company[1].balance or 0,
                        totalIncome = company and company[1] and company[1].total_income or 0,
                        totalExpenses = company and company[1] and company[1].total_expenses or 0,
                        totalFlights = flights and flights[1] and flights[1].total or 0,
                        totalVehicles = vehicles and vehicles[1] and vehicles[1].total or 0,
                        onDutyEmployees = onDuty and onDuty[1] and onDuty[1].total or 0
                    }
                    TriggerClientEvent('heli-taxi:client:receiveStatistics', src, stats)
                end)
            end)
        end)
    end)
end)

-- Salary Payment System
CreateThread(function()
    if not Config.Salary or not Config.Salary.enabled then return end
    
    while true do
        Wait(Config.Salary.payInterval * 60000) -- Convert minutes to milliseconds
        
        local query = Config.Salary.requireOnDuty and 
            'SELECT * FROM heli_taxi_employees WHERE status = "on_duty"' or 
            'SELECT * FROM heli_taxi_employees'
        
        MySQL.query(query, {}, function(employees)
            if not employees then return end
            
            for _, emp in pairs(employees) do
                local salary = emp.salary
                
                -- Check if company has enough money
                MySQL.query('SELECT balance FROM heli_taxi_company LIMIT 1', {}, function(result)
                    if result and result[1] and result[1].balance >= salary then
                        -- Pay salary
                        MySQL.update('UPDATE heli_taxi_company SET balance = balance - ?, total_expenses = total_expenses + ?', 
                            {salary, salary})
                        
                        -- Log transaction
                        MySQL.insert('INSERT INTO heli_taxi_transactions (transaction_type, amount, description, performer_identifier, performer_name) VALUES (?, ?, ?, ?, ?)',
                            {'salary', salary, 'Salary payment to ' .. emp.name, emp.identifier, emp.name})
                        
                        -- Notify player if online
                        for _, playerId in ipairs(GetPlayers()) do
                            local playerIdentifier = Framework.GetIdentifier(tonumber(playerId))
                            if playerIdentifier == emp.identifier then
                                Framework.AddMoney(tonumber(playerId), salary)
                                Framework.Notify(tonumber(playerId), 'You received your salary: $' .. salary, 'success')
                                break
                            end
                        end
                        
                        print('[Heli-Taxi] Paid salary of $' .. salary .. ' to ' .. emp.name)
                    else
                        print('[Heli-Taxi] Insufficient company funds to pay salary to ' .. emp.name)
                    end
                end)
            end
        end)
    end
end)

-- Player disconnect - cleanup
AddEventHandler('playerDropped', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    -- End active flight if any
    if ActiveFlights[identifier] then
        ActiveFlights[identifier] = nil
    end
end)

print('[Heli-Taxi] Server initialized successfully')
