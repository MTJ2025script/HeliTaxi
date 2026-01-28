

Config = {}

--[[
    ============================================================================
    GLOBAL GRUNDEINSTELLUNGEN / BASIC SETTINGS
    ============================================================================
]]

-- Sprache der Benutzeroberfläche
-- 'de' = Deutsch, 'en' = English
Config.Locale = 'de'

-- Framework Auswahl
-- 'auto' = Automatische Erkennung (empfohlen)
-- 'esx' = ESX Framework
-- 'qb-core' = QB-Core Framework
-- 'standalone' = Ohne Framework (eigene Mitarbeiterverwaltung)
Config.Framework = 'auto'

-- Ox Inventory Support (falls verwendet)
Config.UseOxInventory = false

-- Job Name für ESX/QB-Core Integration
-- WICHTIG: Muss mit dem Job Namen in deinem Framework übereinstimmen!
-- Siehe: qbcore_job.lua oder esx_job.sql
Config.JobName = 'helitaxi'

-- Debug Modus (zeigt zusätzliche Informationen in der Konsole)
Config.Debug = false

--[[
    ============================================================================
    DUTY DIENST-SYSTEM / DUTY SYSTEM
    ============================================================================
    
    EINSTELLUNGEN FÜR DAS IM-DIENST-SYSTEM
    
    HINWEIS: Bei Nutzung von ESX/QB-Core Framework wird das Framework-Duty-System
    automatisch verwendet! Diese Einstellungen gelten nur für Standalone Modus.
]]

Config.DutySystem = {
    -- Duty-Check für Fahrzeug-Spawn
    -- true = Nur im Dienst kann gespawnt werden (empfohlen!)
    -- false = Immer spawnen erlaubt
    requireDutyForSpawn = false,        -- Bei QB-Core/ESX nicht nötig (anpassbar!)
    
    -- Duty-Check für Gehaltszahlung
    -- true = Nur im Dienst wird Gehalt gezahlt (empfohlen!)
    -- false = Immer Gehalt zahlen
    requireDutyForSalary = true,        -- Standardmäßig aktiv (anpassbar!)
    
    -- Duty-Check für Boss-Menü
    -- true = Nur im Dienst kann Boss-Menü geöffnet werden
    -- false = Immer Boss-Menü erlauben
    requireDutyForMenu = false,         -- Meistens nicht nötig (anpassbar!)
    
    -- Automatischer Dienst-Status beim Job-Start
    -- true = Beim Einloggen automatisch im Dienst
    -- false = Muss /duty nutzen um in Dienst zu gehen
    autoDutyOnLogin = false             -- Spieler müssen /duty nutzen (anpassbar!)
}

--[[
    ============================================================================
    UI UI HINTERGRUND / UI BACKGROUND
    ============================================================================
    
    VOLLBILD-HINTERGRUND FÜR ALLE BENUTZEROBERFLÄCHEN
    
    WICHTIG: Deine Bilder müssen im Ordner html/img/ liegen!
    Beispiel: html/img/background.png
]]

Config.UIBackground = {
    -- Hintergrund-Bild aktivieren/deaktivieren
    -- true = Hintergrund aktiv
    -- false = Kein Hintergrund (nur Glassmorphism)
    enabled = true,
    
    -- Bild-Dateiname (muss im Ordner html/img/ liegen!)
    -- Beispiele: 'background.png', 'backdrop.jpg', 'heli_bg.png'
    -- ANLEITUNG: 
    -- 1. Erstelle Ordner: html/img/
    -- 2. Kopiere dein Bild dort rein
    -- 3. Trage den Dateinamen hier ein
    image = 'background.png',
    
    -- Sichtbarkeit (0-100)
    -- 0 = Komplett unsichtbar
    -- 85 = 85% SICHTBAR (EMPFOHLEN! - Gute Balance zwischen Bild und UI)
    -- 100 = 100% sichtbar (kein Transparenz)
    -- WICHTIG: Höhere Werte = MEHR sichtbar!
    opacity = 85,
    
    -- Blur-Effekt aktivieren
    -- true = Bild wird leicht verwischt (weicherer Look)
    -- false = Scharfes Bild
    blur = true,
    
    -- Blur-Stärke in Pixel (nur wenn blur = true)
    -- 5 = Leichter Blur (empfohlen!)
    -- 10 = Mittlerer Blur
    -- 20 = Starker Blur
    blurStrength = 5
}

--[[
    ============================================================================
    COMPANY FIRMEN EINSTELLUNGEN / COMPANY SETTINGS
    ============================================================================
]]

-- Name der Firma (wird in Benachrichtigungen angezeigt)
Config.CompanyName = 'Heli-Taxi'

-- Startkapital der Firma (beim ersten Start)
Config.StartingBalance = 50000

-- Blip Einstellungen für die Karte
Config.ShowBlips = true
Config.CompanyBlip = {
    sprite = 43,        -- Icon Typ (43 = Hubschrauber)
    color = 3,          -- Farbe (3 = Hellblau)
    scale = 0.8,        -- Größe
    label = 'Heli-Taxi HQ'  -- Name auf der Karte
}

--[[
    ============================================================================
    LOCATION STANDORTE / LOCATIONS
    ============================================================================
    
    ANLEITUNG: Koordinaten anpassen
    - Nutze /save [name] im Spiel um deine Position zu speichern
    - vector3(x, y, z) = Position ohne Rotation
    - vector4(x, y, z, heading) = Position mit Blickrichtung
]]

