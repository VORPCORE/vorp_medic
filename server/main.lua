local Lib <const>         = Import({ "/configs/config", "/languages/translation", "/configs/logs" })
local Config <const>      = Lib.Config --[[@as vorp_medic]]
local Translation <const> = Lib.Translation --[[@as vorp_medic_translation]]
local Logs <const>        = Lib.Logs

local Core <const>        = exports.vorp_core:GetCore()
local Inv <const>         = exports.vorp_inventory
local T <const>           = Translation.Langs[Config.Lang]
if not T then return print('Translation not found for ' .. Config.Lang) end

local JobsToAlert <const>     = {}
local PlayersAlerts <const>   = {}
local DutyList <const>        = {}

local GetEntityCoords <const> = GetEntityCoords
local GetPlayerPed <const>    = GetPlayerPed


local function registerStorage(prefix, name, limit)
    local isInvRegstered <const> = Inv:isCustomInventoryRegistered(prefix)
    if not isInvRegstered then
        local data <const> = {
            id = prefix,
            name = name,
            limit = limit,
            acceptWeapons = true,
            shared = true,
            ignoreItemStackLimit = true,
            whitelistItems = false,
            UsePermissions = false,
            UseBlackList = false,
            whitelistWeapons = false,
            webhook = Logs.StorageWebook,

        }
        Inv:registerInventory(data)
    end
end

local function hasJob(user)
    local Character <const> = user.getUsedCharacter
    return Config.MedicJobs[Character.job]
end

local function isOnDuty(source)
    return DutyList[source]
end

-- new checker for job and grades
local function _jobAndGrade(user)
    local c = user.getUsedCharacter
    return c and c.job, c and (c.jobgrade or c.jobGrade)
end

-- new checker for boss
local function _canManageStaff(user)
    local job, grade = _jobAndGrade(user)
    local cfg = job and Config.MedicJobs[job]
    local bossFlag = cfg and cfg.Ranks and cfg.Ranks[3] and cfg.Ranks[3].Boss == true
    return bossFlag and tonumber(grade) == 3
end

local function isPlayerNear(source, target)
    local sourcePos <const> = GetEntityCoords(GetPlayerPed(source))
    local targetPos <const> = GetEntityCoords(GetPlayerPed(target))
    local distance <const> = #(sourcePos - targetPos)
    return distance <= 5
end

local function openDoctorMenu(source)
    local user <const> = Core.getUser(source)
    if not user then return end

    if not hasJob(user) then
        return Core.NotifyObjective(source, T.Jobs.YouAreNotADoctor, 5000)
    end
    TriggerClientEvent('vorp_medic:Client:OpenMedicMenu', source)
end

local function getSourceInfo(user, _source)
    local sourceCharacter <const> = user.getUsedCharacter
    local charname <const> = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
    local sourceIdentifier <const> = sourceCharacter.identifier
    local steamname <const> = GetPlayerName(_source)
    return charname, sourceIdentifier, steamname
end

--* OPEN STORAGE
RegisterNetEvent("vorp_medic:Server:OpenStorage", function(key)
    local _source <const> = source
    local user <const> = Core.getUser(_source)
    if not user then return end

    if not hasJob(user) then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotADoctor, 5000)
    end

    if not isOnDuty(_source) then
        return Core.NotifyObjective(_source, T.Duty.YouAreNotOnDuty, 5000)
    end

    local prefix = "vorp_medic_storage_" .. key
    if Config.ShareStorage then
        prefix = "vorp_medic_storage"
    end

    local storageName <const> = Config.Storage[key].Name
    local storageLimit <const> = Config.Storage[key].Limit
    registerStorage(prefix, storageName, storageLimit)
    Inv:openInventory(_source, prefix)
end)

