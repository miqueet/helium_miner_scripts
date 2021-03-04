#bin/bash

CONFIG_DIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)

#you will need to copy config.txt.tmp to config.txt to configure additional variables, this will make it sure the git update works properly

source $CONFIG_DIR/config.txt
 

command -v locate > /dev/null || sudo apt-get install mlocate -y && sudo updatedb

if [ $WALLET_BIN -z ]; then
	WALLET_BIN=$(locate bin/helium-wallet | head -n 1)
fi

if [ $WALLET_KEY -z ]; then
        WALLET_KEY=$(locate wallet.key | head -n 1)
fi
if [ $WALLET_KEY -z ]; then
	$WALLET_BIN create basic --network $NETWORK
	sudo updatedb
        WALLET_KEY=$(locate wallet.key | head -n 1)
fi
