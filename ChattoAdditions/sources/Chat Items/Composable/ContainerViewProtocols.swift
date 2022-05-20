
import UIKit

public protocol SingleContainerViewProtocol {
    func add(child view: UIView)
}

public protocol MultipleContainerViewProtocol {
    func add(children: [UIView])
}

