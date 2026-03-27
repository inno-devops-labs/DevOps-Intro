#!/bin/bash

if cmp -s desired-state.txt current-state.txt; then
    echo "States are synchronized."
else
    echo "Drift detected."
    cp desired-state.txt current-state.txt
    echo "Reconciliation completed."
fi
