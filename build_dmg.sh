#!/bin/bash

set -e

xcodebuild -project Fluxwall.xcodeproj -scheme Fluxwall -configuration Release -derivedDataPath build clean build

APP_PATH="build/Build/Products/Release/Fluxwall.app"
DMG_PATH="Fluxwall.dmg"

rm -f "$DMG_PATH"

mkdir -p dmg_temp
cp -R "$APP_PATH" dmg_temp/
ln -s /Applications dmg_temp/Applications

hdiutil create -volname "Fluxwall" -srcfolder dmg_temp -ov -format UDZO "$DMG_PATH"

rm -rf dmg_temp
