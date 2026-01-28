Locales = Locales or {}

Locales['en'] = {
    -- General notifications
    ['not_employee'] = 'You are not an employee',
    ['not_on_duty'] = 'You must be on duty',
    ['must_be_on_duty'] = 'You must be on duty to spawn vehicles',
    ['now_on_duty'] = 'You are now on duty',
    ['now_off_duty'] = 'You are now off duty',
    
    -- Boss Menu
    ['open_boss_menu'] = 'Press [E] to open Boss Menu',
    ['open_wardrobe'] = 'Press [E] to open Wardrobe',
    ['open_vehicle_management'] = 'Press [E] to access Vehicle Management',
    
    -- Employees
    ['hired'] = 'You hired %s as %s',
    ['you_were_hired'] = 'You have been hired by Heli-Taxi as %s',
    ['fired'] = 'You fired %s',
    ['you_were_fired'] = 'You have been fired from Heli-Taxi',
    ['promoted'] = 'You promoted %s to %s',
    ['you_were_promoted'] = 'You have been promoted to %s',
    ['demoted'] = 'You demoted %s to %s',
    ['you_were_demoted'] = 'You have been demoted to %s',
    ['already_employee'] = 'This person is already an employee',
    ['not_an_employee'] = 'This person is not an employee',
    ['no_permission'] = 'You do not have permission',
    ['highest_rank'] = 'Employee is already at highest rank',
    ['lowest_rank'] = 'Employee is already at lowest rank',
    
    -- Vehicles
    ['vehicle_spawned'] = 'Vehicle spawned at %s',
    ['vehicle_returned'] = 'Vehicle returned successfully',
    ['vehicle_in_use'] = 'Vehicle not available',
    ['already_have_vehicle'] = 'You already have a vehicle spawned',
    ['invalid_helipad'] = 'Invalid helipad',
    ['no_vehicle_to_return'] = 'No active vehicle to return',
    ['must_be_near_helipad'] = 'You must be near a helipad to return the vehicle',
    ['model_load_failed'] = 'Failed to load vehicle model',
    
    -- Flights
    ['flight_started'] = 'Flight started - Flat fee: $%s',
    ['flight_completed'] = 'Flight completed! Distance: %.2f km, Duration: %ds, Earned: $%d',
    ['flight_cancelled'] = 'Flight cancelled',
    ['no_active_flight'] = 'No active flight found',
    
    -- Finances
    ['purchased_vehicle'] = 'Successfully purchased %s for $%s',
    ['insufficient_funds'] = 'Insufficient company funds. Need: $%s, Have: $%s',
    ['vehicle_already_owned'] = 'This vehicle is already in your fleet',
    ['deposited'] = 'Successfully deposited $%s to company account',
    ['withdrawn'] = 'Successfully withdrew $%s from company account',
    ['invalid_amount'] = 'Invalid amount',
    ['not_enough_money'] = 'You do not have enough money',
    ['only_boss_withdraw'] = 'Only the boss can withdraw money',
    ['transaction_failed'] = 'Transaction failed',
    ['error_accessing_account'] = 'Error accessing company account',
    
    -- Salary
    ['received_salary'] = 'You received your salary: $%s',
    ['insufficient_company_funds'] = 'Insufficient company funds to pay salary',
    
    -- Outfit
    ['pilot_uniform_equipped'] = 'Pilot uniform equipped',
    ['civilian_clothes_equipped'] = 'Civilian clothes equipped',
    
    -- Ranks
    ['boss'] = 'Boss',
    ['assistant'] = 'Assistant',
    ['pilot'] = 'Pilot',
    ['junior_pilot'] = 'Junior Pilot',
}
