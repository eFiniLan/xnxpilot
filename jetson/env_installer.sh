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
############################### BASE SYSTEM ###############################
###########################################################################

# Nopasswd sudo
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo -f /etc/sudoers')

# setup /bin/sh symlink
sudo ln -sf /bin/bash /bin/sh

# Disable automatic ondemand switching from ubuntu (cpu auto scaling)
sudo systemctl disable ondemand

# jetpack 4.6 has mode 8
sudo nvpmodel -m 8

# use performance governor
sudo echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# throttling prevention
sudo sh -c 'echo 7000 > /sys/devices/c250000.i2c/i2c-7/7-0040/iio:device0/crit_current_limit_0'

# allow max available CPU freq
sudo sh -c 'for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do echo 1907200 > $i; done'

# reduce reboot time (when a running job is stall)
sudo sed -i -e 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=1s/g' /etc/systemd/system.conf

#allow user to access USB
sudo echo "SUBSYSTEM==\"usb\", MODE=\"0666\", GROUP=\"users\"" > $HOME/openpilot.rules
sudo echo "SUBSYSTEM==\"usb_device\", MODE=\"0666\", GROUP=\"users\"" >> $HOME/openpilot.rules
sudo mv $HOME/openpilot.rules /etc/udev/rules.d
sudo chmod 644 /etc/udev/rules.d/openpilot.rules
sudo chown root /etc/udev/rules.d/openpilot.rules
sudo chgrp root /etc/udev/rules.d/openpilot.rules

# Disable all useless systemctl services, if any, from agnos
sudo systemctl mask apt-daily-upgrade.service
sudo systemctl mask apt-daily.service
sudo systemctl mask apt-daily-upgrade.timer
sudo systemctl mask apt-daily.timer
sudo systemctl disable nvpmodel.service
sudo systemctl mask sys-devices-3100000.serial-tty-ttyTHS0.device
sudo systemctl mask sys-devices-3110000.serial-tty-ttyTHS1.device
sudo systemctl mask sys-devices-3110000.serial-tty-ttyTHS1.device
sudo systemctl mask sys-devices-3140000.serial-tty-ttyTHS4.device
sudo systemctl mask sys-devices-platform-serial8250-tty-ttyS0.device
sudo systemctl mask sys-devices-platform-serial8250-tty-ttyS1.device
sudo systemctl mask sys-devices-platform-serial8250-tty-ttyS2.device
sudo systemctl mask sys-devices-platform-serial8250-tty-ttyS3.device
sudo systemctl mask sys-kernel-debug.mount
sudo systemctl mask motd-news.timer
sudo systemctl mask remote-fs.target
sudo systemctl disable nvzramconfig
sudo systemctl mask plymouth-quit-wait.service # splash screen
sudo systemctl mask plymouth-read-write.service # splash screen
sudo systemctl mask alsa-restore.service # we dont have speakers, so no need alsa
sudo systemctl disable nvphs.service
sudo systemctl mask getty.target
sudo systemctl disable nv_update_verifier.service
sudo systemctl disable nvgetty.service
sudo systemctl mask networkd-dispatcher.service
sudo systemctl mask speech-dispatcher.service
sudo systemctl disable nv-l4t-usb-device-mode.service

# setup UI packages
sudo apt update
sudo apt purge -y gdm3 lightdm
sudo apt install -y --no-install-recommends apt-utils lxdm lxde unclutter

# install packages in ubuntu_setup.sh
# without clang and qt, we need them from focal release (newer)
sudo apt-get install -y --no-install-recommends \
    autoconf \
    build-essential \
    bzip2 \
    capnproto \
    cppcheck \
    libcapnp-dev \
    cmake \
    curl \
    ffmpeg \
    git \
    libavformat-dev libavcodec-dev libavdevice-dev libavutil-dev libswscale-dev libavresample-dev libavfilter-dev \
    libarchive-dev \
    libbz2-dev \
    libcurl4-openssl-dev \
    libeigen3-dev \
    libffi-dev \
    libglew-dev \
    libgles2-mesa-dev \
    libglfw3-dev \
    libglib2.0-0 \
    liblzma-dev \
    libomp-dev \
    libopencv-dev \
    libpng16-16 \
    libssl-dev \
    libstdc++-arm-none-eabi-newlib \
    libsqlite3-dev \
    libtool \
    libusb-1.0-0-dev \
    libzmq3-dev \
    libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-ttf2.0-dev libsmpeg-dev \
    libsdl1.2-dev  libportmidi-dev libswscale-dev libavformat-dev libavcodec-dev libfreetype6-dev \
    libsystemd-dev \
    locales \
    ocl-icd-libopencl1 \
    ocl-icd-opencl-dev \
    opencl-headers \
    python-dev \
    python3-pip \
    screen \
    sudo \
    vim \
    wget \
    htop \
    gcc-arm-none-eabi \
    gir1.2-notify

