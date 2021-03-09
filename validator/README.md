# Helium validator update script

Hello all

make sure to 
```
cp config.txt.dist config.txt
```

if the testnet chain needs to be restarted you will need to perform the following to start over.
```
sudo docker stop validator && sudo docker rm validator
sudo cp ~/validator_data/miner/swarm_key ~
rm -rf ~/validator_data/*
./validator_latest.sh
sleep 10
sudo docker stop validator
sudo cp ~/swarm_key ~/validator_data/miner/swarm_key
sudo docker start validator
sleep 60
./wallet_stake.sh
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


# To setup a cron to have this run on a schedule feel free to use this cronjob
```
crontab -e
```
paste in the following
```
0 */4 * * * ~/helium_miner_scripts/validator/validator_latest.sh 2>&1 >> /var/log/validator_latest.log
```
I haven't done some of the checks ive done in the past and i will make a script to make staking the coins a bit more automated. I also hope to add in a command line arg to delete the validator data dir.

# To run the script without updating the git repo
```
 ./validator_latest.sh -u no
```

# docker-compose

As an alternative to running `docker` directly, `docker-compose` will start the validator and watchtower, a sidecar that watches for an updated `:latest` tag. Run the `run_docker_compose.sh` script to initialize your validator, or make changes as you would like.
