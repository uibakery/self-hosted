RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

printf "${CYAN}Starting UI Bakery configuration...\n${NC}"

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


echo "UI_BAKERY_APP_SERVER_NAME=${url}:${port}" > .env
echo "UI_BAKERY_PORT=${port}" >> .env
echo "UI_BAKERY_JWT_SECRET=${jwt_secret}" >> .env
echo "UI_BAKERY_JWT_SERVICE_ACCOUNT_SECRET=${jwt_service_account_secret}" >> .env
echo "UI_BAKERY_JWT_REFRESH_SECRET=${jwt_refresh_secret}" >> .env
echo "UI_BAKERY_CREDENTIALS_SECRET=${credentials_secret}" >> .env

printf "${CYAN}Starting license setup...\n${NC}"
printf "${GREEN}Do you already have a UI Bakery license key?\n${NC}"
echo "Y - enter your license key, N - start a free trial. (Default - Y)"
while read have_license_key_y_n; do
  if [[ "$have_license_key_y_n" == "Y" ]] || [[ "$have_license_key_y_n" == "y" ]] || [[ "$have_license_key_y_n" == "" ]]; then
    CUSTOM_LICENSE_KEY="YES"
    break
  elif [[ "$have_license_key_y_n" == "N" ]] || [[ "$have_license_key_y_n" == "n" ]]; then
    echo "Enter working email address to generate the free trial license of UI Bakery:"
    while read email; do

      email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
      if [[ $email =~ $email_regex ]] ; then
        break
      else
        printf "${RED}Valid email is required to request a license${NC}\n"
        printf "Enter email:\n"
      fi
    done

    printf "EMAIL: ${email}\n\n"
    CUSTOM_LICENSE_KEY="NO"
    break
  else
   echo "Y - enter your license key, N - start a free trial. (Default - Y)"
  fi
done

if [[ "$CUSTOM_LICENSE_KEY" == "NO" ]]; then
  printf "${CYAN}Issuing a trial license...\n${NC}"
  license=$(curl --connect-timeout 15 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "start_trial", "session": "'"${SESSION_ID}"'", "email": "'"${email}"'"}' $LICENCE_SERVER)
  if [[ "$license" == "" ]]; then
    printf "${RED}Failed to contact a license server. Please contact UI Bakery support at ${GET_KEY_LINK}\n${NC}"
    CUSTOM_LICENSE_KEY="YES"
  else
    printf "${GREEN}Done! Your 14 days license is activated.\n${NC}"
  fi
fi

if [[ "$CUSTOM_LICENSE_KEY" == "YES" ]]; then
  printf "Enter license key:\n"
  while read license; do
    test "$license" != "" && break
    printf "${RED}License key is required!${NC}\n"
    printf "Enter license key:"
  done
fi

echo "UI_BAKERY_LICENSE_KEY=${license}" >> .env

curl --connect-timeout 15 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "license", "session": "'"${SESSION_ID}"'", "key": "'"${license}"'"}' $LICENCE_SERVER  &> /dev/null


if [ -e .env ]; then
  printf "${CYAN}Finishing up installation...${NC}\n"
  LICENSE_KEY_LINE=$(grep -E -i -o 'UI_BAKERY_LICENSE_KEY=(.*)$' ./.env)
  curl --connect-timeout 15 --max-time 20 -s -XPOST -H "Content-type: application/json" -d '{"event": "finish", "session": "'"${SESSION_ID}"'", "key": "'"${LICENSE_KEY_LINE/UI_BAKERY_LICENSE_KEY=/}"'"}' $LICENCE_SERVER &> /dev/null
fi

printf "${GREEN}Running UI Bakery at ${url}:${port}${NC}\n"
