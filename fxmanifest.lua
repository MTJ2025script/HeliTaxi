fx_version 'cerulean'
game 'gta5'

author 'Heli-Taxi Development'
description 'Professionelles Hubschrauber Taxi Business System mit Illegal Operations'
version '2.1.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'locales/de.lua',
    'locales/en.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/main.lua',
    'server/employees.lua',
    'server/vehicles.lua',
    'server/flights.lua',
    'server/banking.lua',
    'server/operating_costs.lua',
    'server/passenger.lua',
    'server/phone.lua',
    'server/calendar.lua',
    'server/standalone_phone.lua'
}

client_scripts {
    'client/framework.lua',
    'client/main.lua',
    'client/menu.lua',
    'client/hud.lua',
    'client/vehicles.lua',
    'client/flight.lua',
    'client/operating_costs.lua',
    'client/passenger.lua',
    'client/phone.lua',
    'client/standalone_phone.lua',
    'client/illegal_locations.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/illegal.html',
    'html/illegal.css',
    'html/illegal.js',
    'html/phone.html',
    'html/phone-style.css',
    'html/phone-script.js',
    'html/booking.html',
    'html/booking-style.css',
    'html/booking-script.js',
    'html/img/*'
}

dependencies {
    'oxmysql'
}
