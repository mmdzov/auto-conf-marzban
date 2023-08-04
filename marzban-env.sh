#!/bin/bash

source auto.sh

env=/opt/marzban/.env

sudo nano $env

read -e -p "Please enter your port: " -i 8000 port


sed -i 's/UVICORN_PORT = .*/UVICORN_PORT = '$port'/' $env

sed -i 's/# UVICORN_SSL_CERTFILE = .*/UVICORN_SSL_CERTFILE = '"${pubkey}"'/' $env

sed -i 's/# UVICORN_SSL_KEYFILE = .*/UVICORN_SSL_KEYFILE = '"${privkey}"'/' $env

sed -i 's/# XRAY_ASSETS_PATH = .*/XRAY_ASSETS_PATH = '"${assets}"'/' $env


read -p "Please enter your telegram api token: " telegram_api_token
read -p "Please enter your telegram user id: " telegram_user_id

if [[ -n $telegram_api_token ]]; then
    sed -i 's/# TELEGRAM_API_TOKEN = .*/TELEGRAM_API_TOKEN = '"$telegram_api_token"'/' $env
fi

if [[ -n $telegram_user_id ]]; then
    sed -i 's/# TELEGRAM_ADMIN_ID = .*/TELEGRAM_ADMIN_ID = '"$telegram_user_id"'/' $env
fi