--* CLEANUP
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, _ in pairs(Config.Storage) do
        local prefix = "vorp_medic_storage_" .. key
        if Config.ShareStorage then
            prefix = "vorp_medic_storage"
        end
        Inv:removeInventory(prefix)
    end

    local players <const> = GetPlayers()
    for i = 1, #players do
        local _source <const> = players[i]
        Player(_source).state:set('isMedicDuty', nil, true)
    end
end)

--* REGISTER STORAGE
AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, value in pairs(Config.Storage) do
        local prefix = "vorp_medic_storage_" .. key
        if Config.ShareStorage then
            prefix = "vorp_medic_storage"
        end
        registerStorage(prefix, value.Name, value.Limit)
    end
    if Config.DevMode then
        TriggerClientEvent("chat:addSuggestion", -1, "/" .. Config.DoctorMenuCommand, T.Menu.OpenDoctorMenu, {})
        RegisterCommand(Config.DoctorMenuCommand, openDoctorMenu, false)
    end
end)

--* ON PLAYER SPAWN
AddEventHandler("vorp:SelectedCharacter", function(source, char)
    if Config.DevMode then return end
    if not Config.MedicJobs[char.job] then return end
    TriggerClientEvent("chat:addSuggestion", source, "/" .. Config.DoctorMenuCommand, T.Menu.OpenDoctorMenu, {})
    RegisterCommand(Config.DoctorMenuCommand, openDoctorMenu, false)
end)

--* HIRE PLAYER
RegisterNetEvent("vorp_medic:server:hirePlayer", function(id, job)
    local _source <const> = source
    local user <const> = Core.getUser(_source)
    if not user then return end

    if not hasJob(user) then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotADoctor, 5000)
    end

    if not _canManageStaff(user) then
        return Core.NotifyObjective(_source, T.Menu.CantHire, 5000)
    end
    if (not Config.AllowBossSelfManage) and tonumber(id) == _source then
        return Core.NotifyObjective(_source, T.Menu.SelfManage, 5000)
    end

    local jobCfg = Config.MedicJobs[job]
    local label <const> = jobCfg and jobCfg.JobLabel
    if not label then return print(T.Jobs.Nojoblabel) end

    local target <const> = id
    local targetUser <const> = Core.getUser(target)
    if not targetUser then return Core.NotifyObjective(_source, T.Player.NoPlayerFound, 5000) end

    local targetCharacter <const> = targetUser.getUsedCharacter
    local targetJob <const> = targetCharacter.job
    if job == targetJob then
        return Core.NotifyObjective(_source, T.Player.PlayeAlreadyHired .. label, 5000)
    end

    if not isPlayerNear(_source, target) then
        return Core.NotifyObjective(_source, T.Player.NotNear, 5000)
    end

    targetCharacter.setJob(job, true)
    targetCharacter.setJobLabel(label, true)

    Core.NotifyObjective(target, T.Player.HireedPlayer .. label, 5000)
    Core.NotifyObjective(_source, T.Menu.HirePlayer, 5000)

    TriggerClientEvent("chat:addSuggestion", _source, "/" .. Config.DoctorMenuCommand, T.Menu.OpenDoctorMenu, {})
    RegisterCommand(Config.DoctorMenuCommand, openDoctorMenu, false)

    TriggerClientEvent("vorp_medic:Client:JobUpdate", target)
    local sourcename <const>, identifier <const>, steamname <const> = getSourceInfo(user, _source)
    local targetname <const>, identifier2 <const>, steamname2 <const> = getSourceInfo(targetUser, target)

    local description <const> = "**" .. Logs.Lang.HiredBy .. "** " .. sourcename .. "\n" .. "** " .. Logs.Lang.Steam .. "** " .. steamname .. "\n" .. "** "
        .. Logs.Lang.Identifier .. "** " .. identifier .. "\n" .. "** " .. Logs.Lang.PlayerID .. "** " .. _source .. "\n\n**" .. Logs.Lang.Job .. "** " .. label .. "\n\n" ..
        "**" .. Logs.Lang.HiredPlayer .. "** " .. targetname .. "\n" .. "** " .. Logs.Lang.Steam .. "** " .. steamname2 .. "\n" .. "** "
        .. Logs.Lang.Identifier .. "** " .. identifier2 .. "\n" .. "** " .. Logs.Lang.PlayerID .. "** " .. _source
    Core.AddWebhook(Logs.Lang.JobHired, Logs.Webhook, description, Logs.color, Logs.Namelogs, Logs.logo, Logs.footerlogo, Logs.avatar)
