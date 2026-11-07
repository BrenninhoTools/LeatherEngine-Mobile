# Building the game

Step 1. [Install git-scm](https://git-scm.com/downloads) if you don't have it already.

Step 2. [Install Haxe 4.3.7](https://haxe.org/download/version/4.3.7/)

Step 3. Run these commands to install the libraries required (the same pinned versions the CI uses, see `.github/scripts/install-libs.sh`):

```
haxelib install hxcpp 4.3.2
haxelib install lime 8.1.3
haxelib install openfl 9.3.4
haxelib install flixel 5.2.2
haxelib install flixel-addons 3.0.2
haxelib install flixel-ui 2.5.0
haxelib install hscript 2.5.0
haxelib install thx.semver 0.2.2
haxelib install polymod 1.7.0 --skip-dependencies
haxelib install hxvlc 2.3.1 --skip-dependencies
haxelib git flixelTextureAtlas https://github.com/Smokey555/Flixel-TextureAtlas 4c6c8e1529156e753937ad13cd28f189f0cbc218
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit daf0664aee99aa8b8d6bdd1eda993a1c3a399067
haxelib git extension-androidtools https://github.com/MAJigsaw77/extension-androidtools 4ef308412a7ae88a60862d1e97a4aa34765b1dcc
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
```

`discord_rpc` is only needed for desktop builds and `extension-androidtools` only for Android.

## Android

* Android SDK + NDK r21e
* Java 17
* `haxelib run lime setup android` (point it to your SDK, NDK and Java)
* `haxelib run lime build android`

Only ARM64 is built. Mods, replays and crash logs live in the storage folder picked in `Options > Mobile > Storage` (default `Android/data/com.leather128.funkin/files`). The bundled mods are copied there on the first launch.

## iOS

* macOS with Xcode
* `haxelib run lime build ios`

Mods, replays and crash logs live in the app's Documents folder, reachable from the Files app.

## Windows

Install Visual Studio Community 2019, and while installing instead of selecting the normal options, only select these components in the 'individual components' instead (or the closest equivalents).

```txt
* MSVC v142 - VS 2019 C++ x64/x86 build tools
* Windows 10 SDK (Latest)
```

## Linux

In your package manager, install the following packages:

```sh
sudo apt-get install libvlc-dev libvlccore-dev vlc-bin luajit
```

Step 4. Run `haxelib run lime test [platform]` in the project directory while replacing '[platform]' with your build target (`android`, `ios`, `windows`, `linux`, `mac`).
