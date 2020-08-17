# Helium miner update script
This script will automatically detect if that latest docker image is running and if this is not the case it will update to the latest docker image.

# Dependencies
Following dependencies shall be met:

- Curl
- jq

Make sure the user that is running the script is allowed to run docker. Either add the user to the docker group or run the scipt as root. See: https://docs.docker.com/engine/install/linux-postinstall/

# Configuration
After cloning this repository make the script executable:

```
$ chmod +x miner_latest.sh
```

## Change architecture 
Currently it is setup to use arm64 version, but it can be easily modified to use the amd64 docker image build by modifying the ARCH variable to equal ``amd`` instead of ``arm``.

## Change region
By default the script is configured for US915 frequencies. To use the miner in other regios like EU868 the script shall be changed by adding the `` --env  REGION_OVERRIDE=EU868`` to the line with ``docker run``:

```
docker run -d --env REGION_OVERRIDE=EU868 --restart always --publish 1680:1680/udp --publish 44158:44158/tcp --name miner --mount type=bind,source=/home/pi/miner_data,target=/var/data quay.io/team-helium/mi$
```

# Script useage

```
$ ./miner_latest.sh
```

This can be called from a cron or ran in a shell.

## Using cron
Add the following lines to your crontab using ``cron -e`` to run the escript dayly at 1 o clock at night:

```
# Check for updates on miner image verey night at 1 o clock
0 1 * * * cd ~/helium_miner_scripts $$ ./miner_latest.sh >> /var/log/miner_latest.log 2>&1
```

# Extra

Check if your miner is running and receiving data fromyour gateway:
```
$ docker exec miner tail -f /var/log/miner/console.log | grep lora
```

Check progress of your miner on the blockchain:
```
$ docker exec miner miner info height
```

Check connectivity of your miner:
```
$ docker exec miner miner peer book -s
```
