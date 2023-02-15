<img alt="FoundationDB logo" src="Logo.png?raw=true" height="200">
---

[![Swift](https://github.com/HUK-COBURG/schwifty-resources/actions/workflows/swift.yml/badge.svg)](https://github.com/HUK-COBURG/schwifty-resources/actions/workflows/swift.yml)

With `schwifty-resources` you get a schwifty way of reading and writing data.

The main idea is to have a similar way of accessing local or remote resources, convenient to use, although having a high flexibility.
It can be used for communicating over HTTP, reading or writing files in the sandbox, acessing user defaults and bundle resources.

## Getting Started Using `schwifty-resources`

### Adding the package

In your `Package.swift` Swift Package Manager manifest, add the following dependency to your `dependencies` argument:

```swift
.package(url: "https://github.com/HUK-COBURG/schwifty-resources.git", .branch("main")),
```

Add the dependency to any targets you've declared in your manifest:

```swift
.target(name: "MyTarget", dependencies: ["SchwiftyResources"]),
```

### Reading bundle resources

To get some data in the bundle, use `BundleResource`, supplying a `ContentResourceDecoder` for the type of data you want to read and a file name to identify it.
In this example a `StringResourceCoder` is used to get the content of the file `document.txt` in the main bundle as a `String`.

```swift
import SchwiftyResources

private struct DocumentBundleResource: BundleResource {
    typealias ContentResourceDecoder = StringResourceCoder
    let fileName: String = "document.txt"
}

do {
    let resource = DocumentBundleResource()
    let content = try await resource.read()
    print(content)
} catch {
    print(error)
}
```

### Getting HTTP API content

To get some data from an HTTP API, use `HttpResource`, supplying a `RequestBodyResourceEncoder`, `ResponseBodyResourceDecoder` and an URL.
In this example the request body will be empty, we are expecting a JSON response body from the url `https://jsonplaceholder.typicode.com/todos` with `Todo` instances in it.

```swift
import SchwiftyResources
import Foundation

private struct Todo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

private struct TodosHttpResource: HttpResource {
    typealias RequestBodyResourceEncoder = EmptyResourceCoder
    typealias ResponseBodyResourceDecoder = JsonResourceCoder<[Todo]>
    let url: URL = "https://jsonplaceholder.typicode.com/todos"
}

do {
    let resource = TodosHttpResource()
    let response = try await resource.response
    let content = response.content
    print(content)
} catch {
    print(error)
}
```

### Writing and reading to and from the user defaults

To write data to and read from the user defaults you can create a `UserDefaultsResource`, defining the `ContentResourceCoder` and a key.

```swift
import SchwiftyResources

struct PropertyUserDefaultsResource: UserDefaultsResource {
    typealias ContentResourceCoder = StringResourceCoder
    let key: String = "property"
}

let resource = PropertyUserDefaultsResource()

do {
    try resource.write(content: "Just a simple string.")
} catch {
    print(error)
}

do {
    let value = try resource.read()
    print(value)
} catch {
    print(error)
}
```


### Writing and reading to and from the sandbox

To write data to and read from the sandbox you can create a `SandboxResource`, defining the `ContentResourceCoder`, a location and the path (or just the file name).
In this example the data, which is stored on the file system will be AES GCM encrypted. The decrypted data though contains an encoded version of the `Rick` type.

```swift
import SchwiftyResources
import Foundation
import CryptoKit

struct Rick: Codable {
    let identifier: String
    let haircut: String
}

struct RicksKeyProvider: AesGcmCrypterKeyProvider {
    static func provideKey() -> SymmetricKey {
        let password = "pAssW0rd#OF-the/c1Tad3l"
        return SymmetricKey(data: SHA256.hash(data: Data(password.utf8)))
    }
}

struct RicksSandboxResource: SandboxResource {
    typealias ContentResourceCoder = CryptedJsonResourceCoder<[Rick], AesGcmCrypter<RicksKeyProvider>>
    let location: SandboxLocation = .documents
    var path: String = "ricks.store"
}

let resource = RicksSandboxResource()

do {
    let ricks: [Rick] = [Rick(identifier: "C-137", haircut: "Mad scientist"),
                         Rick(identifier: "Rick Prime", haircut: "Mad scientist (short)")]
    try await resource.write(content: ricks)
} catch {
    print(error)
}

do {
    let ricks = try await resource.read()
    print(ricks)
} catch {
    print(error)
}
```

## Why the name?

We like the TV show `Rick and Morty`, schwifty is a reference to a [song of them](https://www.youtube.com/watch?v=I1188GO4p1E) and it kind of sounds like Swift - simple as that.


```
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⣀⠀⢀⣼⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣷⣾⣿⣿⣷⣤⣤⣶⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣘⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣍⣀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⢽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠋⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣸⣀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⡛⣃⣤⣄⠀⠀⠀⠀⠀⣀⣀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠻⣿⣿⣿⣆⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⡀⠀⢠⣿⣿⣟⠛⠛⡏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⣿⣿⣆⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣼⣿⡟⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠘⣿⣿⡆⢰⣿⡏⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠘⣿⣿⣿⣿⠃⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠘⣿⣿⡏⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠘⠟⠁⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣇⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠓⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣠⣶⢶⣦⠀⣶⡶⠶⠆⣠⣶⣶⣶⣦⠀⠀⠀⣠⡶⢶⣦⠀⢀⣴⡶⣶⣦⢀⣶⠀⠰⣦⠀⣶⡄⠀⣶⠀⢰⡆⢰⣆⠀⣴⣶⠶⡆⣶⣶⣶⣶⣆⣶⡆⠀⢀⣦
⣸⡟⠀⠀⠀⠀⣿⣦⣤⠀⠉⠀⣿⡆⠀⠀⠀⠀⢿⣷⣤⡀⠀⣾⡏⠀⠀⠁⢸⣿⣤⣴⣿⡆⣿⡇⢠⣿⠀⣸⡇⢸⣿⠀⣿⣥⣤⠀⠈⢹⣿⠀⠀⠸⣿⣄⣼⠇
⢻⣧⡀⢸⣿⢀⣿⠉⠀⠀⠀⠀⣿⡇⠀⠀⠀⠠⣦⡈⠙⣿⡆⢿⣧⡀⢀⣠⢸⣿⠉⠀⣿⡇⢹⣧⣼⢿⣦⡿⠀⢸⣿⠀⣿⡏⠉⠀⠀⢸⣿⠀⠀⠀⢹⣿⠏⠀
⠈⠻⠿⠿⠋⠸⠟⠛⠛⠓⠀⠀⠿⠃⠀⠀⠀⠀⠙⠿⠿⠟⠁⠈⠻⠿⠿⠃⠘⠟⠀⠀⠛⠁⠀⠻⠃⠈⠛⠁⠀⠘⠟⠀⠻⠇⠀⠀⠀⠸⠿⠀⠀⠀⠺⠿⠀⠀
``` 
