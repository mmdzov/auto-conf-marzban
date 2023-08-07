#!/bin/bash

cd

# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install -y


clear

# Create admin
marzban cli admin create --sudo


# Get SSL
pubkey="/etc/letsencrypt/live/example.com/fullchain.pem"
privkey="/etc/letsencrypt/live/example.com/privkey.pem"

read -p "Please enter your domain.com/sub.domain.com: " domain

pubkey="/etc/letsencrypt/live/$domain/fullchain.pem"
privkey="/etc/letsencrypt/live/$domain/privkey.pem"

if [[ -n $domain && ! -d "/etc/letsencrypt/live/$domain" ]]; then
    sudo apt-get install certbot -y
    certbot certonly --standalone --agree-tos --register-unsafely-without-email -d "$domain"
    certbot renew --dry-run
fi

if [[ -n $domain ]]; then 
    mkdir /var/lib/marzban/certs

    cp "$pubkey" /var/lib/marzban/certs/fullchain.pem
    cp "$privkey" /var/lib/marzban/certs/key.pem
fi

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

jq --argfile newRouting routing.json --argfile newOutbounds outbounds.json '.routing = $newRouting | .outbounds = $newOutbounds' $xray_config > temp_config.json

mv temp_config.json $xray_config

cd /opt/marzban

docker compose up -d

clear


# Configure ENV
env_file="/opt/marzban/.env"

read -p "Please enter your port: " port

if [[ -z $port ]]; then 
    port=8000
fi

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

cd


# Install BBR2
read -p "Do you want to install bbr2? [y/n]: " bbr2

default_bbr2="y"

if [[ -z $bbr2 ]]; then 
    bbr2="$default_bbr2"
fi

if [[ ! -f "/root/bbr2.sh" ]]; then

    if [[ "$bbr2" == "y" || "$bbr2" == "Y" ]]; then

        wget --no-check-certificate -q -O bbr2.sh "https://github.com/yeyingorg/bbr2.sh/raw/master/bbr2.sh" && chmod +x bbr2.sh && bash bbr2.sh

        clear

    fi

fi

clear

# # Limit users
read -p "Do you want to limit the number of connected users? [y/n]: " limit_user

default_limit_user="y"

if [[ -z $limit_user ]]; then 
    limit_user="$default_limit_user"
fi


if [[ "$limit_user" == "y" || "$limit_user" == "Y" ]]; then

    read -p "Enter the limit number: " limit_number


    read -p "Enter the panel username: " Username
    read -sp "Enter the panel password: " Password

    echo "نام کاربری: $Username ، رمز عبور: $Password"

    if [[ ! -d "/root/V2IpLimit" ]]; then

        apt install python3-pip

        pip install websockets

        pip install pytz

        git clone https://github.com/houshmand-2005/V2IpLimit.git

        cd V2IpLimit

        cd Marzban

    else 
        cd /root/V2IpLimit/Marzban
    fi
    



    v2iplimit_file="v2iplimit_config.json"

    jq ".LIMIT_NUMBER = $limit_number" $v2iplimit_file > tmp.json 
    jq '.PANEL_USERNAME = "'"$Username"'"' $v2iplimit_file > tmp.json 
    jq '.PANEL_PASSWORD = "'"$Password"'"' $v2iplimit_file > tmp.json 
    jq '.PANEL_DOMAIN = "'"$domain:$port"'"' $v2iplimit_file > tmp.json 

    mv tmp.json $v2iplimit_file

    screen

    python3 v2_ip_limit.py

fi




# Remove extra files
cd
rm -rf tmp.json
rm -rf outbounds.json
rm -rf routing.json


clear

cat << EOF
Happy hacking :)

1. Reboot your system -> sudo reboot
2. Start Marzban -> marzban start

EOF