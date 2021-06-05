#!/bin/bash

# autologin
sudo apt install -y lxdm
sudo sed -i -e 's/#autologin=dgod/autologin=openpilot/g' /etc/lxdm/default.conf
sudo sed -i -e 's/#skip_password/skip_password/g' /etc/lxdm/default.conf
reboot