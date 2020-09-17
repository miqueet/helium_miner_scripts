#!/bin/bash

set_config_var() {
  lua - "$1" "$2" "$3" <<EOF > "$3.bak"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv "$3.bak" "$3"
}
#turn on spi
set_config_var dtparam=spi on /boot/config.txt
sed "/etc/modprobe.d/raspi-blacklist.conf -i -e s/^\(blacklist[[:space:]]*spi[-_]bcm2708\)/#\1/"
dtparam spi=on

#turn on i2c
set_config_var dtparam=i2c_arm on /boot/config.txt
sed "/etc/modprobe.d/raspi-blacklist.conf -i -e s/^\(blacklist[[:space:]]*i2c[-_]bcm2708\)/#\1/"
sed "/etc/modules -i -e s/^#[[:space:]]*\(i2c[-_]dev\)/\1/"
dtparam i2c_arm=on
modprobe i2c-dev

#turn off login from serial and turn on serial
sed -i /boot/cmdline.txt -e s/console=ttyAMA0,[0-9]\//
sed -i /boot/cmdline.txt -e s/console=serial0,[0-9]\//

set_config_var enable_uart 1 /boot/config.txt

do_expand_rootfs() {
  ROOT_PART="$(findmnt / -o source -n)"
  ROOT_DEV="/dev/$(lsblk -no pkname "$ROOT_PART")"

  PART_NUM="$(echo "$ROOT_PART" | grep -o "[[:digit:]]*$")"

  # Get the starting offset of the root partition
  PART_START=$(parted "$ROOT_DEV" -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d: | sed 's/[^0-9]//g')
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk "$ROOT_DEV" <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START

p
w
EOF

  # now set up an init.d script
cat <<EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "\$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs "$ROOT_PART" &&
    update-rc.d resize2fs_once remove &&
    rm /etc/init.d/resize2fs_once &&
    log_end_msg \$?
    ;;
  *)
    echo "Usage: \$0 start" >&2
    exit 3
    ;;
esac
EOF
  chmod +x /etc/init.d/resize2fs_once &&
  update-rc.d resize2fs_once defaults &&
  fi
}

sudo apt update -y
sudo apt upgrade -y

sudo apt install curl jq docker.io -y

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

cd /home/pi/cd packet_forwarder/
./compile.sh

cp ~/helium_miner_scripts/service_files/lora-gw-restart.service /etc/systemd/system/lora-gw-restart.service
cp ~/helium_miner_scripts/service_files/lora-pkt-fwd.service /etc/systemd/system/lora-pkt-fwd.service

sudo systemctl enable lora-gw-restart.service
sudo systemctl enable lora-pkt-fwd.service
sudo systemctl start lora-gw-restart.service
sudo systemctl start lora-pkt-fwd.service

#i'm an idiot for including this
#cd ~
#git clone https://github.com/Wheaties466/helium_miner_scripts.git

sudo touch /var/log/miner_latest.log
crontab -l > crondump
echo "0 1 * * * /home/pi/helium_miner_scripts/miner_latest.sh >> /var/log/miner_latest.log" >> crondump
crontab crondump

echo "remember to backup your swarm key found here: /home/pi/miner_data/miner/swarm_key"
echo "use WinSCP(or another program) to transfer this file to another computer and back it up. This is VERY IMPORTANT"

ip=$(hostname -I | cut -d" " -f1)

echo "if you want to download the file in the web browser, run the following command after reboot."
echo "/home/pi/helium_miner_scripts/miner_latest.sh && cd /home/pi/miner_data/miner/ && python -m SimpleHTTPServer 3000"
echo " CTRL + C will cancel the webserver, but open a web browser and go to http://"$ip":3000/swarm_key"
echo "Save the file locally"

do_expand_rootfs

echo "rebooting the pi in 10 seconds, CTRL + C to stop"
sudo reboot
