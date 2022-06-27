RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


echo "Enter license key: "
while read license; do
  test "$license" != "" && break
  echo -e "${RED}License key is required!${NC}"
  echo "Enter license key: "
done
echo -e "License key: ${license}\n"


echo -e "Enter PORT[3030]: "
while read port; do
  test "$port" == "" && break
  if (( $port > 1 )) && (( $port < 65536 ))
  then 
    break
  else
    echo -e "${RED}PORT isn't valid!${NC}"
  fi
  echo -e "Enter PORT[3030]: "
done
port=${port:-3030}
echo -e "PORT: ${port}\n"


echo -e "Enter server URL[http://localhost]: "
while read url; do
  test "$url" == "" && break
  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  if [[ $url =~ $regex ]]
  then 
    break
  else
    echo -e "${RED}URL isn't valid!${NC}"
  fi
  echo -e "Enter server URL[http://localhost]: "
done
url=${url:-http://localhost}
echo -e "URL: ${url}\n"

echo "UI_BAKERY_LICENSE_KEY=${license}" > .env
echo "UI_BAKERY_APP_SERVER_NAME=${url}:${port}" >> .env
echo "UI_BAKERY_WORKBENCH_PATH=${url}:3040" >> .env
echo "UI_BAKERY_PORT=${port}" >> .env

echo -e "${GREEN}UI Bakery setup is done!${NC}"
echo -e "Run ${CYAN}docker-compose up -d${NC} to bootstrap your instance!"

