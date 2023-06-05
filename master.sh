#!/bin/bash
#install and config k8s
echo "install k8s"
sudo apt update -y
sudo apt -y install curl apt-transport-https vim git wget gnupg2 software-properties-common ca-certificates
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt -y update
sudo apt -y install kubelet kubeadm kubectl
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "config setting"
sudo swapoff -a
sudo mount -a
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

##install and config container runtime
echo "install container runtime"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
sudo sh -c "containerd config default>/etc/containerd/config.toml"
sudo sed -i 's/^\(.*SystemdCgroup =\) false/\1 true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable kubelet

## setup master-node
echo "set up master-node"
sudo kubeadm config images pull
sudo kubeadm init \
  --pod-network-cidr=$1 \
  --apiserver-advertise-address=$(hostname -I)
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config



#install CNI pluggin
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/custom-resources.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
