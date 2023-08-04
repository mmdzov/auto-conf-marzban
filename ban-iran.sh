#!/bin/bash


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

json=$(cat "$xray_config")

new_json=$(echo "$json" | jq --arg routing_conf "$routing_conf" '.routing = $routing_conf')

echo "$new_json" > "$xray_config"

cd /opt/marzban

docker compose down
docker compose up -d

cd