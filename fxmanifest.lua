fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ash_vipdaily'
author 'ASH City'
description 'Récompenses VIP — ASH City'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
    'bridge/shared.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

-- Le framework (qb-core, qbx_core ou es_extended) est détecté automatiquement :
-- il doit simplement être démarré avant cette ressource dans server.cfg.
dependencies {
    'ox_lib',
    'oxmysql',
}
