#!/bin/sh

helm upgrade --install rca /home/const/git/rca-k8s/helm/runecast-analyzer/ \
    -f 00_rca-values.yaml

