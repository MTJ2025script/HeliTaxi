-- Standalone Phone Booking System (unabhängig von QB-Phone)
-- Spieler können einfach eine Nummer anrufen und das Booking-UI öffnet sich automatisch

local isBookingOpen = false
local lastCallTime = 0
local currentRequest = nil
local pendingRequests = {}

-- Phone Number Configuration wird aus Config geladen
local function getPhoneNumber()
    return Config.StandalonePhone and Config.StandalonePhone.phoneNumber or "555-8294" -- 555-TAXI
end

-- Prüfe ob Spieler die Taxi-Nummer anruft
-- Hook in verschiedene Phone-Systeme
if GetResourceState('qb-phone') == 'started' then
    -- QB-Phone Hook
    RegisterNetEvent('qb-phone:client:CallContact', function(contact)
        if contact and contact.number == getPhoneNumber() then
            OpenBookingUI()
        end
    end)
    
    RegisterNetEvent('qb-phone:client:CustomCall', function(number)
        if number == getPhoneNumber() then
            OpenBookingUI()
        end
    end)
elseif GetResourceState('qs-smartphone') == 'started' then
    -- QS Smartphone Hook
    RegisterNetEvent('qs-smartphone:client:callNumber', function(number)
        if number == getPhoneNumber() then
            OpenBookingUI()
        end
    end)
elseif GetResourceState('lb-phone') == 'started' then
    -- LB Phone Hook
    RegisterNetEvent('lb-phone:phoneCallStarted', function(number)
        if number == getPhoneNumber() then
            OpenBookingUI()
        end
    end)
elseif GetResourceState('gksphone') == 'started' then
    -- GKS Phone Hook
    RegisterNetEvent('gksphone:callNumber', function(number)
        if number == getPhoneNumber() then
            OpenBookingUI()
        end
    end)
end

-- Fallback: Command für Anruf (falls kein Phone-System erkannt wird)
RegisterCommand('calltaxi', function()
    OpenBookingUI()
end, false)

-- Alternative: Spieler kann über /taxi anrufen
RegisterCommand('taxi', function()
    OpenBookingUI()
end, false)

-- Öffne Booking UI
function OpenBookingUI()
    -- Cooldown Check
    local currentTime = GetGameTimer()
    if currentTime - lastCallTime < (Config.StandalonePhone.cooldown or 60000) then
        local remainingTime = math.ceil(((Config.StandalonePhone.cooldown or 60000) - (currentTime - lastCallTime)) / 1000)
        TriggerEvent('QBCore:Notify', 'Bitte warten Sie noch ' .. remainingTime .. ' Sekunden', 'error')
        return
    end
    
    if isBookingOpen then
        return
    end
    
    -- Get player data first (before setting NUI focus)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    
    -- Send data to UI first
    SendNUIMessage({
        action = "openBooking",
        data = {
            phoneNumber = getPhoneNumber(),
            currentLocation = streetName,
            playerCoords = {x = coords.x, y = coords.y, z = coords.z},
            timestamp = "" -- Server will add timestamp
        }
    })
    
    -- Small delay before setting NUI focus to ensure UI is ready
    Citizen.Wait(100)
    
    isBookingOpen = true
    SetNuiFocus(true, true)
    
    -- Auto-close after 2 minutes if no action (safety measure against freeze)
    Citizen.SetTimeout(120000, function()
        if isBookingOpen then
            isBookingOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({action = "closeBooking"})
        end
    end)
    
    lastCallTime = currentTime
end