end)

--* FIRE PLAYER
RegisterNetEvent("vorp_medic:server:firePlayer", function(id)
    local _source <const> = source
    local user <const> = Core.getUser(_source)
    if not user then return end

    if not hasJob(user) then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotADoctor, 5000)
    end

    if not _canManageStaff(user) then
        return Core.NotifyObjective(_source, T.Menu.CantHire, 5000)
    end
    if (not Config.AllowBossSelfManage) and tonumber(id) == _source then
        return Core.NotifyObjective(_source, T.Menu.SelfManage, 5000)
    end

    local target <const> = id
    local targetUser <const> = Core.getUser(target)
    if not targetUser then return Core.NotifyObjective(_source, T.Player.NoPlayerFound, 5000) end

    local targetCharacter <const> = targetUser.getUsedCharacter
    local targetJob <const> = targetCharacter.job
    if not Config.MedicJobs[targetJob] then
        return Core.NotifyObjective(_source, T.Player.CantFirenotHired, 5000)
    end

    targetCharacter.setJob("unemployed", true)
    targetCharacter.setJobLabel("Unemployed", true)

    Core.NotifyObjective(target, T.Player.BeenFireed, 5000)
    Core.NotifyObjective(_source, T.Player.FiredPlayer, 5000)

    if isOnDuty(target) then
        Player(target).state:set('isMedicDuty', nil, true)
        DutyList[target] = nil
    end

    TriggerClientEvent("vorp_medic:Client:JobUpdate", target)
    local sourcename <const>, identifier <const>, steamname <const> = getSourceInfo(user, _source)
    local targetname <const>, identifier2 <const>, steamname2 <const> = getSourceInfo(targetUser, target)

    local description <const> = "**" .. Logs.Lang.FiredBy .. "** " .. sourcename .. "\n" .. "** " .. Logs.Lang.Steam .. "** " .. steamname .. "\n" .. "** " .. Logs.Lang.Identifier .. "** " .. identifier .. "\n" .. "** " .. Logs.Lang.PlayerID .. "** " .. _source ..
        "\n\n**" .. Logs.Lang.FromJob .. "** " .. targetJob .. "\n\n" .. "**" .. Logs.Lang.FiredPlayer .. "** " .. targetname .. "\n" .. "** " .. Logs.Lang.Steam .. "** " .. steamname2 .. "\n" .. "** " .. Logs.Lang.Identifier .. "** " .. identifier2 .. "\n" .. "** " .. Logs.Lang.PlayerID .. "** " .. target
    Core.AddWebhook(Logs.Lang.Jobfired, Logs.Webhook, description, Logs.color, Logs.Namelogs, Logs.logo, Logs.footerlogo, Logs.avatar)
end)



