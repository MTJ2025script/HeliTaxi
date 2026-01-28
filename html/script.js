// Global state
let currentEmployee = null;
let currentGender = 'male';
let shopVehicles = [];

// NUI Message Handler
window.addEventListener('message', (event) => {
    const data = event.data;
    
    // Set UI Background Image
    if (data.action === 'setBackground') {
        const bgElement = document.querySelector('.ui-background');
        if (bgElement && data.enabled) {
            bgElement.style.backgroundImage = `url('img/${data.image}')`;
            bgElement.style.opacity = (data.opacity || 85) / 100;
            if (data.blur) {
                bgElement.style.filter = `blur(${data.blurStrength || 5}px)`;
            } else {
                bgElement.style.filter = 'none';
            }
        } else if (bgElement) {
            bgElement.style.backgroundImage = 'none';
        }
        return;
    }
    
    switch(data.action) {
        case 'openBossMenu':
            currentEmployee = data.employeeData;
            
            // Check if this is an ILLEGAL boss menu
            if (currentEmployee && currentEmployee.illegal === true) {
                console.log('[Heli-Taxi] Opening ILLEGAL Boss Menu - schwarze Kasse aktiv!');
                console.log('[Heli-Taxi] Account type:', currentEmployee.account);
                
                // Show illegal UI elements
                document.getElementById('illegalBalanceCard').style.display = 'block';
                document.getElementById('illegalFinanceCard').style.display = 'block';
                document.getElementById('illegalIncomeCard').style.display = 'block';
                document.getElementById('illegalFilterBtn').style.display = 'inline-block';
                
                // Add red theme to boss menu
                document.getElementById('bossMenu').classList.add('illegal-mode');
            } else {
                console.log('[Heli-Taxi] Opening NORMAL Boss Menu');
                
                // Hide illegal UI elements
                document.getElementById('illegalBalanceCard').style.display = 'none';
                document.getElementById('illegalFinanceCard').style.display = 'none';
                document.getElementById('illegalIncomeCard').style.display = 'none';
                document.getElementById('illegalFilterBtn').style.display = 'none';
                
                // Remove red theme
                document.getElementById('bossMenu').classList.remove('illegal-mode');
            }
            
            openMenu('bossMenu');
            loadDashboard();
            loadSettings();  // Load settings immediately
            break;
        case 'openWardrobe':
            currentGender = data.gender;
            openMenu('wardrobeMenu');
            break;
        case 'openVehicleManagement':
            openMenu('vehicleManagement');
            // Don't call fetchVehicles() here - vehicles already sent via updateVehicleList
            break;
        case 'updateVehicleList':
            vehiclesFetching = false;  // Reset flag
            displayVehicles(data.vehicles);
            break;
        case 'closeMenu':
        case 'forceClose':
            closeMenu();
            break;
        case 'showHUD':
            showHUD(data.flatFee);
            break;
        case 'hideHUD':
            hideHUD();
            break;
        case 'updateHUD':
            updateHUD(data);
            break;
        case 'receiveEmployees':
            displayEmployees(data.employees);
            break;
        case 'receiveStatistics':
            displayStatistics(data.stats);
            break;
        case 'receiveNearbyPlayers':
            displayNearbyPlayers(data.players);
            break;
        case 'receiveVehicles':
            // Legacy support - same as updateVehicleList
            vehiclesFetching = false;
            displayVehicles(data.vehicles);
            break;
        case 'receiveVehicleShop':
            displayVehicleShop(data.shopData);
            break;
        case 'receiveTransactions':
            displayTransactions(data.transactions);
            break;
        case 'receiveBalance':
            displayBalance(data.balance);
            break;
        case 'updateBalance':
            document.getElementById('companyBalance').textContent = '$' + formatNumber(data.balance);
            break;
    }
});

// Close menu on ESC
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Don't close if an illegal menu is open - let illegal.js handle it
        if (window.currentIllegalMenu) {
            return;
        }
        closeMenu();
    }
});

// Menu Functions
function openMenu(menuId) {
    document.getElementById(menuId).style.display = 'flex';
    
    // Show background when menu opens
    const bgElement = document.querySelector('.ui-background');
    if (bgElement) {
        bgElement.style.display = 'block';
    }
}

