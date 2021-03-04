#!/bin/bash

# Script for auto updating the helium validator.

# Set default values

CONFIG_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)

#you will need to copy config.txt.tmp to config.txt to configure additional variables, this will make it sure the git update works properly

source $CONFIG_DIR/config.txt

MINER=validator
#modify the data_dir variable in the config.txt file
#DATADIR=~/validator_data
LOGDIR=
QUAY_URL='https://quay.io/api/v1/repository/team-helium/validator/tag/?limit=20&page=1&onlyActiveTags=true'

# Make sure we have the latest version of the script
function update-git {
   SCRIPT_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)
   cd "$SCRIPT_DIR" && git pull
}

command -v jq > /dev/null || sudo apt-get install jq curl -y

# Read switches to override any default values for non-standard configs
while getopts n:d:l: flag
do
   case "${flag}" in
      n) MINER=${OPTARG};;
      d) DATADIR=${OPTARG};;
      l) LOGDIR=${OPTARG};;
      *) echo "Exiting"; exit;;
   esac
done

#make sure the miner is not in CG if it is, then exit the script
minerInConsenus=$(docker exec "$MINER" miner info in_consensus | awk)
if [[$minerInConsenus -eq true]];
    then 
    echo "This validator is in Consenus Group no update for it"
    exit 0
    
fi

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

miner_latest=$(echo "$miner_quay" | grep -v HTTP_Response | jq -c --arg ARCH "$ARCH" '[ .tags[] | select( .name | contains($ARCH)and contains("miner")) ][0].name' | cut -d'"' -f2)

date
echo "$0 starting with MINER=$MINER DATADIR=$DATADIR ARCH=$ARCH running_image=$running_image miner_latest=$miner_latest"

#check to see if the miner is more than 50 block behind
current_height=$(curl -s 'https://testnet-api.helium.wtf/v1/blocks/height' | jq .data.height)
miner_height=$(docker exec "$MINER" miner info height | awk '{print $2}')
height_diff=$(expr "$current_height" - "$miner_height")

if [ "$miner_latest" = "$running_image" ];
then    echo "already on the latest version"
	update-git
        exit 0
fi

# Pull the new miner image. Downloading it now will minimize miner downtime after stop.
docker pull quay.io/team-helium/validator:"$miner_latest"

echo "Stopping and removing old validator software"

docker stop "$MINER" && docker rm "$MINER"

echo "Deleting old validator software"

for image in $(docker images quay.io/team-helium/validator | grep "quay.io/team-helium/validator" | awk '{print $3}'); do
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


docker run -d --init --restart always --name "$MINER" --publish 2154:2154/tcp --mount type=bind,source="$DATADIR",target=/var/data quay.io/team-helium/validator:"$miner_latest"

update-git
