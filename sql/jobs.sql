CREATE TABLE IF NOT EXISTS `custom_jobs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `job_name` varchar(100) NOT NULL,
    `job_label` varchar(100) NOT NULL,
    `description` text DEFAULT NULL,
    `category` varchar(50) DEFAULT 'legal',
    `payment` int(11) DEFAULT 500,
    `required_level` int(11) DEFAULT 1,
    `required_items` text DEFAULT NULL,
    `reward_items` text DEFAULT NULL,
    `coordinates` text DEFAULT NULL,
    `blip_sprite` int(11) DEFAULT 280,
    `blip_color` int(11) DEFAULT 2,
    `max_players` int(11) DEFAULT 4,
    `cooldown` int(11) DEFAULT 300,
    `is_active` tinyint(1) DEFAULT 1,
    `created_by` varchar(50) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `job_name` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `custom_job_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `job_id` int(11) NOT NULL,
    `player_identifier` varchar(50) NOT NULL,
    `times_completed` int(11) DEFAULT 1,
    `total_earned` int(11) DEFAULT 0,
    `last_completed` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`job_id`) REFERENCES `custom_jobs`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- VIP Menu System Tables
CREATE TABLE IF NOT EXISTS `vip_players` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `is_vip` tinyint(1) DEFAULT 1,
    `granted_by` varchar(50) DEFAULT NULL,
    `granted_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `expires_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `vip_claims` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `reward_type` varchar(20) NOT NULL, -- 'weapon', 'vehicle', 'money'
    `reward_data` text DEFAULT NULL,
    `claimed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_claim` (`identifier`, `reward_type`),
    KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;