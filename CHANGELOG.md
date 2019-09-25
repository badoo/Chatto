### 3.5.0 (September 12, 2019)

#### Features
- Support of using compound bubble for text messages #578 by [@magic146](https://github.com/magic146)
- Support of custom menu presentation #584 by [@AntonPalich](https://github.com/AntonPalich)
- Support of layout invalidation for compound bubble #586 by [@Wisors](https://github.com/Wisors)

#### Improvements
- Added accessibility identifier to text bubble #575 by [@wiruzx](https://github.com/wiruzx)
- Migrated existing objc classes to Swift #579 by [@magic146](https://github.com/magic146)
- Various compound bubble layout improvements #587 by [@turbulem](https://github.com/turbulem)
- Added support for draft messages #580 by [@aabalaban](https://github.com/aabalaban)
- Added `didLoseFocusOnItem` method to `ChatInputBarDelegate` #591 by [@magic146](https://github.com/magic146)
- Improved cursor positioning #595 by [@leonspok](https://github.com/leonspok)
- Added support of presenters reusing #596 by [@magic146](https://github.com/magic146)
- Added support for updating message in content presenters #605 by [@wiruzx](https://github.com/wiruzx)

#### Bugfixes
- Fixed using correct uid for decorated item #570 by [@magic146](https://github.com/magic146)
- Fixed filtering content factories #588 by [@Wisors](https://github.com/Wisors)
- Fixed issue with wrong text size calculation in compound bubble #589 by [@AntonPalich](https://github.com/AntonPalich)
- Replaced ReadOnlyOrderedDictionary with ChatItemCompanionCollection in order to support correct uids #590 by [@magic146](https://github.com/magic146)
- Fixed updating `ExpandableTextView` bounds in iOS 13 #592 by [@magic146](https://github.com/magic146)
- Fixed blurry images in the photo picker #594 by [@magic146](https://github.com/magic146)
- Limited maximum scale of preview photos #597 by [@magic146](https://github.com/magic146)
- Fixed calling completion in `changeInputContentBottomMarginTo` method #599 by [@leonspok](https://github.com/leonspok)
- Fixed openning a link in a message #600 by [@magic146](https://github.com/magic146)
- Fixed out of bounds crash due to stirng encoding #603 by [@turbulem](https://github.com/turbulem)
- Fixed implicitly animating layout #604 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed issues with non-selectable links in iOS 13 #606 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed simultaniously recognizing tap and long press #608 by [@AntonPalich](https://github.com/AntonPalich)

### 3.4.0 (April 23, 2019)

#### Features
- Added Xcode 10 and Swift 4.2 support #521 by [@AntonPalich](https://github.com/AntonPalich)
- Added support for showing messages starting from the bottom of the chat #483 by [@rokemoon](https://github.com/rokemoon)
- Added support for scrolling to a specific item in chat #542 by [@AntonPalich](https://github.com/AntonPalich)
- Added accessibility identifiers to messages, photos input and input bar #517 by [@dive](https://github.com/dive)
- Added support for an experimental input presenter that don't use `UIResponder.inputView` API to present a custom input views #536 by [@aabalaban](https://github.com/aabalaban) and [@magic146](https://github.com/magic146)
- Added support for a compound bubble that shows a mixed content in a single bubble #545 by [@wiruzx](https://github.com/wiruzx)
- Added accessibility identifiers to a compound bubble #556 by [@wiruzx](https://github.com/wiruzx)
- Added ability to change an item type dynamically #548 by [@wiruzx](https://github.com/wiruzx)
- Added support for intercepting paste action in input bar #558 and #560 by [@wiruzx](https://github.com/wiruzx)
- Added support for copy action in compound bubble #573 by [@wiruzx](https://github.com/wiruzx)

