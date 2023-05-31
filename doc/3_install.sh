#!/bin/bash

# change jetson power mode, desktop
sudo nvpmodel -m 5 
# maximize Jetson Xavier performance by setting static max frequency to CPU, GPU, and EMC clocks
sudo jetson_clocks

sudo apt autoremove -y

# install jtop
sudo pip3 install setuptools
# jtop
sudo -H pip3 install -U jetson-stats


cd $HOME
git clone https://github.com/commaai/openpilot.git openpilot

cd $HOME/openpilot

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
  OP_DIR=$(git rev-parse --show-toplevel)
  echo "export PYENV_ROOT=\"$HOME/.pyenv\"" >> ~/.bashrc
  echo "export PATH=\"$PYENV_ROOT/bin:$PATH\"" >> ~/.bashrc
  echo "eval \"$(pyenv init --path)\"" >> ~/.bashrc
  echo "source $OP_DIR/tools/openpilot_env.sh" >> ~/.bashrc
  source ~/.bashrc
  echo "added openpilot_env to bashrc"
fi

# do the rest of the git checkout
git lfs pull
git submodule init
git submodule update

# install python
pyenv install -s 3.8.5
pyenv global 3.8.5
pyenv rehash
eval "$(pyenv init -)"

# **** in python env ****
pip install --upgrade pip==20.2.4
pip install pipenv==2020.8.13

pip install setuptools
pip install wheel
pip install pkgconfig
pip install cython
pip install pycapnp
pip install numpy
pip install pycurl
pip install scons
pip install jinja2
pip install setuptools-cythonize
pip install sympy
pip install cffi
pip install logentries
pip install pyzmq
pip install pyjwt
pip install requests
pip install atomicwrites
pip install setproctitle
pip install psutil
pip install smbus2
pip install libusb1
pip install tqdm
pip install crcmod
pip install raven
pip install pycryptodome
pip install hexdump # for dump.py

cd $HOME
# install opencv4
sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
wget -O opencv.zip https://github.com/opencv/opencv/archive/4.5.2.zip
wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.5.2.zip
unzip opencv.zip
unzip opencv_contrib.zip
mv opencv-4.5.2 opencv
mv opencv_contrib-4.5.2 opencv_contrib
cd $HOME/opencv/
mkdir build
cd build

cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D WITH_CUDA=ON \
	-D CUDA_ARCH_PTX="" \
	-D CUDA_ARCH_BIN="7.2" \
  -D WITH_CUDNN=ON \
  -D CUDNN_VERSION="8.0" \
	-D BUILD_opencv_python3=ON \
	-D BUILD_opencv_python2=OFF \
	-D BUILD_opencv_java=OFF \
	-D WITH_GSTREAMER=ON \
	-D WITH_GTK=OFF \
	-D BUILD_TESTS=OFF \
	-D BUILD_PERF_TESTS=OFF \
	-D BUILD_EXAMPLES=OFF \
	-D BUILD_FFMPEG=ON \
	-D OPENCV_DNN_CUDA=ON \
	-D ENABLE_FAST_MATH=ON \
	-D CUDA_FAST_MATH=ON \
	-D WITH_QT=ON \
	-D ENABLE_NEON=ON \
	-D ENABLE_VFPV3=ON \
	-D BUILD_TESTS=OFF \
  -D INSTALL_PYTHON_EXAMPLES=OFF \
  -D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_ENABLE_NONFREE=ON \
  -D OPENCV_GENERATE_PKGCONFIG=ON \
  -D PYTHON_EXECUTABLE=/home/`whoami`/.pyenv/versions/3.8.5/bin/python \
  -D PYTHON_DEFAULT_EXECUTABLE=/home/`whoami`/.pyenv/versions/3.8.5/bin/python \
  -D PYTHON_PACKAGES_PATH=/home/`whoami`/.pyenv/versions/3.8.5/lib/python3.8/site-packages/ \
	-D OPENCV_EXTRA_MODULES_PATH=/home/`whoami`/opencv_contrib/modules ..

make -j $(nproc)
sudo make install

#capnproto
#install with the supplied script instead
cd $HOME/openpilot
sudo cereal/install_capnp.sh

# instrall onnxruntime-gpu
wget https://nvidia.box.com/shared/static/8xgbee5ghhb92i9rrcr04yymg0n3x3t0.whl -O onnxruntime_gpu-1.7.0-cp38-cp38-linux_aarch64.whl
pip install onnxruntime_gpu-1.7.0-cp38-cp38-linux_aarch64.whl
rm -fr onnxruntime_gpu-1.7.0-cp38-cp38-linux_aarch64.whl

#add user to the input device so it can read mouse
sudo usermod -aG input openpilot

sudo apt autoremove -y
reboot
