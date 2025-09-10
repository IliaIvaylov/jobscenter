-- VIP Menu Configuration
VipConfig = {}

-- Framework Settings
VipConfig.Framework = 'auto' -- 'auto', 'esx', 'qbcore'

-- Commands
VipConfig.Commands = {
    openMenu = 'vipmenu',
    giveVip = 'givevip'
}

-- VIP Rewards (monthly configurable)
VipConfig.Rewards = {
    weapon = {
        name = 'WEAPON_CARBINERIFLE',
        label = 'Carbine Rifle',
        ammo = 250,
        enabled = true
    },
    vehicle = {
        model = 'adder',
        label = 'Adder Supercar', 
        plate = 'VIP',
        enabled = true
    },
    money = {
        amount = 50000,
        label = '$50,000 Cash',
        enabled = true
    }
}

-- UI Settings
VipConfig.UI = {
    logoUrl = 'https://cdn-icons-png.flaticon.com/512/2922/2922506.png', -- Palm tree icon
    primaryColor = '#FF6B35', -- Orange
    secondaryColor = '#FF1B8E', -- Pink
    backgroundColor = 'rgba(26, 26, 46, 0.95)'
}

-- Admin Groups (for /givevip command)
VipConfig.AdminGroups = {
    'superadmin',
    'admin', 
    'moderator'
}

-- Database Settings
VipConfig.Database = {
    vipTable = 'vip_players',
    claimsTable = 'vip_claims'
}

-- Notifications
VipConfig.Notifications = {
    noAccess = 'You do not have VIP access!',
    alreadyClaimed = 'You have already claimed this reward!',
    rewardClaimed = 'VIP reward claimed successfully!',
    vipGranted = 'VIP access granted to player!',
    invalidPlayer = 'Invalid player ID!',
    noPermission = 'You do not have permission to use this command!'
}