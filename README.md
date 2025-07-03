### add_pi_wg_host.sh

To be executed from Pi host, creates the second end of the Wireguard tunnel connection to Wireguard server.

### add_peer_wg_server.sh

To be executed on Wireguard Server -on VPS (Amazon Lightsail), updates the tunnel's configuration with new peer.

### add_new_tunnel.sh

To execute on Wireguard Server, creates a new Wg tunnel and sets firewall rules. Admin PC is added into the newly initiated tunnel.
