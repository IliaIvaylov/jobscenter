# VIP Menu System

A modern VIP reward system for FiveM servers compatible with both ESX and QBCore frameworks.

## Features

- **Modern UI**: Stunning gradient design with palm tree logo
- **Dual Framework Support**: Works with both ESX and QBCore
- **Monthly Rewards**: 
  - Money reward ($50,000 configurable)
  - Weapon reward (Carbine Rifle + ammo)
  - Vehicle reward (Adder Supercar, registered to garage)
- **Admin Commands**: `/givevip [playerID]` to grant VIP access
- **Player Commands**: `/vipmenu` to open the VIP menu
- **Claim Protection**: Each reward can only be claimed once per period
- **Database Integration**: Tracks VIP status and claimed rewards

## Installation

1. **Database Setup**: Execute the SQL queries in `sql/jobs.sql` to create the necessary tables:
   - `vip_players` - Stores VIP player data
   - `vip_claims` - Tracks claimed rewards

2. **Dependencies**: 
   - ESX or QBCore framework
   - MySQL/oxmysql resource

3. **Configuration**: Edit `vip_config.lua` to customize:
   - Reward amounts and items
   - UI colors and styling
   - Admin groups
   - Command names

## Usage

### For Players
- Use `/vipmenu` command to open the VIP rewards menu
- Click on any available reward to claim it
- Each reward can only be claimed once per month

### For Administrators
- Use `/givevip [playerID]` to grant VIP access to a player
- Players with VIP access can then use the `/vipmenu` command
- Admin groups are configurable in `vip_config.lua`

## Configuration

### Rewards Configuration
```lua
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
```

### UI Customization
```lua
VipConfig.UI = {
    logoUrl = 'https://cdn-icons-png.flaticon.com/512/2922/2922506.png',
    primaryColor = '#FF6B35', -- Orange
    secondaryColor = '#FF1B8E', -- Pink
    backgroundColor = 'rgba(26, 26, 46, 0.95)'
}
```

## Framework Support

The system automatically detects whether you're running ESX or QBCore:

- **ESX**: Uses `es_extended` exports and `owned_vehicles` table
- **QBCore**: Uses `qb-core` exports and `player_vehicles` table

## Database Tables

### vip_players
Stores VIP player information:
- `identifier`: Player identifier (ESX) or citizenid (QBCore)
- `is_vip`: VIP status (1 = active, 0 = inactive)
- `granted_by`: Admin who granted VIP access
- `granted_at`: Timestamp when VIP was granted

### vip_claims
Tracks claimed rewards:
- `identifier`: Player identifier
- `reward_type`: Type of reward ('money', 'weapon', 'vehicle')
- `reward_data`: JSON data about the claimed reward
- `claimed_at`: Timestamp when reward was claimed

## Screenshots

The VIP menu features a modern gradient design with:
- Orange to pink gradient background matching the palm tree theme
- Interactive reward cards with hover effects
- Clear visual feedback for claimed rewards
- Responsive design for different screen sizes

## Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/vipmenu` | Opens the VIP rewards menu | VIP players |
| `/givevip [playerID]` | Grants VIP access to a player | Admin only |

## Support

This VIP system integrates seamlessly with existing job management systems and provides a premium experience for server subscribers.