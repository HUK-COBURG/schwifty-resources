//
//  BundleResource.swift
//  
//
//  Created by Johannes Bosecker on 11.01.23.
//

import class Foundation.Bundle
import struct Foundation.Data
import struct Foundation.URL

public protocol BundleResource {
    /// The type of the content resource decoder. Must conform to `ResourceDecoder`.
    associatedtype ContentResourceDecoder: ResourceDecoder

    /// The instance of the content resource coder.
    var contentResourceDecoder: ContentResourceDecoder { get }
    /// The bundle of the resource.
    var bundle: Bundle { get }
    /// The file name of the resource
    var fileName: String { get }
    /// Will try to get the data from the given url and decode it with the content resource coder.
    func read() async throws -> ContentResourceDecoder.Content
}

public extension BundleResource {
    var contentResourceDecoder: ContentResourceDecoder {
        ContentResourceDecoder()
    }

    var bundle: Bundle {
        return .main
    }
    
    func read() async throws -> ContentResourceDecoder.Content {
        let url = try buildUrl()

        do {
            let data = try Data(contentsOf: url)

            do {
                let content = try contentResourceDecoder.decode(data: data)
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
    
    // MARK: - Private functions
    
    private func buildUrl() throws -> URL {
        guard let url = bundle.url(forResource: fileName, withExtension: nil) else {
            throw SchwiftyResourcesError.fileNotFound
        }

        return url
    }
}

private enum ErrorWrapper: Error {
    case wrapped(Error)
}
