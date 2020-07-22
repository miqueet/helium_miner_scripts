#!/bin/bash

#auto updating the helium miner. This was written for 


ARCH=arm

miner_latest=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' | jq -r .tags[0].name)


if ` echo $miner_latest | grep -q $ARCH`;
then echo "Latest miner version" $miner_latest;
elif miner_latest=$(curl -s 'https://quay.io/api/v1/repository/team-helium/miner/tag/?limit=100&page=1&onlyActiveTags=true' | jq -r .tags[1].name)
echo "Latest miner version" $miner_latest;
fi

if ` echo $miner_latest | grep -q $ARCH`;
then continue
else echo "latest miner release not found" && exit 0
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
