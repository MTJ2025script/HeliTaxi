// ILLEGALES UI - KOMPLETT GETRENNT VOM NORMALEN SYSTEM

// Use window.currentIllegalMenu to share state with script.js for ESC key handling
window.currentIllegalMenu = null;
let illegalData = {};
let selectedVehicle = null;
let illegalBackgroundEnabled = true;
let illegalBackgroundImage = 'illegal_background.jpg';
let isClosing = false; // Prevent multiple simultaneous close calls

// Constants
const CLOSE_ANIMATION_DURATION = 300; // fadeIn/fadeOut duration in ms
const CLOSE_DEBOUNCE_TIMEOUT = 350; // slightly longer than animation

// Listen for messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    console.log('[ILLEGAL-UI] Received action:', data.action);
    
    switch(data.action) {
        case 'setIllegalBackground':
            setIllegalBackground(data);
            break;
        case 'openIllegalBossMenu':
            openIllegalBossMenu(data.data);
            break;
        case 'openIllegalShop':
            openIllegalShop(data.vehicles);
            break;
        case 'openIllegalGarage':
            openIllegalGarage(data.vehicles, data.helipadIndex);
            break;
        case 'openIllegalManagement':
            openIllegalManagement(data.operations);
            break;
        case 'closeIllegalMenu':
            closeIllegalMenu();
            break;
    }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL BACKGROUND SYSTEM
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function setIllegalBackground(config) {
    console.log('[ILLEGAL-UI] Setting background:', config);
    
    illegalBackgroundEnabled = config.enabled !== false;
    illegalBackgroundImage = config.image || 'illegal_background.jpg';
    
    if (illegalBackgroundEnabled) {
        $('#illegal-background').css({
            'background-image': `url('${illegalBackgroundImage}')`,
            'opacity': (config.opacity || 90) / 100,
            'filter': config.blur ? `blur(${config.blurStrength || 5}px)` : 'none'
        });
    }
}

function enableIllegalBackground() {
    console.log('[ILLEGAL-UI] Enabling illegal background');
    $('body').addClass('illegal-active');
}

function disableIllegalBackground() {
    console.log('[ILLEGAL-UI] Disabling illegal background');
    $('body').removeClass('illegal-active');
}

