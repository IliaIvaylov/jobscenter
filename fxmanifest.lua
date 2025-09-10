fx_version 'cerulean'
game 'gta5'

name 'jobs'
author 'IliaIvaylov'
description 'ESX Job Manager - Manage Jobs Easily from In-Game!'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/assets/*'
}

dependencies {
    'es_extended',
    'oxmysql'
}