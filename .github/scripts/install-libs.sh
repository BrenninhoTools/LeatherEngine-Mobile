#!/bin/sh
set -e

haxelib install hxcpp 4.3.2 --quiet --never
haxelib install lime 8.1.3 --quiet --never
haxelib install openfl 9.3.4 --quiet --never
haxelib install flixel 5.2.2 --quiet --never
haxelib install flixel-addons 3.0.2 --quiet --never
haxelib install flixel-ui 2.5.0 --quiet --never
haxelib install hscript 2.5.0 --quiet --never
haxelib install thx.semver 0.2.2 --quiet --never
haxelib install polymod 1.7.0 --quiet --skip-dependencies --never
haxelib install hxvlc 2.3.1 --quiet --skip-dependencies --never
haxelib git flixelTextureAtlas https://github.com/Smokey555/Flixel-TextureAtlas 4c6c8e1529156e753937ad13cd28f189f0cbc218 --quiet --never
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit daf0664aee99aa8b8d6bdd1eda993a1c3a399067 --quiet --never
haxelib git extension-androidtools https://github.com/MAJigsaw77/extension-androidtools 4ef308412a7ae88a60862d1e97a4aa34765b1dcc --quiet --never

haxelib set hxcpp 4.3.2 --never
haxelib set lime 8.1.3 --never
haxelib set openfl 9.3.4 --never
haxelib set flixel 5.2.2 --never
haxelib set hscript 2.5.0 --never

haxelib list
