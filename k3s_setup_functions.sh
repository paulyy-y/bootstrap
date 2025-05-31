#! /bin/bash

k3s_install_server() {
  # Install k3s server with connection to existing server
  curl -sfL https://get.k3s.io | \
    K3S_TOKEN=$K3S_TOKEN \
    sh -s - server \
    --server https://$SERVER_IP:6443

  # Ensure proper permissions for rancher directory
  sudo chmod -R a+r /etc/rancher
}

k3s_install_cluster_server() {
  # Install k3s server with cluster initialization
  curl -sfL https://get.k3s.io | \
    K3S_TOKEN=$K3S_TOKEN \
    sh -s - server --cluster-init

  # Ensure proper permissions for rancher directory
  sudo chmod -R a+r /etc/rancher/
}

k3s_install_agent() {
  curl -sfL https://get.k3s.io | \
    K3S_TOKEN=$K3S_TOKEN \
    sh -s - agent \
    --server https://$SERVER_IP:6443
}