--* CHECK IF PLAYER IS ON DUTY
Core.Callback.Register("vorp_medic:server:checkDuty", function(source, CB, _)
    local user <const> = Core.getUser(source)
    if not user then return end

    if not hasJob(user) then
        return CB(false)
    end

    local sourcename <const>, identifier <const>, steamname <const> = getSourceInfo(user, source)
    local Character <const> = user.getUsedCharacter
    local Job <const> = Character.job
    local description = "**" .. Logs.Lang.Steam .. "** " .. steamname .. "\n" ..
        "**" .. Logs.Lang.Identifier .. "** " .. identifier .. "\n" ..
        "**" .. Logs.Lang.PlayerID .. "** " .. source .. "\n" ..
        "**" .. Logs.Lang.Job .. "** " .. Job .. "\n" ..
        "**" .. Logs.Lang.PlayerName .. "** " .. sourcename .. "\n"

    if not isOnDuty(source) then
        if not JobsToAlert[source] then
            JobsToAlert[source] = true
        end
        Player(source).state:set('isMedicDuty', true, true)
        DutyList[source] = true
        return CB(true)
    else
        if JobsToAlert[source] then
            JobsToAlert[source] = nil
        end
        Player(source).state:set('isMedicDuty', false, true)
        DutyList[source] = nil

        description = description .. "**" .. Logs.Lang.JobOffDuty .. "**"
        Core.AddWebhook(Logs.Lang.JobOffDuty, Logs.DutyWebhook, description, Logs.color, Logs.Namelogs, Logs.logo, Logs.footerlogo, Logs.Avatar)

        return CB(false)
    end
end)



--* ON PLAYER JOB CHANGE
AddEventHandler("vorp:playerJobChange", function(source, new, _)
    if not Config.MedicJobs[new] then return end
    TriggerClientEvent("vorp_medic:Client:JobUpdate", source)
end)

local function getClosestPlayer(source, isHeal)
    local players <const> = GetPlayers()
    local ent <const> = GetPlayerPed(source)
    local doctorCoords <const> = GetEntityCoords(ent)
    local closestDistance = math.huge
    local closestPlayer = nil

    for _, value in ipairs(players) do
        if tonumber(value) ~= source then
            local targetCoords <const> = GetEntityCoords(GetPlayerPed(value))
            local distance <const> = #(doctorCoords - targetCoords)
            if distance <= closestDistance then
                closestDistance = distance
                closestPlayer = value
            end
        end
    end

    -- allow medics to self heal?
    if isHeal and not closestPlayer then
        return source
    end

    return closestPlayer
end

CreateThread(function()
    for key, value in pairs(Config.Items) do
        Inv:registerUsableItem(key, function(data)
            local _source <const> = data.source
            Inv:closeInventory(_source)

            if value.mustBeOnDuty then
                if not isOnDuty(_source) then
                    return Core.NotifyObjective(_source, T.Duty.YouAreNotOnDuty, 5000)
                end
            end

            if value.revive then
                local closestPlayer <const> = getClosestPlayer(_source)
                if not closestPlayer then return Core.NotifyObjective(_source, T.Player.NoPlayerFoundToRevive, 5000) end

                local Character <const> = Core.getUser(closestPlayer).getUsedCharacter
                local dead <const> = Character.isdead
                if not dead then return Core.NotifyObjective(_source, T.Player.PlayerIsNotDead, 5000) end

                TriggerClientEvent("vorp_medic:Client:ReviveAnim", _source)
                SetTimeout(3000, function()
                    Core.Player.Revive(tonumber(closestPlayer))
                end)
            else
                local closestPlayer <const> = getClosestPlayer(_source, true)
                if not closestPlayer then return Core.NotifyObjective(_source, T.Player.NoPlayerFoundToRevive, 5000) end

                TriggerClientEvent("vorp_medic:Client:HealAnim", _source)
                TriggerClientEvent("vorp_medic:Client:HealPlayer", tonumber(closestPlayer), value.health, value.stamina)
            end

            Inv:subItemById(_source, data.item.id)
        end, GetCurrentResourceName())
    end
end)

--* ALERTS

local function isDoctorOnCall(source)
    if not next(PlayersAlerts) then return false, 0 end

    for _, value in pairs(PlayersAlerts) do
        if value == source then
            return true, value
        end
    end
    return false, 0
end

local function getDoctorFromCall(source)
    return PlayersAlerts[source] or 0
end

local function getPlayerFromCall(source)
    for key, value in pairs(PlayersAlerts) do
        if value == source then
            return key
        end
    end
    return 0
end

