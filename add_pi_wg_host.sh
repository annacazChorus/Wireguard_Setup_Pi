#!/bin/bash

# request all parameters in a non-ambiguous way
echo "Enter Host nb XXXX where your Pi's HostName is PiXXXX:"
read HOSTNB

echo "Enter Network Number X where tunnel is wgX:"
read NTWNB

echo "Enter your Server's Public Key:"
read SERVERPUBKEY

# install all dependencies
sudo apt-get update
sudo apt-get install wireguard resolvconf

echo "Wireguard installed, generating keys..."

# generate private and public keys
wg genkey | sudo tee "/etc/wireguard/client_Pi${HOSTNB}_private.key"
PRIVKEY=$(sudo cat  "/etc/wireguard/client_Pi${HOSTNB}_private.key")

echo $PRIVKEY | wg pubkey | sudo tee "/etc/wireguard/client_Pi${HOSTNB}_public.key"
PUBKEY=$(sudo cat "/etc/wireguard/client_Pi${HOSTNB}_public.key")

# calculate address nb 
IPCLIENT=$((HOSTNB - 2000))
SERVERPORT=$((NTWNB + 51820))

echo "Generating conf file for wg${NTWNB}"

# write conf file
sudo tee "/etc/wireguard/wg${NTWNB}.conf" > /dev/null << EOF
[Interface]
PrivateKey = ${PRIVKEY}
Address = 10.0.${NTWNB}.${IPCLIENT}/32
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVERPUBKEY}
Endpoint = 35.180.179.247:${SERVERPORT}
AllowedIPs=10.0.${NTWNB}.0/24
PersistentKeepalive=25
EOF

# start the tunnel
sudo systemctl enable wg-quick@wg${NTWNB}
sudo systemctl start wg-quick@wg${NTWNB}

echo "wg${NTWNB} Tunnel enabled and started, check systemctl status wg-quick@wg${NTWNB} to ensure functionning"

# display the public key
echo $PUBKEY
