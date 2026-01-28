Config = {}

-- Legal taxi locations only (no illegal activities)
Config.TaxiLocations = {
    {name = "Los Santos International Airport", coords = vector3(-1042.74, -2746.45, 21.36)},
    {name = "Downtown Vinewood", coords = vector3(148.28, -1040.46, 29.37)},
    {name = "Sandy Shores Airfield", coords = vector3(1770.26, 3239.52, 42.13)},
    {name = "Paleto Bay", coords = vector3(-288.85, 6230.03, 31.49)},
    {name = "Vespucci Helipad", coords = vector3(-724.92, -1444.23, 5.0)}
}

-- Helicopter spawn location
Config.HeliSpawn = {
    coords = vector3(-745.45, -1468.52, 5.0),
    heading = 140.0,
    model = "frogger"  -- Taxi helicopter model
}

-- Prices for taxi service
Config.Prices = {
    basePrice = 500,
    perMeter = 0.5
}

-- Colors and UI
Config.MarkerColor = {r = 50, g = 200, b = 50, a = 100}  -- Green for legal markers
Config.BlipColor = 2  -- Green blip
Config.BlipSprite = 43  -- Helicopter sprite
