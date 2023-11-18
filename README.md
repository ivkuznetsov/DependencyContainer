# DependencyContainer

Implementation of dependency injections

An example of using the dependency injection container.
Define keys:
```swift
extension DI {
    static let network = Key<any Network>()
    static let dataManager = Key<any DataManager>()
    static let settings = Key<any Settings>()
}
```

Register your serivces:
```swift
extension DI.Container {
    static func setup() {
        register(DI.network, NetworkImp())
        register(DI.dataManager, DataManagerImp())
        register(DI.settings, SettingsImp())
    }
}
```

Use in class:
```swift
class SomeStateObject: ObservableObject {
    @DI.Static(DI.network, \.tokenUpdater) var network
    @DI.RePublished(DI.settings) var settings
}
```

RePublished property wrapper redirects update from a service to a container ObservableObject

Use in view:
```swift
struct SomeView: View {
    @DI.Observed(DI.dataManager) var data
}
```

## Meta

Ilya Kuznetsov – i.v.kuznecov@gmail.com

Distributed under the MIT license. See ``LICENSE`` for more information.

[https://github.com/ivkuznetsov](https://github.com/ivkuznetsov)
