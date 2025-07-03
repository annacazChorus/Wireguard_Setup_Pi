#!/bin/bash

# request all parameters in a non-ambiguous way
echo "Enter Host nb XXXX where your Pi's HostName is PiXXXX:"
read HOSTNB

echo "Enter Network Number X where tunnel is wgX:"
read NTWNB

echo "Enter your Pi's Public Key:"
read PIPUBKEY

# calculate address nb 
IPCLIENT=$((HOSTNB - 2000))
SERVERPORT=$((NTWNB + 51820))

# add peer in conf file
sudo tee -a "/etc/wireguard/wg${NTWNB}.conf" > /dev/null << EOF
[Peer]
PublicKey = ${PIPUBKEY}
AllowedIPs=10.0.${NTWNB}.${IPCLIENT}/32
EOF

# start the tunnel
sudo systemctl enable wg-quick@wg${NTWNB}
sudo systemctl start wg-quick@wg${NTWNB}
sudo systemctl status wg-quick@wg${NTWNB}
