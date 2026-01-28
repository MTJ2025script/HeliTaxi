// Phone App Script
let isEmployee = false;
let currentRequest = null;

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openPhoneApp':
            openPhoneApp(data.appData);
            break;
        case 'closePhoneApp':
            closePhoneApp();
            break;
        case 'updateAppData':
            updateAppData(data.appData);
            break;
        case 'receivePickupRequest':
            showPickupRequest(data.request);
            break;
        case 'requestSent':
            showRequestStatus();
            break;
        case 'requestCancelled':
            hideRequestStatus();
            break;
    }
});

// Open Phone App
function openPhoneApp(appData) {
    console.log('[PHONE-APP] Opening with data:', appData);
    
    if (appData) {
        updateAppData(appData);
    }
    
    $('#phone-app').fadeIn(200);
}

// Close Phone App
function closePhoneApp() {
    console.log('[PHONE-APP] Closing');
    
    $('#phone-app').fadeOut(200);
    
    $.post('https://Heli-Taxi/closePhoneApp', JSON.stringify({}));
}

// Update App Data
function updateAppData(appData) {
    console.log('[PHONE-APP] Updating data:', appData);
    
    $('#availableVehicles').text(appData.availableVehicles || 0);
    $('#onlineEmployees').text(appData.onlineEmployees || 0);
    
    isEmployee = appData.isEmployee;
    
    if (isEmployee) {
        $('#employee-section').show();
    } else {
        $('#employee-section').hide();
    }
    
    // Update destination if available
    if (appData.destination) {
        showCurrentPickup(appData.destination);
    }
}

// Call Taxi
function callTaxi() {
    console.log('[PHONE-APP] Calling taxi');
    
    $.post('https://Heli-Taxi/callTaxi', JSON.stringify({}), function(response) {
        if (response && response.success) {
            showRequestStatus();
        }
    });
}

// Cancel Request
function cancelRequest() {
    console.log('[PHONE-APP] Cancelling request');
    
    hideRequestStatus();
    
    $.post('https://Heli-Taxi/cancelTaxiRequest', JSON.stringify({}));
}

// Show Request Status
function showRequestStatus() {
    $('#pickup-request').show();
    $('#requestStatus').text('Warte auf Pilot...');
}

// Hide Request Status
function hideRequestStatus() {
    $('#pickup-request').hide();
}

// Show Pickup Request (for employees)
function showPickupRequest(request) {
    console.log('[PHONE-APP] Showing pickup request:', request);
    
    currentRequest = request;
    
    $('#pickupPlayerName').text(request.playerName);
    $('#pickupDistance').text(request.distance || 'Berechne...');
    $('#current-pickup').show();
}

// Show Current Pickup
function showCurrentPickup(destination) {
    $('#pickupPlayerName').text(destination.playerName);
    $('#pickupDistance').text(destination.distance);
    $('#current-pickup').show();
}

// Accept Pickup
function acceptPickup() {
    console.log('[PHONE-APP] Accepting pickup');
    
    $.post('https://Heli-Taxi/acceptPickup', JSON.stringify({
        requesterId: currentRequest ? currentRequest.requesterId : null
    }));
    
    $('#current-pickup').hide();
}

// Cancel Pickup
function cancelPickup() {
    console.log('[PHONE-APP] Cancelling pickup');
    
    $.post('https://Heli-Taxi/cancelPickup', JSON.stringify({
        requesterId: currentRequest ? currentRequest.requesterId : null
    }));
    
    $('#current-pickup').hide();
    currentRequest = null;
}

// ESC key to close
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closePhoneApp();
    }
});
