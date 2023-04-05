#!/bin/sh

RUNECAST_TOKEN="Token from RCA API"
RUNECAST_ADDRESS="rca-nginx.runecast.svc:9080"

sudo tee /var/lib/rancher/k3s/server/runecast-validating-webhook-kubeconfig.yaml > /dev/null << EOF
apiVersion: v1
kind: Config
users:
- name: '${RUNECAST_ADDRESS}'
  user:
    token: '${RUNECAST_TOKEN}'
EOF

sudo tee /var/lib/rancher/k3s/server/runecast-admission-configuration.yaml > /dev/null << EOF
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ValidatingAdmissionWebhook
  configuration:
    apiVersion: apiserver.config.k8s.io/v1
    kind: WebhookAdmissionConfiguration
    kubeConfigFile: "/var/lib/rancher/k3s/server/runecast-validating-webhook-kubeconfig.yaml"
EOF

