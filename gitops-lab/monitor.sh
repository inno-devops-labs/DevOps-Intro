#!/bin/bash
# monitor.sh - Combined reconciliation and health monitoring

printf "Starting GitOps monitoring...\n"
for i in {1..10}; do
    printf "\n--- Check #%d ---\n" "$i"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
