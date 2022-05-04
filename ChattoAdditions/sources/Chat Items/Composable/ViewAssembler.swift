
import UIKit

// MARK: - Protocols

public protocol ViewAssemblerProtocol {
    func assemble(subviews: [AnyBindingKey: UIView]) throws -> AnyIndexedSubviews
}

// MARK: - Implementation

public struct ViewAssembler: ViewAssemblerProtocol {

    // MARK: - Type declarations

    enum Error: Swift.Error {
        case internalInconsistency
    }

    // MARK: - Private properties

    private let hierarchy: MessageViewHierarchy

    // MARK: - Instantiation

    public init(hierarchy: MessageViewHierarchy) {
        self.hierarchy = hierarchy
    }

    // MARK: - ViewAssemblerProtocol

    public func assemble(subviews: [AnyBindingKey: UIView]) throws -> AnyIndexedSubviews {
        for (key, children) in self.hierarchy.allRegistrations() {
            let parentView = subviews[key]

            switch children {
            case .no:
                break
            case .single(let child):
                let childView = subviews[child]!
                guard let container = parentView as? SingleContainerViewProtocol else { throw Error.internalInconsistency }
                container.add(child: childView)
            case .multiple(let children):
                let childrenViews = children.map { subviews[$0]! }
                guard let container = parentView as? MultipleContainerViewProtocol else { throw Error.internalInconsistency }
                container.add(children: childrenViews)
            }
        }

        return AnyIndexedSubviews(
            rootKey: self.hierarchy.root,
            subviews: subviews
        )
    }
}

// MARK: - ReuseIdentifierProvider

extension ViewAssembler: ReuseIdentifierProvider {
    public var reuseIdentifier: String {
        var components: [String] = [self.hierarchy.root.description]

        for (parent, children) in self.hierarchy.allRegistrations() {
            var string = parent.description
            defer { components.append(string) }

            switch children {
            case .no:
                continue
            case .single(let child):
                string += "->\(child.description)"
            case .multiple(let children):
                let childrenDescription = children.map { $0.description }.joined(separator: ",")
                string += "->\(childrenDescription)"
            }
        }

        return components.joined(separator: "::")
    }
}

