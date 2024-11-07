//
//  DI.swift
//  
//
//  Created by Ilya Kuznetsov on 29/03/2023.
//

import Foundation
import SwiftUI
import Combine

///An example of using the dependency injection container.
///Define keys:
///
///     extension DI {
///         static let network = Key<any Network>()
///         static let dataManager = Key<any DataManager>()
///         static let settings = Key<any Settings>()
///     }
///
///Register your serivces:
///
///     extension DI.Container {
///         static func setup() {
///             register(DI.network, NetworkImp())
///             register(DI.dataManager, DataManagerImp())
///             register(DI.settings, SettingsImp())
///         }
///     }
///
///Use in class:
///
///     class SomeStateObject: ObservableObject {
///         @DI.Static(DI.network, \.tokenUpdater) var tokenUpdater
///         @DI.RePublished(DI.settings) var settings
///     }
///
///Use in view:
///
///     struct SomeView: View {
///         @DI.Observed(DI.dataManager) var data
///     }

///A namespace for the dependency injection container.
public enum DI {

    ///A property wrapper that provides a reference to a service in DI.Container.
    @propertyWrapper
    public struct Static<Service> {
        
        public let wrappedValue: Service
        
        public init(value: Service) {
            self.wrappedValue = value
        }
        
        public init(_ key: Key<Service>) {
            wrappedValue = Container.resolve(key)
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            wrappedValue = Container.resolve(key)[keyPath: keyPath]
        }
        
        public var projectedValue: Static<Service> { self }
    }
    
    ///A property wrapper that provides a reference to an 'any ObservableObject' service in DI.Container.
    ///It should be used only in SwiftUI views. Changes in service trigger view updates.
    @propertyWrapper
    public struct Observed<Service>: DynamicProperty {
        
        @dynamicMemberLookup public struct Wrapper {

            let serivce: Service
            
            public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<Service, Subject>) -> Binding<Subject> {
                .init(get: { serivce[keyPath: keyPath] },
                      set: { serivce[keyPath: keyPath] = $0 })
            }
        }
        
        @StateObject private var object: AnyObservableObject
        
        public var wrappedValue: Service { object.base as! Service }
        
        public init(value: Service) {
            _object = .init(wrappedValue: .init(baseOrFail: value))
        }
        
        public init(_ key: Key<Service>) {
            _object = .init(wrappedValue: .init(baseOrFail: Container.resolve(key)))
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            _object = .init(wrappedValue: .init(baseOrFail: Container.resolve(key)[keyPath: keyPath]))
        }
        
        public var projectedValue: Wrapper {
            Wrapper(serivce: wrappedValue)
        }
    }
    
    ///A property wrapper that provides a reference to an 'any ObservableObject' service in DI.Container.
    ///It should be used in another 'ObservableObject'. Updates of the service trigger objectWillChange of the enclosing instance.
    ///The sub-service can be referenced by using a KeyPath.
    @propertyWrapper
    public final class RePublished<Service> {
        
        public static subscript<T: ObservableObject>(
            _enclosingInstance instance: T,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Service>,
            storage storageKeyPath: ReferenceWritableKeyPath<T, RePublished>) -> Service {
            get {
                if instance[keyPath: storageKeyPath].observer == nil {
                    instance[keyPath: storageKeyPath].setupObserver(instance)
                }
                return instance[keyPath: storageKeyPath].value.base as! Service
            }
            set { }
        }
        
        private func setupObserver<T: ObservableObject>(_ instance: T) {
            observer = value.sink { [weak instance] in
                (instance?.objectWillChange as? any Publisher as? ObservableObjectPublisher)?.send()
            }
        }

        @available(*, unavailable, message: "This property wrapper can only be applied to ObservableObject")
        public var wrappedValue: Service {
            get { fatalError() }
            set { fatalError() }
        }
        
        private let value: AnyObservableObject
        private var observer: AnyCancellable?
        
        public init(value: Service) {
            self.value = .init(baseOrFail: value)
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            value = .init(baseOrFail: Container.resolve(key)[keyPath: keyPath])
        }
        
        public init(_ key: Key<Service>) {
            value = .init(baseOrFail: Container.resolve(key))
        }
        
        public var projectedValue: RePublished<Service> { self }
    }
}

extension DI.Static: Sendable where Service: Sendable { }

///ObservableObject wrapper with type erased input. An update of the contained instance triggers objectWillChange of this wrapper.
///This is convenient for using protocol types.
public final class AnyObservableObject: ObservableObject {
    
    public let base: any ObservableObject
    private var observer: AnyCancellable?
    
    public init(_ base: any ObservableObject) {
        self.base = base
        
        observer = base.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

extension AnyObservableObject {
    
    convenience init(baseOrFail base: Any) {
        if let base = base as? any ObservableObject {
            self.init(base)
        } else {
            fatalError("\(type(of: base)) required to be an ObservableObject")
        }
    }
}

private extension ObservableObject {
    
    ///Helper function to subscribe to objectWillChange.
    func sink(_ closure: @escaping ()->()) -> AnyCancellable {
        objectWillChange.sink { _ in closure() }
    }
}
