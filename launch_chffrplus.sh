#!/usr/bin/bash

if [ -z "$BASEDIR" ]; then
  BASEDIR="/data/openpilot"
fi

source "$BASEDIR/launch_env.sh"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

function two_init {
  python /data/openpilot/scripts/installers/language_installer.py
  python /data/openpilot/scripts/installers/sshkey_installer.py
  python /data/openpilot/scripts/installers/font_installer.py
  mount -o remount,rw /system
  if [ ! -f /ONEPLUS ] && ! $(grep -q "letv" /proc/cmdline); then
    sed -i -e 's#/dev/input/event1#/dev/input/event2#g' ~/.bash_profile
    touch /ONEPLUS
  else
    if [ ! -f /LEECO ]; then
      touch /LEECO
    fi
  fi
  mount -o remount,r /system

  # set IO scheduler
  setprop sys.io.scheduler noop
  for f in /sys/block/*/queue/scheduler; do
    echo noop > $f
  done

  # *** shield cores 2-3 ***

  # TODO: should we enable this?
  # offline cores 2-3 to force recurring timers onto the other cores
  #echo 0 > /sys/devices/system/cpu/cpu2/online
  #echo 0 > /sys/devices/system/cpu/cpu3/online
  #echo 1 > /sys/devices/system/cpu/cpu2/online
  #echo 1 > /sys/devices/system/cpu/cpu3/online

  # android gets two cores
  echo 0-1 > /dev/cpuset/background/cpus
  echo 0-1 > /dev/cpuset/system-background/cpus
  echo 0-1 > /dev/cpuset/foreground/cpus
  echo 0-1 > /dev/cpuset/foreground/boost/cpus
  echo 0-1 > /dev/cpuset/android/cpus

  # openpilot gets all the cores
  echo 0-3 > /dev/cpuset/app/cpus

  # mask off 2-3 from RPS and XPS - Receive/Transmit Packet Steering
  echo 3 | tee  /sys/class/net/*/queues/*/rps_cpus
  echo 3 | tee  /sys/class/net/*/queues/*/xps_cpus

  # *** set up governors ***

  # +50mW offroad, +500mW onroad for 30% more RAM bandwidth
  echo "performance" > /sys/class/devfreq/soc:qcom,cpubw/governor
  echo 1056000 > /sys/class/devfreq/soc:qcom,m4m/max_freq
  echo "performance" > /sys/class/devfreq/soc:qcom,m4m/governor

  # unclear if these help, but they don't seem to hurt
  echo "performance" > /sys/class/devfreq/soc:qcom,memlat-cpu0/governor
  echo "performance" > /sys/class/devfreq/soc:qcom,memlat-cpu2/governor

  # GPU
  echo "performance" > /sys/class/devfreq/b00000.qcom,kgsl-3d0/governor

  # /sys/class/devfreq/soc:qcom,mincpubw is the only one left at "powersave"
  # it seems to gain nothing but a wasted 500mW

  # *** set up IRQ affinities ***

  # Collect RIL and other possibly long-running I/O interrupts onto CPU 1
  echo 1 > /proc/irq/78/smp_affinity_list # qcom,smd-modem (LTE radio)
  echo 1 > /proc/irq/33/smp_affinity_list # ufshcd (flash storage)
  echo 1 > /proc/irq/35/smp_affinity_list # wifi (wlan_pci)
  echo 1 > /proc/irq/6/smp_affinity_list  # MDSS

  # USB traffic needs realtime handling on cpu 3
  [ -d "/proc/irq/733" ] && echo 3 > /proc/irq/733/smp_affinity_list
  if [ -f /ONEPLUS ]; then
    [ -d "/proc/irq/736" ] && echo 3 > /proc/irq/736/smp_affinity_list # USB for OP3T
  fi

  # GPU and camera get cpu 2
  CAM_IRQS="177 178 179 180 181 182 183 184 185 186 192"
  for irq in $CAM_IRQS; do
    echo 2 > /proc/irq/$irq/smp_affinity_list
  done
  echo 2 > /proc/irq/193/smp_affinity_list # GPU

  # give GPU threads RT priority
  for pid in $(pgrep "kgsl"); do
    chrt -f -p 52 $pid
  done

  # the flippening!
  LD_LIBRARY_PATH="" content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:1

  # disable bluetooth
  service call bluetooth_manager 8

  # wifi scan
  wpa_cli IFNAME=wlan0 SCAN

  # Check for NEOS update
  if [ -f /LEECO ]; then
    if [ $(< /VERSION) != "$REQUIRED_NEOS_VERSION" ]; then
      if [ -f "$DIR/scripts/continue.sh" ]; then
        cp "$DIR/scripts/continue.sh" "/data/data/com.termux/files/continue.sh"
      fi

      if [ ! -f "$BASEDIR/prebuilt" ]; then
        # Clean old build products, but preserve the scons cache
        cd $DIR
        git clean -xdf
        git submodule foreach --recursive git clean -xdf
      fi

      "$DIR/installer/updater/updater" "file://$DIR/installer/updater/update.json"
    fi
  fi

  # One-time fix for a subset of OP3T with gyro orientation offsets.
  # Remove and regenerate qcom sensor registry. Only done on OP3T mainboards.
  # Performed exactly once. The old registry is preserved just-in-case, and
  # doubles as a flag denoting we've already done the reset.
  if [ -f /ONEPLUS ] && [ ! -f "/persist/comma/op3t-sns-reg-backup" ]; then
    echo "Performing OP3T sensor registry reset"
    mv /persist/sensors/sns.reg /persist/comma/op3t-sns-reg-backup &&
      rm -f /persist/sensors/sensors_settings /persist/sensors/error_log /persist/sensors/gyro_sensitity_cal &&
      echo "restart" > /sys/kernel/debug/msm_subsys/slpi &&
      sleep 5  # Give Android sensor subsystem a moment to recover
  fi
}

function tici_init {
  # wait longer for weston to come up
  if [ -f "$BASEDIR/prebuilt" ]; then
    sleep 3
  fi

  # setup governors
  sudo su -c 'echo "performance" > /sys/class/devfreq/soc:qcom,memlat-cpu0/governor'
  sudo su -c 'echo "performance" > /sys/class/devfreq/soc:qcom,memlat-cpu4/governor'

  # TODO: move this to agnos
  # network manager config
  nmcli connection modify --temporary lte gsm.auto-config yes
  nmcli connection modify --temporary lte gsm.home-only yes
  sudo rm -f /data/etc/NetworkManager/system-connections/*.nmmeta

  # set success flag for current boot slot
  sudo abctl --set_success

  # Check if AGNOS update is required
  if [ $(< /VERSION) != "$AGNOS_VERSION" ]; then
    AGNOS_PY="$DIR/selfdrive/hardware/tici/agnos.py"
    MANIFEST="$DIR/selfdrive/hardware/tici/agnos.json"
    if $AGNOS_PY --verify $MANIFEST; then
      sudo reboot
    fi
    $DIR/selfdrive/hardware/tici/updater $AGNOS_PY $MANIFEST
  fi
}

# jetpack 4.6
function jetson_init {
  # jetpack 4.6 has mode 8
  sudo nvpmodel -m 8

  # use performance governor
  sudo echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

  # run higher fan speed in case we need compilation
  sudo echo 200 > /sys/devices/pwm-fan/target_pwm

  # prevent throttling
  echo 7000 > /sys/devices/c250000.i2c/i2c-7/7-0040/iio:device0/crit_current_limit_0

  # use highest available cpu freq
  for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
    echo 1907200 > $i;
  done

  # gpu min set to highest
  sudo echo 1109250000 > /sys/devices/17000000.gv11b/devfreq/17000000.gv11b/min_freq

  # set IO scheduler
  for f in /sys/block/*/queue/scheduler; do
    echo noop > $f
  done

  # give nvargus-daemon higer priority
  for pid in $(pgrep "nvargus-daemon"); do
    chrt -f -p 52 $pid
  done

  # scale 4.3" 800x480 to 1920x1080
  if [ "$(xdpyinfo | awk '/dimensions/{print $2}')" == "800x480" ]; then
    xrandr --output HDMI-0 --mode 800x480 --scale 2.4x2.25
  fi

  # enable jetson mode
  echo -n 1 > /data/params/d/dp_jetson

  # disable blank screen etc.
  xset s off
  xset s noblank
  xset -dpms

  # hide mouse cursor
  unclutter -idle 0 &
}

