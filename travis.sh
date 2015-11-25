xcodebuild clean build test -project ./Chatto/Chatto.xcodeproj -scheme Chatto -sdk iphonesimulator -configuration Debug | xcpretty; (curl -s https://codecov.io/bash) | bash
xcodebuild clean build test -project ./ChattoAdditions/ChattoAdditions.xcodeproj -scheme ChattoAdditions -sdk iphonesimulator -configuration Debug | xcpretty; (curl -s https://codecov.io/bash) | bash
