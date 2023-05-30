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

echo ""
echo "Checking docker, min required version $MIN_VERSION_DOCKER"
I=`which docker`
if [ -n "$I" ]; then
   printf "${GREEN}Docker is already installed:\n${NC}"
   J=`docker -v`
  echo "$J"
else
  printf "${RED}Could not find docker\n${NC}"

  printf "Install docker? (Default - Y)\n"
  while read install_docker_y_n; do
    if [[ "$install_docker_y_n" == "Y" ]] || [[ "$install_docker_y_n" == "y" ]] || [[ "$install_docker_y_n" == "" ]]; then
       echo "----------------------------------------------------"
       echo "Installing Docker  ....."
       printf "Docker installation requires sudo permissions\n"
       curl -fsSL https://get.docker.com -o get-docker.sh
       yes | sudo sh get-docker.sh
      break
    else
      printf "${RED}Skipping docker installation. The script will try to proceed.\n${NC}"
      break
    fi
  done
fi

DOCKER_COMPOSE_COMMAND=""
I=`which docker-compose`
if [ -n "$I" ]; then
  DOCKER_COMPOSE_COMMAND="docker-compose"
else
  J=`docker compose version --short`
  if [ -n "$J" ]; then
    DOCKER_COMPOSE_COMMAND="docker compose"
  fi
fi

echo ""
echo "Checking docker-compose, min required version $MIN_VERSION_DOCKER_COMPOSE"

if [ -n "$DOCKER_COMPOSE_COMMAND" ]; then
  printf "${GREEN}Docker-compose is already installed:\n${NC}"
  J=`$DOCKER_COMPOSE_COMMAND version --short`
  echo "$J"
else
  printf "${RED}Could not find docker-compose. The script will try to proceed.\n${NC}"
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

if [ -z "$DOCKER_COMPOSE_COMMAND" ]; then
  printf "${RED}Could not find docker-compose to run UI Bakery. Please install docker-compose and run 'docker compose up -d' manually.\n${NC}"
  exit 1
else
  sudo $DOCKER_COMPOSE_COMMAND up -d
fi

