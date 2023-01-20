//
//  UserDefaultsResource.swift
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

import class Foundation.UserDefaults

public protocol UserDefaultsResource {
    /// The type of the content resource coder. Must conform to `ResourceCoder`.
    associatedtype ContentResourceCoder: ResourceCoder

    /// The instance of the content resource coder.
    var contentResourceCoder: ContentResourceCoder { get }
    /// The user defaults where the resource is stored
    var userDefaults: UserDefaults { get }
    /// The key of the resource.
    var key: String { get }
    /// Will try to get the data with the given key and decode it with the content resource coder.
    func read() throws -> ContentResourceCoder.Content?
    /// Will try to encode the content using the content resource coder and write it with the given key.
    func write(content: ContentResourceCoder.Content?) throws
    /// Will try to remove the item from user defaults with the given key.
    func delete()
}

public extension UserDefaultsResource {
    var contentResourceCoder: ContentResourceCoder {
        ContentResourceCoder()
    }
    
    var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    func read() throws -> ContentResourceCoder.Content? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let content = try contentResourceCoder.decode(data: data)
        
        return content
    }
    
    func write(content: ContentResourceCoder.Content?) throws {
        guard let content = content else {
            userDefaults.set(nil, forKey: key)
            return
        }
        
        let data = try contentResourceCoder.encode(content: content)
        userDefaults.set(data, forKey: key)
    }
    
    func delete() {
        userDefaults.removeObject(forKey: key)
    }
}
