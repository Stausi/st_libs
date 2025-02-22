author "Stausi : shop.stausi.com"
documentation "https://docs.stausi.com/"
version "1.0.3"
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
	'assets/*.png'
}

shared_scripts {
	"init.lua"
}

client_scripts {
    'modules/interaction/client.lua',
}

st_libs {
	"framework-bridge",
	"inventory-bridge",
	"version-checker"
}