RegisterCommand(Config.AlertDoctorCommand, function(source)
    if PlayersAlerts[source] then
        return Core.NotifyRightTip(source, T.Error.AlreadyAlertedDoctors, 5000)
    end

    if not next(JobsToAlert) then
        return Core.NotifyRightTip(source, T.Error.NoDoctorsAvailable, 5000)
    end

    if Config.AllowOnlyDeadToAlert then
        local Character <const> = Core.getUser(source).getUsedCharacter
        local dead <const> = Character.isdead
        if not dead then
            return Core.NotifyObjective(source, T.Error.NotDeadCantAlert, 5000)
        end
    end

    local sourcePlayer <const> = GetPlayerPed(source)
    local sourceCoords <const> = GetEntityCoords(sourcePlayer)
    local closestDistance      = math.huge
    local closestDoctor        = nil

    for key, _ in pairs(JobsToAlert) do
        local player <const> = GetPlayerPed(key)
        local playerCoords <const> = GetEntityCoords(player)
        local distance <const> = #(sourceCoords - playerCoords)
        local isOnCall <const>, _ <const> = isDoctorOnCall(key)
        if not isOnCall then
            if distance < closestDistance then
                closestDistance = distance
                closestDoctor = key
            end
        end
    end

    if not closestDoctor then
        return Core.NotifyRightTip(source, T.Error.NoDoctorsAvailable, 5000)
    end

    Core.NotifyObjective(closestDoctor, T.Alert.PlayerNeedsHelp, 5000)
    TriggerClientEvent("vorp_medic:Client:AlertDoctor", closestDoctor, sourceCoords)
    Core.NotifyRightTip(source, T.Alert.DoctorsAlerted, 5000)
    PlayersAlerts[source] = closestDoctor
end, false)

--cancel alert for players
RegisterCommand(Config.cancelalert, function(source)
    if not PlayersAlerts[source] then
        return Core.NotifyRightTip(source, T.Error.NoAlertToCancel, 5000)
    end

    local doctor <const> = getDoctorFromCall(source)
    if doctor > 0 then
        local user <const> = Core.getUser(doctor) -- make sure is still in game
        if user then
            TriggerClientEvent("vorp_medic:Client:RemoveBlip", doctor)
            Core.NotifyObjective(doctor, T.Alert.AlertCanceledByPlayer, 5000)
        end
    end

    PlayersAlerts[source] = nil
    Core.NotifyRightTip(source, T.Alert.AlertCanceled, 5000)
end, false)


-- for doctors to finish alert
RegisterCommand(Config.finishalert, function(source)
    local _source <const> = source

    local hasJobs <const> = hasJob(Core.getUser(_source))
    if not hasJobs then
        return Core.NotifyObjective(_source, T.Jobs.YouAreNotADoctor, 5000)
    end

    local isDuty <const> = isOnDuty(_source)
    if not isDuty then
        return Core.NotifyObjective(_source, T.Duty.YouAreNotOnDuty, 5000)
    end

    local isOnCall <const>, doctor <const> = isDoctorOnCall(_source)
    if isOnCall and doctor > 0 then
        TriggerClientEvent("vorp_medic:Client:RemoveBlip", _source)
        Core.NotifyObjective(_source, T.Alert.AlertCanceled, 5000)
    else
        Core.NotifyObjective(_source, T.Error.NotOnCall, 5000)
    end

    local player <const> = getPlayerFromCall(_source)
    if player > 0 then
        Core.NotifyRightTip(player, T.Alert.AlertCanceledByDoctor, 5000)
        PlayersAlerts[player] = nil
    end
end, false)


