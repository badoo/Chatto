/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit
import ImageIO

public protocol ChatInputBarDelegate: class {
    func inputBarShouldBeginTextEditing(_ inputBar: ChatInputBar) -> Bool
    func inputBarDidBeginEditing(_ inputBar: ChatInputBar)
    func inputBarDidEndEditing(_ inputBar: ChatInputBar)
    func inputBarDidChangeText(_ inputBar: ChatInputBar)
    func inputBarDidRemovePhoto(_ inputBar: ChatInputBar, item: (index: IndexPath, url: URL))
    func inputBarSendButtonPressed(_ inputBar: ChatInputBar)
    func inputBar(_ inputBar: ChatInputBar, shouldFocusOnItem item: ChatInputItemProtocol) -> Bool
    func inputBar(_ inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol)
}

@objc
open class ChatInputBar: ReusableXibView, ChatInputPhotoCellProtocol {

    public weak var delegate: ChatInputBarDelegate?
    weak var presenter: ChatInputBarPresenter?

    public var shouldEnableSendButton = { (inputBar: ChatInputBar) -> Bool in
        for photoCell in inputBar.scrollViewPhotos.subviews {
            if photoCell is ChatInputPhotoCell {
                return true
            }
        }

        return !inputBar.textView.text.isEmpty
    }

    @IBOutlet weak var scrollView: HorizontalStackScrollView!
    @IBOutlet weak var textView: ExpandableTextView!
    @IBOutlet public weak var sendButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var scrollViewPhotos: UIScrollView!
    @IBOutlet weak var tabSelectorContainer: UIView!
    
    @IBOutlet weak var topBorderHeightConstraint: NSLayoutConstraint!

    @IBOutlet var constraintsForHiddenTextView: [NSLayoutConstraint]!
    @IBOutlet weak var constraintsTextViewTop: NSLayoutConstraint!
    @IBOutlet weak var constraintsTextViewBottom: NSLayoutConstraint!
    @IBOutlet weak var constraintsScrollViewViewTop: NSLayoutConstraint!
    @IBOutlet weak var constraionTabSelectorContainerBottom: NSLayoutConstraint!

    @IBOutlet var constraintsForVisibleSendButton: [NSLayoutConstraint]!
    @IBOutlet var constraintsForHiddenSendButton: [NSLayoutConstraint]!
    @IBOutlet var tabBarContainerHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var constraintsCloseButtonBottom: NSLayoutConstraint!
    @IBOutlet weak var constraintsSendButtonBottom: NSLayoutConstraint!
    
    class open func loadNib() -> ChatInputBar {
        let view = Bundle(for: self).loadNibNamed(self.nibName(), owner: nil, options: nil)!.first as! ChatInputBar
        view.translatesAutoresizingMaskIntoConstraints = false
        view.frame = CGRect.zero
        return view
    }

    override class func nibName() -> String {
        return "ChatInputBar"
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.clipsToBounds = true
        self.topBorderHeightConstraint.constant = 1 / UIScreen.main.scale
        self.textView.scrollsToTop = false
        self.textView.delegate = self
        self.textView.delegate_ = self
        self.textView.layer.cornerRadius = 5.0
        self.textView.layer.borderWidth = 1.0
        self.textView.layer.borderColor = UIColor.lightGray.cgColor
        self.scrollView.scrollsToTop = false
        self.sendButton.isEnabled = false
        
        self.scrollViewPhotos.layer.cornerRadius = 5
        self.scrollViewPhotos.layer.borderColor = UIColor.lightGray.cgColor
        self.scrollViewPhotos.layer.borderWidth = 1
    }

    open override func updateConstraints() {
//        if self.showsTextView {
//            NSLayoutConstraint.activate(self.constraintsForVisibleTextView)
//            NSLayoutConstraint.deactivate(self.constraintsForHiddenTextView)
//        } else {
//            NSLayoutConstraint.deactivate(self.constraintsForVisibleTextView)
//            NSLayoutConstraint.activate(self.constraintsForHiddenTextView)
//        }
//        if self.showsSendButton {
//            NSLayoutConstraint.deactivate(self.constraintsForHiddenSendButton)
//            NSLayoutConstraint.activate(self.constraintsForVisibleSendButton)
//        }
//        else {
//            NSLayoutConstraint.deactivate(self.constraintsForVisibleSendButton)
//            NSLayoutConstraint.activate(self.constraintsForHiddenSendButton)
//        }

        self.constraintsCloseButtonBottom.constant = self.showsShelf ? 44 : 0
        self.constraintsTextViewBottom.constant = self.showsShelf ? 54 : 10
        self.constraintsSendButtonBottom.constant = self.showsShelf ? 44 : 0
        self.constraionTabSelectorContainerBottom.constant = self.showsShelf ? 0 : -44

        super.updateConstraints()
    }

    open var showsTextView: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
            self.updateIntrinsicContentSizeAnimated()
        }
    }

    open var showsShelf: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
