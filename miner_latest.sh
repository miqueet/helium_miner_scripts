#!/bin/bash

# Script for auto updating the helium miner.

# Set default values
MINER=miner
REGION=US915
GWPORT=1680
MINERPORT=44158
DATADIR=/home/pi/miner_data
LOGDIR=
QUAY_URL='https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=20&page=1&onlyActiveTags=true'

# Make sure we have the latest version of the script
function update-git {
   SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
   cd "$SCRIPT_DIR" && git pull
}

command -v jq > /dev/null || sudo apt-get install jq curl -y

# Read switches to override any default values for non-standard configs
while getopts n:g:p:d:l:r: flag
do
   case "${flag}" in
      n) MINER=${OPTARG};;
      g) GWPORT=${OPTARG};;
      p) MINERPORT=${OPTARG};;
      d) DATADIR=${OPTARG};;
      l) LOGDIR=${OPTARG};;
      r) REGION=${OPTARG};;
      *) echo "Exiting"; exit;;
   esac
done

# Autodetect running image version and set arch
if [ "$(uname -m)" == "x86_64" ]; then
        ARCH=amd
else
        ARCH=arm
fi

running_image=$(docker container inspect -f '{{.Config.Image}}' "$MINER" | awk -F: '{print $2}')

miner_quay=$(curl -s "$QUAY_URL" --write-out '\nHTTP_Response:%{http_code}')

miner_response=$(echo "$miner_quay" | grep "HTTP_Response" | cut -d":" -f2)

if [[ $miner_response -ne 200 ]];
	then
	echo "Bad Response from Server"
	exit 0
fi

miner_latest=$(echo "$miner_quay" | grep -v HTTP_Response | jq -c --arg ARCH "$ARCH" '[ .tags[] | select( .name | contains($ARCH)and contains("GA")) ][0].name' | cut -d'"' -f2)
#test url
#miner_latest=$(echo "$miner_quay" | grep -v HTTP_Response | jq -c --arg ARCH "$ARCH" '[ .tags[] | select( .name | contains($ARCH)and contains("64_202")) ][0].name' | cut -d'"' -f2)



date
echo "$0 starting with MINER=$MINER GWPORT=$GWPORT MINERPORT=$MINERPORT DATADIR=$DATADIR LOGDIR=$LOGDIR REGION=$REGION ARCH=$ARCH running_image=$running_image miner_latest=$miner_latest"

#check to see if the miner is more than 50 block behind
current_height=$(curl -s https://api.helium.io/v1/blocks/height | jq .data.height)
miner_height=$(docker exec "$MINER" miner info height | awk '{print $2}')
height_diff=$(expr "$current_height" - "$miner_height")

# commenting this out until I can find a better solution. Seems to be causing more problems than solutions.
##if [[ $height_diff -gt 50 ]]; then docker stop "$MINER" && docker start "$MINER" && echo "stopping and starting the miner because it may be stuck syncing the blockchain" ; fi

#If the miner is more than 500 blocks behind, stop the image, remove the container, remove the image. It will be redownloaded later in the script.
##if [[ $height_diff -gt 500 ]]; then docker stop "$MINER" && docker rm "$MINER" && docker image rm quay.io/team-helium/miner:"$miner_latest" ; fi

##if echo "$miner_latest" | grep -q $ARCH;
##        then echo "Latest miner version $miner_latest";
##elif miner_latest=$(echo "$miner_quay" | grep -v HTTP_Response | jq -r .tags[1].name)
##        then echo "Latest miner version $miner_latest";
##fi

if [ "$miner_latest" = "$running_image" ];
then    echo "already on the latest version"
	update-git
        exit 0
fi

# Pull the new miner image. Downloading it now will minimize miner downtime after stop.
docker pull quay.io/team-helium/miner:"$miner_latest"

echo "Stopping and removing old miner"

docker stop "$MINER" && docker rm "$MINER"

echo "Deleting old miner software"

for image in $(docker images quay.io/team-helium/miner | grep "quay.io/team-helium/miner" | awk '{print $3}'); do
	image_cleanup=$(docker images | grep "$image" | awk '{print $2}')
	#change this to $running_image if you want to keep the last 2 images
	if [ "$image_cleanup" = "$miner_latest" ]; then
	       continue
        else
		echo "Cleaning up: $image_cleanup"
		docker image rm "$image"
        
        fi		
done

echo "Provisioning new miner version"

if [ -n "$LOGDIR" ];
then
	LOGMOUNT="--mount type=bind,source=$LOGDIR,target=/var/data/log"
fi

docker run -d --init --env REGION_OVERRIDE="$REGION" --restart always --publish "$GWPORT":"$GWPORT"/udp --publish "$MINERPORT":"$MINERPORT"/tcp --name "$MINER" $LOGMOUNT --mount type=bind,source="$DATADIR",target=/var/data quay.io/team-helium/miner:"$miner_latest"

if [ "$GWPORT" -ne 1680 ] || [ "$MINERPORT" -ne 44158 ]; then
   echo "Using nonstandard ports, adjusting miner config"
   docker exec "$MINER" sed -i "/^  {blockchain,/{N;s/$/\n      {port, $MINERPORT},/}; s/1680/$GWPORT/" /opt/miner/releases/0.1.0/sys.config
fi

echo "Increasing memory limit for snapshots. See https://discord.com/channels/404106811252408320/730245219974381708/851336745538027550"
docker exec "$MINER" sed -i 's/{key, undefined}$/{key, undefined},{snapshot_memory_limit, 1000}/' /opt/miner/releases/0.1.0/sys.config
docker restart "$MINER"

update-git
