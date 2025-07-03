#!/bin/bash

# request all parameters in a non-ambiguous way
echo "Enter NEW Network Number X where tunnel is wgX:"
read NTWNB

echo "Enter your Admin PC's Public Key:"
read PCPUBKEY

# install all dependencies
sudo apt-get update
sudo apt-get install -y wireguard resolvconf conntrack

echo "Wireguard installed, generating new keys for server..."

# generate private and public keys
wg genkey | sudo tee "/etc/wireguard/server_wg${NTWNB}_private.key"
PRIVKEY=$(sudo cat  "/etc/wireguard/server_wg${NTWNB}_private.key")

echo $PRIVKEY | wg pubkey | sudo tee "/etc/wireguard/server_wg${NTWNB}_public.key"
PUBKEY=$(sudo cat "/etc/wireguard/server_wg${NTWNB}_public.key")

# calculate address nb
IPVPS=1 
IPPC=2
SERVERPORT=$((NTWNB + 51820))

echo "Generating conf file for wg${NTWNB}"

# write conf file
sudo tee "/etc/wireguard/wg${NTWNB}.conf" > /dev/null << EOF
[Interface]
PrivateKey = ${PRIVKEY}
Address = 10.0.${NTWNB}.${IPVPS}/24
SaveConfig = false
ListenPort = ${SERVERPORT}
PostUp = /etc/wireguard/firewall-wg${NTWNB}-set.sh
PostDown = /etc/wireguard/firewall-wg${NTWNB}-reset.sh

[Peer]
PublicKey = ${PCPUBKEY}
AllowedIPs=10.0.${NTWNB}.${IPPC}/32
EOF

echo "Generating firewall scripts for wg${NTWNB}"
echo "Script firewall-wg${NTWNB}-set.sh..."

sudo tee "/etc/wireguard/firewall-wg${NTWNB}-set.sh" > /dev/null << EOF
#!/bin/bash

iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# allow traffic from already established connections
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# allow all pings
iptables -A INPUT -p icmp -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT

# allow PC to communicate to any machine on VPN subnet
iptables -A FORWARD -s 10.0.${NTWNB}.${IPPC} -d 10.0.${NTWNB}.0/24 -j ACCEPT

# allow Pis to communicate to one another -and not to PC
iptables -A FORWARD -s 10.0.${NTWNB}.0/24 -d 10.0.${NTWNB}.${IPPC} -j DROP
iptables -A FORWARD -s 10.0.${NTWNB}.0/24 -d 10.0.${NTWNB}.0/24 -j ACCEPT

# allow any traffic incoming from wg${NTWNB} network
iptables -A INPUT -i wg${NTWNB} -j ACCEPT
EOF


echo "Script firewall-wg${NTWNB}-reset.sh..."

sudo tee "/etc/wireguard/firewall-wg${NTWNB}-reset.sh" > /dev/null << EOF
#!/bin/bash

# remove all connections established on wg${NTWNB} tunnel setup
iptables -D FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

iptables -D INPUT -p icmp -j ACCEPT
iptables -D OUTPUT -p icmp -j ACCEPT
iptables -D FORWARD -p icmp -j ACCEPT

iptables -D FORWARD -s 10.0.${NTWNB}.${IPPC} -d 10.0.${NTWNB}.0/24 -j ACCEPT

iptables -D FORWARD -s 10.0.${NTWNB}.0/24 -d 10.0.${NTWNB}.${IPPC} -j DROP
iptables -D FORWARD -s 10.0.${NTWNB}.0/24 -d 10.0.${NTWNB}.0/24 -j ACCEPT

iptables -D INPUT -i wg${NTWNB} -j ACCEPT
EOF


# enable execution of the firewall scripts
sudo chmod +x /etc/wireguard/firewall-wg${NTWNB}-set.sh
sudo chmod +x /etc/wireguard/firewall-wg${NTWNB}-reset.sh

# start the tunnel
sudo systemctl enable wg-quick@wg${NTWNB}
sudo systemctl start wg-quick@wg${NTWNB}

echo "wg${NTWNB} Tunnel enabled and started, check systemctl status wg-quick@wg${NTWNB} to ensure functionning"

# display the public key
echo $PUBKEY
