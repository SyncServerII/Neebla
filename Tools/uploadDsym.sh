#!/bin/bash

# Run this from the Neebla folder
# Usage: ./Tools/uploadDsym.sh /path/to/dSYMs

if [ $# -eq 0 ]; then
    echo "No dsym arg supplied"
    exit 1
fi

echo "Uploading dysm $1 to Firebase Crashlytics"

# I got upload-symbols from /Users/chris/Library/Developer/Xcode/DerivedData/Neebla-aybzuiaoyytaypbvqtqeummvcssh/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics

./Tools/upload-symbols -gsp Neebla/Resources/GoogleService-Info.plist -p ios "$1"


