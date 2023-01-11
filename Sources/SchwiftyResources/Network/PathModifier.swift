//
//  PathModifier.swift
//
//
//  Created by Johannes Bosecker on 29.11.22.
//

/// Conform to this type to manipulate the path of a URL.
public protocol PathModifier {
    /// This function will be called before the request is sent. Return the modified path, which should replace the path before.
    func modify(path: String) -> String
}

/// A path modifier, which takes a dictionary of parameters (key value pairs) and replaces the occurrences of "{key}" with "value".
public struct ParametersPathModifier: PathModifier {
    public let parameters: [String: String]

    public init(parameters: [String: String]) {
        self.parameters = parameters
    }

    public func modify(path: String) -> String {
        var modifiedPath = path

        for key in parameters.keys {
            guard let value = parameters[key] else {
                continue
            }

            modifiedPath = modifiedPath.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return modifiedPath
    }
}

/// A path modifier, which appends the given component at the end of the path.
public struct AppendComponentPathModifier: PathModifier {
    public let component: String

    public init(component: String) {
        self.component = component
    }

    public func modify(path: String) -> String {
        var modifiedPath = path

        if modifiedPath.last == "/" {
            modifiedPath.removeLast()
        }

        if component.first != "/" {
            modifiedPath.append("/")
        }

        modifiedPath.append(component)

        return modifiedPath
    }
}
