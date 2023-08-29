//
//  PathModifier.swift
//
//  Copyright (c) 2023 HUK-COBURG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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

            modifiedPath = modifiedPath.replacingOccurrences(of: "(\(key))", with: value)
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
