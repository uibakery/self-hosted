#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
LICENCE_SERVER="https://cloud.uibakery.io/onpremise/license"
GET_KEY_LINK="https://cloud.uibakery.io/onpremise/get-license"
SESSION_ID=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 42 | xargs -0)

printf "${GREEN}Welcome to UI Bakery installation script. Setup process won't take more than a couple of minutes.\n${NC}"
printf "${CYAN}Starting dependencies configuration...\n${NC}"
curl --connect-timeout 10 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "start", "session": "'"${SESSION_ID}"'"}' $LICENCE_SERVER  &> /dev/null

MIN_VERSION_DOCKER="20.10.11"
MIN_VERSION_DOCKER_COMPOSE="1.29.2"

OS_ID=""
if [ -r /etc/os-release ]; then
 OS_ID="$(. /etc/os-release && echo "$ID")"
fi

echo ""
echo "Checking docker, min required version $MIN_VERSION_DOCKER"
I=`which docker`
if [ -n "$I" ]; then
   printf "${GREEN}Docker is already installed:\n${NC}"
   J=`docker version --format '{{.Server.Version}}'`
  echo "$J"
else
  echo "Please, install docker first."
  exit
fi

echo ""
echo "Checking docker-compose, min required version $MIN_VERSION_DOCKER_COMPOSE"
I=`which docker-compose`
if [ -n "$I" ]; then
   printf "${GREEN}Docker-compose is already installed:\n${NC}"
   J=`docker-compose version --short`
  echo "$J"
else
  echo "Please, install docker-compose first."
  exit
fi


printf "Downloading setup files ----------------------------------\n\n"

[ -d ./ui-bakery-on-premise ] || mkdir ui-bakery-on-premise
cd ui-bakery-on-premise

if [[ "$1" == "TEST" ]]; then
  cp ../setup.sh ./setup.sh
  cp ../update.sh ./update.sh
else
  curl -s -k -L -o setup.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/setup.sh
  curl -s -k -L -o update.sh https://raw.githubusercontent.com/uibakery/self-hosted/main/update.sh
fi
curl -s -k -L -o docker-compose.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose.yml

export SESSION_ID
bash ./setup.sh
echo "Starting the application... May require sudo password"

sudo docker-compose up -d
