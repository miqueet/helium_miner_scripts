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

WALLET_BALANCE=$($WALLET_BIN -f $WALLET_KEY info | grep -i balance | grep -v "DC\|Securities" | awk '{print $4}')

WALLET_ADDR=$(/home/helium/helium-wallet-rs/bin/helium-wallet -f $WALLET_KEY info | grep "Address" | awk '{print $4}')

if [[ $WALLET_BALLANCE -lt 10000 ]]; then
	echo " Wallet balance is less than 10k, go to https://faucet.helium.wtf/ to re up. submit the following wallet address" $WALLET_ADDR
	exit 0
fi

WALLET_ADDR=$(/home/helium/helium-wallet-rs/bin/helium-wallet -f $WALLET_KEY info | grep "Address" | awk '{print $4}')

PEER_ADDR=$(sudo docker exec validator miner peer addr | cut -d'/' -f3)

$WALLET_BIN validators stake $PEER_ADDR 10000 --commit

echo "funds should be sucessfully staked"