-- Close Booking UI
RegisterNUICallback('closeBooking', function(data, cb)
    isBookingOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Submit Booking Request
RegisterNUICallback('submitBooking', function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Destination handling
    local destination = nil
    if data.useWaypoint then
        local waypoint = GetFirstBlipInfoId(8) -- Waypoint blip
        if DoesBlipExist(waypoint) then
            local waypointCoords = GetBlipInfoIdCoord(waypoint)
            destination = {x = waypointCoords.x, y = waypointCoords.y, z = waypointCoords.z}
        else
            TriggerEvent('QBCore:Notify', 'Bitte setzen Sie einen Wegpunkt auf der Karte!', 'error')
            cb({success = false, message = 'Kein Wegpunkt gesetzt'})
            return
        end
    else
        destination = {x = coords.x, y = coords.y, z = coords.z}
    end
    
    -- Send request to server
    TriggerServerEvent('heli-taxi:server:submitStandaloneBooking', {
        pickup = {x = coords.x, y = coords.y, z = coords.z},
        destination = destination,
        passengerCount = data.passengerCount or 1,
        note = data.note or '',
        phoneNumber = data.phoneNumber or 'Unbekannt',
        timestamp = os.date("%d.%m.%Y %H:%M:%S")
    })
    
    -- Close UI
    isBookingOpen = false
    SetNuiFocus(false, false)
    
    TriggerEvent('QBCore:Notify', 'Taxi-Anfrage gesendet! Bitte warten Sie auf einen Piloten.', 'success', 5000)
    
    cb({success = true})
end)

-- Request Callback
RegisterNUICallback('requestCallback', function(data, cb)
    TriggerServerEvent('heli-taxi:server:requestCallback', {
        phoneNumber = data.phoneNumber,
        reason = data.reason or 'Rückruf gewünscht',
        timestamp = os.date("%d.%m.%Y %H:%M:%S")
    })
    
    TriggerEvent('QBCore:Notify', 'Rückruf-Anfrage gespeichert. Wir rufen Sie zurück!', 'success')
    
    cb({success = true})
end)

-- EMPLOYEE SIDE - Receive booking request
RegisterNetEvent('heli-taxi:client:receiveStandaloneBooking', function(requestData)
    table.insert(pendingRequests, requestData)
    
    -- Notification
    TriggerEvent('QBCore:Notify', '📱 Neue Taxi-Buchung von ' .. (requestData.phoneNumber or 'Unbekannt'), 'primary', 8000)
    
    -- Play sound
    PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", true)
    
    -- Set GPS waypoint
    SetNewWaypoint(requestData.pickup.x, requestData.pickup.y)
    
    -- Create blip
    local blip = AddBlipForCoord(requestData.pickup.x, requestData.pickup.y, requestData.pickup.z)
    SetBlipSprite(blip, 64) -- Helicopter
    SetBlipColour(blip, 5) -- Yellow
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("🚁 Taxi-Abholung: " .. (requestData.phoneNumber or 'Kunde'))
    EndTextCommandSetBlipName(blip)
    
    -- Store blip in request
    requestData.blip = blip
    
    -- Show employee notification UI
    SendNUIMessage({
        action = "showEmployeeRequest",
        data = requestData
    })
    
    -- Auto-remove after 10 minutes
    SetTimeout(600000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

-- Employee accepts booking
RegisterNUICallback('acceptBooking', function(data, cb)
    local requestId = data.requestId
    
    TriggerServerEvent('heli-taxi:server:acceptStandaloneBooking', requestId)
    TriggerEvent('QBCore:Notify', 'Auftrag angenommen! GPS-Route aktiv.', 'success')
    
    cb({success = true})
end)

-- Employee declines booking
RegisterNUICallback('declineBooking', function(data, cb)
    local requestId = data.requestId
    
    -- Remove from pending
    for i, req in ipairs(pendingRequests) do
        if req.id == requestId then
            if DoesBlipExist(req.blip) then
                RemoveBlip(req.blip)
            end
            table.remove(pendingRequests, i)
            break
        end
    end
    
    TriggerServerEvent('heli-taxi:server:declineStandaloneBooking', requestId)
    TriggerEvent('QBCore:Notify', 'Auftrag abgelehnt.', 'error')
    
    cb({success = true})
end)

-- Update on booking status
RegisterNetEvent('heli-taxi:client:bookingAccepted', function(employeeName)
    TriggerEvent('QBCore:Notify', '✅ ' .. employeeName .. ' hat Ihre Buchung angenommen!', 'success', 7000)
    PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", true)
end)

RegisterNetEvent('heli-taxi:client:bookingDeclined', function()
    TriggerEvent('QBCore:Notify', '❌ Ihre Buchung wurde abgelehnt. Bitte versuchen Sie es erneut.', 'error', 7000)
end)

RegisterNetEvent('heli-taxi:client:noEmployeesAvailable', function()
    TriggerEvent('QBCore:Notify', 'Momentan sind keine Piloten verfügbar. Bitte versuchen Sie es später erneut.', 'error', 7000)
end)

-- Emergency close for frozen UI (ESC key fallback)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isBookingOpen then
            -- ESC key to close in case of freeze
            if IsControlJustReleased(0, 322) or IsControlJustReleased(0, 177) then -- ESC or Backspace
                isBookingOpen = false
                SetNuiFocus(false, false)
                SendNUIMessage({action = "closeBooking"})
            end
        else
            Citizen.Wait(500) -- Reduce CPU usage when UI is closed
        end
    end
end)

print('[Heli-Taxi] Standalone Phone Booking System loaded')
print('[Heli-Taxi] Taxi-Nummer: ' .. getPhoneNumber())
print('[Heli-Taxi] Befehle: /calltaxi oder /taxi')
