#!/bin/bash
set -e

#sudo apt update
#sudo apt install -y snapd
#sudo snap install microk8s --classic --channel=1.29/stable

sudo usermod -a -G microk8s vagrant
sudo chown -f -R vagrant /home/vagrant/.kube || true

# sudo microk8s status --wait-ready
sudo microk8s enable dns
sudo microk8s enable ingress
sudo microk8s enable helm3
sudo microk8s enable prometheus
sudo microk8s enable metrics-server
sudo microk8s enable  dashboard


exit 0
