//
//  ResourceCoder.swift
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

import struct Foundation.Data
import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

/// Conform to this protocol and set it as typealias of `HttpResource`, `LocalResource` or `UserDefaultsResource` to be able to en- and decode the content.
public typealias ResourceCoder = ResourceEncoder & ResourceDecoder

/// Conform to this protocol and set it as typealias of `HttpResource`, `LocalResource` or `UserDefaultsResource` to be able to encode the content.
public protocol ResourceEncoder<Content> {
    associatedtype Content
    init()
    var contentType: String? { get }
    func encode(content: Content) throws -> Data?
}

/// Conform to this protocol and set it as typealias of `HttpResource`, `LocalResource` or `UserDefaultsResource` to be able to decode the content.
public protocol ResourceDecoder<Content> {
    associatedtype Content
    init()
    func decode(data: Data) throws -> Content
}

/// This resource coder will encode to nil Data and decode to a `Void`.
/// The ContentType will also be empty.
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

/// This resource coder will just pass through the data.
/// The ContentType has to be set.
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

/// This resource coder will just pass through the data.
/// The ContentType has to be set.
/// Additionally the data will be en- and decrypted using the given `Crypter`.
public struct CryptedDataResourceCoder<Cryption: Crypter>: ResourceCoder {
    public typealias Content = Data
    
    let dataResourceCoder = DataResourceCoder()
    
    public init() {}
    
    public var contentType: String?
    
    public func encode(content: Data) throws -> Data? {
        let data = try dataResourceCoder.encode(content: content)
        
        do {
            let encryptedData = try Cryption.encrypt(data: data ?? Data())
            return encryptedData
        } catch {
            throw SchwiftyResourcesError.encryptionFailed(error)
        }
    }
    
    public func decode(data: Data) throws -> Data {
        var decryptedData: Data? = nil
        
        do {
            decryptedData = try Cryption.decrypt(data: data)
        } catch {
            throw SchwiftyResourcesError.decryptionFailed(error)
        }
        
        guard let decryptedData = decryptedData else {
            throw SchwiftyResourcesError.decryptionFailed(nil)
        }
        
        let content = try dataResourceCoder.decode(data: decryptedData)
        return content
    }
}

/// This resource coder will encode the given `Model` using a default `JSONEncoder`.
/// `Model` has to conform to `Encodable`.
/// The ContentType is fixed to "application/json".
public struct JsonResourceEncoder<Model: Encodable>: ResourceEncoder {
    public typealias Content = Model

    private let jsonEncoder = JSONEncoder()

    public init() {}

    public let contentType: String? = "application/json"

    public func encode(content: Model) throws -> Data? {
        do {
            return try jsonEncoder.encode(content)
        } catch {
            throw SchwiftyResourcesError.jsonEncodingFailed(error)
        }
    }
}


/// This resource coder will decode the data to the given `Model`, by passing it to a default `JSONDecoder`.
/// `Model` has to conform to `Decodable`.
public struct JsonResourceDecoder<Model: Decodable>: ResourceDecoder {
    public typealias Content = Model

    private let jsonDecoder = JSONDecoder()

    public init() {}

    public func decode(data: Data) throws -> Content {
        do {
            return try jsonDecoder.decode(Content.self, from: data)
        } catch {
            throw SchwiftyResourcesError.jsonDecodingFailed(error)
        }
    }
}

/// This resource coder will encode the given `Model` using a default `JSONEncoder` and decode the data to the given `Model`, by passing it to a default `JSONDecoder`.
/// `Model` has to conform to `Codable`.
/// The ContentType is fixed to "application/json".
public struct JsonResourceCoder<Model: Codable>: ResourceCoder {
    public typealias Content = Model
    
    private let jsonResourceEncoder = JsonResourceEncoder<Model>()
    private let jsonResourceDecoder = JsonResourceDecoder<Model>()

    public init() {}

    public let contentType: String? = "application/json"

    public func encode(content: Model) throws -> Data? {
        return try jsonResourceEncoder.encode(content: content)
    }
    
    public func decode(data: Data) throws -> Content {
        return try jsonResourceDecoder.decode(data: data)
    }
}

/// This resource coder will encode the given `Model` using a default `JSONEncoder` and decode the data to the given `Model`, by passing it to a default `JSONDecoder`.
/// `Model` has to conform to `Codable`.
/// The ContentType is fixed to "application/json".
/// Additionally the data will be en- and decrypted using the given `Crypter`.
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

/// This resource coder will encode a `String` to UTF8 Data and decode from UTF8 Data to a `String`.
/// The ContentType defaults to "text/plain" but can be set, if desired.
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
