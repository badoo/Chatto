//
//  ChatInputPhotoCell.swift
//  Pods
//
//  Created by Norayr Harutyunyan on 12/6/16.
//
//

import UIKit

protocol ChatInputPhotoCellProtocol {
    // protocol definition goes here
    
    func chatInputPhotoCellDidRemove(cell: ChatInputPhotoCell, item: (index: IndexPath, url: URL))
}

open class ChatInputPhotoCell: UIImageView {
    var removeButton: UIButton!
    var item: (index: IndexPath, url: URL)!
    
    var delegate:ChatInputPhotoCellProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private var imageView: UIImageView!
    private func commonInit() {
        self.clipsToBounds = true
        self.contentMode = .scaleAspectFill
        self.isUserInteractionEnabled = true

        removeButton = UIButton(type: .custom)
        let image:UIImage = UIImage(named: "remove-photo-button", in: Bundle(for: PhotosInputPlaceholderCell.self), compatibleWith: nil)!
        removeButton.setImage(image, for: UIControlState.normal)
        removeButton.addTarget(self, action: #selector(onButtonRemove), for: .touchUpInside)
        self.addSubview(removeButton)
        
        self.layer.cornerRadius = 5
        self.clipsToBounds = true
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.removeButton.frame = CGRect(x: self.frame.size.width - 31, y: 3, width: 27, height: 27)
    }
    
    func onButtonRemove () {
        delegate?.chatInputPhotoCellDidRemove(cell: self, item: self.item)
    }
}
