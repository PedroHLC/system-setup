#!/usr/bin/env bash
set -euo pipefail

_gateway=''${GATEWAY_IP:-192.168.0.1}
_wan=''${WAN_INTERFACE:-eno1}

_lab=$(dig +short lab.pedrohlc.com | tail -1)
_cf=$(dig +short engage.cloudflareclient.com | tail -1)

echo "CF: $_cf | LAB: $_lab"

# make current wireguard connections permanent
echo '>> Ensuring connection to the VPNs'
sudo ip route replace "$_lab" via "$_gateway" dev "$_wan"
sudo ip route replace "$_cf" via "$_gateway" dev "$_wan"

if [ -n "$2" ]; then
  echo 'Too many arguments'
  exit 3
fi

# attempt
echo '>> Test connection to WARP'
sudo ip route replace 8.8.8.8 via 172.16.0.2 dev wg1
sleep 1
if ! ping -c 8 8.8.8.8; then
  echo '>> Failed to ping google, reverting...'
  sudo ip route del 8.8.8.8 via 172.16.0.2 dev wg1
  exit 1
fi

if [ "$1" == "-4" ]; then
  # make default through zero-trust
  echo '>> Introduce and test default IPv4 route via WARP'
  sudo ip route replace default via 172.16.0.2 dev wg1
  sleep 1
  if ! ping -c 8 1.1.1.1; then
    echo '>> Failed to ping cloudflare, reverting...'
    sudo ip route del default via 172.16.0.2 dev wg1
    sudo ip route del 8.8.8.8 via 172.16.0.2 dev wg1
    exit 2
  fi
  sudo ip -4 route flush cache
elif [ "$1" == "-6" ]; then
  echo '>> Introduce and test default IPv6 route via WARP'
  sudo ip -6 route replace default dev wg1
  sleep 1
  curl -6 'https://google.com'
  sudo ip -6 route flush cache
elif [ -n "$1" ]; then
  dig +short "$1" |\
    xargs -tI % \
      sudo ip route replace % via 172.16.0.2 dev wg1
fi

echo '>> Finished with success!'
