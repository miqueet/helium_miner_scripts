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
image=$(docker container inspect -f '{{.Config.Image}}' $MINER 2>/dev/null) || {
   echo "The $MINER container isn't running, aborting."
   exit 1
}

echo "Fetching the latest version"
docker pull $image > /dev/null

# Compare image ids
image_id=$(docker image inspect --format '{{.Id}}' $image)
running_id=$(docker inspect --format '{{.Image}}' $MINER)

if [ "$image_id" = "$running_id" ];
then    echo "already on the latest version"
        exit 0
fi

echo "Stopping and removing old miner"

docker stop $MINER
docker rm $MINER

echo "Deleting old miner software"

docker images quay.io/team-helium/miner -f "before=$image" --format "{{.ID}}" | xargs docker image rm

echo "Provisioning new miner version"

docker run -d --env REGION_OVERRIDE=$REGION --restart always --publish $GWPORT:$GWPORT/udp --publish $MINERPORT:$MINERPORT/tcp --name $MINER --mount type=bind,source=$DATADIR,target=/var/data $image

if [ $GWPORT -ne 1680 ] || [ $MINERPORT -ne 44158 ]; then
   echo "Using nonstandard ports, adjusting miner config"
   docker exec $MINER sed -i "s/44158/$MINERPORT/; s/1680/$GWPORT/" /opt/miner/releases/0.1.0/sys.config
   docker restart $MINER
fi
