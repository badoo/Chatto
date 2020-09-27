#!/bin/bash

set -o pipefail

WORKSPACE='Chatto.xcworkspace'
SCHEME='Chatto'

case "$1" in
    chatto) ;;
    additions)
        SCHEME='ChattoAdditions'
        ;;
    app)
        WORKSPACE='ChattoApp/ChattoApp.xcworkspace'
        SCHEME='ChattoApp'
        ;;
    *) echo "Invalid operation"
        exit 1
        ;;
esac

xcodebuild clean build test \
    -workspace $WORKSPACE \
    -scheme $SCHEME \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 11' \
    -configuration Debug | xcpretty
