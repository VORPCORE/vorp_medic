local Core     = exports.vorp_core:GetCore()
local MenuData = exports.vorp_menu:GetMenuData()
local T        = Translation.Langs[Config.Lang]
local blip     = 0

-- on resource stop
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    -- remove blips
    for key, value in pairs(Config.Stations) do
        RemoveBlip(value.BlipHandle)
    end
end)

local function getClosestPlayer()
    local players <const> = GetActivePlayers()
    local coords <const> = GetEntityCoords(PlayerPedId())

    for _, value in ipairs(players) do
        if PlayerId() ~= value then
            local targetPed <const> = GetPlayerPed(value)
            local targetCoords <const> = GetEntityCoords(targetPed)
            local distance <const> = #(coords - targetCoords)
            if distance < 3.0 then
                return true, targetPed, value
            end
        end
    end
    return false, nil
end

local group <const> = GetRandomIntInRange(0, 0xFFFFFF)
local prompt        = 0
local function registerPrompts()
    if prompt ~= 0 then UiPromptDelete(prompt) end
    prompt = UiPromptRegisterBegin()
    UiPromptSetControlAction(prompt, Config.Keys.B)
    local label = VarString(10, "LITERAL_STRING", T.Menu.Press)
    UiPromptSetText(prompt, label)
    UiPromptSetGroup(prompt, group, 0)
    UiPromptSetStandardMode(prompt, true)
    UiPromptRegisterEnd(prompt)
end

local function getPlayerJob()
    local job <const> = LocalPlayer.state.Character.Job
    return Config.MedicJobs[job]
end

local function isOnDuty()
    if not LocalPlayer.state.isMedicDuty then
        Core.NotifyObjective(T.Duty.YouAreNotOnDuty, 5000)
        return false
    end
    return true
end

local function createBlips()
    for key, value in pairs(Config.Stations) do
        local blip <const> = BlipAddForCoords(Config.Blips.Style, value.Coords.x, value.Coords.y, value.Coords.z)
        SetBlipSprite(blip, Config.Blips.Sprite)
        BlipAddModifier(blip, Config.Blips.Color)
        SetBlipName(blip, value.Name)
        value.BlipHandle = blip
    end
end

local isHandleRunning = false
local function Handle()
    registerPrompts()
    isHandleRunning = true
    while true do
        local sleep = 1000
        for key, value in pairs(Config.Stations) do
            local coords <const> = GetEntityCoords(PlayerPedId())

            if value.Storage[key] then
                local distanceStorage <const> = #(coords - value.Storage[key].Coords)
                if distanceStorage < 2.0 then
                    sleep = 0
                    if distanceStorage < 1.5 then
                        local label <const> = VarString(10, "LITERAL_STRING", value.Name)
                        UiPromptSetActiveGroupThisFrame(group, label, 0, 0, 0, 0)

                        if UiPromptHasStandardModeCompleted(prompt, 0) then
                            if isOnDuty() then
                                local isAnyPlayerClose <const> = getClosestPlayer()
                                if not isAnyPlayerClose then
                                    TriggerServerEvent("vorp_medic:Server:OpenStorage", key)
                                else
                                    Core.NotifyObjective(T.Error.Playernearby, 5000)
                                end
                            end
                        end
                    end
                end
            end

            if value.Teleports[key] then
                local distanceTeleport <const> = #(coords - value.Teleports[key].Coords)
                if distanceTeleport < 2.0 then
                    sleep = 0
                    if distanceTeleport < 1.5 then
                        local label <const> = VarString(10, "LITERAL_STRING", value.Name)
                        UiPromptSetActiveGroupThisFrame(group, label, 0, 0, 0, 0)

                        if UiPromptHasStandardModeCompleted(prompt, 0) then
                            if isOnDuty() then
                                OpenTeleportMenu(key)
                            end
                        end
                    end
                end
            end


            local distanceStation <const> = #(coords - value.Coords)
            if distanceStation < 2.0 then
                sleep = 0

                local label <const> = VarString(10, "LITERAL_STRING", value.Name)
                UiPromptSetActiveGroupThisFrame(group, label, 0, 0, 0, 0)

                if UiPromptHasStandardModeCompleted(prompt, 0) then
                    local job <const> = LocalPlayer.state.Character.Job
                    if Config.SheriffJobs[job] then
                        OpenSheriffMenu()
                    else
                        Core.NotifyObjective(T.Error.OnlyDoctorOpenMenu, 5000)
                    end
                end
            end
        end

        if not isHandleRunning then return end
        Wait(sleep)
    end