//            self.updateIntrinsicContentSizeAnimated()
        }
    }

    open var showsSendButton: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
            self.updateIntrinsicContentSizeAnimated()
        }
    }

    public var maxCharactersCount: UInt? // nil -> unlimited

    private func updateIntrinsicContentSizeAnimated() {
        let options: UIViewAnimationOptions = [.beginFromCurrentState, .allowUserInteraction]
        UIView.animate(withDuration: 0.25, delay: 0, options: options, animations: { () -> Void in
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }, completion: nil)
    }

    open override func layoutSubviews() {
        self.updateConstraints() // Interface rotation or size class changes will reset constraints as defined in interface builder -> constraintsForVisibleTextView will be activated
        super.layoutSubviews()
    }

    var inputItems = [ChatInputItemProtocol]() {
        didSet {
            let inputItemViews = self.inputItems.map { (item: ChatInputItemProtocol) -> ChatInputItemView in
                let inputItemView = ChatInputItemView()
                inputItemView.inputItem = item
                inputItemView.delegate = self
                return inputItemView
            }
            self.scrollView.addArrangedViews(inputItemViews)
        }
    }

    open func becomeFirstResponderWithInputView(_ inputView: UIView?) {
        self.textView.inputView = inputView

        if self.textView.isFirstResponder {
            self.textView.reloadInputViews()
        } else {
            self.textView.becomeFirstResponder()
        }
    }

    public var inputText: String {
        get {
            return self.textView.text
        }
        set {
            self.textView.text = newValue
            self.updateSendButton()
        }
    }

    fileprivate func updateSendButton() {
        self.sendButton.isEnabled = self.shouldEnableSendButton(self)
    }

    @IBAction func buttonTapped(_ sender: AnyObject) {
        self.presenter?.onSendButtonPressed()
        self.delegate?.inputBarSendButtonPressed(self)
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        self.showsShelf = !self.showsShelf
    }
    
    public func setTextViewPlaceholderAccessibilityIdentifer(_ accessibilityIdentifer: String) {
        self.textView.setTextPlaceholderAccessibilityIdentifier(accessibilityIdentifer)
    }
    
    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) || action == #selector(UIResponderStandardEditActions.copy(_:)) {
            return true
        }
        
        return false
    }

    public func showPhotosCollectionView(_ value: Bool) {
        self.constraintsTextViewTop.constant = value ? 120 : 10
        self.constraintsScrollViewViewTop.constant = value ? 10 : -110
        self.scrollViewPhotos.isHidden = !value
    }
    
    public func setPhotoItemList(_ list: [(index: IndexPath, url: URL)]) {
        if list != nil && list.count > 0 {
            self.showPhotosCollectionView(true)
        } else {
            self.showPhotosCollectionView(false)
        }

        for item in self.scrollViewPhotos.subviews {
            if item is ChatInputPhotoCell {
                item.removeFromSuperview()
            }
        }
        
        var i:Int = 0
        for item in list {
            let url:URL = item.url
            var imageView: ChatInputPhotoCell = ChatInputPhotoCell(frame: CGRect(x: 5 + 150*i, y: 5, width: 144, height: 90))
            imageView.item = item
            imageView.delegate = self
            
            if url.pathExtension.lowercased() == "pdf" {
                let img:UIImage? = self.drawPDFfromURL(url: url)
                
                if img != nil {
                    imageView.image = img
                } else {
                    imageView.backgroundColor = UIColor(red: 71.0/255.0, green:160.0/255.0, blue:219.0/255.0, alpha: 1.0)
                }
            } else {
                let imgData = try! Data(contentsOf: url)
                imageView.image = UIImage(data: imgData)
            }
            
            self.scrollViewPhotos.addSubview(imageView)
            i += 1
        }
        
        self.scrollViewPhotos.contentSize =  CGSize(width: list.count*150 + 10, height: 100)
        self.scrollViewPhotos.scrollRectToVisible(CGRect(x: self.scrollViewPhotos.contentSize.width - self.scrollViewPhotos.frame.size.width, y: 0, width: self.scrollViewPhotos.frame.size.width, height: self.scrollViewPhotos.frame.size.height), animated: true)
        self.updateSendButton()
    }
    
    func chatInputPhotoCellDidRemove(cell: ChatInputPhotoCell, item: (index: IndexPath, url: URL)) {
        self.delegate?.inputBarDidRemovePhoto(self, item: item)

        cell.removeFromSuperview()
        
        var i: Int = 0
        for photoCell in self.scrollViewPhotos.subviews {
            if photoCell is ChatInputPhotoCell {
                photoCell.frame = CGRect(x: 5 + 150*i, y: 5, width: 144, height: 90)
                i += 1
            }
        }
        
        self.scrollViewPhotos.contentSize =  CGSize(width: i*150 + 10, height: 100)

        if i == 0 {
            self.showPhotosCollectionView(false)
        }

        self.updateSendButton()
    }
    
    func drawPDFfromURL(url: URL) -> UIImage? {
        guard let document = CGPDFDocument(url as CFURL) else { return nil }
        guard let page = document.page(at: 1) else { return nil }
        
        let pageRect = page.getBoxRect(.mediaBox)
        if #available(iOS 10.0, *) {
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let img1 = renderer.jpegData(withCompressionQuality: 1.0, actions: { cnv in
                UIColor.white.set()
                cnv.fill(pageRect)
                cnv.cgContext.translateBy(x: 0.0, y: pageRect.size.height);
                cnv.cgContext.scaleBy(x: 1.0, y: -1.0);
                cnv.cgContext.drawPDFPage(page);
            })
            let img2 = UIImage(data: img1)
            return img2
        } else {
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
                let thumbSize = 640
                let options: [NSString: NSObject] = [
                    kCGImageSourceThumbnailMaxPixelSize: thumbSize as NSObject,
                    kCGImageSourceCreateThumbnailFromImageIfAbsent: true as NSObject,
                    kCGImageSourceCreateThumbnailWithTransform: true as NSObject]
                return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary?).flatMap { UIImage(cgImage: $0) }
            }
        }
        
        return nil
    }
}

