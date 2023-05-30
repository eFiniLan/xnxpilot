***Warning***
=======================
Do not waste time & money on this if you are not familiar with linux and openpilot, debug skill required. 

---

Table of Contents
=======================

* [What is openpilot?](#what-is-openpilot)
* [About this](#about-this)
* [To do](#to-do)
* [Hardware preparation](#hardware-preparation)
* [Software preparation](#software-preparation)
* [Installation](#installation)
* [Jetson useful links](#jetson-useful-links)
* [Openpilot patch](#openpilot-patch)
* [To run](#to-run)
* [Tuning](#tuning)
* [Credits](#credits)

---

What is openpilot?
------
[openpilot](http://github.com/commaai/openpilot) is an open source driver assistance system. Currently, openpilot performs the functions of Adaptive Cruise Control (ACC), Automated Lane Centering (ALC), Forward Collision Warning (FCW) and Lane Departure Warning (LDW) for a growing variety of supported [car makes, models and model years](#supported-cars). In addition, while openpilot is engaged, a camera based Driver Monitoring (DM) feature alerts distracted and asleep drivers.

About this
------
This project is to showcase how to run openpilot on Nvidia Jetson Xavier NX with minimal changes to openpilot.

The video was recorded on commit [22cf2e6440ca004994f30b7b9e8d0c20de35c52a](https://github.com/commaai/openpilot/tree/22cf2e6440ca004994f30b7b9e8d0c20de35c52a) on 17/05/2021 (v0.8.4). 

Simulation:
<table>
  <tr>
    <td><a href="https://youtu.be/ubxSSLWqyt8" title="YouTube" rel="noopener"><img src="http://i3.ytimg.com/vi/ubxSSLWqyt8/hqdefault.jpg"></a></td>
  </tr>
</table>

On road:
<table>
  <tr>
    <td><a href="https://youtu.be/RqoTT5m4Kp8" title="YouTube" rel="noopener"><img src="http://i3.ytimg.com/vi/RqoTT5m4Kp8/hqdefault.jpg"></a></td>
  </tr>
</table>

---

To do
------
- [x] Create build scripts.
- [x] Add patch samples/tutorials.
- [x] On road tests.
- [ ] Add sensor support.
- [ ] Tuning tutorials.

---

Hardware preparation
------
- [Nvidia Jetson Xavier NX](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-xavier-nx/)
- 32GB+ microsd card (UHS 3 speed minimum)
- [Waveshare IMX 219-83 Stereo Camera](https://www.waveshare.com/IMX219-83-Stereo-Camera.htm)
- [comma.ai Black Panda](https://comma.ai/shop/products/panda) (or white/grey panda but require more code customization.)
---

Software preparation
------
- Jetpack 4.5.1

---

Installation
------
1) [Install ubuntu 18.04 / Jetpack 4.5.1 on to sdcard](https://developer.nvidia.com/embedded/learn/get-started-jetson-xavier-nx-devkit)
- While installing, use username "**openpilot**".
2) clone this repo to your home directory (e.g. ```cd ~/ && git clone https://github.com/efinilan/xnxpilot.git```)
3) run: ```cd ~/xnxpilot/ && ./1_install.sh``` wait for reboot.
4) run: ```cd ~/xnxpilot/ && ./2_install.sh``` wait for reboot.
5) run: ```cd ~/xnxpilot/ && ./3_install.sh``` wait for reboot.
6) run: ```cd ~/xnxpilot/ && ./4_install.sh``` wait for reboot.
7) Completed, this should be the minimal configuration to run openpilot on Jetson.

---

Jetson useful links
------
Here are a few useful links I found that can potentially improve Jetson performance.

- [Useful tips before using Jetson Series(Nano, TX2, Xavier NX, Xavier)](https://spyjetson.blogspot.com/2019/09/jetson-nano-useful-tips-before-you.html{)
- [Script to remove unnecessary stuffs from the Jetson to save disk space (WIP)](https://gist.github.com/adujardin/c0ee25cfb343ea5b6d17ea88ec6634ac)
- [Scripts to help build the 4.9.201 kernel and modules onboard the Jetson Xavier NX (L4T 32.5.1, JetPack 4.5.1).](https://github.com/jetsonhacks/buildJetsonXavierNXKernel)
- [Jetson hacks](https://www.jetsonhacks.com/)
- [Jetson kernel customization](https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/kernel_custom.html)


---

Openpilot patches
------
This is based on the openpilot master branch and is constantly changing, so there is no patch that works all the time.
Here I will explain why these files are changed so you can update the patches in the future.

**Notes**: All the sample patches below are based on commit [22cf2e6440ca004994f30b7b9e8d0c20de35c52a](https://github.com/commaai/openpilot/tree/22cf2e6440ca004994f30b7b9e8d0c20de35c52a) on 17/05/2021 (v0.8.4).


#### patches/1_SConstruct.diff
This file patches ```SConstruct``` file in the openpilot root folder.
Here we:
1) Create a new ```arch``` called ```linuxarm64``` so the reset of the modules will not mis-identify your board as ```aarch64``` or ```larch64``` used by comma.ai's board.
2) Setup the right environment path/variables, since it's not ```aarch64``` or ```larch64```, the default configuration uses x64/x86 architecure, however, jetson is arm64 (aarch64) based, so we have to utilize a few libraries from ```larch64``` configuration.

#### patches/2_selfdrive-crash.py.diff
This file patches ```selfdrive/crash.py``` so it does not use sentry.io library
Noted openpilot has plan to deprecate sentry.io service so the file may not exist in the future.
Here we:
1) keep all the function/method and simply ```pass``` the logic.
2) remove everything related to sentry sdk

#### 3_selfdrive-manager-manager.py.diff
This file patches ```selfdrive/manager/manager.py``` so it bypass comma.ai registration
Here we:
1) Simply give "```00000```" (or whatever you wish) as your dongle_id

#### 4_selfdrive-manager-process_config.py.diff
This file patches ```selfdrive/manager/process_config.py``` to disable several CPU intense processes.
Here we:
1) Disable service including: ```manage_athenad```, ```logcatd```, ```loggerd```, ```logmessaged```, ```updated```, ```uploader```

#### 5_selfdrive-thermald-thermald.py.diff
This file patches ```selfdrive/thermald/thermald.py``` to turn into onroad mode right away.
This is for testing the system locally without waiting for ignition signal.

#### 6_selfdrive-modeld-SConscript.diff
This file patches ```selfdrive/modeld/SConscript``` to disable use of SNPE
Here we:
1) Add a condition when it identify the board as "```linuxarm64``" just like Darwin (Mac), we do not use any of the SNPE library existed on Qualcomm platforms.

#### 7_selfdrive-modeld-runners-onnx_runner.py.diff
This file patches ```selfdrive/modeld/runners/onnx_runner.py``` to use CUDA as execution provider.
When openpilot runs in PC mode, it uses ONNX Runtime to load the AI model, however, it uses CPU as it's execution provider by default.
Here we:
1) Changed ```CPUExecutionProvider``` to ```CUDAExecutionProvider```

#### 8_selfdrive-camerad-cameras-camera_webcam.cc.diff (OPTIONAL)
This file patches ```selfdrive/camerad/cameras/camera_webcam.cc``` to use gstreamer for video feed.
Only consider this patch if you want to use MIPI camera interface.
Here we:
1) Uses gstreamer to get video sources.
2) Map driver camera to the 2nd camera of the stereo camera.

---

To Run
------
First compile with:
```bash
cd ~/openpilot
USE_WEBCAM=1 scons -j ($nproc)
```

Then run it with:
```bash
cd ~/openpilot/selfdrive/manager
PASSIVE=0 NOSENSOR=1 USE_WEBCAM=1 ./manager.py
```

---


Tuning
------
#### Autostart ####
to be able to start openpilot at boot, there are a couple of process we need to do:

1. make sure your user ```openpilot``` has sufficient permissions:
```
sudo usermod -aG video openpilot
sudo usermod -aG root openpilot
```
Perhaps the quickest way is to give root privilege, edit /etc/passwd and change your user/grup id to 0, e.g.:
```
openpilot:x:1000:1000:openpilot,,,:/home/opnpilot:/bin/bash
```
and change to
```
openpilot:x:0:0:openpilot,,,:/home/opnpilot:/bin/bash
```

*for some unknown reasons gstreamer is unable to get video position(?) in a non-root environment.*

2. Create a script to start openpilot, place this file in /home/openpilot/start_op.sh (your home folder):
```bash
#!/bin/bash
cd /home/openpilot/openpilot/selfdrive/manager/
PASSIVE=0 NOSENSOR=1 USE_WEBCAM=1 ./managaer
```
make sure you make it executable:
```
chmod +x /home/openpilot/start_op.sh
```

3. Modify ```/home/openpilot/.bashrc``` to use tmux:
at the end of the file, make sure you have these:
```bash
export PYENV_ROOT="/home/openpilot/.pyenv"
export PATH="/home/openpilot/.pyenv/bin:/home/openpilot/.pyenv/shims:/home/openpilot/.pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
source /home/openpilot/openpilot/tools/openpilot_env.sh
cd /home/openpilot/openpilot
TMUX_SESSION="openpilot"
tmux has-session -t ${TMUX_SESSION} 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -s ${TMUX_SESSION} -n bash -d
  tmux send-keys -t ${TMUX_SESSION}:0 'bash /home/openpilot/start_op.sh' C-m
fi

tmux attach-session -t ${TMUX_SESSION}
```

*the first 2~3 line should already be in your .bashrc file (something similar)*

4. (Optional) Modify ```/home/openpilot/.config/lxsession/LXDE/autostart``` to start a lxterminal after you boot up.
add the line below at the end of the file:
```
@lxterminal
```

so now once you logged into one of your terminal/console, it should run openpilot on your first tmux session just like openpilot on EON/C2.


Credits
------
- Sid for his [installer script](https://discord.com/channels/660951518014341124/697074382018707507/841722618150780988)
- [dragonpilot Community](https://github.com/dragonpilot-community/dragonpilot/)
- [RetroPilot Community](https://discord.gg/fGUuASVZKg)
- [Unofficial OpenPilot Community](https://discord.gg/Mrf8FwfWSr)
