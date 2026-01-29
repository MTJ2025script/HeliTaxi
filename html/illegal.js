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
        case 'updateIllegalFleet':
            displayIllegalFleet(data.vehicles);
            break;
        case 'updateIllegalTransactions':
            displayIllegalTransactions(data.transactions);
            break;
        case 'updateIllegalOperations':
            displayIllegalOperations(data.operations);
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
// ILLEGAL TAB SWITCHING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function switchIllegalTab(tabName, element) {
    console.log('[ILLEGAL-UI] Switching to tab:', tabName);
    
    // Update tab buttons
    $('.illegal-tabs .tab-btn').removeClass('active');
    if (element) {
        $(element).addClass('active');
    }
    
    // Update tab content
    $('#illegal-boss-menu .tab-content').removeClass('active');
    $('#' + tabName).addClass('active');
    
    // Load tab data
    switch(tabName) {
        case 'illegal-dashboard':
            loadIllegalDashboard();
            break;
        case 'illegal-fleet':
            loadIllegalFleet();
            break;
        case 'illegal-finances':
            loadIllegalFinances();
            break;
        case 'illegal-operations':
            loadIllegalOperations();
            break;
    }
}

function loadIllegalDashboard() {
    console.log('[ILLEGAL-UI] Loading illegal dashboard');
    // Update dashboard stats from illegalData
    if (illegalData) {
        $('#illegalDashboardBalance').text('$' + formatMoney(illegalData.blackCash || 0));
        $('#illegalArmyVehicles').text(illegalData.armyVehicleCount || 0);
        $('#illegalOperationsCount').text(illegalData.operationsCount || 0);
    }
}

function loadIllegalFleet() {
    console.log('[ILLEGAL-UI] Loading illegal fleet');
    // Request fleet data from server
    $.post('https://Heli-Taxi/getIllegalFleet', JSON.stringify({}));
}

function loadIllegalFinances() {
    console.log('[ILLEGAL-UI] Loading illegal finances');
    // Update finances from illegalData
    if (illegalData) {
        $('#illegalFinancesBalance').text('$' + formatMoney(illegalData.blackCash || 0));
        $('#illegalFinancesIncome').text('$' + formatMoney(illegalData.illegalIncome || 0));
        $('#illegalHeatLevel').text((illegalData.heatLevel || 0) + '%');
    }
    // Request transactions
    $.post('https://Heli-Taxi/getIllegalTransactions', JSON.stringify({}));
}

