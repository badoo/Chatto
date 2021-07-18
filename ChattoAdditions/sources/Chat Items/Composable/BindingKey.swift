
import Foundation

// MARK: - Protocol

public protocol BindingKeyProtocol: Hashable, CustomStringConvertible {
    associatedtype View
    associatedtype ViewModel
    associatedtype LayoutProvider: LayoutProviderProtocol
    var uuid: UUID { get }
}

// MARK: - Implementation

public struct BindingKey<View, ViewModel, LayoutProvider: LayoutProviderProtocol>: BindingKeyProtocol {
    public let uuid = UUID()
    public var description: String { "BindingKey<\(View.self),\(ViewModel.self),\(LayoutProvider.self)>" }
}

// MARK: - Type erasure

public struct AnyBindingKey: Hashable, CustomStringConvertible {

    let uuid: UUID

    // MARK: - Private properties

    private let viewType: Any.Type
    private let viewModelType: Any.Type
    private let layoutProviderType: Any.Type
    private let _description: () -> String

    // MARK: - Instantiation

    public init<Base: BindingKeyProtocol>(_ base: Base) {
        self.viewType = Base.View.self
        self.viewModelType = Base.ViewModel.self
        self.layoutProviderType = Base.LayoutProvider.self
        self.uuid = base.uuid
        self._description = { base.description }
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.uuid)
        hasher.combine(ObjectIdentifier(self.viewType))
        hasher.combine(ObjectIdentifier(self.viewModelType))
        hasher.combine(ObjectIdentifier(self.layoutProviderType))
    }

    // MARK: - Equatable

    public static func == (lhs: AnyBindingKey, rhs: AnyBindingKey) -> Bool {
        return lhs.viewType == rhs.viewType
            && lhs.viewModelType == rhs.viewModelType
            && lhs.layoutProviderType == rhs.layoutProviderType
            && lhs.uuid == rhs.uuid
    }

    // MARK: - CustomStringConvertible

    public var description: String { self._description() }
}
