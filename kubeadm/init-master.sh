#!/bin/bash

echo ">>> INIT MASTER NODE"

sudo systemctl enable kubelet


sudo kubeadm init \
  --pod-network-cidr=$K8S_POD_NETWORK_CIDR \
  --service-cidr=$K8S_SERVICE_CIDR \
  --control-plane-endpoint=$K8S_CONTROL_PLANE_ENDPOINT \
  --apiserver-advertise-address=$MASTER_NODE_IP \
  --v=5


echo ">>> CONFIGURE KUBECTL"

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

sudo mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id vagrant -u):$(id vagrant -g) $HOME/.kube/config


echo ">>> FIX KUBELET NODE IP"

echo "KUBELET_EXTRA_ARGS=\"--node-ip=$MASTER_NODE_IP\"" | sudo tee -a /var/lib/kubelet/kubeadm-flags.env


if [ "$K8S_POD_NETWORK_TYPE" == "cilium" ]
then 
  echo ">>> DEPLOY POD NETWORK > CILIUM"
  sed -i -e 's/\r$//' /vagrant/cni/cilium/scripts/cilium.sh
  /vagrant/cni/cilium/scripts/cilium.sh 
fi


sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo ">>> GET WORKER JOIN COMMAND "

rm -f /vagrant/kubeadm/init-worker.sh
kubeadm token create --print-join-command >> /vagrant/kubeadm/init-worker.sh


