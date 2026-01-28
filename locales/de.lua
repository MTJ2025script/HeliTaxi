Locales = Locales or {}

Locales['de'] = {
    -- Allgemeine Benachrichtigungen
    ['not_employee'] = 'Du bist kein Mitarbeiter',
    ['not_on_duty'] = 'Du musst im Dienst sein',
    ['must_be_on_duty'] = 'Du musst im Dienst sein, um Fahrzeuge zu spawnen',
    ['now_on_duty'] = 'Du bist jetzt im Dienst',
    ['now_off_duty'] = 'Du bist jetzt nicht mehr im Dienst',
    
    -- Boss Menü
    ['open_boss_menu'] = '~y~📋 ~w~Boss Menü ~b~[E]',
    ['open_wardrobe'] = '~g~👔 ~w~Garderobe ~b~[E]',
    ['open_vehicle_management'] = '~o~🚁 ~w~Fahrzeugverwaltung ~b~[E]',
    ['toggle_duty'] = '~b~💼 ~w~Im Dienst ~b~[E]',
    ['open_vehicle_shop'] = '~r~🛒 ~w~Fahrzeug Shop ~b~[E]',
    
    -- Mitarbeiter
    ['hired'] = 'Du hast %s als %s eingestellt',
    ['you_were_hired'] = 'Du wurdest von Heli-Taxi als %s eingestellt',
    ['fired'] = 'Du hast %s gefeuert',
    ['you_were_fired'] = 'Du wurdest von Heli-Taxi gefeuert',
    ['promoted'] = 'Du hast %s zu %s befördert',
    ['you_were_promoted'] = 'Du wurdest zu %s befördert',
    ['demoted'] = 'Du hast %s zu %s degradiert',
    ['you_were_demoted'] = 'Du wurdest zu %s degradiert',
    ['already_employee'] = 'Diese Person ist bereits ein Mitarbeiter',
    ['not_an_employee'] = 'Diese Person ist kein Mitarbeiter',
    ['no_permission'] = 'Du hast keine Berechtigung dafür',
    ['highest_rank'] = 'Mitarbeiter hat bereits den höchsten Rang',
    ['lowest_rank'] = 'Mitarbeiter hat bereits den niedrigsten Rang',
    
    -- Fahrzeuge
    ['vehicle_spawned'] = 'Fahrzeug gespawnt bei %s',
    ['vehicle_returned'] = 'Fahrzeug erfolgreich zurückgegeben',
    ['vehicle_in_use'] = 'Fahrzeug nicht verfügbar',
    ['already_have_vehicle'] = 'Du hast bereits ein Fahrzeug gespawnt',
    ['invalid_helipad'] = 'Ungültiger Landeplatz',
    ['no_vehicle_to_return'] = 'Kein aktives Fahrzeug zum Zurückgeben',
    ['must_be_near_helipad'] = 'Du musst in der Nähe eines Landeplatzes sein, um das Fahrzeug zurückzugeben',
    ['model_load_failed'] = 'Fahrzeugmodell konnte nicht geladen werden',
    
    -- Flüge
    ['flight_started'] = 'Flug gestartet - Grundgebühr: $%s',
    ['flight_completed'] = 'Flug abgeschlossen! Distanz: %.2f km, Dauer: %ds, Verdient: $%d',
    ['flight_cancelled'] = 'Flug abgebrochen',
    ['no_active_flight'] = 'Kein aktiver Flug gefunden',
    
    -- Finanzen
    ['purchased_vehicle'] = '%s erfolgreich für $%s gekauft',
    ['insufficient_funds'] = 'Unzureichendes Firmenguthaben. Benötigt: $%s, Verfügbar: $%s',
    ['vehicle_already_owned'] = 'Dieses Fahrzeug ist bereits in deiner Flotte',
    ['deposited'] = '$%s erfolgreich auf das Firmenkonto eingezahlt',
    ['withdrawn'] = '$%s erfolgreich vom Firmenkonto abgehoben',
    ['invalid_amount'] = 'Ungültiger Betrag',
    ['not_enough_money'] = 'Du hast nicht genug Geld',
    ['only_boss_withdraw'] = 'Nur der Boss kann Geld abheben',
    ['transaction_failed'] = 'Transaktion fehlgeschlagen',
    ['error_accessing_account'] = 'Fehler beim Zugriff auf das Firmenkonto',
    
    -- Gehalt
    ['received_salary'] = 'Du hast dein Gehalt erhalten: $%s',
    ['insufficient_company_funds'] = 'Unzureichendes Firmenguthaben für Gehaltszahlung',
    
    -- Outfit
    ['pilot_uniform_equipped'] = '✈️ Pilotenuniform ausgerüstet',
    ['civilian_clothes_equipped'] = '👔 Zivilkleidung ausgerüstet',
    
    -- NEU: Spawn-Gebühr
    ['spawn_fee_charged'] = '🚁 Helikopter gespawnt - Bereitstellungsgebühr $%s abgebucht',
    ['spawn_fee_insufficient'] = 'Nicht genug Geld in Firmenkasse für Spawn-Gebühr (Benötigt: $%s)',
    ['company_debt_limit'] = '⚠️ Firmenkasse hat Kreditlimit erreicht! (Max. Schulden: $%s)',
    
    -- NEU: Betriebskosten
    ['operating_cost_requested'] = '💼 Betriebskosten-Anfrage gesendet: $%s',
    ['new_cost_request'] = '💰 Neue Betriebskosten-Anfrage von %s: $%s',
    ['operating_cost_approved'] = '✅ Betriebskosten genehmigt: $%s erhalten',
    ['operating_cost_declined'] = '❌ Deine Betriebskosten-Anfrage wurde abgelehnt',
    ['cost_request_approved'] = '✅ Betriebskosten für %s genehmigt: $%s überwiesen',
    ['cost_request_declined'] = '❌ Betriebskosten-Anfrage von %s abgelehnt',
    ['request_not_found'] = 'Anfrage nicht gefunden',
    ['invalid_request'] = 'Ungültige Anfrage',
    
    -- NEU: Passagier-Taxi
    ['passenger_notified'] = '📱 Passagier-Anfrage gesendet',
    ['pilot_not_found'] = 'Pilot nicht gefunden',
    ['taxi_accepted'] = '✅ Taxi gebucht - Grundgebühr $%s abgebucht',
    ['taxi_accepted_debt'] = '✅ Taxi gebucht - Grundgebühr $%s abgebucht (Dein Kontostand: $%s)',
    ['taxi_declined'] = 'ℹ️ Verstanden - Genieße den privaten Flug!',
    ['passenger_accepted_taxi'] = '✅ %s hat Taxi gebucht - Flug aktiv',
    ['passenger_declined_taxi'] = '❌ %s hat Taxi abgelehnt',
    ['ride_ended'] = '✈️ Flug beendet - Rechnung: $%s bezahlt',
    ['ride_ended_debt'] = '✈️ Flug beendet - Rechnung: $%s bezahlt (Kontostand: $%s)',
    ['ride_payment_received'] = '💰 Taxi-Einnahme: $%s → Firmenkasse',
    
    -- Ränge
    ['boss'] = 'Boss',
    ['assistant'] = 'Assistent',
    ['pilot'] = 'Pilot',
    ['junior_pilot'] = 'Junior Pilot',
}
