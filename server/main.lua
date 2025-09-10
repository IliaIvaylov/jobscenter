ESX = exports["es_extended"]:getSharedObject()

-- Framework Detection
local QBCore = nil
local Framework = 'ESX'

-- Try to detect QBCore
pcall(function()
    QBCore = exports['qb-core']:GetCoreObject()
    if QBCore then
        Framework = 'QBCore'
        print('VIP Menu: QBCore framework detected')
    end
end)

if Framework == 'ESX' then
    print('VIP Menu: ESX framework detected')
end

-- Datos en memoria
local jobsData = {
    jobs = {},
    categories = {
        {name = "legal", label = "Legal", color = "#4CAF50"},
        {name = "illegal", label = "Illegal", color = "#f44336"},
        {name = "delivery", label = "Delivery", color = "#2196F3"},
        {name = "mining", label = "Mining", color = "#FF9800"},
        {name = "fishing", label = "Fishing", color = "#00BCD4"},
        {name = "farming", label = "Farming", color = "#8BC34A"}
    },
    statistics = {
        totalJobs = 0,
        activeJobs = 0,
        inactiveJobs = 0,
        totalCompletions = 0
    }
}

-- Cargar datos de la base de datos
function LoadJobsData()
    print('Loading jobs data from database...')
    MySQL.Async.fetchAll('SELECT * FROM custom_jobs ORDER BY created_at DESC', {}, function(result)
        jobsData.jobs = result or {}
        print('Loaded ' .. #jobsData.jobs .. ' jobs from database')
        UpdateStatistics()
    end)
end

-- Actualizar estadísticas
function UpdateStatistics()
    local stats = {
        totalJobs = #jobsData.jobs,
        activeJobs = 0,
        inactiveJobs = 0,
        totalCompletions = 0
    }
    
    for _, job in pairs(jobsData.jobs) do
        if job.is_active == 1 then
            stats.activeJobs = stats.activeJobs + 1
        else
            stats.inactiveJobs = stats.inactiveJobs + 1
        end
        stats.totalCompletions = stats.totalCompletions + (job.completions or 0)
    end
    
    jobsData.statistics = stats
    print('Statistics updated:', json.encode(stats))
end

-- Eventos del servidor
RegisterNetEvent('esx-job-manager:requestData', function()
    local src = source
    print('Data requested by player:', src)
    LoadJobsData()
    Wait(200) -- Pequeño delay para asegurar que los datos se carguen
    TriggerClientEvent('esx-job-manager:receiveData', src, jobsData)
    print('Data sent to player:', src)
end)

RegisterNetEvent('esx-job-manager:createJob', function(data)
    local src = source
    print('Creating job for player:', src)
    print('Job data received:', json.encode(data))
    
    -- Validar datos requeridos
    if not data.job_label or data.job_label == '' then
        TriggerClientEvent('esx:showNotification', src, '~r~Error: Job label is required')
        return
    end
    
    -- Establecer valores por defecto
    local jobName = (data.job_label or 'New Job'):lower():gsub(' ', '_')
    local jobLabel = data.job_label or 'New Job'
    local description = data.description or ''
    local category = data.category or 'legal'
    local payment = tonumber(data.payment) or 500
    local requiredLevel = tonumber(data.required_level) or 1
    local maxPlayers = tonumber(data.max_players) or 4
    local cooldown = tonumber(data.cooldown) or 300
    local blipSprite = tonumber(data.blip_sprite) or 280
    local blipColor = tonumber(data.blip_color) or 2
    local blipCoords = data.blip_coords or '{}'
    
    MySQL.Async.insert([[
        INSERT INTO custom_jobs (job_name, job_label, description, category, payment, 
                                required_level, max_players, cooldown, blip_sprite, 
                                blip_color, blip_coords, is_active, completions, created_at) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 0, NOW())
    ]], {
        jobName,
        jobLabel,
        description,
        category,
        payment,
        requiredLevel,
        maxPlayers,
        cooldown,
        blipSprite,
        blipColor,
        blipCoords
    }, function(insertId)
        if insertId then
            print('Job created successfully with ID:', insertId)
            TriggerClientEvent('esx:showNotification', src, '~g~Job created successfully!')
            TriggerClientEvent('esx-job-manager:jobCreated', src)
            -- Notificar a todos los clientes para actualizar blips
            TriggerClientEvent('esx-job-manager:jobCreated', -1)
        else
            print('Error creating job')
            TriggerClientEvent('esx:showNotification', src, '~r~Error creating job')
        end
    end)
end)

