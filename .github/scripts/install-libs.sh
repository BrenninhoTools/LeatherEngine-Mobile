#!/bin/sh
set -e

HXCPP_VERSION=4.3.184

curl -sSL -o "${RUNNER_TEMP:-/tmp}/hxcpp.zip" "https://github.com/HaxeFoundation/hxcpp/releases/download/v$HXCPP_VERSION/hxcpp-$HXCPP_VERSION.zip"
haxelib install "${RUNNER_TEMP:-/tmp}/hxcpp.zip" --quiet --never

haxelib install lime 8.3.2 --quiet --never
haxelib install openfl 9.5.2 --quiet --never
haxelib install flixel 6.2.1 --quiet --never
haxelib install flixel-addons 4.0.1 --quiet --never
haxelib install hscript 2.7.0 --quiet --never
haxelib install polymod 2.0.0 --quiet --never
haxelib install hxvlc 2.3.2 --quiet --skip-dependencies --never
haxelib git flixel-ui https://github.com/HaxeFlixel/flixel-ui ff2f30148cb1a7c9b10373aa89cf1e0d7aafb648 --quiet --never
haxelib git flixelTextureAtlas https://github.com/Smokey555/Flixel-TextureAtlas 4c6c8e1529156e753937ad13cd28f189f0cbc218 --quiet --never
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit daf0664aee99aa8b8d6bdd1eda993a1c3a399067 --quiet --never
haxelib git extension-androidtools https://github.com/MAJigsaw77/extension-androidtools 4ef308412a7ae88a60862d1e97a4aa34765b1dcc --quiet --never

haxelib set lime 8.3.2 --never
haxelib set openfl 9.5.2 --never
haxelib set flixel 6.2.1 --never
haxelib set flixel-addons 4.0.1 --never
haxelib set hscript 2.7.0 --never
haxelib set polymod 2.0.0 --never

haxelib list