function closeMenu() {
    document.querySelectorAll('.menu-container').forEach(menu => {
        menu.style.display = 'none';
    });
    
    // Hide background when menu closes
    const bgElement = document.querySelector('.ui-background');
    if (bgElement) {
        bgElement.style.display = 'none';
    }
    
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Tab Switching
function switchTab(tabName, element) {
    // Update tab buttons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    if (element) {
        element.classList.add('active');
    }
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tabName).classList.add('active');
    
    // Load tab data
    switch(tabName) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'employees':
            fetchEmployees();
            break;
        case 'fleet':
            fetchVehicles();
            break;
        case 'finances':
            fetchFinances();
            break;
        case 'calendar':
            loadAppointments();
            break;
        case 'settings':
            loadSettings();
            break;
    }
}

// Dashboard
function loadDashboard() {
    fetchStatistics();
    
    if (currentEmployee) {
        const dutyBtn = document.getElementById('dutyStatus');
        dutyBtn.textContent = currentEmployee.status === 'on_duty' ? 'Dienst beenden' : 'Im Dienst gehen';
    }
}

function fetchStatistics() {
    fetch(`https://${GetParentResourceName()}/getStatistics`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function displayStatistics(stats) {
    // Normal company balance
    document.getElementById('companyBalance').textContent = '$' + formatNumber(stats.balance);
    document.getElementById('totalFlights').textContent = formatNumber(stats.totalFlights);
    document.getElementById('fleetSize').textContent = formatNumber(stats.totalVehicles);
    document.getElementById('onDutyCount').textContent = formatNumber(stats.onDutyEmployees);
    
    // Illegal account (schwarze Kasse)
    if (currentEmployee && currentEmployee.illegal === true && stats.illegalBalance !== undefined) {
        console.log('[Heli-Taxi] Displaying illegal balance: $' + stats.illegalBalance);
        document.getElementById('illegalBalance').textContent = '$' + formatNumber(stats.illegalBalance);
        document.getElementById('illegalFinanceBalance').textContent = '$' + formatNumber(stats.illegalBalance);
        document.getElementById('illegalIncome').textContent = '$' + formatNumber(stats.illegalIncome || 0);
    }
}

// Toggle Duty
function toggleDuty() {
    fetch(`https://${GetParentResourceName()}/toggleDuty`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    
    // Toggle UI
    const dutyBtn = document.getElementById('dutyStatus');
    const isOnDuty = dutyBtn.textContent === 'Dienst beenden';
    dutyBtn.textContent = isOnDuty ? 'Im Dienst gehen' : 'Dienst beenden';
}

// Employees
function fetchEmployees() {
    fetch(`https://${GetParentResourceName()}/getEmployees`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function displayEmployees(employees) {
    const tbody = document.getElementById('employeeTableBody');
    tbody.innerHTML = '';
    
    if (!employees || employees.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="no-data">Keine Mitarbeiter gefunden</td></tr>';
        return;
    }
    
    employees.forEach(emp => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${emp.name}</td>
            <td>${emp.rank}</td>
            <td>$${formatNumber(emp.salary)}</td>
            <td><span class="status-badge status-${emp.status}">${emp.status.replace('_', ' ')}</span></td>
            <td>${emp.total_flights || 0}</td>
            <td>
                <select class="rank-select" onchange="setEmployeeRank('${emp.identifier}', this.value)">
                    <option value="">Rang setzen...</option>
                    <option value="boss" ${emp.rank === 'boss' ? 'selected' : ''}>Boss</option>
                    <option value="assistant" ${emp.rank === 'assistant' ? 'selected' : ''}>Assistent</option>
                    <option value="pilot" ${emp.rank === 'pilot' ? 'selected' : ''}>Pilot</option>
                    <option value="junior_pilot" ${emp.rank === 'junior_pilot' ? 'selected' : ''}>Junior Pilot</option>
                    <option value="illegal" ${emp.rank === 'illegal' ? 'selected' : ''}>🚨 ILLEGAL</option>
                </select>
            </td>
            <td>
                <button class="btn btn-success" style="padding: 5px 10px; font-size: 11px; margin-right: 5px;" onclick="promoteEmployee('${emp.identifier}')">Befördern</button>
                <button class="btn btn-warning" style="padding: 5px 10px; font-size: 11px; margin-right: 5px;" onclick="demoteEmployee('${emp.identifier}')">Degradieren</button>
                <button class="btn btn-danger" style="padding: 5px 10px; font-size: 11px;" onclick="fireEmployee('${emp.identifier}')">Feuern</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

// NEW FUNCTION: Set Employee Rank directly
function setEmployeeRank(identifier, rank) {
    if (!rank) return;
    
    fetch(`https://${GetParentResourceName()}/setEmployeeRank`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier, rank })
    });
    
    setTimeout(() => fetchEmployees(), 500);
}

function showHireDialog() {
    fetch(`https://${GetParentResourceName()}/getNearbyPlayers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

async function displayNearbyPlayers(players) {
    if (!players || players.length === 0) {
        // NO MORE ALERT! Use custom dialog instead
        await showDialog(
            '⚠️ Keine Spieler',
            'Keine Spieler in der Nähe gefunden. Gehe näher an einen Spieler heran.',
            false
        );
        return;
    }
    
    let playerList = 'Wähle einen Spieler zum Einstellen:\n\n';
    players.forEach((player, index) => {
        playerList += `${index + 1}. ${player.name} ${player.isEmployee ? '(Bereits Mitarbeiter)' : ''}\n`;
    });
    
    const choice = await showDialog(
        '👥 Spieler einstellen',
        playerList + '\nBitte Nummer eingeben:',
        true
    );
    
    if (choice) {
        const index = parseInt(choice) - 1;
        if (index >= 0 && index < players.length && !players[index].isEmployee) {
            hireEmployee(players[index].source);
        }
    }
}

function hireEmployee(targetSource) {
    fetch(`https://${GetParentResourceName()}/hireEmployee`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetSource })
    });
    
    setTimeout(() => fetchEmployees(), 1000);
}

async function fireEmployee(identifier) {
    const confirmed = await showDialog(
        '⚠️ Mitarbeiter feuern',
        'Sind Sie sicher, dass Sie diesen Mitarbeiter feuern möchten?',
        false
    );
    
    if (confirmed) {
        fetch(`https://${GetParentResourceName()}/fireEmployee`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identifier })
        });
        
        setTimeout(() => fetchEmployees(), 1000);
    }
}