RegisterNetEvent('esx-job-manager:updateJob', function(jobId, jobData)
    local src = source
    print('Updating job:', jobId, 'for player:', src)
    print('Update data:', json.encode(jobData))
    
    local query = 'UPDATE custom_jobs SET '
    local params = {}
    local setParts = {}
    
    for key, value in pairs(jobData) do
        table.insert(setParts, key .. ' = ?')
        table.insert(params, value)
    end
    
    if #setParts > 0 then
        query = query .. table.concat(setParts, ', ') .. ' WHERE id = ?'
        table.insert(params, jobId)
        
        MySQL.Async.execute(query, params, function(affectedRows)
            if affectedRows > 0 then
                print('Job updated successfully')
                TriggerClientEvent('esx:showNotification', src, '~g~Job updated successfully!')
                TriggerClientEvent('esx-job-manager:jobUpdated', src)
                TriggerClientEvent('esx-job-manager:jobUpdated', -1)
            else
                print('No rows affected when updating job')
                TriggerClientEvent('esx:showNotification', src, '~r~Error updating job')
            end
        end)
    end
end)

RegisterNetEvent('esx-job-manager:deleteJob', function(jobId)
    local src = source
    print('Deleting job:', jobId, 'for player:', src)
    
    MySQL.Async.execute('DELETE FROM custom_jobs WHERE id = ?', {jobId}, function(affectedRows)
        if affectedRows > 0 then
            print('Job deleted successfully')
            TriggerClientEvent('esx:showNotification', src, '~g~Job deleted successfully!')
            TriggerClientEvent('esx-job-manager:jobDeleted', src)
            TriggerClientEvent('esx-job-manager:jobDeleted', -1)
        else
            print('No rows affected when deleting job')
            TriggerClientEvent('esx:showNotification', src, '~r~Error deleting job')
        end
    end)
end)

RegisterNetEvent('esx-job-manager:toggleJobStatus', function(jobId, isActive)
    local src = source
    print('Toggling job status:', jobId, 'to', isActive, 'for player:', src)
    
    MySQL.Async.execute('UPDATE custom_jobs SET is_active = ? WHERE id = ?', {
        isActive and 1 or 0, jobId
    }, function(affectedRows)
        if affectedRows > 0 then
            print('Job status updated successfully')
            TriggerClientEvent('esx:showNotification', src, '~g~Job status updated!')
            TriggerClientEvent('esx-job-manager:jobUpdated', src)
            TriggerClientEvent('esx-job-manager:jobUpdated', -1)
        else
            print('No rows affected when toggling job status')
            TriggerClientEvent('esx:showNotification', src, '~r~Error updating job status')
        end
    end)
end)

-- Comando para abrir el menú
RegisterCommand('jobmanager', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' then
        print('Opening job manager for admin:', source)
        TriggerClientEvent('esx-job-manager:openMenu', source)
    else
        TriggerClientEvent('esx:showNotification', source, '~r~No tienes permisos para usar este comando')
    end
end, false)

-- Inicializar datos al cargar el recurso
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('Jobs resource starting...')
        Wait(2000) -- Esperar a que MySQL esté listo
        LoadJobsData()
        print('Jobs resource started successfully')
    end
end)

-- VIP MENU SYSTEM FUNCTIONS

-- Get player object based on framework
function GetPlayer(src)
    if Framework == 'ESX' then
        return ESX.GetPlayerFromId(src)
    elseif Framework == 'QBCore' then
        return QBCore.Functions.GetPlayer(src)
    end
    return nil
end

-- Get player identifier
function GetPlayerIdentifier(src)
    local player = GetPlayer(src)
    if Framework == 'ESX' then
        return player and player.identifier or nil
    elseif Framework == 'QBCore' then
        return player and player.PlayerData.citizenid or nil
    end
    return nil
