#!/usr/bin/bash

if [ -z "$BASEDIR" ]; then
  BASEDIR="/data/openpilot"
fi

source "$BASEDIR/launch_env.sh"
cp -f "$BASEDIR/installer/updater/update.zip" "/data/media/0/update.zip" || exit
pm disable ai.comma.plus.offroad
killall _ui
"$BASEDIR/installer/updater/updater" "file://$BASEDIR/installer/updater/oneplus.json"
