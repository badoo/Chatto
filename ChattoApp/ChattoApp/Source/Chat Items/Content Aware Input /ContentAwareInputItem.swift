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

import ChattoAdditions

open class ContentAwareInputItem {
    public var textInputHandler: ((String) -> Void)?

    let buttonAppearance: TabInputButtonAppearance
    public init(tabInputButtonAppearance: TabInputButtonAppearance = ContentAwareInputItem.createDefaultButtonAppearance()) {
        self.buttonAppearance = tabInputButtonAppearance
        self.customInputView.onAction = { [weak self] (text) in
            self?.textInputHandler?(text)
        }
    }

    public static func createDefaultButtonAppearance() -> TabInputButtonAppearance {
        let images: [UIControlStateWrapper: UIImage] = [
            UIControlStateWrapper(state: .normal): UIImage(named: "custom-icon-unselected", in: Bundle(for: ContentAwareInputItem.self), compatibleWith: nil)!,
            UIControlStateWrapper(state: .selected): UIImage(named: "custom-icon-selected", in: Bundle(for: ContentAwareInputItem.self), compatibleWith: nil)!,
            UIControlStateWrapper(state: .highlighted): UIImage(named: "custom-icon-selected", in: Bundle(for: ContentAwareInputItem.self), compatibleWith: nil)!
        ]
        return TabInputButtonAppearance(images: images, size: nil)
    }

    var customInputView: CustomInputView = {
        return CustomInputView(frame: .zero)
    }()
    lazy fileprivate var internalTabView: TabInputButton = {
        return TabInputButton.makeInputButton(withAppearance: self.buttonAppearance, accessibilityID: "text.chat.input.view")
    }()

    open var selected = false {
        didSet {
            self.internalTabView.isSelected = self.selected
        }
    }
}

// MARK: - ChatInputItemProtocol
extension ContentAwareInputItem: ChatInputItemProtocol {
    public var shouldSaveDraftMessage: Bool {
        return false
    }

    public var supportsExpandableState: Bool {
        return true
    }

    public var expandedStateTopMargin: CGFloat {
        return 140.0
    }

    public var presentationMode: ChatInputItemPresentationMode {
        return .customView
    }

    public var showsSendButton: Bool {
        return false
    }

    public var inputView: UIView? {
        return self.customInputView
    }

    public var tabView: UIView {
        return self.internalTabView
    }

    public func handleInput(_ input: AnyObject) {
        if let text = input as? String {
            self.textInputHandler?(text)
        }
    }
}

class CustomInputView: UIView {
    var onAction: ((String) -> Void)?
    private var label: UILabel!
    private var textField: UITextField!
    private var button: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(white: 0.98, alpha: 1.0)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func commonInit() {
        let textField = UITextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.borderStyle = .roundedRect
        textField.text = "Try me"
        self.textField = textField

        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 2
        label.textColor = UIColor(white: 0.15, alpha: 1.0)
        label.text = "Just a custom content view with text field and button."
        self.label = label

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        button.setTitle("Send Message", for: .normal)
        self.button = button

        self.addSubview(label)
        self.addSubview(textField)
        self.addSubview(button)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.leftAnchor.constraint(equalTo: self.leftAnchor),
            label.rightAnchor.constraint(equalTo: self.rightAnchor),
            label.heightAnchor.constraint(equalToConstant: 50.0),
            label.topAnchor.constraint(equalTo: self.topAnchor, constant: 12.0),
            textField.leftAnchor.constraint(equalTo: self.leftAnchor),
            textField.rightAnchor.constraint(equalTo: self.rightAnchor),
            textField.heightAnchor.constraint(equalToConstant: 50.0),
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12.0),
            button.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            button.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 12.0)
        ])
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }

    @objc
    private func onTap(_ sender: Any) {
        self.onAction?(self.textField.text ?? "Nothing to send")
        self.endEditing(true)
    }
}
