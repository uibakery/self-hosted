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

function check_version {

 local Q_INSTALL_DOCKER="NO"
 local IFS=""

 if [[ "$1" == "DOCKER" ]]; then
   IFS='.' read -ra min_version <<< "$MIN_VERSION_DOCKER"
 else
   IFS='.' read -ra min_version <<< "$MIN_VERSION_DOCKER_COMPOSE"
 fi

 IFS=' ' read -ra version_array <<< "$2"
 IFS='.' read -ra subsubversion_array <<< "${version_array[2]}"

 local c_version="${subsubversion_array[0]//[[:space:]]/}"
 if (( $c_version < "${min_version[0]}" )); then
   Q_INSTALL_DOCKER="YES"
 elif (( $c_version > "${min_version[0]}" )); then
   Q_INSTALL_DOCKER="NO"
 else
    local c_subversion="${subsubversion_array[1]//[[:space:]]/}"
    if (( $c_subversion < "${min_version[1]}" )); then
       Q_INSTALL_DOCKER="YES"
    elif (( $c_subversion > "${min_version[1]}" ));  then
       Q_INSTALL_DOCKER="NO"
    else
       IFS=',' read -ra c_subsubversion_array <<< "${subsubversion_array[2]}"
       local c_subsubversion="${c_subsubversion_array[0]//[[:space:]]/}"
       if (( $c_subsubversion < "${min_version[2]}" ));  then
          Q_INSTALL_DOCKER="YES"
       else
          Q_INSTALL_DOCKER="NO"
       fi
    fi
 fi
 local Q_NEED_INSTALL_DOCKER=0
 if [[ "$Q_INSTALL_DOCKER" == "YES" ]]; then
     echo "The minimum required version should be ${min_version[0]}.${min_version[1]}.${min_version[2]}"
     echo -e "\033[0m\033[0m\033[31m You need to manually upgrade the component to at least the minimum required version. Installation will be aborted."
     echo -e "\033[m"
     Q_NEED_INSTALL_DOCKER=1
 fi

  return $Q_NEED_INSTALL_DOCKER
}

OS_ID=""
if [ -r /etc/os-release ]; then
 OS_ID="$(. /etc/os-release && echo "$ID")"
fi
OS_AUTO_INSTALL="ubuntu"

NEXT_INSTALL_OPERATION=""
echo ""
echo "Checking docker ----------------------------"
I=`which docker`
if [ -n "$I" ]; then
   printf "${GREEN}Docker is already installed\n${NC}"
   if [[ "$OS_ID" == "$OS_AUTO_INSTALL" ]]; then
       J=`docker -v`
       echo "$J"
       check_version "DOCKER" "$J"
       f_result=$?
       if (( $f_result == 0 )); then
          NEED_INSTALL_DOCKER="NO"
       else
          NEXT_INSTALL_OPERATION="EXIT"
       fi
   else
      echo "Make sure the installed version of docker is ${MIN_VERSION_DOCKER} or higher."
      echo "Continue? Y/n (Default - Y)"
      while read docker_version_y_n; do
        if [[ "$docker_version_y_n" == "Y" ]] || [[ "$docker_version_y_n" == "y" ]] || [[ "$docker_version_y_n" == "" ]]; then
         NEED_INSTALL_DOCKER="NO"
         break
        elif [[ "$docker_version_y_n" == "N" ]] || [[ "$docker_version_y_n" == "n" ]]; then
         exit
        else
         echo "Y - yes, I have have proper version of docker; N - no, I want to exit from install"
        fi
     done
   fi
else
    if [[ "$OS_ID" == "$OS_AUTO_INSTALL" ]]; then
       NEED_INSTALL_DOCKER="YES"
    else
       echo "Please, install docker first."
       exit
    fi
fi

echo ""
echo "Checking docker-compose ----------------------------"
I=`which docker-compose`
if [ -n "$I" ]; then
   printf "${GREEN}Docker-compose is already installed\n${NC}"
   if [[ "$OS_ID" == "$OS_AUTO_INSTALL" ]]; then
       J=`docker-compose -v`
       echo "$J"
       check_version "DOCKER_COMPOSE" "$J"
       f_result=$?
       if (( $f_result == 0 )); then
         NEED_INSTALL_DOCKER_COMPOSE="NO"
       else
         NEXT_INSTALL_OPERATION="EXIT"
       fi
    else
      echo "Make sure the installed version of docker-compose is ${MIN_VERSION_DOCKER_COMPOSE} or higher."
      echo "Continue? Y/n (Default - Y)"
      while read docker_compose_version_y_n; do
        if [[ "$docker_compose_version_y_n" == "Y" ]] || [[ "$docker_compose_version_y_n" == "y" ]] || [[ "$docker_compose_version_y_n" == "" ]]; then
         NEED_INSTALL_DOCKER_COMPOSE="NO"
         break
        elif [[ "$docker_compose_version_y_n" == "N" ]] || [[ "$docker_compose_version_y_n" == "n" ]]; then
         exit
        else
         echo "Y - yes, I have have proper version of docker-compose; N - no, I want to exit from install"
        fi
     done
    fi
else
    if [[ "$OS_ID" == "$OS_AUTO_INSTALL" ]]; then
       NEED_INSTALL_DOCKER_COMPOSE="YES"
    else
       echo "Please, install docker-compose first."
       exit
    fi
fi

if [[ "$NEXT_INSTALL_OPERATION" == "EXIT" ]]; then
 exit
fi

if [[ "$NEED_INSTALL_DOCKER" == "YES" ]]; then
   echo "----------------------------------------------------"
   echo "Installing Docker  ....."
   printf "Docker installation requries sudo permissions\n"
   curl -fsSL https://get.docker.com -o get-docker.sh
   yes | sudo sh get-docker.sh
fi

if [[ "$NEED_INSTALL_DOCKER_COMPOSE" == "YES" ]]; then
   echo "----------------------------------------------------"
   echo "Installing Docker-compose  ....."
   sudo curl -s -L "https://github.com/docker/compose/releases/download/${MIN_VERSION_DOCKER_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
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
echo "Running the application..."

sudo docker-compose up -d
