#!/bin/sh

kubectl -n demo-policy1 create deployment nginx --image=nginx:1.23.4-alpine
