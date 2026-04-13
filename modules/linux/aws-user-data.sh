#! /bin/bash
set -euo pipefail

# Disable swap (required by kubelet)
swapoff -a
sed -i '/swap/d' /etc/fstab

# Load kernel modules for containerd
cat <<MODULES > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES
modprobe overlay
modprobe br_netfilter

# Sysctl params for Kubernetes networking
cat <<SYSCTL > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
sysctl --system

# Install containerd
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg containerd

# Configure containerd with systemd cgroup
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Add Kubernetes apt repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# Install kubeadm, kubelet, kubectl
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet
