#!/bin/bash

#auto updating the helium miner. This was written for 


ARCH=arm

#if you're running the miner on amd64 based architecture uncomment below
#if you accidently install the wrong miner software, the miner will immediately crash and you will need to remove the bad image
#docker stop miner && docker rm miner && docker image ls
#remove the bad image with "docker image rm [IMAGE ID]
#ARCH=amd

miner_latest=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' | jq -c --arg ARCH "$ARCH" '[ .tags[] | select( .name | contains($ARCH)) ][0].name' | cut -d'"' -f2)


if `echo $miner_latest | grep -q $ARCH`;
then echo "Latest miner version" $miner_latest;
elif miner_latest=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' | jq -r .tags[1].name)
then echo "Latest miner version" $miner_latest;
fi

running_image=$(docker images quay.io/team-helium/miner:$miner_latest -q)

if [[ $running_image ]];
then    echo "already on the latest version"
        exit 0
fi

echo "Stopping and removing old miner"

docker stop miner && docker rm miner

echo "Running new miner version"

docker run -d --restart always --publish 1680:1680/udp --publish 44158:44158/tcp --name miner --mount type=bind,source=/home/pi/miner_data,target=/var/data quay.io/team-helium/miner:$miner_latest
