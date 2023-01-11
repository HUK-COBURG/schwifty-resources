//
//  UserDefaultsResource.swift
//  
//
//  Created by Johannes Bosecker on 10.01.23.
//

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
    func read() async throws -> ContentResourceCoder.Content?
    /// Will try to encode the content using the content resource coder and write it with the given key.
    func write(content: ContentResourceCoder.Content?) async throws
}

public extension UserDefaultsResource {
    var contentResourceCoder: ContentResourceCoder {
        ContentResourceCoder()
    }
    
    var userDefaults: UserDefaults {
        return UserDefaults.standard
    }
    
    func read() async throws -> ContentResourceCoder.Content? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let content = try contentResourceCoder.decode(data: data)
        
        return content
    }
    
    func write(content: ContentResourceCoder.Content?) async throws {
        guard let content = content else {
            userDefaults.set(nil, forKey: key)
            return
        }
        
        let data = try contentResourceCoder.encode(content: content)
        userDefaults.set(data, forKey: key)
    }
}