Config.Locations = {
    -- Boss Menü (MARKER)
    BossMenu = vector3(-126.0284, -641.1374, 168.8204),
    
    -- Garderobe (MARKER)
    Wardrobe = vector3(-130.9768, -633.5480, 168.8204),
    
    -- Duty Toggle (NPC)
    DutyToggle = vector4(-139.2165, -633.9833, 168.8204, 354.6650),
    
    -- Fahrzeugverwaltung (NPC)
    VehicleManagement = vector4(-727.0356, -1499.9502, 5.0005, 335.2927),
    
    -- Fahrzeug Shop (MARKER)
    VehicleShop = vector3(-145.7871, -635.7437, 168.8204),
    
    -- Hauptstandort HQ (für Blip)
    HQ = vector3(-734.9818, -1483.6512, 5.0005),
    
    -- Duty Toggle NPC Konfiguration (Schöne Frau!)
    DutyNPC = {
        model = 'a_f_y_business_02',  -- Attraktive Geschäftsfrau
        interactDistance = 2.5,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        frozen = true,
        invincible = true,
        blockEvents = true
    },
    
    -- NPC Konfiguration
    VehicleManagementNPC = {
        model = 's_m_m_pilot_02',
        interactDistance = 2.5,
        scenario = 'WORLD_HUMAN_CLIPBOARD'
    },
    
    -- 3 Normale Landeplätze (erweiterbar)
    Helipads = {
        {
            coords = vector4(-744.9388, -1468.5111, 5.0005, 23.6175),
            label = 'Landeplatz 1',
            description = 'Hauptlandeplatz'
        },
        {
            coords = vector4(-724.6525, -1444.3718, 5.0005, 324.3865),
            label = 'Landeplatz 2',
            description = 'Westlicher Landeplatz'
        },
        {
            coords = vector4(-762.1002, -1453.7061, 5.0005, 248.5201),
            label = 'Landeplatz 3',
            description = 'Östlicher Landeplatz'
        }
    }
}

--[[
    ============================================================================
    EMPLOYEE MITARBEITER RÄNGE / EMPLOYEE RANKS
    ============================================================================
    
    HIER KANNST DU RÄNGE, GEHÄLTER UND BERECHTIGUNGEN ANPASSEN
    
    Berechtigungen:
    - hire:         Mitarbeiter einstellen
    - fire:         Mitarbeiter feuern
    - promote:      Mitarbeiter befördern
    - demote:       Mitarbeiter degradieren
    - manage_fleet: Fahrzeuge verwalten/kaufen
    - manage_bank:  Firmenkonto verwalten
    - view_stats:   Statistiken einsehen
    - fly:          Helikopter fliegen
]]

Config.Ranks = {
    ['boss'] = {
        label = 'Boss',         -- Name des Ranges (anpassbar!)
        salary = 5000,          -- Stundenlohn in $ (anpassbar!)
        permissions = {
            hire = true,
            fire = true,
            promote = true,
            demote = true,
            manage_fleet = true,
            manage_bank = true,
            view_stats = true,
            fly = true
        }
    },
    ['assistant'] = {
        label = 'Assistent',    -- Name des Ranges (anpassbar!)
        salary = 3500,          -- Stundenlohn in $ (anpassbar!)
        permissions = {
            hire = true,        -- Darf einstellen
            fire = false,       -- Darf NICHT feuern
            promote = false,
            demote = false,
            manage_fleet = true,
            manage_bank = false,
            view_stats = true,
            fly = true
        }
    },
    ['pilot'] = {
        label = 'Pilot',        -- Name des Ranges (anpassbar!)
        salary = 2500,          -- Stundenlohn in $ (anpassbar!)
        permissions = {
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manage_fleet = false,
            manage_bank = false,
            view_stats = false,
            fly = true          -- Darf nur fliegen
        }
    },
    ['junior_pilot'] = {
        label = 'Junior Pilot', -- Name des Ranges (anpassbar!)
        salary = 1500,          -- Stundenlohn in $ (anpassbar!)
        permissions = {
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manage_fleet = false,
            manage_bank = false,
            view_stats = false,
            fly = true          -- Darf nur fliegen
        }
    },
    --  DER EINE zusätzliche Rang für illegale Operationen 
    -- WICHTIG: Illegal employees haben ALLE pilot permissions PLUS illegal access!
    ['illegal'] = {
        label = 'ILLEGAL Illegal Operator',
        salary = 15500,         -- 7500 + 8000 = Höheres Gehalt für riskante Arbeit
        permissions = {
            hire = false,
            fire = false,
            promote = false,
            demote = false,
            manage_fleet = true,    -- Zugang zu Military Garage
            manage_bank = false,
            view_stats = true,      -- Wie Pilot: Statistiken sehen
            access_wardrobe = true, -- Wie Pilot: Garderobe nutzen
            fly = true,
            illegal_ops = true      -- PLUS: Zugang zu illegalen Features
        },
        description = 'Pilot-Berechtigungen + illegale Operationen (3 Extra Helipads, Tablet-NPC, Military Helis)'
    }
}

