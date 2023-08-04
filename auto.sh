#!/bin/bash


## variables
pubkey=""
privkey=""
assets="/var/lib/marzban/assets/"



# Install
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install


# create admin
source create-admin.sh


# Get SSL
source ssl.sh

# Ban iranian applications and websites
source ban-iran.sh

# Configure ENV
source marzban-env.sh


marzban restart