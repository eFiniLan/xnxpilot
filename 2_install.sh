#!/bin/bash

# change jetson power mode, desktop
sudo nvpmodel -m 5 
# maximize Jetson Xavier performance by setting static max frequency to CPU, GPU, and EMC clocks
sudo jetson_clocks

# install packages in ubuntu_setup.sh
# without clang and qt
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
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
    libmysqlclient-dev \
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
    gcc-arm-none-eabi

# install focal version
sudo sed -i -e 's#bionic#focal#g' /etc/apt/sources.list
sudo apt update
sudo apt install -y --no-install-recommends \
	tmux \
	clang \
	qml-module-qtquick2 \
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
	ccache \
	libreadline-dev \
	nvidia-cudnn8 \
	nano

sudo apt install -y libpocl2
sudo sed -i -e 's#focal#bionic#g' /etc/apt/sources.list
sudo apt update

sudo apt purge -y whoopsie apport apparmor rpcbind gpsd isc-dhcp-server

wget -O .tmux.conf https://raw.githubusercontent.com/geohot/configuration/master/.tmux.conf
# reboot
reboot

