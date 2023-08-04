#!/bin/bash

# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install -y

# /usr/bin/expect <<EOD
#   set timeout 1
#   spawn echo -n ^C
#   expect -exact "^C"
#   send "\x03"
#   expect eof
# EOD

clear
# create admin

marzban cli admin create --sudo


# Get SSL
read -p "Please enter your domain: " domain

sudo apt-get install certbot -y
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $domain
certbot renew --dry-run -y

pubkey="/etc/letsencrypt/live/$domain/fullchain.pem"
privkey="/etc/letsencrypt/live/$domain/privkey.pem"

/usr/bin/expect <<EOD
  set timeout 1
  spawn echo -n ^C
  expect -exact "^C"
  send "\x03"
  expect eof
EOD


mkdir /var/lib/marzban/certs

cp "$pubkey" /var/lib/marzban/certs/fullchain.pem
cp "$privkey" /var/lib/marzban/certs/key.pem

clear

# Ban iranian applications and websites
assets="/var/lib/marzban/assets/"

mkdir -p "$assets"

wget -O "$assets/geosite.dat" https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat

wget -O "$assets/geoip.dat" https://github.com/v2fly/geoip/releases/latest/download/geoip.dat

wget -O "$assets/iran.dat" https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat


xray_config="/var/lib/marzban/xray_config.json"

routing_file="https://github.com/mmdzov/auto-conf-marzban/raw/main/routing.json"

jq --argfile routing "$routing_file" '.routing = $routing' "$xray_config" > tmp.json && mv tmp.json "$xray_config"

cd /opt/marzban

docker compose up -d

clear

# Configure ENV

env_file="/opt/marzban/.env"

read -e -p "Please enter your port: " -i 8000 port

sed -i "s/UVICORN_PORT = .*/UVICORN_PORT = $port/" $env_file

sed -i 's/# UVICORN_SSL_CERTFILE = "\/var\/lib\/marzban\/certs\/example.com\/fullchain.pem"/UVICORN_SSL_CERTFILE = "\/var\/lib\/marzban\/certs\/fullchain.pem"/' $env_file
sed -i 's/# UVICORN_SSL_KEYFILE = "\/var\/lib\/marzban\/certs\/example.com\/key.pem"/UVICORN_SSL_KEYFILE = "\/var\/lib\/marzban\/certs\/key.pem"/' $env_file

sed -i 's/# XRAY_ASSETS_PATH = "\/usr\/local\/share\/xray"/XRAY_ASSETS_PATH = "\/var\/lib\/marzban\/assets\/"/' $env_file

read -p "Please enter your telegram api token: " telegram_api_token
read -p "Please enter your telegram user id: " telegram_user_id

if [[ -n $telegram_api_token ]]; then
    sed -i 's/# TELEGRAM_API_TOKEN = "123456789:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"/TELEGRAM_API_TOKEN = "'"$telegram_api_token"'"/' $env_file
fi

if [[ -n $telegram_user_id ]]; then
    sed -i 's/# TELEGRAM_ADMIN_ID = "987654321"/TELEGRAM_ADMIN_ID = "'"$telegram_user_id"'"/' $env_file
fi


clear

marzban restart