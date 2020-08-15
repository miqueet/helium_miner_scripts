# helium_miner_scripts

This script will automatically detect if that latest docker image is running and if this is not the case it will update to the latest docker image.

# Dependencies

Following dependencies shalle be met:

- Curl
- jq

Make sure the user that is running is allowed to run docker. Either add the user to the docker group or run the scipt as root.

# Configuration

After cloning this repositry make teh script executable:

```
chmod +x miner_latest.sh
```

Currently it is setup to use arm64 version, but it can be easily modified to use the amd64 docker image build by modifying the ARCH variable to equal ``amd`` instead of ``arm``.

# Script useage

```
$ ./miner_latest.sh
```

This can be called from a cron or ran in a shell.


