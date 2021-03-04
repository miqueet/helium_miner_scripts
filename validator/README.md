# Helium validator update script

Hello all

make sure to 
```
cp config.txt.tmp config.txt
```

if the testnet chain needs to be restarted you will need to perform the following to start over.
```
docker stop validator && docker rm validator
rm -rf ~/validator_data/*
./validator_update.sh
{restake hnt}
```

# First it assumes you have the helium wallet software installed
If you do not have that installed, do the following.
```
cd ~ && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
sudo apt install pkg-config libssl-dev build-essential
PATH=$PATH:$HOME/.cargo/bin
git clone https://github.com/helium/helium-wallet-rs
cd helium-wallet-rs
cargo build --release
```

I haven't done some of the checks ive done in the past and i will make a script to make staking the coins a bit more automated. I also hope to add in a command line arg to delete the validator data dir.