function promoteEmployee(identifier) {
    fetch(`https://${GetParentResourceName()}/promoteEmployee`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier })
    });
    
    setTimeout(() => fetchEmployees(), 1000);
}

function demoteEmployee(identifier) {
    fetch(`https://${GetParentResourceName()}/demoteEmployee`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identifier })
    });
    
    setTimeout(() => fetchEmployees(), 1000);
}

// Transaction Filter Variables
let currentTransactionFilter = 'all';
let allTransactions = [];

// Filter Transactions by Type
function filterTransactions(type) {
    currentTransactionFilter = type;
    
    // Update active button
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    // Re-display with filter
    displayTransactions(allTransactions);
}

// Vehicles
let vehiclesFetching = false;  // Prevent multiple simultaneous fetches

function fetchVehicles() {
    if (vehiclesFetching) {
        console.log('[Heli-Taxi] Already fetching vehicles, skipping...');
        return;
    }
    
    vehiclesFetching = true;
    
    const content = document.getElementById('vehicleManagementContent');
    if (content) {
        content.innerHTML = '<div class="loading">Lade Fahrzeuge...</div>';
    }
    
    fetch(`https://${GetParentResourceName()}/getVehicles`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function displayVehicles(vehicles) {
    const fleetGrid = document.getElementById('vehicleList');
    const managementContent = document.getElementById('vehicleManagementContent');
    
    const html = vehicles && vehicles.length > 0 ? 
        vehicles.map(veh => `
            <div class="vehicle-card">
                <div class="vehicle-header">
                    <div class="vehicle-name">${veh.model.toUpperCase()}</div>
                    <span class="status-badge status-${veh.status}">${veh.status.replace('_', ' ')}</span>
                </div>
                <div class="vehicle-info">
                    <div class="vehicle-info-item">
                        <span class="vehicle-info-label">Plate:</span>
                        <span class="vehicle-info-value">${veh.plate}</span>
                    </div>
                    <div class="vehicle-info-item">
                        <span class="vehicle-info-label">Condition:</span>
                        <span class="vehicle-info-value">${Math.floor(veh.condition)}%</span>
                    </div>
                    <div class="vehicle-info-item">
                        <span class="vehicle-info-label">Fuel:</span>
                        <span class="vehicle-info-value">${Math.floor(veh.fuel)}%</span>
                    </div>
                    <div class="vehicle-info-item">
                        <span class="vehicle-info-label">Flights:</span>
                        <span class="vehicle-info-value">${veh.total_flights || 0}</span>
                    </div>
                </div>
                ${veh.status === 'available' ? `
                    <div class="vehicle-actions">
                        <button class="btn btn-success" onclick="spawnVehicle('${veh.plate}', 1)">Landeplatz 1</button>
                        <button class="btn btn-success" onclick="spawnVehicle('${veh.plate}', 2)">Landeplatz 2</button>
                        <button class="btn btn-success" onclick="spawnVehicle('${veh.plate}', 3)">Landeplatz 3</button>
                    </div>
                ` : veh.status === 'in_use' ? `
                    <div class="vehicle-actions">
                        <button class="btn btn-primary" onclick="storeVehicle('${veh.plate}')">🏢 In Garage Lagern</button>
                    </div>
                ` : '<div style="text-align: center; color: #aaa; padding: 10px;">Fahrzeug im Einsatz</div>'}
            </div>
        `).join('') : '<div class="loading">Keine Fahrzeuge gefunden</div>';
    
    if (fleetGrid) fleetGrid.innerHTML = html;
    if (managementContent) managementContent.innerHTML = html;
}

function storeVehicle(plate) {
    fetch(`https://${GetParentResourceName()}/storeVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate })
    });
    
    setTimeout(() => fetchVehicles(), 1000);
}

function spawnVehicle(plate, helipadIndex) {
    fetch(`https://${GetParentResourceName()}/spawnVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate, helipadIndex })
    });
}

// Vehicle Shop
function openVehicleShop() {
    fetch(`https://${GetParentResourceName()}/getVehicleShop`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    
    document.getElementById('vehicleShop').style.display = 'flex';
}

function closeVehicleShop() {
    document.getElementById('vehicleShop').style.display = 'none';
}

function displayVehicleShop(shopData) {
    document.getElementById('shopBalance').textContent = '$' + formatNumber(shopData.balance);
    
    // Store vehicles globally for purchase function
    shopVehicles = shopData.vehicles || [];
    
    const grid = document.getElementById('shopVehicleGrid');
    
    const html = shopData.vehicles && shopData.vehicles.length > 0 ?
        shopData.vehicles.map(veh => `
            <div class="vehicle-card ${veh.owned ? 'owned' : ''}">
                <div class="vehicle-header">
                    <div class="vehicle-name">${veh.label}</div>
                    <div class="vehicle-price">$${formatNumber(veh.price)}</div>
                </div>
                <div class="vehicle-info">
                    <div class="vehicle-info-item">
                        <span class="vehicle-info-label">Category:</span>
                        <span class="vehicle-info-value">${veh.category.toUpperCase()}</span>
                    </div>
                    <div class="vehicle-info-item">
                        <span class="vehicle-info-label">Model:</span>
                        <span class="vehicle-info-value">${veh.model.toUpperCase()}</span>
                    </div>
                </div>
                <div class="vehicle-actions">
                    ${!veh.owned ? 
                        `<button class="btn btn-success" onclick="purchaseVehicle('${veh.model}')">Kaufen</button>` :
                        `<button class="btn" style="opacity: 0.5;" disabled>Im Besitz</button>`
                    }
                </div>
            </div>
        `).join('') : '<div class="loading">No vehicles available</div>';
    
    grid.innerHTML = html;
}

async function purchaseVehicle(model) {
    // Find vehicle info from shop vehicles
    const vehicle = shopVehicles.find(v => v.model === model);
    const label = vehicle ? vehicle.label : model;
    const price = vehicle ? vehicle.price : 0;
    
    const confirmed = await showDialog(
        '🛒 Fahrzeug kaufen',
        `Möchten Sie ${label} für $${formatNumber(price)} kaufen?`,
        false
    );
    
    if (confirmed) {
        fetch(`https://${GetParentResourceName()}/purchaseVehicle`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model })
        });
        
        setTimeout(() => {
            fetch(`https://${GetParentResourceName()}/getVehicleShop`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }, 1000);
    }
}

