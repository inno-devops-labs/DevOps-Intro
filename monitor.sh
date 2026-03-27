#!/bin/bash

for i in {1..10}; do
    echo "Iteration $i"
    ./healthcheck.sh
    ./reconcile.sh
    sleep 3
done