end


RegisterNetEvent("vorp_medic:Client:JobUpdate", function()
    local hasJob = getPlayerJob()

    if not hasJob then
        isHandleRunning = false
        return
    end

    if isHandleRunning then return end
    CreateThread(Handle)
end)

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    createBlips()
    local hasJob <const> = getPlayerJob()
    if not hasJob then return end
    if not isHandleRunning then
        CreateThread(Handle)
    end
end)

function OpenSheriffMenu()
    MenuData.CloseAll()
    local elements <const> = {
        {
            label = T.Menu.HirePlayer,
            value = "hire",
            desc = T.Menu.HirePlayer .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        },
        {
            label = T.Menu.FirePlayer,
            value = "fire",
            desc = T.Menu.FirePlayer .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        }
    }

    MenuData.Open("default", GetCurrentResourceName(), "OpenSheriffMenu", {
        title = T.Menu.SheriffMenu,
        subtext = T.Menu.HireFireMenu,
        align = Config.Align,
        elements = elements,

    }, function(data, menu)
        if data.current.value == "hire" then
            OpenHireMenu()
        elseif data.current.value == "fire" then
            local MyInput <const> = {
                type = "enableinput",
                inputType = "input",
                button = T.Player.Confirm,
                placeholder = T.Player.PlayerId,
                style = "block",
                attributes = {
                    inputHeader = T.Menu.FirePlayer,
                    type = "number",
                    pattern = "[0-9]",
                    title = T.Player.OnlyNumbersAreAllowed,
                    style = "border-radius: 10px; background-color: ; border:none;",
                }
            }

            local res = exports.vorp_inputs:advancedInput(MyInput)
            res = tonumber(res)
            if res and res > 0 then
                TriggerServerEvent("vorp_medic:server:firePlayer", res)
            end
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenHireMenu()
    MenuData.CloseAll()
    local elements = {}
    for key, _ in pairs(Config.MedicJobs) do
        table.insert(elements, { label = T.Jobs.Job .. ": " .. key, value = key, desc = T.Jobs.Job .. key })
    end

    MenuData.Open("default", GetCurrentResourceName(), "OpenHireFireMenu", {
        title = T.Menu.HireFireMenu,
        subtext = T.Menu.SubMenu,
        elements = elements,
        align = Config.Align,
        lastmenu = "OpenSheriffMenu"

    }, function(data, menu)
        if (data.current == "backup") then
            return _G[data.trigger]()
        end

        menu.close()
        local MyInput = {
            type = "enableinput",
            inputType = "input",
            button = T.Player.Confirm,
            placeholder = T.Player.PlayerId,
            style = "block",
            attributes = {
                inputHeader = T.Menu.HirePlayer,
                type = "number",
                pattern = "[0-9]",
                title = T.Player.OnlyNumbersAreAllowed,
                style = "border-radius: 10px; background-color: ; border:none;",
            }
        }

        local res = exports.vorp_inputs:advancedInput(MyInput)
        res = tonumber(res)
        if res and res > 0 then
            TriggerServerEvent("vorp_medic:server:hirePlayer", res, data.current.value)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function OpenTeleportMenu(location)
    MenuData.CloseAll()
    local elements = {}
    for key, value in pairs(Config.Teleports) do
        if location then
            if location ~= key then
                table.insert(elements, {
                    label = key,
                    value = key,
                    desc = T.Teleport.TeleportTo .. ": " .. value.Name
                })
            end
        else
            table.insert(elements, {
                label = key,
                value = key,
                desc = T.Teleport.TeleportTo .. ": " .. value.Name
            })
        end
    end

    MenuData.Open("default", GetCurrentResourceName(), "OpenTeleportMenu", {
        title = T.Teleport.TeleportMenu,
        subtext = T.Menu.SubMenu,
        align = Config.Align,
        elements = elements,

    }, function(data, menu)
        menu.close()
        local coords <const> = Config.Teleports[data.current.value].Coords
        DoScreenFadeOut(1000)
        repeat Wait(0) until IsScreenFadedOut()
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
        repeat Wait(0) until HasCollisionLoadedAroundEntity(PlayerPedId()) == 1
        DoScreenFadeIn(1000)
        repeat Wait(0) until IsScreenFadedIn()
    end, function(data, menu)
        menu.close()
    end)
end

local function OpenMedicMenu()
    MenuData.CloseAll()
    local isONduty <const> = LocalPlayer.state.isMedicDuty
    local label <const> = isONduty and T.Duty.OffDuty or T.Duty.OnDuty
    local desc <const> = isONduty and T.Duty.GoOffDuty or T.Duty.GoOnDuty
    local elements <const> = {
        {
            label = label,
            value = "duty",
            desc = desc .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        }
    }

    if Config.UseTeleportsMenu then
        table.insert(elements, {
            label = T.Teleport.TeleportTo,
            value = "teleports",
            desc = T.Teleport.TeleportToDifferentLocations .. "<br><br><br><br><br><br><br><br><br><br><br><br>"
        })
    end

    MenuData.Open("default", GetCurrentResourceName(), "OpenMedicMenu", {
        title = T.Menu.DoctorMenu,
        subtext = T.Menu.SubMenu,
        align = Config.Align,
        elements = elements,

    }, function(data, menu)
        if data.current.value == "teleports" then
            OpenTeleportMenu()
        elseif data.current.value == "duty" then
            local result = Core.Callback.TriggerAwait("vorp_medic:server:checkDuty")
            if result then
                Core.NotifyObjective(T.Duty.YouAreNowOnDuty, 5000)
            else
                Core.NotifyObjective(T.Duty.YouAreNotOnDuty, 5000)
            end
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

RegisterNetEvent("vorp_medic:Client:OpenMedicMenu", function()
    OpenMedicMenu()
end)


-- vorp_medic:Client:HealAnim"
RegisterNetEvent("vorp_medic:Client:HealAnim", function()
    -- for doctor animation
end)
RegisterNetEvent("vorp_medic:Client:HealPlayer", function(health, stamina)
    -- for player animation
    if health and health > 0 then
        local oldHealth = GetEntityHealth(PlayerPedId())
        local newHealth = oldHealth + health
        SetEntityHealth(PlayerPedId(), newHealth, 0)
    end
    if stamina and stamina > 0 then
        local oldStamina = GetPlayerStamina(PlayerId())
        local newStamina = oldStamina + stamina
        SetPlayerStamina(PlayerId(), newStamina)
    end
end)

RegisterNetEvent("vorp_medic:Client:ReviveAnim", function()
    -- for revive animation
end)

RegisterNetEvent("vorp_medic:Client:AlertDoctor", function(targetCoords)
    if blip ~= 0 then return end -- dont allow more than one call

    blip = BlipAddForCoords(Config.Blips.Style, targetCoords.x, targetCoords.y, targetCoords.z)
    SetBlipSprite(blip, Config.Blips.Sprite)
    BlipAddModifier(blip, Config.Blips.Color)
    SetBlipName(blip, "player alert")

    StartGpsMultiRoute(joaat("COLOR_RED"), true, true)
    AddPointToGpsMultiRoute(targetCoords.x, targetCoords.y, targetCoords.z, false)
    SetGpsMultiRouteRender(true)

    repeat Wait(1000) until #(GetEntityCoords(PlayerPedId()) - targetCoords) < 5.0 or blip == 0

    RemoveBlip(blip)
    blip = 0
    ClearGpsMultiRoute()
    Core.NotifyObjective("you have arrived to the location", 5000)
end)


RegisterNetEvent("vorp_medic:Client:RemoveBlip", function()
    if blip == 0 then return end
    RemoveBlip(blip)
    blip = 0
    ClearGpsMultiRoute()
end)