--[[
    ============================================================================
    HELI HUBSCHRAUBER FLOTTE / HELICOPTER FLEET
    ============================================================================
    
    HIER KANNST DU HELIKOPTER ANPASSEN, HINZUFÜGEN ODER ENTFERNEN
    
    Parameter:
    - model:            Spawn-Name des Fahrzeugs (muss in FiveM existieren)
    - label:            Anzeige-Name im Shop (anpassbar!)
    - price:            Kaufpreis in $ (0 = kostenlos/Starter)
    - category:         Kategorie (economy/business/luxury) (anpassbar!)
    - starter:          true = Wird beim Start kostenlos hinzugefügt
    - maxFuel:          Maximaler Tankinhalt
    - fuelConsumption:  Verbrauch pro Minute
]]

Config.Vehicles = {
    
    --  STARTINVENTAR (Kostenlos beim Server-Start) 
    {
        model = 'frogger',
        label = 'Frogger (Economy)',       -- Name im Shop (anpassbar!)
        price = 0,
        category = 'economy',               -- Kategorie (anpassbar!)
        starter = true,
        maxFuel = 100,
        fuelConsumption = 0.8
    },
    {
        model = 'swift',
        label = 'Swift (Business)',         -- Name im Shop (anpassbar!)
        price = 0,
        category = 'business',              -- Kategorie (anpassbar!)
        starter = true,
        maxFuel = 120,
        fuelConsumption = 1.0
    },
    
    --  KAUFBARE PREMIUM HELIKOPTER 
    {
        model = 'akula',
        label = 'Akula (Luxury)',           -- Name im Shop (anpassbar!)
        price = 2500000,                    -- Preis (anpassbar!)
        category = 'luxury',
        starter = false,
        maxFuel = 150,
        fuelConsumption = 1.5
    },
    {
        model = 'valkyrie',
        label = 'Valkyrie (Heavy)',         -- Name im Shop (anpassbar!)
        price = 3000000,                    -- Preis (anpassbar!)
        category = 'luxury',
        starter = false,
        maxFuel = 180,
        fuelConsumption = 2.0
    },
    {
        model = 'volatus',
        label = 'Volatus (Executive)',      -- Name im Shop (anpassbar!)
        price = 1800000,                    -- Preis (anpassbar!)
        category = 'luxury',
        starter = false,
        maxFuel = 140,
        fuelConsumption = 1.2
    },
    {
        model = 'annihilator',
        label = 'Annihilator (Combat)',     -- Name im Shop (anpassbar!)
        price = 2200000,                    -- Preis (anpassbar!)
        category = 'luxury',
        starter = false,
        maxFuel = 160,
        fuelConsumption = 1.8
    },
    {
        model = 'havok',
        label = 'Havok (Compact)',          -- Name im Shop (anpassbar!)
        price = 1500000,                    -- Preis (anpassbar!)
        category = 'luxury',
        starter = false,
        maxFuel = 100,
        fuelConsumption = 1.0
    },
    
    --  MILITARY/ARMY HELIKOPTER (Spezial-Garage) 
    {
        model = 'cargobob',
        label = 'Cargobob (Heavy Transport)',  -- GROSSER TRANSPORT-HELI
        price = 3500000,
        category = 'military',
        starter = false,
        maxFuel = 200,
        fuelConsumption = 2.5,
        passengers = 8,                     -- Kann 8 Passagiere mitnehmen!
        militaryOnly = true,                -- Nur in Military Garage verfügbar
        requiredRole = 'illegal',    -- Benötigt Military Pilot Rolle
        heavyLift = true                    -- Kann schwere Fracht transportieren
    },
    {
        model = 'supervolito',
        label = 'Super Volito (Executive Transport)',  -- VIELE LEUTE
        price = 2800000,
        category = 'military',
        starter = false,
        maxFuel = 160,
        fuelConsumption = 1.6,
        passengers = 6,                     -- Kann 6 Passagiere mitnehmen!
        militaryOnly = true,
        requiredRole = 'illegal'
    },
    {
        model = 'buzzard',
        label = 'Buzzard (Attack)',
        price = 2200000,
        category = 'military',
        starter = false,
        maxFuel = 140,
        fuelConsumption = 1.5,
        passengers = 4,
        militaryOnly = true,
        requiredRole = 'illegal',
        armed = true                        -- Bewaffnet
    },
    {
        model = 'savage',
        label = 'Savage (Heavy Attack)',
        price = 4000000,
        category = 'military',
        starter = false,
        maxFuel = 180,
        fuelConsumption = 2.2,
        passengers = 2,
        militaryOnly = true,
        requiredRole = 'illegal',
        armed = true,
        heavyWeapons = true
    },
    
    -- Du kannst weitere Helikopter hinzufügen:
    -- {
    --     model = 'buzzard2',
    --     label = 'Buzzard (Attack)',
    --     price = 2000000,
    --     category = 'military',
    --     starter = false,
    --     maxFuel = 130,
    --     fuelConsumption = 1.4
    -- },
}

--[[
    ============================================================================
    ECONOMY PREISSYSTEM / PRICING SYSTEM
    ============================================================================
    
    HIER KANNST DU DIE FLUGPREISE ANPASSEN
]]

Config.Pricing = {
    flatFee = 2500,         -- Grundgebühr pro Flug in $ (anpassbar!)
    perKilometer = 500,     -- Preis pro geflogenem Kilometer in $ (anpassbar!)
    minimumCharge = 2500    -- Mindestgebühr (sollte = flatFee sein)
}