--* ON PLAYER DROP
AddEventHandler("playerDropped", function()
    local _source = source

    local isOnCall <const>, doctor <const> = isDoctorOnCall(_source)
    if isOnCall and doctor > 0 then
        TriggerClientEvent("vorp_medic:Client:RemoveBlip", doctor)
        Core.NotifyObjective(doctor, T.Alert.PlayerDisconnectedAlertCanceled, 5000)
    end

    if DutyList[_source] then
        DutyList[_source] = nil
    end

    if JobsToAlert[_source] then
        JobsToAlert[_source] = nil
    end

    if PlayersAlerts[_source] then
        PlayersAlerts[_source] = nil
    end
end)

--* EXPORTS
-- ADD TO READ ME
exports("isOnDuty", function(source)
    return DutyList[source]
end)

exports("getDoctorFromCall", function(source)
    return getDoctorFromCall(source)
end)

--* Hire/Fire Employees / database fetch
local function db_fetch_all(sql, params, cb)
    if not (exports.oxmysql and exports.oxmysql.execute) then
        print("^1oxmysql not found (SELECT)^7")
        return cb({})
    end
    exports.oxmysql:execute(sql, params or {}, function(rows)
        cb(rows or {})
    end)
end

local function db_execute(sql, params, cb)
    if not (exports.oxmysql and exports.oxmysql.execute) then
        print("^1oxmysql not found (UPDATE)^7")
        if cb then cb(0) end
        return
    end
    exports.oxmysql:execute(sql, params or {}, function(affected)
        if cb then cb(affected or 0) end
    end)
end

RegisterNetEvent("vorp_medic:server:listEmployeesAll", function(jobFilter)
    local src = source
    local user = Core.getUser(src); if not user then return end

    if not _canManageStaff(user) then
        return Core.NotifyObjective(src, T.Menu.CantSeeEmployees, 5000)
    end
    if not (jobFilter and Config.MedicJobs[jobFilter]) then
        return Core.NotifyObjective(src, "Invalid job.", 5000)
    end

    local dutyByChar = {}
    for _, sid in ipairs(GetPlayers()) do
        local id = tonumber(sid)
        local u = Core.getUser(id)
        if u then
            local c = u.getUsedCharacter
            local cid = c and (c.charidentifier or c.charIdentifier)
            if cid then
                dutyByChar[tonumber(cid)] = (Player(id).state.isMedicDuty == true)
            end
        end
    end

    db_fetch_all(
        "SELECT charidentifier, firstname, lastname, job, joblabel, jobgrade FROM characters WHERE job = ?",
        { jobFilter },
        function(rows)
            local employees = {}
            for _, r in ipairs(rows or {}) do
                local cid = tonumber(r.charidentifier)
                employees[#employees+1] = {
                    charidentifier = cid,
                    firstname = r.firstname,
                    lastname = r.lastname,
                    job = r.job,
                    joblabel = r.joblabel,
                    jobgrade = r.jobgrade or 0,
                    onduty = dutyByChar[cid] == true,
                }
            end
            TriggerClientEvent("vorp_medic:client:EmployeesList", src, employees, jobFilter)
        end
    )
end)

RegisterNetEvent("vorp_medic:server:fireByCharId", function(charid, jobFilter)
    local src = source
    local user = Core.getUser(src); if not user then return end
    if not _canManageStaff(user) then
        return Core.NotifyObjective(src, T.Menu.OnlySeniorFire, 5000)
    end

    local mycid = (user.getUsedCharacter.charidentifier or user.getUsedCharacter.charIdentifier)
    if (not Config.AllowBossSelfManage) and tonumber(charid) == tonumber(mycid) then
        return Core.NotifyObjective(src, T.Menu.SelfManage, 5000)
    end

    -- if the player is online — synchronously update the state and give him a notification
    for _, sid in ipairs(GetPlayers()) do
        local id = tonumber(sid)
        local u = Core.getUser(id)
        if u then
            local c = u.getUsedCharacter
            local cid = c and (c.charidentifier or c.charIdentifier)
            if cid and tonumber(cid) == tonumber(charid) then
                c.setJob("unemployed", true)
                c.setJobLabel("Unemployed", true)
                if Player(id).state.isMedicDuty then
                    Player(id).state:set('isMedicDuty', nil, true)
                end
                Core.NotifyObjective(id, (T.Player and T.Player.BeenFireed), 5000)
                break
            end
        end
    end

    db_execute(
        "UPDATE characters SET job = ?, joblabel = ?, jobgrade = ? WHERE charidentifier = ? LIMIT 1",
        { "unemployed", "Unemployed", 0, tonumber(charid) },
        function(_)
            Core.NotifyObjective(src, (T.Player and T.Player.FiredPlayer) or "Employee fired.", 5000)
            -- immediately update the list in the menu if an active job filter is passed
            if jobFilter and Config.MedicJobs[jobFilter] then
                TriggerEvent("vorp_medic:server:listEmployeesAll", jobFilter)
            end
        end
    )
end)

