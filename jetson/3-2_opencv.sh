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
############################ DOWNLOAD PACKAGES ############################
###########################################################################
echo "openv load!!!"
mkdir -p /data/${WORKSPACE}/
cd /data/${WORKSPACE}/

FILE="./opencv-${OPENPCV_VERSION}.zip"
if test -f "$FILE"; then
    echo "$FILE exist"
else
    echo "$FILE downloading !"
    curl -L https://github.com/opencv/opencv/archive/${OPENPCV_VERSION}.zip -o opencv-${OPENPCV_VERSION}.zip &
fi

FILE="./opencv_contrib-${OPENPCV_VERSION}.zip"
if test -f "$FILE"; then
    echo "$FILE exist"
else
    echo "$FILE downloading !"
  curl -L https://github.com/opencv/opencv_contrib/archive/${OPENPCV_VERSION}.zip -o opencv_contrib-${OPENPCV_VERSION}.zip &
fi
wait


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

# echo "** Remove other OpenCV first"
# sudo sudo apt-get purge -y *libopencv*

# echo "** Install requirement"
# sudo apt-get update
# sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
# sudo apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
# sudo apt-get install -y libqtcore4 libqtgui4
# sudo apt-get install -y libv4l-dev v4l-utils qv4l2 v4l2ucp

# unzip opencv-${OPENPCV_VERSION}.zip
# unzip opencv_contrib-${OPENPCV_VERSION}.zip
cd opencv-${OPENPCV_VERSION}/

echo "** Building..."
FILE="./release"
if test -d "$FILE"; then
    cd release/
else
    mkdir release
    echo "$FILE downloading !"
fi

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


# cmake -D WITH_CUDA=ON \
#         -D WITH_CUDNN=OFF \
#         -D CUDA_ARCH_BIN="${JETSON_ARCH}" \
#         -D CUDA_ARCH_PTX="" \
#         -D OPENCV_GENERATE_PKGCONFIG=ON \
#         -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENPCV_VERSION}/modules \
#         -D WITH_GSTREAMER=ON \
#         -D WITH_LIBV4L=ON \
#         -D BUILD_opencv_python2=OFF \
#         -D BUILD_opencv_python3=ON \
#         -D BUILD_TESTS=OFF \
#         -D BUILD_PERF_TESTS=OFF \
#         -D BUILD_EXAMPLES=OFF \
#         -D CMAKE_BUILD_TYPE=RELEASE \
#         -D CMAKE_INSTALL_PREFIX=/usr/local \
#         -D WITH_GTK=OFF \
#         -D ENABLE_FAST_MATH=ON \
#         -D BUILD_opencv_java=OFF \
#         -D WITH_QT=OFF \
#         -D INSTALL_PYTHON_EXAMPLES=OFF \
#         -D INSTALL_C_EXAMPLES=OFF \
#         -D WITH_CUFFT=ON \
#         -D WITH_CUBLAS=ON \
#         -D WITH_1394=OFF \
#         -D WITH_ANDROID_MEDIANDK=OFF \
#         -D BUILD_JAVA=OFF \
#         -D BUILD_FAT_JAVA_LIB=OFF \
#         -D BUILD_opencv_python2=OFF \
#         ..