# clean up
sudo apt purge -y libreoffice* thunderbird* rhythmbox* transmission* mutter* *visionworks* ubuntu-wallpapers-bionic \
     *theme-ubuntu* remmina* branding-ubuntu light-themes pulseaudio packagekit ibus* \
     deluge smplayer* onboard* snapd* vpi1* galculator xmms2* youtube-dl unity-* whoopsie* \
     apport apparmor rpcbind gpsd isc-dhcp-server firefox printer-driver-* evolution-data-server* \
     lxmusic* avahi* yelp* vlc* nfs* ntfs* python-gi samba* docker* chromium-* system-config-printer-* \
     geoclue* totem* gnome-* modemmanager
sudo apt autoremove -y && sudo apt clean -y

# reinstall again making sure clean up didn't delete them.
sudo apt install -y --no-install-recommends lxdm lxde

# install packages from focal
sudo sed -i -e 's#bionic#focal#g' /etc/apt/sources.list
sudo apt update
sudo apt install -y tmux nano
sudo apt install -y --no-install-recommends \
	clang \
	qt5-default \
	qtmultimedia5-dev \
	qtwebengine5-dev \
  qtdeclarative5-dev \
	qtchooser \
	libqt5x11extras5-dev \
  qtlocation5-dev \
  qtpositioning5-dev \
  libqt5sql5-sqlite \
  libqt5svg5-dev \
  libqt5opengl5-dev \
	ccache \
	qml-module-qtquick2 \
	libreadline-dev

# libqt5opengl5-dev is for mapbox

sudo sed -i -e 's#focal#bionic#g' /etc/apt/sources.list

# clean up again
sudo apt update
sudo apt purge -y mysql-common p7zip* ppp* kerneloops *gvfs*
sudo apt autoremove -y

# add missing wifi manager
sudo apt install -y network-manager-gnome

# delete sample files
sudo rm -rf /usr/local/cuda/samples \
    /usr/src/cudnn_samples_* \
    /usr/src/tensorrt/data \
    /usr/src/tensorrt/samples \
    /usr/share/visionworks* ~/VisionWorks-SFM*Samples \
    /opt/nvidia/deepstream/deepstream*/samples

#add user to the input device so it can read mouse
sudo usermod -aG input ${USERNAME}

# common folders
sudo mkdir -p /data/ /data/params/d/ /data/media/0/ /persist/ /data/log /data/media/0/realdata/ /data/media/0/fakedata/

# dp will recognize it as jetson
sudo touch /JETSON

# allow ssh in root because we will give openpilot full root access.
sudo sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#KerberosAuthentication no/KerberosAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#GSSAPIAuthentication no/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#UseDNS no/UseDNS no/g' /etc/ssh/sshd_config
sudo sed -i -e 's/#UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config

# install jtop
sudo pip3 install setuptools
sudo -H pip3 install -U jetson-stats

###########################################################################
############################ OPENPILOT RELATED ############################
###########################################################################

# install git lfs
if ! command -v "git-lfs" > /dev/null 2>&1; then
  curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
  sudo apt-get install git-lfs
fi

# install pyenv
if ! command -v "pyenv" > /dev/null 2>&1; then
  curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
