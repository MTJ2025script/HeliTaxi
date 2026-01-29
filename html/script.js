// HeliTaxi Management UI Script
const app = document.getElementById('app');
const closeBtn = document.getElementById('close-btn');
const tabs = document.querySelectorAll('.tab');
const tabContents = document.querySelectorAll('.tab-content');
const permissionError = document.getElementById('permission-error');

let currentData = null;
let hasPermission = true;

// Debug logging (matches the format from error logs)
function log(message) {
    console.log(`[HeliTaxi-UI] ${message}`);
}

// Initialize UI
function init() {
    log('UI Script initialized');
    
    // Close button handler
    closeBtn.addEventListener('click', closeMenu);
    
    // Tab switching
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const tabName = tab.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
    
    // ESC key to close
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeMenu();
        }
    });
}

// Switch between tabs
function switchTab(tabName) {
    log(`Switching to tab: ${tabName}`);
    
    // Update tab buttons
    tabs.forEach(tab => {
        if (tab.getAttribute('data-tab') === tabName) {
            tab.classList.add('active');
        } else {
            tab.classList.remove('active');
        }
    });
    
    // Update tab content
    tabContents.forEach(content => {
        if (content.id === tabName) {
            content.classList.add('active');
        } else {
            content.classList.remove('active');
        }
    });
    
    // Load content based on tab
    loadTabContent(tabName);
}

// Load content for specific tab
function loadTabContent(tabName) {
    log(`Loading content for tab: ${tabName}`);
    
    switch(tabName) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'fleet':
            loadFleet();
            break;
        case 'employees':
            loadEmployees();
            break;
        case 'finances':
            loadFinances();
            break;
    }
}

// Load dashboard data
function loadDashboard() {
    log('Loading dashboard');
    if (currentData && currentData.stats) {
        document.getElementById('total-flights').textContent = currentData.stats.flights || 0;
        document.getElementById('active-helicopters').textContent = currentData.stats.helicopters || 0;
        document.getElementById('total-revenue').textContent = '$' + (currentData.stats.revenue || 0);
        document.getElementById('employees-online').textContent = currentData.stats.employees || 0;
    }
}

// Load fleet data
function loadFleet() {
    log('Loading fleet');
    const fleetList = document.getElementById('fleet-list');
    
    if (currentData && currentData.fleet && currentData.fleet.length > 0) {
        fleetList.innerHTML = '';
        currentData.fleet.forEach(vehicle => {
            const item = document.createElement('div');
            item.className = 'fleet-item';
            item.innerHTML = `
                <div class="fleet-name">${vehicle.name || 'Unknown'}</div>
                <div class="fleet-status status-${vehicle.status || 'available'}">${vehicle.status || 'Available'}</div>
                <div class="fleet-location">${vehicle.location || 'Unknown Location'}</div>
            `;
            fleetList.appendChild(item);
        });
    }
}

// Load employees data
function loadEmployees() {
    log('Loading employees');
    const employeeList = document.getElementById('employee-list');
    
    if (currentData && currentData.employees && currentData.employees.length > 0) {
        employeeList.innerHTML = '';
        currentData.employees.forEach(employee => {
            const item = document.createElement('div');
            item.className = 'fleet-item'; // Reuse styling
            item.innerHTML = `
                <div class="fleet-name">${employee.name || 'Unknown'}</div>
                <div class="fleet-status status-available">${employee.rank || 'Employee'}</div>
                <div class="fleet-location">Online</div>
            `;
            employeeList.appendChild(item);
        });
    } else {
        employeeList.innerHTML = '<p class="no-data">No employees online</p>';
    }
}

// Load finances data
function loadFinances() {
    log('Loading finances');
    if (currentData && currentData.finances) {
        document.getElementById('today-income').textContent = '$' + (currentData.finances.today || 0);
        document.getElementById('week-income').textContent = '$' + (currentData.finances.week || 0);
        document.getElementById('month-income').textContent = '$' + (currentData.finances.month || 0);
    }
}

// Open the boss menu
function openBossMenu(data) {
    log('Opening Boss Menu with data: ' + JSON.stringify(data));
    
    currentData = data || {};
    
    // Check permissions
    if (data && data.hasPermission === false) {
        log('Permission denied - showing error message');
        hasPermission = false;
        permissionError.classList.remove('hidden');
        app.classList.remove('hidden');
        document.querySelector('.container').style.display = 'none';
        return;
    }
    
    hasPermission = true;
    permissionError.classList.add('hidden');
    document.querySelector('.container').style.display = 'flex';
    
    // Show UI
    app.classList.remove('hidden');
    log('UI enabled');
    
    // Set focus to allow closing with ESC
    SetNuiFocus(true, true);
    
    // Load initial tab
    switchTab('dashboard');
}

// Handle legacy "illegal" boss menu calls
function openIllegalBossMenu(data) {
    log('Received action: openIllegalBossMenu (legacy call)');
    log('Converting to legal boss menu');
    // Convert illegal boss menu to legal boss menu
    openBossMenu(data);
}

// Close the menu
function closeMenu() {
    log('Closing menu');
    app.classList.add('hidden');
    permissionError.classList.add('hidden');
    
    // Remove focus
    SetNuiFocus(false, false);
    
    // Notify client
    fetch('https://heli-taxi/close', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Set NUI Focus (FiveM specific)
function SetNuiFocus(hasFocus, hasCursor) {
    fetch(`https://heli-taxi/setFocus`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            focus: hasFocus,
            cursor: hasCursor
        })
    });
}

// Listen for messages from Lua
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (!data || !data.action) {
        return;
    }
    
    log(`Received action: ${data.action}`);
    
    switch(data.action) {
        case 'openBossMenu':
        case 'openManagementMenu':
            openBossMenu(data.data);
            break;
        case 'openIllegalBossMenu':
            // Handle legacy illegal boss menu calls
            openIllegalBossMenu(data.data);
            break;
        case 'close':
        case 'closeMenu':
            closeMenu();
            break;
        case 'updateData':
            if (data.data) {
                currentData = data.data;
                loadTabContent(document.querySelector('.tab.active').getAttribute('data-tab'));
            }
            break;
        default:
            log(`Unknown action: ${data.action}`);
    }
});

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

log('Script loaded successfully');
