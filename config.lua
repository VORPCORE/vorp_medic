Config                      = {}

Config.DevMode              = true

Config.Align                = "top-left" -- menu alignment

Config.Lang                 = "English"  -- language you want to use please make sure its in the translation.lua

Config.AllowOnlyDeadToAlert = true       -- if true only dead players can alert doctors
Config.AlertDoctorCommand = "alertDoctor"

Config.DoctorMenuCommand = 'doctormenu' -- Command to go on duty and teleport
-- add any job names here
Config.MedicJobs         = {
    doctor = true,
    headdoctor = true,
}

Config.Keys              = { -- prompts
    B = 0x4CC0E2FE,
}

-- jobs allowed to hire
Config.JobLabels         = {
    doctor = "Doctor",
    headdoctor = "Head Doctor",
    shaman = "Shaman",
}

-- jobs that can open hire menu
Config.DoctorJobs        = {
    headdoctor = true,
}

-- if true storage for every doctor station will be shared if false they will be unique
Config.ShareStorage      = true

-- storage locations
--check the server.lua for webhook url location line 21 in server.lua
Config.Storage           = {

    Valentine = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(-288.74, 808.77, 119.44),
    },
    Strawberry = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(-1803.33, -432.59, 158.83),
    },
    Blackwater = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(-833.15, -1269.5, 43.69),
    },
    Rhodes = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(1371.96, -1305.42, 77.97),

    },
    SaintDenis = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(2722.86, -1228.6, 50.37),

    },
    Tumbleweed = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(-5533.5, -2944.19, -1.68),
    },
    Annesburg = {
        Name = "Medical storage",
        Limit = 1000,
        Coords = vector3(2927.08, 1353.72, 44.74),
    },
    Armadillo = {
        Name = "Medical storage",
        Coords = vector3(-3657.81, -2602.66, -13.29),
    },
}

-- if true players can use teleport from the doctor menu if false only from locations
Config.UseTeleportsMenu  = true

-- set up locations to teleport to or from
Config.Teleports         = {

    Valentine = {
        Name = " Valentine",
        Coords = vector3(-280.38, 817.81, 119.38),
    },
    Strawberry = {
        Name = "Strawberry",
        Coords = vector3(-1793.37, -422.81, 155.97),
    },
    Blackwater = {
        Name = "Blackwater",
        Coords = vector3(-853.9, -1277.13, 43.32),
    },
    Rhodes = {
        Name = "Rhodes",
        Coords = vector3(1372.79, -1313.25, 77.24),

    },
    SaintDenis = {
        Name = "Saint Denis",
        Coords =vector3(2723.1, -1238.92, 49.95),

    },
    Tumbleweed = {
        Name = "Tumbleweed",
        Coords = vector3(-5518.78, -2949.74, -1.73),
    },
    Annesburg = {
        Name = "Annesburg",
        Coords = vector3(2926.08, 1342.24, 44.1),
    },
    Armadillo = {
        Name = "Armadillo",
        Coords = vector3(-3669.97, -2604.21, -13.71),
    },
}

--blips for stations
Config.Blips             = {
    Color = "COLOR_WHITE",
    Style = "BLIP_STYLE_FRIENDLY_ON_RADAR",
    Sprite = "blip_mp_travelling_saleswoman",
}

Config.AlertBlips        = {
    Color = "COLOR_RED",
    Style = "BLIP_STYLE_CHALLENGE_OBJECTIVE",
    Sprite = "blip_mp_travelling_saleswoman",
}

-- doctor stations  boss menu locations
Config.Stations = {

    Valentine = {
        Name = "Valentine doctor",
        Coords = vector3(-288.82, 808.44, 119.43), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Strawberry = {
        Name = "Strawberry doctor",
        Coords = vector3(-1807.87, -430.77, 158.83), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Blackwater = {
        Name = "Blackwater doctor",
        Coords = vector3(-833.81, -1264.22, 43.69), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Rhodes = {
        Name = "Rhodes doctor",
        Coords = vector3(1368.21, -1307.35, 78.02), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    SaintDenis = {
        Name = "Saint Denis doctor",
        Coords = vector3(2721.29, -1233.11, 50.37), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Armadillo = {
        Name = "Armadillo doctor",
        Coords = vector3(-3661.75, -2600.83, -13.29), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Annesburg = {
        Name = "Annesburg doctor",
        Coords = vector3(2925.92, 1350.49, 44.85), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Tumbleweed = {
        Name = "Tumbleweed doctor",
        Coords = vector3(-5528.09, -2953.05, -0.7), 
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
}
-- usable items
Config.Items    = {
    bandage = {      -- item name
        health = 50, -- health to add
        stamina = 0, -- stamina to add
        revive = false,
    },
    potion = {
        health = 100,
        stamina = 0,
        revive = false,
    },
    syringe = {
        health = 0,
        stamina = 0,
        revive = true,
    },

}
