#!/bin/bash


# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install


# create admin
source create-admin.sh


# Get SSL
source ssl.sh


# Configure ENV
source marzban-env.sh