--[[
    ============================================================================
    ILLEGAL PRICING SEHR HOHE PREISE WEGEN PRISON-RISIKO!
    ============================================================================
    
    ILLEGAL FLÜGE HABEN EXTREM HOHE PREISE WEGEN:
    - Prison-Zeit (bis zu 30 Minuten)
    - Wanted Level 4
    - Fahrzeug-Beschlagnahme (40% Risiko)
    - Polizei-Verfolgung (35% Chance)
]]

Config.IllegalPricing = {
    flatFee = 25000,         -- $25,000 Grundgebühr (10x Normal!) - Prison-Risiko!
    perKilometer = 5000,     -- $5,000 pro km (10x Normal!) - Extrem hoch!
    minimumCharge = 25000,   -- Minimum $25,000
    
    -- Risiko-Faktoren
    prisonRisk = true,
    prisonTimeMin = 15,      -- Minimum 15 Min Prison
    prisonTimeMax = 30,      -- Maximum 30 Min Prison
    wantedLevel = 4,         -- 4 Sterne Wanted
    policeAlertChance = 0.30, -- 30% Polizei-Alarm
    confiscationRisk = 0.40,  -- 40% Fahrzeug-Beschlagnahme
    
    -- WANTED VERSCHWINDET NACH ERFOLGREICHER LIEFERUNG!
    -- Egal ob Passagier oder Cargo - bei illegalen Flügen
    clearWantedOnDelivery = true  -- Wanted wird gelöscht nach Ablieferung
}

--[[
    ============================================================================
    CARGO TRANSPORT SYSTEM A-ZU-B FLÜGE MIT WARE
    ============================================================================
    
    NUR FÜR ILLEGAL-RANG!
    NUR ÜBER TABLET-NPC VERFÜGBAR!
    NUR PUNKT A NACH PUNKT B (KEINE PASSAGIERE)!
]]

Config.CargoSystem = {
    enabled = true,
    requireTabletNPC = true,      -- Nur über Tablet-NPC buchbar
    requireIllegalRank = true,    -- Nur für Rang "illegal"
    onlyAtoB = true,              -- Nur A→B Flüge (keine Passagiere)
    preventPassengers = true,     -- Blockiert Passagiere während Cargo-Flug
    
    -- Cargo-Typen mit SEHR HOHEN PREISEN
    cargoTypes = {
        {
            id = 'drugs',
            label = 'Drogen-Transport',
            basePrice = 50000,        -- $50,000 Grundgebühr!
            pricePerKm = 7500,        -- $7,500 pro km!
            riskLevel = 'extreme',
            prisonTime = 30,          -- 30 Min Prison
            wantedLevel = 4,
            policeAlertChance = 0.35,
            confiscationRisk = 0.40,
            clearWantedOnDelivery = true,  -- Wanted verschwindet nach Ablieferung
            description = 'Extrem gefährlich - hohe Strafen!'
        },
        {
            id = 'weapons',
            label = 'Waffen-Schmuggel',
            basePrice = 75000,        -- $75,000 Grundgebühr!
            pricePerKm = 10000,       -- $10,000 pro km!
            riskLevel = 'extreme',
            prisonTime = 30,
            wantedLevel = 4,
            policeAlertChance = 0.40,
            confiscationRisk = 0.50,
            clearWantedOnDelivery = true,  -- Wanted verschwindet nach Ablieferung
            description = 'Höchstes Risiko - Bundeswehr-Equipment!'
        },
        {
            id = 'contraband',
            label = 'Schmuggelware',
            basePrice = 60000,        -- $60,000 Grundgebühr!
            pricePerKm = 8000,        -- $8,000 pro km!
            riskLevel = 'high',
            prisonTime = 25,
            wantedLevel = 3,
            policeAlertChance = 0.30,
            confiscationRisk = 0.35,
            clearWantedOnDelivery = true,  -- Wanted verschwindet nach Ablieferung
            description = 'Diverse illegale Güter'
        },
        {
            id = 'cash',
            label = 'Bargeld-Transport',
            basePrice = 40000,        -- $40,000 Grundgebühr!
            pricePerKm = 6000,        -- $6,000 pro km!
            riskLevel = 'high',
            prisonTime = 20,
            wantedLevel = 3,
            policeAlertChance = 0.25,
            confiscationRisk = 0.30,
            clearWantedOnDelivery = true,  -- Wanted verschwindet nach Ablieferung
            description = 'Geldwäsche - Schwarzgeld'
        }
    },
    
    -- UI Management Settings
    showRiskWarning = true,       -- Zeige Risiko-Warnung im UI
    requireConfirmation = true,   -- Bestätigung erforderlich
    showPriceCalculation = true,  -- Zeige Live-Preis-Kalkulation
    generateInvoice = true,       -- Automatische Rechnung
    invoicePrefix = 'CARGO',      -- Rechnungs-Prefix
    
    -- Flight Management
    maxActiveFlights = 5,         -- Max 5 aktive Cargo-Flüge gleichzeitig
    flightTimeout = 60,           -- 60 Min Timeout
    allowCancel = false,          -- Cargo-Flüge können NICHT abgebrochen werden!
    
    -- Fail Consequences
    loseMoneyOnFail = true,       -- Verliere Geld bei Fehlschlag
    failPenalty = 50000,          -- $50,000 Strafe
    confiscateCargo = true,       -- Cargo wird beschlagnahmt
    blacklistOnMultipleFails = false -- Kein Blacklist (RP-Server entscheidet)
}

