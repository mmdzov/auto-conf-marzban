#!/bin/bash


env=/opt/marzban/.env

nano $env

# Ask for PORT
read -e -p "Please enter your port: " -i 8000 port


sed -i 's/UVICORN_PORT = .*/UVICORN_PORT = '$port'/' $env

sed -i 's/# UVICORN_SSL_CERTFILE = .*/UVICORN_SSL_CERTFILE = '"$pubkey"'/' $env

sed -i 's/# UVICORN_SSL_KEYFILE = .*/UVICORN_SSL_KEYFILE = '"$privkey"'/' $env


