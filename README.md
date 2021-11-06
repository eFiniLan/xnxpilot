Licensing
------
xnxpilot is released under the MIT license. Some parts of the software are released under other licenses as specified.

Any user of this software shall indemnify and hold harmless Rick Lan, dragonpilot, comma.ai, Inc. and its directors, officers, employees, agents, stockholders, affiliates, subcontractors and customers from and against all allegations, claims, actions, suits, demands, damages, liabilities, obligations, losses, settlements, judgments, costs and expenses (including without limitation attorneys’ fees and costs) which arise out of, relate to or result from any use of this software by user.

***THIS IS ALPHA QUALITY SOFTWARE FOR RESEARCH PURPOSES ONLY. THIS IS NOT A PRODUCT. YOU ARE RESPONSIBLE FOR COMPLYING WITH LOCAL LAWS AND REGULATIONS. NO WARRANTY EXPRESSED OR IMPLIED.***

---

Table of Contents
------

* [What is xnxpilot?](#what-is-xnxpilot)
* [Showcase](#showcase)
* [Checklist](#checklist)
* [Hardware requirement](#hardware-requirement)
* [Software requirement](#software-requirement)
* [Hardware assimbly](#hardware-assembly)
* [Installation](#installation)
* [Credits](#credits)
* [Notes](#notes)

---

What is xnxpilot?
------
xnxpilot (Xavier NX Pilot) is an open source driver assistance system based on [dragonpilot](http://github.com/dragonpilot-community/dragonpilot) and [openpilot](http://github.com/commaai/openpilot), running on a NVIDIA Jetson Xavier NX platform instead of a qualcomm 821 mobile phone.



If you would like to run it with minimal changes to openpilot, please see the example in "doc" branch, based on openpilot 0.8.4 

---

Showcase
------
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

Running on dragonpilot 0.8:
<table>
  <tr>
    <td><a href="https://youtu.be/o2pm8bAJvAM" title="YouTube" rel="noopener"><img src="http://i3.ytimg.com/vi/o2pm8bAJvAM/hqdefault.jpg"></a></td>
    <td><a href="https://youtu.be/GEr-K3D3sDU" title="YouTube" rel="noopener"><img src="http://i3.ytimg.com/vi/GEr-K3D3sDU/hqdefault.jpg"></a></td>
  </tr>
</table>

---

Checklist
------
- [x] Create build scripts
- [x] Add patch samples / tutorials.
- [x] On road lateral control tests.
- [ ] On road longitudinal control tests.
- [ ] Add IMU sensor to improve GPS accuracy.
- [ ] Tuning. (WIP)

---

Hardware Requirement
------
- [Nvidia Jetson Xavier NX](https://www.nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-xavier-nx/)
- 32GB+ microsd card (UHS 3 speed minimum)
- [Arducam IMX 477](https://www.amazon.com/gp/product/B08F743RGG/)
- [comma.ai Black Panda](https://comma.ai/shop/products/panda) (or white/grey panda but require more code customization.)
- (Optional) [comma.ai Windshield mount](https://github.com/commaai/neo/tree/master/case/eon)
- (Optional) [GoPro flat adhesive mount](https://www.amazon.com/AFAITH-Adhesive-Mounts-GoPro-Camera/dp/B00BUD6LPY/)
- (Optional) [Waveshare 4.3" IPS Touchscreen](https://www.amazon.com.au/gp/product/B0852NW9FM/)
- (Optional) [DCDZ Jetson Xavier NX Carrier Board NCB00](https://item.taobao.com/item.htm?ft=t&id=613984388047)
- (Optional) [CSI to HDMI Extension Module](https://www.amazon.com/gp/product/B06XDNBM63/)
- (Optional) Targus notebook charger for car.
---

Software Requirement
------
- [NVIDIA JetPack 4.6](https://developer.nvidia.com/jetpack-sdk-46)

---

Hardware assembly
------
It is important to know that your camera needs **firmly attached** onto your windshield, any small movement to the camera while driving may result dangerous steering/acceleration.

I highly recommended to 3D print those commaai windshield mount (use with gopro mount) and use it to mount your camera, 24 degree one will do the job.

---

Installation
------
1) [Install ubuntu 18.04 / Jetpack 4.6 on to sdcard](https://developer.nvidia.com/embedded/learn/get-started-jetson-xavier-nx-devkit)
2) Insert your sd card to your jetson, have camera connect to CAM0, boot up, use the following configuration (installer will use those values to set up the device):
  - username: **comma**
  - password: **comma**
  - hostname: **tici**
  - mode: **20W 6 cores**

3) Once completed, run:
  - `sudo /opt/nvidia/jetson-io/jetson-io.py`
  - select `Configure Jetson Nano CSI Connector` > `Configure for compatible hardware` > `Camera IMX477 Dual` > `Save pin changes` > `Save and exit without rebooting`.

4) clone this repo to your home directory (e.g. `cd ~/ && git clone https://github.com/efinilan/xnxpilot.git openpilot -b 0.8.9 --single-branch`)
5) run `cd ~/openpilot/jetson/ && sudo bash env_installer.py`
6) Take a rest, this will take around **1.5 hrs** to config your system and another **10 mins** for compile dragonpilot, depends on your internet connection.
7) Congradulations, you have dragonpilot running on your jetson. 
---

Credits
------
- [dragonpilot](https://github.com/dragonpilot-community/dragonpilot/)
- [Commaai Openpilot](https://github.com/commaai/openpiplot)
- [RetroPilot Community](https://discord.gg/fGUuASVZKg)
- [Unofficial OpenPilot Community](https://discord.gg/Mrf8FwfWSr)

---

Notes
------
#### set_core_affinity ####
Jetson Xavier NX has 6 cores running at 1.9 GHz, here is what I've defined:

0 = camerad

1 = modeld

2 = boardd

3 = controlsd

4 = plannerd / radard

This will spread processes other CPU cores.