ESX = exports["es_extended"]:getSharedObject()

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