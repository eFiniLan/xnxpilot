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
pip install future-fstrings # for acados
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
cp /home/${USERNAME}/openpilot /data/

# make sure everything goes to the right display
echo "export DISPLAY=:0.0" >> $HOME/.bashrc

# start openpilot correctly
echo "export USE_MIPI=\"1\"" >> $HOME/.bashrc
echo "export NOSENSOR=\"1\"" >> $HOME/.bashrc
echo "export PASSIVE=\"0\"" >> $HOME/.bashrc

# start from /data/openpilot
echo "[ -d \"/data/openpilot\" ] && cd /data/openpilot" >> $HOME/.bashrc

