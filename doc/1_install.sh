#!/bin/bash

# change jetson power mode, desktop
sudo nvpmodel -m 5 
# maximize Jetson Xavier performance by setting static max frequency to CPU, GPU, and EMC clocks
sudo jetson_clocks

#allow sudo without password
IS_SUDO=$(sudo cat /etc/sudoers | grep `whoami` | wc -l)
if [ $IS_SUDO = 0 ]; then
  echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | (sudo su -c 'EDITOR="tee -a" visudo -f /etc/sudoers')
fi

#allow user to access USB
sudo echo "SUBSYSTEM==\"usb\", MODE=\"0666\", GROUP=\"users\"" > $HOME/openpilot.rules
sudo echo "SUBSYSTEM==\"usb_device\", MODE=\"0666\", GROUP=\"users\"" >> $HOME/openpilot.rules
sudo mv $HOME/openpilot.rules /etc/udev/rules.d
sudo chmod 644 /etc/udev/rules.d/openpilot.rules
sudo chown root /etc/udev/rules.d/openpilot.rules
sudo chgrp root /etc/udev/rules.d/openpilot.rules

# remove unused apps
sudo apt update
sudo apt purge -y libreoffice* thunderbird* rhythmbox* transmission* mutter* *visionworks* ubuntu-wallpapers-bionic ubuntu-desktop *theme-ubuntu* remmina branding-ubuntu light-themes lightdm gdm3 pulseaudio packagekit ibus* metacity mate-desktop-common xfwm4 matchbox-window-manager lubuntu*
sudo apt install -y apt-utils openbox
sudo apt purge -y deluge smplayer* onboard* snapd* vpi1* lxmusic* avahi* yelp* gnome-* vlc* nfs* ntfs* docker* python-gi samba*
sudo apt autoremove -y && sudo apt clean -y
sudo apt upgrade -y
sudo apt install gir1.2-notify

#reboot
reboot