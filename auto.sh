#!/bin/bash

# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install -y

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


routing_conf='{\n        \"domainStrategy\": \"IPIfNonMatch\",\n        \"rules\": [\n            {\n                \"type\": \"field\",\n                \"outboundTag\": \"blackhole\",\n                \"ip\": [\n                    \"geoip:private\",\n                    \"geoip:ir\"\n                ]\n            },\n            {\n                \"type\": \"field\",\n                \"port\": 53,\n                \"network\": \"tcp,udp\",\n                \"outboundTag\": \"DNS-Internal\"\n            },\n            {\n                \"type\": \"field\",\n                \"outboundTag\": \"blackhole\",\n                \"protocol\": [\n                    \"bittorrent\"\n                ]\n            },\n            {\n                \"outboundTag\": \"blackhole\",\n                \"domain\": [\n                    \"regexp:.*\\\\.ir$\",\n                    \"ext:iran.dat:ir\",\n                    \"ext:iran.dat:other\",\n                    \"geosite:category-ir\",\n                    \"blogfa\",\n                    \"bank\",\n                    \"tebyan.net\",\n                    \"beytoote.com\",\n                    \"Film2movie.ws\",\n                    \"Setare.com\",\n                    \"downloadha.com\",\n                    \"Sanjesh.org\"\n                ],\n                \"type\": \"field\"\n            }\n        ]\n    }"'


xray_config="/var/lib/marzban/xray_config.json"

formatted_json=$(echo "$json" | jq -c '.')

json=$(cat $xray_config)

new_json=$(echo "$formatted_json" | jq --arg routing_conf "$routing_conf" '.routing = $routing_conf')

echo "$new_json" > "$xray_config"

cd /opt/marzban

docker compose up -d

clear

# Configure ENV
update_env_variable() {
  local env_file="$1"
  local variable_name="$2"
  local new_value="$3"

  while IFS= read -r line; do
    if [[ $line == \#* ]]; then
      echo "$line"
    else
      if [[ $line == "$variable_name="* ]]; then
        echo "$variable_name=$new_value"
      else
        echo "$line"
      fi
    fi
  done < "$env_file" > temp_env && mv temp_env "$env_file"

  echo "Variable $variable_name was updated with value $new_value in file $env_file."
}

env_file="/opt/marzban/.env"

read -e -p "Please enter your port: " -i 8000 port

sed -i "s/UVICORN_PORT = .*/UVICORN_PORT = $port/" $env_file

update_env_variable "$env_file" "UVICORN_SSL_CERTFILE" "$pubkey"
update_env_variable "$env_file" "UVICORN_SSL_KEYFILE" "$privkey"
update_env_variable "$env_file" "XRAY_ASSETS_PATH" "$assets"


read -p "Please enter your telegram api token: " telegram_api_token
read -p "Please enter your telegram user id: " telegram_user_id

if [[ -n $telegram_api_token ]]; then
    update_env_variable "$env_file" "TELEGRAM_API_TOKEN" "$telegram_api_token"
fi

if [[ -n $telegram_user_id ]]; then
    update_env_variable "$env_file" "TELEGRAM_ADMIN_ID" "$telegram_user_id"
fi


clear

marzban restart