// Finances
function fetchFinances() {
    fetch(`https://${GetParentResourceName()}/getBalance`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
    
    fetch(`https://${GetParentResourceName()}/getTransactions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ limit: 50 })
    });
}

function displayBalance(balance) {
    document.getElementById('financeBalance').textContent = '$' + formatNumber(balance.balance);
    document.getElementById('totalIncome').textContent = '$' + formatNumber(balance.totalIncome);
    document.getElementById('totalExpenses').textContent = '$' + formatNumber(balance.totalExpenses);
}

function displayTransactions(transactions) {
    // Store all transactions for filtering
    if (transactions && transactions.length > 0) {
        allTransactions = transactions;
    }
    
    const tbody = document.getElementById('transactionTableBody');
    tbody.innerHTML = '';
    
    if (!transactions || transactions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="no-data">Keine Transaktionen gefunden</td></tr>';
        return;
    }
    
    // Filter transactions based on current filter
    let filteredTransactions = transactions;
    if (currentTransactionFilter === 'legal') {
        filteredTransactions = transactions.filter(tx => !tx.is_illegal);
    } else if (currentTransactionFilter === 'illegal') {
        filteredTransactions = transactions.filter(tx => tx.is_illegal);
    }
    
    if (filteredTransactions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="no-data">Keine Transaktionen in dieser Kategorie</td></tr>';
        return;
    }
    
    filteredTransactions.forEach(tx => {
        const row = document.createElement('tr');
        const date = new Date(tx.transaction_date);
        row.innerHTML = `
            <td>${date.toLocaleString()}</td>
            <td><span class="status-badge status-${tx.transaction_type}">${tx.transaction_type}</span></td>
            <td style="color: ${tx.transaction_type === 'income' ? '#00ff88' : '#ff3232'}">$${formatNumber(tx.amount)}</td>
            <td>${tx.description}</td>
        `;
        tbody.appendChild(row);
    });
}

async function showDepositDialog() {
    try {
        const amount = await showDialog(
            '💵 Geld einzahlen',
            'Wie viel möchten Sie einzahlen?',
            true
        );
        
        if (amount && !isNaN(amount) && parseInt(amount) > 0) {
            fetch(`https://${GetParentResourceName()}/depositMoney`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ amount: parseInt(amount) })
            }).catch(err => {
                console.error('[Heli-Taxi] Deposit error:', err);
            });
            
            setTimeout(() => fetchFinances(), 1000);
        }
    } catch (error) {
        console.error('[Heli-Taxi] Deposit dialog error:', error);
    }
}

