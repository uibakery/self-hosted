#!/bin/bash

MIN_VERSION_DOCKER="20.10.11"
MIN_VERSION_DOCKER_COMPOSE="1.29.2"
CUR_VERSION_UI_BAKERY="latest" 

function check_version {

 local Q_INSTALL_DOCKER="NO"
 local position=0
 local IFS=""

 if [[ "$1" == "DOCKER" ]]; then
   position=2
   IFS='.' read -ra min_version <<< "$MIN_VERSION_DOCKER"
 else
   position=1
   IFS='.' read -ra min_version <<< "$MIN_VERSION_DOCKER_COMPOSE"
 fi

 IFS=':' read -ra version_array <<< "$2"
 IFS='~' read -ra subversion_array <<< "${version_array[${position}]}"
 IFS='.' read -ra subsubversion_array <<< "${subversion_array[0]}"

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
       IFS='-' read -ra c_subsubversion_array <<< "${subsubversion_array[2]}"
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
     echo -e "\033[0m\033[0m\033[31m You need to manually upgrade the component to at least the minimum required version. Installation will be aborted !"
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
echo "Checking docker-ce ----------------------------"
I=`which docker`
if [ -n "$I" ]; then
   echo "Docker-ce is already installed...."
   if [[ "$OS_ID" == "$OS_AUTO_INSTALL" ]]; then
       J=`dpkg -s docker-ce | grep "Version" `
       echo "$J"
       check_version "DOCKER" "$J"
       f_result=$?
       if (( $f_result == 0 )); then
          NEED_INSTALL_DOCKER="NO"
       else
          NEXT_INSTALL_OPERATION="EXIT"
       fi
   else
      echo "Make sure the installed version of docker is ${MIN_VERSION_DOCKER} or higher. Continue? Y/n (Default - Y)"
      while read docker_version_y_n; do
        if [[ "$docker_version_y_n" == "Y" ]] || [[ "$docker_version_y_n" == "y" ]] || [[ "$docker_version_y_n" == "" ]]; then
         NEED_INSTALL_DOCKER="NO"
         break
        elif [[ "$docker_version_y_n" == "N" ]] || [[ "$docker_version_y_n" == "n" ]]; then
         exit
        else
         echo "Y - yes, i have have proper version of docker; N - no, i want to exit from install"
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
   echo "Docker-compose is already installed...."
   if [[ "$OS_ID" == "$OS_AUTO_INSTALL" ]]; then
       J=`dpkg -s docker-compose | grep "Version" `
       echo "$J"
       check_version "DOCKER_COMPOSE" "$J"
       f_result=$?
       if (( $f_result == 0 )); then
         NEED_INSTALL_DOCKER_COMPOSE="NO"
       else
         NEXT_INSTALL_OPERATION="EXIT"
       fi
    else
      echo "Make sure the installed version of docker-compose is ${MIN_VERSION_DOCKER_COMPOSE} or higher. Continue? Y/n (Default - Y)"
      while read docker_compose_version_y_n; do
        if [[ "$docker_compose_version_y_n" == "Y" ]] || [[ "$docker_compose_version_y_n" == "y" ]] || [[ "$docker_compose_version_y_n" == "" ]]; then
         NEED_INSTALL_DOCKER_COMPOSE="NO"
         break
        elif [[ "$docker_compose_version_y_n" == "N" ]] || [[ "$docker_compose_version_y_n" == "n" ]]; then
         exit
        else
         echo "Y - yes, i have have proper version of docker-compose; N - no, i want to exit from install"
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
   curl -fsSL https://get.docker.com -o get-docker.sh
   yes | sudo sh get-docker.sh
fi

if [[ "$NEED_INSTALL_DOCKER_COMPOSE" == "YES" ]]; then
   echo "----------------------------------------------------"
   echo "Installing Docker-compose  ....."
   yes | sudo apt install docker-compose
fi

echo "----------------------------------------------------"
if [[ "$CUR_VERSION_UI_BAKERY" == "latest" ]]; then
  file_name="ui-bakery-on-premise-vlatest.tar.gz"
else
  file_name="ui-bakery-on-premise_v${CUR_VERSION_UI_BAKERY}.tar.gz"
fi  
curl -k -L -o ${file_name} https://storageaccountrguib99d2.blob.core.windows.net/ui-bakery-cloud-on-premise/${file_name}

[ -d ./ui-bakery-on-premise ] || mkdir ui-bakery-on-premise

echo "----------------------------------------------------"
echo "Unpacking the archive....."
tar -xf ${file_name} -C ui-bakery-on-premise > /dev/null

echo "Configuring application settings....."
cd ui-bakery-on-premise
./setup.sh
echo -e "\033[m ---------------------------------------------"

echo "----------------------------------------------------"
echo "Building containers and running the application....."
sudo docker-compose up -d
