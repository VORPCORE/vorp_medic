Config                      = {}

Config.DevMode              = true

Config.Align                = "top-left" -- menu alignment

Config.Lang                 = "English"  -- language you want to use please make sure its in the translation.lua

Config.AllowOnlyDeadToAlert = true       -- if true only dead players can alert doctors


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
--check the server.lua for webhook url location line 19 in server.lua
Config.Storage           = {

    Valentine = {
        Name = "Storage",
        Limit = 1000,
        Coords = vector3(-288.74, 808.77, 119.44),
    },
    Strawberry = {
        Name = "Storage",
        Limit = 1000,
        Coords = vector3(-1811.868, -353.766, 163.649),
    },
    Blackwater = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(-766.4104, -1271.5747, 44.0613),
    },
    Rhodes = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(1361.552, -1303.204, 76.767),

    },
    SaintDenis = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(2507.538, -1301.395, 47.953),

    },
    Tumbleweed = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(-5526.896, -2928.556, -2.360),
    },
    Annesburg = {
        Name = "Armoury",
        Limit = 1000,
        Coords = vector3(2909.674, 1309.006, 43.938),
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
        Coords = vector3(-1811.868, -353.766, 163.649),
    },
    Blackwater = {
        Name = "Blackwater",
        Coords = vector3(-766.4104, -1271.5747, 44.0613),
    },
    Rhodes = {
        Name = "Rhodes",
        Coords = vector3(1361.552, -1303.204, 76.767),

    },
    SaintDenis = {
        Name = "Saint Denis",
        Coords = vector3(2507.538, -1301.395, 47.953),

    },
    Tumbleweed = {
        Name = "Tumbleweed",
        Coords = vector3(-5526.896, -2928.556, -2.360),
    },
    Annesburg = {
        Name = "Annesburg",
        Coords = vector3(2909.674, 1309.006, 43.938),
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
        Coords = vector3(-286.65, 815.05, 119.44),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Strawberry = {
        Name = "Strawberry doctor",
        Coords = vector3(-1811.868, -353.766, 163.649),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Blackwater = {
        Name = "Blackwater doctor",
        Coords = vector3(-766.4104, -1271.5747, 44.0613),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Rhodes = {
        Name = "Rhodes doctor",
        Coords = vector3(1361.552, -1303.204, 76.767),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    SaintDenis = {
        Name = "Saint Denis doctor",
        Coords = vector3(2507.538, -1301.395, 47.953),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Tumbleweed = {
        Name = "Tumbleweed doctor",
        Coords = vector3(-5526.896, -2928.556, -2.360),
        Teleports = Config.Teleports,
        Storage = Config.Storage,
    },
    Annesburg = {
        Name = "Annesburg doctor",
        Coords = vector3(2909.674, 1309.006, 43.938),
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
