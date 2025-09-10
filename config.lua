Config = {}

-- Permission system
Config.AdminGroups = {
    'superadmin',
    'admin',
    'moderator'
}

-- Admin identifiers (respaldo si los grupos no funcionan)
Config.AdminIdentifiers = {
    'steam:165815c58dab0864b6fbc7f83a81cc3dda29331e',  -- Reemplaza con tu Steam ID
    'license:165815c58dab0864b6fbc7f83a81cc3dda29331e', -- Reemplaza con tu License
    'fivem:1002393',          -- Reemplaza con tu FiveM ID
    -- Añade más identifiers según necesites
    -- Para encontrar tu identifier, usa el comando /checkgroup después de instalar
}

-- Job categories
Config.JobCategories = {
    {name = 'legal', label = 'Legal Jobs', color = '#4CAF50'},
    {name = 'criminal', label = 'Criminal Jobs', color = '#F44336'},
    {name = 'delivery', label = 'Delivery Jobs', color = '#2196F3'},
    {name = 'gathering', label = 'Gathering Jobs', color = '#FF9800'},
    {name = 'service', label = 'Service Jobs', color = '#9C27B0'}
}

-- Default job settings
Config.DefaultJobSettings = {
    payment = 500,
    requiredLevel = 1,
    cooldown = 300, -- 5 minutes
    maxPlayers = 4
}

-- Commands
Config.Commands = {
    openMenu = 'jobmanager',
    createJob = 'createjob',
    deleteJob = 'deletejob'
}

-- Notifications
Config.UseESXNotify = true

-- Database table name
Config.TableName = 'custom_jobs'

-- Debug mode (para encontrar tu identifier)
Config.Debug = true