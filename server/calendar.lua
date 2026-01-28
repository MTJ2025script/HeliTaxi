-- Calendar & Appointments Server Module

-- Get all appointments
RegisterNetEvent('heli-taxi:server:getAppointments', function()
    local src = source
    
    MySQL.query('SELECT * FROM heli_taxi_appointments ORDER BY appointment_date ASC, appointment_time ASC', {}, function(result)
        if result then
            TriggerClientEvent('heli-taxi:client:receiveAppointments', src, result)
        else
            TriggerClientEvent('heli-taxi:client:receiveAppointments', src, {})
        end
    end)
end)

-- Create new appointment
RegisterNetEvent('heli-taxi:server:createAppointment', function(data)
    local src = source
    
    local identifier = Framework.GetIdentifier(src)
    
    MySQL.insert('INSERT INTO heli_taxi_appointments (title, description, appointment_date, appointment_time, created_by) VALUES (?, ?, ?, ?, ?)',
        {data.title, data.description, data.date, data.time, identifier},
        function(insertId)
            if insertId then
                TriggerClientEvent('QBCore:Notify', src, 'Termin erfolgreich erstellt!', 'success')
                -- Refresh appointments for all employees
                TriggerEvent('heli-taxi:server:refreshAppointments')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Fehler beim Erstellen des Termins', 'error')
            end
        end
    )
end)

-- Update appointment
RegisterNetEvent('heli-taxi:server:updateAppointment', function(data)
    local src = source
    
    MySQL.update('UPDATE heli_taxi_appointments SET title = ?, description = ?, appointment_date = ?, appointment_time = ? WHERE id = ?',
        {data.title, data.description, data.date, data.time, data.id},
        function(affectedRows)
            if affectedRows > 0 then
                TriggerClientEvent('QBCore:Notify', src, 'Termin erfolgreich aktualisiert!', 'success')
                -- Refresh appointments for all employees
                TriggerEvent('heli-taxi:server:refreshAppointments')
            else
                TriggerClientEvent('QBCore:Notify', src, 'Fehler beim Aktualisieren des Termins', 'error')
            end
        end
    )
end)

-- Delete appointment
RegisterNetEvent('heli-taxi:server:deleteAppointment', function(appointmentId)
    local src = source
    
    MySQL.query('DELETE FROM heli_taxi_appointments WHERE id = ?', {appointmentId}, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('QBCore:Notify', src, 'Termin erfolgreich gelöscht!', 'success')
            -- Refresh appointments for all employees
            TriggerEvent('heli-taxi:server:refreshAppointments')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Fehler beim Löschen des Termins', 'error')
        end
    end)
end)

-- Refresh appointments for all employees
RegisterNetEvent('heli-taxi:server:refreshAppointments', function()
    MySQL.query('SELECT * FROM heli_taxi_appointments ORDER BY appointment_date ASC, appointment_time ASC', {}, function(result)
        if result then
            -- Send to all online employees
            local players = GetPlayers()
            for _, playerId in ipairs(players) do
                local Player = Framework.GetPlayer(tonumber(playerId))
                if Player and Framework.GetJobName(tonumber(playerId)) == Config.JobName then
                    TriggerClientEvent('heli-taxi:client:receiveAppointments', tonumber(playerId), result)
                end
            end
        end
    end)
end)
