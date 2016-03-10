//
//  BaseMessageCollectionViewCellAvatarStyle.swift
//  ChattoApp
//
//  Created by Zhao Wang on 3/9/16.
//  Copyright © 2016 Badoo. All rights reserved.
//

import Foundation
import ChattoAdditions

class BaseMessageCollectionViewCellAvatarStyle: BaseMessageCollectionViewCellDefaultStyle {
    override func getAvatarImageSize(messageViewModel: MessageViewModelProtocol) -> CGSize {
        // Display avatar for both incoming and outgoing messages for demo purpose
        if messageViewModel.isIncoming {
            return CGSize(width: 35, height: 35)
        } else {
            return CGSize(width: 35, height: 35)
        }
    }
}
