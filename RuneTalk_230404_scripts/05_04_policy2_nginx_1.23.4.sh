#!/bin/sh

kubectl -n demo-policy2 create deployment nginx --image=nginx:1.23.4