--[[
    ============================================================================
    ECONOMYACCOUNT KASSEN-SYSTEM / ACCOUNT SYSTEM
    ============================================================================
    
    ZWEI SEPARATE KASSEN MIT EIGENEN TAXOMETER-PREISEN
    
    WICHTIG: Jede Mission hat ihre eigenen basePrice + pricePerKm Werte!
    Der Taxometer berechnet direkt mit den Missions-Preisen, KEINE Extra-Gebühren!
]]

Config.AccountSystem = {
    -- Normale Kasse (Legale Flüge)
    normalAccount = {
        enabled = true,
        label = "Normale Firmenkasse",
        taxometerEnabled = true,        -- Taxometer läuft mit Missions-Preisen
        pilotCut = 0.40,                -- Pilot bekommt 40%
        companyCut = 0.60,              -- Firma bekommt 60%
        showInMenu = true,              -- In Boss-Menü anzeigen
        transactionPrefix = "LEGAL",    -- Prefix für Transaktionen
        
        -- Taxometer nutzt Missions-basePrice + Missions-pricePerKm
        -- Beispiel VIP: $5,000 + $1,000/km
        useMissionPricing = true
    },
    
    -- Illegale Kasse (Gang-Ops, Schmuggling)
    illegalAccount = {
        enabled = true,
        label = "ILLEGAL Schwarze Kasse",
        taxometerEnabled = true,        -- Taxometer läuft mit ILLEGALEN Preisen!
        pilotCut = 0.40,                -- Pilot bekommt 40%
        companyCut = 0.60,              -- Firma bekommt 60%
        showInMenu = true,              -- In Boss-Menü anzeigen (nur für Boss)
        transactionPrefix = "ILLEGAL",  -- Prefix für Transaktionen
        requireRole = 'boss',           -- Nur Boss kann schwarze Kasse sehen
        separateBalance = true,         -- Getrennte Balance in DB
        
        -- Taxometer nutzt direkt die HOHEN illegalen Missions-Preise!
        -- Beispiel Gang Op: $15,000 + $3,000/km (6x Normal)
        -- Keine Extra-Gebühren - Preise sind bereits in Mission definiert!
        useMissionPricing = true
    },
    
    -- Military Kasse (optional separate)
    militaryAccount = {
        enabled = false,                -- Deaktiviert = nutzt normale Kasse
        label = "[MILITARY] Military Account",
        taxometerEnabled = true,
        pilotCut = 0.40,
        companyCut = 0.60,
        showInMenu = true,
        transactionPrefix = "MILITARY",
        requireRole = 'illegal',
        separateBalance = false,        -- false = nutzt normale Kasse
        useMissionPricing = true
    }
}

-- Kompatibilitäts-Aliase für Code
Config.FlatFee = Config.Pricing.flatFee
Config.PricePerKm = Config.Pricing.perKilometer
Config.SpawnFee = nil  -- Wird später aus BusinessCosts gesetzt
Config.MaxOperatingCostRequest = nil  -- Wird später aus BusinessCosts gesetzt
Config.MaxCompanyDebt = nil  -- Wird später aus DebtSystem gesetzt

--[[
    ============================================================================
    SALARY GEHALTSSYSTEM / SALARY SYSTEM
    ============================================================================
    
    AUTOMATISCHE GEHALTSZAHLUNG:
    - Mitarbeiter erhalten automatisch ihr Gehalt
    - ALLE 1 STUNDE in Echtzeit (60 Minuten)
    - Gilt für ALLE Ränge (legal UND illegal)
    - Auszahlung erfolgt auch wenn Spieler offline ist (beim nächsten Login)
]]

Config.Salary = {
    enabled = true,         -- Automatische Gehaltszahlung aktiviert
    payInterval = 60,       -- ALLE 1 STUNDE ECHTZEIT (60 Minuten) - gilt für LEGAL & ILLEGAL!
    requireOnDuty = false   -- JEDER bekommt Gehalt - egal ob on/off duty (angepasst!)
}

--[[
    ============================================================================
    ACCOUNT GESCHÄFTSKOSTEN / BUSINESS COSTS
    ============================================================================
    
    GEBÜHREN UND BETRIEBSKOSTEN
]]

Config.BusinessCosts = {
    -- Spawn-Gebühr: Wird beim Helikopter spawnen von Firmenkasse abgebucht
    spawnFee = 500,                     -- $500 pro Spawn (anpassbar!)
    
    -- Betriebskosten: Max. Betrag der angefordert werden kann (Tanken, Reparatur etc.)
    maxOperatingCostRequest = 5000,     -- Max. $5,000 pro Anfrage (anpassbar!)
    
    -- Arten von Betriebskosten
    operatingCostTypes = {
        { value = 'fuel', label = ' Tanken' },
        { value = 'repair', label = ' Reparatur' },
        { value = 'maintenance', label = ' Wartung' },
        { value = 'other', label = ' Sonstiges' }
    }
}

--[[
    ============================================================================
     PASSAGIER-TAXI-SYSTEM / PASSENGER TAXI SYSTEM
    ============================================================================
    
    WENN SPIELER OHNE helitaxi JOB EINSTEIGT
]]

