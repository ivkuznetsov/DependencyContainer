//
//  DIContainer.swift
//  
//
//  Created by Ilya Kuznetsov on 15/08/2023.
//

import Foundation

extension DI {
    
    ///A key for storing services in DI.Container
    public struct Key<Value>: Hashable {
        private let id = ObjectIdentifier(Value.self)
        
        public init() {}
    }
    
    ///A singletone container for services. Registering a new service replaces the old one with the same key.
    public final class Container {
        
        fileprivate static let current = Container()
        private var lock = pthread_rwlock_t()
        private var storage: [Int:Any] = [:]
        
        public init() {
            pthread_rwlock_init(&lock, nil)
        }
        
        public static func register<Service>(_ key: Key<Service>, _ make: ()->Service) {
            let service = make()
            pthread_rwlock_wrlock(&current.lock)
            current.storage[key.hashValue] = ObservableObjectWrapper(service)
            pthread_rwlock_unlock(&current.lock)
        }
        
        public static func register<Service>(_ key: Key<Service>, _ service: Service) {
            register(key, { service })
        }
        
        public static func resolveObservable<Service>(_ key: Key<Service>) -> ObservableObjectWrapper<Service> {
            pthread_rwlock_rdlock(&current.lock)
            let result = current.storage[key.hashValue] as! ObservableObjectWrapper<Service>
            pthread_rwlock_unlock(&current.lock)
            return result
        }
        
        public static func resolve<Service>(_ key: Key<Service>) -> Service {
            resolveObservable(key).observed
        }
        
        deinit {
            pthread_rwlock_destroy(&lock)
        }
    }
}
