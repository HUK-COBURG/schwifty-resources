//
//  BundleResource.swift
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

import class Foundation.Bundle
import struct Foundation.Data
import struct Foundation.URL

public protocol BundleResource: Sendable {
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
