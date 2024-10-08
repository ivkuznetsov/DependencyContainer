# DependencyContainer

**DependencyContainer** is an implementation of dependency injection for Swift applications, designed to simplify service management and improve code modularity.

## Overview

This dependency injection container allows you to define, register, and resolve services in a clean and type-safe manner, facilitating better management of dependencies in your SwiftUI applications.

### Defining Keys

To begin using the container, you first need to define keys for your services. These keys are used to identify the services when registering and resolving them.
```swift
extension DI {
    static let network = Key<any Network>()
    static let dataManager = Key<any DataManager>()
    static let settings = Key<any Settings>()
}
```

### Registering Services

Next, you will register your services within the DI.Container. This step associates each service with its corresponding key.
```swift
extension DI.Container {
    static func setup() {
        register(DI.network, NetworkImp())
        register(DI.dataManager, DataManagerImp())
        register(DI.settings, SettingsImp())
    }
}
```

### Using Services in Classes

You can access the registered services in your classes by using the provided property wrappers. For example, in a class that conforms to ObservableObject, you can inject dependencies as follows:

```swift
class SomeStateObject: ObservableObject {
    @DI.Static(DI.network, \.tokenUpdater) var network
    @DI.RePublished(DI.settings) var settings
}
```

### `RePublished` Property Wrapper

The `RePublished` property wrapper automatically redirects updates from the injected service to the enclosing `ObservableObject`, ensuring your UI stays in sync with the underlying data.

RePublished property wrapper redirects update from a service to a container ObservableObject

### Using Services in Views

In SwiftUI views, you can also inject and observe your services. For example:
```swift
struct SomeView: View {
    @DI.Observed(DI.dataManager) var data
    
    var body: some View {
        // Your view content using the injected data manager
    }
}
```

## Meta

Ilya Kuznetsov – i.v.kuznecov@gmail.com

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/ivkuznetsov](https://github.com/ivkuznetsov)
