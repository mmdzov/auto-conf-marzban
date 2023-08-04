#!/bin/bash


assets="/var/lib/marzban/assets/"

mkdir -p "$assets"

wget -O "$assets/geosite.dat" https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat

wget -O "$assets/geoip.dat" https://github.com/v2fly/geoip/releases/latest/download/geoip.dat

wget -O "$assets/iran.dat" https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat


