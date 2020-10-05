#!/bin/bash

# Welcome!
# Just want to get a few things out of the way. This script assumes you're running this on a raspberry pi 4 with raspberian lite freshly installed.

sudo apt update -y
sudo apt upgrade -y

sudo apt install curl jq docker.io git vim gcc build-essential -y

sudo usermod -aG docker pi

mkdir ~/miner_data

cd ~
git clone https://github.com/Lora-net/packet_forwarder
git clone https://github.com/Lora-net/lora_gateway

cd packet_forwarder/lora_pkt_fwd

mv ~/packet_forwarder/lora_pkt_fwd/global_conf.json ~/packet_forwarder/lora_pkt_fwd/global_conf.json.1
curl -s -o ~/packet_forwarder/lora_pkt_fwd/global_conf.json 'https://helium-media.s3-us-west-2.amazonaws.com/global_conf.json'
#wget https://helium-media.s3-us-west-2.amazonaws.com/global_conf.json --backups

#sed link
sed -i 's/#define SPI_SPEED       8000000/#define SPI_SPEED       2000000/' /home/pi/lora_gateway/libloragw/src/loragw_spi.native.c

cd /home/pi/packet_forwarder/
./compile.sh

sudo cp ~/helium_miner_scripts/service_files/lora-gw-restart.service /etc/systemd/system/lora-gw-restart.service
sudo cp ~/helium_miner_scripts/service_files/lora-pkt-fwd.service /etc/systemd/system/lora-pkt-fwd.service

sudo systemctl enable lora-gw-restart.service
sudo systemctl enable lora-pkt-fwd.service
sudo systemctl start lora-gw-restart.service
sudo systemctl start lora-pkt-fwd.service

#i'm an idiot for including this
#cd ~
#git clone https://github.com/Wheaties466/helium_miner_scripts.git

sudo touch ~/crondump
sudo chmod 777 ~/crondump
sudo crontab -l > ~/crondump
echo "0 */4 * * * /home/pi/helium_miner_scripts/miner_latest.sh >> /var/log/miner_latest.log" >> ~/crondump
echo "0 0 * * * cd /home/pi/helium_miner_scripts && git pull" >> ~/crondump
sudo crontab -u pi ~/crondump

echo "remember to backup your swarm key found here: /home/pi/miner_data/miner/swarm_key"
echo "use WinSCP(or another program) to transfer this file to another computer and back it up. This is VERY IMPORTANT"

ip=$(hostname -I | cut -d" " -f1)

echo "if you want to download the file in the web browser, run the following command after reboot."
echo "/home/pi/helium_miner_scripts/miner_latest.sh && cd /home/pi/miner_data/miner/ && python -m SimpleHTTPServer 3000"
echo " CTRL + C will cancel the webserver, but open a web browser and go to http://"$ip":3000/swarm_key"
echo "Save the file locally"

# I think one of these was causing issues booting after applying.
#sudo raspi-config nonint do_spi 1
#sudo raspi-config nonint do_i2c 1
#sudo raspi-config nonint do_serial 1
#sudo raspi-config nonint do_wifi_country US
#sudo raspi-config nonint do_ssh 1

locale=en_US.UTF-8
layout=us
sudo raspi-config nonint do_change_locale $locale
sudo raspi-config nonint do_configure_keyboard $layout

#add swap
sudo dphys-swapfile swapoff
sudo sed -i -e 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/g' /etc/dphys-swapfile

echo "rebooting the pi in 10 seconds, CTRL + C to stop"
sleep 10
sudo reboot
