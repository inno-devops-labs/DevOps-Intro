#!/bin/bash
echo "Starting GitOps monitoring..."
for i in {1..5}; do
    echo "--- Check #$i ---"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 2
done
