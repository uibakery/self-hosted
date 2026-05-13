RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
LICENCE_SERVER="https://cloud.uibakery.io/onpremise/license"
GET_KEY_LINK="https://cloud.uibakery.io/settings/on-premise-license"


if [ -z "${SESSION_ID}" ];
then
  SESSION_ID=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 42 | xargs -0)
  curl --connect-timeout 10 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "start_custom", "session": "'"${SESSION_ID}"'"}' $LICENCE_SERVER  &> /dev/null
fi

printf "${CYAN}Starting UI Bakery configuration...\n${NC}"

printf "Enter PORT (for example, 3030):\n"
while true; do
  if ! read port; then
    printf "${RED}PORT is required but input could not be read.${NC}\n"
    exit 1
  fi
  if [[ $port =~ ^[0-9]+$ ]] && (( port > 1 )) && (( port < 65536 ))
  then
    break
  else
    printf "${RED}PORT is required and must be between 2 and 65535.${NC}\n"
  fi
  printf "Enter PORT (for example, 3030):"
done
printf "PORT: ${port}\n\n"


printf "Enter server URL without port (for example, http://localhost):\n"
while true; do
  if ! read url; then
    printf "${RED}URL is required but input could not be read.${NC}\n"
    exit 1
  fi
  regex='^https?://[A-Za-z0-9.-]+$'
  if [[ $url =~ $regex ]]
  then
    break
  else
    printf "${RED}URL is required and must start with http:// or https://, without port or trailing slash.${NC}\n"
  fi
  printf "Enter server URL without port (for example, http://localhost):"
done
printf "URL: ${url}\n\n"

jwt_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 42 | xargs -0)
jwt_service_account_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 55 | xargs -0)
jwt_refresh_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 42 | xargs -0)
credentials_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 32 | xargs -0)
project_private_key_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 32 | xargs -0)
auth_device_info_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 32 | xargs -0)
mfa_secret=$(LC_ALL=C tr -cd "A-Za-z0-9" < /dev/urandom | head -c 32 | xargs -0)

if [ -e .env ]; then
  cp .env .env_old
fi


echo "UI_BAKERY_VERSION=latest" > .env
echo "UI_BAKERY_APP_SERVER_NAME=${url}:${port}" >> .env
echo "UI_BAKERY_PORT=${port}" >> .env
echo "UI_BAKERY_JWT_SECRET=${jwt_secret}" >> .env
echo "UI_BAKERY_JWT_SERVICE_ACCOUNT_SECRET=${jwt_service_account_secret}" >> .env
echo "UI_BAKERY_JWT_REFRESH_SECRET=${jwt_refresh_secret}" >> .env
echo "UI_BAKERY_CREDENTIALS_SECRET=${credentials_secret}" >> .env
echo "UI_BAKERY_PROJECT_PRIVATE_KEY_SECRET=${project_private_key_secret}" >> .env
echo "UI_BAKERY_AUTH_DEVICE_INFO_SECRET=${auth_device_info_secret}" >> .env
echo "UI_BAKERY_MFA_SECRET=${mfa_secret}" >> .env
echo "UI_BAKERY_INTERNAL_API_URL=http://bakery-back:8080" >> .env

printf "${CYAN}License setup\n${NC}"
printf "Register and generate an on-premise license key:\n"
printf "${GET_KEY_LINK}\n\n"
printf "Enter license key:\n"
while read license; do
  test "$license" != "" && break
  printf "${RED}License key is required!${NC}\n"
  printf "Enter license key:"
done

echo "UI_BAKERY_LICENSE_KEY=${license}" >> .env

curl --connect-timeout 15 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "license", "session": "'"${SESSION_ID}"'", "key": "'"${license}"'"}' $LICENCE_SERVER  &> /dev/null


if [ -e .env ]; then
  printf "${CYAN}Finishing up installation...${NC}\n"
  LICENSE_KEY_LINE=$(grep -E -i -o 'UI_BAKERY_LICENSE_KEY=(.*)$' ./.env)
  curl --connect-timeout 15 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "finish", "session": "'"${SESSION_ID}"'", "key": "'"${LICENSE_KEY_LINE/UI_BAKERY_LICENSE_KEY=/}"'"}' $LICENCE_SERVER &> /dev/null
fi

printf "${GREEN}Running UI Bakery at ${url}:${port}${NC}\n"
