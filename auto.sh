#!/bin/bash

# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

kill -9 888

clear

# create admin

marzban cli admin create --sudo


# Get SSL
read -p "Please enter your domain: " domain

echo y | sudo apt-get install certbot -y
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $domain
echo y | certbot renew --dry-run

pubkey="/etc/letsencrypt/live/$domain/fullchain.pem"
privkey="/etc/letsencrypt/live/$domain/privkey.pem"

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


routing_conf='{
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "outboundTag": "blackhole",
                "ip": [
                    "geoip:private",
                    "geoip:ir"
                ]
            },
            {
                "type": "field",
                "port": 53,
                "network": "tcp,udp",
                "outboundTag": "DNS-Internal"
            },
            {
                "type": "field",
                "outboundTag": "blackhole",
                "protocol": [
                    "bittorrent"
                ]
            },
            {
                "outboundTag": "blackhole",
                "domain": [
                    "regexp:.*\\.ir$",
                    "ext:iran.dat:ir",
                    "ext:iran.dat:other",
                    "geosite:category-ir",
                    "blogfa",
                    "bank",
                    "tebyan.net",
                    "beytoote.com",
                    "Film2movie.ws",
                    "Setare.com",
                    "downloadha.com",
                    "Sanjesh.org"
                ],
                "type": "field"
            }
        ]
    }'


xray_config="/var/lib/marzban/xray_config.json"

json=$(cat $xray_config)

new_json=$(echo "$json" | jq --arg routing_conf "$routing_conf" '.routing = $routing_conf')

echo "$new_json" > "$xray_config"

cd /opt/marzban

docker compose up -d

clear

# Configure ENV
port=8000

env="/opt/marzban/.env"

read -e -p "Please enter your port: " -i $port port

sed -i "s/UVICORN_PORT = .*/UVICORN_PORT = $port/" "$env"

sed -i 's/# UVICORN_SSL_CERTFILE = .*/UVICORN_SSL_CERTFILE = '"$pubkey"'/' $env

sed -i 's/# UVICORN_SSL_KEYFILE = .*/UVICORN_SSL_KEYFILE = '"$privkey"'/' $env

sed -i 's/# XRAY_ASSETS_PATH = .*/XRAY_ASSETS_PATH = '"$assets"'/' $env


read -p "Please enter your telegram api token: " telegram_api_token
read -p "Please enter your telegram user id: " telegram_user_id

if [[ -n $telegram_api_token ]]; then
    sed -i 's/# TELEGRAM_API_TOKEN = .*/TELEGRAM_API_TOKEN = '"$telegram_api_token"'/' $env
fi

if [[ -n $telegram_user_id ]]; then
    sed -i 's/# TELEGRAM_ADMIN_ID = .*/TELEGRAM_ADMIN_ID = '"$telegram_user_id"'/' $env
fi


clear

marzban restart