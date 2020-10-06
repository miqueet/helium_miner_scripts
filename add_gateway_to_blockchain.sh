#!/bin/bash

#This script assumes a few things.
#First it assumes you have the helium wallet software installed in $HOME/helium-wallet-rs/bin
#If you do not have that installed, do the following.
#  cd ~ && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# sudo apt install pkg-config libssl-dev build-essential
# PATH=$PATH:$HOME/.cargo/bin
# git clone https://github.com/helium/helium-wallet-rs
# cd helium-wallet-rs
# cargo build --release

#If you need to create a wallet.key file use the argument create after calling the script
# ex. ./add_gateway_to_blockchain create
#Thinking about just doing ssh-keygen

#all these if -z statements are just checking to see whats installed and prompting for where it is installed if we can't detect it automatically

SSHPASS=$(which sshpass)
if [[ -z $SSHPASS ]]; then
sudo apt install sshpass -y
fi

SSHPASS=$(which sshpass)

if [[ $1 -eq "create" ]]; then
	echo "Type in your 12 words from the helium mobile app"
	echo "The password it asks for is the password to the key file it is creating. Make one up"
	helium-wallet create basic --seed
fi

wallet_key_location=$(ls | grep -x "wallet.key")

if [[ -z $wallet_key_location ]]; then
	read -p "Please enter the full path of your wallet.key file: " wallet_key_location
fi

wallet_binary=$(which helium-wallet)

if [[ -z $wallet_binary ]]; then
	read -p "Enter the full path of the helium-wallet binary file. If you don't have it there are instructions in the comments on how to compile for linux" $wallet_binary
fi

# This script also assumes that you are connecting to a remote miner over ssh and that you have the wallet software locally in your $PATH. It will add the path below if you just recently installed it.

read -p 'What is the IP address of the miner youd like to connect to?' miner_ip
read -p 'What is the port number?' miner_port

read -p 'Type(or Paste) your onboarding code?' ONBOARD

read -sp 'What is the ssh password for the pi user?(Default: raspberry): ' SSH_PASSWORD

PATH=$PATH:$HOME/helium-wallet-rs/bin

WALLET_ADDRESS=$(helium-wallet -f $wallet_key_location info | grep Address | awk '{print $4}')

ADD_GATEWAY="docker exec miner miner txn add_gateway owner=$WALLET_ADDRESS --payer 14fzfjFcHpDR1rTH8BNPvSi5dKBbgxaDnmsVPbCjuq9ENjpZbxh"

echo "this is the ssh password, more than likely its still the default, raspberry"

if [[ -z $SSHPASS ]]; then
ADD_GW_MINER_OUTPUT=$(ssh -oStrictHostKeyChecking=accept-new -p $miner_port pi@$miner_ip $ADD_GATEWAY);
else ADD_GW_MINER_OUTPUT=$(sshpass -p $SSH_PASSWORD ssh -oStrictHostKeyChecking=accept-new -p $miner_port pi@$miner_ip $ADD_GATEWAY)
fi

echo "Miner output: " $ADD_GW_MINER_OUTPUT

echo "Type in the password you created earlier"
helium-wallet -f $wallet_key_format --format json onboard $ADD_GW_MINER_OUTPUT --onboarding $ONBOARD --commit

echo "If you see a hash and txn number, it should be sucessful"

read -p 'please enter the LAT,LONG as follows -10.098098,88.909808(NO SPACES)[GET THE LAT LONG FROM GOOGLE MAPS]: ' LATLONG

ASSERT_GW="docker exec miner miner txn assert_location owner=$WALLET_ADDRESS location=$LATLONG --payer 14fzfjFcHpDR1rTH8BNPvSi5dKBbgxaDnmsVPbCjuq9ENjpZbxh"

echo "this is the ssh password, more than likely its still the default, raspberry"
if [[ -z $SSHPASS ]]; then
	ASSERT_GW_MINER_OUTPUT=$(ssh -oStrictHostKeyChecking=accept-new -p $miner_port pi@$miner_ip $ASSERT_GW )
else
	ASSERT_GW_MINER_OUTPUT=$(sshpass -p $SSH_PASSWORD ssh -oStrictHostKeyChecking=accept-new -p $miner_port pi@$miner_ip $ASSERT_GW )

fi

helium-wallet -f $wallet_key_location --format json onboard $ASSERT_GW_MINER_OUTPUT --onboarding $ONBOARD --commit

echo "you're all done!"