Config.PassengerTaxi = {
    enabled = true,                     -- Passagier-Taxi-System aktivieren
    dialogTimeout = 30,                 -- Sekunden bis Auto-Ablehnung (anpassbar!)
    requireConfirmation = true,         -- Passagier muss bestätigen!
    
    -- Kosten-Info die dem Passagier VOR Bestätigung angezeigt wird
    showDetailedCostInfo = true,        -- Zeige detaillierte Kostenübersicht
}

--[[
    ============================================================================
     MINUS-KONTEN / DEBT SYSTEM
    ============================================================================
]]

Config.DebtSystem = {
    -- Firmenkasse: Maximale Schulden (Kreditlimit)
    maxCompanyDebt = 50000,             -- Max. -$50,000 Schulden (anpassbar!)
    
    -- Passagiere: Können unbegrenzt ins Minus gehen
    allowPassengerDebt = true,          -- Passagiere können Schulden haben
    -- HINWEIS: Passagiere haben KEIN Limit - Rechnung wird IMMER bezahlt!
}

--[[
    ============================================================================
    EMPLOYEE UNIFORMEN / OUTFITS
    ============================================================================
    
    HIER KANNST DU DIE PILOTENUNIFORM ANPASSEN
    
    Nutze Tools wie fivem-appearance oder esx_skin um die Werte herauszufinden
]]

