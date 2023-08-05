#!/bin/bash

cd

clear

# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install -y

clear

# Create admin
marzban cli admin create --sudo


# Get SSL
domain=""
read -p "Please enter your domain.com/sub.domain.com: " domain

if [ ! -d "/etc/letsencrypt/live/$domain" ]; then
    sudo apt-get install certbot -y
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$domain"
    certbot renew --dry-run
fi


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

curl -o routing.json https://raw.githubusercontent.com/mmdzov/auto-conf-marzban/main/routing.json
curl -o outbounds.json https://raw.githubusercontent.com/mmdzov/auto-conf-marzban/main/outbounds.json

# jq --argjson newRouting "$(cat routing.json)" '.routing = $newRouting' $xray_config > temp_config.json
# jq --argjson newOutbounds "$(cat outbounds.json)" '.outbounds = $newOutbounds' $xray_config > temp_config.json
jq --argfile newRouting routing.json --argfile newOutbounds outbounds.json '.routing = $newRouting | .outbounds += $newOutbounds' $xray_config > temp_config.json

mv temp_config.json $xray_config

cd /opt/marzban

docker compose up -d

clear


# Configure ENV
env_file="/opt/marzban/.env"

read -p "Please enter your port: " port

if [[ -n $port ]]; then
    sed -i "s/UVICORN_PORT = .*/UVICORN_PORT = $port/" $env_file
fi

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

cd

# Install BBR2
bbr2="y"
read -p "Do you want to limit the number of connected users? [y/n]: " bbr2

if [[ "$bbr2" == "y" || "$bbr2" == "Y" ]]; then

    sudo apt update

    git clone https://github.com/linhua55/bbr2.git

    cd bbr2

    sudo chmod +x install.sh

    sudo ./install.sh

    clear

fi

# Restart marzban
marzban restart

echo "Happy hacking :)"