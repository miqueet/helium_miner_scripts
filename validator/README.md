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


I haven't done some of the checks ive done in the past and i will make a script to make staking the coins a bit more automated. I also hope to add in a command line arg to delete the validator data dir.