end

-- Check if player is admin
function IsPlayerAdmin(src)
    local player = GetPlayer(src)
    if not player then return false end
    
    if Framework == 'ESX' then
        local group = player.getGroup()
        for _, adminGroup in pairs(VipConfig.AdminGroups) do
            if group == adminGroup then return true end
        end
    elseif Framework == 'QBCore' then
        local perms = QBCore.Functions.GetPermission(src)
        for _, adminGroup in pairs(VipConfig.AdminGroups) do
            if perms[adminGroup] then return true end
        end
    end
    return false
end

-- Check if player has VIP access
function HasVipAccess(identifier)
    local result = MySQL.Sync.fetchAll('SELECT * FROM vip_players WHERE identifier = ? AND is_vip = 1', {identifier})
    return result and #result > 0
end

-- Check if player has claimed a specific reward
function HasClaimedReward(identifier, rewardType)
    local result = MySQL.Sync.fetchAll('SELECT * FROM vip_claims WHERE identifier = ? AND reward_type = ?', {identifier, rewardType})
    return result and #result > 0
end

-- Give money to player
function GiveMoney(src, amount)
    local player = GetPlayer(src)
    if not player then return false end
    
    if Framework == 'ESX' then
        player.addMoney(amount)
    elseif Framework == 'QBCore' then
        player.Functions.AddMoney('cash', amount)
    end
    return true
end

-- Give weapon to player
function GiveWeapon(src, weapon, ammo)
    local player = GetPlayer(src)
    if not player then return false end
    
    if Framework == 'ESX' then
        player.addWeapon(weapon, ammo or 0)
    elseif Framework == 'QBCore' then
        -- For QBCore, we need to use the proper item system
        local hasWeapon = player.Functions.AddItem(weapon:lower(), 1)
        if hasWeapon and ammo and ammo > 0 then
            -- Add appropriate ammo based on weapon type
            local ammoType = 'pistol_ammo' -- Default, could be made configurable
            if weapon:find('RIFLE') then
                ammoType = 'rifle_ammo'
            elseif weapon:find('SMG') then
                ammoType = 'smg_ammo'
            elseif weapon:find('SHOTGUN') then
                ammoType = 'shotgun_ammo'
            end
            player.Functions.AddItem(ammoType, ammo)
        end
        return hasWeapon
    end
    return true
end

-- Give vehicle to player
function GiveVehicle(src, model, plate)
    local player = GetPlayer(src)
    if not player then return false end
    
    local identifier = GetPlayerIdentifier(src)
    if not identifier then return false end
    
    local finalPlate = plate .. math.random(100, 999)
    
    -- For ESX, add to owned_vehicles table
    if Framework == 'ESX' then
        local vehicleProps = {
            model = GetHashKey(model),
            plate = finalPlate,
            bodyHealth = 1000,
            engineHealth = 1000,
            tankHealth = 1000,
            fuelLevel = 100
        }
        
        MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)', {
            identifier,
            finalPlate,
            json.encode(vehicleProps)
        })
    elseif Framework == 'QBCore' then
        -- For QBCore, add to player_vehicles table
        local vehicleProps = {
            model = model,
            plate = finalPlate,
            garage = 'pillboxgarage',
            fuel = 100,
            engine = 1000,
            body = 1000,
            state = 1
        }
        
        MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            'license:' .. GetPlayerIdentifiers(src)[1],
            identifier,
            model,
            GetHashKey(model),
            json.encode(vehicleProps),
            finalPlate,
            'pillboxgarage',
            1
        })
    end
    
    return true
end

-- VIP EVENTS

-- Request VIP menu data
RegisterNetEvent('vip-menu:requestData', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if not identifier then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.invalidPlayer, 'error')
        return
    end
    
    local hasVip = HasVipAccess(identifier)
    if not hasVip then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.noAccess, 'error')
        return
    end
    
    -- Get claimed rewards
    local claimedRewards = {}
    for rewardType, _ in pairs(VipConfig.Rewards) do
        claimedRewards[rewardType] = HasClaimedReward(identifier, rewardType)
    end
    
    local data = {
        rewards = VipConfig.Rewards,
        claimed = claimedRewards,
        ui = VipConfig.UI
    }
    
    TriggerClientEvent('vip-menu:receiveData', src, data)