fi

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
# install bashrc
source ~/.bashrc
if [ -z "$OPENPILOT_ENV" ]; then
  echo "export PYENV_ROOT=\"$HOME/.pyenv\"" >> ~/.bashrc
  echo "export PATH=\"$PYENV_ROOT/bin:$PATH\"" >> ~/.bashrc
  echo "eval \"$(pyenv init --path)\"" >> ~/.bashrc
  echo "source /data/openpilot/jetson/openpilot_env.sh" >> ~/.bashrc
  source $HOME/openpilot/jetson/openpilot_env.sh
  source ~/.bashrc
  echo "added openpilot_env to bashrc"
fi


# install python
pyenv install -s ${PYENV_PYTHON_VERSION}
pyenv global ${PYENV_PYTHON_VERSION}
pyenv rehash
eval "$(pyenv init -)"

# **** in python env ****
pip install --upgrade pip==20.2.4
pip install pipenv==2020.8.13

pip install setuptools
pip install wheel
pip install pkgconfig

# packages
pip install atomicwrites
pip install casadi
pip install cffi
pip install crcmod
pip install furture-string # for acados
pip install hexdump # for dump.py
pip install libusb1
pip install numpy
pip install psutil
pip install pycapnp==1.1.0
pip install cryptography
pip install pyzmq
pip install requests
pip install setproctitle
pip install smbus2
pip install sympy
pip install tqdm
pip install cython
pip install scons
pip install pycryptodome
pip install jinja2
pip install pyjwt
pip install pyserial
pip install sentry-sdk

#pip install setuptools-cythonize
#pip install logentries
# mapd
pip install scipy
pip install overpy

# openpilot tmux
echo "unbind C-b" > $HOME/.tmux.conf
echo "set -g prefix \`" >> $HOME/.tmux.conf
echo "bind-key \` last-window" >> $HOME/.tmux.conf
echo "bind-key e send-prefix" >> $HOME/.tmux.conf
echo "bind-key S command-prompt -p 'Save log to file:' -I '/tmp/openpilot_log' 'capture-pane -S-7200; save-buffer %1; delete-buffer'" >> $HOME/.tmux.conf
echo "set -g status-position bottom" >> $HOME/.tmux.conf
echo "set -g status-style bg=colour234,fg=colour137,dim" >> $HOME/.tmux.conf
echo "set -g status-left ''" >> $HOME/.tmux.conf
echo "set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '" >> $HOME/.tmux.conf
echo "set -g status-right-length 50" >> $HOME/.tmux.conf
echo "set -g status-left-length 20" >> $HOME/.tmux.conf
echo "set -g history-limit 7200" >> $HOME/.tmux.conf
echo "setw -g window-status-current-style fg=colour81,bg=colour238,bold" >> $HOME/.tmux.conf
echo "setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '" >> $HOME/.tmux.conf
echo "setw -g window-status-style fg=colour138,bg=colour235" >> $HOME/.tmux.conf
echo "setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '" >> $HOME/.tmux.conf
echo "setw -g window-status-bell-style fg=colour255,bg=colour1,bold" >> $HOME/.tmux.conf

# move to /data/openpilot
cd /data
mv /home/${USERNAME}/openpilot /data/

# make sure everything goes to the right display
echo "export DISPLAY=:0.0" >> $HOME/.bashrc

# start openpilot correctly
echo "export USE_MIPI=\"1\"" >> $HOME/.bashrc
echo "export NOSENSOR=\"1\"" >> $HOME/.bashrc
echo "export PASSIVE=\"0\"" >> $HOME/.bashrc

# start from /data/openpilot
echo "[ -d \"/data/openpilot\" ] && cd /data/openpilot" >> $HOME/.bashrc

###########################################################################
############################ DOWNLOAD PACKAGES ############################
###########################################################################
mkdir -p /data/${WORKSPACE}/
cd /data/${WORKSPACE}/
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz &
wget https://nvidia.box.com/shared/static/gjqofg7rkg97z3gc8jeyup6t8n9j8xjw.whl -O onnxruntime_gpu-1.8.0-cp38-cp38-linux_aarch64.whl &
curl -L https://github.com/opencv/opencv/archive/${OPENPCV_VERSION}.zip -o opencv-${OPENPCV_VERSION}.zip &
curl -L https://github.com/opencv/opencv_contrib/archive/${OPENPCV_VERSION}.zip -o opencv_contrib-${OPENPCV_VERSION}.zip &
wait

