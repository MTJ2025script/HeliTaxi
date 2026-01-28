-- Standalone Phone Booking System - Server Side

local activeBookings = {}
local callbackRequests = {}
local bookingIdCounter = 0

-- Submit standalone booking
RegisterNetEvent('heli-taxi:server:submitStandaloneBooking', function(bookingData)
    local src = source
    local Player = Framework.GetPlayer(src)
    
    if not Player then return end
    
    -- Generate unique booking ID
    bookingIdCounter = bookingIdCounter + 1
    local bookingId = 'BOOK-' .. os.date("%Y%m%d") .. '-' .. bookingIdCounter
    
    -- Add timestamp server-side
    bookingData.timestamp = os.date("%d.%m.%Y %H:%M")
    
    -- Add player info
    local playerName = Framework.GetPlayerName(src)
    bookingData.id = bookingId
    bookingData.playerId = src
    bookingData.playerName = playerName
    bookingData.status = 'pending'
    bookingData.createdAt = os.time()
    
    -- Store booking
    activeBookings[bookingId] = bookingData
    
    -- Get all online employees
    local employees = Framework.GetEmployees()
    local sentToEmployees = 0
    
    for _, employeeId in ipairs(employees) do
        if Framework.IsPlayerOnline(employeeId) then
            TriggerClientEvent('heli-taxi:client:receiveStandaloneBooking', employeeId, bookingData)
            sentToEmployees = sentToEmployees + 1
        end
    end
    
    if sentToEmployees == 0 then
        TriggerClientEvent('heli-taxi:client:noEmployeesAvailable', src)
        -- Auto-save as callback request
        table.insert(callbackRequests, {
            phoneNumber = bookingData.phoneNumber,
            reason = 'Automatisch - Keine Piloten verfügbar',
            timestamp = bookingData.timestamp,
            bookingData = bookingData
        })
    end
    
    -- Log booking
    if Config.Debug then
        print(string.format('[Heli-Taxi] Booking %s created by %s - Sent to %d employees', 
            bookingId, playerName, sentToEmployees))
    end
    
    -- Save to database
    MySQL.Async.insert('INSERT INTO heli_taxi_bookings (booking_id, player_identifier, phone_number, pickup_coords, destination_coords, passenger_count, note, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        bookingId,
        Framework.GetPlayerIdentifier(Player),
        bookingData.phoneNumber,
        json.encode(bookingData.pickup),
        json.encode(bookingData.destination),
        bookingData.passengerCount,
        bookingData.note,
        'pending',
        os.date('%Y-%m-%d %H:%M:%S')
    })
end)

-- Employee accepts booking
RegisterNetEvent('heli-taxi:server:acceptStandaloneBooking', function(bookingId)
    local src = source
    local Player = Framework.GetPlayer(src)
    
    if not Player then return end
    
    local booking = activeBookings[bookingId]
    if not booking then return end
    
    if booking.status ~= 'pending' then
        TriggerClientEvent('QBCore:Notify', src, 'Diese Buchung wurde bereits bearbeitet.', 'error')
        return
    end
    
    -- Update status
    booking.status = 'accepted'
    booking.acceptedBy = src
    booking.acceptedByName = Framework.GetPlayerName(Player)
    booking.acceptedAt = os.time()
    
    -- Notify customer
    if Framework.IsPlayerOnline(booking.playerId) then
        TriggerClientEvent('heli-taxi:client:bookingAccepted', booking.playerId, booking.acceptedByName)
    end
    
    -- Notify other employees (remove notification)
    local employees = Framework.GetEmployees()
    for _, employeeId in ipairs(employees) do
        if employeeId ~= src and Framework.IsPlayerOnline(employeeId) then
            TriggerClientEvent('QBCore:Notify', employeeId, 
                'Buchung ' .. bookingId .. ' wurde von ' .. booking.acceptedByName .. ' angenommen.', 
                'primary')
        end
    end
    
    -- Update database
    MySQL.Async.execute('UPDATE heli_taxi_bookings SET status = ?, accepted_by = ?, accepted_at = ? WHERE booking_id = ?', {
        'accepted',
        Framework.GetPlayerIdentifier(Player),
        os.date('%Y-%m-%d %H:%M:%S'),
        bookingId
    })
    
    if Config.Debug then
        print(string.format('[Heli-Taxi] Booking %s accepted by %s', bookingId, booking.acceptedByName))
    end
end)

