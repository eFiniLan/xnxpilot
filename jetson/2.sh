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

FILE="./clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz"
if test -f "$FILE"; then
    echo "$FILE exist"
else
    echo "$FILE downloading !"
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz &
fi


FILE="./onnxruntime_gpu-1.8.0-cp38-cp38-linux_aarch64.whl"
if test -f "$FILE"; then
    echo "$FILE exist"
else
    echo "$FILE downloading !"
    wget https://nvidia.box.com/shared/static/gjqofg7rkg97z3gc8jeyup6t8n9j8xjw.whl -O onnxruntime_gpu-1.8.0-cp38-cp38-linux_aarch64.whl &
fi

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
sudo rm -rf /usr/lib/${LLVM_INSTALL_FOLDER}/
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