###########################################################################
############################### ONNX RUNTIME ##############################
###########################################################################
cd /data/${WORKSPACE}/
pip install onnxruntime_gpu-1.8.0-cp38-cp38-linux_aarch64.whl

###########################################################################
################################## LLVM 12 ################################
###########################################################################
# for POCL
cd /data/${WORKSPACE}/
tar -xvf clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz
sudo mkdir -p /usr/lib/${LLVM_INSTALL_FOLDER}/
sudo mv clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu/* /usr/lib/${LLVM_INSTALL_FOLDER}/

###########################################################################
################################### POCL ##################################
###########################################################################
cd /data/${WORKSPACE}/
git clone --single-branch --branch ${POCL_VERSION} https://github.com/pocl/pocl.git
cd /data/${WORKSPACE}/pocl
mkdir build
cd /data/${WORKSPACE}/pocl/build/
cmake -DCMAKE_BUILD_TYPE=Release -DWITH_LLVM_CONFIG=/usr/lib/${LLVM_INSTALL_FOLDER}/bin/llvm-config -DENABLE_CUDA=ON -DSTATIC_LLVM=ON ..
make -j $(nproc)
sudo make install
mkdir -p /etc/OpenCL/vendors/
echo "/usr/local/lib/libpocl.so" > /etc/OpenCL/vendors/pocl.icd

###########################################################################
################################## OPENCV #################################
###########################################################################
# Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA Corporation and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto.  Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA Corporation is strictly prohibited.

# jetpack opencv doesn't have cuda that's why we compile manually
# check jtop for more info.
cd /data/${WORKSPACE}/

echo "** Remove other OpenCV first"
sudo sudo apt-get purge -y *libopencv*

echo "** Install requirement"
sudo apt-get update
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
sudo apt-get install -y libv4l-dev v4l-utils qv4l2 v4l2ucp

unzip opencv-${OPENPCV_VERSION}.zip
unzip opencv_contrib-${OPENPCV_VERSION}.zip
cd opencv-${OPENPCV_VERSION}/

echo "** Building..."
mkdir release
cd release/
cmake -D WITH_CUDA=ON \
        -D WITH_CUDNN=OFF \
        -D CUDA_ARCH_BIN="${JETSON_ARCH}" \
        -D CUDA_ARCH_PTX="" \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENPCV_VERSION}/modules \
        -D WITH_GSTREAMER=ON \
        -D WITH_LIBV4L=ON \
        -D BUILD_opencv_python2=OFF \
        -D BUILD_opencv_python3=ON \
        -D BUILD_TESTS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_EXAMPLES=OFF \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D WITH_GTK=OFF \
        -D ENABLE_FAST_MATH=ON \
        -D BUILD_opencv_java=OFF \
        -D WITH_QT=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D INSTALL_C_EXAMPLES=OFF \
        -D WITH_CUFFT=ON \
        -D WITH_CUBLAS=ON \
        -D WITH_1394=OFF \
        -D WITH_ANDROID_MEDIANDK=OFF \
        -D BUILD_JAVA=OFF \
        -D BUILD_FAT_JAVA_LIB=OFF \
        -D BUILD_opencv_python2=OFF \
        ..
make -j$(nproc)
sudo make install
###########################################################################
################################## FINAL ##################################
###########################################################################
cd /data && rm -fr /data/${WORKSPACE}/

# creates the necessary links and cache
sudo ldconfig -v

# delay restart
sudo shutdown -r 1

# clean up once last time
sudo apt autoremove -y && sudo apt clean -y

# lxdm give comma autologin
sudo sed -i -e "s/# autologin=dgod/autologin=${USERNAME}/g" /etc/lxdm/default.conf

# remove screensaver
sudo sed -i -e 's/@xscreensaver -no-splash//g' /etc/xdg/lxsession/LXDE/autostart

# auto start openpilot
sudo sh -c 'echo "@lxterminal --command tmux new-session -s '${USERNAME}' -d /data/openpilot/jetson/launcher.sh" >> /etc/xdg/lxsession/LXDE/autostart'

# comma as root
USERNAME="comma"
sudo sed -i -e "s#${USERNAME}:x:1000:1000:${USERNAME}#${USERNAME}:x:0:0:${USERNAME}#g" /etc/passwd