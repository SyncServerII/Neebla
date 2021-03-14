#!/bin/bash

if [ $# -eq 0 ]; then
    echo "No dsym.zip arg supplied"
    exit 1
fi

echo "Uploading dysm $1 to bugsnag"

bugsnag-dsym-upload --verbose --api-key 6ad7fdcd3a83687cd475e7ea60de7702 "$1"


