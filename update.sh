RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

LICENSE_KEY_LINE=$(grep -E -i -o 'UI_BAKERY_LICENSE_KEY=(.*)$' ./.env)
curl -XPOST -H "Content-type: application/json" -d '{"event": "update", "key": "'"${LICENSE_KEY_LINE}"'"}' 'https://cloud.uibakery.io/api/automation/6HOZ4akpRr?key=eeac94fe-07f7-4167-ac8e-653346347adb'

if [ -e docker-compose.yaml ]; then
  cp docker-compose.yaml docker-compose_old.yaml
  printf "New ${CYAN}docker-compose.yaml${NC} is downloaded, you can find old version at ${CYAN}docker-compose_old.yaml${NC}\n"
  curl -k -L -o docker-compose.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose.yml

  sudo docker-compose build --pull 
  sudo docker-compose pull && sudo docker-compose up -d
  sudo docker image prune -a -f
fi

if [ -e docker-compose-external-db.yaml ]; then
  cp docker-compose-external-db.yaml docker-compose-external-db_old.yaml
  printf "New ${CYAN}New docker-compose-external-db.yaml${NC} is downloaded, you can find old version at ${CYAN}docker-compose-external-db_old.yaml${NC}\n"
  curl -k -L -o docker-compose-external-db.yml https://raw.githubusercontent.com/uibakery/self-hosted/main/docker-compose-external-db.yml

  sudo docker-compose -f docker-compose-external-db.yaml build --pull 
  sudo docker-compose -f docker-compose-external-db.yaml pull && sudo docker-compose -f docker-compose-external-db.yaml up -d
  sudo docker image prune -a -f
fi

printf "${GREEN}UI Bakery update is done!${NC}\n"