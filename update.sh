RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
LICENCE_SERVER="https://cloud.uibakery.io/onpremise/license"

if [ -e .env ]; then
  LICENSE_KEY_LINE=$(grep -E -i -o 'UI_BAKERY_LICENSE_KEY=(.*)$' ./.env)
  curl -s -XPOST -H "Content-type: application/json" -d '{"event": "update", "key": "'"${LICENSE_KEY_LINE/UI_BAKERY_LICENSE_KEY=/}"'"}' $LICENCE_SERVER  &> /dev/null
fi

printf "Docker compose restart requries sudo permissions\n"

if [ -e docker-compose.yml ]; then
  cp docker-compose.yml docker-compose_old.yml
  curl -s -k -L -o docker-compose.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose.yml

  sudo docker-compose build --pull 
  sudo docker-compose pull && sudo docker-compose up -d
  sudo docker image prune -a -f
fi

if [ -e docker-compose-external-db.yml ]; then
  cp docker-compose-external-db.yml docker-compose-external-db_old.yml
  curl -s -k -L -o docker-compose-external-db.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose-external-db.yml

  sudo docker-compose -f docker-compose-external-db.yml build --pull 
  sudo docker-compose -f docker-compose-external-db.yml pull && sudo docker-compose -f docker-compose-external-db.yml up -d
  sudo docker image prune -a -f
fi

printf "${GREEN}UI Bakery update is done!${NC}\n"