async function showWithdrawDialog() {
    try {
        const amount = await showDialog(
            '💸 Geld abheben',
            'Wie viel möchten Sie abheben?',
            true
        );
        
        if (amount && !isNaN(amount) && parseInt(amount) > 0) {
            fetch(`https://${GetParentResourceName()}/withdrawMoney`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ amount: parseInt(amount) })
            }).catch(err => {
                console.error('[Heli-Taxi] Withdraw error:', err);
            });
            
            setTimeout(() => fetchFinances(), 1000);
        }
    } catch (error) {
        console.error('[Heli-Taxi] Withdraw dialog error:', error);
    }
}

// Settings
function loadSettings() {
    console.log('[Heli-Taxi] loadSettings() called');
    console.log('[Heli-Taxi] currentEmployee:', currentEmployee);
    
    // Fallback if currentEmployee not available
    const employee = currentEmployee || {};
    
    // Log what we're trying to set
    console.log('[Heli-Taxi] Setting employee ID:', employee.identifier || employee.id || '-');
    console.log('[Heli-Taxi] Setting employee rank:', employee.rank);
    console.log('[Heli-Taxi] Setting employee salary:', employee.salary);
    console.log('[Heli-Taxi] Setting employee flights:', employee.total_flights);
    
    // Safely display data with fallbacks
    const employeeIdEl = document.getElementById('employeeId');
    const employeeRankEl = document.getElementById('employeeRank');
    const employeeSalaryEl = document.getElementById('employeeSalary');
    const employeeFlightsEl = document.getElementById('employeeFlights');
    
    if (employeeIdEl) employeeIdEl.textContent = employee.identifier || employee.id || '-';
    if (employeeRankEl) employeeRankEl.textContent = getRankLabel(employee.rank) || employee.rank || '-';
    if (employeeSalaryEl) employeeSalaryEl.textContent = '$' + formatNumber(employee.salary || 0);
    if (employeeFlightsEl) employeeFlightsEl.textContent = employee.total_flights || 0;
    
    console.log('[Heli-Taxi] Settings loaded successfully');
    
    // Hide Secret Role & Security Clearance fields (no longer used)
    const secretRoleEl = document.getElementById('secretRoleSetting');
    const securityClearanceEl = document.getElementById('securityClearanceSetting');
    if (secretRoleEl) secretRoleEl.style.display = 'none';
    if (securityClearanceEl) securityClearanceEl.style.display = 'none';
}

