#!/bin/sh

kubectl create namespace demo-policy1
kubectl label namespaces demo-policy1 runecast-admission-policy=1

kubectl create namespace demo-policy2
kubectl label namespaces demo-policy2 runecast-admission-policy=2