#### Improvements
- Changed access modifier to `open` in `scrollToBottom` function #501 by [@azimin](https://github.com/azimin)
- Added `@objc` modifier to `scrollToBottom` function #502 by [@azimin](https://github.com/azimin)
- Added support for postponing a presenter factory initialization #528 by [@magic146](https://github.com/magic146)
- Added `IDETemplateMacros` to workspaces #544 by [@wiruzx](https://github.com/wiruzx)
- Changed some access modifiers to `public` in `ScreenMetric.swift` and `InputContainerView` #551 by [@magic146](https://github.com/magic146)
- Various improvements to support a new input bar in Badoo #552 by [@magic146](https://github.com/magic146)

#### Bug
- Fixed an issue with wrong `inputAccessoryView` position on iOS 12 #530 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed an issue (introduced in #530) with wrong `inputView` height after dismissing a modally presented view controller #531 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed an issue (introduced in #530) with wrong `inputView` height after sending a multilin text message #568 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed an issue (introduced in #542) with double completion execution in performBatchUpdates #543 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed an issue (introduced in #545) with fractional bubble size #553 by [@wiruzx](https://github.com/wiruzx)
- Fixed a crash caused by force unwrapped optional in case when a device was rotated with unopened tab with chat in `UITabBarViewController` #538 by [@alaija](https://github.com/alaija)
- Fixed a freeze caused by `PHCachingImageManager` in some cases #566 by [@leonspok](https://github.com/leonspok)

### 3.3.1 (April 9, 2018)

#### Bugs
- Fix iOS 11 text rendering issue related to carriage return symbol #364 by [@0xpablo](https://github.com/0xpablo)

### 3.3.0 (March 10, 2018)

#### Features
- Added Swift 4 support #385 by [@AntonPalich](https://github.com/AntonPalich) and #345 by [@jpunz](https://github.com/jpunz)
- Added messages selection #411 by [@AntonPalich](https://github.com/AntonPalich)
- Added accessibility identifier to selection indicator #428 by [@AntonPalich](https://github.com/AntonPalich)
- Added iCloud Library support to photos input #415 by [@Wisors](https://github.com/Wisors)
- Added camera position settings for live camera cell #393 by [@Wisors](https://github.com/Wisors)
- Allow client to set selected range of textView in ChatInputBar #402 by [@phatmann](https://github.com/phatmann)
- Allow override of text message `text` #403 by [@phatmann](https://github.com/phatmann)
- Added ability to change input bar placeholder #396 by [@chupakabr](https://github.com/chupakabr)
- Allow to build TextMessagePresenter subclasses without exposing internal properties #421 by [@AntonPalich](https://github.com/AntonPalich)
- Made UIScrollView delegates open in BaseChatViewController #438 by [@azimin](https://github.com/azimin)
- Exposed keyboard position handling #445 by [@chupakabr](https://github.com/chupakabr)
- Added additional state for keyboard tracker and ability to modify content insets #454 by [@azimin](https://github.com/azimin)
- Removed Xcode 9 warnings #439 by [@irace](https://github.com/irace)

#### Bugs
- Fixed crashes that happened under some conditions in project with Swift 4 that used Chatto with Swift 3.2 #405, #414 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed issue with live camera cell when it wasnt updated after updating its appearance #404 by [@Wisors](https://github.com/Wisors)
- Fixed issue with photo picker after migration to Swift 4 #437 by [@AntonPalich](https://github.com/AntonPalich)
- Fixed crash that happened on devices with unaccessible camera caused by forced unwrapped optional #424 by [@Wisors](https://github.com/Wisors)
- Removed gap under input bar on iPhone X #447 by [@azimin](https://github.com/azimin)
- Fixed issue with wrong input bar position when hidesBottomBarWhenPushed is true on iPhone X #457 by [@AntonPalich](https://github.com/AntonPalich)

### 3.2.0 (October 20, 2017)

#### Features:
 - Added support for custom main view in BaseChatViewController #323 by [@serge-star](https://github.com/serge-star) 
 - Added ability to change input bar border color and width #339 by [@NSEGeorge](https://github.com/NSEGeorge)
 - Added ability to control visibility of failed icon #359 by [@turbulem](https://github.com/turbulem)
 - Added Xcode 9 and iOS 11 support #352 by [@AntonPalich](https://github.com/AntonPalich)
 - Added support for swiftlint 0.23 #371 by [@AntonPalich](https://github.com/AntonPalich)