RegisterNetEvent("vorp_medic:server:setGradeByCharId", function(charid, newGrade)
    local src = source
    local user = Core.getUser(src); if not user then return end

    if not _canManageStaff(user) then
        return Core.NotifyObjective(src, T.Menu.OnlySeniorManage, 5000)
    end
    local mycid = (user.getUsedCharacter.charidentifier or user.getUsedCharacter.charIdentifier)
    if (not Config.AllowBossSelfManage) and tonumber(charid) == tonumber(mycid) then
        return Core.NotifyObjective(src, T.Menu.SelfManage, 5000)
    end

    newGrade = tonumber(newGrade or 0) or 0
    if newGrade < 0 then newGrade = 0 end
    if newGrade > 3 then newGrade = 3 end

    db_fetch_all("SELECT charidentifier, firstname, lastname, job, joblabel, jobgrade FROM characters WHERE charidentifier = ? LIMIT 1",
        { tonumber(charid) },
        function(rows)
            local r = rows and rows[1]; if not r then return Core.NotifyObjective(src, T.Menu.NoCharacter, 4000) end

            local job = r.job
            local jobCfg = Config.MedicJobs[job]
            if not jobCfg then return Core.NotifyObjective(src, "Not a medic job.", 4000) end

            local oldGrade = tonumber(r.jobgrade or 0)
            local oldRank = (jobCfg.Ranks[oldGrade] and jobCfg.Ranks[oldGrade].name) or ("Grade " .. tostring(oldGrade))
            local newRank = (jobCfg.Ranks[newGrade] and jobCfg.Ranks[newGrade].name) or ("Grade " .. tostring(newGrade))

            local action = (newGrade > oldGrade) and "promoted" or ((newGrade < oldGrade) and "demoted" or "updated")
            local msgBoss = ("You %s %s %s to %s"):format(action, r.firstname or "", r.lastname or "", newRank)
            local msgTarget = (action == "promoted" and ("You have been promoted to: %s"):format(newRank))
                           or (action == "demoted" and ("You have been demoted to: %s"):format(newRank))
                           or ("Your rank was set to: %s"):format(newRank)

            -- update online player (label) + notify him
            local targetOnlineId
            for _, sid in ipairs(GetPlayers()) do
                local id = tonumber(sid)
                local u = Core.getUser(id)
                if u then
                    local c = u.getUsedCharacter
                    local cid = c and (c.charidentifier or c.charIdentifier)
                    if cid and tonumber(cid) == tonumber(charid) then
                        targetOnlineId = id
                        if c.setJobLabel then
                            c.setJobLabel(newRank, true)
                        end
                        Core.NotifyObjective(id, msgTarget, 5000)
                        break
                    end
                end
            end

            -- write to the database
            db_execute("UPDATE characters SET jobgrade = ?, joblabel = ? WHERE charidentifier = ? LIMIT 1",
                { newGrade, newRank, tonumber(charid) },
                function(a)
                    Core.NotifyObjective(src, msgBoss, 5000)
                    -- if the player is offline — at least the boss received confirmation
                end
            )
        end
    )
end)