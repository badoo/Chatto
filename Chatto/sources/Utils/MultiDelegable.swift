//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import Foundation

public struct DelegateStore<Delegate> {
    private var delegatesTable = NSHashTable<AnyObject>.weakObjects()

    public init() {}

    public func add(_ delegate: Delegate) {
        self.delegatesTable.add(delegate as AnyObject)
    }

    public func remove(_ delegate: Delegate) {
        self.delegatesTable.remove(delegate as AnyObject)
    }

    public func contains(_ delegate: Delegate) -> Bool {
        return self.delegatesTable.contains(delegate as AnyObject)
    }

    public func notifyAll(_ block: (Delegate) -> Void) {
        self.delegatesTable.allObjects.compactMap { $0 as? Delegate }.forEach(block)
    }
}

extension DelegateStore: CustomStringConvertible {

    public var description: String {
        var string = "DelegateStore ["
        string += self.delegatesTable.allObjects.map({ return "<\(type(of: $0))>"}).joined(separator: ", ")
        return string + "]"
    }

}
