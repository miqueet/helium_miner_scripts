#!/bin/bash

# Script for auto updating the helium miner.

# Set default values
MINER=miner
REGION=US915
GWPORT=1680
MINERPORT=44158
DATADIR=/home/pi/miner_data

# Read switches to override any default values for non-standard configs
while getopts n:g:p:d:r: flag
do
   case "${flag}" in
      n) MINER=${OPTARG};;
      g) GWPORT=${OPTARG};;
      p) MINERPORT=${OPTARG};;
      d) DATADIR=${OPTARG};;
      r) REGION=${OPTARG};;
   esac
done

# Autodetect running image version and set arch
running_image=$(docker container inspect -f '{{.Config.Image}}' $MINER | awk -F: '{print $2}')
if [ `echo $running_image | awk -F_ '{print $1}'` = "miner-arm64" ]; then
   ARCH=arm
elif [ `echo $running_image | awk -F_ '{print $1}'` = "miner-amd64" ]; then 
   ARCH=amd
else
   ARCH=arm
fi

#miner_latest=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' | jq -c --arg ARCH "$ARCH" '[ .tags[] | select( .name | contains($ARCH)) ][0].name' | cut -d'"' -f2)

miner_quay=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' --write-out '\nHTTP_Response:%{http_code}')

miner_response=$(echo "$miner_quay" | grep "HTTP_Response" | cut -d":" -f2)

if [[ $miner_response -ne 200 ]];
	then
	echo "Bad Response from Server"
	exit 0
fi

miner_latest=$(echo "$miner_quay" | grep -v HTTP_Response | jq -c --arg ARCH "$ARCH" '[ .tags[] | select( .name | contains($ARCH)) ][0].name' | cut -d'"' -f2)

date

if `echo $miner_latest | grep -q $ARCH`;
then echo "Latest miner version" $miner_latest;
elif miner_latest=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' | jq -r .tags[1].name)
then echo "Latest miner version" $miner_latest;
fi


if [ $miner_latest = $running_image ];
then    echo "already on the latest version"
        exit 0
fi

echo "Stopping and removing old miner"

docker stop $MINER && docker rm $MINER

echo "Provisioning new miner version"

docker run -d --env REGION_OVERRIDE=$REGION --restart always --publish $GWPORT:$GWPORT/udp --publish $MINERPORT:$MINERPORT/tcp --name $MINER --mount type=bind,source=$DATADIR,target=/var/data quay.io/team-helium/miner:$miner_latest

if [ $GWPORT -ne 1680 ] || [ $MINERPORT -ne 44158 ]; then
   echo "Using nonstandard ports, adjusting miner config"
   docker exec $MINER sed -i "s/44158/$MINERPORT/; s/1680/$GWPORT/" /opt/miner/releases/0.1.0/sys.config
   docker restart $MINER
fi
