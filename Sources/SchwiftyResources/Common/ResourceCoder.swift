//
//  ResourceCoder.swift
//  
//
//  Created by Johannes Bosecker on 10.01.23.
//

import struct Foundation.Data
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

/// Conform to this protocol and set it as typealias of `HttpResource`, `LocalResource` or `UserDefaultsResource` to be able to en- and decode the content.
public protocol ResourceCoder<Content> {
    associatedtype Content
    init()
    var contentType: String? { get }
    func encode(content: Content) throws -> Data?
    func decode(data: Data) throws -> Content
}

/// This resource coder will encode to nil Data and decode to a `Void`. The ContentType will also be empty.
public struct EmptyResourceCoder: ResourceCoder {
    public typealias Content = Void

    public init() {}

    public let contentType: String? = nil

    public func encode(content: Void) throws -> Data? {
        return nil
    }

    public func decode(data _: Data) throws -> Content {
        return ()
    }
}

/// This resource coder will just pass through the data. The ContentType has to be set.
public struct DataResourceCoder: ResourceCoder {
    public typealias Content = Data

    public init() {}

    public var contentType: String?

    public func encode(content: Data) throws -> Data? {
        return content
    }

    public func decode(data: Data) throws -> Content {
        return data
    }
}

/// This resource coder will encode the given `Model` using a default `JSONEncoder` and decode the data to the given `Model`, by passing it to a default `JSONDecoder`. `Model` has to conform to `Codable`. The ContentType is fixed to "application/json".
public struct JsonResourceCoder<Model: Codable>: ResourceCoder {
    public typealias Content = Model

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public init() {}

    public let contentType: String? = "application/json"

    public func encode(content: Model) throws -> Data? {
        do {
            return try jsonEncoder.encode(content)
        } catch {
            throw SchwiftyResourcesError.jsonEncodingFailed(error)
        }
    }
    
    public func decode(data: Data) throws -> Content {
        do {
            return try jsonDecoder.decode(Content.self, from: data)
        } catch {
            throw SchwiftyResourcesError.jsonDecodingFailed(error)
        }
    }
}

public struct CryptedJsonResourceCoder<Model: Codable, Cryption: Crypter>: ResourceCoder {
    public typealias Content = Model
    
    let jsonResourceCoder = JsonResourceCoder<Model>()
    
    public init() {}
    
    public let contentType: String? = "application/octet-stream"
    
    public func encode(content: Model) throws -> Data? {
        let jsonData = try jsonResourceCoder.encode(content: content)
        
        do {
            let data = try Cryption.encrypt(data: jsonData ?? Data())
            return data
        } catch {
            throw SchwiftyResourcesError.encryptionFailed(error)
        }
    }
    
    public func decode(data: Data) throws -> Content {
        var jsonData: Data? = nil
        
        do {
            jsonData = try Cryption.decrypt(data: data)
        } catch {
            throw SchwiftyResourcesError.decryptionFailed(error)
        }
        
        guard let jsonData = jsonData else {
            throw SchwiftyResourcesError.decryptionFailed(nil)
        }
        
        let content = try jsonResourceCoder.decode(data: jsonData)
        return content
    }
}

/// This resource coder will encode a `String` to UTF8 Data and decode from UTF8 Data to a `String`. The ContentType defaults to "text/plain" but can be set, if desired.
public struct StringResourceCoder: ResourceCoder {
    public typealias Content = String

    public init() {}

    public var contentType: String? = "text/plain"

    public func encode(content: String) throws -> Data? {
        return content.data(using: .utf8)
    }

    public func decode(data: Data) throws -> Content {
        guard let string = String(data: data, encoding: .utf8) else {
            throw SchwiftyResourcesError.stringDecodingFailed
        }

        return string
    }
}
