#!/bin/zsh
create-dmg \
  --volname "QSOLog Installer" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "qsolog.app" 200 190 \
  --hide-extension "qsolog.app" \
  --app-drop-link 600 190 \
  "build/qsolog.dmg" \
  "build/macos/Build/Products/Release/qsolog.app"
