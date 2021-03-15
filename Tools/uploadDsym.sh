#!/bin/bash

# From the Neebla folder, I ran:
#   ./Tools/uploadDsym.sh ~/Desktop/dSYMs
# dSYMs is a *folder* not a zip file.
# Note this is *not* working when I use a zip file.
# See https://github.com/bugsnag/bugsnag-dsym-upload/issues/32

if [ $# -eq 0 ]; then
    echo "No dsym folder arg supplied"
    exit 1
fi

echo "Uploading dysm $1 to bugsnag"

bugsnag-dsym-upload --verbose --api-key 6ad7fdcd3a83687cd475e7ea60de7702 "$1"


