#!/bin/bash
set -e

sudo apt update
sudo apt install -y haproxy

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend http
    bind *:80
    default_backend nodes

backend nodes
    balance roundrobin
    server node1 192.168.56.11:80 check
    server node2 192.168.56.12:80 check
    server node3 192.168.56.13:80 check
    server node4 192.168.56.14:80 check
EOF

sudo systemctl restart haproxy