// Translate rank IDs to readable German labels
function getRankLabel(rank) {
    const rankLabels = {
        'boss': 'Boss',
        'assistant': 'Assistent',
        'pilot': 'Pilot',
        'junior_pilot': 'Junior Pilot',
        'illegal': '🚨 ILLEGAL OPERATOR'
    };
    return rankLabels[rank] || rank;
}

// Wardrobe
function changeOutfit(outfitType) {
    fetch(`https://${GetParentResourceName()}/changeOutfit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ outfitType })
    });
    
    closeMenu();
}

// HUD
function showHUD(flatFee) {
    document.getElementById('flightHUD').style.display = 'block';
    document.getElementById('flightDuration').textContent = '00:00:00';
    document.getElementById('flightDistance').textContent = '0.00 km';
    document.getElementById('flightCost').textContent = '$' + formatNumber(flatFee);
    document.getElementById('fuelConsumed').textContent = '0.0 L';
}

function hideHUD() {
    document.getElementById('flightHUD').style.display = 'none';
}

function updateHUD(data) {
    document.getElementById('flightDuration').textContent = formatDuration(data.duration);
    document.getElementById('flightDistance').textContent = data.distance.toFixed(2) + ' km';
    document.getElementById('flightCost').textContent = '$' + formatNumber(data.cost);
    document.getElementById('fuelConsumed').textContent = data.fuelConsumed.toFixed(1) + ' L';
}

// Utility Functions
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDuration(seconds) {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    return `${hrs.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
}

// Custom Dialog System
function showDialog(title, message, showInput = false) {
    return new Promise((resolve) => {
        const dialog = document.getElementById('customDialog');
        const input = document.getElementById('dialogInput');
        const titleEl = document.getElementById('dialogTitle');
        const messageEl = document.getElementById('dialogMessage');
        const confirmBtn = document.getElementById('dialogConfirm');
        const cancelBtn = document.getElementById('dialogCancel');
        
        titleEl.textContent = title;
        messageEl.textContent = message;
        input.style.display = showInput ? 'block' : 'none';
        input.value = '';
        
        dialog.style.display = 'flex';
        
        if (showInput) {
            setTimeout(() => input.focus(), 100);
        }
        
        const confirm = () => {
            dialog.style.display = 'none';
            document.removeEventListener('keydown', keyHandler);
            confirmBtn.onclick = null;
            cancelBtn.onclick = null;
            resolve(showInput ? input.value : true);
        };
        
        const cancel = () => {
            dialog.style.display = 'none';
            document.removeEventListener('keydown', keyHandler);
            confirmBtn.onclick = null;
            cancelBtn.onclick = null;
            resolve(null);
        };
        
        const keyHandler = (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                confirm();
            } else if (e.key === 'Escape') {
                e.preventDefault();
                cancel();
            }
        };
        
        confirmBtn.onclick = confirm;
        cancelBtn.onclick = cancel;
        document.addEventListener('keydown', keyHandler);
    });
}

function GetParentResourceName() {
    // Try to get the FiveM global function first
    if (window.GetParentResourceName && typeof window.GetParentResourceName === 'function') {
        try {
            return window.GetParentResourceName();
        } catch (e) {
            // Fallback if error
        }
    }
    
    // Fallback for development/browser testing
    return 'Heli-Taxi';
}

// ======================================
// Calendar/Appointments Functions
// ======================================

let appointments = [];
let editingAppointmentId = null;

// Load appointments
function loadAppointments() {
    fetch(`https://${GetParentResourceName()}/getAppointments`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    }).then(response => response.json())
      .then(data => {
          appointments = data || [];
          renderAppointments();
      }).catch(() => {});
}