end)

-- Claim VIP reward
RegisterNetEvent('vip-menu:claimReward', function(rewardType)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    -- Validate reward type
    if not rewardType or type(rewardType) ~= 'string' then
        TriggerClientEvent('vip-menu:showNotification', src, 'Invalid reward type!', 'error')
        return
    end
    
    -- Check if reward type is valid
    if not VipConfig.Rewards[rewardType] then
        TriggerClientEvent('vip-menu:showNotification', src, 'Invalid reward type!', 'error')
        return
    end
    
    if not identifier then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.invalidPlayer, 'error')
        return
    end
    
    local hasVip = HasVipAccess(identifier)
    if not hasVip then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.noAccess, 'error')
        return
    end
    
    if HasClaimedReward(identifier, rewardType) then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.alreadyClaimed, 'error')
        return
    end
    
    local reward = VipConfig.Rewards[rewardType]
    if not reward or not reward.enabled then
        TriggerClientEvent('vip-menu:showNotification', src, 'This reward is not available!', 'error')
        return
    end
    
    local success = false
    local rewardData = {}
    
    if rewardType == 'money' then
        success = GiveMoney(src, reward.amount)
        rewardData = {amount = reward.amount}
    elseif rewardType == 'weapon' then
        success = GiveWeapon(src, reward.name, reward.ammo)
        rewardData = {weapon = reward.name, ammo = reward.ammo}
    elseif rewardType == 'vehicle' then
        success = GiveVehicle(src, reward.model, reward.plate)
        rewardData = {model = reward.model, plate = reward.plate}
    end
    
    if success then
        -- Record the claim
        MySQL.Async.execute('INSERT INTO vip_claims (identifier, reward_type, reward_data) VALUES (?, ?, ?)', {
            identifier,
            rewardType,
            json.encode(rewardData)
        }, function(affectedRows)
            if affectedRows and affectedRows > 0 then
                TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.rewardClaimed, 'success')
                TriggerClientEvent('vip-menu:rewardClaimed', src, rewardType)
            else
                print('Warning: Failed to record VIP claim for player ' .. src)
            end
        end)
    else
        TriggerClientEvent('vip-menu:showNotification', src, 'Failed to give reward!', 'error')
    end
end)

-- Give VIP access command
RegisterCommand(VipConfig.Commands.giveVip, function(source, args, rawCommand)
    local src = source
    
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.noPermission, 'error')
        return
    end
    
    if not args[1] then
        TriggerClientEvent('vip-menu:showNotification', src, 'Usage: /' .. VipConfig.Commands.giveVip .. ' [playerID]', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local targetPlayer = GetPlayer(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.invalidPlayer, 'error')
        return
    end
    
    local targetIdentifier = GetPlayerIdentifier(targetId)
    local adminIdentifier = GetPlayerIdentifier(src)
    
    -- Check if player already has VIP
    if HasVipAccess(targetIdentifier) then
        TriggerClientEvent('vip-menu:showNotification', src, 'Player already has VIP access!', 'error')
        return
    end
    
    -- Grant VIP access
    MySQL.Async.execute('INSERT INTO vip_players (identifier, granted_by) VALUES (?, ?) ON DUPLICATE KEY UPDATE is_vip = 1, granted_by = ?, granted_at = NOW()', {
        targetIdentifier,
        adminIdentifier,
        adminIdentifier
    }, function(affectedRows)
        if affectedRows > 0 then
            TriggerClientEvent('vip-menu:showNotification', src, VipConfig.Notifications.vipGranted, 'success')
            TriggerClientEvent('vip-menu:showNotification', targetId, 'You have been granted VIP access!', 'success')
        else
            TriggerClientEvent('vip-menu:showNotification', src, 'Failed to grant VIP access!', 'error')
        end
    end)
end, false)