//
//  FileResource.swift
//
//
//  Created by Johannes Bosecker on 13.12.22.
//

import class Foundation.Bundle
import struct Foundation.Data
import struct Foundation.URL
import Foundation.NSPathUtilities

public protocol FileResource {
    /// The type of the content resource coder. Must conform to `ResourceCoder`.
    associatedtype ContentResourceCoder: ResourceCoder

    /// The instance of the content resource coder.
    var contentResourceCoder: ContentResourceCoder { get }
    /// The URL of the resource.
    var url: URL { get async throws }
    /// Will try to get the data from the given url and decode it with the content resource coder.
    func read() async throws -> ContentResourceCoder.Content
    /// Will try to encode the content using the content resource coder and write it to the given url.
    func write(content: ContentResourceCoder.Content) async throws
}

public extension FileResource {
    var contentResourceCoder: ContentResourceCoder {
        ContentResourceCoder()
    }

    func read() async throws -> ContentResourceCoder.Content {
        let url = try await self.url

        do {
            let data = try Data(contentsOf: url)

            do {
                let content = try contentResourceCoder.decode(data: data)
                return content
            } catch {
                throw ErrorWrapper.wrapped(error)
            }
        } catch {
            if let error = error as? ErrorWrapper, case let .wrapped(wrappedError) = error {
                throw wrappedError
            } else {
                throw SchwiftyResourcesError.cannotReadFile(error)
            }
        }
    }
    
    func write(content: ContentResourceCoder.Content) async throws {
        let url = try await self.url
        let data = try contentResourceCoder.encode(content: content)
        
        do {
            try (data ?? Data()).write(to: url)
        } catch {
            throw SchwiftyResourcesError.cannotReadFile(error)
        }
    }
}

public protocol SandboxResource: FileResource {
    /// The location inside the sandbox (e.g. caches or documents)
    var location: SandboxLocation { get }
    /// The path to the resource relative to the location
    var path: String { get }
}

public extension SandboxResource {
    var url: URL {
        get throws {
            guard let locationUrl = location.url else {
                throw SchwiftyResourcesError.sandboxLocationUnavailable
            }
            
            return locationUrl.appendingPathComponent(path, isDirectory: false)
        }
    }
}

public enum SandboxLocation {
    case caches
    case documents
    
    var url: URL? {
        var path: String? = nil
        
        switch self {
        case .caches:
            path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        case .documents:
            path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        }
        
        guard let path = path else {
            return nil
        }
        
        return URL(fileURLWithPath: path)
    }
}

private enum ErrorWrapper: Error {
    case wrapped(Error)
}
