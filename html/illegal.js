// ILLEGALES UI - KOMPLETT GETRENNT VOM NORMALEN SYSTEM
// GLEICHER AUFBAU WIE LEGAL, ABER STRIKT GETRENNT

// Use window.currentIllegalMenu to share state with script.js for ESC key handling
window.currentIllegalMenu = null;
let illegalData = {};
let illegalCurrentTab = 'illegal-dashboard';

// Constants
const CLOSE_ANIMATION_DURATION = 300;

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
        case 'updateIllegalFleet':
            displayIllegalFleet(data.vehicles);
            break;
        case 'updateIllegalTransactions':
            displayIllegalTransactions(data.transactions);
            break;
        case 'closeIllegalMenu':
            closeIllegalMenu();
            break;
    }
});

// Background system
function setIllegalBackground(config) {
    console.log('[ILLEGAL-UI] Setting background:', config);
    
    const enabled = config.enabled !== false;
    const image = config.image || 'illegal_background.jpg';
    
    if (enabled) {
        $('#illegal-background').css({
            'background-image': `url('${image}')`,
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

// Close menu on ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && window.currentIllegalMenu) {
        event.stopPropagation();
        event.preventDefault();
        closeIllegalMenu();
    }
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL BOSS MENU - TABS SYSTEM (wie Legal Boss Menu)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function switchIllegalTab(tabName, element) {
    console.log('[ILLEGAL-UI] Switching to tab:', tabName);
    
    illegalCurrentTab = tabName;
    
    // Update tab buttons
    $('#illegalBossMenu .tab-btn').removeClass('active');
    if (element) {
        $(element).addClass('active');
    }
    
    // Update tab content
    $('#illegalBossMenu .tab-content').removeClass('active');
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
    console.log('[ILLEGAL-UI] Loading dashboard');
    updateIllegalDashboardStats();
}

function loadIllegalFleet() {
    console.log('[ILLEGAL-UI] Loading fleet');
    $.post('https://Heli-Taxi/getIllegalFleet', JSON.stringify({}));
}

function loadIllegalFinances() {
    console.log('[ILLEGAL-UI] Loading finances');
    updateIllegalFinancesDisplay();
    $.post('https://Heli-Taxi/getIllegalTransactions', JSON.stringify({}));
}

function loadIllegalOperations() {
    console.log('[ILLEGAL-UI] Loading operations');
    updateIllegalOperationsStats();
    $.post('https://Heli-Taxi/getIllegalOperations', JSON.stringify({}));
}

function openIllegalBossMenu(data) {
    console.log('[ILLEGAL-UI] Opening Illegal Boss Menu with data:', data);
    
    illegalData = data || {};
    
    // Enable illegal background
    enableIllegalBackground();
    
    // Update all stats
    updateIllegalDashboardStats();
    updateIllegalFinancesDisplay();
    updateIllegalOperationsStats();
    
    // Show menu
    $('#illegalBossMenu').fadeIn(CLOSE_ANIMATION_DURATION);
    switchIllegalTab('illegal-dashboard', $('#illegalBossMenu .tab-btn').first());
    window.currentIllegalMenu = 'boss';
    
    // Load fleet immediately
    loadIllegalFleet();
}

function updateIllegalDashboardStats() {
    if (!illegalData) return;
    
    $('#illegalBalance').text('$' + formatMoney(illegalData.blackCash || 0));
    $('#illegalArmyCount').text(illegalData.armyVehicleCount || 0);
    $('#illegalOpsCount').text(illegalData.operationsCount || 0);
    $('#illegalHeat').text((illegalData.heatLevel || 0) + '%');
    $('#illegalProfit').text('$' + formatMoney(illegalData.totalProfit || 0));
}

function updateIllegalFinancesDisplay() {
    if (!illegalData) return;
    
    $('#illegalFinanceBalance').text('$' + formatMoney(illegalData.blackCash || 0));
    $('#illegalFinanceIncome').text('$' + formatMoney(illegalData.illegalIncome || 0));
    $('#illegalFinanceExpenses').text('$' + formatMoney(illegalData.illegalExpenses || 0));
}

function updateIllegalOperationsStats() {
    if (!illegalData) return;
    
    $('#illegalHeatOps').text((illegalData.heatLevel || 0) + '%');
    $('#illegalOpsCountOps').text(illegalData.operationsCount || 0);
    $('#illegalProfitOps').text('$' + formatMoney(illegalData.totalProfit || 0));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL FLEET DISPLAY (BESTAND 1)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function displayIllegalFleet(vehicles) {
    console.log('[ILLEGAL-UI] Displaying fleet:', vehicles);
    
    const container = $('#illegalVehicleList');
    container.empty();
    
    if (!vehicles || vehicles.length === 0) {
        container.html('<div class="no-data" style="padding: 40px; text-align: center; color: #999;">Keine Army Fahrzeuge im Bestand</div>');
        return;
    }
    
    vehicles.forEach(function(vehicle) {
        const vehicleName = vehicle.label || vehicle.model || 'Unknown';
        const vehicleCard = $('<div>').addClass('vehicle-card illegal-vehicle-card').html(`
            <div class="vehicle-name" style="color: #ff4444; font-weight: 500; margin-bottom: 8px;">${vehicleName}</div>
            <div class="vehicle-model" style="color: #999; font-size: 12px; margin-bottom: 5px;">Model: ${vehicle.model}</div>
            <div class="vehicle-plate" style="color: #666; font-size: 11px; margin-bottom: 10px;">🔖 ${vehicle.plate || 'N/A'}</div>
            <div class="vehicle-status" style="color: ${vehicle.state === 1 ? '#00ff00' : '#ffaa00'}; font-size: 12px;">
                ${vehicle.state === 1 ? '✓ Verfügbar' : '⚠ Im Einsatz'}
            </div>
        `);
        
        container.append(vehicleCard);
    });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL SHOP (BESTAND 2)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalShop() {
    console.log('[ILLEGAL-UI] Opening illegal shop');
    $.post('https://Heli-Taxi/requestIllegalShop', JSON.stringify({}));
}

function openIllegalShopActual(vehicles) {
    console.log('[ILLEGAL-UI] Opening shop with vehicles:', vehicles);
    
    // Hide boss menu, show shop
    $('#illegalBossMenu').hide();
    
    // Update shop balance
    $('#illegalShopBalance').text(formatMoney(illegalData.blackCash || 0));
    
    // Clear and populate vehicle grid
    const container = $('#illegalShopVehicleGrid');
    container.empty();
    
    if (!vehicles || vehicles.length === 0) {
        container.html('<div class="no-data" style="padding: 40px; text-align: center; color: #999;">Keine Fahrzeuge verfügbar</div>');
    } else {
        vehicles.forEach(function(vehicle) {
            const vehicleName = vehicle.label || vehicle.model || 'Unknown';
            const vehicleCard = $('<div>').addClass('vehicle-card illegal-vehicle-card').html(`
                <div class="vehicle-name" style="color: #ff4444; font-weight: 500; margin-bottom: 10px;">${vehicleName}</div>
                <div class="vehicle-price" style="color: #00ff00; font-size: 22px; font-weight: 300; margin: 10px 0;">$${formatMoney(vehicle.price)}</div>
                <div class="vehicle-category" style="color: #999; font-size: 11px; margin-bottom: 8px;">
                    ${vehicle.category === 'military' ? '🎖️ MILITARY' : '🚁 ARMY'}
                </div>
                <div class="vehicle-stats" style="color: #666; font-size: 11px;">
                    ${vehicle.passengers ? '👥 ' + vehicle.passengers + ' Sitze' : ''}
                    ${vehicle.armed ? ' | 🎯 Bewaffnet' : ''}
                </div>
            `);
            
            vehicleCard.click(function() {
                buyIllegalVehicle(vehicle);
            });
            
            container.append(vehicleCard);
        });
    }
    
    $('#illegalVehicleShop').fadeIn(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = 'shop';
}

function buyIllegalVehicle(vehicle) {
    console.log('[ILLEGAL-UI] Buying vehicle:', vehicle);
    
    $.post('https://Heli-Taxi/purchaseIllegalVehicle', JSON.stringify({
        model: vehicle.model,
        price: vehicle.price
    }));
}

function closeIllegalShop() {
    $('#illegalVehicleShop').fadeOut(CLOSE_ANIMATION_DURATION, function() {
        $('#illegalBossMenu').fadeIn(CLOSE_ANIMATION_DURATION);
    });
    window.currentIllegalMenu = 'boss';
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ILLEGAL GARAGE (3 Helipad NPCs)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function openIllegalGarage(vehicles, helipadIndex) {
    console.log('[ILLEGAL-UI] Opening garage | Helipad:', helipadIndex, '| Vehicles:', vehicles);
    
    // Enable illegal background
    enableIllegalBackground();
    
    // Update helipad name
    $('#illegalHelipadName').text('HELIPAD ' + (helipadIndex || 1));
    $('#illegalGarageCount').text(vehicles ? vehicles.length : 0);
    
    // Clear and populate vehicle list
    const container = $('#illegalGarageVehicles');
    container.empty();
    
    if (!vehicles || vehicles.length === 0) {
        container.html('<div class="no-data" style="padding: 40px; text-align: center; color: #999;">Keine Fahrzeuge geparkt</div>');
    } else {
        vehicles.forEach(function(vehicle) {
            const vehicleName = vehicle.label || vehicle.model || 'Unknown';
            const fuelPercent = Math.max(0, Math.min(100, vehicle.fuel || 100));
            const fuelColor = fuelPercent > 50 ? '#00ff00' : fuelPercent > 25 ? '#ffaa00' : '#ff0000';
            
            const vehicleItem = $('<div>').addClass('vehicle-item').css({
                'background': 'rgba(0, 0, 0, 0.4)',
                'border-left': '2px solid #8b0000',
                'padding': '15px',
                'margin-bottom': '10px',
                'display': 'flex',
                'justify-content': 'space-between',
                'align-items': 'center'
            }).html(`
                <div class="vehicle-info">
                    <div class="name" style="color: #ff4444; font-weight: 500; margin-bottom: 5px;">${vehicleName}</div>
                    <div class="plate" style="color: #999; font-size: 12px; margin-bottom: 5px;">🔖 ${vehicle.plate || 'N/A'}</div>
                    <div class="fuel-bar" style="display: flex; align-items: center; gap: 10px;">
                        <div class="fuel-bar-bg" style="width: 100px; height: 4px; background: rgba(255,255,255,0.1); border-radius: 2px; overflow: hidden;">
                            <div class="fuel-bar-fill" style="width: ${fuelPercent}%; height: 100%; background: ${fuelColor};"></div>
                        </div>
                        <span style="color: #666; font-size: 11px;">⛽ ${Math.round(fuelPercent)}%</span>
                    </div>
                </div>
                <button class="btn btn-danger" style="padding: 8px 16px; font-size: 12px;">SPAWNEN</button>
            `);
            
            vehicleItem.find('.btn').click(function() {
                spawnIllegalVehicle(vehicle.id);
            });
            
            container.append(vehicleItem);
        });
    }
    
    $('#illegalGarage').fadeIn(CLOSE_ANIMATION_DURATION);
    window.currentIllegalMenu = 'garage';
}

function spawnIllegalVehicle(vehicleId) {
    console.log('[ILLEGAL-UI] Spawning vehicle:', vehicleId);
    
    $.post('https://Heli-Taxi/spawnIllegalVehicle', JSON.stringify({
        vehicleId: vehicleId
    }));
    
    closeIllegalGarage();
}

function storeIllegalVehicle() {
    console.log('[ILLEGAL-UI] Storing vehicle');
    
    $.post('https://Heli-Taxi/storeIllegalVehicle', JSON.stringify({}));
}

function closeIllegalGarage() {
    $('#illegalGarage').fadeOut(CLOSE_ANIMATION_DURATION);
    disableIllegalBackground();
    window.currentIllegalMenu = null;
    
    $.post('https://Heli-Taxi/closeMenu', JSON.stringify({}));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TRANSACTIONS DISPLAY
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function displayIllegalTransactions(transactions) {
    console.log('[ILLEGAL-UI] Displaying transactions:', transactions);
    
    const tbody = $('#illegalTransactionTableBody');
    tbody.empty();
    
    if (!transactions || transactions.length === 0) {
        tbody.html('<tr><td colspan="4" class="no-data">Keine Transaktionen</td></tr>');
        return;
    }
    
    transactions.forEach(function(tx) {
        const row = $('<tr>').html(`
            <td>${tx.date || '-'}</td>
            <td>${tx.type || '-'}</td>
            <td style="color: ${tx.amount > 0 ? '#00ff00' : '#ff4444'};">$${formatMoney(Math.abs(tx.amount || 0))}</td>
            <td>${tx.description || '-'}</td>
        `);
        tbody.append(row);
    });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CLOSE MENU
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function closeIllegalMenu() {
    console.log('[ILLEGAL-UI] Closing all menus');
    
    $('#illegalBossMenu').fadeOut(CLOSE_ANIMATION_DURATION);
    $('#illegalVehicleShop').fadeOut(CLOSE_ANIMATION_DURATION);
    $('#illegalGarage').fadeOut(CLOSE_ANIMATION_DURATION);
    
    disableIllegalBackground();
    window.currentIllegalMenu = null;
    
    $.post('https://Heli-Taxi/closeMenu', JSON.stringify({}));
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HELPER FUNCTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function formatMoney(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function toggleIllegalDuty() {
    console.log('[ILLEGAL-UI] Toggling duty');
    $.post('https://Heli-Taxi/toggleDuty', JSON.stringify({}));
}

function showIllegalDepositDialog() {
    console.log('[ILLEGAL-UI] Show deposit dialog');
    // TODO: Implement deposit dialog
}

function showIllegalWithdrawDialog() {
    console.log('[ILLEGAL-UI] Show withdraw dialog');
    // TODO: Implement withdraw dialog
}

console.log('[ILLEGAL-UI] illegal.js loaded - STRIKT GETRENNT VERSION');