Config.Outfits = {
    male = {
        ['pilot'] = {
            -- ESX/Native Format (für Kompatibilität)
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 13, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 11,
            ['pants_1'] = 10, ['pants_2'] = 0,
            ['shoes_1'] = 25, ['shoes_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
            ['chain_1'] = 0, ['chain_2'] = 0,
            ['ears_1'] = -1, ['ears_2'] = 0,
            
            -- QB-Clothing/Illenium-Appearance Format (optional - wird automatisch konvertiert)
            outfitData = {
                ['t-shirt'] = {item = 15, texture = 0},
                ['torso2'] = {item = 13, texture = 0},
                ['arms'] = {item = 11, texture = 0},
                ['pants'] = {item = 10, texture = 0},
                ['shoes'] = {item = 25, texture = 0},
                ['hat'] = {item = -1, texture = 0},
            }
        }
    },
    female = {
        ['pilot'] = {
            -- ESX/Native Format (für Kompatibilität)
            ['tshirt_1'] = 14, ['tshirt_2'] = 0,
            ['torso_1'] = 13, ['torso_2'] = 0,
            ['decals_1'] = 0, ['decals_2'] = 0,
            ['arms'] = 9,
            ['pants_1'] = 10, ['pants_2'] = 0,
            ['shoes_1'] = 25, ['shoes_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
            ['chain_1'] = 0, ['chain_2'] = 0,
            ['ears_1'] = -1, ['ears_2'] = 0,
            
            -- QB-Clothing/Illenium-Appearance Format (optional - wird automatisch konvertiert)
            outfitData = {
                ['t-shirt'] = {item = 14, texture = 0},
                ['torso2'] = {item = 13, texture = 0},
                ['arms'] = {item = 9, texture = 0},
                ['pants'] = {item = 10, texture = 0},
                ['shoes'] = {item = 25, texture = 0},
                ['hat'] = {item = -1, texture = 0},
            }
        }
    }
}

--[[
    ============================================================================
    UI VISUELLE EINSTELLUNGEN / VISUAL SETTINGS
    ============================================================================
]]

-- Marker Einstellungen (die 3D Symbole an Standorten)
Config.DrawDistance = 10.0              -- Sichtweite in Metern (anpassbar!)
Config.MarkerType = 1                   -- Typ (1 = Zylinder, 2 = Kugel, etc.)
Config.MarkerSize = {x = 1.5, y = 1.5, z = 1.0}  -- Größe (anpassbar!)
Config.MarkerColor = {r = 0, g = 150, b = 255, a = 120}  -- Farbe RGBA (anpassbar!)

--[[
    ============================================================================
    SETTINGS TECHNISCHE EINSTELLUNGEN / TECHNICAL SETTINGS
    ============================================================================
]]

-- Timeout für das Laden von Fahrzeug-Modellen (in Millisekunden)
Config.ModelLoadTimeout = 10000

-- Maximale Anzahl von Spielern bei "In der Nähe" Suche (Performance)
Config.MaxNearbyPlayers = 50

--[[
    ============================================================================
    PHONE STANDALONE PHONE BOOKING SYSTEM
    ============================================================================
    
    UNABHÄNGIGES TELEFON-BUCHUNGS-SYSTEM
    Läuft parallel zur QB-Phone App - KEINE Installation im Handy nötig!
    
    FUNKTIONEN:
    - Spieler ruft Telefonnummer an → Booking-UI öffnet sich automatisch
    - GPS-Wegpunkt wählen oder aktuelle Position
    - Mitarbeiter erhalten Benachrichtigung (Annehmen/Ablehnen)
    - Rückruf-System mit Telefonnummer-Speicherung
    - Datum/Uhrzeit Tracking
    - Professional UI Design
]]


-- ============================================================================
-- ILLEGAL ILLEGAL LOCATIONS & NPCs
-- ============================================================================
--[[
    Versteckte Gang-Anlaufstellen mit separaten NPCs an JEDEM Landeplatz!
    Nur für Gang Pilots & Special Ops sichtbar - KEINE Blips!
]]

--[[
    ============================================================================
    ILLEGAL ILLEGALE LOCATIONS / ILLEGAL LOCATIONS
    ============================================================================
    
    EXTRA-SYSTEM FÜR DEN "ILLEGAL" RANG
    
    NUR SICHTBAR FÜR MITARBEITER MIT RANG "illegal"!
    Automatische Sichtbarkeits-Trennung - keine Marker/Blips für normale Spieler
    
    STRUKTUR:
    - 1x Tablet-NPC (illegale Firma-Verwaltung: Boss Menu, etc.)
    - 1x Shop Marker (Fahrzeuge kaufen - KEIN NPC, nur Marker)
    - 3x Landeplätze + jeweils 1 NPC für Fahrzeug-Management
    - Duty über normales System (kein extra Duty nötig!)
    
    WICHTIG: 
    - Setze die Koordinaten auf deine gewünschten Orte
    - Aktuell sind Platzhalter (0.0, 0.0, 0.0) gesetzt
    - Verwende /coords im Spiel um Koordinaten zu finden
]]

Config.IllegalLocations = {
    enabled = true,
    
    -- TABLET-NPC (Illegale Firma-Verwaltung)
    -- Hier können illegale Mitarbeiter:
    -- - Boss Menu öffnen (Firma verwalten)
    -- - Mitarbeiter einstellen/entlassen
    -- - Finanzen verwalten
    -- Nur für "illegal" Rang sichtbar
    TabletNPC = {
        enabled = true,
        coords = vector4(-736.4840, -1503.7228, 5.0005, 51.4065),
        NPC = {
            model = 'g_m_m_mexboss_01',        -- Gang Boss Model
            scenario = 'WORLD_HUMAN_SMOKING',   -- Raucht
            frozen = true,
            invincible = true,
            blockEvents = true,
            interactDistance = 2.5,
            helpText = '~r~[Illegal Verwaltung]~s~ Drücke ~INPUT_CONTEXT~ für ~y~Firma-Menü~s~'
        }
    },
    
    -- SHOP MARKER (Army/Bundeswehr Helikopter kaufen)
    -- KEIN NPC - nur ein Marker!
    -- Hier können illegale Mitarbeiter Military/Army Helis kaufen
    -- Nur für "illegal" Rang sichtbar
    VehicleShop = {
        enabled = true,
        coords = vector3(-747.9616, -1508.1331, 5.0006),
        markerType = 1,                    -- Marker Typ (1 = Zylinder)
        markerColor = {r = 255, g = 0, b = 0, a = 100},  -- Rot
        interactDistance = 2.5,
        helpText = '~r~[Army Shop]~s~ Drücke ~INPUT_CONTEXT~ für ~y~Military Helis~s~'
    },
    
    -- 3 ILLEGALE LANDEPLÄTZE + FAHRZEUG-MANAGEMENT NPCS
    -- Jeder Landeplatz hat seinen eigenen NPC für Fahrzeug-Spawning
    -- Nur für "illegal" Rang sichtbar
    -- ERWEITERBAR: Füge weitere hinzu oder entferne welche!
    Helipads = {
        {
            name = "Illegal Landeplatz Hafen",
            coords = vector4(596.8853, -3029.4810, 6.0693, 83.4829),  -- HELIPAD Position (wo Heli landet)
            label = 'Illegal Pad 1',
            description = 'Versteckter Landeplatz (erweiterbar)',
            -- NPC für diesen Landeplatz (Fahrzeug-Management)
            -- NPC steht NEBEN dem Helipad, nicht darauf!
            NPC = {
                enabled = true,
                coords = vector4(592.5178, -3049.0083, 6.1697, 296.2487),  -- NPC Position neben Pad!
                model = 'g_m_y_mexgang_01',            -- Gang Member Model
                scenario = 'WORLD_HUMAN_SMOKING',       -- Raucht (FIXED: war Schweißen)
                frozen = true,
                invincible = true,
                blockEvents = true,
                interactDistance = 2.5,
                helpText = '~r~[Illegal Garage]~s~ Drücke ~INPUT_CONTEXT~ für ~y~Fahrzeuge~s~'
            }
        },
        {
            name = "Illegal Landeplatz Fabrik",
            coords = vector4(2756.2219, 1364.4866, 24.5240, 355.1977),  -- LANDEPLATZ Koordinaten
            label = 'Illegal Pad 2',
            description = 'Versteckter Landeplatz (erweiterbar)',
            -- NPC für diesen Landeplatz (Fahrzeug-Management)
            NPC = {
                enabled = true,
                coords = vector4(2767.9619, 1387.6740, 24.5384, 110.1361),  -- NPC Position neben Pad
                model = 'g_m_y_mexgang_01',            -- Gang Member Model
                scenario = 'WORLD_HUMAN_SMOKING',       -- Raucht
                frozen = true,
                invincible = true,
                blockEvents = true,
                interactDistance = 2.5,
                helpText = '~r~[Illegal Garage]~s~ Drücke ~INPUT_CONTEXT~ für ~y~Fahrzeuge~s~'
            }
        },
        {
            name = "Illegaler Landeplatz Feld",
            coords = vector4(2225.7483, 5162.2739, 57.9237, 116.8980),  -- LANDEPLATZ Koordinaten
            label = 'Illegal Pad 3',
            description = 'Versteckter Landeplatz (erweiterbar)',
            -- NPC für diesen Landeplatz (Fahrzeug-Management)
            NPC = {
                enabled = true,
                coords = vector4(2240.0383, 5156.4346, 57.5635, 100.6616),  -- NPC Position neben Pad
                model = 'g_m_m_mexboss_01',            -- Gang Boss Model
                scenario = 'WORLD_HUMAN_GUARD_STAND',   -- Wache
                frozen = true,
                invincible = true,
                blockEvents = true,
                interactDistance = 2.5,
                helpText = '~r~[Illegal Garage]~s~ Drücke ~INPUT_CONTEXT~ für ~y~Fahrzeuge~s~'
            }
        }
        -- Du kannst weitere hinzufügen:
        -- {
        --     name = "Versteckter Landeplatz 4",
        --     coords = vector4(x, y, z, heading),
        --     label = 'Illegal Pad 4',
        --     description = 'Zusätzlicher versteckter Landeplatz',
        --     NPC = {
        --         enabled = true,
        --         coords = vector4(x, y, z, heading),
        --         model = 'g_m_y_mexgang_01',
        --         scenario = 'WORLD_HUMAN_CLIPBOARD',
        --         frozen = true,
        --         invincible = true,
        --         blockEvents = true,
        --         interactDistance = 2.5,
        --         helpText = '~r~[Illegal Garage]~s~ Drücke ~INPUT_CONTEXT~ für ~y~Fahrzeuge~s~'
        --     }
        -- },
    },
    
    -- Zugriffskontrolle
    -- AUTOMATISCH: Nur "illegal" Rang kann diese NPCs/Marker/Landeplätze sehen!
    -- Duty wird über normales System genutzt (kein extra Duty nötig)
    accessControl = {
        allowedRoles = {'illegal'},  -- NUR für Rang "illegal" zugänglich
        requireOnDuty = false,       -- Kein Dienst-Check nötig (nutzt normales Duty)
        showBlips = false            -- KEINE Blips auf Karte (geheim!)
    },
    
    -- Sicherheit & Logging
    security = {
        logAccess = true,            -- Zugriffe loggen
        notifyPolice = false,        -- KEINE Polizei-Benachrichtigung
        hideFromMap = true           -- Versteckt auf Karte
    }
}

Config.StandalonePhone = {
    -- System aktivieren/deaktivieren
    enabled = true,
    
    -- Telefonnummer für Taxi-Buchungen
    -- Spieler rufen diese Nummer an um zu buchen
    phoneNumber = "555-8294",  -- 555-TAXI (anpassbar!)
    
    -- Alternative Nummer (optional)
    alternativeNumber = "911",  -- Notrufnummer (optional, kann leer sein)
    
    -- Cooldown zwischen Anrufen (in Millisekunden)
    cooldown = 60000,  -- 60 Sekunden (anpassbar!)
    
    -- UI Einstellungen
    ui = {
        -- Position der Employee Notification
        notificationPosition = "top-right",  -- top-right, top-left, bottom-right, bottom-left
        
        -- Auto-Hide Notification nach X Sekunden
        autoHideAfter = 30,  -- 30 Sekunden (anpassbar!)
        
        -- Sound abspielen bei neuer Buchung
        playSound = true,
        soundName = "Menu_Accept",
        soundSet = "Phone_SoundSet_Default"
    },
    
    -- Callback-System
    callbacks = {
        -- Callback-Anfragen aktivieren
        enabled = true,
        
        -- Maximale Anzahl gespeicherter Callbacks
        maxCallbacks = 50,
        
        -- Auto-Löschen nach X Tagen
        autoDeleteAfterDays = 7
    },
    
    -- Booking Einstellungen
    booking = {
        -- Maximale Passagiere pro Buchung
        maxPassengers = 6,
        
        -- Booking automatisch nach X Minuten ablaufen lassen
        expiryMinutes = 10,
        
        -- GPS-Route für Mitarbeiter setzen
        setGPSRoute = true,
        
        -- Blip auf Map erstellen
        createBlip = true,
        blipSprite = 64,  -- Helicopter
        blipColor = 5,    -- Yellow
        blipScale = 0.8
    },
    
    -- Integration mit bestehenden Phone-Systemen
    -- Automatische Erkennung von: qb-phone, qs-smartphone, lb-phone, gksphone
    autoDetectPhoneSystem = true,
    
    -- Fallback Commands (wenn kein Phone-System erkannt wird)
    enableCommands = true,
    commands = {
        "calltaxi",  -- /calltaxi
        "taxi"       -- /taxi
    }
}

--[[
    ============================================================================
     KOMPATIBILITÄTS-ALIASE (Nicht ändern!)
    ============================================================================
]]

-- Setze Aliase für einfacheren Zugriff im Code
if Config.BusinessCosts then
    Config.SpawnFee = Config.BusinessCosts.spawnFee
    Config.MaxOperatingCostRequest = Config.BusinessCosts.maxOperatingCostRequest
end

if Config.DebtSystem then
    Config.MaxCompanyDebt = Config.DebtSystem.maxCompanyDebt
end

--[[
    ============================================================================
     ENDE DER KONFIGURATION
    ============================================================================
    
    Du hast alle wichtigen Einstellungen angepasst?
    
    1. Speichere diese Datei
    2. Starte den Server neu: /restart Heli-Taxi
    3. Viel Erfolg mit deinem Heli-Taxi Business! HELI
    
    Bei Problemen: Siehe INSTALLATION.md und USAGE.md
]]
