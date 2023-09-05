//
//  LayoutConstants.swift
//  VoodooLabChattoAdditions
//
//  Created by Loïc Saillant on 05/09/2023.
//

import Foundation

struct LayoutConstants {
    
    static var baselineQuotient: CGFloat {
        if #available(iOS 16.4, *) {
            return 2.0
        } else {
            return 4.0
        }
    }
}
