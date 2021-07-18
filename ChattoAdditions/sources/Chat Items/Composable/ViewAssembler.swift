
import UIKit

// MARK: - Protocols

public protocol ViewAssemblerProtocol {
    func assemble(subviews: [AnyBindingKey: UIView]) -> AnyIndexedSubviews
}

public protocol SingleCompositionRegistry {
    mutating func register<Composition: SingleViewComposition, Key: BindingKeyProtocol>(viewComposition: Composition, key: AnyBindingKey, to: Key)
    where Composition.View == Key.View
}

public protocol MultipleCompositionRegistry {
    mutating func register<Composition: MultipleViewComposition, Key: BindingKeyProtocol>(viewComposition: Composition, keys: [AnyBindingKey], to: Key)
    where Composition.View == Key.View
}

// MARK: - Implementation

public struct ViewAssembler: ViewAssemblerProtocol, SingleCompositionRegistry, MultipleCompositionRegistry {

    // MARK: - Type declarations

    fileprivate enum Composition {
        case single(composition: AnySingleViewComposition, key: AnyBindingKey)
        case multiple(composition: AnyMultipleViewComposition, keys: [AnyBindingKey])
    }

    // MARK: - Private properties

    fileprivate let root: AnyBindingKey
    private(set) fileprivate var compositions: [AnyBindingKey: Composition] = [:]

    // MARK: - Instantiation

    public init(root: AnyBindingKey) {
        self.root = root
    }

    // MARK: - SingleCompositionRegistry

    public mutating func register<Composition: SingleViewComposition, Key: BindingKeyProtocol>(
        viewComposition: Composition,
        key: AnyBindingKey,
        to: Key
    ) where Composition.View == Key.View {
        let erasedComposition = AnySingleViewComposition(viewComposition)
        self.compositions[.init(to)] = .single(
            composition: erasedComposition,
            key: key
        )
    }

    // MARK: - MultipleCompositionRegistry

    public mutating func register<Composition: MultipleViewComposition, Key: BindingKeyProtocol>(
        viewComposition: Composition,
        keys: [AnyBindingKey],
        to: Key
    ) where Composition.View == Key.View {
        let erasedComposition = AnyMultipleViewComposition(viewComposition)
        self.compositions[.init(to)] = .multiple(
            composition: erasedComposition,
            keys: keys
        )
    }

    // MARK: - ViewAssemblerProtocol

    public func assemble(subviews: [AnyBindingKey: UIView]) -> AnyIndexedSubviews {
        for (parentKey, composition) in self.compositions {
            let parent = subviews[parentKey]
            switch composition {
                case let .single(composition, childKey):
                    let child = subviews[childKey]!
                    composition.add(child: child, to: parent)
                case let .multiple(composition, keys):
                    let children = keys.map { subviews[$0]! }
                    composition.add(children: children, to: parent)
            }
        }
        return AnyIndexedSubviews(
            rootKey: self.root,
            subviews: subviews
        )
    }
}

// MARK: - ReuseIdentifierProvider

extension ViewAssembler: ReuseIdentifierProvider {
    public var reuseIdentifier: String {
        var components: [String] = [self.root.description]

        for (parentKey, composition) in self.compositions {
            var string = parentKey.description + "->"
            switch composition {
                case let .single(_, childKey):
                    string += childKey.description
                case let .multiple(_, childrenKeys):
                    string += childrenKeys.map { $0.description }.joined(separator: ",")
            }
            components.append(string)
        }

        return components.joined(separator: "::")
    }
}

// MARK: - Convenience

extension ViewAssembler {
    public init<Key: BindingKeyProtocol>(root: Key) {
        self.init(root: .init(root))
    }
}

