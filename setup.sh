RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


printf "Enter license key:\n"
while read license; do
  test "$license" != "" && break
  printf "${RED}License key is required!${NC}\n"
  printf "Enter license key:"
done
printf "License key: ${license}\n\n"


printf "Enter PORT[3030]:\n"
while read port; do
  test "$port" == "" && break
  if (( $port > 1 )) && (( $port < 65536 ))
  then
    break
  else
    printf "${RED}PORT isn't valid!${NC}\n"
  fi
  printf "Enter PORT[3030]:"
done
port=${port:-3030}
printf "PORT: ${port}\n\n"


printf "Enter server URL[http://localhost]:\n"
while read url; do
  test "$url" == "" && break
  regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
  if [[ $url =~ $regex ]]
  then
    break
  else
    printf "${RED}URL isn't valid!${NC}\n"
  fi
  printf "Enter server URL[http://localhost]:"
done
url=${url:-http://localhost}
printf "URL: ${url}\n\n"

jwt_secret=$(LC_CTYPE=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 42 | xargs -0)
jwt_service_account_secret=$(LC_CTYPE=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 55 | xargs -0)
jwt_refresh_secret=$(LC_CTYPE=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 42 | xargs -0)
credentials_secret=$(LC_CTYPE=C tr -cd "A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)\\-+=" < /dev/urandom | head -c 32 | xargs -0)

if [ -e .env ]; then
  cp .env .env_old
fi

echo "UI_BAKERY_LICENSE_KEY=${license}" > .env
echo "UI_BAKERY_APP_SERVER_NAME=${url}:${port}" >> .env
echo "UI_BAKERY_PORT=${port}" >> .env
echo "UI_BAKERY_JWT_SECRET=${jwt_secret}" >> .env
echo "UI_BAKERY_JWT_SERVICE_ACCOUNT_SECRET=${jwt_service_account_secret}" >> .env
echo "UI_BAKERY_JWT_REFRESH_SECRET=${jwt_refresh_secret}" >> .env
echo "UI_BAKERY_CREDENTIALS_SECRET=${credentials_secret}" >> .env 

printf "${CYAN}Verifying your license key...${NC}\n"
LICENSE_KEY_LINE=$(grep -E -i -o 'UI_BAKERY_LICENSE_KEY=(.*)$' ./.env)
curl -XPOST -H "Content-type: application/json" -d '{"event": "install", "key": "'"${LICENSE_KEY_LINE}"'"}' 'https://cloud.uibakery.io/api/automation/6HOZ4akpRr?key=eeac94fe-07f7-4167-ac8e-653346347adb'
printf "${GREEN}License key verification succeeded!${NC}\n"

printf "${GREEN}UI Bakery setup is done!${NC}\n"
printf "Run ${CYAN}docker-compose up -d${NC} to bootstrap your instance!\n"