// Close menu on ESC - with conflict prevention
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && window.currentIllegalMenu) {
        event.stopPropagation(); // Prevent script.js ESC handler from also firing
        event.preventDefault();
        closeIllegalMenu();
    }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL BOSS MENU (Tablet NPC)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalBossMenu(data) {
    console.log('[ILLEGAL-UI] Opening Boss Menu with data:', data);
    
    illegalData = data || {};
    isClosing = false; // Reset closing flag when opening new menu
    
    // Enable illegal background
    enableIllegalBackground();
    
    // Update schwarze Kasse
    $('#blackCash').text(formatMoney(data.blackCash || 0));
    
    // Hide all menus
    $('.illegal-container').hide();
    
    // Show Boss Menu
    $('#illegal-boss-menu').fadeIn(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = 'boss';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL SHOP (Army Helis)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalShop(vehicles) {
    console.log('[ILLEGAL-UI] Opening Shop with vehicles:', vehicles);
    
    isClosing = false; // Reset closing flag when opening new menu
    
    // Enable illegal background
    enableIllegalBackground();
    
    // Hide all menus
    $('.illegal-container').hide();
    
    // Clear vehicle list
    $('#illegal-vehicle-list').empty();
    
    // Add vehicles
    if (vehicles && vehicles.length > 0) {
        vehicles.forEach(function(vehicle) {
            const vehicleHtml = `
                <div class="vehicle-name">${vehicle.name}</div>
                <div class="vehicle-price">$${formatMoney(vehicle.price)}</div>
                <div class="vehicle-stats">
                    ⚡ Speed: ${vehicle.speed || 'N/A'} | 
                    🔧 Handling: ${vehicle.handling || 'N/A'}
                </div>
            `;
            const vehicleCard = $('<div>').addClass('vehicle-card').html(vehicleHtml);
            
            vehicleCard.click(function() {
                buyIllegalVehicle(vehicle);
            });
            
            $('#illegal-vehicle-list').append(vehicleCard);
        });
    } else {
        $('#illegal-vehicle-list').html('<div style="color: #999; text-align: center; padding: 40px;">Keine Fahrzeuge verfügbar</div>');
    }
    
    // Show Shop
    $('#illegal-shop').fadeIn(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = 'shop';
}

function buyIllegalVehicle(vehicle) {
    console.log('[ILLEGAL-UI] Buying vehicle:', vehicle.model);
    
    $.post('https://Heli-Taxi/buyIllegalVehicle', JSON.stringify({
        model: vehicle.model,
        price: vehicle.price
    }));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL GARAGE (Helipad NPCs)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalGarage(vehicles, helipadIndex) {
    console.log('[ILLEGAL-UI] Opening Garage | Helipad:', helipadIndex, '| Vehicles:', vehicles);
    
    isClosing = false; // Reset closing flag when opening new menu
    
    // Enable illegal background
    enableIllegalBackground();
    
    // Hide all menus
    $('.illegal-container').hide();
    
    // Set helipad name
    $('#helipadName').text('HELIPAD ' + (helipadIndex || 1));
    
    // Clear vehicle list
    $('#illegal-garage-vehicles').empty();
    
    // Add vehicles
    if (vehicles && vehicles.length > 0) {
        vehicles.forEach(function(vehicle) {
            const vehicleItemHtml = `
                <div class="vehicle-info">
                    <div class="name">${vehicle.model}</div>
                    <div class="plate">${vehicle.plate || 'N/A'}</div>
                </div>
                <button class="illegal-btn" style="padding: 8px 15px; font-size: 14px;">SPAWN</button>
            `;
            const vehicleItem = $('<div>').addClass('vehicle-item').html(vehicleItemHtml);
            
            vehicleItem.find('.illegal-btn').click(function() {
                spawnIllegalVehicleById(vehicle.id);
            });
            
            $('#illegal-garage-vehicles').append(vehicleItem);
        });
    } else {
        $('#illegal-garage-vehicles').html('<div style="color: #999; text-align: center; padding: 40px;">Keine Fahrzeuge geparkt</div>');
    }
    
    // Show Garage
    $('#illegal-garage').fadeIn(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = 'garage';
}

function spawnIllegalVehicle() {
    if (selectedVehicle) {
        console.log('[ILLEGAL-UI] Spawning vehicle:', selectedVehicle);
        
        $.post('https://Heli-Taxi/spawnIllegalVehicle', JSON.stringify({
            vehicleId: selectedVehicle
        }));
        
        closeIllegalMenu();
    }
}

function spawnIllegalVehicleById(vehicleId) {
    console.log('[ILLEGAL-UI] Spawning vehicle by ID:', vehicleId);
    
    $.post('https://Heli-Taxi/spawnIllegalVehicle', JSON.stringify({
        vehicleId: vehicleId
    }));
    
    closeIllegalMenu();
}

function storeIllegalVehicle() {
    console.log('[ILLEGAL-UI] Storing current vehicle');
    
    $.post('https://Heli-Taxi/storeIllegalVehicle', JSON.stringify({}));
    
    closeIllegalMenu();
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL MANAGEMENT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalManagement(operations) {
    console.log('[ILLEGAL-UI] Opening Management with operations:', operations);
    
    isClosing = false; // Reset closing flag when opening new menu
    
    // Hide all menus
    $('.illegal-container').hide();
    
    // Update stats
    $('#heatLevel').text((operations.heatLevel || 0) + '%');
    $('#operationsCount').text(operations.count || 0);
    $('#totalProfit').text(formatMoney(operations.totalProfit || 0));
    
    // Clear operations list
    $('#operationsList').empty();
    
    // Add operations
    if (operations.list && operations.list.length > 0) {
        operations.list.forEach(function(op) {
            const operationItemHtml = `
                <div class="operation-header">
                    <span class="operation-type">${op.type}</span>
                    <span class="operation-profit">$${formatMoney(op.profit)}</span>
                </div>
                <div class="operation-details">${op.details}</div>
            `;
            const operationItem = $('<div>').addClass('operation-item').html(operationItemHtml);
            
            $('#operationsList').append(operationItem);
        });
    } else {
        $('#operationsList').html('<div style="color: #999; text-align: center; padding: 40px;">Keine Operations</div>');
    }
    
    // Show Management
    $('#illegal-management').fadeIn(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = 'management';
}

function manageIllegalOperations() {
    console.log('[ILLEGAL-UI] Opening illegal operations management');
    
    $.post('https://Heli-Taxi/requestIllegalOperations', JSON.stringify({}));
}

function viewIllegalTransactions() {
    console.log('[ILLEGAL-UI] Opening illegal transactions');
    
    $.post('https://Heli-Taxi/requestIllegalTransactions', JSON.stringify({}));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NAVIGATION FROM BOSS MENU
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalShopFromMenu() {
    console.log('[ILLEGAL-UI] Requesting illegal shop from boss menu');
    
    $.post('https://Heli-Taxi/requestIllegalShopFromMenu', JSON.stringify({}));
}

function openIllegalGarageFromMenu() {
    console.log('[ILLEGAL-UI] Requesting illegal garage from boss menu');
    
    $.post('https://Heli-Taxi/requestIllegalGarageFromMenu', JSON.stringify({}));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UTILITY FUNCTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function closeIllegalMenu() {
    // Prevent multiple simultaneous close calls
    if (isClosing) {
        console.log('[ILLEGAL-UI] Already closing, ignoring duplicate call');
        return;
    }
    
    if (!window.currentIllegalMenu) {
        console.log('[ILLEGAL-UI] No menu open, ignoring close call');
        return;
    }
    
    console.log('[ILLEGAL-UI] Closing illegal menu');
    isClosing = true;
    
    // Disable illegal background
    disableIllegalBackground();
    
    $('.illegal-container').fadeOut(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = null;
    selectedVehicle = null;
    
    $.post('https://Heli-Taxi/closeIllegalMenu', JSON.stringify({}));
    
    // Reset closing flag after animation completes
    setTimeout(function() {
        isClosing = false;
    }, CLOSE_DEBOUNCE_TIMEOUT);
}

function formatMoney(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
