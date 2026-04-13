#!/bin/bash
# =============================================================================
# User-data script for EC2 instances — Kubernetes node preparation
#
# This script runs ONCE on first boot. It prepares the node so that
# kubeadm can initialize (master) or join (worker) the cluster.
#
# What it does:
#   1. Disables swap            (kubelet requirement)
#   2. Loads kernel modules     (overlay + br_netfilter for container networking)
#   3. Sets sysctl params       (bridged traffic & IP forwarding)
#   4. Installs containerd      (CRI runtime)
#   5. Installs kubeadm/kubelet/kubectl
#
# After boot you still need to:
#   - On master: sudo kubeadm init ...
#   - On workers: sudo kubeadm join ...
# =============================================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

K8S_VERSION="v1.35.1"

echo ">>> [1/5] Disabling swap (required by kubelet)"
swapoff -a
sed -i '/swap/d' /etc/fstab

echo ">>> [2/5] Loading kernel modules for container networking"
cat <<MODULES > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES
modprobe overlay
modprobe br_netfilter

echo ">>> [3/5] Configuring sysctl for Kubernetes networking"
cat <<SYSCTL > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
sysctl --system

echo ">>> [4/5] Installing and configuring containerd"
apt-get update -qq
apt-get install -y -qq apt-transport-https ca-certificates curl gnupg containerd

mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
# Enable systemd cgroup driver (must match kubelet's cgroup driver)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo ">>> [5/5] Installing kubeadm, kubelet, kubectl (${K8S_VERSION})"
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl
# Hold versions so apt-get upgrade doesn't break the cluster
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet

echo ">>> Node ready — run 'kubeadm init' (master) or 'kubeadm join' (worker)"
