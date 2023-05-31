#!/bin/bash -e
# The MIT License
#
# Copyright (c) 2019-, Rick Lan, dragonpilot community, and a number of other of contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#####################################################################
# Configuration:
# * Use IMX 477 Arducam.
# * Minimum of 32GB of U3 micro sdcard.
# * Work on Nvidia Jetson Xavier NX only.
# * Use Jetpack 4.6.
# * setup your username / password as: comma / comma
# * setup your host name as: tici
# * change your camera settings in /opt/nvidia/jetson-io/jetson-io.py
#####################################################################

JETSON_ARCH="7.2"
PYENV_PYTHON_VERSION="3.8.10"
OPENPCV_VERSION="4.5.0"
LLVM_VERSION="12.0.1"
LLVM_INSTALL_FOLDER="llvm-12"
POCL_VERSION="release_1_8"
USERNAME="comma"

WORKSPACE="workspace"


###########################################################################
################################## FINAL ##################################
###########################################################################
# !!!! donot delete the workspace
#cd /data && rm -fr /data/${WORKSPACE}/

# creates the necessary links and cache
sudo ldconfig -v

# delay restart
# -YJ-
# sudo shutdown -r 1

# clean up once last time
# -YJ- will clean qt5, so do not do this !!!!
# sudo apt autoremove -y && sudo apt clean -y

# lxdm give comma autologin
sudo sed -i -e "s/# autologin=dgod/autologin=${USERNAME}/g" /etc/lxdm/default.conf

# remove screensaver
sudo sed -i -e 's/@xscreensaver -no-splash//g' /etc/xdg/lxsession/LXDE/autostart

# auto start openpilot
sudo sh -c 'echo "@lxterminal --command tmux new-session -s '${USERNAME}' -d /data/openpilot/jetson/launcher.sh" >> /etc/xdg/lxsession/LXDE/autostart'

# comma as root
USERNAME="comma"
sudo sed -i -e "s#${USERNAME}:x:1000:1000:${USERNAME}#${USERNAME}:x:0:0:${USERNAME}#g" /etc/passwd
