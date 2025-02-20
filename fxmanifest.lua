author "Stausi : shop.stausi.com"
documentation "https://docs.stausi.com/"
version "1.0.2"
package_id "1"

fx_version "adamant"
game "gta5"
lua54 "yes"

files {
	"init.lua",
	"modules/**.lua",
}

shared_scripts {
	"init.lua"
}

st_libs {
	"framework-bridge",
	"inventory-bridge",
	"version-checker"
}