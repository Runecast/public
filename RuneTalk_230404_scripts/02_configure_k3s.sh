#!/bin/sh

sudo tee /etc/rancher/k3s/config.yaml > /dev/null << EOF
kube-apiserver-arg:
  - "admission-control-config-file=/var/lib/rancher/k3s/server/runecast-admission-configuration.yaml"
EOF

sudo systemctl restart k3s
