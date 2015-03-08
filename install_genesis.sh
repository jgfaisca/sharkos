#!/bin/bash
#
##############################################################
# Author: jose.faisca@gmail.com
# Date: 2013/12/1
# Version: 0.1
# Description: Installing arkOS / Genesis on X86_64/i386 PC
# Links: http://arkos.io
###############################################################
# (1) - Install Arch Linux base system and reboot
# (https://wiki.archlinux.org/index.php/Installation_guide)  
#
# (2) - Execute ./install_genesis.sh as root 
# 

# get host IP
ip=$(echo $(hostname -i))

# clean pacman cahe
echo $(pacman -Scc --noconfirm)

# sync package database
echo $(pacman -Syy --noconfirm)

# check if base group is installed
echo $(pacman -S --needed base --noconfirm)

# check if base-revel group is installed
echo $(pacman -S --needed base-devel --noconfirm)

# remove python 3
echo $(pacman -R python --noconfirm)

# install Python 2
echo $(pacman -S python2 --noconfirm)

# completely replace python 3 with python 2
$(ln -sf /usr/bin/python2 /usr/bin/python)
# verify
echo $(ls -l /usr/bin/python)

# remove pip 3
echo $(pacman -R python-pip --noconfirm)

# install pip 2
echo $(pacman -S python2-pip --noconfirm)

#completely replace pip 3 with pip 2
$(ln -sf /usr/bin/pip2 /usr/bin/pip)
# verify
echo $(ls -l /usr/bin/pip)

# install additional archlinux packages
echo $(pacman -S git openssh net-tools wget libxslt fail2ban --noconfirm)

# install python packages from pip
echo $(pip install --upgrade pyopenssl)
echo $(pip install --upgrade gevent)
echo $(pip install --upgrade lxml)
echo $(pip install --upgrade ntplib)
echo $(pip install --upgrade pyparsing)
echo $(pip install --upgrade feedparser)
echo $(pip install --upgrade passlib)
echo $(pip install --upgrade PIL)
echo $(pip install --upgrade psutil)

# show installed python packages
echo $(pip show pyopenssl gevent lxml ntplib \
pyparsing feedparser passlib PIL psutil)

# get python-iptables from source
$(rm -rf /opt/python-iptables*)
$(git clone https://github.com/ldx/python-iptables.git /opt/python-iptables)
# build and install python-iptables
cd /opt/python-iptables
echo $(python setup.py build)
echo $(python setup.py install)

# stop Genesis service
echo $(systemctl stop genesis)
# remove Genesis service
echo $(rm -f /etc/systemd/system/genesis.service)
# remove Genesis installation
$(rm -rf /usr/lib/python2.7/site-packages/genesis*)
$(rm -rf /var/lib/genesis*)
$(rm -rf /etc/genesis*)

# get Genesis from sources
$(rm -rf /opt/genesis*)
$(git clone https://github.com/cznweb/genesis.git /opt/genesis)

# modify genesis.conf and add the line firstrun = yes to the [genesis] section.
# SEARCH=“firstrun = yes”
# NEW=“firstrun = no”
# f=“/opt/genesis/genesis.conf”
# $(sed "s/$SEARCH/$NEW/g" "$f" > "$f.new" && mv "$f.new" "$f”)

# build and install Genesis
cd /opt/genesis
echo $(make clean)
echo $(python setup.py build)
echo $(python setup.py install)
current_dir=$(pwd)
cd $current_dir

# create archlinux genesis service
cat > /etc/systemd/system/genesis.service <<EOF
[Unit]
Description=Genesis Server

[Service]
ExecStart=/usr/bin/genesis-panel --start
ExecStop=/usr/bin/genesis-panel --stop
PIDFile=/var/run/genesis.pid

[Install]
WantedBy=multi-user.target
EOF

# enable Genesis service during the boot process
$(systemctl enable genesis)

# verify if Genesis service is enabled at boot
se=$(echo $(systemctl is-enabled genesis))
if [[ "$se" == *enabled* ]]; then
  echo "Genesis service is enabled"
else
  echo "ERROR enabling Genesis service"
fi

# start Genesis daemon
$(systemctl start genesis)

# verify Genesis daemon status
ds=$(echo $(systemctl list-units | grep genesis))
if [[ "$ds" == *running* ]]; then
  # show Genesis daemon status
  echo $(systemctl status genesis -l)
else
  echo "ERROR starting Genesis service. Aborting! ";exit 1
fi

echo "--------------------------------------------------------"
echo "Genesis listen on HTTP port 8000 by default
echo "URL = http://$ip:8000"
echo ""
echo "Default username : admin"
echo "Default password : admin"
echo ""
echo "You may stop Genesis with 'systemctl stop genesis'"
echo "--------------------------------------------------------"
echo
echo "done!"
echo

exit 0


