#!/bin/bash

# Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
  exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

echo  "Update packages list and update system"
apt update
apt upgrade -y

echo "Install nala"
apt install nala -y

echo  "Making .config and Moving config files and background to Pictures"
cd $builddir
mkdir -p /home/$username/.config
mkdir -p /home/$username/.fonts
mkdir -p /home/$username/Pictures
mkdir -p /usr/share/sddm/themes
cp .Xresources /home/$username
cp .Xnord /home/$username
cp -R dotconfig/* /home/$username/.config/
cp bg.jpg /home/$username/Pictures/
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username
tar -xzvf sugar-candy.tar.gz -C /usr/share/sddm/themes
mv /home/$username/.config/sddm.conf /etc/sddm.conf

echo "Installing sugar-candy dependencies"
nala install libqt5svg5 qml-module-qtquick-controls qml-module-qtquick-controls2 -y

echo "Installing Essential Programs" 
nala install feh bspwm sxhkd kitty rofi polybar picom thunar nitrogen lxpolkit x11-xserver-utils unzip yad wget pulseaudio pavucontrol -y

echo "Installing Other less important Programs"
nala install firefox microsoft-edge-stable gedit neofetch flameshot psmisc mangohud vim lxappearance papirus-icon-theme lxappearance fonts-noto-color-emoji sddm -y

echo "Download Nordic Theme"
cd /usr/share/themes/
git clone https://github.com/EliverLara/Nordic.git

echo "Installing fonts"
cd $builddir 
nala install fonts-font-awesome
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d /home/$username/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip
unzip Meslo.zip -d /home/$username/.fonts
mv dotfonts/fontawesome/otfs/*.otf /home/$username/.fonts/
chown $username:$username /home/$username/.fonts/*

echo "Reloading Font"
fc-cache -vf
# Removing zip Files
rm ./FiraCode.zip ./Meslo.zip

echo "Install Nordzy cursor"
git clone https://github.com/alvatip/Nordzy-cursors
cd Nordzy-cursors
./install.sh
cd $builddir
rm -rf Nordzy-cursors

echo "Enable graphical login and change target from CLI to GUI"
systemctl enable sddm
systemctl set-default graphical.target

# Configure bash to use nala wrapper instead of apt
ubashrc="/home/$username/.bashrc"
rbashrc="/root/.bashrc"
if [ -f "$ubashrc" ]; then
cat << \EOF >> "$ubashrc"
apt() {
  command nala "$@"
}
sudo() {
  if [ "$1" = "apt" ]; then
    shift
    command sudo nala "$@"
  else
    command sudo "$@"
  fi
}
EOF
fi

if [ -f "$rbashrc" ]; then
cat << \EOF >> "$rbashrc"
apt() {
  command nala "$@"
}
EOF
fi

# Beautiful bash
git clone https://github.com/ChrisTitusTech/mybash
cd mybash
bash setup.sh
cd $builddir

# Polybar configuration
bash scripts/changeinterface