-- Employee declines booking
RegisterNetEvent('heli-taxi:server:declineStandaloneBooking', function(bookingId)
    local src = source
    local booking = activeBookings[bookingId]
    
    if not booking then return end
    
    -- Count how many employees declined
    if not booking.declinedBy then
        booking.declinedBy = {}
    end
    table.insert(booking.declinedBy, src)
    
    -- Check if all online employees declined
    local employees = Framework.GetEmployees()
    local onlineEmployeeCount = 0
    for _, employeeId in ipairs(employees) do
        if Framework.IsPlayerOnline(employeeId) then
            onlineEmployeeCount = onlineEmployeeCount + 1
        end
    end
    
    if #booking.declinedBy >= onlineEmployeeCount then
        -- All employees declined
        booking.status = 'declined'
        
        -- Notify customer
        if Framework.IsPlayerOnline(booking.playerId) then
            TriggerClientEvent('heli-taxi:client:bookingDeclined', booking.playerId)
        end
        
        -- Save as callback request
        table.insert(callbackRequests, {
            phoneNumber = booking.phoneNumber,
            reason = 'Automatisch - Alle Piloten abgelehnt',
            timestamp = booking.timestamp,
            bookingData = booking
        })
        
        -- Update database
        MySQL.Async.execute('UPDATE heli_taxi_bookings SET status = ? WHERE booking_id = ?', {
            'declined',
            bookingId
        })
    end
end)

-- Request callback
RegisterNetEvent('heli-taxi:server:requestCallback', function(callbackData)
    local src = source
    local Player = Framework.GetPlayer(src)
    
    if not Player then return end
    
    callbackData.playerId = src
    callbackData.playerName = Framework.GetPlayerName(Player)
    callbackData.identifier = Framework.GetPlayerIdentifier(Player)
    callbackData.createdAt = os.time()
    
    table.insert(callbackRequests, callbackData)
    
    -- Save to database
    MySQL.Async.insert('INSERT INTO heli_taxi_callbacks (player_identifier, phone_number, reason, created_at) VALUES (?, ?, ?, ?)', {
        callbackData.identifier,
        callbackData.phoneNumber,
        callbackData.reason,
        os.date('%Y-%m-%d %H:%M:%S')
    })
    
    -- Notify boss
    local employees = Framework.GetEmployees()
    for _, employeeId in ipairs(employees) do
        if Framework.IsPlayerOnline(employeeId) and Framework.IsPlayerBoss(employeeId) then
            TriggerClientEvent('QBCore:Notify', employeeId, 
                '📞 Neue Rückruf-Anfrage von ' .. callbackData.phoneNumber, 
                'primary', 5000)
        end
    end
    
    if Config.Debug then
        print(string.format('[Heli-Taxi] Callback request from %s (%s): %s', 
            callbackData.playerName, callbackData.phoneNumber, callbackData.reason))
    end
end)

-- Get callback requests (for boss menu)
Framework.CreateCallback('heli-taxi:server:getCallbackRequests', function(source, cb)
    cb(callbackRequests)
end)

-- Get active bookings (for employee menu)
Framework.CreateCallback('heli-taxi:server:getActiveBookings', function(source, cb)
    local bookings = {}
    for id, booking in pairs(activeBookings) do
        if booking.status == 'pending' or booking.status == 'accepted' then
            table.insert(bookings, booking)
        end
    end
    cb(bookings)
end)

-- Delete callback request
RegisterNetEvent('heli-taxi:server:deleteCallback', function(index)
    local src = source
    if not Framework.IsPlayerBoss(src) then return end
    
    if callbackRequests[index] then
        table.remove(callbackRequests, index)
    end
end)

-- Create database tables if they don't exist
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS heli_taxi_bookings (
            id INT AUTO_INCREMENT PRIMARY KEY,
            booking_id VARCHAR(50) UNIQUE NOT NULL,
            player_identifier VARCHAR(50) NOT NULL,
            phone_number VARCHAR(20),
            pickup_coords TEXT NOT NULL,
            destination_coords TEXT NOT NULL,
            passenger_count INT DEFAULT 1,
            note TEXT,
            status VARCHAR(20) DEFAULT 'pending',
            accepted_by VARCHAR(50),
            accepted_at DATETIME,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_status (status),
            INDEX idx_player (player_identifier)
        )
    ]])
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS heli_taxi_callbacks (
            id INT AUTO_INCREMENT PRIMARY KEY,
            player_identifier VARCHAR(50) NOT NULL,
            phone_number VARCHAR(20) NOT NULL,
            reason TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_player (player_identifier)
        )
    ]])
end)

print('[Heli-Taxi] Standalone Phone Booking Server loaded')
