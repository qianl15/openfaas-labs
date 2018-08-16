#!/bin/bash

# Steps reproduced from https://blog.alexellis.io/your-instant-kubernetes-cluster/

if [ $# -ne 1 ]; then
  echo "Usage: ./setup_kubecluster.sh <master-slave>"
  echo "<master-slave>: 'm' for master, 's' for slave"
  exit 1
fi

master_slave=$1
if [[ "${master_slave}" != "s"  &&  "${master_slave}" != "m" ]]; then
  echo "<master-slave> parameter must be 'm' or 's'"
  exit 1
fi

echo ${master_slave}", yay!"

exit

# Install docker
sudo apt-get update \
        && sudo apt-get install -qy docker.io

# Install Kubernetes package
sudo apt-get update \
       && sudo apt-get install -y apt-transport-https \
       && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg |
       sudo apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" \
       | sudo tee -a /etc/apt/sources.list.d/kubernetes.list \
       && sudo apt-get update

sudo apt-get update \
         && sudo apt-get install -y \
         kubelet \
         kubeadm \
         kubernetes-cni

if [ "${master_slave}" == "s" ]; then
  echo "Done setting up slave server! Use the kubeadm join command from the master to complete the setup"
  exit 0
fi

# Start the cluster
slave_cmd=`sudo kubeadm init | grep "kubeadm join"`

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install WeaveNet
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "Done setting up the master server! Now run the following on the slave server: "${slave_cmd}

exit 0