function launch {
  # Remove orphaned git lock if it exists on boot
  [ -f "$DIR/.git/index.lock" ] && rm -f $DIR/.git/index.lock

  # Pull time from panda
  $DIR/selfdrive/boardd/set_time.py

  # Check to see if there's a valid overlay-based update available. Conditions
  # are as follows:
  #
  # 1. The BASEDIR init file has to exist, with a newer modtime than anything in
  #    the BASEDIR Git repo. This checks for local development work or the user
  #    switching branches/forks, which should not be overwritten.
  # 2. The FINALIZED consistent file has to exist, indicating there's an update
  #    that completed successfully and synced to disk.

  if [ -f "${BASEDIR}/.overlay_init" ]; then
#    find ${BASEDIR}/.git -newer ${BASEDIR}/.overlay_init | grep -q '.' 2> /dev/null
#    if [ $? -eq 0 ]; then
#      echo "${BASEDIR} has been modified, skipping overlay update installation"
#    else
      if [ -f "${STAGING_ROOT}/finalized/.overlay_consistent" ]; then
        if [ ! -d /data/safe_staging/old_openpilot ]; then
          echo "Valid overlay update found, installing"
          LAUNCHER_LOCATION="${BASH_SOURCE[0]}"

          mv $BASEDIR /data/safe_staging/old_openpilot
          mv "${STAGING_ROOT}/finalized" $BASEDIR
          cd $BASEDIR

          # Partial mitigation for symlink-related filesystem corruption
          # Ensure all files match the repo versions after update
          git reset --hard
          git submodule foreach --recursive git reset --hard

          echo "Restarting launch script ${LAUNCHER_LOCATION}"
          unset REQUIRED_NEOS_VERSION
          unset AGNOS_VERSION
          exec "${LAUNCHER_LOCATION}"
        else
          echo "openpilot backup found, not updating"
          # TODO: restore backup? This means the updater didn't start after swapping
        fi
      fi
#    fi
  fi

  # handle pythonpath
  ln -sfn $(pwd) /data/pythonpath
  export PYTHONPATH="$PWD:$PWD/pyextra"

  # dp - ignore chmod changes
  git -C $DIR config core.fileMode false

  # dp - apply custom patch
  if [ -f "/data/media/0/dp_patcher.py" ]; then
    python /data/media/0/dp_patcher.py
  fi
  # hardware specific init
  if [ -f /EON ]; then
    two_init
  elif [ -f /TICI ]; then
    tici_init
  elif [ -f /JETSON ]; then
    jetson_init
    # make sure we have right models
    if [ ! -f "$DIR/models/supercombo.onnx" ]; then
      rm -fr $DIR/models/*.dlc
      wget https://github.com/commaai/openpilot/raw/72a736f90e57a7d5845891ea34b17360b6f684d0/models/supercombo.onnx -O "$DIR/models/supercombo.onnx"
    fi
  fi

  # write tmux scrollback to a file
  tmux capture-pane -pq -S-1000 > /tmp/launch_log

  # start manager
  cd selfdrive/manager
  if [ -f /EON ]; then
    if [ ! -f "/system/comma/usr/lib/libgfortran.so.5.0.0" ]; then
      mount -o remount,rw /system
      tar -zxvf /data/openpilot/selfdrive/mapd/assets/libgfortran.tar.gz -C /system/comma/usr/lib/
      mount -o remount,r /system
    fi
    if [ ! -d "/system/comma/usr/lib/python3.8/site-packages/opspline" ]; then
      mount -o remount,rw /system
      tar -zxvf /data/openpilot/selfdrive/mapd/assets/opspline.tar.gz -C /system/comma/usr/lib/python3.8/site-packages/
      mount -o remount,r /system
    fi
    ./build.py && ./manager.py
  else
    ./custom_dep.py && ./build.py && ./manager.py
  fi
  # if broken, keep on screen error
  while true; do sleep 1; done
}

launch
