// Booking UI Script
let currentBookingRequest = null;

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openBooking':
            openBooking(data.data);
            break;
        case 'closeBooking':
            closeBooking();
            break;
        case 'showEmployeeRequest':
            showEmployeeRequest(data.data);
            break;
        case 'hideEmployeeRequest':
            hideEmployeeRequest();
            break;
        case 'updatePilotCount':
            updatePilotCount(data.count);
            break;
    }
});

// Open Booking UI
function openBooking(data) {
    console.log('[BOOKING] Opening with data:', data);
    
    if (data) {
        if (data.phoneNumber) {
            $('#phoneNumber').val(data.phoneNumber);
        }
    }
    
    $('#booking-container').fadeIn(200);
}

// Close Booking UI
function closeBooking() {
    console.log('[BOOKING] Closing');
    
    $('#booking-container').fadeOut(200);
    $('#success-message').fadeOut(200);
    
    // Reset form
    $('#bookingForm')[0].reset();
    
    $.post('https://Heli-Taxi/closeBooking', JSON.stringify({}));
}

// Update Pilot Count
function updatePilotCount(count) {
    $('#pilotCount').text(count);
}

// Form Submit Handler
$('#bookingForm').on('submit', function(e) {
    e.preventDefault();
    
    const formData = {
        phoneNumber: $('#phoneNumber').val(),
        passengerCount: parseInt($('#passengerCount').val()),
        useWaypoint: $('input[name="destination"]:checked').val() === 'waypoint',
        note: $('#note').val()
    };
    
    console.log('[BOOKING] Submitting:', formData);
    
    $.post('https://Heli-Taxi/submitBooking', JSON.stringify(formData), function(response) {
        if (response && response.success) {
            // Show success message
            $('#booking-container').hide();
            $('#success-message').fadeIn(200);
            
            // Auto-close after 3 seconds
            setTimeout(function() {
                closeBooking();
            }, 3000);
        }
    });
});

// Request Callback
function requestCallback() {
    const phoneNumber = $('#phoneNumber').val();
    
    if (!phoneNumber) {
        alert('Bitte gib deine Telefonnummer ein!');
        return;
    }
    
    $.post('https://Heli-Taxi/requestCallback', JSON.stringify({
        phoneNumber: phoneNumber,
        reason: 'Rückruf gewünscht'
    }), function(response) {
        if (response && response.success) {
            alert('Rückruf-Anfrage gespeichert! Wir rufen dich zurück.');
            closeBooking();
        }
    });
}

// Employee: Show Request Notification
function showEmployeeRequest(request) {
    console.log('[BOOKING] Showing employee request:', request);
    
    currentBookingRequest = request;
    
    $('#requestPhone').text(request.phoneNumber || 'Unbekannt');
    $('#requestPassengers').text(request.passengerCount || '1');
    $('#requestNote').text(request.note || '-');
    $('#requestTime').text(request.timestamp || 'Jetzt');
    
    $('#employee-request').fadeIn(200);
    
    // Auto-hide after 30 seconds
    setTimeout(function() {
        hideEmployeeRequest();
    }, 30000);
}

// Employee: Hide Request Notification
function hideEmployeeRequest() {
    $('#employee-request').fadeOut(200);
    currentBookingRequest = null;
}

// Employee: Accept Booking
function acceptBooking() {
    console.log('[BOOKING] Accepting booking');
    
    if (currentBookingRequest) {
        $.post('https://Heli-Taxi/acceptBooking', JSON.stringify({
            requestId: currentBookingRequest.id
        }));
    }
    
    hideEmployeeRequest();
}

// Employee: Decline Booking
function declineBooking() {
    console.log('[BOOKING] Declining booking');
    
    if (currentBookingRequest) {
        $.post('https://Heli-Taxi/declineBooking', JSON.stringify({
            requestId: currentBookingRequest.id
        }));
    }
    
    hideEmployeeRequest();
}

// ESC key to close
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeBooking();
    }
});