// Render appointments list
function renderAppointments() {
    const container = document.getElementById('appointmentsList');
    if (!container) return;
    
    if (appointments.length === 0) {
        container.innerHTML = '<div class="no-data">Keine Termine vorhanden</div>';
        return;
    }
    
    // Sort by date and time
    appointments.sort((a, b) => {
        const dateA = new Date(`${a.appointment_date} ${a.appointment_time}`);
        const dateB = new Date(`${b.appointment_date} ${b.appointment_time}`);
        return dateA - dateB;
    });
    
    const now = new Date();
    
    container.innerHTML = appointments.map(apt => {
        const aptDate = new Date(`${apt.appointment_date} ${apt.appointment_time}`);
        const isPast = aptDate < now;
        const dateStr = new Date(apt.appointment_date).toLocaleDateString('de-DE');
        
        return `
            <div class="appointment-card ${isPast ? 'past' : ''}">
                <div class="appointment-header">
                    <h4>${apt.title}</h4>
                    <span class="appointment-date">${dateStr} um ${apt.appointment_time.substring(0,5)}</span>
                </div>
                ${apt.description ? `<div class="appointment-description">${apt.description}</div>` : ''}
                <div class="appointment-actions">
                    <button class="btn-small btn-edit" onclick="editAppointment(${apt.id})">📝 Bearbeiten</button>
                    <button class="btn-small btn-delete" onclick="deleteAppointment(${apt.id})">🗑️ Löschen</button>
                </div>
            </div>
        `;
    }).join('');
}

// Create or update appointment
function createAppointment() {
    const title = document.getElementById('appointmentTitle').value.trim();
    const description = document.getElementById('appointmentDescription').value.trim();
    const date = document.getElementById('appointmentDate').value;
    const time = document.getElementById('appointmentTime').value;
    
    if (!title || !date || !time) {
        showDialog('Bitte füllen Sie alle Pflichtfelder aus', 'error');
        return;
    }
    
    const data = {
        title: title,
        description: description,
        date: date,
        time: time
    };
    
    if (editingAppointmentId) {
        // Update existing
        data.id = editingAppointmentId;
        fetch(`https://${GetParentResourceName()}/updateAppointment`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(data)
        }).then(() => {
            clearAppointmentForm();
            loadAppointments();
        });
    } else {
        // Create new
        fetch(`https://${GetParentResourceName()}/createAppointment`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify(data)
        }).then(() => {
            clearAppointmentForm();
            loadAppointments();
        });
    }
}

// Edit appointment
function editAppointment(id) {
    const apt = appointments.find(a => a.id === id);
    if (!apt) return;
    
    document.getElementById('appointmentTitle').value = apt.title;
    document.getElementById('appointmentDescription').value = apt.description || '';
    document.getElementById('appointmentDate').value = apt.appointment_date;
    document.getElementById('appointmentTime').value = apt.appointment_time.substring(0,5);
    
    editingAppointmentId = id;
    document.getElementById('createAppointmentBtn').innerHTML = '<span>💾 Speichern</span>';
    document.getElementById('cancelEditBtn').style.display = 'inline-block';
}

// Cancel edit
function cancelEditAppointment() {
    clearAppointmentForm();
}

// Clear form
function clearAppointmentForm() {
    document.getElementById('appointmentTitle').value = '';
    document.getElementById('appointmentDescription').value = '';
    document.getElementById('appointmentDate').value = '';
    document.getElementById('appointmentTime').value = '';
    editingAppointmentId = null;
    document.getElementById('createAppointmentBtn').innerHTML = '<span>📅 Termin Erstellen</span>';
    document.getElementById('cancelEditBtn').style.display = 'none';
}

// Delete appointment
function deleteAppointment(id) {
    showCustomDialog(
        'Termin löschen?',
        'Möchten Sie diesen Termin wirklich löschen?',
        (confirmed) => {
            if (confirmed) {
                fetch(`https://${GetParentResourceName()}/deleteAppointment`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({ id: id })
                }).then(() => {
                    loadAppointments();
                });
            }
        }
    );
}

// Receive appointments from server
window.addEventListener('message', (event) => {
    if (event.data.type === 'receiveAppointments') {
        appointments = event.data.appointments || [];
        renderAppointments();
    }
});

// ========================================
// PASSENGER TAXI SYSTEM
// ========================================

let currentPilotId = null;

// Show passenger dialog
function showPassengerDialog(data) {
    currentPilotId = data.pilotId;
    document.getElementById('pilotName').textContent = data.pilotName;
    document.getElementById('flatFeeDisplay').textContent = '$' + data.flatFee.toLocaleString();
    document.getElementById('pricePerKmDisplay').textContent = '$' + data.pricePerKm.toLocaleString();
    document.getElementById('passengerDialog').style.display = 'flex';
}

// Accept taxi ride
function acceptTaxiRide() {
    fetch(`https://${GetParentResourceName()}/acceptTaxi`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ pilotId: currentPilotId })
    });
    document.getElementById('passengerDialog').style.display = 'none';
    currentPilotId = null;
}

