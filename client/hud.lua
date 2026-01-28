-- HUD System
-- The HUD is primarily handled by the HTML/CSS/JS files
-- This file contains any additional client-side HUD logic

-- Show/Hide HUD based on flight status
RegisterNetEvent('heli-taxi:client:toggleHUD', function(show)
    SendNUIMessage({
        action = show and 'showHUD' or 'hideHUD'
    })
end)
