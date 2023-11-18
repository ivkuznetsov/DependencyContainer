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
    
public enum DI {

    ///Property wrapper with a reference to a service in DI.Container.
    ///This wrapper doesn't increaze the size of a struct.
    @propertyWrapper
    public struct Static<Service> {
        
        public let wrappedValue: Service
        private let key: Key<Service>?
        
        public init(_ key: Key<Service>) {
            self.key = key
            wrappedValue = Container.resolve(key)
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            self.key = nil
            wrappedValue = Container.resolveObservable(key).observed[keyPath: keyPath]
        }
        
        public var projectedValue: Static<Service> { self }
        
        public func replace(_ service: Service) {
            if let key {
                Container.register(key, service)
            }
        }
    }
    
    ///Property wrapper with a reference to an 'any ObservableObject' service in DI.Container.
    ///It should be used only in SwiftUI view. The change in service triggers the view update.
    ///The sub-service can be referenced by using a KeyPath.
    ///The size is 17 bytes.
    @propertyWrapper
    public struct Observed<Service>: DynamicProperty {
        
        @StateObject private var wrapper: ObservableObjectWrapper<Service>
        
        public var wrappedValue: Service { wrapper.observed }
        
        public init(wrappedValue value: Service) {
            _wrapper = .init(wrappedValue: .init(value))
        }
        
        public init(_ key: Key<Service>) {
            _wrapper = .init(wrappedValue: Container.resolveObservable(key))
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            _wrapper = .init(wrappedValue: .init(Container.resolveObservable(key).observed[keyPath: keyPath]))
        }
        
        public var projectedValue: Binding<Service> { $wrapper.observed }
    }
    
    ///Property wrapper with a refernce to an 'any ObservableObject' service in DI.Container.
    ///It should be used in another 'ObservableObject'. An update of the service triggers objectWillChange of enoclosing instance.
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
                return instance[keyPath: storageKeyPath].value
            }
            set { }
        }
        
        private func setupObserver<T: ObservableObject>(_ instance: T) {
            observer = ((value as? any ObservableObject)?.sink { [weak instance] in
                (instance?.objectWillChange as? any Publisher as? ObservableObjectPublisher)?.send()
            })
        }

        private var observer: AnyCancellable?
        
        @available(*, unavailable, message: "This property wrapper can only be applied to classes")
        public var wrappedValue: Service {
            get { fatalError() }
            set { fatalError() }
        }
        
        private var value: Service
        private let key: Key<Service>?
        
        public init(wrappedValue value: Service) {
            key = nil
            self.value = value
        }
        
        public init<ServiceContainer>(_ key: Key<ServiceContainer>, _ keyPath: KeyPath<ServiceContainer, Service>) {
            self.key = nil
            value = Container.resolveObservable(key).observed[keyPath: keyPath]
        }
        
        public init(_ key: Key<Service>) {
            self.key = key
            value = Container.resolve(key)
        }
        
        public var projectedValue: RePublished<Service> { self }
        
        public func replace(_ service: Service) {
            if let key = projectedValue.key {
                Container.register(key, service)
            }
            observer = nil
            value = service
        }
    }
}

///ObservableObject wrapper with type erased input. An update of the contained instance triggers objectWillChange of this wrapper.
///This is convenient for using protocol types.
public final class ObservableObjectWrapper<Value>: ObservableObject {
    
    public fileprivate(set) var observed: Value
    private var observer: AnyCancellable?
    
    public init(_ observable: Value) {
        self.observed = observable
        
        observer = (observable as? any ObservableObject)?.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

private extension ObservableObject {
    
    func sink(_ closure: @escaping ()->()) -> AnyCancellable {
        objectWillChange.sink { _ in closure() }
    }
}
