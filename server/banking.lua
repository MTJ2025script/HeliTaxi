-- Banking System

-- Get Transaction History
RegisterNetEvent('heli-taxi:server:getTransactions', function(limit)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_bank', src) then
        Framework.Notify(src, 'You do not have permission to view transactions', 'error')
        return
    end
    
    local queryLimit = limit or 100
    
    MySQL.query([[
        SELECT * FROM heli_taxi_transactions 
        ORDER BY transaction_date DESC 
        LIMIT ?
    ]], {queryLimit}, function(transactions)
        TriggerClientEvent('heli-taxi:client:receiveTransactions', src, transactions or {})
    end)
end)

-- Deposit Money (Boss/Assistant)
RegisterNetEvent('heli-taxi:server:depositMoney', function(amount)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_bank', src) then
        Framework.Notify(src, 'You do not have permission to deposit money', 'error')
        return
    end
    
    if amount <= 0 then
        Framework.Notify(src, 'Invalid amount', 'error')
        return
    end
    
    -- Check if player has enough money
    local playerMoney = Framework.GetMoney(src)
    if playerMoney < amount then
        Framework.Notify(src, 'You do not have enough money', 'error')
        return
    end
    
    -- Remove money from player
    if Framework.RemoveMoney(src, amount) then
        -- Add to company balance
        MySQL.update('UPDATE heli_taxi_company SET balance = balance + ?, total_income = total_income + ?',
            {amount, amount})
        
        -- Log transaction
        MySQL.insert([[
            INSERT INTO heli_taxi_transactions 
            (transaction_type, amount, description, performer_identifier, performer_name)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            'income',
            amount,
            'Cash deposit by ' .. Framework.GetPlayerName(src),
            identifier,
            Framework.GetPlayerName(src)
        })
        
        Framework.Notify(src, 'Successfully deposited $' .. amount .. ' to company account', 'success')
    else
        Framework.Notify(src, 'Transaction failed', 'error')
    end
end)

-- Withdraw Money (Boss only)
RegisterNetEvent('heli-taxi:server:withdrawMoney', function(amount)
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_bank', src) then
        Framework.Notify(src, 'You do not have permission to withdraw money', 'error')
        return
    end
    
    local rank = GetEmployeeRank(identifier, src)
    if rank ~= 'boss' then
        Framework.Notify(src, 'Only the boss can withdraw money', 'error')
        return
    end
    
    if amount <= 0 then
        Framework.Notify(src, 'Invalid amount', 'error')
        return
    end
    
    -- Check company balance
    MySQL.query('SELECT balance FROM heli_taxi_company LIMIT 1', {}, function(result)
        if not result or not result[1] then
            Framework.Notify(src, 'Error accessing company account', 'error')
            return
        end
        
        local balance = result[1].balance
        
        if balance < amount then
            Framework.Notify(src, 'Insufficient company funds', 'error')
            return
        end
        
        -- Deduct from company balance
        MySQL.update('UPDATE heli_taxi_company SET balance = balance - ?, total_expenses = total_expenses + ?',
            {amount, amount})
        
        -- Give money to player
        Framework.AddMoney(src, amount)
        
        -- Log transaction
        MySQL.insert([[
            INSERT INTO heli_taxi_transactions 
            (transaction_type, amount, description, performer_identifier, performer_name)
            VALUES (?, ?, ?, ?, ?)
        ]], {
            'expense',
            amount,
            'Cash withdrawal by ' .. Framework.GetPlayerName(src),
            identifier,
            Framework.GetPlayerName(src)
        })
        
        Framework.Notify(src, 'Successfully withdrew $' .. amount .. ' from company account', 'success')
    end)
end)

-- Get Balance
RegisterNetEvent('heli-taxi:server:getBalance', function()
    local src = source
    local identifier = Framework.GetIdentifier(src)
    
    if not HasPermission(identifier, 'manage_bank', src) then
        Framework.Notify(src, 'You do not have permission to view company balance', 'error')
        return
    end
    
    MySQL.query('SELECT * FROM heli_taxi_company LIMIT 1', {}, function(result)
        if result and result[1] then
            TriggerClientEvent('heli-taxi:client:receiveBalance', src, {
                balance = result[1].balance,
                totalIncome = result[1].total_income,
                totalExpenses = result[1].total_expenses
            })
        end
    end)
end)