#### Bugs:
 - Fixed crash caused by missing optionality identifier in UIKit #310 by [@raisaanjani92](https://github.com/raisaanjani92)
 - Fixed input container position when presenting chat as child controller #338 by [@KaterinaPetrova](https://github.com/KaterinaPetrova)
 - Fixed issue with gesture recognizers that wasn't disabled for text messages on iOS 11 #366 by [@AntonPalich](https://github.com/AntonPalich)

### 3.1.0 (May 29, 2017)

* swiftlint 0.13 support & Xcode 8.2 compatibility [#253](https://github.com/badoo/Chatto/pull/253) - [@diegosanchezr](https://github.com/diegosanchezr)
* swiftlint 0.14 support & hashes improvements [#271](https://github.com/badoo/Chatto/pull/271) - [@diegosanchezr](https://github.com/diegosanchezr)
* Removed lazy keyword from accessoryTimestampView property in BaseMessageCollectionViewCell [#286](https://github.com/badoo/Chatto/pull/286) - [@geegaset](https://github.com/geegaset)
* Fixed typo in a comment in BaseChatViewController+Changes.swift [#296](https://github.com/badoo/Chatto/pull/296) - [@NickAger](https://github.com/NickAger)
* BasicChatInputBarPresenter.chatInputBar became public [#297](https://github.com/badoo/Chatto/pull/297) - [@NickAger](https://github.com/NickAger)
* Added ability to specify tint color for text input [#301](https://github.com/badoo/Chatto/pull/301) - [@V0idPRO](https://github.com/V0idPRO)
* Xcode 8.3 compatibility [#300](https://github.com/badoo/Chatto/pull/300) - [@geegaset](https://github.com/geegaset)
* Empty layout model is returned if layout delegate is nil [#304](https://github.com/badoo/Chatto/pull/304) - [@chupakabr](https://github.com/chupakabr)

### 3.0.1 (Nov 14, 2016)
* Swift 3.0.1 / Xcode 8.1 support [#233](https://github.com/badoo/Chatto/pull/233) - [@diegosanchezr](https://github.com/diegosanchezr)
* Fixes weird linker issue with Carthage [#232](https://github.com/badoo/Chatto/pull/232) - [@zwang](https://github.com/zwang)
* Avoids using AVCapture in simulator [#235](https://github.com/badoo/Chatto/pull/235) - [@geegaset](https://github.com/geegaset)
* Avoids crashing when receiving a nil indexPath (WebDriverAgent) [#248](https://github.com/badoo/Chatto/pull/248) - [@diegosanchezr](https://github.com/diegosanchezr)

### 3.0 (Sept 21, 2016)
* Swift 3 support 🎉 - [#220](https://github.com/badoo/Chatto/pull/220) - [@diegosanchezr](https://github.com/diegosanchezr)

### 2.1 (Sept 17, 2016)
* Enhanced customization for LiveCameraCell [#199](https://github.com/badoo/Chatto/pull/199) - [@TerekhovAnton](https://github.com/TerekhovAnton)
* Fixes input not being at the bottom when chat is embedded in a UITabbarController [#202](https://github.com/badoo/Chatto/pull/202) - [@andris-zalitis](https://github.com/andris-zalitis)
* Fixes collection view insets when keyboard is shown [#204](https://github.com/badoo/Chatto/pull/204) - [@dbburgess](https://github.com/dbburgess)
* LiveCameraCellPresenter made public [#205](https://github.com/badoo/Chatto/pull/205) - [@diegosanchezr](https://github.com/diegosanchezr)
* Fixes order of photos on iOS 10 [#215](https://github.com/badoo/Chatto/pull/215) - [@geegaset](https://github.com/geegaset)
* Adds accessibility identifiers in ChatInputBar [#218](https://github.com/badoo/Chatto/pull/218), [#206](https://github.com/badoo/Chatto/pull/206) - [@geegaset](https://github.com/geegaset) 
* Xcode 8 - Swift 2.3 support

### 2.0 (Aug 8, 2016)
* Renames `ChatViewController` to `BaseChatViewController`. [#31](https://github.com/badoo/Chatto/pull/31) - [@diegosanchezr](https://github.com/diegosanchezr)
* Makes presenters easier to reuse by relaxing generic constraints [#35](https://github.com/badoo/Chatto/pull/35) - [@diegosanchezr](https://github.com/diegosanchezr)
* Fixes issues when the dataSource updates with a different instance for a previously existing chatItem. [#36](https://github.com/badoo/Chatto/pull/36) - [@diegosanchezr](https://github.com/diegosanchezr)
* `BaseChatViewController` exposes `chatItemCompanionCollection`. [#39](https://github.com/badoo/Chatto/pull/39) - [@diegosanchezr](https://github.com/diegosanchezr)
  * This gives access to the presenter and decorationAttributes of a chatItem.
* `ChatDataSourceDelegateProtocol` gets `chatDataSourceDidUpdate(:context)`.  [#39](https://github.com/badoo/Chatto/pull/39) - [@diegosanchezr](https://github.com/diegosanchezr)
  * This allows to customize the update of the UICollectionView (reloadData vs performBatchUpdates)
* `MessageViewModelProtocol` loses `status` setter. `messageModel` property is removed. [#44](https://github.com/badoo/Chatto/pull/44) - [@diegosanchezr](https://github.com/diegosanchezr)
* `ChatDataSourceProtocol` loses the completion blocks in `loadNext()` and `loadPrevious()`. [#45](https://github.com/badoo/Chatto/pull/45) - [@diegosanchezr](https://github.com/diegosanchezr)
  * It's now the dataSource's responsability to notify when pagination finishes (by triggering `chatDataSourceDidUpdate(:context)`)
* `BaseChatViewController` is no longer retained until a running update finishes. [#47](https://github.com/badoo/Chatto/pull/47) - [@diegosanchezr](https://github.com/diegosanchezr)
* `BaseMessageCollectionViewCell` can now be subclassed out of `ChattoAdditions`. [#48](https://github.com/badoo/Chatto/pull/48) - [@bcamur](https://github.com/bcamur)
* `ChatInputBarDelegate` made public. [#50](https://github.com/badoo/Chatto/pull/50) - [@AntonPalich](https://github.com/AntonPalich)
* `PhotoMessagePresenter` exposes `viewModelBuilder` and `interactionHandler`. [#52](https://github.com/badoo/Chatto/pull/52) - [@AntonPalich](https://github.com/AntonPalich)
* Avatars in cells. [#55](https://github.com/badoo/Chatto/pull/55) - [@zwang](https://github.com/zwang), [#176](https://github.com/badoo/Chatto/pull/176) - [@maxkonovalov](https://github.com/maxkonovalov)
  * `MessageViewModelProtocol` gets `avatarImage` property
  * `BaseMessageCollectionViewCellStyleProtocol` gets methods to configure the layout of the avatar
  * `BaseMessageInteractionHandlerProtocol` gets `userDidTapOnAvatar(viewModel:)`
  * `ChatItemDecorationAttributes` gets `canShowAvatar`
* `BaseMessagePresenter` exposes user events (so subclasses can complement or bypass the interactionHandler). [#62](https://github.com/badoo/Chatto/pull/62) - [@AntonPalich](https://github.com/AntonPalich)
  * `BaseMessagePresenter.onCellBubbleTapped()`
  * `BaseMessagePresenter.onCellBubbleLongPressed()`
  * `BaseMessagePresenter.onCellFailedButtonTapped()`
* `BaseMessagePresenter` exposes `messageModel`, `sizingCell`, `viewModelBuilder`, `interactionHandler` and `cellStyle`. [#63](https://github.com/badoo/Chatto/pull/63) - [@AntonPalich](https://github.com/AntonPalich)
* `PhotosChatInputItem` gets new callbacks `cameraPermissionHandler`, `photosPermissionHandler`. [#65](https://github.com/badoo/Chatto/pull/65) - [@Viacheslav-Radchenko](https://github.com/Viacheslav-Radchenko)
* Enhanced customization for cells and the input component. [#67](https://github.com/badoo/Chatto/pull/67) - [@diegosanchezr](https://github.com/diegosanchezr), [#73](https://github.com/badoo/Chatto/pull/73) [@AntonPalich](https://github.com/AntonPalich)
* `BaseChatViewController` exposes `referenceIndexPathsToRestoreScrollPositionOnUpdate`. [#75](https://github.com/badoo/Chatto/pull/75) - [@diegosanchezr](https://github.com/diegosanchezr)
  * It can be overriden to customize how the scroll position is preserved after a update.
* Fixes blinking when sending text messages on iOS 8
* Adds placeholders when there are very few photos in the camera roll. [#85](https://github.com/badoo/Chatto/pull/85) - [@Viacheslav-Radchenko](https://github.com/Viacheslav-Radchenko)
* `BaseChatViewController` exposes `createPresenterFactory()`. It can be overriden to provide a factory of presenters with custom logic. [#89](https://github.com/badoo/Chatto/pull/89) - [@weyg](https://github.com/weyg)
* `BaseChatViewController` exposes `inputContainer`. [#90](https://github.com/badoo/Chatto/pull/90) - [@diegosanchezr](https://github.com/diegosanchezr)
* Fixes insets issues. [#91](https://github.com/badoo/Chatto/pull/91), [#110](https://github.com/badoo/Chatto/pull/110) - [@diegosanchezr](https://github.com/diegosanchezr)
* Fixes memory leak when screen is left with the keyboard opened. [#93](https://github.com/badoo/Chatto/pull/93) - [@diegosanchezr](https://github.com/diegosanchezr)
* PhotosChatInputItem listens to changes in the camera roll and updates accordingly. [#94](https://github.com/badoo/Chatto/pull/94) - [@AntonPalich](https://github.com/AntonPalich)  
* Fixes issues with the keyboard [#96](https://github.com/badoo/Chatto/pull/96), [#115](https://github.com/badoo/Chatto/pull/115) - [@diegosanchezr](https://github.com/diegosanchezr), [#108](https://github.com/badoo/Chatto/pull/108) - [@AntonPalich](https://github.com/AntonPalich)
* `BaseChatViewController` gets `setChatDataSource(_:triggeringUpdateType)`. [#98](https://github.com/badoo/Chatto/pull/98) - [@diegosanchezr](https://github.com/diegosanchezr)
  * This allows to set a dataSource and not trigger an update of the collection view immediately.
  * This can be useful on the first load of the conversation when the dataSource doesn't have any data yet.
* `ChatInputBar` gets `shouldEnableSendButton` closure to customize when the send button is enabled [#103](https://github.com/badoo/Chatto/pull/103) - [@ikashkuta](https://github.com/ikashkuta)
* Fixes UIMenuController not going away on the first tap outside when the keyboard is dismissed. [#104](https://github.com/badoo/Chatto/pull/104) - [@diegosanchezr](https://github.com/diegosanchezr)
* `ChatInputBarDelegate` gets `inputBarShouldBeginTextEditing(_:)` and `inputBar(_: shouldFocusOnItem)` [#105](https://github.com/badoo/Chatto/pull/105) - [@ikashkuta](https://github.com/ikashkuta)
* `BaseChatViewController` gets `accessoryViewRevealerConfig`. [#114](https://github.com/badoo/Chatto/pull/114) - [@diegosanchezr](https://github.com/diegosanchezr)
  * Allows setting an angle threshold that triggers the revealing
  * Allows applying a transform to the finger's translation (to mimic a resistance effect)
* Fixes sizing of text cells: [#122](https://github.com/badoo/Chatto/pull/122), [#123](https://github.com/badoo/Chatto/pull/123) - [@AntonPalich](https://github.com/AntonPalich), [#127](https://github.com/badoo/Chatto/pull/127), [#161](https://github.com/badoo/Chatto/pull/161)- [@diegosanchezr](https://github.com/diegosanchezr)
* `ChatInputBar` gets `focusOnInputItem(_:)` so that an input item can be focused programmatically. [#124](https://github.com/badoo/Chatto/pull/124) - [@ikashkuta](https://github.com/ikashkuta)  
* `BaseMessagePresenter` gets user events `onCellBubbleLongPressBegan()` and `onCellBubbleLongPressEnded`. [#125](https://github.com/badoo/Chatto/pull/125) - [@AntonPalich](https://github.com/AntonPalich)
* `PhotoBubbleView` can be subclassed. [#130](https://github.com/badoo/Chatto/pull/130) - [@AntonPalich](https://github.com/AntonPalich)
* Configurable margins for revealable timestamps. [#135](https://github.com/badoo/Chatto/pull/135) - [@AntonPalich](https://github.com/AntonPalich)
* `BaseChatViewController` gets `endsEditingWhenTappingOnChatBackground` to dismiss the keyboard automatically. [#138](https://github.com/badoo/Chatto/pull/138) - [@diegosanchezr](https://github.com/diegosanchezr)
* `BaseMessageCollectionViewCellDefaultStyle` gets optional `bubbleBorderImages` [#139](https://github.com/badoo/Chatto/pull/139) - [@diegosanchezr](https://github.com/diegosanchezr)
* `ChatItemsDecorator` can now have a last word about the `uid` used by the update engine. [#143](https://github.com/badoo/Chatto/pull/143) - [@diegosanchezr](https://github.com/diegosanchezr)
* `BaseChatViewController` gets `updatesConfig` property. [#145](https://github.com/badoo/Chatto/pull/145) - [@diegosanchezr](https://github.com/diegosanchezr)
  * `coalesceUpdates` controls whether updates are combined (if dataSource notifies about changes while there is a running update)
  * `fastUpdates` controls whether a UICollectionView update can be performed before the previous one has finished.
* Exposes `BaseChatViewController.updateQueue`. [#150](https://github.com/badoo/Chatto/pull/150) - [@ikashkuta](https://github.com/ikashkuta), [#169](https://github.com/badoo/Chatto/pull/169) - [@diegosanchezr](https://github.com/diegosanchezr)
  * Allows clients to pause updates in the UICollectionView.
* Performance optimizations for text cells. [#144](https://github.com/badoo/Chatto/pull/144), [#166](https://github.com/badoo/Chatto/pull/166) - [@diegosanchezr](https://github.com/diegosanchezr)
* `ChatInputBar` gets `maxCharactersCount` to limit text input size
* Allows `ChatInputBar` to be instantiated from an own nib. [#153](https://github.com/badoo/Chatto/pull/153) - [@makoni](https://github.com/makoni)
* Enhanced customization for buttons in `ChatInputBar`. [#154](https://github.com/badoo/Chatto/pull/154) - [@diegosanchezr](https://github.com/diegosanchezr)
* Fixes memory leak. [#165](https://github.com/badoo/Chatto/pull/165) - [@AntonPalich](https://github.com/AntonPalich)
* Improves responsiveness of the camera. [#168](https://github.com/badoo/Chatto/pull/168), [#173](https://github.com/badoo/Chatto/pull/173) - [@diegosanchezr](https://github.com/diegosanchezr)
* Preserves height of the input view when switching between input items. [#170](https://github.com/badoo/Chatto/pull/170), [#174](https://github.com/badoo/Chatto/pull/174) - [@ikashkuta](https://github.com/ikashkuta)
* `AccessoryViewRevealable` gets `allowAccessoryViewRevealing`. [#175](https://github.com/badoo/Chatto/pull/175) - [@ikashkuta](https://github.com/ikashkuta)
  * Allows to control whether timestamp can be revealed on a per cell basis.

### 1.0.1 (Jan 14, 2016)
* Support for Carthage

### 1.0 (Nov 27, 2015)
* First version
