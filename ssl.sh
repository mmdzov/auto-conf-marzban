#!/bin/bash

source auto.sh

read -p "Please enter your domain: " domain

echo y | sudo apt-get install certbot -y
certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $domain
echo y | certbot renew --dry-run

global variable
pubkey="/etc/letsencrypt/live/$domain/fullchain.pem"

global variable
privkey="/etc/letsencrypt/live/$domain/privkey.pem"

mkdir /var/lib/marzban/certs

cp "$pubkey" /var/lib/marzban/certs/fullchain.pem
cp "$privkey" /var/lib/marzban/certs/key.pem
