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

sudo apt install sshpass -y

# This script also assumes that you are connecting to a remote miner over ssh and that you have the wallet software locally in your $PATH. It will add the path below if you just recently installed it.

read -p 'What is the IP address of the miner youd like to connect to?' miner_ip
read -p 'What is the port number?' miner_port

read -p 'Type(or Paste) your onboarding code?' ONBOARD

read -sp 'What is the ssh password for the pi user?(Default: raspberry): ' SSH_PASSWORD

PATH=$PATH:$HOME/helium-wallet-rs/bin

echo "Type in your 12 words from the helium mobile app"
echo "The password it asks for is the password to the key file it is creating. Make one up" 
helium-wallet create basic --seed

WALLET_ADDRESS=$(helium-wallet info | grep Address | awk '{print $4}')

ADD_GATEWAY="docker exec miner miner txn add_gateway owner=$WALLET_ADDRESS --payer 14fzfjFcHpDR1rTH8BNPvSi5dKBbgxaDnmsVPbCjuq9ENjpZbxh"

echo "this is the ssh password, more than likely its still the default, raspberry"

ADD_GW_MINER_OUTPUT=$(sshpass -p $SSH_PASSWORD ssh -oStrictHostKeyChecking=accept-new -p $miner_port pi@$miner_ip $ADD_GATEWAY)

echo "Miner output: " $ADD_GW_MINER_OUTPUT

echo "Type in the password you created earlier"
helium-wallet --format json onboard $ADD_GW_MINER_OUTPUT --onboarding $ONBOARD --commit

echo "If you see a hash and txn number, it should be sucessful"

read -p 'please enter the LAT,LONG as follows -10.098098,88.909808(NO SPACES)[GET THE LAT LONG FROM GOOGLE MAPS]: ' LATLONG

ASSERT_GW="docker exec miner miner txn assert_location owner=$WALLET_ADDRESS location=$LATLONG --payer 14fzfjFcHpDR1rTH8BNPvSi5dKBbgxaDnmsVPbCjuq9ENjpZbxh"

echo "this is the ssh password, more than likely its still the default, raspberry"

ASSERT_GW_MINER_OUTPUT=$(sshpass -p $SSH_PASSWORD ssh -oStrictHostKeyChecking=accept-new -p $miner_port pi@$miner_ip $ASSERT_GW )

helium-wallet --format json onboard $ASSERT_GW_MINER_OUTPUT --onboarding $ONBOARD --commit
