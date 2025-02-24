author "Stausi : shop.stausi.com"
documentation "https://docs.stausi.com/"
version "1.0.6"
package_id "1"

fx_version "adamant"
game "gta5"
lua54 "yes"

ui_page 'web/build/index.html'

files {
	"init.lua",
	"modules/**.lua",
	'web/build/index.html',
    'web/build/**/*',
	'assets/*.png',
    'locales/*.json',
}

shared_scripts {
	'resource/init.lua',
    'resource/**/shared.lua',
}

client_scripts {
    'resource/**/client.lua',
}

server_scripts {
    'modules/filesInDirectory/server.lua',
    'modules/version-checker/server.lua',
    'resource/**/server.lua',
}
