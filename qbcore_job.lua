-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- INSTALLATION FÜR QB-CORE
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- 
-- 1. Öffne die Datei: qb-core/shared/jobs.lua
-- 2. Füge den folgenden Code INNERHALB der QBShared.Jobs Tabelle ein:
-- 3. Speichern und QB-Core neu starten
--
-- BEISPIEL WO EINFÜGEN:
-- QBShared.Jobs = {
--     ['police'] = { ... },
--     ['ambulance'] = { ... },
--     ['helitaxi'] = { ... },  <-- HIER EINFÜGEN
-- }
--
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

['helitaxi'] = {
    label = 'Heli-Taxi',
    defaultDuty = false,
    offDutyPay = false,
    grades = {
        ['0'] = {
            name = 'Junior Pilot',
            payment = 1500
        },
        ['1'] = {
            name = 'Pilot',
            payment = 2500
        },
        ['2'] = {
            name = 'Assistent',
            payment = 3500
        },
        ['3'] = {
            name = 'Boss',
            payment = 5000,
            isboss = true,
        },
        ['4'] = {
            name = 'illegal',
            payment = 4000
        },
    },
},

-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- WICHTIG: Vergiss nicht das Komma am Ende!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--
-- SPIELER JOB ZUWEISEN:
-- /setjob [ID] helitaxi [grade]
--
-- Grades:
-- 0 = Junior Pilot
-- 1 = Pilot
-- 2 = Assistent
-- 3 = Boss
-- 4 = Illegal (Zugang zu illegalen Operationen)
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

