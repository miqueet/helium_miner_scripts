# helium_miner_scripts
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

# Script useage

```
$ ./miner_latest.sh
```

This can be called from a cron or ran in a shell.


