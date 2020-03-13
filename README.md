# Chatto [![Build Status](https://travis-ci.org/badoo/Chatto.svg?branch=master)](https://travis-ci.org/badoo/Chatto) [![codecov.io](https://codecov.io/github/badoo/Chatto/coverage.svg?branch=master)](https://codecov.io/github/badoo/Chatto?branch=master) [![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Chatto.svg)](https://img.shields.io/cocoapods/v/Chatto.svg) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)


`Chatto` is a Swift lightweight framework to build chat applications. It's been designed to be extensible and performant. Along with `Chatto` there is `ChattoAdditions`, a companion framework which includes cells for messages and an extensible input component. You can find more details about how it was implemented in our [blog](https://techblog.badoo.com/blog/2015/12/04/how-we-made-chatto/). See them in action!
<div align="center">
<img src="./readme-images/readme-pic-1.png" />
<img src="./readme-images/readme-pic-2.png" />
<img src="./readme-images/readme-pic-3.png" />
<img src="./readme-images/readme-pic-4.png" />
</div>

## Features
- Calculation of collection view changes and layout in background
- Supports pagination in both directions and autoloading
- Message count contention for fast pagination and rotation with thousands of messsages
- Accessory view revealing by swiping from right
- Interactive keyboard dismissal
- Text bubbles
- Photo bubbles
- Extensible input bar

## How to use

Check the [wiki!](https://github.com/badoo/Chatto/wiki)

## How to install
### CocoaPods

1. Make sure `use_frameworks!` is added to your `Podfile`.

2. Include the following in your `Podfile`:
  ```
  # Swift 5
  pod 'Chatto', '= 3.5.0'
  pod 'ChattoAdditions', '= 3.5.0' # if you want to use the cells or the input component
  ```
  ```
  # Swift 4.2
  pod 'Chatto', '= 3.4.0'
  pod 'ChattoAdditions', '= 3.4.0' # if you want to use the cells or the input component
  ```
  ```
  # Swift 4
  pod 'Chatto', '= 3.3.1'
  pod 'ChattoAdditions', '= 3.3.1' # if you want to use the cells or the input component
  ```
  ```
  # Swift 3
  pod 'Chatto', '= 3.2.0'
  pod 'ChattoAdditions', '= 3.2.0' # if you want to use the cells or the input component
  ```
  ```
  # Swift 2.x
  pod 'Chatto', '= 2.1.0'
  pod 'ChattoAdditions', '= 2.1.0' # if you want to use the cells or the input component
  ```
If you like living on the bleeding edge, you can use the `master` branch with:
  ```
  pod 'Chatto', :git => 'https://github.com/badoo/Chatto', :branch => 'master'
  pod 'ChattoAdditions', :git => 'https://github.com/badoo/Chatto', :branch => 'master'
  ```
3. Run `pod install`

### Carthage

If you’re using [Carthage](https://github.com/Carthage/Carthage#if-youre-building-for-ios-tvos-or-watchos), simply add Chatto to your Cartfile:
```
# Swift 5
github "badoo/Chatto"
```
```
# Swift 2.x
github "badoo/Chatto" "swift-2"
```

### Manually

1. Clone, add as a submodule or [download.](https://github.com/badoo/Chatto/archive/master.zip)
2. Drag and drop `Chatto` and/or `ChattoAdditions` project to your workspace
3. Add `Chatto` and/or `ChattoAdditions` to Embedded binaries

## License
Source code is distributed under MIT license.

## Android
Check our colleagues' project [Chateau]( https://github.com/badoo/Chateau)!

## Blog
Read more on our [tech blog](http://techblog.badoo.com/) or explore our other [open source projects](https://github.com/badoo)