// MARK: - ChatInputItemViewDelegate
extension ChatInputBar: ChatInputItemViewDelegate {
    func inputItemViewTapped(_ view: ChatInputItemView) {
        self.focusOnInputItem(view.inputItem)
    }

    public func focusOnInputItem(_ inputItem: ChatInputItemProtocol) {
        let shouldFocus = self.delegate?.inputBar(self, shouldFocusOnItem: inputItem) ?? true
        guard shouldFocus else { return }

        self.presenter?.onDidReceiveFocusOnItem(inputItem)
        self.delegate?.inputBar(self, didReceiveFocusOnItem: inputItem)
    }
}

// MARK: - ChatInputBarAppearance
extension ChatInputBar {
    public func setAppearance(_ appearance: ChatInputBarAppearance) {
        self.textView.font = appearance.textInputAppearance.font
        self.textView.textColor = appearance.textInputAppearance.textColor
        self.textView.textContainerInset = appearance.textInputAppearance.textInsets
        self.textView.setTextPlaceholderFont(appearance.textInputAppearance.placeholderFont)
        self.textView.setTextPlaceholderColor(appearance.textInputAppearance.placeholderColor)
        self.textView.setTextPlaceholder(appearance.textInputAppearance.placeholderText)
        self.tabBarInterItemSpacing = appearance.tabBarAppearance.interItemSpacing
        self.tabBarContentInsets = appearance.tabBarAppearance.contentInsets
//        self.sendButton.contentEdgeInsets = appearance.sendButtonAppearance.insets
//        self.sendButton.setTitle(appearance.sendButtonAppearance.title, for: .normal)
//        appearance.sendButtonAppearance.titleColors.forEach { (state, color) in
//            self.sendButton.setTitleColor(color, for: state.controlState)
//        }
//        self.sendButton.titleLabel?.font = appearance.sendButtonAppearance.font
        self.tabBarContainerHeightConstraint.constant = appearance.tabBarAppearance.height
    }
}

extension ChatInputBar { // Tabar
    public var tabBarInterItemSpacing: CGFloat {
        get {
            return self.scrollView.interItemSpacing
        }
        set {
            self.scrollView.interItemSpacing = newValue
        }
    }

    public var tabBarContentInsets: UIEdgeInsets {
        get {
            return self.scrollView.contentInset
        }
        set {
            self.scrollView.contentInset = newValue
        }
    }
}

// MARK: UITextViewDelegate
extension ChatInputBar: UITextViewDelegate {
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return self.delegate?.inputBarShouldBeginTextEditing(self) ?? true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.presenter?.onDidEndEditing()
        self.delegate?.inputBarDidEndEditing(self)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        textView.tintColor = UIColor(red: 71.0/255.0, green:160.0/255.0, blue:219.0/255.0, alpha: 1.0)
        self.presenter?.onDidBeginEditing()
        self.delegate?.inputBarDidBeginEditing(self)
    }

    public func textViewDidChange(_ textView: UITextView) {
        self.updateSendButton()
        self.delegate?.inputBarDidChangeText(self)
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn nsRange: NSRange, replacementText text: String) -> Bool {
        let range = self.textView.text.bma_rangeFromNSRange(nsRange)
        if let maxCharactersCount = self.maxCharactersCount {
            let currentCount = textView.text.characters.count
            let rangeLength = textView.text.substring(with: range).characters.count
            let nextCount = currentCount - rangeLength + text.characters.count
            return UInt(nextCount) <= maxCharactersCount
        }
        return true
    }
}

// MARK: ExpandableTextViewDelegate
extension ChatInputBar: ExpandableTextViewDelegate {
    func didPasteImageWithData(_ imageData: Data) {
        self.presenter?.onSendImage(imageData)
    }
}

private extension String {
    func bma_rangeFromNSRange(_ nsRange: NSRange) -> Range<String.Index> {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return  self.startIndex..<self.startIndex }
        return from ..< to
    }
}