// Decline taxi ride
function declineTaxiRide() {
    fetch(`https://${GetParentResourceName()}/declineTaxi`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ pilotId: currentPilotId })
    });
    document.getElementById('passengerDialog').style.display = 'none';
    currentPilotId = null;
}

// Show taxi HUD
function showTaxiHud(data) {
    document.getElementById('taxiFlatFee').textContent = '$' + data.flatFee.toLocaleString();
    document.getElementById('taxiHUD').style.display = 'block';
}

// End taxi ride (manual button)
function endTaxiRide() {
    fetch(`https://${GetParentResourceName()}/endTaxiRide`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// Update taxi HUD
function updateTaxiHud(data) {
    // Format duration
    const minutes = Math.floor(data.duration / 60);
    const seconds = Math.floor(data.duration % 60);
    const durationText = minutes.toString().padStart(2, '0') + ':' + seconds.toString().padStart(2, '0');
    
    document.getElementById('taxiDuration').textContent = durationText;
    document.getElementById('taxiDistance').textContent = data.distance.toFixed(2) + ' km';
    document.getElementById('taxiFlatFee').textContent = '$' + data.flatFee.toLocaleString();
    document.getElementById('taxiDistanceCost').textContent = '$' + Math.round(data.distanceCost).toLocaleString();
    document.getElementById('taxiTimeCost').textContent = '$' + Math.round(data.timeCost || 0).toLocaleString();
    document.getElementById('taxiTotalCost').textContent = '$' + Math.round(data.totalCost).toLocaleString();
}

// Hide taxi HUD
function hideTaxiHud() {
    document.getElementById('taxiHUD').style.display = 'none';
}

// Show invoice
function showInvoice(invoice) {
    
    // Format duration
    const minutes = Math.floor(invoice.duration / 60);
    const seconds = Math.floor(invoice.duration % 60);
    const durationText = minutes.toString().padStart(2, '0') + ':' + seconds.toString().padStart(2, '0');
    
    document.getElementById('invoiceDistance').textContent = invoice.distance.toFixed(2) + ' km';
    document.getElementById('invoiceDuration').textContent = durationText;
    document.getElementById('invoiceFlatFee').textContent = '$' + invoice.flatFee.toLocaleString();
    document.getElementById('invoiceDistanceCost').textContent = '$' + Math.round(invoice.distanceCost).toLocaleString();
    document.getElementById('invoiceTotalCost').textContent = '$' + Math.round(invoice.totalCost).toLocaleString();
    document.getElementById('invoiceBalance').textContent = '$' + invoice.passengerBalance.toLocaleString();
    
    // Add debt indicator if needed
    const balanceElement = document.getElementById('invoiceBalance');
    if (invoice.isInDebt) {
        balanceElement.style.color = '#ff4444';
        balanceElement.style.fontWeight = '700';
    } else {
        balanceElement.style.color = 'white';
    }
    
    document.getElementById('invoiceDialog').style.display = 'flex';
}

// Close invoice
function closeInvoice() {
    fetch(`https://${GetParentResourceName()}/closeInvoice`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
    document.getElementById('invoiceDialog').style.display = 'none';
}

// Add passenger handlers to message event listener
const originalMessageHandler = window.onmessage;
window.addEventListener('message', (event) => {
    const data = event.data;
    
    // Forward showExclusiveMissions to iframe
    if (data.action === 'showExclusiveMissions') {
        const iframe = document.getElementById('exclusiveMissionsFrame');
        if (iframe) {
            iframe.style.display = 'block';
            iframe.contentWindow.postMessage(data, '*');
        }
    }
    // Hide exclusive missions iframe
    else if (data.action === 'hideExclusiveMissions') {
        const iframe = document.getElementById('exclusiveMissionsFrame');
        if (iframe) {
            iframe.style.display = 'none';
        }
    }
    else if (data.action === 'showPassengerDialog') {
        showPassengerDialog(data.data);
    } else if (data.action === 'showTaxiHud') {
        showTaxiHud(data.data);
    } else if (data.action === 'updateTaxiHud') {
        updateTaxiHud(data.data);
    } else if (data.action === 'hideTaxiHud') {
        hideTaxiHud();
    } else if (data.action === 'showInvoice') {
        showInvoice(data.invoice);
    } else if (data.action === 'hideInvoice') {
        // Hide invoice dialog
        const invoiceDialog = document.getElementById('invoiceDialog');
        if (invoiceDialog) {
            invoiceDialog.style.display = 'none';
        }
    }
});

