#!/bin/sh

if [ ! -f docker-compose.yml ]; then
  cp docker-compose.yml.dist docker-compose.yml
fi

# todo: test for my.env existence, that'll prevent docker-compose from seeing it as updated
touch my.env
mkdir -p ${HOME}/validator_data/

# todo: fill in the external IP
#MYIP=$(curl --silent api.ipify.org)

docker-compose up -d