function loadIllegalOperations() {
    console.log('[ILLEGAL-UI] Loading illegal operations');
    // Request operations data
    $.post('https://Heli-Taxi/getIllegalOperations', JSON.stringify({}));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL BOSS MENU (Tablet NPC)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalBossMenu(data) {
    console.log('[ILLEGAL-UI] Opening Boss Menu with data:', data);
    
    illegalData = data || {};
    isClosing = false; // Reset closing flag when opening new menu
    
    // Enable illegal background
    enableIllegalBackground();
    
    // Update all dashboard stats
    $('#illegalDashboardBalance').text('$' + formatMoney(data.blackCash || 0));
    $('#illegalArmyVehicles').text(data.armyVehicleCount || 0);
    $('#illegalOperationsCount').text(data.operationsCount || 0);
    
    // Update finances tab
    $('#illegalFinancesBalance').text('$' + formatMoney(data.blackCash || 0));
    $('#illegalFinancesIncome').text('$' + formatMoney(data.illegalIncome || 0));
    $('#illegalHeatLevel').text((data.heatLevel || 0) + '%');
    
    // Update operations tab
    $('#illegalHeatLevelOps').text((data.heatLevel || 0) + '%');
    $('#illegalOperationsCountOps').text(data.operationsCount || 0);
    $('#illegalTotalProfit').text(formatMoney(data.totalProfit || 0));
    
    // Hide all illegal menus
    $('.illegal-container').hide();
    
    // Show Boss Menu and ensure we're on dashboard tab
    $('#illegal-boss-menu').fadeIn(CLOSE_ANIMATION_DURATION);
    switchIllegalTab('illegal-dashboard', $('.illegal-tabs .tab-btn').first());
    window.currentIllegalMenu = 'boss';
    
    // Load fleet immediately
    loadIllegalFleet();
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
    
    // Update shop balance (use blackCash from illegalData)
    $('#shopBalance').text(formatMoney(illegalData.blackCash || 0));
    
    // Clear vehicle list
    $('#illegal-vehicle-list').empty();
    
    // Add vehicles
    if (vehicles && vehicles.length > 0) {
        vehicles.forEach(function(vehicle) {
            // Determine category badge
            const categoryLabel = vehicle.category === 'transport' ? 'TRANSPORT' : 
                                vehicle.category === 'attack' ? 'ATTACK' : 
                                'MILITARY';
            
            // Use consistent vehicle name property
            const vehicleName = vehicle.label || vehicle.name || 'Unknown Vehicle';
            
            // Build stats display
            const stats = [];
            if (vehicle.passengers) stats.push(`👥 ${vehicle.passengers} Sitze`);
            if (vehicle.speed) stats.push(`⚡ Speed: ${vehicle.speed}`);
            if (vehicle.armed) stats.push(`🎯 Bewaffnet`);
            if (vehicle.heavyLift) stats.push(`💪 Heavy Lift`);
            
            const vehicleHtml = `
                <div class="vehicle-name">${vehicleName}</div>
                <div class="vehicle-category">${categoryLabel}</div>
                <div class="vehicle-price">$${formatMoney(vehicle.price)}</div>
                <div class="vehicle-stats">
                    ${stats.join(' | ')}
                </div>
            `;
            const vehicleCard = $('<div>')
                .addClass('vehicle-card')
                .attr('data-category', vehicle.category || 'all')
                .html(vehicleHtml);
            
            vehicleCard.click(function() {
                buyIllegalVehicle(vehicle);
            });
            
            $('#illegal-vehicle-list').append(vehicleCard);
        });
    } else {
        $('#illegal-vehicle-list').html('<div class="no-vehicles" style="grid-column: 1 / -1;">Keine Fahrzeuge verfügbar</div>');
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
    
    // Update vehicle count
    $('#vehicleCount').text(vehicles ? vehicles.length : 0);
    
    // Clear vehicle list
    $('#illegal-garage-vehicles').empty();
    
    // Add vehicles
    if (vehicles && vehicles.length > 0) {
        vehicles.forEach(function(vehicle) {
            // Calculate fuel percentage for display with validation
            let fuelPercent = vehicle.fuel !== undefined ? vehicle.fuel : 100;
            // Clamp value between 0 and 100
            fuelPercent = Math.max(0, Math.min(100, fuelPercent));
            const fuelColor = fuelPercent > 50 ? '#00ff00' : fuelPercent > 25 ? '#ffaa00' : '#ff0000';
            
            // Use consistent vehicle name property
            const vehicleName = vehicle.label || vehicle.model || 'Unknown';
            
            const vehicleItemHtml = `
                <div class="vehicle-info">
                    <div class="name">${vehicleName}</div>
                    <div class="plate">🔖 ${vehicle.plate || 'N/A'}</div>
                    <div class="fuel-bar">
                        <div class="fuel-bar-bg">
                            <div class="fuel-bar-fill" style="width: ${fuelPercent}%; background: ${fuelColor};"></div>
                        </div>
                        <span class="fuel-text">⛽ ${Math.round(fuelPercent)}%</span>
                    </div>
                </div>
                <button class="spawn-btn">SPAWNEN</button>
            `;
            const vehicleItem = $('<div>').addClass('vehicle-item').html(vehicleItemHtml);
            
            vehicleItem.find('.spawn-btn').click(function() {
                spawnIllegalVehicleById(vehicle.id);
            });
            
            $('#illegal-garage-vehicles').append(vehicleItem);
        });
    } else {
        $('#illegal-garage-vehicles').html('<div class="no-vehicles">Keine Fahrzeuge geparkt</div>');
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

function openIllegalShopFromIllegalMenu() {
    console.log('[ILLEGAL-UI] Opening illegal shop from illegal boss menu fleet tab');
    
    $.post('https://Heli-Taxi/requestIllegalShopFromMenu', JSON.stringify({}));
}

function openIllegalGarageFromMenu() {
    console.log('[ILLEGAL-UI] Requesting illegal garage from boss menu');
    
    $.post('https://Heli-Taxi/requestIllegalGarageFromMenu', JSON.stringify({}));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DISPLAY ILLEGAL FLEET IN BOSS MENU
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function displayIllegalFleet(vehicles) {
    console.log('[ILLEGAL-UI] Displaying illegal fleet:', vehicles);
    
    const container = $('#illegalVehicleList');
    container.empty();
    
    if (!vehicles || vehicles.length === 0) {
        container.html('<div class="no-data" style="padding: 40px; text-align: center; color: #999;">Keine Army Fahrzeuge im Bestand</div>');
        return;
    }
    
    vehicles.forEach(function(vehicle) {
        const vehicleName = vehicle.label || vehicle.model || 'Unknown';
        const vehicleCard = $('<div>').addClass('vehicle-card illegal-vehicle-card').html(`
            <div class="vehicle-name" style="color: #ff4444;">${vehicleName}</div>
            <div class="vehicle-model" style="color: #999; font-size: 12px; margin-top: 5px;">Model: ${vehicle.model}</div>
            <div class="vehicle-plate" style="color: #666; font-size: 11px; margin-top: 5px;">Kennzeichen: ${vehicle.plate || 'N/A'}</div>
            <div class="vehicle-status" style="color: #00ff00; font-size: 12px; margin-top: 10px;">
                ${vehicle.state === 1 ? '✓ Verfügbar' : '⚠ Im Einsatz'}
            </div>
        `);
        
        container.append(vehicleCard);
    });
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CATEGORY FILTER FOR SHOP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function filterShopCategory(category) {
    console.log('[ILLEGAL-UI] Filtering shop by category:', category);
    
    // Update active button using data attribute
    $('.category-btn').removeClass('active');
    $(`.category-btn[data-category="${category}"]`).addClass('active');
    
    // Filter vehicles
    if (category === 'all') {
        $('.vehicle-card').show();
    } else {
        $('.vehicle-card').hide();
        $(`.vehicle-card[data-category="${category}"]`).show();
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GARAGE REFRESH
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function refreshGarage() {
    console.log('[ILLEGAL-UI] Refreshing garage inventory');
    
    // Close current menu
    closeIllegalMenu();
    
    // Request fresh data from server
    $.post('https://Heli-Taxi/requestIllegalGarageFromMenu', JSON.stringify({}));
}
