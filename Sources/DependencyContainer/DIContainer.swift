//
//  DIContainer.swift
//  
//
//  Created by Ilya Kuznetsov on 15/08/2023.
//

import Foundation

extension DI {
    
    ///A key for storing services in the `DI.Container`.
    public struct Key<Value>: Hashable, Sendable {
        private let id = UUID()
        
        public init() {}
    }
    
    ///A singleton container for managing services.
    ///Registering a new service with an existing key replaces the old one.
    public final class Container {
        
        ///The singleton instance of the service container
        fileprivate static let current = Container()
        
        ///Lock for thread-safe access to storage
        private var lock = pthread_rwlock_t()
        
        ///Storage for registered services, using the hash value of the key for indexing
        private var storage: [Int:Any] = [:]
        
        public init() {
            pthread_rwlock_init(&lock, nil)
        }
        
        ///Registers a new service with a specified key.
        /// - Parameters:
        ///   - key: The key used to identify the service.
        ///   - make: A closure that produces the service instance.
        public static func register<Service>(_ key: Key<Service>, _ make: ()->Service) {
            let service = make()
            pthread_rwlock_wrlock(&current.lock)
            current.storage[key.hashValue] = service
            pthread_rwlock_unlock(&current.lock)
        }
        
        /// Registers a service with a specified key.
        /// - Parameters:
        ///   - key: The key used to identify the service.
        ///   - service: The service instance to register.
        public static func register<Service>(_ key: Key<Service>, _ service: Service) {
            register(key, { service })
        }
        
        /// Resolves a service for the specified key.
        /// - Parameter key: The key used to identify the service.
        /// - Returns: The requested service instance.
        public static func resolve<Service>(_ key: Key<Service>) -> Service {
            pthread_rwlock_rdlock(&current.lock)
            guard let result = current.storage[key.hashValue] as? Service else {
                fatalError("The service \(type(of: Service.self)) is not registered")
            }
            pthread_rwlock_unlock(&current.lock)
            return result
        }
        
        deinit {
            pthread_rwlock_destroy(&lock)
        }
    }
}
