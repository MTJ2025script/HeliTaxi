# HeliTaxi
Helicopter Transport System for FiveM

## Description
A clean and legal helicopter taxi service for FiveM servers. Players can call a helicopter taxi to travel between legal locations.

## Features
- ✅ Legal helicopter taxi service
- ✅ NPC pilot with proper AI navigation
- ✅ Multiple destination locations
- ✅ Clean markers and blips
- ✅ No illegal activities or markers
- ✅ Proper cleanup on resource stop
- ✅ Boss/Management UI system
- ✅ Permission-based access control

## Installation
1. Download the resource
2. Place the `HeliTaxi` folder in your server's `resources` folder
3. Add `ensure HeliTaxi` to your `server.cfg`
4. Restart your server

## Usage

### Taxi Service
1. Go to the Helicopter Taxi location (marked on map with helicopter icon)
2. Press `E` when near the marker
3. Select your destination
4. Get in the helicopter
5. The NPC pilot will fly you to your destination

### Management Menu
1. Go to the HeliTaxi Management location (blue briefcase icon on map)
2. Press `E` when near the marker to open the management interface
3. Or use the command: `/helitaximenu`

The management menu includes:
- **Dashboard**: Overview of operations (flights, revenue, employees)
- **Fleet**: Manage helicopter fleet
- **Employees**: View online employees
- **Finances**: Financial reports

## Configuration
Edit `config.lua` to customize:
- Taxi locations (all legal locations)
- Helicopter spawn point
- Helicopter model
- Marker colors and blips
- Prices (if using ESX)

## Requirements
- FiveM server
- No additional dependencies required (standalone)
- Optional: ESX for payment system and job ranks

## Commands
- `/helitaximenu` - Open the management interface

## Fixed Issues
- ✅ NPC navigation now works properly
- ✅ Removed all illegal markers and interactions
- ✅ Script runs cleanly without errors
- ✅ Proper cleanup of entities
- ✅ Fixed black UI screen issue
- ✅ Fixed "no access" permission errors
- ✅ Properly handles "illegal" boss menu calls (converts to legal menu)
- ✅ Rank system properly integrated

## License
Free to use and modify
