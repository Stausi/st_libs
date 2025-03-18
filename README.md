<p align="center">
  A open source libary for Stausi Scripts. You can also integrate your own scripts if you want.
</p>

<p align="center">
  <a href="https://github.com/Stausi/st_libs/releases/tag/v1.0.0"><img alt="Latest release" src="https://img.shields.io/github/v/release/Stausi/st_libs?logo=github"/></a>
  <a href="https://github.com/Stausi/st_libs/releases/latest/download/st_libs.zip"><img alt="Total download" src="https://img.shields.io/github/downloads/Stausi/st_libs/total"/></a>
  <img alt="License" src="https://img.shields.io/github/license/Stausi/st_libs"/>
</p>

---

## Linden

A big shoutout to (Linden)[https://github.com/overextended] for his work on ox_lib, which has been a great inspiration and foundation for many features in this library. While a lot of ox_lib is used for better compatibility with Stausi Scripts, many parts of this library are also unique and tailored specifically for our needs. If you don't need my specialised features, please visit [ox_lib](https://github.com/overextended/ox_lib)

## 📚 Documentation

For the full documentation, visit [docs.stausi.com](https://docs.stausi.com/st_libs).

## 🧷 Modules

## ❔ Usage
1. To use libraries, add the initiator as a shared script inside of your **fxmanifest.lua** file.
```lua
shared_scripts {
  '@st_libs/init.lua'
}
```
2. List modules you want use inside the **fxmanifest.lua** (in lowercase)
 ```lua
st_libs {
  'print',
  'table',
}
```
3. You can now use the libraries inside of your resource with the st global variable.

## 👥 Community

For help, discussion, support or any other conversations:
[Join the Stausis Discord Server](https://discord.gg/nKsErtYmek)

## ➕ Contributing

If you're interested in constributing to Stausi Libraries, please open a [new PR](https://github.com/Stausi/st_libs/pulls).

