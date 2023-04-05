#!/bin/sh

RUNECAST_NAMESPACE='runecast'
RUNECAST_SERVICE=$(kubectl -n $RUNECAST_NAMESPACE get service -l app.kubernetes.io/name=nginx -o jsonpath='{.items[].metadata.name}')
RUNECAST_SERVICE_PORT=$(kubectl -n $RUNECAST_NAMESPACE get service -l app.kubernetes.io/name=nginx -o jsonpath='{.items[].spec.ports[].port}')
RUNECAST_SERVICE_CERTIFICATE=$(kubectl -n $RUNECAST_NAMESPACE get pod -l app.kubernetes.io/name=nginx -o jsonpath='{.items[].spec.volumes[?(@.name=="nginx-certificate")].secret.secretName}' | xargs kubectl get secret -n $RUNECAST_NAMESPACE -o jsonpath='{.data.tls\.crt}')

echo "$RUNECAST_SERVICE"
echo "$RUNECAST_SERVICE_PORT"
echo "$RUNECAST_SERVICE_CERTIFICATE"

cat << EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: "runecast-validating-webhook"
webhooks:
- name: "deny-critical-and-medium.runecast.com"
  rules:
  - apiGroups:   ["*"]
    apiVersions: ["v1"]
    operations:  ["CREATE","UPDATE"]
    resources:   ["pods","daemonsets","deployments","replicasets","statefulsets","replicationcontrollers","cronjobs","jobs"]
    scope:       "Namespaced"
  namespaceSelector:
    matchExpressions:
    - values:
      - '1'
      operator: In
      key: runecast-admission-policy
  clientConfig:
    service: 
      namespace: ${RUNECAST_NAMESPACE}
      name: ${RUNECAST_SERVICE}
      path: /rca/api/v2/k8s-admission-policy-review/policy/1
      port: ${RUNECAST_SERVICE_PORT}
    caBundle: ${RUNECAST_SERVICE_CERTIFICATE}
  admissionReviewVersions: ["v1", "v1beta1"]
  sideEffects: None
  timeoutSeconds: 30

- name: "deny-fixed-critical-and-medium.runecast.com"
  rules:
  - apiGroups:   ["*"]
    apiVersions: ["v1"]
    operations:  ["CREATE","UPDATE"]
    resources:   ["pods","daemonsets","deployments","replicasets","statefulsets","replicationcontrollers","cronjobs","jobs"]
    scope:       "Namespaced"
  namespaceSelector:
    matchExpressions:
    - values:
      - '2'
      operator: In
      key: runecast-admission-policy
  clientConfig:
    service: 
      namespace: ${RUNECAST_NAMESPACE}
      name: ${RUNECAST_SERVICE}
      path: /rca/api/v2/k8s-admission-policy-review/policy/2
      port: ${RUNECAST_SERVICE_PORT}
    caBundle: ${RUNECAST_SERVICE_CERTIFICATE}
  admissionReviewVersions: ["v1", "v1beta1"]
  sideEffects: None
  timeoutSeconds: 30

EOF
