#!/usr/bin/env bash

set -e

APP_DIR=/data/workspace/homelab/k8s/apps

for file in $APP_DIR/*-app.yaml ; do
  app=$(echo ${file##*/} | sed 's/\(\w\+\)-app.*/\1/')
  kubectl delete secret "$app-doppler-token" -n doppler-operator-system --ignore-not-found
  kubectl create secret generic "$app-doppler-token" -n doppler-operator-system --from-literal=serviceToken=$(doppler configs tokens create --project "$app" --config dev "$app-token" --plain)
done
