#!/bin/bash

POD_CIDR=10.40.0.0/16
MASKSIZE=24


echo ">>> DOWNLOADING CILIUM"

sudo wget https://get.helm.sh/helm-v3.12.2-linux-amd64.tar.gz

sudo tar -xvf helm-v3.12.2-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin

sudo rm helm-v3.12.2-linux-amd64.tar.gz
sudo rm -rf linux-amd64

/usr/local/bin/helm version

echo ">>> INSTALLING CILIUM AND METRICS-SERVER IN HA MODE"

sudo /usr/local/bin/helm repo add cilium https://helm.cilium.io/
sudo /usr/local/bin/helm install cilium cilium/cilium \
    --namespace kube-system \
    --set ipam.operator.clusterPoolIPv4PodCIDRList=${POD_CIDR} \
    --set ipam.operator.clusterPoolIPv4MaskSize=${MASKSIZE} 


curl -LO https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
sudo sed -i 's/policy\/v1beta1/policy\/v1/g' high-availability.yaml

/usr/bin/kubectl apply -f high-availability.yaml

echo ">>> REMEMBER TO SETUP KUBELET CSR FOR METRICS SERVER"
